# UX-MINIMA V3.1 VS Code Extension

Bu eklenti `.uxm` dosyaları için syntax highlighting, diagnostics, meta servis hover bilgisi, trace replay, memory watch, UIR/OPT export ve native build komutları sağlar.

## Kurulum

```bat
npm install
npm run compile
```

VS Code içinde extension development host açmak için `F5` kullanılabilir.

## Komutlar

- `UX-MINIMA: Internal Trace & Memory Watch`
- `UX-MINIMA: Run Trace with Toolchain`
- `UX-MINIMA: Export UIR`
- `UX-MINIMA: Export Optimizer Report`
- `UX-MINIMA: Build Native EXE`
- `UX-MINIMA: Open Memory Watch`
- `UX-MINIMA: Open Meta Service Help`

## Toolchain

`tools/` klasörüne şu dosyalar koyulabilir:

- `uxm31_full_tool.exe`
- `uxm31_compiler_full.exe`
- `uxm31_runtime_fb_full.bas`

Ayarlar Settings üzerinden değiştirilebilir.

## Memory Watch

Internal trace komutu extension içindeki hafif UXM interpreter'ı çalıştırır ve tape/stack/fifo/data snapshot üretir. Böylece toolchain exe olmadan da bellek izleme paneli açılır.
