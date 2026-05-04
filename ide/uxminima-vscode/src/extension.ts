import * as vscode from "vscode";
import * as fs from "fs";
import * as path from "path";
import { UxmDiagnostics } from "./diagnostics";
import { UxmToolchain } from "./toolchain";
import { readTraceFile, TraceFile } from "./traceReader";
import { MemoryViewPanel } from "./views/memoryView";
import { UxmInterpreter } from "./uxmInterpreter";
import { metaMarkdown, META_SERVICES } from "./metaServices";

let lastTrace: TraceFile | undefined;
let output: vscode.OutputChannel;
let diagnostics: UxmDiagnostics;
let toolchain: UxmToolchain;

export function activate(context: vscode.ExtensionContext): void {
  output = vscode.window.createOutputChannel("UX-MINIMA");
  diagnostics = new UxmDiagnostics(context);
  toolchain = new UxmToolchain(output, context);
  context.subscriptions.push(output);

  for (const doc of vscode.workspace.textDocuments) {
    diagnostics.validate(doc);
  }

  context.subscriptions.push(vscode.workspace.onDidOpenTextDocument((doc: vscode.TextDocument) => diagnostics.validate(doc)));
  context.subscriptions.push(vscode.workspace.onDidChangeTextDocument((e: vscode.TextDocumentChangeEvent) => diagnostics.validate(e.document)));
  context.subscriptions.push(vscode.workspace.onDidCloseTextDocument((doc: vscode.TextDocument) => diagnostics.clear(doc.uri)));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.validateFile", () => {
    const doc = activeUxmDocument();
    if (!doc) { return; }
    diagnostics.validate(doc);
    vscode.window.showInformationMessage("UX-MINIMA dosyası doğrulandı.");
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.internalTrace", async () => {
    const doc = activeUxmDocument();
    if (!doc) { return; }
    await doc.save();
    const interpreter = new UxmInterpreter();
    const result = interpreter.run(doc.getText());
    lastTrace = { snapshot: { type: "snapshot", source: doc.fileName, engine: "internal-vscode", events: result.events.length }, events: result.events };
    const art = toolchain.artifactsFor(doc.fileName);
    fs.writeFileSync(art.trace, result.events.map(e => JSON.stringify(e)).join("\n"), "utf8");
    output.appendLine(`\n[Internal Trace] ${doc.fileName}`);
    output.appendLine(result.output || "");
    if (result.diagnostics.length) {
      output.appendLine("Diagnostics:");
      for (const d of result.diagnostics) { output.appendLine("- " + d); }
    }
    output.show(true);
    MemoryViewPanel.show(context, lastTrace);
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.finalBuildCompiler", async () => {
    try {
      const exe = await toolchain.buildFinalCompiler();
      vscode.window.showInformationMessage(`Final ARGE compiler üretildi: ${exe}`);
    } catch (err) { vscode.window.showErrorMessage(String(err)); }
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.finalRunAll", async () => {
    await runFinalAndOpen(context, "all");
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.finalRunTrace", async () => {
    await runFinalAndOpen(context, "trace");
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.finalRunStep", async () => {
    await runFinalAndOpen(context, "step");
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.finalCompileAsm", async () => {
    const doc = activeUxmDocument();
    if (!doc) { return; }
    await doc.save();
    try {
      const art = await toolchain.finalCompileAsm(doc.fileName);
      await openIfExists(art.asm, vscode.ViewColumn.Beside);
      vscode.window.showInformationMessage(`ASM üretildi: ${art.asm}`);
    } catch (err) { vscode.window.showErrorMessage(String(err)); }
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.finalExportUIR", async () => {
    const doc = activeUxmDocument();
    if (!doc) { return; }
    await doc.save();
    try {
      const art = await toolchain.finalExportUIR(doc.fileName);
      await openIfExists(art.uir, vscode.ViewColumn.Beside);
    } catch (err) { vscode.window.showErrorMessage(String(err)); }
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.finalExportDiagnostics", async () => {
    const doc = activeUxmDocument();
    if (!doc) { return; }
    await doc.save();
    try {
      const art = await toolchain.finalExportDiagnostics(doc.fileName);
      await openIfExists(art.diag, vscode.ViewColumn.Beside);
    } catch (err) { vscode.window.showErrorMessage(String(err)); }
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.finalExportOPT", async () => {
    const doc = activeUxmDocument();
    if (!doc) { return; }
    await doc.save();
    try {
      const art = await toolchain.finalExportOPT(doc.fileName);
      await openIfExists(art.opt, vscode.ViewColumn.Beside);
    } catch (err) { vscode.window.showErrorMessage(String(err)); }
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.runTrace", async () => {
    const doc = activeUxmDocument();
    if (!doc) { return; }
    await doc.save();
    try {
      const art = await toolchain.runTrace(doc.fileName);
      lastTrace = readTraceFile(art.trace);
      MemoryViewPanel.show(context, lastTrace);
      vscode.window.showInformationMessage(`Trace üretildi: ${art.trace}`);
    } catch (err) { vscode.window.showErrorMessage(String(err)); }
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.exportUIR", async () => {
    const doc = activeUxmDocument();
    if (!doc) { return; }
    await doc.save();
    try {
      const art = await toolchain.exportUIR(doc.fileName);
      await openIfExists(art.uir, vscode.ViewColumn.Beside);
    } catch (err) { vscode.window.showErrorMessage(String(err)); }
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.exportOPT", async () => {
    const doc = activeUxmDocument();
    if (!doc) { return; }
    await doc.save();
    try {
      const art = await toolchain.exportOPT(doc.fileName);
      await openIfExists(art.opt, vscode.ViewColumn.Beside);
    } catch (err) { vscode.window.showErrorMessage(String(err)); }
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.buildNative", async () => {
    const doc = activeUxmDocument();
    if (!doc) { return; }
    await doc.save();
    try {
      const art = await toolchain.buildNative(doc.fileName);
      vscode.window.showInformationMessage(`Native EXE üretildi: ${art.exe}`);
    } catch (err) { vscode.window.showErrorMessage(String(err)); }
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.openMemoryWatch", () => {
    MemoryViewPanel.show(context, lastTrace);
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.openMetaHelp", async () => {
    const doc = await vscode.workspace.openTextDocument({ language: "markdown", content: metaHelpMarkdown() });
    await vscode.window.showTextDocument(doc, { preview: false, viewColumn: vscode.ViewColumn.Beside });
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.openFinalDocs", async () => {
    const docPath = path.join(context.extensionPath, "docs", "UXM31_FINAL_ARGE_COMPILER.md");
    await openIfExists(docPath, vscode.ViewColumn.Beside);
  }));

  context.subscriptions.push(vscode.languages.registerHoverProvider("uxminima", {
    provideHover(document: vscode.TextDocument, position: vscode.Position) {
      const range = document.getWordRangeAtPosition(position, /@#|@![0-9]+|@[0-9]+/);
      if (!range) { return undefined; }
      const token = document.getText(range);
      if (token === "@#") {
        return new vscode.Hover(new vscode.MarkdownString("**@# Dinamik meta çağrı**\n\nAktif hücredeki değer meta servis id olarak kullanılır."), range);
      }
      if (token.startsWith("@!")) {
        const id = Number(token.slice(2));
        return new vscode.Hover(new vscode.MarkdownString(`**@!${id} Host meta çağrısı**\n\nMacro expansion'a bakmadan doğrudan host/runtime meta servisini çağırır.\n\n${metaMarkdown(id)}`), range);
      }
      const id = Number(token.slice(1));
      return new vscode.Hover(new vscode.MarkdownString(metaMarkdown(id)), range);
    }
  }));

  output.appendLine("UX-MINIMA extension activated.");
}

