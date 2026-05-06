**zip içindeki kodun gerçekliğine** 
---

# Kısa Hüküm

**Evet, sistem pratikte “iki başlı” görünüyor.**
Hatta daha teknik söylersem:

* **2 ana omurga**
* **2 yardımcı/yan omurga**
* ve bunların üstünde bir **ortak runtime + extension katmanı** var.

Yani bu klasör tek bir tekil compiler değil.
Aynı UX-Minima dilini işleyen **birden fazla yürütüm/derleme hattı** var.

---

# 1. Büyük Resim – Grafik Doküm

## 1A) Ana mimari haritası

```text
                         ┌──────────────────────────────┐
                         │         UXM SOURCE           │
                         │         (*.uxm)              │
                         └──────────────┬───────────────┘
                                        │
            ┌───────────────────────────┼───────────────────────────┐
            │                           │                           │
            │                           │                           │
            ▼                           ▼                           ▼
┌─────────────────────┐      ┌──────────────────────┐      ┌──────────────────────┐
│ A) KLASIK NATIVE    │      │ B) FINAL / ARGE      │      │ C) FULL TOOL         │
│ COMPILER HATTI      │      │ COMPILER HATTI       │      │ (legacy/yardımcı)    │
│ uxm31_compiler_fb   │      │ final/uxm31_comp...  │      │ uxm31_full_tool_fb   │
└──────────┬──────────┘      └──────────┬───────────┘      └──────────┬───────────┘
           │                            │                              │
           │ ASM üretir                 │ ASM üretir                   │ Trace/UIR/OPT üretir
           │                            │ yorumlar / step             │ yorumlar
           ▼                            │ diag / uir / opt / trace    │
┌─────────────────────┐                 │ IDE protocol                │
│ NASM                │                 ▼                              ▼
│ ASM -> OBJ          │      ┌──────────────────────┐      ┌──────────────────────┐
└──────────┬──────────┘      │ JSON / TRACE / UIR   │      │ Legacy Trace / UIR / │
           │                 │ DIAG / OPT çıktıları │      │ OPT çıktıları        │
           ▼                 └──────────┬───────────┘      └──────────────────────┘
┌─────────────────────┐                 │
│ FreeBASIC Runtime   │                 │
│ + OBJ -> EXE        │                 │
└──────────┬──────────┘                 │
           │                            │
           ▼                            ▼
┌─────────────────────┐      ┌──────────────────────┐
│ Native EXE          │      │ IDE / Analiz /       │
│ çalıştırılır        │      │ compile/interpret    │
└─────────────────────┘      └──────────────────────┘


                       Ayrıca bir de:

                       D) VS Code iç yorumlayıcısı
                       src/uxmInterpreter.ts
                       - hızlı kontrol
                       - internal trace
                       - memory watch
                       - native derleyici değildir
```

---

## 1B) Ortak alt katmanlar

```text
                    ┌──────────────────────────────────┐
                    │         SHARED LANGUAGE          │
                    │  tape / stack / data / meta /   │
                    │  macro / branch / addressing    │
                    └──────────────────────────────────┘
                                      │
                                      ▼
                    ┌──────────────────────────────────┐
                    │          RUNTIME CORE            │
                    │ uxm31_runtime_fb_full.bas        │
                    │ core meta, io, pointer, fifo,   │
                    │ data, sort, wild, status, flags │
                    └──────────────┬───────────────────┘
                                   │
         ┌─────────────────────────┼─────────────────────────┐
         │                         │                         │
         ▼                         ▼                         ▼
┌──────────────────┐    ┌────────────────────┐    ┌────────────────────┐
│ FP RUNTIME       │    │ MATRIX RUNTIME     │    │ MATH RUNTIME       │
│ runtime_fp_...   │    │ runtime_matrix_... │    │ runtime_math_...   │
└──────────────────┘    └────────────────────┘    └────────────────────┘

         ┌─────────────────────────┼─────────────────────────┐
         │                         │                         │
         ▼                         ▼                         ▼
┌──────────────────┐    ┌────────────────────┐    ┌────────────────────┐
│ lib/ux_fp_v1.uxm │    │ lib/ux_mat_v1.uxm  │    │ lib/ux_math_v1.uxm │
└──────────────────┘    └────────────────────┘    └────────────────────┘
```

