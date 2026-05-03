# Copilot Instructions for UX-MINIMA

Bu repo UX-MINIMA x64 V3.1 dili, VS Code eklentisi ve toolchain entegrasyonu içindir.

UX-MINIMA Brainfuck benzeri fakat genişletilmiş bir tape/stack/data/FIFO tabanlı dildir.

Temel kurallar:
- `.uxm` dosyalarında komut içinde boşluk yasaktır.
- `0(T-2)+k10` geçerlidir.
- `0 (T-2) + k10` geçersizdir.
- Bellek modeli tape/stack/data olarak 64 KB toplam alana bölünür.
- Varsayılan model: tape=32 KB, stack=8 KB, data=24 KB.
- Hücre tipi byte, word veya dword olabilir.
- Meta servis frame düzeni:
  - T-2 = arg1
  - T-1 = arg2
  - T   = arg0 / meta merkezi
  - T+1 = result
- `@20` toplama, `@23` bölme, `@90` FIFO push, `@91` FIFO pop, `@127` wild layout change servisidir.
- `sN=start,{text}` string tanımlar.
- `pN` string basar.
- `m128..m255` kullanıcı macro alanıdır.
- Native compiler macro’ları compile-time inline açar.
- Interpreter/full tool runtime macro call-stack destekler.

Kod yazarken:
- VS Code extension TypeScript ile yazılır.
- Toolchain çağrıları `child_process.execFile` ile yapılır.
- Trace dosyaları NDJSON formatındadır.
- Tape/Stack/Data/FIFO görselleştirme trace dosyasından veya extension içi interpreter'dan yapılır.
- Syntax highlighting TextMate grammar ile yapılır.
- Diagnostics extension içinde hızlı parser ile yapılır.
