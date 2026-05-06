# Dort Hat Mimari Koruma Manifesti

Bu projede hatlar birlestirilmeden korunacak. Tek dosyada rastgele yamalama yasak.

## HAT1_NATIVE_X64

Amac: UXM kaynak -> ASM -> OBJ -> EXE.
Otorite dosyalar:
- `uxm31_compiler_fb.bas`
- `uxm31_runtime_fb.bas`
- `uxm31_runtime_fb_full.bas`
- `build_all.bat`
- `build_one.bat`
- `run_tests.bat`

## HAT2_FULL_TOOL_INTERPRETER

Amac: interpreter, trace, UIR, optimizer, IDE protokol.
Otorite adaylari:
- `uxm31_full_tool_fb.bas`
- `uxm31_full_tool_fb_2.bas`

Gercek: Bu hat su an temiz FreeBASIC kaynagi degil; markdown karisik. Once temiz kaynak cikarilacak.

## HAT3_FINAL_ARGE_COMPILER

Amac: final/ARGE tek merkez compiler + interpreter + diagnostics + UIR + ASM emitter.
Otorite dosyalar:
- `final/uxm31_compiler_final.bas`
- `final/build_final.bat`
- `build_final_compiler.bat`
- `run_final_probe.bat`

Gercek: Derleme hatalari var. VS Code final komutlari bu hata cozulmeden guvenilir degil.

## HAT4_VSCODE_EXTENSION

Amac: UXM dili icin VS Code yuzeyi.
Otorite dosyalar:
- `ide/uxminima-vscode/package.json`
- `ide/uxminima-vscode/src/*.ts`
- `ide/uxminima-vscode/syntaxes/*`
- `ide/uxminima-vscode/snippets/*`

Gercek: Eklenti var; fakat toolchain final/full/native derleyicilere bagimli.

## Ortak kabul kurali

Her ozellik icin 4 hatta su kararlar disinda ifade yasak:

- PASS
- FAIL
- UNSUPPORTED
- RESERVED
- BROKEN_SOURCE

`VAR` tek basina kabul degildir.