---

# 2. “İki başlılık” tam olarak nereden geliyor?

Burada karışıklık yaratan şey sadece “aynı projede çok dosya olması” değil.
Asıl neden şu:

## 2.1 Aynı dilin birden fazla uygulaması var

UX-Minima dili:

* bir yerde **klasik native compiler** ile işleniyor,
* bir yerde **final/ARGE compiler** ile işleniyor,
* bir yerde **legacy full tool** ile yorumlanıyor,
* bir yerde de **VS Code iç yorumlayıcısı** ile çalıştırılıyor.

Yani tek bir parser/backend kütüphanesi yok;
aynı dil mantığı **birkaç farklı motor içinde tekrar yazılmış**.

Bu çok kritik nokta.

---

## 2.2 Build script’ler bir hattı kullanıyor, IDE başka hattı kullanıyor

### Klasik `.bat` hattı şunu kullanıyor:

* `build_all.bat`
* `build_one.bat`
* `run_tests.bat`

ve bunlar doğrudan:

* `uxm31_compiler_fb.bas`
* `uxm31_runtime_fb_full.bas`

üzerinden gidiyor.

---

### VS Code tarafı ise ağırlıklı olarak şunu kullanıyor:

* `final/uxm31_compiler_final.bas`
* `toolchain.ts`

ve native build gerektiğinde:

1. final compiler ile `.asm` üretiyor
2. NASM ile `.obj` yapıyor
3. runtime ile `.exe` linkliyor

Yani IDE yolu ile klasik `.bat` yolu **aynı frontend’i kullanmıyor**.

---

## 2.3 Aynı isimli ama birebir aynı olmayan dosyalar var

Bu da önemli.

Klasörde hem kökte hem alt klasörlerde benzer dosyalar var.

### Aynı ama farklı örnekler:

* `uxm31_compiler_fb.bas`
* `compiler/uxm31_compiler_fb.bas`

Bunlar **aynı dosya değil**.

Aynı şekilde:

* `uxm31_runtime_fb_full.bas`
* `runtime/uxm31_runtime_fb_full.bas`

bunlar da **tam birebir aynı değil**.

Ama:

* `uxm31_full_tool_fb.bas`
* `tools/uxm31_full_tool_fb.bas`

bunlar **aynı** görünüyor.

Bu şunu gösteriyor:

> proje içinde bazı dosyalar “kökte çalışan otorite sürüm”,
> bazıları ise “klasöre göre kopya/alt sürüm” gibi duruyor.

Bu da “iki başlı / çok başlı” hissini artırıyor.

---

# 3. Kod gerçekliğine göre ana hatlar

Şimdi her hattı ayrı ayrı anlatıyorum.

---

# 3A) HAT A — KLASİK NATIVE DERLEME HATTI

Bu hat proje içinde en doğrudan “compiler -> asm -> obj -> exe” hattıdır.

## Temel dosyalar

* `build_all.bat`
* `build_one.bat`
* `run_tests.bat`
* `uxm31_compiler_fb.bas`
* `uxm31_runtime_fb_full.bas`

## Gerçek akış

```text
.uxm
  ↓
uxm31_compiler_fb.bas
  ↓
.asm
  ↓
NASM
  ↓
.obj / .o
  ↓
uxm31_runtime_fb_full.bas + FreeBASIC
  ↓
.exe
```

---

## Bu hattın görevi nedir?

Bu hattın görevi:

* UXM kaynak kodunu parse etmek
* instruction dizisine dönüştürmek
* branch/macro/string/meta çözümlemek
* NASM x64 assembly üretmek
* runtime ile linklenebilecek native çıktı hazırlamak

---

## Koddaki ana aşamalar

`uxm31_compiler_fb.bas` içinde ana akış sırası çok net:

1. `InitDefaults()`
2. `ReadFileToSrc()`
3. `ParsePragmas()`
4. `ApplyMemoryModel()`
5. `FirstPassDefinitions()`
6. `ParseProgram()`
7. `ValidateBranches()`
8. `GenerateASM()`

Bu şu demek:

### Frontend yapıyor:

* pragma okuma
* bellek modeli kurma
* string/macro ön tarama
* program parse etme
* branch doğrulama

### Backend yapıyor:

