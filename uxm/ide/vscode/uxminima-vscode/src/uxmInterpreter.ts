import { TraceEvent, CellEntry, ascii } from "./traceReader";
import { META_SERVICES } from "./metaServices";

type SpaceName = "T" | "D" | "S" | "P" | "E" | "F";
type AddrKind = "T" | "T_REL" | "T_ABS" | "D_ABS" | "S_ABS" | "SP" | "P" | "E" | "F" | "IND_T" | "IND_T_REL" | "D_AT_T_REL" | "D_AT_TBASE_REL";

interface Address { kind: AddrKind; value: number; value2?: number; text: string; }
interface Instr { op: string; amount: number; text: string; addr: Address; metaId?: number; metaDyn?: boolean; metaForceHost?: boolean; brCond?: string; brDir?: number; brDist?: number; brTarget?: number; mate?: number; stringId?: number; }
interface StringDef { id: number; start: number; text: string; }
interface MacroDef { id: number; text: string; }

export interface InternalTraceResult {
  events: TraceEvent[];
  output: string;
  uir: Instr[];
  diagnostics: string[];
}

export class UxmInterpreter {
  private readonly diagnostics: string[] = [];
  private readonly unsupportedMetaReported = new Set<number>();
  private instr: Instr[] = [];
  private strings = new Map<number, StringDef>();
  private macros = new Map<number, MacroDef>();
  private tape: number[] = [];
  private data: number[] = [];
  private stack: number[] = [];
  private fifo: number[] = [];
  private ptr = 0;
  private sp = 0;
  private status = 0;
  private flags = 128;
  private cellBits = 8;
  private tapeKB = 32;
  private stackKB = 8;
  private dataKB = 24;
  private output = "";
  private step = 0;
  private rngState = 0;
  private pragmaDataInits: Array<{ idx: number; value: number }> = [];
  private pragmaSeedEnabled = false;
  private pragmaSeedValue = 1;

  run(source: string): InternalTraceResult {
    this.reset();
    this.parsePragmas(source);
    this.applyMemory();
    this.firstPass(source);
    this.instr = this.parseProgram(source, 0);
    this.validate();
    this.loadStrings();
    const events = this.execute();
    return { events, output: this.output, uir: this.instr, diagnostics: this.diagnostics };
  }

  private reset(): void {
    this.diagnostics.length = 0;
    this.unsupportedMetaReported.clear();
    this.instr = [];
    this.strings.clear();
    this.macros.clear();
    this.ptr = 0;
    this.sp = 0;
    this.status = 0;
    this.flags = 128;
    this.cellBits = 8;
    this.tapeKB = 32;
    this.stackKB = 8;
    this.dataKB = 24;
    this.output = "";
    this.step = 0;
    this.fifo = [];
    this.rngState = Date.now() >>> 0;
    this.pragmaDataInits = [];
    this.pragmaSeedEnabled = false;
    this.pragmaSeedValue = 1;
  }

  private parsePragmas(source: string): void {
    for (const raw of source.split(/\r?\n/)) {
      const line = raw.trim().toLowerCase().replace(/\s+/g, "");
      if (!line.startsWith("#")) { continue; }
      if (line.startsWith("#cell")) {
        if (line.includes("byte")) { this.cellBits = 8; }
        if (line.includes("word")) { this.cellBits = 16; }
        if (line.includes("dword")) { this.cellBits = 32; }
      } else if (line.startsWith("#memory")) {
        const get = (name: string): number | undefined => {
          const m = new RegExp(`${name}=([0-9]+)`).exec(line);
          return m ? Number(m[1]) : undefined;
        };
        this.tapeKB = get("tape") ?? this.tapeKB;
        this.stackKB = get("stack") ?? this.stackKB;
        this.dataKB = get("data") ?? this.dataKB;
      } else if (line.startsWith("#compare")) {
        if (line.includes("signed")) { this.flags |= 0x10; }
        if (line.includes("unsigned")) { this.flags &= ~0x10; }
      } else if (line.startsWith("#endian")) {
        if (line.includes("big")) { this.flags |= 0x20; }
        if (line.includes("little")) { this.flags &= ~0x20; }
      } else if (line.startsWith("#modewild")) {
        this.flags |= 0x40;
      } else if (line.startsWith("#seed")) {
        const seed = Number(line.replace("#seed", "").trim());
        if (Number.isFinite(seed)) {
          this.pragmaSeedEnabled = true;
          this.pragmaSeedValue = seed === 0 ? 1 : seed;
        }
      } else if (line.startsWith("#poly") || line.startsWith("#expr-rpn") || line.startsWith("#matrix") || line.startsWith("#identity") || line.startsWith("#zeros") || line.startsWith("#ones")) {
        this.parseDataPragma(raw.trim());
      }
    }
  }

  private applyMemory(): void {
    if (this.tapeKB + this.stackKB + this.dataKB !== 64) {
      this.diagnostics.push(`#memory toplamı 64 KB değil: ${this.tapeKB + this.stackKB + this.dataKB}`);
    }
    const bytes = this.cellBits / 8;
    this.tape = new Array(Math.floor((this.tapeKB * 1024) / bytes)).fill(0);
    this.stack = new Array(Math.floor((this.stackKB * 1024) / bytes)).fill(0);
    this.data = new Array(Math.floor((this.dataKB * 1024) / bytes)).fill(0);
  }

  private firstPass(source: string): void {
    const sRe = /\bs([0-9]+)\s*=\s*([0-9]+)\s*,\s*\{([\s\S]*?)\}/g;
    for (const m of source.matchAll(sRe)) {
      this.strings.set(Number(m[1]), { id: Number(m[1]), start: Number(m[2]), text: this.unescape(m[3]) });
    }
    const mRe = /\bm([0-9]+)\s*=\s*\{([\s\S]*?)\}/g;
    for (const m of source.matchAll(mRe)) {
      const id = Number(m[1]);
      if (id < 128 || id > 255) { this.diagnostics.push(`m${id}: macro id 128..255 olmalı.`); }
      this.macros.set(id, { id, text: m[2] });
    }
  }

  private parseProgram(source: string, depth: number): Instr[] {
    if (depth > 32) { this.diagnostics.push("Macro genişleme derinliği 32'yi geçti."); return []; }
    const code = this.stripDefinitions(source);
    const out: Instr[] = [];
    let p = 0;
    while (p < code.length) {
      const c = code[p];
      if (/\s/.test(c)) { p++; continue; }
      if (c === "#") { while (p < code.length && code[p] !== "\n") { p++; } continue; }
      if (c === "p") {
        const m = /^p([0-9]+)/.exec(code.slice(p));
        if (m) { out.push({ op: "PRINT_STRING", amount: 0, text: m[0], addr: this.addrT(), stringId: Number(m[1]) }); p += m[0].length; continue; }
      }
      if (c === "@") {
        if (code[p + 1] === "#") { out.push({ op: "META", amount: 0, text: "@#", addr: this.addrT(), metaDyn: true }); p += 2; continue; }
        const mForce = /^@!([0-9]+)/.exec(code.slice(p));
        if (mForce) {
          out.push({ op: "META", amount: 0, text: mForce[0], addr: this.addrT(), metaId: Number(mForce[1]), metaForceHost: true });
          p += mForce[0].length;
          continue;
        }
        const m = /^@([0-9]+)/.exec(code.slice(p));
        if (m) {
          const id = Number(m[1]);
          const macro = this.macros.get(id);
          if (macro) { out.push(...this.parseProgram(macro.text, depth + 1)); } else { out.push({ op: "META", amount: 0, text: m[0], addr: this.addrT(), metaId: id }); }
          p += m[0].length;
          continue;
        }
      }
      if (c === ":") {
        const m = /^:(:|0|z|Z|c|C|o|O|s|S)?([+-])([0-9]+)/.exec(code.slice(p));
        if (m) { out.push({ op: "BRANCH", amount: 0, text: m[0], addr: this.addrT(), brCond: m[1] ?? "+", brDir: m[2] === "+" ? 1 : -1, brDist: Number(m[3]) }); p += m[0].length; continue; }
      }
      if ("><+-0.,[]$%?!;&|^~{}eE".includes(c)) {
        const start = p;
        p++;
        let amount = 1;
        if ((c === "+" || c === "-") && code[p]?.toLowerCase() === "k") {
          const m = /^k([0-9]+)/i.exec(code.slice(p));
          if (m) { amount = Number(m[1]); p += m[0].length; }
        }
        const addr = this.parseAddress(code, () => p, (np) => { p = np; });
        const op = this.commandToOp(c);
        out.push({ op, amount, text: code.slice(start, p), addr });
        if (c === "0" && (code[p] === "+" || code[p] === "-") && code[p + 1]?.toLowerCase() === "k") {
          const sign = code[p];
          const m = /^.k([0-9]+)/i.exec(code.slice(p));
          if (m) { out.push({ op: sign === "+" ? "INC" : "DEC", amount: Number(m[1]), text: m[0], addr }); p += m[0].length; }
        }
        continue;
      }
      this.diagnostics.push(`Bilinmeyen karakter: ${c}`);
      p++;
    }
    return out;
  }

