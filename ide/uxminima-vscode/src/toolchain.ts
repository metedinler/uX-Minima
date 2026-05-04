import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";
import { execFile } from "child_process";

export interface ToolchainPaths {
  fullTool: string;
  compiler: string;
  finalCompiler: string;
  finalCompilerSource: string;
  runtime: string;
  nasm: string;
  fbc: string;
  buildDir: string;
  autoBuildFinalCompiler: boolean;
  maxSteps: number;
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
  diag: string;
  ideRequest: string;
  ideResponse: string;
}

export class UxmToolchain {
  constructor(private readonly output: vscode.OutputChannel, private readonly context: vscode.ExtensionContext) {}

  getPaths(): ToolchainPaths {
    const cfg = vscode.workspace.getConfiguration("uxminima");
    const root = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? process.cwd();
    const buildDirSetting = cfg.get<string>("buildDirectory", "build");
    return {
      fullTool: this.resolveTool(cfg.get<string>("fullToolPath", "uxm31_full_tool.exe"), root),
      compiler: this.resolveTool(cfg.get<string>("compilerPath", "uxm31_compiler_full.exe"), root),
      finalCompiler: this.resolveTool(cfg.get<string>("finalCompilerPath", "uxm31_compiler_final.exe"), root),
      finalCompilerSource: this.resolveTool(cfg.get<string>("finalCompilerSourcePath", "uxm31_compiler_final.bas"), root),
      runtime: this.resolveTool(cfg.get<string>("runtimePath", "uxm31_runtime_fb_full.bas"), root),
      nasm: cfg.get<string>("nasmPath", "nasm"),
      fbc: cfg.get<string>("fbcPath", "fbc"),
      buildDir: path.isAbsolute(buildDirSetting) ? buildDirSetting : path.join(root, buildDirSetting),
      autoBuildFinalCompiler: cfg.get<boolean>("autoBuildFinalCompiler", true),
      maxSteps: cfg.get<number>("maxSteps", 1000)
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
      obj: path.join(paths.buildDir, `${baseName}.obj`),
      exe: path.join(paths.buildDir, `${baseName}.exe`),
      trace: path.join(paths.buildDir, `${baseName}.trace.ndjson`),
      uir: path.join(paths.buildDir, `${baseName}.uir.json`),
      opt: path.join(paths.buildDir, `${baseName}.opt.json`),
      diag: path.join(paths.buildDir, `${baseName}.diag.json`),
      ideRequest: path.join(paths.buildDir, `${baseName}.ide.request.json`),
      ideResponse: path.join(paths.buildDir, `${baseName}.ide.response.json`)
    };
  }

  async buildFinalCompiler(): Promise<string> {
    const paths = this.getPaths();
    if (!fs.existsSync(paths.finalCompilerSource)) {
      throw new Error(`Final compiler source bulunamadı: ${paths.finalCompilerSource}`);
    }
    await this.run(paths.fbc, [paths.finalCompilerSource, "-x", paths.finalCompiler], "Build Final ARGE Compiler");
    return paths.finalCompiler;
  }

  async ensureFinalCompiler(): Promise<string> {
    const paths = this.getPaths();
    if (!paths.autoBuildFinalCompiler) {
      return paths.finalCompiler;
    }
    const exeExists = fs.existsSync(paths.finalCompiler);
    const srcExists = fs.existsSync(paths.finalCompilerSource);
    if (!srcExists) {
      throw new Error(`Final compiler source bulunamadı: ${paths.finalCompilerSource}`);
    }
    let shouldBuild = !exeExists;
    if (exeExists) {
      const srcMtime = fs.statSync(paths.finalCompilerSource).mtimeMs;
      const exeMtime = fs.statSync(paths.finalCompiler).mtimeMs;
      shouldBuild = srcMtime > exeMtime;
    }
    if (shouldBuild) {
      await this.buildFinalCompiler();
    }
    return paths.finalCompiler;
  }

  async finalRunAll(sourceFile: string): Promise<BuildArtifacts> {
    const art = this.artifactsFor(sourceFile);
    const compiler = await this.ensureFinalCompiler();
    await this.run(compiler, ["--input", art.source, "--mode", "all", "--asm", art.asm, "--uir", art.uir, "--diag", art.diag, "--trace", art.trace, "--opt", art.opt], "Final Compiler ALL");
    return art;
  }

  async finalRunTrace(sourceFile: string): Promise<BuildArtifacts> {
    const art = this.artifactsFor(sourceFile);
    const compiler = await this.ensureFinalCompiler();
    await this.run(compiler, ["--input", art.source, "--mode", "interpret", "--trace", art.trace, "--uir", art.uir, "--diag", art.diag, "--opt", art.opt], "Final Compiler Interpret Trace");
    return art;
  }