* `EmitHeader`
* `EmitStringInitializers`
* `EmitInstr`
* `EmitFooter`

ile doğrudan assembly üretme.

---

## Bu hattın yapabildikleri

### Çekirdek dil

* tape hareketi
* increment/decrement
* clear
* putc/getc
* loop `[ ]`
* push/pop
* eq/gt/lt
* and/or/xor/not/shl/shr
* status
* meta çağrıları
* branch
* print string

### Adresleme

Koddaki adresleme ailesi zengin:

* `(T)`
* `(T+N)`
* `(T-N)`
* `(T:N)`
* `(D:N)`
* `(S:N)`
* `(SP)`
* `(P)`
* `(E)`
* `(F)`
* `(*T)`
* `(*(T+N))`
* `(D@T)`
* `(D@T+N)`
* `(D@T-N)`
* `(D@(T-2)+N)`

### Meta servis tabanı

* core
* arithmetic
* io
* pointer/memory
* fifo/data/sort/wild

### Extension bağları

Bu compiler içine gerçekten include edilmiş:

* `math_extensions/compiler/arge_parse_math_additions.bas`
* `math_extensions/compiler/arge_parse_matrix_additions.bas`

Yani **math ve matrix için parser seviyesi ekler** var.

---

## Bu hattın runtime tarafı ne yapıyor?

`uxm31_runtime_fb_full.bas` tarafında:

* bellek alanı
* tape/data/stack erişimi
* flags/status
* IO
* meta dispatch
* FIFO
* data/tape block işlemleri
* pointer işlemleri
* wild mode mantığı

var.

Ve en önemlisi, runtime sonunda şu modülleri include ediyor:

* `runtime/runtime_fp_services.bas`
* `math_extensions/runtime/runtime_matrix_services.bas`
* `math_extensions/runtime/runtime_math_services.bas`

Yani native EXE hattı sadece “core runtime” değil;
**FP + Matrix + Math servisleri de bağlı**.

---

## Bu hattın yapamadıkları / sınırlamaları

Bu hattın en büyük sınırlaması şu:

### 1. Doğrudan interpreter değil

Bu hat esas olarak **ASM üretici compiler**.

Yani:

* trace
* JSON diagnostic
* UIR export
* optimizer report
* step mode
* IDE response protocol

gibi şeyler bunun ana rolü değil.

---

### 2. IDE merkezli değil

Bu hattın dili ve native üretimi güçlü ama:

* IDE protocol backend’i değil
* JSON tabanlı tanılama motoru değil

---

### 3. FP tarafı “parser extension” olarak değil daha çok runtime/lib ağırlıklı

Math ve matrix tarafında compiler include’ları var.
Ama FP tarafında parser include değil, daha çok:

* `lib/ux_fp_v1.uxm`
* `runtime/runtime_fp_services.bas`

üzerinden yürüyen bir yapı var.

Yani FP daha çok **kütüphane + runtime servis** katmanı gibi duruyor.

---

### 4. Matrix testleri varsayılan test zincirinde yok

`run_tests.bat` şunları döndürüyor:

* `tests`
* `math_extensions\tests_math`
* `tests_fp`

Ama `tests_matrix` bu default zincirde **yok**.

Bu da önemli bir operasyonel gerçek.

---

## Ne zaman bu hat kullanılmalı?

Bu hat şu amaçlar için ana aday:

* gerçek native EXE üretmek
* klasik test zincirini koşturmak
* “dilin native derleyicisi” olarak çalışmak
* performans odaklı üretim hattı kurmak

---

# 3B) HAT B — FINAL / ARGE COMPILER HATTI

Bu ikinci ana omurga.

## Temel dosyalar

* `final/uxm31_compiler_final.bas`
* `build_final_compiler.bat`
* `run_final_probe.bat`
* `final/UXM31_FINAL_ARGE_COMPILER.md`

---

## Bu hattın temel karakteri nedir?

Bu hat sadece compiler değil.

Bu dosya içinde bir arada şu roller var:

* parser
* validator
* optimizer
* interpreter
* step engine
* trace exporter
* UIR exporter
* diagnostics exporter
* ASM generator
* IDE protocol backend

Yani bu daha çok:

> **“tek merkezli araştırma / analiz / IDE / compiler aracı”**

