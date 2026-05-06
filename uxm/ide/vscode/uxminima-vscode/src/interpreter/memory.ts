export function cellMaskForBits(cellBits: number): number {
  if (cellBits === 8) return 0xff;
  if (cellBits === 16) return 0xffff;
  return 0xffffffff;
}

export function signBitForBits(cellBits: number): number {
  if (cellBits === 8) return 0x80;
  if (cellBits === 16) return 0x8000;
  return 0x80000000;
}

export function scaleForBits(cellBits: number): number {
  if (cellBits === 8) return 100;
  if (cellBits === 16) return 1000;
  return 10000;
}
