import { META_SERVICES } from "../metaServices";

export function buildUnsupportedMetaMessage(id: number, reason: string): string {
  const info = META_SERVICES[id];
  if (info) {
    return `@${id} ${info.name}: bilincli desteklenmiyor (${reason}).`;
  }
  return `@${id}: bilincli desteklenmiyor (${reason}).`;
}