gibi.

---

## Bu hattın çalışma modları

Kod ve belgeye göre modlar şunlar:

* `compile`
* `interpret`
* `step`
* `all`
* `--ide-in / --ide-out`

Yani tek exe ile:

```text
compile  -> ASM + UIR + DIAG + OPT
interpret -> yorumla + trace
step -> adım adım çalıştır
all -> compile + interpret + export
ide -> IDE request/response backend
```

---

## Bu hattın koddaki ana akışı

`Main()` içinde açıkça şunları yapıyor:

1. `ParseCLI()`
2. `ParseIdeJson()` gerekirse
3. `ReadFile()`
4. `ParsePragmasAndArge()`
5. `ApplyMemory()`
6. `FirstPassDefs()`
7. `ParseProgram()`
8. `ValidateProgram()`
9. `OptimizeProgram()`
10. `ExportDiagnostics()`
11. `ExportUIR()`
12. `ExportOpt()`
13. `RunProgram()` (interpret/step ise)
14. `GenerateASM()` (compile ise)
15. `ExportIdeResult()`

Bu yapı klasik compiler’dan çok daha geniş.

---

## Bu hattın yapabildikleri

### 1. Yorumlayabilir

Kodun içinde gerçek interpreter var:

* `RunProgram()`
* `ExecInstr()`
* `RuntimeMeta()`

### 2. Step mode var

Adım sayısı sınırı var, trace üretimi var.

### 3. Diagnostics üretiyor

JSON olarak hata/uyarı/tanılama çıkarabiliyor.

### 4. UIR üretiyor

Ara temsil / instruction raporu çıkarabiliyor.

### 5. Optimizer raporu üretiyor

Örneğin:

* clear + inc/dec -> set
* ardışık inc/dec birleştirme

gibi optimizasyon olaylarını kaydediyor.

### 6. IDE backend olabiliyor

`--ide-in` ve `--ide-out` desteği var.

### 7. ASM da üretebiliyor

Yani bu sadece interpreter değil; compiler rolü de var.

---

## Bu hattın yapamadıkları / sınırlamaları

Burada çok önemli ve koddan açık görülen bir şey var:

### 1. ASM emitter “ana native hat kadar oturmuş” görünmüyor

Özellikle emitter tarafında şu tarz işaretler var:

* `EmitSetFlagsFromRAX(): ; flags update minimal`
* branch emitter içinde bazı flag branch’lerde:
  `"flag branch not expanded in minimal emitter"`

Yani final compiler’ın **interpreter/analysis/IDE tarafı daha güçlü**,
ASM emitter tarafı ise daha **ARGE / minimal emitter** karakterinde.

Bu çok önemli.

---

### 2. Varsayılan klasik test hattı bunu kullanmıyor

`.bat` dosyaları klasik hatta bağlı.
Final compiler kendi dünyasında çalışıyor.

---

### 3. Native EXE için tek başına son adım değil

Final compiler genelde ASM üretir.
Sonra EXE gerekirse:

* NASM
* runtime
* FreeBASIC

ile ayrıca bağlanır.

Yani “tek exe her şeyi yapıyor” gibi görünse de native EXE üretiminde yine runtime/link katmanına ihtiyaç var.

---

## Bu hat ne için ideal?

Bu hat özellikle şunlar için çok değerli:

* IDE entegrasyonu
* trace
* adım adım yürütme
* tanılama
* UIR / optimizer raporları
* dil üzerinde araştırma / analiz
* frontend doğrulama

Yani bunu ben **ARGE/IDE merkezli omurga** olarak görüyorum.

---

# 3C) HAT C — FULL TOOL / LEGACY MONOLITIK ARAÇ

Bu üçüncü önemli hat ama ana üretim hattı değil.

## Temel dosyalar

* `uxm31_full_tool_fb.bas`
* `tools/uxm31_full_tool_fb.bas`

Bu dosya kökte ve `tools/` altında aynı.

---

## Bu dosya ne?

Bu, tek dosyada toplanmış bir:

* parser
* interpreter
* trace exporter
* UIR exporter
* optimizer
* IDE command reader
* meta runtime benzeri motor

Yani bu dosya, klasik compiler ile final compiler arasında bir **yardımcı / geçiş / tool** gibi duruyor.

