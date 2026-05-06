# Büyük Kodları Parçalama Planı

Parçalama kodu güzelleştirmek için değil, aynı bölgenin tekrar tekrar bozulmasını önlemek için yapılacaktır.

## Native compiler

Kaynak: `uxm31_compiler_fb.bas`

Hedef:

```text
uxm/core/compiler/native/native_main.bas
uxm/core/compiler/native/native_cli.bas
uxm/core/compiler/native/native_lexer_parser.bas
uxm/core/compiler/native/native_addressing.bas
uxm/core/compiler/native/native_meta_parse.bas
uxm/core/compiler/native/native_asm_emit.bas
uxm/core/compiler/native/native_validation.bas
```

## Runtime

Kaynak: `uxm31_runtime_fb_full.bas`

Hedef:

```text
uxm/core/runtime/runtime_host.bas
uxm/core/runtime/runtime_memory.bas
uxm/core/runtime/runtime_io.bas
uxm/core/runtime/runtime_status_flags.bas
uxm/core/runtime/runtime_meta_dispatch.bas
uxm/core/runtime/services/runtime_fp_services.bas
uxm/core/runtime/services/runtime_matrix_services.bas
uxm/core/runtime/services/runtime_math_services.bas
```

## Final compiler

Kaynak: `final/uxm31_compiler_final.bas`

Önce onarım:

- `Option Explicit` ve `#Lang "fb"` sırası düzeltilir veya build komutu uyarlanır.
- `instr`, `ptr`, `sp`, `dir`, `pos` gibi çakışan/reserved isimler değiştirilir.
- Tek satır `If ... ElseIf ...` zincirleri blok `If` yapısına çevrilir.

Sonra parçalama:

```text
uxm/core/compiler/final/final_main.bas
uxm/core/compiler/final/final_cli.bas
uxm/core/compiler/final/final_parser.bas
uxm/core/compiler/final/final_interpreter.bas
uxm/core/compiler/final/final_asm_emit.bas
uxm/core/compiler/final/final_trace_json.bas
uxm/core/compiler/final/final_math_bridge.bas
```

## VSCode interpreter

Kaynak: `ide/uxminima-vscode/src/uxmInterpreter.ts`

Hedef:

```text
uxm/ide/vscode/src/interpreter/core.ts
uxm/ide/vscode/src/interpreter/parser.ts
uxm/ide/vscode/src/interpreter/metaRuntime.ts
uxm/ide/vscode/src/interpreter/memory.ts
uxm/ide/vscode/src/interpreter/trace.ts
```
