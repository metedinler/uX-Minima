"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildUnsupportedMetaMessage = buildUnsupportedMetaMessage;
const metaServices_1 = require("../metaServices");
function buildUnsupportedMetaMessage(id, reason) {
    const info = metaServices_1.META_SERVICES[id];
    if (info) {
        return `@${id} ${info.name}: bilincli desteklenmiyor (${reason}).`;
    }
    return `@${id}: bilincli desteklenmiyor (${reason}).`;
}
//# sourceMappingURL=metaRuntime.js.map