  async finalRunStep(sourceFile: string): Promise<BuildArtifacts> {
    const art = this.artifactsFor(sourceFile);
    const paths = this.getPaths();
    const compiler = await this.ensureFinalCompiler();
    await this.run(compiler, ["--input", art.source, "--mode", "step", "--trace", art.trace, "--uir", art.uir, "--diag", art.diag, "--opt", art.opt, "--max-steps", String(paths.maxSteps)], "Final Compiler Step Mode");
    return art;
  }

  async finalCompileAsm(sourceFile: string): Promise<BuildArtifacts> {
    const art = this.artifactsFor(sourceFile);
    const compiler = await this.ensureFinalCompiler();
    await this.run(compiler, ["--input", art.source, "--mode", "compile", "--asm", art.asm, "--uir", art.uir, "--diag", art.diag, "--opt", art.opt], "Final Compiler Compile ASM");
    return art;
  }

  async finalExportUIR(sourceFile: string): Promise<BuildArtifacts> {
    const art = this.artifactsFor(sourceFile);
    const compiler = await this.ensureFinalCompiler();
    await this.run(compiler, ["--input", art.source, "--mode", "compile", "--uir", art.uir, "--diag", art.diag, "--opt", art.opt], "Final Compiler Export UIR");
    return art;
  }

  async finalExportDiagnostics(sourceFile: string): Promise<BuildArtifacts> {
    const art = this.artifactsFor(sourceFile);
    const compiler = await this.ensureFinalCompiler();
    await this.run(compiler, ["--input", art.source, "--mode", "compile", "--diag", art.diag, "--uir", art.uir, "--opt", art.opt], "Final Compiler Export Diagnostics");
    return art;
  }

  async finalExportOPT(sourceFile: string): Promise<BuildArtifacts> {
    const art = this.artifactsFor(sourceFile);
    const compiler = await this.ensureFinalCompiler();
    await this.run(compiler, ["--input", art.source, "--mode", "compile", "--opt", art.opt, "--uir", art.uir, "--diag", art.diag], "Final Compiler Export OPT");
    return art;
  }

  async finalIde(sourceFile: string, command: "run" | "step" | "compile" | "all"): Promise<BuildArtifacts> {
    const art = this.artifactsFor(sourceFile);
    const compiler = await this.ensureFinalCompiler();
    const req = { command, source: art.source, asm: art.asm, uir: art.uir, diag: art.diag, trace: art.trace, opt: art.opt };
    fs.writeFileSync(art.ideRequest, JSON.stringify(req, null, 2), "utf8");
    await this.run(compiler, ["--ide-in", art.ideRequest, "--ide-out", art.ideResponse], `Final Compiler IDE ${command}`);
    return art;
  }

  async runTrace(sourceFile: string): Promise<BuildArtifacts> {
    const paths = this.getPaths();
    const art = this.artifactsFor(sourceFile);
    await this.run(paths.fullTool, ["run", art.source, art.trace], "Legacy Run Trace");
    return art;
  }

  async exportUIR(sourceFile: string): Promise<BuildArtifacts> {
    const paths = this.getPaths();
    const art = this.artifactsFor(sourceFile);
    await this.run(paths.fullTool, ["uir", art.source, art.uir], "Legacy Export UIR");
    return art;
  }

  async exportOPT(sourceFile: string): Promise<BuildArtifacts> {
    const paths = this.getPaths();
    const art = this.artifactsFor(sourceFile);
    await this.run(paths.fullTool, ["opt", art.source, art.opt], "Legacy Export OPT");
    return art;
  }

  async buildNative(sourceFile: string): Promise<BuildArtifacts> {
    const paths = this.getPaths();
    const art = await this.finalCompileAsm(sourceFile);
    if (!fs.existsSync(paths.runtime)) {
      throw new Error(`Runtime bulunamadı: ${paths.runtime}. Native EXE için uxm31_runtime_fb_full.bas dosyasını tools/ içine koy veya uxminima.runtimePath ayarını düzelt.`);
    }
    await this.run(paths.nasm, ["-f", "win64", art.asm, "-o", art.obj], "ASM -> OBJ");
    await this.run(paths.fbc, [paths.runtime, art.obj, "-x", art.exe], "Runtime + OBJ -> EXE");
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
    const fromRootTools = path.join(root, "tools", toolPath);
    if (fs.existsSync(fromRootTools)) {
      return fromRootTools;
    }
    const fromExtensionTools = path.join(this.context.extensionPath, "tools", toolPath);
    if (fs.existsSync(fromExtensionTools)) {
      return fromExtensionTools;
    }
    return toolPath;
  }

  private run(command: string, args: string[], title: string): Promise<void> {
    this.output.appendLine(`\n[${title}] ${command} ${args.map(a => JSON.stringify(a)).join(" ")}`);
    const cwd = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? this.context.extensionPath;
    return new Promise((resolve, reject) => {
      execFile(command, args, { cwd }, (error: Error | null, stdout: string, stderr: string) => {
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
