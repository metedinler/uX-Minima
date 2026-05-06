import type { CellEntry } from "../traceReader";

export function collectWindow(
  mem: number[],
  start: number,
  count: number,
  asciiFn: (value: number) => string
): CellEntry[] {
  const out: CellEntry[] = [];
  for (let i = 0; i < count && start + i < mem.length; i++) {
    const value = mem[start + i] ?? 0;
    out.push({ index: start + i, value, ascii: asciiFn(value) });
  }
  return out;
}

export function collectNonZero(
  mem: number[],
  limit: number,
  asciiFn: (value: number) => string
): CellEntry[] {
  const out: CellEntry[] = [];
  for (let i = 0; i < mem.length && out.length < limit; i++) {
    const value = mem[i] ?? 0;
    if (value !== 0) {
      out.push({ index: i, value, ascii: asciiFn(value) });
    }
  }
  return out;
}