---

## Gerçek rolü ne?

VS Code eklentisindeki `toolchain.ts` bunu “legacy” işler için kullanıyor:

* `runTrace`
* `exportUIR`
* `exportOPT`

Yani extension bunu şu tür işlerde çağırıyor:

* “Legacy Run Trace”
* “Legacy Export UIR”
* “Legacy Export OPT”

Bu isimlendirme bile bize şunu söylüyor:

> Bu hat halen kullanılıyor ama ana yön artık final compiler tarafına kaymış.

---

## Yapabildikleri

* parse
* çalıştırma
* trace
* UIR export
* OPT export
* IDE komut dosyası okuma
* macro call stack
* fifo/data/sort/wild işlemleri

---

## Yapamadıkları / sınırlamaları

* klasik `.bat` native build zincirinin merkezinde değil
* son tasarımın “nihai otoritesi” gibi görünmüyor
* VS Code’da daha çok legacy yardımcı olarak kullanılıyor
* native EXE üretim zincirinin ana kapısı değil

---

## Bu hat ne işe yarıyor?

Ben bunu şöyle adlandırırım:

> **araç katmanı / yardımcı araştırma motoru / geçiş aracı**

---

# 3D) HAT D — VS CODE İÇ YORUMLAYICISI

Bu dördüncü hat.

## Temel dosya

* `ide/uxminima-vscode/src/uxmInterpreter.ts`

---

## Bu ne yapıyor?

Bu, VS Code içinde hızlıca:

* parse
* validate
* internal trace
* memory watch için veri üretme

işlerini yapıyor.

---

## Yapabildikleri

* hızlı syntax/semantic kontrol
* internal trace
* memory görünümü
* instruction listesi çıkarma
* lightweight yorumlama

---

## Yapamadıkları

* native EXE üretmez
* asıl FreeBASIC compiler’ın birebir yerine geçmez
* otoriter runtime değildir
* tam son üretim hattı değildir

---

## Rolü

Bu bir:

> **editör içi hızlı geri bildirim motoru**

Yani asıl derleyici değil, IDE yardımcısı.

---

# 4. “İki başlılık” aslında nasıl sınıflanmalı?

Ben bunu teknik olarak şöyle sınıflandırıyorum:

---

## ANA OMRUGA 1 — Üretim / Native omurga

**Merkez:** `uxm31_compiler_fb.bas` + `uxm31_runtime_fb_full.bas`

Amaç:

* gerçek `.asm`
* gerçek `.obj`
* gerçek `.exe`

Bu hat **native ürün hattı**.

---

## ANA OMRUGA 2 — ARGE / IDE omurga

**Merkez:** `final/uxm31_compiler_final.bas`

Amaç:

* UIR
* diagnostics
* optimizer
* trace
* step mode
* IDE protocol
* gerektiğinde `.asm`

Bu hat **analiz/araştırma/IDE hattı**.

---

## YARDIMCI OMRUGA 3 — Legacy tool

**Merkez:** `uxm31_full_tool_fb.bas`

Amaç:

* trace
* UIR
* OPT
* interpreter tarzı yardımcı işlevler

---

## YARDIMCI OMRUGA 4 — IDE internal interpreter

**Merkez:** `src/uxmInterpreter.ts`

Amaç:

* editör içi hızlı geri bildirim

---

# 5. Katman bazlı sistem mimarisi

Şimdi yukarıdaki hatlardan bağımsız olarak UX-Minima’nın gerçek mimarisini katman katman anlatayım.

---

## Katman 0 — Kaynak dil yüzeyi

Bu katmanda kullanıcı `.uxm` yazar.

Dil öğeleri:

* tape hareket
* stack
* data
* macro
* string
* meta call
* branch
* status
* addressing
* pragmas
* extension lib kullanımı

---

## Katman 1 — Frontend / Parse katmanı

Bu katman:

* source dosyayı okur
* pragma’ları çözer
* bellek modelini uygular
* string/macro ön tanımlarını alır
* instruction listesi oluşturur

Burada önemli gerçek:

**Bu frontend tek yerde yazılmamış.**
Birden fazla dosyada benzer frontend mantığı var:

