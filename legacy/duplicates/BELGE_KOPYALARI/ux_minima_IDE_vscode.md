Evet Mete abi, **VS Code eklentisi** olarak yapalım. Bu yol en mantıklısı: hem editör hazır, hem Copilot ile aynı ortamda çalışır, hem de bizim `uxm31_full_tool.exe` çıktılarından **tape, stack, data, FIFO, flags, status** izleme panelleri yapılabilir.

VS Code tarafında dil renklendirme için TextMate grammar kullanılır; VS Code bunu resmi olarak dil eklentilerinin temel syntax highlighting yolu olarak anlatıyor. Tape/stack gibi özel paneller için de Tree View veya Webview View API kullanabiliriz; VS Code bu tip yan panel ve özel HTML tabanlı arayüzleri extension API ile destekliyor. ([Visual Studio Code][1])

## Karar: VS Code eklentisi + UX-MINIMA toolchain

Proje adı şöyle olsun:

```text
uxminima-vscode
```

Bu eklenti şunları yapacak:

```text
1. .uxm dosyalarını tanıyacak.
2. Syntax highlighting yapacak.
3. @ meta servisleri, sN stringleri, mN macro’ları, pN print stringleri renklendirecek.
4. Hatalı boşlukları ve hatalı adreslemeleri uyarı olarak gösterecek.
5. Sağ/sol panelde Tape, Stack, Data, FIFO izlemesi yapacak.
6. Flags ve Status byte canlı gösterilecek.
7. Run Trace butonu ile programı uxm31_full_tool.exe üzerinden çalıştıracak.
8. trace.ndjson dosyasını okuyup adım adım görselleştirecek.
9. UIR ve optimizer raporlarını panelde gösterecek.
10. Native Build komutu ile ASM → OBJ → EXE zincirini çalıştıracak.
11. Copilot’un UX-MINIMA dilini anlayabilmesi için repo içine özel dokümanlar koyacak.
```

## Önerilen proje ağacı

```text
uxminima-vscode/
├─ package.json
├─ tsconfig.json
├─ language-configuration.json
├─ syntaxes/
│  └─ uxm.tmLanguage.json
├─ snippets/
│  └─ uxm.code-snippets
├─ src/
│  ├─ extension.ts
│  ├─ commands.ts
│  ├─ diagnostics.ts
│  ├─ metaServices.ts
│  ├─ traceReader.ts
│  ├─ toolchain.ts
│  ├─ views/
│  │  ├─ memoryView.ts
│  │  ├─ traceView.ts
│  │  ├─ stackView.ts
│  │  ├─ fifoView.ts
│  │  └─ dataView.ts
│  └─ webview/
│     ├─ memoryPanel.html
│     ├─ memoryPanel.css
│     └─ memoryPanel.js
├─ tools/
│  ├─ uxm31_full_tool.exe
│  ├─ uxm31_compiler_full.exe
│  ├─ uxm31_runtime_fb_full.bas
│  └─ README_TOOLCHAIN.md
├─ docs/
│  ├─ UXM_LANGUAGE_SPEC.md
│  ├─ UXM_META_SERVICES.md
│  ├─ UXM_MEMORY_MODEL.md
│  ├─ UXM_IDE_PROTOCOL.md
│  ├─ UXM_TRACE_FORMAT.md
│  └─ UXM_EXAMPLES.md
├─ .github/
│  └─ copilot-instructions.md
└─ README.md
```

## Tape, Stack, Data, FIFO izlemesi nasıl yapılacak?

Bizim `uxm31_full_tool.exe run program.uxm build/program.trace.ndjson` komutu zaten JSON trace üretiyor. Eklenti bu trace dosyasını okuyacak ve adım adım şu alanları gösterecek:

```json
{
  "step": 12,
  "ip": 5,
  "op": "META",
  "ptr": 2,
  "sp": 0,
  "fifo_count": 1,
  "status": 0,
  "flags": 128,
  "current": 90,
  "meta_id": 91
}
```