export function deactivate(): void {}

async function runFinalAndOpen(context: vscode.ExtensionContext, mode: "all" | "trace" | "step"): Promise<void> {
  const doc = activeUxmDocument();
  if (!doc) { return; }
  await doc.save();
  try {
    const art = mode === "all" ? await toolchain.finalRunAll(doc.fileName) : mode === "step" ? await toolchain.finalRunStep(doc.fileName) : await toolchain.finalRunTrace(doc.fileName);
    lastTrace = fs.existsSync(art.trace) ? readTraceFile(art.trace) : undefined;
    if (lastTrace) { MemoryViewPanel.show(context, lastTrace); }
    output.appendLine(`\n[Final ${mode}] ${doc.fileName}`);
    if (lastTrace?.end?.output) { output.appendLine(lastTrace.end.output); }
    output.show(true);
    vscode.window.showInformationMessage(`Final ${mode} tamamlandı: ${art.trace}`);
  } catch (err) { vscode.window.showErrorMessage(String(err)); }
}

async function openIfExists(filePath: string, viewColumn: vscode.ViewColumn): Promise<void> {
  if (!fs.existsSync(filePath)) {
    vscode.window.showWarningMessage(`Dosya bulunamadı: ${filePath}`);
    return;
  }
  const uri = vscode.Uri.file(filePath);
  await vscode.window.showTextDocument(uri, { preview: false, viewColumn });
}

function activeUxmDocument(): vscode.TextDocument | undefined {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showWarningMessage("Aktif editör yok.");
    return undefined;
  }
  if (editor.document.languageId !== "uxminima" && path.extname(editor.document.fileName).toLowerCase() !== ".uxm") {
    vscode.window.showWarningMessage("Aktif dosya .uxm değil.");
    return undefined;
  }
  return editor.document;
}

function metaHelpMarkdown(): string {
  const rows = Object.values(META_SERVICES)
    .sort((a, b) => a.id - b.id)
    .map(m => `| @${m.id} | ${m.name} | \`${m.frame}\` | ${m.description} |`)
    .join("\n");
  return `# UX-MINIMA Meta Servisleri\n\n| Meta | Ad | Frame | Açıklama |\n|---|---|---|---|\n${rows}\n\n## Host meta zorlaması\n\n\`@!N\` macro aramasını bypass ederek doğrudan host/runtime servisini çağırır. FP macro başlıklarında \`m210={@!210}\` gibi kullanılır.\n\n## Kullanıcı macro alanı\n\n@128..@255 kullanıcı macro alanıdır. Native compiler tarafında compile-time inline, final/interpreter tarafında runtime macro call-stack olarak çalıştırılabilir.\n`;
}
