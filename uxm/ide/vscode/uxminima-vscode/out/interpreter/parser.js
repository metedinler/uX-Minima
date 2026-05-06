"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.stripDefinitionsText = stripDefinitionsText;
function stripDefinitionsText(source) {
    return source
        .replace(/\bs[0-9]+\s*=\s*[0-9]+\s*,\s*\{[\s\S]*?\}/g, "")
        .replace(/\bm[0-9]+\s*=\s*\{[\s\S]*?\}/g, "");
}
//# sourceMappingURL=parser.js.map