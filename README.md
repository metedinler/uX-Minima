# UX-MINIMA x64 V3.1 Full Final Real

TR: Bu klasor UX-MINIMA dilinin aktif, calisan gelistirme kopyasidir. Derleyici, runtime, test zinciri ve VS Code eklentisi birlikte burada yurur.

EN: This folder is the active, working development copy of the UX-MINIMA language. Compiler, runtime, test chain, and VS Code extension are maintained together here.

## Ne Bu Proje? / What Is This Project?

TR: UX-MINIMA, hucre tabanli (tape/stack/data) bir DSL'dir. Kaynak .uxm dosyasi native x64 NASM asm uretilir, sonra NASM + FreeBASIC runtime ile EXE'ye baglanir.

EN: UX-MINIMA is a cell-based DSL (tape/stack/data). A .uxm source is compiled to native x64 NASM asm, then linked into an EXE via NASM + FreeBASIC runtime.

## Ozellikler / Features

- TR: Native derleme hattı (UXM -> ASM -> OBJ -> EXE)
- EN: Native compile chain (UXM -> ASM -> OBJ -> EXE)
- TR: Meta servisler (core, aritmetik, matematik, IO, pointer, FIFO/data/sort/wild)
- EN: Meta services (core, arithmetic, math, IO, pointer, FIFO/data/sort/wild)
- TR: Dynamic meta cagrisi ve adresleme varyantlari
- EN: Dynamic meta calls and addressing variants
- TR: VS Code eklentisi (syntax, komutlar, native build, trace/uir/opt)
- EN: VS Code extension (syntax, commands, native build, trace/uir/opt)

## Kurulum / Setup

1. TR: NASM kurulu olmali ve PATH icinde olmali.
1. EN: NASM must be installed and available on PATH.
2. TR: FreeBASIC x64 onerilen yol:
2. EN: Recommended FreeBASIC x64 path:

```text
C:/Users/mete/Downloads/BasicOyunSource/uXBasic_repo/tools/FreeBASIC-1.10.1-win64/fbc.exe
```

3. TR: VS Code eklentisi icin Node.js/NPM gerekir.
3. EN: Node.js/NPM is required for the VS Code extension.

## Hizli Komutlar / Quick Commands

```bat
build_all.bat
build_one.bat tests\test01_print_A.uxm
run_tests.bat
```

TR: `run_tests.bat` tum testleri sirayla calistirir.
EN: `run_tests.bat` runs all tests sequentially.

## VS Code Eklentisi / VS Code Extension

Konum / Location: ide/uxminima-vscode

```bat
cd ide\uxminima-vscode
npm install
npm run compile
npx @vscode/vsce package
```

TR: Uretilen VSIX dosyasi VS Code'a yuklenebilir.
EN: The generated VSIX can be installed into VS Code.

## Klasorler / Folders

- compiler/: TR: Derleyici kaynaklari | EN: Compiler sources
- runtime/: TR: Runtime katmani | EN: Runtime layer
- ide/: TR: VS Code eklentisi | EN: VS Code extension
- tests/: TR: Dil testleri | EN: Language tests
- build/: TR: Derleme ciktilari | EN: Build artifacts
- tools/: TR: Yardimci araclar | EN: Helper tools

## Dokuman-Gerceklik Politikasi / Documentation-Reality Policy

TR: Belgede yer alan ozelliklerin kodda calisiyor olmasi hedeflenir. Kodda olmayan tasarim maddeleri belgeye calisir ozellik gibi yazilmaz.

EN: Features documented as available must be working in code. Design-only ideas are not presented as implemented features.

## Takip / Tracking

- MASTER_TAKIP_DOKUMANI_V31.md