  private stripDefinitions(source: string): string {
    return source
      .replace(/\bs[0-9]+\s*=\s*[0-9]+\s*,\s*\{[\s\S]*?\}/g, "")
      .replace(/\bm[0-9]+\s*=\s*\{[\s\S]*?\}/g, "");
  }

  private parseAddress(code: string, getP: () => number, setP: (p: number) => void): Address {
    let p = getP();
    if (code[p] !== "(") { return this.addrT(); }
    let depth = 0;
    const start = p;
    while (p < code.length) {
      if (/\s/.test(code[p])) { this.diagnostics.push("Adresleme içinde boşluk yasak."); }
      if (code[p] === "(") { depth++; }
      if (code[p] === ")") { depth--; if (depth === 0) { break; } }
      p++;
    }
    if (p >= code.length) { this.diagnostics.push("Adresleme parantezi kapanmadı."); return this.addrT(); }
    const body = code.slice(start + 1, p).toUpperCase();
    setP(p + 1);
    if (body === "T") { return this.addrT(); }
    if (body === "SP") { return { kind: "SP", value: 0, text: "(SP)" }; }
    if (body === "P") { return { kind: "P", value: 0, text: "(P)" }; }
    if (body === "E") { return { kind: "E", value: 0, text: "(E)" }; }
    if (body === "F") { return { kind: "F", value: 0, text: "(F)" }; }
    if (body === "*T") { return { kind: "IND_T", value: 0, text: "(*T)" }; }
    if (/^T[+]\d+$/.test(body)) { return { kind: "T_REL", value: Number(body.slice(2)), text: `(${body})` }; }
    if (/^T-\d+$/.test(body)) { return { kind: "T_REL", value: -Number(body.slice(2)), text: `(${body})` }; }
    if (/^T:\d+$/.test(body)) { return { kind: "T_ABS", value: Number(body.slice(2)), text: `(${body})` }; }
    if (/^D:\d+$/.test(body)) { return { kind: "D_ABS", value: Number(body.slice(2)), text: `(${body})` }; }
    if (/^S:\d+$/.test(body)) { return { kind: "S_ABS", value: Number(body.slice(2)), text: `(${body})` }; }
    if (/^D@T$/.test(body)) { return { kind: "D_AT_T_REL", value: 0, value2: 0, text: `(${body})` }; }
    if (/^D@T[+]\d+$/.test(body)) { return { kind: "D_AT_T_REL", value: 0, value2: Number(body.slice(4)), text: `(${body})` }; }
    if (/^D@T-\d+$/.test(body)) { return { kind: "D_AT_T_REL", value: 0, value2: -Number(body.slice(4)), text: `(${body})` }; }
    const dAtTBase = /^D@\(T([+-]\d+)?\)([+-]\d+)?$/.exec(body);
    if (dAtTBase) {
      const baseRel = dAtTBase[1] ? Number(dAtTBase[1]) : 0;
      const dataRel = dAtTBase[2] ? Number(dAtTBase[2]) : 0;
      return { kind: "D_AT_TBASE_REL", value: baseRel, value2: dataRel, text: `(${body})` };
    }
    const indirect = /^\*\(T([+-]\d+)\)$/.exec(body);
    if (indirect) { return { kind: "IND_T_REL", value: Number(indirect[1]), text: `(${body})` }; }
    this.diagnostics.push(`Geçersiz adresleme: (${body})`);
    return this.addrT();
  }

  private addrT(): Address { return { kind: "T", value: 0, text: "(T)" }; }

  private commandToOp(c: string): string {
    const map: Record<string, string> = { ">": "RIGHT", "<": "LEFT", "+": "INC", "-": "DEC", "0": "CLEAR", ".": "PUTC", ",": "GETC", "[": "LOOP_BEGIN", "]": "LOOP_END", "$": "PUSH", "%": "POP", "?": "EQ", "!": "GT", ";": "LT", "&": "AND", "|": "OR", "^": "XOR", "~": "NOT", "{": "SHL", "}": "SHR", "e": "STATUS", "E": "STATUS" };
    return map[c] ?? "NOP";
  }

  private validate(): void {
    const stack: number[] = [];
    this.instr.forEach((ins, i) => {
      if (ins.op === "LOOP_BEGIN") { stack.push(i); }
      if (ins.op === "LOOP_END") {
        const j = stack.pop();
        if (j === undefined) { this.diagnostics.push(`Fazla ] @${i + 1}`); }
        else { ins.mate = j; this.instr[j].mate = i; }
      }
      if (ins.op === "BRANCH") {
        const target = i + (ins.brDir ?? 1) * (ins.brDist ?? 0);
        if (target < 0 || target >= this.instr.length) { this.diagnostics.push(`Branch hedefi dışarıda @${i + 1}`); }
        else { ins.brTarget = target; }
      }
    });
    for (const j of stack) { this.diagnostics.push(`Kapanmamış [ @${j + 1}`); }
  }

  private loadStrings(): void {
    for (const s of this.strings.values()) {
      for (let i = 0; i < s.text.length && s.start + i < this.data.length; i++) {
        this.data[s.start + i] = s.text.charCodeAt(i) & this.mask();
      }
      if (s.start + s.text.length < this.data.length) { this.data[s.start + s.text.length] = 0; }
    }
    for (const it of this.pragmaDataInits) {
      if (it.idx >= 0 && it.idx < this.data.length) {
        this.data[it.idx] = it.value & this.mask();
      }
    }
    if (this.pragmaSeedEnabled) {
      this.rngSeed(this.pragmaSeedValue);
    }
  }

  private addDataInit(idx: number, value: number): void {
    if (!Number.isFinite(idx) || idx < 0) { return; }
    this.pragmaDataInits.push({ idx: Math.floor(idx), value: Math.floor(value) });
  }

  private splitCsvValues(csv: string): number[] {
    return csv.split(",").map((x) => Number(x.trim())).filter((x) => Number.isFinite(x));
  }

  private pow10(n: number): number {
    let p = 1;
    for (let i = 0; i < Math.max(0, n); i++) { p *= 10; }
    return p;
  }

  private fixedToScaled(s: string, scale: number): number {
    const v = Number(s.trim());
    if (!Number.isFinite(v)) { return 0; }
    return Math.trunc(v * this.pow10(scale));
  }

  private matrixEmitHeader(base: number, rows: number, cols: number, typ: number, scale: number): void {
    const total = rows * cols;
    const totalCells = 16 + total;
    let flags = 0;
    if (typ === 1) flags |= 1;
    if (typ === 2) flags |= 2;
    this.addDataInit(base + 0, 77);
    this.addDataInit(base + 1, 1);
    this.addDataInit(base + 2, 2);
    this.addDataInit(base + 3, typ);
    this.addDataInit(base + 4, flags);
    this.addDataInit(base + 5, rows);
    this.addDataInit(base + 6, cols);
    this.addDataInit(base + 7, scale);
    this.addDataInit(base + 8, 1);
    this.addDataInit(base + 9, 16);
    this.addDataInit(base + 10, total);
    this.addDataInit(base + 11, totalCells);
    this.addDataInit(base + 12, cols);
    this.addDataInit(base + 13, 1);
    this.addDataInit(base + 14, 0);
    this.addDataInit(base + 15, 0);
  }

