# UX-MINIMA V3.1 FINAL ARGE VS Code Extension

Bu eklenti `.uxm` dosyaları için syntax highlighting, diagnostics, snippet, meta hover, internal trace, final compiler trace/step, UIR/OPT/DIAG export ve memory watch sağlar.

## İlk kurulum

```bat
npm install
npm run compile
code .
```

VS Code içinde `F5` ile Extension Development Host aç.

## Final compiler kurulumu

Eklenti içinde `tools/uxm31_compiler_final.bas` hazır gelir. İlk kullanımda eklenti, ayar açıksa bunu FreeBASIC ile otomatik derlemeye çalışır:

```bat
fbc tools\uxm31_compiler_final.bas -x tools\uxm31_compiler_final.exe
```

Elle derlemek için Command Palette:

```text
UX-MINIMA: Build Final ARGE Compiler
```

## Ana komutlar

```text
UX-MINIMA: Final Compiler Step Mode
UX-MINIMA: Final Compiler Interpret Trace
UX-MINIMA: Final Compiler Run ALL
UX-MINIMA: Final Compiler Compile ASM
UX-MINIMA: Final Compiler Export UIR
UX-MINIMA: Final Compiler Export Diagnostics
UX-MINIMA: Final Compiler Export Optimizer Report
UX-MINIMA: Internal Trace & Memory Watch
UX-MINIMA: Build Native EXE
```

## Ayarlar

```json
{
  "uxminima.finalCompilerSourcePath": "uxm31_compiler_final.bas",
  "uxminima.finalCompilerPath": "uxm31_compiler_final.exe",
  "uxminima.autoBuildFinalCompiler": true,
  "uxminima.maxSteps": 1000,
  "uxminima.buildDirectory": "build",
  "uxminima.fbcPath": "fbc",
  "uxminima.nasmPath": "nasm"
}
```

Yollar workspace kökünde, `tools/` klasöründe veya eklentinin kendi `tools/` klasöründe aranır.

## Final ARGE özellikleri

```text
(D@T)
(D@T+N)
(D@T-N)
(D@(T-2)+N)
@!N
#arge version
#arge json on
#arge step on
#arge trace on
#arge watch tape=0:32
```

## Native build notu

Native EXE üretimi için ayrıca şu runtime dosyası gerekir:

```text
uxm31_runtime_fb_full.bas
```

Bunu workspace `tools/` klasörüne koyabilir veya `uxminima.runtimePath` ayarını gösterebilirsin.
