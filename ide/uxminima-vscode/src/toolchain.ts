import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";
import { execFile } from "child_process";

export interface ToolchainPaths {
  fullTool: string;
  compiler: string;
  runtime: string;
  nasm: string;
  fbc: string;
  buildDir: string;
}

export interface BuildArtifacts {
  source: string;
  baseName: string;
  buildDir: string;
  asm: string;
  obj: string;
  exe: string;
  trace: string;
  uir: string;
  opt: string;
}

export class UxmToolchain {
  constructor(private readonly output: vscode.OutputChannel) {}

  getPaths(): ToolchainPaths {
    const cfg = vscode.workspace.getConfiguration("uxminima");
    const root = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? process.cwd();
    const buildDirSetting = cfg.get<string>("buildDirectory", "build");
    return {
      fullTool: this.resolveTool(cfg.get<string>("fullToolPath", "uxm31_full_tool.exe"), root),
      compiler: this.resolveTool(cfg.get<string>("compilerPath", "uxm.exe"), root),
      runtime: this.resolveTool(cfg.get<string>("runtimePath", "uxm31_runtime_fb_full.bas"), root),
      nasm: cfg.get<string>("nasmPath", "nasm"),
      fbc: cfg.get<string>("fbcPath", "fbc"),
      buildDir: path.isAbsolute(buildDirSetting) ? buildDirSetting : path.join(root, buildDirSetting)
    };
  }

  artifactsFor(sourceFile: string): BuildArtifacts {
    const paths = this.getPaths();
    const baseName = path.basename(sourceFile, path.extname(sourceFile));
    if (!fs.existsSync(paths.buildDir)) {
      fs.mkdirSync(paths.buildDir, { recursive: true });
    }
    return {
      source: sourceFile,
      baseName,
      buildDir: paths.buildDir,
      asm: path.join(paths.buildDir, `${baseName}.asm`),
      obj: path.join(paths.buildDir, `${baseName}.o`),
      exe: path.join(paths.buildDir, `${baseName}.exe`),
      trace: path.join(paths.buildDir, `${baseName}.trace.ndjson`),
      uir: path.join(paths.buildDir, `${baseName}.uir.json`),
      opt: path.join(paths.buildDir, `${baseName}.opt.json`)
    };
  }

  async runTrace(sourceFile: string): Promise<BuildArtifacts> {
    const paths = this.getPaths();
    const art = this.artifactsFor(sourceFile);
    await this.run(paths.fullTool, ["run", art.source, art.trace], "Run Trace");
    return art;
  }

  async exportUIR(sourceFile: string): Promise<BuildArtifacts> {
    const paths = this.getPaths();
    const art = this.artifactsFor(sourceFile);
    await this.run(paths.fullTool, ["uir", art.source, art.uir], "Export UIR");
    return art;
  }

  async exportOPT(sourceFile: string): Promise<BuildArtifacts> {
    const paths = this.getPaths();
    const art = this.artifactsFor(sourceFile);
    await this.run(paths.fullTool, ["opt", art.source, art.opt], "Export OPT");
    return art;
  }

  async buildNative(sourceFile: string): Promise<BuildArtifacts> {
    const paths = this.getPaths();
    const art = this.artifactsFor(sourceFile);
    await this.run(paths.compiler, [art.source, art.asm], "UXM -> ASM");
    await this.run(paths.nasm, ["-f", "win64", art.asm, "-o", art.obj], "ASM -> OBJ");
    await this.run(paths.fbc, ["-x", art.exe, paths.runtime, art.obj], "Runtime + OBJ -> EXE");
    return art;
  }

  private resolveTool(toolPath: string, root: string): string {
    if (path.isAbsolute(toolPath)) {
      return toolPath;
    }
    const fromRoot = path.join(root, toolPath);
    if (fs.existsSync(fromRoot)) {
      return fromRoot;
    }
    const fromTools = path.join(root, "tools", toolPath);
    if (fs.existsSync(fromTools)) {
      return fromTools;
    }
    return toolPath;
  }

  private run(command: string, args: string[], title: string): Promise<void> {
    this.output.appendLine(`\n[${title}] ${command} ${args.map(a => JSON.stringify(a)).join(" ")}`);
    return new Promise((resolve, reject) => {
      execFile(command, args, { cwd: vscode.workspace.workspaceFolders?.[0]?.uri.fsPath }, (error, stdout, stderr) => {
        if (stdout) { this.output.appendLine(stdout); }
        if (stderr) { this.output.appendLine(stderr); }
        if (error) {
          this.output.show(true);
          reject(new Error(`${title} başarısız: ${error.message}`));
          return;
        }
        resolve();
      });
    });
  }
}