* `uxm31_compiler_fb.bas`
* `final/uxm31_compiler_final.bas`
* `uxm31_full_tool_fb.bas`
* `src/uxmInterpreter.ts`

Yani dilin parse/yürütüm semantiği tekrar tekrar uygulanmış.

Bu da mimari olarak çok önemli.

---

## Katman 2 — İç temsil / instruction modeli

Klasik compiler’da instruction bilgisi:

* paralel diziler şeklinde

örneğin:

* op
* amount
* addrKind
* addrVal
* metaId
* branch hedefi
* string id
* macro text

gibi.

Final compiler’da ise daha düzenli bir `Type TInstr` yapısı var.

Yani:

* klasik hat = array tabanlı representation
* final hat = struct/type tabanlı representation

Bu da iki hattın ayrı evrim geçirdiğini gösteriyor.

---

## Katman 3 — Yürütüm / yorumlama katmanı

Bu katman sadece final compiler, full tool ve TS interpreter tarafında var.

İşlevler:

* instruction’ı sırayla çalıştırmak
* ptr/sp/status/flags yönetmek
* meta çağrıları çözmek
* trace olayları üretmek
* output üretmek

Bu yüzden bu katman daha çok:

* `final/uxm31_compiler_final.bas`
* `uxm31_full_tool_fb.bas`
* `ide/uxminima-vscode/src/uxmInterpreter.ts`

tarafında oturuyor.

---

## Katman 4 — Native codegen katmanı

Bu katman:

* instruction listesinden NASM x64 asm üretir.

Özellikle:

* header
* bellek yerleşimi
* string initializers
* instruction emit
* footer

Bu katman iki yerde var:

* klasik compiler
* final compiler

Ama klasik compiler’daki codegen daha “ana üretim codegen’i” gibi,
final compiler’daki codegen ise daha “minimal/ARGE emitter” gibi.

---

## Katman 5 — Runtime katmanı

Bu katman native program çalışınca devreye girer.

Ana görevleri:

* tape/data/stack belleğini yönetmek
* meta servislerini sağlamak
* IO yapmak
* bounds / status / flags yönetmek
* extension çağrılarını çözmek

Ana dosya:

* `uxm31_runtime_fb_full.bas`

---

## Katman 6 — Extension katmanı

Burada alan genişliyor.

### Matrix

* `runtime_matrix_services.bas`
* `ux_mat_v1.uxm`

### FP

* `runtime_fp_services.bas`
* `ux_fp_v1.uxm`

### Math

* `runtime_math_services.bas`
* `ux_math_v1.uxm`

Bu tasarım çok önemli çünkü UX-Minima burada “çekirdek + extension” biçimine oturuyor.

---

## Katman 7 — Araçlar / IDE / raporlama

Burada:

* VS Code extension
* trace
* diagnostic JSON
* UIR
* optimizer raporu
* final docs
* memory watch

yer alıyor.

Bu da projeyi sadece compiler olmaktan çıkarıp **toolchain** haline getiriyor.

---

# 6. Meta servis mimarisi

Kod gerçekliğinde UX-Minima’nın büyük gücü meta servis sistemi.

Kabaca harita şöyle okunuyor:

```text
Core / basic meta       -> düşük id aralıkları
FIFO / data / sort      -> 90+ bölgesi
Matrix                  -> @160..@176
FP                      -> @200..@224
Math ext                -> @240..@244 ve @250..@254
```

Bu yapı sayesinde dil çekirdeği çok büyütülmeden yetenek eklenmiş.

---

# 7. Hangi hat ne yapıyor? – Karşılaştırma matrisi

Aşağıya çok net bir matris koyuyorum.

## 7A) Hat bazlı yetenek matrisi