  private parseDataPragma(rawLine: string): void {
    const line = rawLine.trim();
    const lower = line.toLowerCase();
    const eqPos = line.indexOf("=");
    const left = (eqPos >= 0 ? line.slice(0, eqPos) : line).trim();
    const right = (eqPos >= 0 ? line.slice(eqPos + 1) : "").trim();

    if (lower.startsWith("#poly")) {
      const base = Number(left.replace(/^#poly/i, "").trim());
      const vals = this.splitCsvValues(right);
      if (!Number.isFinite(base) || vals.length === 0) { return; }
      this.addDataInit(base + 0, 80);
      this.addDataInit(base + 1, 1);
      this.addDataInit(base + 2, vals.length - 1);
      this.addDataInit(base + 3, 0);
      vals.forEach((v, i) => this.addDataInit(base + 4 + i, v));
      return;
    }

    if (lower.startsWith("#expr-rpn")) {
      const base = Number(left.replace(/^#expr-rpn/i, "").trim());
      if (!Number.isFinite(base)) { return; }
      const tokenCode = (tok: string): number => {
        const t = tok.toLowerCase();
        if (t === "const") return 1;
        if (t === "x") return 2;
        if (t === "+" || t === "add") return 10;
        if (t === "-" || t === "sub") return 11;
        if (t === "*" || t === "mul") return 12;
        if (t === "/" || t === "div") return 13;
        if (t === "pow") return 14;
        if (t === "sin") return 20;
        if (t === "cos") return 21;
        if (t === "tan") return 22;
        if (t === "exp") return 23;
        if (t === "log") return 24;
        if (t === "sqrt") return 25;
        if (t === "neg") return 30;
        if (t === "abs") return 31;
        if (t === "end") return 99;
        return 1;
      };
      this.addDataInit(base + 0, 69);
      this.addDataInit(base + 1, 1);
      this.addDataInit(base + 3, 0);
      const toks = right.split(/\s+/).filter(Boolean);
      let outIdx = base + 4;
      let count = 0;
      for (const tok of toks) {
        if (/^[0-9]+$/.test(tok)) {
          this.addDataInit(outIdx, 1);
          this.addDataInit(outIdx + 1, Number(tok));
          outIdx += 2;
          count += 2;
        } else {
          this.addDataInit(outIdx, tokenCode(tok));
          outIdx += 1;
          count += 1;
        }
      }
      this.addDataInit(outIdx, 99);
      count += 1;
      this.addDataInit(base + 2, count);
      return;
    }

    const parts = left.split(/\s+/).filter(Boolean);
    const cmd = (parts[0] || "").toLowerCase();
    if (cmd === "#matrix" || cmd === "#matrix-signed" || cmd === "#matrix-fixed") {
      const base = Number(parts[1]);
      const rows = Number(parts[2]);
      const cols = Number(parts[3]);
      if (!Number.isFinite(base) || !Number.isFinite(rows) || !Number.isFinite(cols) || rows <= 0 || cols <= 0) { return; }
      if (cmd === "#matrix-fixed") {
        const scale = Number(parts[4] || "0");
        this.matrixEmitHeader(base, rows, cols, 2, scale);
        const vals = right.split(",");
        const need = Math.min(vals.length, rows * cols);
        for (let i = 0; i < need; i++) this.addDataInit(base + 16 + i, this.fixedToScaled(vals[i], scale));
      } else {
        this.matrixEmitHeader(base, rows, cols, cmd === "#matrix-signed" ? 1 : 0, 0);
        const vals = this.splitCsvValues(right);
        const need = Math.min(vals.length, rows * cols);
        for (let i = 0; i < need; i++) this.addDataInit(base + 16 + i, vals[i]);
      }
      return;
    }

    if (cmd === "#identity") {
      const base = Number(parts[1]);
      const n = Number(parts[2]);
      if (!Number.isFinite(base) || !Number.isFinite(n) || n <= 0) { return; }
      this.matrixEmitHeader(base, n, n, 0, 0);
      for (let i = 0; i < n; i++) this.addDataInit(base + 16 + i * n + i, 1);
      return;
    }

    if (cmd === "#zeros" || cmd === "#ones") {
      const base = Number(parts[1]);
      const rows = Number(parts[2]);
      const cols = Number(parts[3]);
      if (!Number.isFinite(base) || !Number.isFinite(rows) || !Number.isFinite(cols) || rows <= 0 || cols <= 0) { return; }
      this.matrixEmitHeader(base, rows, cols, 0, 0);
      if (cmd === "#ones") {
        for (let i = 0; i < rows * cols; i++) this.addDataInit(base + 16 + i, 1);
      }
    }
  }

  private execute(): TraceEvent[] {
    const events: TraceEvent[] = [];
    let ip = 0;
    let guard = 0;
    while (ip >= 0 && ip < this.instr.length && guard < 100000) {
      guard++;
      const ins = this.instr[ip];
      const oldIp = ip;
      ip = this.executeOne(ip, ins);
      events.push(this.makeEvent(oldIp, ins));
      if (this.status === 11 || this.status === 12) { break; }
    }
    return events;
  }

  private executeOne(ip: number, ins: Instr): number {
    switch (ins.op) {
      case "RIGHT": this.ptr += ins.amount; this.boundsPtr(); return ip + 1;
      case "LEFT": this.ptr -= ins.amount; this.boundsPtr(); return ip + 1;
      case "INC": this.writeAddr(ins.addr, this.readAddr(ins.addr) + ins.amount); return ip + 1;
      case "DEC": this.writeAddr(ins.addr, this.readAddr(ins.addr) - ins.amount); return ip + 1;
      case "CLEAR": this.writeAddr(ins.addr, 0); return ip + 1;
      case "PUTC": this.output += String.fromCharCode(this.readAddr(ins.addr) & 0xff); return ip + 1;
      case "GETC": this.writeAddr(ins.addr, 0); this.setStatus(26); return ip + 1;
      case "PUSH": this.push(this.readAddr(ins.addr)); return ip + 1;
      case "POP": this.writeAddr(ins.addr, this.pop()); return ip + 1;
      case "EQ": return this.binaryStack(ins, (a, b) => a === b ? 1 : 0, ip);
      case "GT": return this.binaryStack(ins, (a, b) => a > b ? 1 : 0, ip);
      case "LT": return this.binaryStack(ins, (a, b) => a < b ? 1 : 0, ip);
      case "AND": return this.binaryStack(ins, (a, b) => a & b, ip);
      case "OR": return this.binaryStack(ins, (a, b) => a | b, ip);
      case "XOR": return this.binaryStack(ins, (a, b) => a ^ b, ip);
      case "NOT": this.writeAddr(ins.addr, ~this.readAddr(ins.addr)); return ip + 1;
      case "SHL": this.writeAddr(ins.addr, this.readAddr(ins.addr) << 1); return ip + 1;
      case "SHR": this.writeAddr(ins.addr, this.readAddr(ins.addr) >>> 1); return ip + 1;
      case "STATUS": this.writeAddr(ins.addr, this.status); return ip + 1;
      case "LOOP_BEGIN": return this.tape[this.ptr] === 0 && ins.mate !== undefined ? ins.mate + 1 : ip + 1;
      case "LOOP_END": return this.tape[this.ptr] !== 0 && ins.mate !== undefined ? ins.mate + 1 : ip + 1;
      case "META": this.meta(ins.metaDyn ? this.tape[this.ptr] : (ins.metaId ?? 0), ins.metaForceHost === true); return ip + 1;
      case "BRANCH": return this.branchTaken(ins) ? (ins.brTarget ?? ip + 1) : ip + 1;
      case "PRINT_STRING": this.printString(ins.stringId ?? 0); return ip + 1;
      default: return ip + 1;
    }
  }

  private binaryStack(ins: Instr, fn: (a: number, b: number) => number, ip: number): number {
    const a = this.pop();
    const b = this.readAddr(ins.addr);
    this.writeAddr(ins.addr, fn(a, b));
    return ip + 1;
  }

  private branchTaken(ins: Instr): boolean {
    switch (ins.brCond) {
      case "0": return this.tape[this.ptr] === 0;
      case ":": return true;
      case "z": return (this.flags & 1) !== 0;
      case "Z": return (this.flags & 1) === 0;
      case "c": return (this.flags & 2) !== 0;
      case "C": return (this.flags & 2) === 0;
      case "o": return (this.flags & 4) !== 0;
      case "O": return (this.flags & 4) === 0;
      case "s": return (this.flags & 8) !== 0;
      case "S": return (this.flags & 8) === 0;
      default: return this.tape[this.ptr] !== 0;
    }
  }

  private meta(id: number, forceHost = false): void {
    if (id >= 128 && id <= 255) {
      const reason = forceHost
        ? "@!N host meta cagrisi internal yorumlayicida uygulanmadi"
        : "128..255 araliginda host/macro servis runtime olarak uygulanmadi";
      this.markUnsupportedMeta(id, reason);
      return;
    }
    const arg1 = this.readTape(this.ptr - 2);
    const arg2 = this.readTape(this.ptr - 1);
    const arg0 = this.readTape(this.ptr);
    let result: number | undefined;
    let preserveStatusAfterWrite = false;
    switch (id) {
      case 0: this.setStatus(0); break;
      case 1: this.setStatus(0); break;
      case 2: this.setStatus(0); break;
      case 3: result = Math.floor(this.rngNext() * 256); break;
      case 4: result = Date.now(); break;
      case 5: this.output += "\n"; this.setStatus(0); break;
      case 6: this.output += "[UXM META]"; this.setStatus(0); break;
      case 7: result = 7; break;
      case 8: result = 8; break;
      case 9: result = this.status; preserveStatusAfterWrite = true; break;
      case 10: this.setStatus(0); break;
      case 11: this.setStatus(arg1 & 0xff); break;
      case 12: this.output += `STATUS=${this.status}`; this.setStatus(0); break;
      case 13: this.setStatus(this.status === 0 ? 1 : this.status); break;
      case 14: this.setStatus(0); break;
      case 15: result = (this.flags & 0x400) ? 1 : 0; preserveStatusAfterWrite = true; break;
      case 20: result = arg1 + arg2; break;
      case 21: result = arg1 - arg2; break;
      case 22: result = arg1 * arg2; break;
      case 23: if (arg2 === 0) { result = 0; this.setStatus(15); } else { result = Math.floor(arg1 / arg2); } break;
      case 24: if (arg2 === 0) { result = 0; this.setStatus(15); } else { result = arg1 % arg2; } break;
      case 25: result = arg1 < arg2 ? arg1 : arg2; break;
      case 26: result = arg1 > arg2 ? arg1 : arg2; break;
      case 27: {
        if ((this.flags & 0x10) !== 0) {
          let signed = arg2;
          if (this.cellBits === 8 && (arg2 & 0x80)) signed = arg2 - 256;
          else if (this.cellBits === 16 && (arg2 & 0x8000)) signed = arg2 - 65536;
          else if (this.cellBits === 32 && (arg2 & 0x80000000)) signed = arg2 - 4294967296;
          result = signed < 0 ? (Math.abs(signed) & this.mask()) : (signed & this.mask());
        } else {
          result = arg2 & this.mask();
        }
      } break;
      case 28: result = (((~arg2) + 1) >>> 0) & this.mask(); break;
      case 29: result = arg1 === arg2 ? 0 : (arg1 > arg2 ? 1 : this.mask()); break;
      case 30: { // RND_RANGE: min=T-2, max=T-1 -> T+1
        if (arg2 < arg1) { result = arg1; } else { result = arg1 + Math.floor(this.rngNext() * (arg2 - arg1 + 1)); }
      } break;
      case 31: // RND_SEED: seed=T-1
        this.rngSeed(arg2);
        this.setStatus(0);
        break;
      case 32: // RND_FLOAT01 -> scaled fixed 0..ScaleFactor
        result = Math.floor(this.rngNext() * this.scale());
        break;
      case 33: // DIV_UNSIGNED
        if (arg2 === 0) { result = 0; this.setStatus(15); } else { result = Math.floor(arg1 / arg2); }
        break;
      case 34: { // DIV_SIGNED
        if (arg2 === 0) { result = 0; this.setStatus(15); break; }
        const toSigned = (v: number) => {
          if (this.cellBits === 8 && (v & 0x80)) return v - 256;
          if (this.cellBits === 16 && (v & 0x8000)) return v - 65536;
          if (this.cellBits === 32 && (v & 0x80000000)) return v - 4294967296;
          return v;
        };
        const sa = toSigned(arg1);
        const sb = toSigned(arg2);
        const sr = Math.trunc(sa / sb);
        const pow2 = this.cellBits === 8 ? 256 : this.cellBits === 16 ? 65536 : 4294967296;
        result = sr < 0 ? ((pow2 + sr) >>> 0) & this.mask() : (sr & this.mask());
      } break;
      case 35: // MOD_UNSIGNED
        if (arg2 === 0) { result = 0; this.setStatus(15); } else { result = arg1 % arg2; }
        break;
      case 36: { // MOD_SIGNED
        if (arg2 === 0) { result = 0; this.setStatus(15); break; }
        const toSigned2 = (v: number) => {
          if (this.cellBits === 8 && (v & 0x80)) return v - 256;
          if (this.cellBits === 16 && (v & 0x8000)) return v - 65536;
          if (this.cellBits === 32 && (v & 0x80000000)) return v - 4294967296;
          return v;
        };
        const sa2 = toSigned2(arg1);
        const sb2 = toSigned2(arg2);
        let m = sa2 % sb2;
        const pow2_2 = this.cellBits === 8 ? 256 : this.cellBits === 16 ? 65536 : 4294967296;
        if (m < 0) m += pow2_2;
        result = m & this.mask();
      } break;
      case 40: result = Math.round(Math.sin(arg2 * Math.PI / 180) * this.scale()); break;
      case 41: result = Math.round(Math.cos(arg2 * Math.PI / 180) * this.scale()); break;
      case 42: result = Math.round(Math.tan(arg2 * Math.PI / 180) * this.scale()); break;
      case 43: result = Math.round(Math.sqrt(arg1 * arg1 + arg2 * arg2)); break;
      case 44: result = Math.round(Math.asin(arg2 / this.scale()) * 180 / Math.PI); break;
      case 45: result = Math.round(Math.acos(arg2 / this.scale()) * 180 / Math.PI); break;
      case 46: result = Math.round(Math.sqrt(arg2)); break;
      case 47: result = Math.round(Math.sinh(arg2 * Math.PI / 180) * this.scale()); break;
      case 48: result = Math.round(Math.cosh(arg2 * Math.PI / 180) * this.scale()); break;
      case 49: result = Math.round(Math.tanh(arg2 * Math.PI / 180) * this.scale()); break;
      case 52: {
        const x = this.toSignedCell(arg2) / this.scale();
        result = Math.round(Math.asinh(x) * this.scale());
      } break;
      case 53: {
        const x = arg2 / this.scale();
        if (x < 1) {
          result = 0;
          this.setStatus(14);
        } else {
          result = Math.round(Math.acosh(x) * this.scale());
        }
      } break;
      case 54: {
        const x = this.toSignedCell(arg2) / this.scale();
        if (Math.abs(x) >= 1) {
          result = 0;
          this.setStatus(13);
        } else {
          result = Math.round(Math.atanh(x) * this.scale());
        }
      } break;
      case 55:
        if (arg2 === 0) {
          result = 0;
          this.setStatus(14);
        } else {
          result = Math.round(Math.log(arg2) * this.scale());
        }
        break;
      case 56:
        result = Math.round(Math.exp(this.toSignedCell(arg2) / this.scale()) * this.scale());
        break;
      case 57:
        result = Math.round(Math.pow(arg1, arg2));
        break;
      case 58:
        result = Math.round((arg2 * Math.PI / 180) * this.scale());
        break;
      case 59:
        result = Math.round((arg2 / this.scale()) * 180 / Math.PI);
        break;
      case 60: this.output += String(arg2); this.setStatus(0); break;
      case 61: this.output += String(this.readTape(this.ptr + 1)); this.setStatus(0); break;
      case 62: this.output += String(this.pop()); break;
      case 63: result = 0; this.setStatus(26); preserveStatusAfterWrite = true; break;
      case 64: this.output += " "; this.setStatus(0); break;
      case 67: this.output += (arg2 & this.mask()).toString(16).toUpperCase(); this.setStatus(0); break;
      case 68: this.output += (arg2 & this.mask()).toString(2); this.setStatus(0); break;
      case 69: this.output += String.fromCharCode(arg2 & 0xff); this.setStatus(0); break;
      case 80: this.ptr = arg2; this.boundsPtr(); this.flags |= 0x1000; break;
      case 81:
        if (this.ptr + arg2 >= this.tape.length) {
          this.setStatus(10);
        } else {
          this.ptr += arg2;
          this.flags |= 0x1000;
          this.setStatus(0);
        }
        break;
      case 82: result = this.ptr; break;
      case 83: result = this.ptr < this.tape.length ? 1 : 0; break;
      case 84: result = this.tape.length; break;
      case 85: result = this.data.length; break;
      case 86: result = this.stack.length; break;
      case 87: result = this.cellBits; break;
      case 88: result = this.cellBits === 8 ? 1 : this.cellBits === 16 ? 2 : 4; break;
      case 89: this.output += `LAYOUT tape=${this.tape.length} stack=${this.stack.length} data=${this.data.length}`; break;
      case 90: this.fifo.push(arg2 & this.mask()); this.setStatus(0); break;
      case 91: result = this.fifo.shift() ?? 0; this.setStatus(this.fifo.length >= 0 ? 0 : 12); break;
      case 92: result = this.fifo[0] ?? 0; this.setStatus(this.fifo.length ? 0 : 12); break;
      case 93: result = this.fifo.length; break;
      case 94: this.fifo = []; this.setStatus(0); break;
      case 95: result = this.data[arg2] ?? 0; break;
      case 96: this.data[arg1] = arg2 & this.mask(); this.setStatus(0); break;
      case 97: { const v = this.data[arg2] ?? 0; result = v >= 48 && v <= 57 ? v - 48 : 0; break; }
      case 98: this.copy(this.data, arg1, arg2, arg0); break;
      case 99: this.clear(this.data, arg1, arg2); break;
      case 100: this.sort(this.tape, arg1, arg2, true); break;
      case 101: this.sort(this.tape, arg1, arg2, false); break;
      case 102: this.sort(this.data, arg1, arg2, true); break;
      case 103: this.sort(this.data, arg1, arg2, false); break;
      case 104: result = this.search(this.tape, arg1, arg2, arg0); break;
      case 105: result = this.search(this.data, arg1, arg2, arg0); break;
      case 106: this.copy(this.tape, arg1, arg2, arg0); break;
      case 107: this.clear(this.tape, arg1, arg2); break;
      case 120: this.flags &= ~0x10; this.setStatus(0); break;
      case 121: this.flags |= 0x10; this.setStatus(0); break;
      case 122: result = (this.flags & 0x10) ? 1 : 0; break;
      case 123: this.flags &= ~0x20; this.setStatus(0); break;
      case 124: this.flags |= 0x20; this.setStatus(0); break;
      case 125: result = (this.flags & 0x20) ? 1 : 0; break;
      case 126: result = this.flags; break;
      case 127: this.changeLayout(arg1, arg2, arg0); break;
      case 160:
        if (!this.matInit(arg1, arg2, arg0, 0, 0)) this.setStatus(16); else this.setStatus(0);
        break;
      case 161:
        if (!this.matValid(arg1)) this.setStatus(16); else {
          const n = this.data[arg1 + 10] | 0;
          for (let i = 0; i < n; i++) this.data[arg1 + 16 + i] = 0;
          this.setStatus(0);
        }
        break;
      case 162: {
        const idx = this.matCellIndex(arg1, arg2, arg0);
        if (idx < 0) this.setStatus(16); else { this.data[idx] = this.readTape(this.ptr - 3) & this.mask(); this.setStatus(0); }
      } break;
      case 163: {
        const idx = this.matCellIndex(arg1, arg2, arg0);
        if (idx < 0) this.setStatus(16); else result = this.data[idx] ?? 0;
      } break;
      case 164:
        if (!this.matValid(arg1)) this.setStatus(16); else {
          const n = this.data[arg1 + 10] | 0;
          const v = this.readTape(this.ptr - 3) & this.mask();
          for (let i = 0; i < n; i++) this.data[arg1 + 16 + i] = v;
          this.setStatus(0);
        }
        break;
      case 165:
        if (!this.matValid(arg1) || !this.matValid(arg2)) this.setStatus(16); else {
          const n = this.data[arg2 + 10] | 0;
          if ((this.data[arg1 + 10] | 0) !== n) this.setStatus(16); else {
            for (let i = 0; i < n; i++) this.data[arg1 + 16 + i] = this.data[arg2 + 16 + i] ?? 0;
            this.setStatus(0);
          }
        }
        break;
      case 166:
        if (!this.matValid(arg1)) this.setStatus(16); else {
          const rows = this.data[arg1 + 5] | 0;
          const cols = this.data[arg1 + 6] | 0;
          for (let r = 0; r < rows; r++) {
            let line = "[";
            for (let c = 0; c < cols; c++) {
              const idx = this.matCellIndex(arg1, r, c);
              if (c > 0) line += " ";
              line += String(this.toSignedCell(this.data[idx] ?? 0));
            }
            this.output += line + "]\n";
          }
          this.setStatus(0);
        }
        break;
      case 167:
      case 168:
        if (!this.matValid(arg1) || !this.matValid(arg2) || !this.matValid(arg0)) this.setStatus(16); else {
          const n = this.data[arg1 + 10] | 0;
          if ((this.data[arg2 + 10] | 0) !== n || (this.data[arg0 + 10] | 0) !== n) this.setStatus(16); else {
            for (let i = 0; i < n; i++) {
              const lv = this.toSignedCell(this.data[arg2 + 16 + i] ?? 0);
              const rv = this.toSignedCell(this.data[arg0 + 16 + i] ?? 0);
              this.data[arg1 + 16 + i] = (id === 167 ? lv + rv : lv - rv) & this.mask();
            }
            this.setStatus(0);
          }
        }
        break;
      case 169:
        if (!this.matValid(arg1) || !this.matValid(arg2)) this.setStatus(16); else {
          const n = this.data[arg1 + 10] | 0;
          if ((this.data[arg2 + 10] | 0) !== n) this.setStatus(16); else {
            const s = this.toSignedCell(arg0);
            for (let i = 0; i < n; i++) this.data[arg1 + 16 + i] = (this.toSignedCell(this.data[arg2 + 16 + i] ?? 0) * s) & this.mask();
            this.setStatus(0);
          }
        }
        break;
      case 170:
        if (!this.matValid(arg1) || !this.matValid(arg2) || !this.matValid(arg0)) this.setStatus(16); else {
          const ar = this.data[arg2 + 5] | 0; const ac = this.data[arg2 + 6] | 0;
          const br = this.data[arg0 + 5] | 0; const bc = this.data[arg0 + 6] | 0;
          if (ac !== br || (this.data[arg1 + 5] | 0) !== ar || (this.data[arg1 + 6] | 0) !== bc) this.setStatus(16); else {
            for (let r = 0; r < ar; r++) for (let c = 0; c < bc; c++) {
              let acc = 0;
              for (let k = 0; k < ac; k++) {
                const ia = this.matCellIndex(arg2, r, k), ib = this.matCellIndex(arg0, k, c);
                acc += this.toSignedCell(this.data[ia] ?? 0) * this.toSignedCell(this.data[ib] ?? 0);
              }
              const io = this.matCellIndex(arg1, r, c);
              this.data[io] = acc & this.mask();
            }
            this.setStatus(0);
          }
        }
        break;
      case 171:
        if (!this.matValid(arg1) || !this.matValid(arg2)) this.setStatus(16); else {
          const rs = this.data[arg2 + 5] | 0; const cs = this.data[arg2 + 6] | 0;
          if ((this.data[arg1 + 5] | 0) !== cs || (this.data[arg1 + 6] | 0) !== rs) this.setStatus(16); else {
            for (let r = 0; r < rs; r++) for (let c = 0; c < cs; c++) {
              const s = this.matCellIndex(arg2, r, c), d = this.matCellIndex(arg1, c, r);
              this.data[d] = this.data[s] ?? 0;
            }
            this.setStatus(0);
          }
        }
        break;
      case 172:
        if (!this.matInit(arg1, arg2, arg2, 0, 0)) this.setStatus(16); else {
          for (let i = 0; i < arg2; i++) {
            const idx = this.matCellIndex(arg1, i, i);
            if (idx >= 0) this.data[idx] = 1;
          }
          this.setStatus(0);
        }
        break;
      case 173:
        if (!this.matValid(arg1) || (this.data[arg1 + 5] | 0) !== (this.data[arg1 + 6] | 0)) this.setStatus(16); else {
          const n = this.data[arg1 + 5] | 0;
          let tr = 0;
          for (let i = 0; i < n; i++) {
            const idx = this.matCellIndex(arg1, i, i);
            tr += this.toSignedCell(this.data[idx] ?? 0);
          }
          result = tr;
        }
        break;
      case 174:
        if (!this.matValid(arg1) || (this.data[arg1 + 5] | 0) !== 2 || (this.data[arg1 + 6] | 0) !== 2) this.setStatus(16); else {
          const m00 = this.toSignedCell(this.data[this.matCellIndex(arg1, 0, 0)] ?? 0);
          const m01 = this.toSignedCell(this.data[this.matCellIndex(arg1, 0, 1)] ?? 0);
          const m10 = this.toSignedCell(this.data[this.matCellIndex(arg1, 1, 0)] ?? 0);
          const m11 = this.toSignedCell(this.data[this.matCellIndex(arg1, 1, 1)] ?? 0);
          result = m00 * m11 - m01 * m10;
        }
        break;
      case 175:
        if (!this.matValid(arg1)) this.setStatus(16); else { this.output += `${this.data[arg1 + 5] | 0}x${this.data[arg1 + 6] | 0}`; this.setStatus(0); }
        break;
      case 176:
        if (!this.matValid(arg1)) this.setStatus(16); else {
          const n = this.data[arg1 + 10] | 0;
          let s = "";
          for (let i = 0; i < n; i++) { if (i) s += " "; s += String(this.toSignedCell(this.data[arg1 + 16 + i] ?? 0)); }
          this.output += s;
          this.setStatus(0);
        }
        break;
      case 200:
      case 201:
        this.fpWriteScaled(arg1, 0);
        if (arg1 + 1 < this.data.length) this.data[arg1 + 1] = id === 201 ? 32 : 16;
        this.setStatus(0);
        break;
      case 202: this.fpWriteScaled(arg1, 0); this.setStatus(0); break;
      case 203: this.fpWriteScaled(arg1, this.fpReadScaled(arg2)); this.setStatus(0); break;
      case 204:
        if (arg1 + 2 >= this.data.length) this.setStatus(16);
        else { this.data[arg1 + 2] = this.fpReadScaled(arg1) & this.mask(); this.setStatus(0); }
        break;
      case 205:
        result = Math.trunc(this.fpReadScaled(arg1) / this.fpScaleConst());
        break;
      case 206:
        result = this.fpReadScaled(arg1) === 0 ? 1 : 0;
        break;
      case 207:
        if (this.fpReadScaled(arg1) === 0) result = 0;
        else if (this.fpReadScaled(arg1) < 0) result = this.mask();
        else result = 1;
        break;
      case 208:
        result = Math.abs(Math.trunc(this.fpReadScaled(arg1) / this.fpScaleConst()));
        break;
      case 209:
        this.output += `FP RAW base=${arg1} v=${this.fpReadScaled(arg1)}`;
        this.setStatus(0);
        break;
      case 210: this.fpWriteScaled(arg1, this.fpReadScaled(arg2) + this.fpReadScaled(arg0)); this.setStatus(0); break;
      case 211: this.fpWriteScaled(arg1, this.fpReadScaled(arg2) - this.fpReadScaled(arg0)); this.setStatus(0); break;
      case 212: this.fpWriteScaled(arg1, Math.trunc((this.fpReadScaled(arg2) * this.fpReadScaled(arg0)) / this.fpScaleConst())); this.setStatus(0); break;
      case 213:
        if (this.fpReadScaled(arg0) === 0) { this.setStatus(15); }
        else { this.fpWriteScaled(arg1, Math.trunc((this.fpReadScaled(arg2) * this.fpScaleConst()) / this.fpReadScaled(arg0))); this.setStatus(0); }
        break;
      case 214:
        if (this.fpReadScaled(arg2) === this.fpReadScaled(arg0)) result = 0;
        else if (this.fpReadScaled(arg2) > this.fpReadScaled(arg0)) result = 1;
        else result = this.mask();
        break;
      case 215: this.fpWriteScaled(arg1, Math.abs(this.fpReadScaled(arg2))); this.setStatus(0); break;
      case 216: this.fpWriteScaled(arg1, -this.fpReadScaled(arg2)); this.setStatus(0); break;
      case 217: this.fpWriteScaled(arg1, this.fpReadScaled(arg1)); this.setStatus(0); break;
      case 218: this.fpWriteScaled(arg1, this.fpReadScaled(arg1)); this.setStatus(0); break;
      case 219: this.fpWriteScaled(arg1, Math.trunc(this.fpReadScaled(arg1) / this.fpScaleConst()) * this.fpScaleConst()); this.setStatus(0); break;
      case 220: this.fpWriteScaled(arg1, this.toSignedCell(arg2) * this.fpScaleConst()); this.setStatus(0); break;
      case 221: this.fpWriteScaled(arg1, Math.trunc(Number(this.readDataString(arg2)) * this.fpScaleConst())); this.setStatus(0); break;
      case 222: this.writeDataString(arg2, String(this.fpReadScaled(arg1) / this.fpScaleConst())); this.setStatus(0); break;
      case 223: this.output += String(this.fpReadScaled(arg2) / this.fpScaleConst()); this.setStatus(0); break;
      case 224: this.fpWriteScaled(arg1, this.fpReadScaled(arg1) * Math.trunc(Math.pow(10, arg2))); this.setStatus(0); break;
      case 230:
      case 231:
      case 232:
      case 233:
      case 234:
        this.setStatus(5);
        break;
      case 240: {
        if ((this.data[arg2] ?? 0) !== 80) { this.setStatus(16); break; }
        const deg = this.data[arg2 + 2] | 0;
        this.data[arg1 + 0] = 80; this.data[arg1 + 1] = 1; this.data[arg1 + 3] = this.data[arg2 + 3] ?? 0;
        if (deg <= 0) { this.data[arg1 + 2] = 0; this.data[arg1 + 4] = 0; this.setStatus(0); break; }
        this.data[arg1 + 2] = deg - 1;
        for (let i = 1; i <= deg; i++) this.data[arg1 + 3 + i] = (this.toSignedCell(this.data[arg2 + 4 + i] ?? 0) * i) & this.mask();
        this.setStatus(0);
      } break;
      case 241: {
        if ((this.data[arg2] ?? 0) !== 80) { this.setStatus(16); break; }
        const deg = this.data[arg2 + 2] | 0;
        this.data[arg1 + 0] = 80; this.data[arg1 + 1] = 1; this.data[arg1 + 2] = deg + 1; this.data[arg1 + 3] = this.data[arg2 + 3] ?? 0;
        this.data[arg1 + 4] = arg0 & this.mask();
        for (let i = 0; i <= deg; i++) this.data[arg1 + 5 + i] = Math.trunc(this.toSignedCell(this.data[arg2 + 4 + i] ?? 0) / (i + 1)) & this.mask();
        this.setStatus(0);
      } break;
      case 242: {
        if ((this.data[arg1] ?? 0) !== 80) { this.setStatus(16); break; }
        const deg = this.data[arg1 + 2] | 0;
        let acc = 0;
        for (let i = deg; i >= 0; i--) acc = acc * this.toSignedCell(arg2) + this.toSignedCell(this.data[arg1 + 4 + i] ?? 0);
        result = acc;
      } break;
      case 243: {
        if ((this.data[arg1] ?? 0) !== 80) { this.setStatus(16); break; }
        const deg = this.data[arg1 + 2] | 0;
        let out = "";
        for (let i = 0; i <= deg; i++) {
          if (i > 0) out += " + ";
          out += String(this.toSignedCell(this.data[arg1 + 4 + i] ?? 0));
          if (i > 0) out += "x";
          if (i > 1) out += `^${i}`;
        }
        this.output += out;
        this.setStatus(0);
      } break;
      case 244:
        for (let i = 0; i < arg2; i++) if (arg1 + i < this.data.length) this.data[arg1 + i] = 0;
        this.setStatus(0);
        break;
      case 245:
        if ((this.data[arg1] ?? 0) !== 80) this.setStatus(16);
        else result = this.data[arg1 + 2] ?? 0;
        break;
      case 246:
        if ((this.data[arg1] ?? 0) !== 80) this.setStatus(16);
        else result = this.data[arg1 + 3] ?? 0;
        break;
      case 247:
        if ((this.data[arg1] ?? 0) !== 80) this.setStatus(16);
        else { this.output += `POLY@${arg1} deg=${this.data[arg1 + 2] ?? 0}`; this.setStatus(0); }
        break;
      case 248:
        if ((this.data[arg1] ?? 0) !== 69) this.setStatus(16);
        else result = this.data[arg1 + 2] ?? 0;
        break;
      case 249:
        if ((this.data[arg1] ?? 0) !== 69) this.setStatus(16);
        else { this.output += `EXPR@${arg1} tok=${this.data[arg1 + 2] ?? 0}`; this.setStatus(0); }
        break;
      case 250:
        result = this.exprEvalRpn(arg1, this.toSignedCell(arg2));
        break;
      case 251: {
        let h = this.toSignedCell(arg0);
        if (h === 0) h = 1;
        const f1 = this.exprEvalRpn(arg1, this.toSignedCell(arg2) + h);
        const f2 = this.exprEvalRpn(arg1, this.toSignedCell(arg2) - h);
        result = Math.trunc((f1 - f2) / (2 * h));
      } break;
      case 252: {
        const a = this.toSignedCell(arg2); const b = this.toSignedCell(arg0); const n = 16;
        const h = (b - a) / n;
        let sum = 0;
        for (let i = 0; i <= n; i++) {
          const x = a + i * h;
          if (i === 0 || i === n) sum += this.exprEvalRpn(arg1, Math.trunc(x));
          else sum += 2 * this.exprEvalRpn(arg1, Math.trunc(x));
        }
        result = Math.trunc((sum * h) / 2);
      } break;
      case 253: {
        const a = this.toSignedCell(arg2); const b = this.toSignedCell(arg0); const n = 16;
        const h = (b - a) / n;
        let sum = this.exprEvalRpn(arg1, a) + this.exprEvalRpn(arg1, b);
        for (let i = 1; i < n; i++) {
          const x = a + i * h;
          if ((i % 2) === 0) sum += 2 * this.exprEvalRpn(arg1, Math.trunc(x));
          else sum += 4 * this.exprEvalRpn(arg1, Math.trunc(x));
        }
        result = Math.trunc((sum * h) / 3);
      } break;
      case 254:
        this.output += `[RPN @${arg1}]`;
        this.setStatus(0);
        break;
      default: this.markUnsupportedMeta(id, "meta servis tanimli degil veya internal yorumlayicida henuz uygulanmadi"); break;
    }
    if (result !== undefined) {
      this.writeTape(this.ptr + 1, result);
      if (!preserveStatusAfterWrite) {
        this.setStatus(this.status === 15 ? 15 : 0);
      }
    }
  }

  private markUnsupportedMeta(id: number, reason: string): void {
    this.setStatus(5);
    if (this.unsupportedMetaReported.has(id)) {
      return;
    }
    const info = META_SERVICES[id];
    if (info) {
      this.diagnostics.push(`@${id} ${info.name}: bilincli desteklenmiyor (${reason}).`);
    } else {
      this.diagnostics.push(`@${id}: bilincli desteklenmiyor (${reason}).`);
    }
    this.unsupportedMetaReported.add(id);
  }

  private copy(mem: number[], src: number, dst: number, count: number): void { for (let i = 0; i < count; i++) { mem[dst + i] = mem[src + i] ?? 0; } this.setStatus(0); }
  private clear(mem: number[], dst: number, count: number): void { for (let i = 0; i < count; i++) { mem[dst + i] = 0; } this.setStatus(0); }
  private sort(mem: number[], start: number, count: number, asc: boolean): void { const part = mem.slice(start, start + count).sort((a, b) => asc ? a - b : b - a); for (let i = 0; i < part.length; i++) { mem[start + i] = part[i]; } this.setStatus(0); }
  private search(mem: number[], start: number, count: number, target: number): number { for (let i = 0; i < count; i++) { if (mem[start + i] === target) { return i; } } return this.mask(); }
  private toSignedCell(v: number): number {
    const masked = v & this.mask();
    if (this.cellBits === 8 && (masked & 0x80)) return masked - 0x100;
    if (this.cellBits === 16 && (masked & 0x8000)) return masked - 0x10000;
    if (this.cellBits === 32 && (masked & 0x80000000)) return masked - 0x100000000;
    return masked;
  }

  private matValid(base: number): boolean {
    return base >= 0 && base + 15 < this.data.length && this.data[base + 0] === 77 && this.data[base + 1] === 1 && this.data[base + 2] === 2;
  }

  private matCellIndex(base: number, r: number, c: number): number {
    if (!this.matValid(base)) return -1;
    const rows = this.data[base + 5] | 0;
    const cols = this.data[base + 6] | 0;
    if (r < 0 || c < 0 || r >= rows || c >= cols) return -1;
    const idx = base + (this.data[base + 9] | 0) + r * (this.data[base + 12] | 0) + c * (this.data[base + 13] | 0);
    if (idx < 0 || idx >= this.data.length) return -1;
    return idx;
  }

  private matInit(base: number, rows: number, cols: number, typ: number, scale: number): boolean {
    if (base < 0 || rows <= 0 || cols <= 0) return false;
    const total = rows * cols;
    if (base + 16 + total - 1 >= this.data.length) return false;
    const flags = typ === 1 ? 1 : typ === 2 ? 2 : 0;
    this.data[base + 0] = 77;
    this.data[base + 1] = 1;
    this.data[base + 2] = 2;
    this.data[base + 3] = typ;
    this.data[base + 4] = flags;
    this.data[base + 5] = rows;
    this.data[base + 6] = cols;
    this.data[base + 7] = scale;
    this.data[base + 8] = 1;
    this.data[base + 9] = 16;
    this.data[base + 10] = total;
    this.data[base + 11] = 16 + total;
    this.data[base + 12] = cols;
    this.data[base + 13] = 1;
    this.data[base + 14] = 0;
    this.data[base + 15] = 0;
    for (let i = 0; i < total; i++) this.data[base + 16 + i] = 0;
    return true;
  }

  private fpScaleConst(): number { return 1_000_000; }
  private fpReadScaled(base: number): number { return this.toSignedCell(this.data[base] ?? 0); }
  private fpWriteScaled(base: number, v: number): void { if (base >= 0 && base < this.data.length) this.data[base] = v & this.mask(); }

  private readDataString(start: number): string {
    let s = "";
    for (let i = start; i < this.data.length; i++) {
      const ch = (this.data[i] ?? 0) & 0xff;
      if (ch === 0) break;
      s += String.fromCharCode(ch);
    }
    return s;
  }

  private writeDataString(start: number, s: string): void {
    for (let i = 0; i < s.length && start + i < this.data.length; i++) this.data[start + i] = s.charCodeAt(i) & this.mask();
    if (start + s.length < this.data.length) this.data[start + s.length] = 0;
  }

  private exprEvalRpn(exprBase: number, x: number): number {
    if (exprBase < 0 || exprBase + 4 >= this.data.length) return 0;
    if ((this.data[exprBase] ?? 0) !== 69) return 0;
    const count = this.data[exprBase + 2] | 0;
    let ip = exprBase + 4;
    const st: number[] = [];
    while (ip < exprBase + 4 + count && ip < this.data.length) {
      const tok = this.toSignedCell(this.data[ip++] ?? 0);
      if (tok === 1) { st.push(this.toSignedCell(this.data[ip++] ?? 0)); continue; }
      if (tok === 2) { st.push(x); continue; }
      if (tok === 10 || tok === 11 || tok === 12 || tok === 13 || tok === 14) {
        if (st.length < 2) return 0;
        const b = st.pop()!;
        const a = st.pop()!;
        if (tok === 10) st.push(a + b);
        else if (tok === 11) st.push(a - b);
        else if (tok === 12) st.push(a * b);
        else if (tok === 13) st.push(b === 0 ? 0 : Math.trunc(a / b));
        else st.push(Math.trunc(Math.pow(a, b)));
        continue;
      }
      if (tok === 20 || tok === 21 || tok === 22 || tok === 23 || tok === 24 || tok === 25 || tok === 30 || tok === 31) {
        if (st.length < 1) return 0;
        const a = st.pop()!;
        if (tok === 20) st.push(Math.trunc(Math.sin(a)));
        else if (tok === 21) st.push(Math.trunc(Math.cos(a)));
        else if (tok === 22) st.push(Math.trunc(Math.tan(a)));
        else if (tok === 23) st.push(Math.trunc(Math.exp(a)));
        else if (tok === 24) st.push(a <= 0 ? 0 : Math.trunc(Math.log(a)));
        else if (tok === 25) st.push(a < 0 ? 0 : Math.trunc(Math.sqrt(a)));
        else if (tok === 30) st.push(-a);
        else st.push(Math.abs(a));
        continue;
      }
      if (tok === 99) break;
    }
    return st.length ? st[st.length - 1] : 0;
  }

  private changeLayout(tapeKB: number, stackKB: number, dataKB: number): void {
    if ((this.flags & 0x40) === 0) { this.setStatus(23); return; }
    if (tapeKB + stackKB + dataKB !== 64) { this.setStatus(16); return; }
    this.tapeKB = tapeKB; this.stackKB = stackKB; this.dataKB = dataKB;
    const oldTape = this.tape.slice(); const oldData = this.data.slice(); const oldStack = this.stack.slice();
    this.applyMemory();
    for (let i = 0; i < Math.min(oldTape.length, this.tape.length); i++) { this.tape[i] = oldTape[i]; }
    for (let i = 0; i < Math.min(oldData.length, this.data.length); i++) { this.data[i] = oldData[i]; }
    for (let i = 0; i < Math.min(oldStack.length, this.stack.length); i++) { this.stack[i] = oldStack[i]; }
    this.setStatus(0);
  }

  private makeEvent(ip: number, ins: Instr): TraceEvent {
    this.step++;
    return {
      step: this.step,
      ip: ip + 1,
      op: ins.op,
      src: ins.text,
      ptr: this.ptr,
      sp: this.sp,
      fifo_count: this.fifo.length,
      status: this.status,
      flags: this.flags,
      current: this.tape[this.ptr] ?? 0,
      meta_id: ins.metaId,
      tape: this.window(this.tape, Math.max(0, this.ptr - 8), 17),
      stack: this.window(this.stack, Math.max(0, this.sp - 12), 12),
      fifo: this.fifo.slice(0, 16).map((value, index) => ({ index, value, ascii: ascii(value) })),
      data: this.nonZero(this.data, 32),
      output: this.output
    };
  }

  private window(mem: number[], start: number, count: number): CellEntry[] {
    const out: CellEntry[] = [];
    for (let i = 0; i < count && start + i < mem.length; i++) {
      const value = mem[start + i] ?? 0;
      out.push({ index: start + i, value, ascii: ascii(value) });
    }
    return out;
  }

  private nonZero(mem: number[], limit: number): CellEntry[] {
    const out: CellEntry[] = [];
    for (let i = 0; i < mem.length && out.length < limit; i++) {
      const value = mem[i] ?? 0;
      if (value !== 0) { out.push({ index: i, value, ascii: ascii(value) }); }
    }
    return out;
  }

  private printString(id: number): void { const s = this.strings.get(id); if (s) { this.output += s.text; } else { this.setStatus(5); } }
  private push(v: number): void { if (this.sp >= this.stack.length) { this.setStatus(11); return; } this.stack[this.sp++] = v & this.mask(); }
  private pop(): number { if (this.sp <= 0) { this.setStatus(12); return 0; } return this.stack[--this.sp] ?? 0; }

  private readAddr(addr: Address): number { const r = this.resolve(addr); if (!r) { return 0; } const [space, idx] = r; if (space === "T") { return this.readTape(idx); } if (space === "D") { return this.data[idx] ?? 0; } if (space === "S") { return this.stack[idx] ?? 0; } if (space === "P") { return this.ptr; } if (space === "E") { return this.status; } if (space === "F") { return this.flags; } return 0; }
  private writeAddr(addr: Address, value: number): void { const r = this.resolve(addr); if (!r) { return; } const [space, idx] = r; const v = value & this.mask(); if (space === "T") { this.writeTape(idx, v); } if (space === "D") { this.data[idx] = v; } if (space === "S") { this.stack[idx] = v; } if (space === "P") { this.ptr = v; } if (space === "E") { this.setStatus(v); } if (space === "F") { this.flags = v; } this.setZS(v); }
  private resolve(addr: Address): [SpaceName, number] | undefined {
    let idx = 0;
    let out: [SpaceName, number] | undefined;
    switch (addr.kind) {
      case "T": out = ["T", this.ptr]; break;
      case "T_REL": out = ["T", this.ptr + addr.value]; break;
      case "T_ABS": out = ["T", addr.value]; break;
      case "D_ABS": out = ["D", addr.value]; break;
      case "S_ABS": out = ["S", addr.value]; break;
      case "SP": out = ["S", Math.max(0, this.sp - 1)]; break;
      case "P": out = ["P", 0]; break;
      case "E": out = ["E", 0]; break;
      case "F": out = ["F", 0]; break;
      case "IND_T": idx = this.readTape(this.ptr); out = ["T", idx]; break;
      case "IND_T_REL": idx = this.readTape(this.ptr + addr.value); out = ["T", idx]; break;
      case "D_AT_T_REL": idx = this.readTape(this.ptr) + (addr.value2 ?? 0); out = ["D", idx]; break;
      case "D_AT_TBASE_REL": idx = this.readTape(this.ptr + addr.value) + (addr.value2 ?? 0); out = ["D", idx]; break;
    }
    if (!out) { return undefined; }
    const [space, index] = out;
    if (space === "T" && (index < 0 || index >= this.tape.length)) { this.setStatus(10); return undefined; }
    if (space === "D" && (index < 0 || index >= this.data.length)) { this.setStatus(16); return undefined; }
    if (space === "S" && (index < 0 || index >= this.stack.length)) { this.setStatus(12); return undefined; }
    return out;
  }

  private readTape(i: number): number { if (i < 0 || i >= this.tape.length) { this.setStatus(10); return 0; } return this.tape[i] ?? 0; }
  private writeTape(i: number, value: number): void { if (i < 0 || i >= this.tape.length) { this.setStatus(10); return; } this.tape[i] = value & this.mask(); this.setZS(this.tape[i]); }
  private boundsPtr(): void { if (this.ptr < 0 || this.ptr >= this.tape.length) { this.setStatus(10); this.ptr = Math.max(0, Math.min(this.tape.length - 1, this.ptr)); } }
  private setStatus(code: number): void { this.status = code & 0xff; if (this.status === 0) { this.flags &= ~0x400; } else { this.flags |= 0x400; } }
  private setZS(v: number): void { this.flags &= ~(1 | 8); const x = v & this.mask(); if (x === 0) { this.flags |= 1; } if ((x & this.signBit()) !== 0) { this.flags |= 8; } }
  private mask(): number { return this.cellBits === 8 ? 0xff : this.cellBits === 16 ? 0xffff : 0xffffffff; }
  private rngSeed(seed: number): void { this.rngState = seed >>> 0; }
  private rngNext(): number { this.rngState = (Math.imul(1664525, this.rngState) + 1013904223) >>> 0; return this.rngState / 4294967296; }
  private signBit(): number { return this.cellBits === 8 ? 0x80 : this.cellBits === 16 ? 0x8000 : 0x80000000; }
  private scale(): number { return this.cellBits === 8 ? 100 : this.cellBits === 16 ? 1000 : 10000; }
  private unescape(s: string): string { return s.replace(/\\n/g, "\n").replace(/\\r/g, "\r").replace(/\\t/g, "\t").replace(/\\\{/g, "{").replace(/\\\}/g, "}").replace(/\\\\/g, "\\"); }
}
