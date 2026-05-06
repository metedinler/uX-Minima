# Kanonik UXM Compiler Mimarisi V3

## Amaç

Tek kod sistemi kurulacak. Aynı iş için üç farklı dosya aktif kalmayacak.

## Ana hat

```text
.uxm kaynak
  -> native compiler parser/address/meta parse
  -> x64 NASM asm emit
  -> NASM obj
  -> FreeBASIC full runtime link
  -> EXE
  -> test output + JSON/CSV rapor
```

## Katmanlar

### 1. Native compiler

Kanonik kaynak: `uxm31_compiler_fb.bas`.

Görevleri:

- UXM komutlarını parse etmek
- adresleme modlarını çözmek
- meta servis çağrılarını üretmek
- NASM x64 ASM üretmek

### 2. Runtime host

Kanonik kaynak: `uxm31_runtime_fb_full.bas`.

Görevleri:

- `ux_meta_call_ex` dispatcher
- bellek okuma/yazma
- IO
- status/flags/error
- FP/matrix/math servis modüllerini bağlamak

### 3. Runtime servisleri

- FP: `runtime_fp_services.bas`
- Matrix: `runtime_matrix_services.bas`
- Math/türev/integral: `runtime_math_services.bas`

### 4. Final compiler/interpreter

Kanonik onarım hedefi: `final/uxm31_compiler_final.bas`.

Görevleri:

- interpreter
- step/trace
- JSON/NDJSON rapor
- UIR/DIAG/OPT export
- ASM export

Mevcut durumda kırık build logları olduğu için çalışan ana hat ilan edilmez.

### 5. VSCode IDE

Kanonik kaynak: `ide/uxminima-vscode`.

Görevleri:

- UXM syntax/diagnostics/snippets
- internal interpreter
- trace reader
- memory watch
- native/final toolchain komutları

## Dört hat kararı

- Hat 1: Native ASM/EXE — öncelikli çalışan hat.
- Hat 2: Final interpreter/compiler — onarım hedefi.
- Hat 3: VSCode IDE — path ve toolchain güncellemesi gerekir.
- Hat 4: Full tool — mevcut dosyalar kırık; karantina.
