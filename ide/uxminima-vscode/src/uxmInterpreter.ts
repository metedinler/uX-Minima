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
      case "META": this.meta(ins.metaDyn ? this.tape[this.ptr] : (ins.metaId ?? 0)); return ip + 1;
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

  private meta(id: number): void {
    if (id >= 128 && id <= 255) { this.setStatus(5); return; }
    const arg1 = this.readTape(this.ptr - 2);
    const arg2 = this.readTape(this.ptr - 1);
    const arg0 = this.readTape(this.ptr);
    let result: number | undefined;
    switch (id) {
      case 0: this.setStatus(0); break;
      case 3: result = Math.floor(Math.random() * 256); break;
      case 5: this.output += "\n"; this.setStatus(0); break;
      case 9: result = this.status; break;
      case 10: this.setStatus(0); break;
      case 20: result = arg1 + arg2; break;
      case 21: result = arg1 - arg2; break;
      case 22: result = arg1 * arg2; break;
      case 23: if (arg2 === 0) { result = 0; this.setStatus(15); } else { result = Math.floor(arg1 / arg2); } break;
      case 24: if (arg2 === 0) { result = 0; this.setStatus(15); } else { result = arg1 % arg2; } break;
      case 40: result = Math.round(Math.sin(arg2 * Math.PI / 180) * this.scale()); break;
      case 41: result = Math.round(Math.cos(arg2 * Math.PI / 180) * this.scale()); break;
      case 42: result = Math.round(Math.tan(arg2 * Math.PI / 180) * this.scale()); break;
      case 43: result = Math.round(Math.sqrt(arg1 * arg1 + arg2 * arg2)); break;
      case 60: this.output += String(arg2); this.setStatus(0); break;
      case 61: this.output += String(this.readTape(this.ptr + 1)); this.setStatus(0); break;
      case 64: this.output += " "; this.setStatus(0); break;
      case 80: this.ptr = arg2; this.boundsPtr(); this.flags |= 0x1000; break;
      case 82: result = this.ptr; break;
      case 84: result = this.tape.length; break;
      case 85: result = this.data.length; break;
      case 86: result = this.stack.length; break;
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
      default: this.setStatus(5); break;
    }
    if (result !== undefined) { this.writeTape(this.ptr + 1, result); this.setStatus(this.status === 15 ? 15 : 0); }
  }

  private copy(mem: number[], src: number, dst: number, count: number): void { for (let i = 0; i < count; i++) { mem[dst + i] = mem[src + i] ?? 0; } this.setStatus(0); }
  private clear(mem: number[], dst: number, count: number): void { for (let i = 0; i < count; i++) { mem[dst + i] = 0; } this.setStatus(0); }
  private sort(mem: number[], start: number, count: number, asc: boolean): void { const part = mem.slice(start, start + count).sort((a, b) => asc ? a - b : b - a); for (let i = 0; i < part.length; i++) { mem[start + i] = part[i]; } this.setStatus(0); }
  private search(mem: number[], start: number, count: number, target: number): number { for (let i = 0; i < count; i++) { if (mem[start + i] === target) { return i; } } return this.mask(); }

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
  private signBit(): number { return this.cellBits === 8 ? 0x80 : this.cellBits === 16 ? 0x8000 : 0x80000000; }
  private scale(): number { return this.cellBits === 8 ? 100 : this.cellBits === 16 ? 1000 : 10000; }
  private unescape(s: string): string { return s.replace(/\\n/g, "\n").replace(/\\r/g, "\r").replace(/\\t/g, "\t").replace(/\\\{/g, "{").replace(/\\\}/g, "}").replace(/\\\\/g, "\\"); }
}
