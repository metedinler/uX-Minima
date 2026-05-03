import * as vscode from "vscode";

const commandBeforeAddress = /([><+\-0\.,\[\]\$%\?!;&\|\^~\{\}eE])\s+\(/g;
const addressWithSpace = /\([^\)]*\s+[^\)]*\)/g;
const metaPattern = /@([0-9]+)/g;
const macroPattern = /\bm([0-9]+)\s*=\s*\{/g;
const memoryPattern = /^\s*#memory\s+(.+)$/i;

export class UxmDiagnostics {
  private readonly collection: vscode.DiagnosticCollection;

  constructor(context: vscode.ExtensionContext) {
    this.collection = vscode.languages.createDiagnosticCollection("uxminima");
    context.subscriptions.push(this.collection);
  }

  validate(document: vscode.TextDocument): void {
    if (document.languageId !== "uxminima") {
      return;
    }
    const diagnostics: vscode.Diagnostic[] = [];
    const text = document.getText();
    for (let lineIndex = 0; lineIndex < document.lineCount; lineIndex++) {
      const line = document.lineAt(lineIndex).text;
      this.validateLine(document, line, lineIndex, diagnostics);
    }
    this.validateGlobal(document, text, diagnostics);
    this.collection.set(document.uri, diagnostics);
  }

  clear(uri: vscode.Uri): void {
    this.collection.delete(uri);
  }

  private validateLine(document: vscode.TextDocument, line: string, lineIndex: number, diagnostics: vscode.Diagnostic[]): void {
    const trimmed = line.trim();
    if (trimmed.length === 0 || trimmed.startsWith("#")) {
      if (trimmed.toLowerCase().startsWith("#memory")) {
        this.validateMemoryPragma(document, line, lineIndex, diagnostics);
      }
      return;
    }

    for (const match of line.matchAll(commandBeforeAddress)) {
      const start = match.index ?? 0;
      const range = new vscode.Range(lineIndex, start, lineIndex, Math.min(line.length, start + match[0].length));
      diagnostics.push(new vscode.Diagnostic(range, "Komut ile adresleme arasında boşluk yasak. Örnek: 0(T-2)+k10", vscode.DiagnosticSeverity.Error));
    }

    for (const match of line.matchAll(addressWithSpace)) {
      const start = match.index ?? 0;
      const range = new vscode.Range(lineIndex, start, lineIndex, Math.min(line.length, start + match[0].length));
      diagnostics.push(new vscode.Diagnostic(range, "Adresleme parantezi içinde boşluk yasak. Örnek: (T+1), (D:0)", vscode.DiagnosticSeverity.Error));
    }

    for (const match of line.matchAll(metaPattern)) {
      const id = Number(match[1]);
      if (!Number.isInteger(id) || id < 0 || id > 255) {
        const start = match.index ?? 0;
        diagnostics.push(new vscode.Diagnostic(new vscode.Range(lineIndex, start, lineIndex, start + match[0].length), "Meta servis id 0..255 aralığında olmalı.", vscode.DiagnosticSeverity.Error));
      }
    }

    for (const match of line.matchAll(macroPattern)) {
      const id = Number(match[1]);
      if (id < 128 || id > 255) {
        const start = match.index ?? 0;
        diagnostics.push(new vscode.Diagnostic(new vscode.Range(lineIndex, start, lineIndex, start + match[0].length), "Kullanıcı macro id 128..255 aralığında olmalı.", vscode.DiagnosticSeverity.Error));
      }
    }
  }

  private validateGlobal(document: vscode.TextDocument, text: string, diagnostics: vscode.Diagnostic[]): void {
    const loopStack: vscode.Position[] = [];
    for (let i = 0; i < text.length; i++) {
      const c = text[i];
      const pos = document.positionAt(i);
      const lineText = document.lineAt(pos.line).text.trim();
      if (lineText.startsWith("#")) {
        continue;
      }
      if (c === "[") {
        loopStack.push(pos);
      } else if (c === "]") {
        if (loopStack.length === 0) {
          diagnostics.push(new vscode.Diagnostic(new vscode.Range(pos, pos.translate(0, 1)), "Fazla ] bulundu.", vscode.DiagnosticSeverity.Error));
        } else {
          loopStack.pop();
        }
      }
    }
    for (const pos of loopStack) {
      diagnostics.push(new vscode.Diagnostic(new vscode.Range(pos, pos.translate(0, 1)), "Kapanmamış [ döngü başlangıcı.", vscode.DiagnosticSeverity.Error));
    }
  }

  private validateMemoryPragma(document: vscode.TextDocument, line: string, lineIndex: number, diagnostics: vscode.Diagnostic[]): void {
    const m = line.match(memoryPattern);
    if (!m) { return; }
    const body = m[1].toLowerCase().replace(/\s+/g, "");
    const getVal = (key: string): number | undefined => {
      const r = new RegExp(`${key}=([0-9]+)`).exec(body);
      return r ? Number(r[1]) : undefined;
    };
    const tape = getVal("tape");
    const stack = getVal("stack");
    const data = getVal("data");
    if (tape !== undefined && stack !== undefined && data !== undefined && tape + stack + data !== 64) {
      diagnostics.push(new vscode.Diagnostic(new vscode.Range(lineIndex, 0, lineIndex, line.length), `#memory toplamı 64 KB olmalı. Şu an: ${tape + stack + data} KB`, vscode.DiagnosticSeverity.Error));
    }
  }
}