İlk sürümde “canlı çalışırken izleme” yerine **trace replay** yapalım. Yani program çalışır, trace dosyası çıkar, IDE bu trace’i adım adım oynatır. Sonra `uxm31_full_tool.exe` içine `--step-server` veya `--watch-json` modu ekleyip gerçek canlı izlemeye geçeriz.

Panel düzeni şöyle olsun:

```text
UX-MINIMA Explorer
├─ Tape Watch
│  ├─ T:0 = 0
│  ├─ T:1 = 65
│  ├─ T:2 = 90  ← pointer
│  └─ T:3 = 65  ← result
├─ Stack Watch
│  ├─ SP = 2
│  ├─ S:0 = 65
│  └─ S:1 = 66
├─ FIFO Watch
│  ├─ Count = 2
│  ├─ F:0 = 65
│  └─ F:1 = 66
├─ Data Watch
│  ├─ D:0 = 72 'H'
│  ├─ D:1 = 69 'E'
│  └─ D:2 = 76 'L'
├─ Flags
│  ├─ Z = 0
│  ├─ C = 0
│  ├─ O = 0
│  ├─ S = 0
│  ├─ SGN = 0
│  ├─ END = 0
│  └─ WILD = 0
└─ Status
   └─ 0 OK
```

Tree View daha basit listeler için uygun. Bellek tablosu, renkli hücre gösterimi ve trace replay gibi daha zengin arayüz için Webview View daha iyi olur. VS Code’un resmi Webview API’si, extension içinde özel HTML/CSS/JS arayüzleri oluşturmaya izin veriyor. ([Visual Studio Code][2])

## Syntax highlighting kuralları

Renklendirilecek ana gruplar:

```text
Komutlar:
> < + - 0 . , [ ] $ % ? ! ; & | ^ ~ { } e

Meta:
@20
@90
@#
@127

String:
s1=0,{Merhaba\n}

String print:
p1

Macro:
m128={0+k65.}

Adresleme:
(T)
(T-2)
(T+1)
(T:10)
(D:0)
(S:0)
(SP)
(P)
(E)
(F)
(*T)
(*(T+1))

Pragma:
#mode safe
#mode normal
#mode wild
#cell byte
#memory tape=32,stack=8,data=24
#bounds on
#compare signed
#endian little

Yorum:
# TEST:
# EXPECT_OUTPUT:
```

Ayrıca diagnostic sistemi şu hataları gösterecek:

```text
0 (T:10)      HATA: komut ile adres arasında boşluk var
+ (T+1)       HATA
. (D:0)       HATA
(T + 1)       HATA: adresleme içinde boşluk var
@999          HATA: meta id 0..255 aralığında olmalı
m12={...}     HATA: kullanıcı macro id 128..255 olmalı
#memory tape=40,stack=8,data=20  HATA: toplam 64 KB değil
```

Diagnostics için basit eklenti içi validator yeterli olur. Daha sonra Language Server Protocol’e geçebiliriz; VS Code belgelerinde LSP’nin autocomplete, diagnostics, jump-to-definition gibi dil özelliklerini editörden ayırmak için kullanıldığı anlatılıyor. ([Visual Studio Code][3])

## Copilot için doküman sistemi

Copilot’un UX-MINIMA’yı doğru anlaması için repo içine mutlaka şu dosyaları koyacağız:

```text
.github/copilot-instructions.md
docs/UXM_LANGUAGE_SPEC.md
docs/UXM_META_SERVICES.md
docs/UXM_MEMORY_MODEL.md
docs/UXM_IDE_PROTOCOL.md
docs/UXM_TRACE_FORMAT.md
docs/UXM_EXAMPLES.md
```

GitHub ve VS Code artık proje özelinde Copilot’a bağlam vermek için custom instructions dosyalarını destekliyor; GitHub dokümanı repository custom instructions dosyalarının Copilot’a proje bağlamı, build/test kuralları ve doğrulama bilgisi vermek için kullanılabileceğini belirtiyor. VS Code tarafında da file-based custom instructions öneriliyor. ([GitHub Docs][4])

