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
  toolchain = new UxmToolchain(output);
  context.subscriptions.push(output);

  for (const doc of vscode.workspace.textDocuments) {
    diagnostics.validate(doc);
  }

  context.subscriptions.push(vscode.workspace.onDidOpenTextDocument(doc => diagnostics.validate(doc)));
  context.subscriptions.push(vscode.workspace.onDidChangeTextDocument(e => diagnostics.validate(e.document)));
  context.subscriptions.push(vscode.workspace.onDidCloseTextDocument(doc => diagnostics.clear(doc.uri)));

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

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.runTrace", async () => {
    const doc = activeUxmDocument();
    if (!doc) { return; }
    await doc.save();
    try {
      const art = await toolchain.runTrace(doc.fileName);
      lastTrace = readTraceFile(art.trace);
      MemoryViewPanel.show(context, lastTrace);
      vscode.window.showInformationMessage(`Trace üretildi: ${art.trace}`);
    } catch (err) {
      vscode.window.showErrorMessage(String(err));
    }
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.exportUIR", async () => {
    const doc = activeUxmDocument();
    if (!doc) { return; }
    await doc.save();
    try {
      const art = await toolchain.exportUIR(doc.fileName);
      const uri = vscode.Uri.file(art.uir);
      await vscode.window.showTextDocument(uri, { preview: false, viewColumn: vscode.ViewColumn.Beside });
    } catch (err) {
      vscode.window.showErrorMessage(String(err));
    }
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.exportOPT", async () => {
    const doc = activeUxmDocument();
    if (!doc) { return; }
    await doc.save();
    try {
      const art = await toolchain.exportOPT(doc.fileName);
      const uri = vscode.Uri.file(art.opt);
      await vscode.window.showTextDocument(uri, { preview: false, viewColumn: vscode.ViewColumn.Beside });
    } catch (err) {
      vscode.window.showErrorMessage(String(err));
    }
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.buildNative", async () => {
    const doc = activeUxmDocument();
    if (!doc) { return; }
    await doc.save();
    try {
      const art = await toolchain.buildNative(doc.fileName);
      vscode.window.showInformationMessage(`Native EXE üretildi: ${art.exe}`);
    } catch (err) {
      vscode.window.showErrorMessage(String(err));
    }
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.openMemoryWatch", () => {
    MemoryViewPanel.show(context, lastTrace);
  }));

  context.subscriptions.push(vscode.commands.registerCommand("uxminima.openMetaHelp", async () => {
    const doc = await vscode.workspace.openTextDocument({ language: "markdown", content: metaHelpMarkdown() });
    await vscode.window.showTextDocument(doc, { preview: false, viewColumn: vscode.ViewColumn.Beside });
  }));

  context.subscriptions.push(vscode.languages.registerHoverProvider("uxminima", {
    provideHover(document, position) {
      const range = document.getWordRangeAtPosition(position, /@#|@[0-9]+/);
      if (!range) { return undefined; }
      const token = document.getText(range);
      if (token === "@#") {
        return new vscode.Hover(new vscode.MarkdownString("**@# Dinamik meta çağrı**\n\nAktif hücredeki değer meta servis id olarak kullanılır."), range);
      }
      const id = Number(token.slice(1));
      return new vscode.Hover(new vscode.MarkdownString(metaMarkdown(id)), range);
    }
  }));

  output.appendLine("UX-MINIMA extension activated.");
}

export function deactivate(): void {}

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
  return `# UX-MINIMA Meta Servisleri\n\n| Meta | Ad | Frame | Açıklama |\n|---|---|---|---|\n${rows}\n\n## Kullanıcı macro alanı\n\n@128..@255 kullanıcı macro alanıdır. Native compiler tarafında compile-time inline, full tool/interpreter tarafında runtime macro call-stack olarak çalıştırılabilir.\n`;
}
