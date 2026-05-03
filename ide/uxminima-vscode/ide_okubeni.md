Mete abi, başladım ve ilk çalışan VS Code eklentisi paketini hazırladım:

[uxminima-vscode.zip](sandbox:/mnt/data/uxminima-vscode.zip)

İçinde şunlar var:

```text
uxminima-vscode/
├─ package.json
├─ tsconfig.json
├─ language-configuration.json
├─ syntaxes/uxm.tmLanguage.json
├─ snippets/uxm.code-snippets
├─ src/
│  ├─ extension.ts
│  ├─ diagnostics.ts
│  ├─ toolchain.ts
│  ├─ traceReader.ts
│  ├─ uxmInterpreter.ts
│  ├─ metaServices.ts
│  └─ views/memoryView.ts
├─ docs/
│  ├─ UXM_LANGUAGE_SPEC.md
│  ├─ UXM_META_SERVICES.md
│  ├─ UXM_MEMORY_MODEL.md
│  ├─ UXM_TRACE_FORMAT.md
│  ├─ UXM_IDE_PROTOCOL.md
│  └─ UXM_EXAMPLES.md
├─ .github/copilot-instructions.md
├─ tools/README_TOOLCHAIN.md
└─ examples/
   ├─ fifo_watch.uxm
   └─ data_sort.uxm
```

Bu ilk paket şu işleri yapıyor:

```text
.uxm dosyalarını tanır
syntax highlighting yapar
snippet verir
hatalı boşluk/adresleme/macro/meta uyarısı verir
@ meta servisleri için hover açıklaması verir
internal trace çalıştırır
Tape / Stack / FIFO / Data izleme paneli açar
UIR / OPT / native build komutlarını toolchain üzerinden çağırır
Copilot için proje talimat dosyası içerir
```

Kurulum:

```bat
cd uxminima-vscode
npm install
npm run compile
code .
```

Sonra VS Code içinde `F5` ile Extension Development Host açılır.

Denemek için:

```text
examples/fifo_watch.uxm
```

dosyasını aç ve Command Palette’ten çalıştır:

```text
UX-MINIMA: Internal Trace & Memory Watch
```

Bu komut, daha toolchain EXE’lerine gerek kalmadan TypeScript içindeki hafif UXM interpreter ile çalışır ve şu panelleri gösterir:

```text
Tape Window
Stack
FIFO
Data Non-Zero
Flags / Status
Output
```

Native toolchain için daha sonra şu dosyaları `tools/` klasörüne koyacağız veya VS Code Settings’ten yollarını göstereceğiz:

```text
uxm31_full_tool.exe
uxm31_compiler_full.exe
uxm31_runtime_fb_full.bas
nasm.exe
fbc.exe
```

Bu paket bizim UX-MINIMA IDE’nin VS Code temelidir.
