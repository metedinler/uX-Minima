# UX-MINIMA IDE Protokolü

VS Code eklentisi iki çalışma yolunu destekler:

1. Internal Trace & Memory Watch: TypeScript içi hafif interpreter ile çalışır. Tape/stack/fifo/data snapshot üretir.
2. Toolchain Trace: `uxm31_full_tool.exe run source.uxm trace.ndjson` çağırır.

Komutlar:

- `UX-MINIMA: Internal Trace & Memory Watch`
- `UX-MINIMA: Run Trace with Toolchain`
- `UX-MINIMA: Export UIR`
- `UX-MINIMA: Export Optimizer Report`
- `UX-MINIMA: Build Native EXE`
- `UX-MINIMA: Open Memory Watch`
