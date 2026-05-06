export function stripDefinitionsText(source: string): string {
  return source
    .replace(/\bs[0-9]+\s*=\s*[0-9]+\s*,\s*\{[\s\S]*?\}/g, "")
    .replace(/\bm[0-9]+\s*=\s*\{[\s\S]*?\}/g, "");
}
