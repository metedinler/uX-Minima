import * as fs from "fs";

export interface CellEntry {
  index: number;
  value: number;
  ascii?: string;
}

export interface TraceEvent {
  step: number;
  ip: number;
  op: string;
  src?: string;
  ptr: number;
  sp: number;
  fifo_count: number;
  status: number;
  flags: number;
  current: number;
  char?: number;
  meta_id?: number;
  taken?: number;
  target?: number;
  tape?: CellEntry[];
  stack?: CellEntry[];
  fifo?: CellEntry[];
  data?: CellEntry[];
  output?: string;
}

export interface TraceFile {
  snapshot?: Record<string, unknown>;
  events: TraceEvent[];
}

export function readTraceFile(filePath: string): TraceFile {
  const text = fs.readFileSync(filePath, "utf8");
  const events: TraceEvent[] = [];
  let snapshot: Record<string, unknown> | undefined;
  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line) { continue; }
    try {
      const obj = JSON.parse(line);
      if (obj.type === "snapshot") {
        snapshot = obj;
      } else if (typeof obj.step === "number") {
        events.push(obj as TraceEvent);
      }
    } catch {
      // Eski veya bozuk satırları atla; panel kalan geçerli satırlarla çalışsın.
    }
  }
  return { snapshot, events };
}

export function ascii(value: number): string {
  if (value >= 32 && value <= 126) {
    return String.fromCharCode(value);
  }
  if (value === 10) { return "\\n"; }
  if (value === 13) { return "\\r"; }
  if (value === 9) { return "\\t"; }
  return "";
}