| Özellik                      | Klasik Native Hat |        Final/ARGE Hat |            Full Tool |   IDE İç Yorumlayıcı |
| ---------------------------- | ----------------- | --------------------: | -------------------: | -------------------: |
| `.uxm` parse                 | Evet              |                  Evet |                 Evet |                 Evet |
| Native ASM üretimi           | Evet              |                  Evet |       Ana amaç değil |                Hayır |
| NASM + OBJ + EXE hattı       | Evet              | Dolaylı / ASM sonrası |                Hayır |                Hayır |
| Gerçek runtime ile EXE       | Evet              |        Evet (dolaylı) |                Hayır |                Hayır |
| Yorumlayıcı                  | Hayır             |                  Evet |                 Evet |                 Evet |
| Step mode                    | Hayır             |                  Evet | Kısmi / trace odaklı |                Kısmi |
| JSON diagnostics             | Hayır / zayıf     |                  Evet |              Kısıtlı |                Basit |
| UIR export                   | Hayır             |                  Evet |                 Evet | İç temsil olarak var |
| OPT report                   | Hayır             |                  Evet |                 Evet |                Hayır |
| IDE protocol                 | Hayır             |                  Evet |                Kısmi |        IDE içi zaten |
| VS Code entegrasyonu         | Dolaylı           |                 Güçlü |               Legacy |             Doğrudan |
| Varsayılan `.bat` test hattı | Evet              |                 Hayır |                Hayır |                Hayır |

---

## 7B) Otorite matrisi

| İş                          | Otorite dosya/hat                                     |
| --------------------------- | ----------------------------------------------------- |
| Klasik native build         | `uxm31_compiler_fb.bas` + `uxm31_runtime_fb_full.bas` |
| Klasik test zinciri         | `run_tests.bat`                                       |
| Final analiz/diag/trace     | `final/uxm31_compiler_final.bas`                      |
| Legacy trace/UIR/OPT        | `uxm31_full_tool_fb.bas`                              |
| Editör içi hızlı yürütüm    | `src/uxmInterpreter.ts`                               |
| Native EXE’yi IDE’den kurma | `toolchain.ts` + final compiler + NASM + runtime      |

---

# 8. Kod gerçekliğine göre güçlü taraflar

Burada gerçekten güçlü bulduğum kısımlar şunlar:

## 8.1 Çekirdek dil + extension ayrımı var

Bu çok olumlu.

## 8.2 Native hat gerçekten موجود/gerçek

Yani kağıt üstünde değil:

* `.asm`
* `.o/.obj`
* `.exe`

çıktıları `build/` içinde gerçekten var.

## 8.3 Final/ARGE hattı sadece hayal değil

Gerçekten:

* interpret
* step
* diag
* uir
* opt
* ide

rollerini taşıyor.

## 8.4 VS Code eklentisi ciddi

Sadece syntax renklendirme değil:

* build
* trace
* memory watch
* final compiler komutları
* internal interpreter

var.

## 8.5 Matrix / FP / Math gerçekten kodda karşılık bulmuş

Sadece belge değil:

* runtime servisleri
* lib dosyaları
* test dosyaları
* build artifaktları

var.

---

# 9. Kod gerçekliğine göre mimari sıkışma / yapısal sorun

Burada “hata raporu” istemedin, o yüzden doğrudan mimari gerçekliği söylüyorum:

## Asıl yapısal durum şu:

**Sistem modüler ama tek-merkezli değil.**

Bu yüzden şu etki oluşuyor:

```text
aynı dil
+ birden fazla parser
+ birden fazla interpreter
+ iki ayrı asm emitter
+ farklı build girişleri
= iki başlı / çok başlı his
```

Yani sorun “dosyalar dağınık”tan çok şu:

> **language semantics birden fazla motorda paralel yaşıyor.**

Bu, araştırma açısından zenginlik;
ama mimari açıdan çok merkezlilik demek.

---

# 10. Benim teknik sınıflandırmam – en doğru isimlendirme

Ben bu projeyi şöyle isimlendiririm:

## UX-Minima aslında şudur:

### A. Dil çekirdeği

* tape/stack/data tabanlı DSL

### B. Native compiler hattı

* gerçek assembly/native üretim hattı

### C. Runtime platformu

* meta servisler + memory + IO + extensions

### D. ARGE/analysis compiler hattı

* IDE/trace/UIR/diag/step odaklı

### E. Extension ekosistemi

* FP
* Math
* Matrix

### F. IDE/tooling katmanı

* VS Code
* internal interpreter
* memory watch
* diagnostics

Yani bu artık basit bir compiler değil.
Bu daha çok:

> **çok hatlı, deneysel ama çalışan bir DSL toolchain ailesi**

gibi.

---

# 11. En net sonuç

Şunu net söyleyebilirim:

## UX-Minima bu zip içinde “tek compiler” değil.

