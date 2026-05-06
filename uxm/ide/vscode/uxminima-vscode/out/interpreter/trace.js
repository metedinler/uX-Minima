"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.collectWindow = collectWindow;
exports.collectNonZero = collectNonZero;
function collectWindow(mem, start, count, asciiFn) {
    const out = [];
    for (let i = 0; i < count && start + i < mem.length; i++) {
        const value = mem[start + i] ?? 0;
        out.push({ index: start + i, value, ascii: asciiFn(value) });
    }
    return out;
}
function collectNonZero(mem, limit, asciiFn) {
    const out = [];
    for (let i = 0; i < mem.length && out.length < limit; i++) {
        const value = mem[i] ?? 0;
        if (value !== 0) {
            out.push({ index: i, value, ascii: asciiFn(value) });
        }
    }
    return out;
}
//# sourceMappingURL=trace.js.map