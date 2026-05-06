"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const diagnostics_1 = require("./diagnostics");
const toolchain_1 = require("./toolchain");
const traceReader_1 = require("./traceReader");
const memoryView_1 = require("./views/memoryView");
const uxmInterpreter_1 = require("./uxmInterpreter");
const metaServices_1 = require("./metaServices");
let lastTrace;
let output;
let diagnostics;
let toolchain;
function activate(context) {
    output = vscode.window.createOutputChannel("UX-MINIMA");
    diagnostics = new diagnostics_1.UxmDiagnostics(context);
    toolchain = new toolchain_1.UxmToolchain(output, context);
    context.subscriptions.push(output);
    for (const doc of vscode.workspace.textDocuments) {
        diagnostics.validate(doc);
    }
    context.subscriptions.push(vscode.workspace.onDidOpenTextDocument((doc) => diagnostics.validate(doc)));
    context.subscriptions.push(vscode.workspace.onDidChangeTextDocument((e) => diagnostics.validate(e.document)));
    context.subscriptions.push(vscode.workspace.onDidCloseTextDocument((doc) => diagnostics.clear(doc.uri)));
    context.subscriptions.push(vscode.commands.registerCommand("uxminima.validateFile", () => {
        const doc = activeUxmDocument();
        if (!doc) {
            return;
        }
        diagnostics.validate(doc);
        vscode.window.showInformationMessage("UX-MINIMA dosyası doğrulandı.");
    }));
    context.subscriptions.push(vscode.commands.registerCommand("uxminima.internalTrace", async () => {
        const doc = activeUxmDocument();
        if (!doc) {
            return;
        }
        await doc.save();
        const interpreter = new uxmInterpreter_1.UxmInterpreter();
        const result = interpreter.run(doc.getText());
        lastTrace = { snapshot: { type: "snapshot", source: doc.fileName, engine: "internal-vscode", events: result.events.length }, events: result.events };
        const art = toolchain.artifactsFor(doc.fileName);
        fs.writeFileSync(art.trace, result.events.map(e => JSON.stringify(e)).join("\n"), "utf8");
        output.appendLine(`\n[Internal Trace] ${doc.fileName}`);
        output.appendLine(result.output || "");
        if (result.diagnostics.length) {
            output.appendLine("Diagnostics:");
            for (const d of result.diagnostics) {
                output.appendLine("- " + d);
            }
        }
        output.show(true);
        memoryView_1.MemoryViewPanel.show(context, lastTrace);
    }));
    context.subscriptions.push(vscode.commands.registerCommand("uxminima.finalBuildCompiler", async () => {
        try {
            const exe = await toolchain.buildFinalCompiler();
            vscode.window.showInformationMessage(`Final ARGE compiler üretildi: ${exe}`);
        }
        catch (err) {
            vscode.window.showErrorMessage(String(err));
        }
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
        if (!doc) {
            return;
        }
        await doc.save();
        try {
            const art = await toolchain.finalCompileAsm(doc.fileName);
            await openIfExists(art.asm, vscode.ViewColumn.Beside);
            vscode.window.showInformationMessage(`ASM üretildi: ${art.asm}`);
        }
        catch (err) {
            vscode.window.showErrorMessage(String(err));
        }
    }));
    context.subscriptions.push(vscode.commands.registerCommand("uxminima.finalExportUIR", async () => {
        const doc = activeUxmDocument();
        if (!doc) {
            return;
        }
        await doc.save();
        try {
            const art = await toolchain.finalExportUIR(doc.fileName);
            await openIfExists(art.uir, vscode.ViewColumn.Beside);
        }
        catch (err) {
            vscode.window.showErrorMessage(String(err));
        }
    }));
    context.subscriptions.push(vscode.commands.registerCommand("uxminima.finalExportDiagnostics", async () => {
        const doc = activeUxmDocument();
        if (!doc) {
            return;
        }
        await doc.save();
        try {
            const art = await toolchain.finalExportDiagnostics(doc.fileName);
            await openIfExists(art.diag, vscode.ViewColumn.Beside);
        }
        catch (err) {
            vscode.window.showErrorMessage(String(err));
        }
    }));
    context.subscriptions.push(vscode.commands.registerCommand("uxminima.finalExportOPT", async () => {
        const doc = activeUxmDocument();
        if (!doc) {
            return;
        }
        await doc.save();
        try {
            const art = await toolchain.finalExportOPT(doc.fileName);
            await openIfExists(art.opt, vscode.ViewColumn.Beside);
        }
        catch (err) {
            vscode.window.showErrorMessage(String(err));
        }
    }));
    context.subscriptions.push(vscode.commands.registerCommand("uxminima.runTrace", async () => {
        const doc = activeUxmDocument();
        if (!doc) {
            return;
        }
        await doc.save();
        try {
            const art = await toolchain.runTrace(doc.fileName);
            lastTrace = (0, traceReader_1.readTraceFile)(art.trace);
            memoryView_1.MemoryViewPanel.show(context, lastTrace);
            vscode.window.showInformationMessage(`Trace üretildi: ${art.trace}`);
        }
        catch (err) {
            vscode.window.showErrorMessage(String(err));
        }
    }));
    context.subscriptions.push(vscode.commands.registerCommand("uxminima.exportUIR", async () => {
        const doc = activeUxmDocument();
        if (!doc) {
            return;
        }
        await doc.save();
        try {
            const art = await toolchain.exportUIR(doc.fileName);
            await openIfExists(art.uir, vscode.ViewColumn.Beside);
        }
        catch (err) {
            vscode.window.showErrorMessage(String(err));
        }
    }));
    context.subscriptions.push(vscode.commands.registerCommand("uxminima.exportOPT", async () => {
        const doc = activeUxmDocument();
        if (!doc) {
            return;
        }
        await doc.save();
        try {
            const art = await toolchain.exportOPT(doc.fileName);
            await openIfExists(art.opt, vscode.ViewColumn.Beside);
        }
        catch (err) {
            vscode.window.showErrorMessage(String(err));
        }
    }));
    context.subscriptions.push(vscode.commands.registerCommand("uxminima.buildNative", async () => {
        const doc = activeUxmDocument();
        if (!doc) {
            return;
        }
        await doc.save();
        try {
            const art = await toolchain.buildNative(doc.fileName);
            vscode.window.showInformationMessage(`Native EXE üretildi: ${art.exe}`);
        }
        catch (err) {
            vscode.window.showErrorMessage(String(err));
        }
    }));
    context.subscriptions.push(vscode.commands.registerCommand("uxminima.openMemoryWatch", () => {
        memoryView_1.MemoryViewPanel.show(context, lastTrace);
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
        provideHover(document, position) {
            const range = document.getWordRangeAtPosition(position, /@#|@![0-9]+|@[0-9]+/);
            if (!range) {
                return undefined;
            }
            const token = document.getText(range);
            if (token === "@#") {
                return new vscode.Hover(new vscode.MarkdownString("**@# Dinamik meta çağrı**\n\nAktif hücredeki değer meta servis id olarak kullanılır."), range);
            }
            if (token.startsWith("@!")) {
                const id = Number(token.slice(2));
                return new vscode.Hover(new vscode.MarkdownString(`**@!${id} Host meta çağrısı**\n\nMacro expansion'a bakmadan doğrudan host/runtime meta servisini çağırır.\n\n${(0, metaServices_1.metaMarkdown)(id)}`), range);
            }
            const id = Number(token.slice(1));
            return new vscode.Hover(new vscode.MarkdownString((0, metaServices_1.metaMarkdown)(id)), range);
        }
    }));
    output.appendLine("UX-MINIMA extension activated.");
}
function deactivate() { }
async function runFinalAndOpen(context, mode) {
    const doc = activeUxmDocument();
    if (!doc) {
        return;
    }
    await doc.save();
    try {
        const art = mode === "all" ? await toolchain.finalRunAll(doc.fileName) : mode === "step" ? await toolchain.finalRunStep(doc.fileName) : await toolchain.finalRunTrace(doc.fileName);
        lastTrace = fs.existsSync(art.trace) ? (0, traceReader_1.readTraceFile)(art.trace) : undefined;
        if (lastTrace) {
            memoryView_1.MemoryViewPanel.show(context, lastTrace);
        }
        output.appendLine(`\n[Final ${mode}] ${doc.fileName}`);
        if (lastTrace?.end?.output) {
            output.appendLine(lastTrace.end.output);
        }
        output.show(true);
        vscode.window.showInformationMessage(`Final ${mode} tamamlandı: ${art.trace}`);
    }
    catch (err) {
        vscode.window.showErrorMessage(String(err));
    }
}
async function openIfExists(filePath, viewColumn) {
    if (!fs.existsSync(filePath)) {
        vscode.window.showWarningMessage(`Dosya bulunamadı: ${filePath}`);
        return;
    }
    const uri = vscode.Uri.file(filePath);
    await vscode.window.showTextDocument(uri, { preview: false, viewColumn });
}
function activeUxmDocument() {
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
function metaHelpMarkdown() {
    const rows = Object.values(metaServices_1.META_SERVICES)
        .sort((a, b) => a.id - b.id)
        .map(m => `| @${m.id} | ${m.name} | \`${m.frame}\` | ${m.description} |`)
        .join("\n");
    return `# UX-MINIMA Meta Servisleri\n\n| Meta | Ad | Frame | Açıklama |\n|---|---|---|---|\n${rows}\n\n## Host meta zorlaması\n\n\`@!N\` macro aramasını bypass ederek doğrudan host/runtime servisini çağırır. FP macro başlıklarında \`m210={@!210}\` gibi kullanılır.\n\n## Kullanıcı macro alanı\n\n@128..@255 kullanıcı macro alanıdır. Native compiler tarafında compile-time inline, final/interpreter tarafında runtime macro call-stack olarak çalıştırılabilir.\n`;
}
//# sourceMappingURL=extension.js.map