`.github/copilot-instructions.md` şöyle olmalı:

```markdown
# Copilot Instructions for UX-MINIMA

Bu repo UX-MINIMA x64 V3.1 dili, VS Code eklentisi ve toolchain entegrasyonu içindir.

UX-MINIMA Brainfuck benzeri fakat genişletilmiş bir tape/stack/data/FIFO tabanlı dildir.

Temel kurallar:
- .uxm dosyalarında komut içinde boşluk yasaktır.
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
- Toolchain çağrıları child_process ile yapılır.
- Trace dosyaları NDJSON formatındadır.
- Tape/Stack/Data/FIFO görselleştirme trace dosyasından yapılır.
- Syntax highlighting TextMate grammar ile yapılır.
- Diagnostics extension içinde hızlı parser ile yapılır.
```

Bu dosya Copilot’un yanlışlıkla UX-MINIMA’yı JavaScript, Brainfuck veya BASIC gibi yorumlamasını azaltır.

## VS Code komutları

Command Palette içinde şu komutlar olacak:

```text
UX-MINIMA: Run Trace
UX-MINIMA: Replay Trace
UX-MINIMA: Export UIR
UX-MINIMA: Export Optimizer Report
UX-MINIMA: Build Native EXE
UX-MINIMA: Open Memory Watch
UX-MINIMA: Open Meta Service Help
UX-MINIMA: Generate Program Template
UX-MINIMA: Validate Current File
```

VS Code task sistemi de external tool çalıştırmak için uygun; resmi dokümanda tasks.json veya task provider ile dış araçların editör içinden çalıştırılabileceği belirtiliyor. Biz build/run zincirini hem command olarak hem de task provider olarak verebiliriz. ([Visual Studio Code][5])

## İlk sürüm hedefi

İlk çalışan sürümde şunları yapalım:

```text
1. .uxm dosyası tanıma
2. Syntax highlighting
3. Snippetler
4. Run Trace
5. UIR Export
6. OPT Export
7. Native Build
8. Trace Viewer
9. Tape/Stack/FIFO/Data Watch paneli
10. Copilot instruction ve dil dokümanları
```

İkinci sürüm:

```text
1. Breakpoint benzeri IP durdurma
2. Step forward / step backward trace replay
3. Hücreye sağ tık: “Watch this cell”
4. Meta servis hover açıklaması
5. Yanlış frame kullanım uyarısı
6. Otomatik test runner
7. EXPECT_OUTPUT doğrulama
```

## Bence dosya üretimine buradan başlayalım

İlk gerçek dosya seti şu olmalı:

```text
package.json
language-configuration.json
syntaxes/uxm.tmLanguage.json
snippets/uxm.code-snippets
src/extension.ts
src/toolchain.ts
src/traceReader.ts
src/views/memoryView.ts
docs/UXM_LANGUAGE_SPEC.md
.github/copilot-instructions.md
```

Böyle başlarsak birkaç adımda çalışan VS Code eklentisi çıkar. Sonra memory watch panelini geliştirip tape/stack/data/FIFO hücrelerini renkli tablo olarak gösteririz.

[1]: https://code.visualstudio.com/api/language-extensions/syntax-highlight-guide?utm_source=chatgpt.com "Syntax Highlight Guide | Visual Studio Code Extension API"
[2]: https://code.visualstudio.com/api/extension-guides/webview?utm_source=chatgpt.com "Webview API | Visual Studio Code Extension API"
[3]: https://code.visualstudio.com/api/language-extensions/language-server-extension-guide?utm_source=chatgpt.com "Language Server Extension Guide"
[4]: https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot?utm_source=chatgpt.com "Adding repository custom instructions for GitHub Copilot"
[5]: https://code.visualstudio.com/docs/debugtest/tasks?utm_source=chatgpt.com "Integrate with External Tools via Tasks"
