"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cellMaskForBits = cellMaskForBits;
exports.signBitForBits = signBitForBits;
exports.scaleForBits = scaleForBits;
function cellMaskForBits(cellBits) {
    if (cellBits === 8)
        return 0xff;
    if (cellBits === 16)
        return 0xffff;
    return 0xffffffff;
}
function signBitForBits(cellBits) {
    if (cellBits === 8)
        return 0x80;
    if (cellBits === 16)
        return 0x8000;
    return 0x80000000;
}
function scaleForBits(cellBits) {
    if (cellBits === 8)
        return 100;
    if (cellBits === 16)
        return 1000;
    return 10000;
}
//# sourceMappingURL=memory.js.map