**Kod gerçekliğine göre yapı şudur:**

```text
1) Bir klasik/native üretim hattı var.
2) Bir final/ARGE analiz-yorumlama hattı var.
3) Bir legacy full-tool hattı var.
4) Bir de IDE içi hafif yorumlayıcı var.
5) Bunların hepsi aynı dili farklı amaçlarla yürütüyor.
```

Bu yüzden senin “compiler iki başlı gibi” gözlemin doğru.

Ama daha doğru teknik ifade şu olur:

> **Sistem iki ana başlı, iki yardımcı başlı, ortak runtime ve extension katmanlı çok merkezli bir UX-Minima toolchain mimarisine sahip.**

---

# 12. Sana kullanım kılavuzuna koymalık kısa metin

İstersen bunu doğrudan kılavuza koyabilirsin:

```text
UX-Minima V3.1 Full Final Real, tek bir derleyici dosyasından oluşan basit bir sistem değildir. Kod gerçekliğinde proje iki ana omurgaya sahiptir: (1) .uxm kaynağını NASM x64 assembly’ye ve oradan runtime aracılığıyla native EXE’ye dönüştüren klasik/native derleme hattı, (2) yorumlama, adım adım yürütme, diagnostic, UIR, optimizer ve IDE protokolü sağlayan final/ARGE hattı. Bunlara ek olarak legacy full-tool hattı ile VS Code iç yorumlayıcısı yardımcı yürütüm katmanları olarak yer alır. Tüm bu hatlar ortak dil çekirdeğini, runtime katmanını ve FP/Matrix/Math extension servislerini paylaşır; ancak parse, yorumlama ve çıktı üretimi tek bir merkezden değil, birden fazla motor üzerinden yürütülür.
```

---

İstersen bir sonraki adımda sana bunun devamı olarak şunlardan **birini** hazırlayayım:

1. **“Dosya dosya görev haritası”**

   * her `.bas`, `.bat`, `.ts`, `.uxm` ne işe yarıyor

2. **“Komut / meta / extension matrisi”**

   * hangi meta hangi runtime’a gidiyor

3. **“Klasik hat vs final hat satır satır karşılaştırma”**

   * aynı görev iki hatta nasıl uygulanmış

4. **“Temiz mimari önerisi”**

   * bu çok başlı yapı tek omurgaya nasıl indirgenir

İstersen ben sıradaki cevapta **dosya dosya görev haritasını** çıkarayım.

---

# 13. Sprint 1 Baslangic Kapsami: e Komutu ve ERR Bayragi

Bu dosyada tespit edilen cok hatli mimari icin ilk standardizasyon adimi su sekilde kilitlendi:

## 13.1 Ortak kural

```text
Bir komut standarda girdiyse,
4 hatta da ya calisacak
ya da acikca "bilincli desteklenmiyor" olarak isaretlenecek.
```

Sessiz fark yasak.

## 13.2 Sprint 1 teknik konusu

```text
Komut: e
Meta: @9, @10, @11, @12, @13, @14, @15
Flag: FLAGS.R (runtime error present)
```

Core servisleri:

```text
@13 ERR FLAG SET
@14 ERR FLAG RESET
@15 ERR FLAG READ
```

## 13.3 Hat bazli zorunlu davranis

1. Klasik native hat
  - Runtime `e` ve `@9..@15` semantigini deterministik yurutur.
2. Final/ARGE hat
  - Interpreter ile ASM emit sonucunda status/ERR bayragi gorunumu uyumlu olur.
3. Full tool
  - `e` ve `@9..@15` icin native ile ayni sonuc verir.
4. VS Code ic yorumlayici
  - Destek varsa birebir semantik verir.
  - Destek yoksa bilincli desteklenmiyor tanisini acikca uretir.

## 13.4 Sprint 1 cikti dosyalari

```text
MASTER_TAKIP_DOKUMANI_V31.md
servis komutlari.md
tests/UX-MINIMA x64 V3.1 Tasar#U0131m Belgesi.md
UXM_V31_Kod_Belge_Matris_Paketi/uxm31_matrix_out/meta_servis_matrisi.csv
UXM_V31_Kod_Belge_Matris_Paketi/uxm31_matrix_out/UXM_KOD_BELGE_MATRIS_RAPORU.md
```
