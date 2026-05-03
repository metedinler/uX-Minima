Mete abi, aşağıdaki metin doğrudan **`KULLANMA_KILAVUZU.md`** olarak kaydedilebilir.

````markdown
# UX-MINIMA x64 V3.1 Full Kullanma Kılavuzu

## 1. UX-MINIMA Nedir?

UX-MINIMA, Brainfuck mantığından doğan fakat daha genişletilmiş bir düşük seviyeli programlama dilidir.
 Temelinde bir **tape**, yani hücrelerden oluşan doğrusal bellek alanı vardır. Programcı, bu tape üzerinde bir
 pointer ile gezinir, hücreleri artırır, azaltır, sıfırlar, yazdırır, okur, stack veya FIFO yapısına veri
 atar, meta servislerle daha gelişmiş işlemler çağırır.

Klasik Brainfuck yalnızca birkaç komutla çalışır. UX-MINIMA V3.1 ise bu yapıyı genişletir:

- Tape belleği vardır.
- Stack belleği vardır.
- Data belleği vardır.
- FIFO kuyruğu vardır.
- Byte / Word / Dword hücre tipi seçilebilir.
- Signed / unsigned çalışma modu vardır.
- Endian bayrağı vardır.
- Carry, overflow, zero, sign gibi flag sistemi vardır.
- Meta servislerle matematik, string, data, sort, FIFO, layout ve sistem işlemleri yapılabilir.
- Native x64 NASM çıktısı üretilebilir.
- FreeBASIC runtime ile Windows exe haline getirilebilir.
- JSON trace, UIR export, optimizer raporu ve IDE protokolü desteklenir.

UX-MINIMA’nın amacı klasik anlamda kolay bir dil olmak değildir. Bu dil, programcıya belleği, pointer’ı,
stack’i, veri akışını, koşullu dallanmayı ve işlemci mantığını doğrudan hissettiren küçük ama güçlü bir
deneysel sistemdir.

---

## 2. Dosya Seti

Full V3.1 sisteminde ana dosyalar şunlardır:

```text
uxm31_compiler_fb_full.bas      Native x64 NASM compiler
uxm31_runtime_fb_full.bas       Native exe için FreeBASIC runtime
uxm31_full_tool_fb.bas          Interpreter + JSON trace + UIR + optimizer + IDE motoru
````

Yardımcı dosyalar:

```text
tests_full\*.uxm                Test programları
build\                          Üretilen asm, obj, exe, json dosyaları
```

---

## 3. Gerekli Araçlar

Windows üzerinde şu araçlar gerekir:

```text
FreeBASIC compiler: fbc
NASM assembler: nasm
```

Komut satırından şu iki komut çalışıyorsa ortam hazırdır:

```bat
fbc --version
nasm -v
```

---

## 4. Genel Derleme Akışı

UX-MINIMA native derleme hattı şu şekildedir:

```text
.uxm kaynak dosyası
        ↓
uxm31_compiler_fb_full.bas
        ↓
x64 NASM .asm dosyası
        ↓
NASM ile .obj dosyası
        ↓
uxm31_runtime_fb_full.bas ile link
        ↓
Windows .exe
```

Örnek:

```bat
fbc uxm31_compiler_fb_full.bas -x uxm31_compiler_full.exe
uxm31_compiler_full.exe tests_full\test20_fifo_char_order.uxm build\test20.asm build\test20.uir.json build\test20.opt.json
nasm -f win64 build\test20.asm -o build\test20.obj
fbc uxm31_runtime_fb_full.bas build\test20.obj -x build\test20.exe
build\test20.exe
```

---

## 5. Interpreter / IDE / Trace Akışı

Native exe üretmeden, programı yorumlayıcı modda çalıştırmak için:

```bat
fbc uxm31_full_tool_fb.bas -x uxm31_full_tool.exe
uxm31_full_tool.exe run tests_full\test20_fifo_char_order.uxm build\test20.trace.ndjson
```

UIR üretmek için:

```bat
uxm31_full_tool.exe uir tests_full\test20_fifo_char_order.uxm build\test20.uir.json
```

Optimizer raporu üretmek için:

```bat
uxm31_full_tool.exe opt tests_full\test20_fifo_char_order.uxm build\test20.opt.json
```

IDE komutu ile çalıştırmak için örnek `ide_run.json`:

```json
{"command":"run","source":"tests_full\\test20_fifo_char_order.uxm","out":"build\\ide_trace.ndjson"}
```

Çalıştırma:

```bat
uxm31_full_tool.exe ide ide_run.json
```

---

## 6. Kaynak Dosya Uzantısı

UX-MINIMA kaynak dosyaları için önerilen uzantı:

```text
.uxm
```

Dosya UTF-8 BOM’suz kaydedilmelidir. Compiler BOM varsa temizlemeye çalışır, fakat en sağlıklı kullanım BOM’suz UTF-8’dir.

---

## 7. Bellek Modeli

UX-MINIMA V3.1 toplam 64 KB mantıksal alan kullanır.

Varsayılan model:

```text
Tape  : 32 KB
Stack : 8 KB
Data  : 24 KB
Toplam: 64 KB
```

Alternatif örnek:

```text
Tape  : 48 KB
Stack : 4 KB
Data  : 12 KB
Toplam: 64 KB
```

Kaynak dosyada pragma ile ayarlanabilir:

```text
#memory tape=48,stack=4,data=12
```

Hücre tipi seçimi:

```text
#cell byte
#cell word
#cell dword
```

Byte mod:

```text
1 hücre = 1 byte
0..255 unsigned
-128..127 signed
```

Word mod:

```text
1 hücre = 2 byte
0..65535 unsigned
-32768..32767 signed
```

Dword mod:

```text
1 hücre = 4 byte
0..4294967295 unsigned
```

---

## 8. Pragma Komutları

Pragma satırları `#` ile başlar.

### Çalışma modu

```text
#mode safe
#mode normal
#mode wild
```

Safe mode daha kontrollüdür. Wild mode, tehlikeli ve deneysel servisleri açar. 
Özellikle runtime memory layout değiştirme için wild mode gerekir.

### Hücre tipi

```text
#cell byte
#cell word
#cell dword
```

### Bellek dağılımı

```text
#memory tape=32,stack=8,data=24
#memory tape=48,stack=4,data=12
```

### Bounds kontrolü

```text
#bounds on
#bounds off
```

### Signed / unsigned karşılaştırma

```text
#compare signed
#compare unsigned
```

### Endian seçimi

```text
#endian little
#endian big
```

---

## 9. Temel Komutlar

| Komut      | Görev                                                  |            |
| ---------- | ------------------------------------------------------ | ---------- |
| `>`        | Pointer’ı sağa taşır                                   |            |
| `<`        | Pointer’ı sola taşır                                   |            |
| `+`        | Aktif hücreyi artırır                                  |            |
| `-`        | Aktif hücreyi azaltır                                  |            |
| `0`        | Hücreyi sıfırlar                                       |            |
| `.`        | Hücredeki değeri karakter olarak basar                 |            |
| `,`        | Klavyeden karakter okur                                |            |
| `[`        | Döngü başlangıcı                                       |            |
| `]`        | Döngü sonu                                             |            |
| `$`        | Stack push                                             |            |
| `%`        | Stack pop                                              |            |
| `?`        | Eşitlik karşılaştırması                                |            |
| `!`        | Büyüktür karşılaştırması                               |            |
| `;`        | Küçüktür karşılaştırması                               |            |
| `&`        | Bitwise AND                                            |            |
| `|`        | Bitwise OR                                             |            |
| `^`        | Bitwise XOR                                            |            |
| `~`        | Bitwise NOT                                            |            |
| `{`        | SHL, sola bit kaydırma, 2 ile çarpma                   |            |
| `}`        | SHR, sağa bit kaydırma, 2’ye bölme                     |            |
| `@N`       | Meta servis çağırır                                    |            |
| `@#`       | Aktif hücredeki sayıyı meta servis numarası kabul eder |            |
| `sN=...`   | String tanımlar                                        |            |
| `pN`       | String basar                                           |            |
| `mN={...}` | Macro tanımlar                                         |            |
| `#`        | Yorum / pragma                                         |            |
| `:`        | Branch / jump ailesi                                   |            |

---

## 10. Kısaltılmış Komut Kullanımı

Çok sayıda `+` veya `-` yazmak yerine `kN` kullanılabilir.

Şu:

```text
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
```

yerine:

```text
+k65
```

yazılır.

Örnek:

```text
0+k65.
```

Bu kod aktif hücreyi sıfırlar, 65 yapar ve `A` karakterini basar.

---

## 11. Adresleme Sistemi

Adresleme komuttan hemen sonra parantezle yazılır. Komut ile adres arasında boşluk olmamalıdır.

Doğru:

```text
0(T:10)+k65
.(T:10)
```

Yanlış:

```text
0 (T:10)
+ (T+1)
. (D:0)
```

Çünkü V3.1’de boşluk komut ayırıcı olarak düşünülür. Komutun içinde boşluk olmamalıdır.

### Adresleme biçimleri

| Adresleme  | Anlam                                    |
| ---------- | ---------------------------------------- |
| `(T)`      | Aktif tape hücresi                       |
| `(T+N)`    | Aktif pointer’dan N hücre sonrası        |
| `(T-N)`    | Aktif pointer’dan N hücre öncesi         |
| `(T:N)`    | Tape üzerinde mutlak N. hücre            |
| `(D:N)`    | Data alanında N. hücre                   |
| `(S:N)`    | Stack alanında N. hücre                  |
| `(SP)`     | Stack’in tepe hücresi                    |
| `(P)`      | Pointer değeri                           |
| `(E)`      | Status byte                              |
| `(F)`      | Flags word                               |
| `(*T)`     | Aktif hücredeki değeri adres kabul eder  |
| `(*(T+N))` | T+N hücresindeki değeri adres kabul eder |

Örnek:

```text
0(T:10)+k65
.(T:10)
```

Bu kod tape 10. hücreye 65 yazar ve `A` basar.

---

## 12. String Tanımlama ve Yazdırma

String tanımı:

```text
s1=0,{Merhaba UX-MINIMA\n}
```

Burada:

```text
s1      string numarasıdır
0       data alanındaki başlangıç hücresidir
{...}   yazılacak metindir
```

String basma:

```text
p1
```

Örnek:

```text
s1=0,{Merhaba Mete abi\n}
p1
```

Beklenen çıktı:

```text
Merhaba Mete abi
```

---

## 13. Stack Kullanımı

Stack LIFO mantığıyla çalışır. Son giren ilk çıkar.

Push:

```text
$
```

Pop:

```text
%
```

Örnek:

```text
0+k65$
0+k66$
%.
%.
```

Çıktı:

```text
BA
```

Çünkü önce 65, sonra 66 stack’e atılır. Pop yapılınca önce 66 çıkar.

---

## 14. FIFO Kullanımı

FIFO queue mantığıdır. İlk giren ilk çıkar.

Meta servisleri:

```text
@90   FIFO push
@91   FIFO pop
@92   FIFO peek
@93   FIFO count
@94   FIFO clear
```

Örnek:

```text
>>
0(T-1)+k65
@90
0(T-1)+k66
@90
@91
.(T+1)
@91
.(T+1)
```

Çıktı:

```text
AB
```

Stack LIFO, FIFO ise kuyruk mantığıdır. İkisi farklı amaçlar için kullanılır.

---

## 15. Meta Servis Mantığı

Meta servisler `@N` biçiminde çağrılır.

Genel frame mantığı:

```text
(T-2) = arg1
(T-1) = arg2
(T)   = çağrı merkezi / servis numarası / aktif hücre
(T+1) = sonuç
```

Örnek toplama:

```text
>>
0(T-2)+k10
0(T-1)+k20
@20
@61
```

Burada:

```text
@20 toplama yapar
@61 sonucu decimal basar
```

Çıktı:

```text
30
```

---

## 16. Temel Meta Servisler

| Meta  | Görev                        |
| ----- | ---------------------------- |
| `@0`  | OK / no-op                   |
| `@1`  | Ekranı temizler              |
| `@2`  | Cursor’u 1,1 konumuna alır   |
| `@3`  | Rastgele byte üretir         |
| `@4`  | Timer değeri üretir          |
| `@5`  | Yeni satır basar             |
| `@6`  | `[UXM META]` basar           |
| `@9`  | Status değerini sonuca yazar |
| `@10` | Status temizler              |
| `@12` | Status mesajını basar        |

---

## 17. Aritmetik Meta Servisleri

| Meta  | Görev         |
| ----- | ------------- |
| `@20` | Toplama       |
| `@21` | Çıkarma       |
| `@22` | Çarpma        |
| `@23` | Bölme         |
| `@24` | Mod / kalan   |
| `@25` | Min           |
| `@26` | Max           |
| `@27` | Mutlak değer  |
| `@28` | Negatif alma  |
| `@29` | Karşılaştırma |

Örnek bölme ve kalan:

```text
>>
0(T-2)+k20
0(T-1)+k6
@23
@61
@5
@24
@61
```

Çıktı:

```text
3
2
```

---

## 18. Matematik Meta Servisleri

| Meta  | Görev           |
| ----- | --------------- |
| `@40` | Sin             |
| `@41` | Cos             |
| `@42` | Tan             |
| `@43` | Hipotenüs       |
| `@44` | Arcsin          |
| `@45` | Arccos          |
| `@46` | Karekök         |
| `@47` | Sinh            |
| `@48` | Cosh            |
| `@49` | Tanh            |
| `@52` | Asinh           |
| `@53` | Acosh           |
| `@54` | Atanh           |
| `@55` | Log             |
| `@56` | Exp             |
| `@57` | Pow             |
| `@58` | Derece → radyan |
| `@59` | Radyan → derece |

Byte modda trigonometrik ölçek 100’dür.

Örnek:

```text
>>
0(T-1)+k30
@40
@61
```

Yaklaşık çıktı:

```text
50
```

Çünkü `sin(30°) = 0.5`, byte mod ölçek 100 olduğu için sonuç 50 olur.

---

## 19. I/O Meta Servisleri

| Meta  | Görev                         |
| ----- | ----------------------------- |
| `@60` | Arg2 değerini decimal basar   |
| `@61` | Sonuç hücresini decimal basar |
| `@62` | Stack pop edip decimal basar  |
| `@63` | Decimal sayı okur             |
| `@64` | Boşluk basar                  |
| `@67` | Hex basar                     |
| `@68` | Binary basar                  |

---

## 20. Pointer ve Layout Meta Servisleri

| Meta  | Görev                         |
| ----- | ----------------------------- |
| `@80` | Pointer’ı arg2 değerine taşır |
| `@81` | Pointer’a arg2 kadar ekler    |
| `@82` | Pointer değerini sonuca yazar |
| `@83` | Pointer geçerli mi sorgular   |
| `@84` | Tape cell sayısını verir      |
| `@85` | Data cell sayısını verir      |
| `@86` | Stack cell sayısını verir     |
| `@87` | Cell bit değerini verir       |
| `@88` | Cell byte değerini verir      |
| `@89` | Layout bilgisi basar          |

Örnek:

```text
>>
0(T-1)+k10
@80
0+k65.
```

Bu kod pointer’ı 10. hücreye taşır, oraya 65 yazar ve `A` basar.

---

## 21. Data Servisleri

| Meta   | Görev                   |
| ------ | ----------------------- |
| `@95`  | Data read               |
| `@96`  | Data write              |
| `@97`  | Data ASCII digit → sayı |
| `@98`  | Data block copy         |
| `@99`  | Data block clear        |
| `@102` | Data sort ascending     |
| `@103` | Data sort descending    |
| `@105` | Data linear search      |

Örnek data write / read:

```text
>>
0(T-2)+k5
0(T-1)+k88
@96
0(T-1)+k5
@95
.(T+1)
```

Çıktı:

```text
X
```

Çünkü ASCII 88, `X` karakteridir.

---

## 22. Tape Block ve Sort Servisleri

| Meta   | Görev                |
| ------ | -------------------- |
| `@100` | Tape sort ascending  |
| `@101` | Tape sort descending |
| `@104` | Tape linear search   |
| `@106` | Tape block copy      |
| `@107` | Tape block clear     |

Örnek:

```text
0(T:10)+k49
0(T:11)+k51
0(T:12)+k50
>>
0(T-2)+k10
0(T-1)+k3
@101
.(T:10)
.(T:11)
.(T:12)
```

Çıktı:

```text
321
```

---

## 23. Flags Sistemi

UX-MINIMA V3.1’de flags word bulunur.

| Flag    | Anlam           |
| ------- | --------------- |
| `Z`     | Zero flag       |
| `C`     | Carry flag      |
| `O`     | Overflow flag   |
| `S`     | Sign flag       |
| `SGN`   | Signed mode     |
| `END`   | Endian mode     |
| `WILD`  | Wild mode       |
| `BND`   | Bounds check    |
| `FIFO`  | FIFO kullanımı  |
| `ERR`   | Hata var        |
| `DIRTY` | Bellek değişti  |
| `PCHG`  | Pointer değişti |

Flag meta servisleri:

| Meta   | Görev                       |
| ------ | --------------------------- |
| `@120` | Unsigned mode               |
| `@121` | Signed mode                 |
| `@122` | Signed mode sorgusu         |
| `@123` | Little endian               |
| `@124` | Big endian                  |
| `@125` | Endian sorgusu              |
| `@126` | Flags değerini sonuca yazar |

---

## 24. Status Sistemi

Status byte son hata veya çalışma durumunu tutar.

| Kod  | Anlam                      |
| ---- | -------------------------- |
| `0`  | OK                         |
| `5`  | Invalid meta id            |
| `10` | Pointer out of bounds      |
| `11` | Stack overflow             |
| `12` | Stack underflow            |
| `13` | Arithmetic overflow        |
| `14` | Arithmetic underflow       |
| `15` | Division by zero           |
| `16` | Data bounds error          |
| `23` | Wild dışı işlem reddedildi |
| `24` | Protected meta id          |
| `26` | EOF                        |

Status okumak için:

```text
e
```

veya:

```text
e(T+1)
@61
```

Örnek:

```text
>>
0(T-2)+k20
0(T-1)
@23
e(T+1)
@61
```

Bölme sıfıra yapıldığı için çıktı:

```text
15
```

---

## 25. Branch / Jump Sistemi

Branch komutları `:` ile başlar.

| Komut  | Anlam                                       |
| ------ | ------------------------------------------- |
| `:+N`  | Aktif hücre sıfır değilse N komut ileri git |
| `:-N`  | Aktif hücre sıfır değilse N komut geri git  |
| `:0+N` | Aktif hücre sıfırsa N komut ileri git       |
| `:0-N` | Aktif hücre sıfırsa N komut geri git        |
| `::+N` | Koşulsuz N komut ileri git                  |
| `::-N` | Koşulsuz N komut geri git                   |
| `:z+N` | Z flag set ise ileri git                    |
| `:Z+N` | Z flag clear ise ileri git                  |
| `:c+N` | C flag set ise ileri git                    |
| `:C+N` | C flag clear ise ileri git                  |
| `:o+N` | O flag set ise ileri git                    |
| `:O+N` | O flag clear ise ileri git                  |
| `:s+N` | S flag set ise ileri git                    |
| `:S+N` | S flag clear ise ileri git                  |

Örnek:

```text
0
:0+3
0+k65.
0+k66.
```

Aktif hücre 0 olduğu için `A` basan bölüm atlanır ve çıktı:

```text
B
```

---

## 26. Döngü Sistemi

Klasik Brainfuck döngüsü korunmuştur.

```text
[
    aktif hücre sıfır değilse döngü devam eder
]
```

Örnek mantık:

```text
0+k5
[
.
-
]
```

Bu kod aktif hücre 5’ten 0’a düşene kadar karakter basar. Ancak karakter değeri kontrol edilmediği için terminalde görünür bir çıktı beklenmeyebilir.

Döngü yazarken kural şudur:

```text
Döngünün kontrol hücresi aktif pointer üzerindeki hücredir.
Döngü içinde bu hücreyi azaltmak veya değiştirmek gerekir.
Aksi halde sonsuz döngü oluşur.
```

---

## 27. Macro Sistemi

Macro tanımı:

```text
m128={0+k65.}
```

Macro çağrısı:

```text
@128
```

Native compiler tarafında macro’lar derleme zamanında inline açılır.

Interpreter / full tool tarafında runtime macro call-stack mantığı desteklenir.

Örnek:

```text
m128={0+k72. @129 0+k33.}
m129={0+k73.}
@128
```

Çıktı:

```text
HI!
```

---

## 28. Dinamik Meta Çağrı

`@#`, aktif hücredeki değeri meta servis numarası kabul eder.

Örnek:

```text
>>
0(T-1)+k65
0(T)+k90
@#
0(T)+k91
@#
.(T+1)
```

Burada:

```text
T hücresine 90 yazılır
@# çalışınca @90 çağrılmış olur
sonra T hücresine 91 yazılır
@# çalışınca @91 çağrılmış olur
```

Çıktı:

```text
A
```

---

## 29. Wild Mode Layout Change

Wild mode dışında layout değiştirme reddedilir.

Safe mode örneği:

```text
#mode safe
>>
0(T-2)+k48
0(T-1)+k4
0(T)+k12
@127
e(T+1)
@61
```

Beklenen status:

```text
23
```

Wild mode örneği:

```text
#mode wild
>>
0(T-2)+k48
0(T-1)+k4
0(T)+k12
@127
@84
@61
```

Bu kod runtime’da layout’u şu hale getirir:

```text
Tape  : 48 KB
Stack : 4 KB
Data  : 12 KB
```

Byte modda tape cell sayısı:

```text
49152
```

---

## 30. JSON Trace

Interpreter/full tool ile çalıştırıldığında her adım NDJSON formatında kaydedilir.

Komut:

```bat
uxm31_full_tool.exe run tests_full\test20_fifo_char_order.uxm build\test20.trace.ndjson
```

Trace satırları şu tiptedir:

```json
{"step":1,"ip":1,"op":"RIGHT","ptr":1,"sp":0,"status":0,"flags":128,"current":0}
```

Bu dosya IDE için çok önemlidir. Çünkü IDE bu dosyadan:

```text
hangi komut çalıştı
pointer nerede
stack kaçta
FIFO kaç elemanlı
status ne
flags ne
aktif hücre değeri ne
```

bilgisini okuyabilir.

---

## 31. UIR Export

UIR, compiler’ın kaynak kodu nasıl gördüğünü gösteren ara temsildir.

Komut:

```bat
uxm31_full_tool.exe uir tests_full\test20_fifo_char_order.uxm build\test20.uir.json
```

Native compiler da UIR üretir:

```bat
uxm31_compiler_full.exe tests_full\test20_fifo_char_order.uxm build\test20.asm build\test20.uir.json build\test20.opt.json
```

UIR içinde her komut şu bilgilerle yer alır:

```text
ip
op
amount
addr_kind
addr_val
meta_id
branch_target
mate
text
```

---

## 32. Pattern Optimizer

Optimizer şu tip dönüşümleri yapar:

```text
0 +k65      → SET 65
+k10 -k10   → iptal
+k5 +k3     → +k8
> <         → iptal
> >         → pointer hareket birleştirme
```

Optimizer raporu:

```bat
uxm31_full_tool.exe opt tests_full\test35_optimizer_visible_result.uxm build\test35.opt.json
```

Örnek rapor:

```json
{"msg":"CLEAR + INC/DEC -> SET @1"}
```

---

## 33. Programcı Nasıl Düşünmeli?

UX-MINIMA’da değişken adı yoktur. Her hücre bir değişken gibi düşünülebilir. Programcı, belleği kendisi düzenler.

Örneğin:

```text
T:0  sayaç
T:1  geçici değer
T:2  sonuç
D:0  string başlangıcı
S:0  stack alanı
```

Bu dilde program yazarken düşünce şu olmalıdır:

```text
1. Hangi hücre neyi temsil edecek?
2. Pointer nerede duracak?
3. Girdi argümanları T-2, T-1, T civarında mı tutulacak?
4. Sonuç T+1’e mi yazılacak?
5. Değer stack’e mi atılacak?
6. FIFO kuyruğu mu kullanılacak?
7. Data alanı sabit tablo gibi mi kullanılacak?
8. Sort, search veya block copy için meta servis daha uygun mu?
```

UX-MINIMA’da yüksek seviyeli dillerdeki değişken, array, function, if, goto, procedure gibi kavramların hepsi bellek, pointer, branch, stack ve meta servislerle kurulur.

---

## 34. Basit Program Örnekleri

### A basma

```text
0+k65.
```

### String basma

```text
s1=0,{Merhaba\n}
p1
```

### Toplama

```text
>>
0(T-2)+k12
0(T-1)+k30
@20
@61
```

### FIFO ile karakter sırası

```text
>>
0(T-1)+k65
@90
0(T-1)+k66
@90
@91
.(T+1)
@91
.(T+1)
```

### Data sort

```text
>>
0(T-2)
0(T-1)+k67
@96
0(T-2)+k1
0(T-1)+k65
@96
0(T-2)+k2
0(T-1)+k66
@96
0(T-2)
0(T-1)+k3
@102
```

---

## 35. Native ve Interpreter Arasındaki Fark

Native compiler:

```text
uxm31_compiler_fb_full.bas
```

şunu yapar:

```text
UXM → NASM ASM → OBJ → EXE
```

Macro’ları derleme zamanında inline açar.

Interpreter/full tool:

```text
uxm31_full_tool_fb.bas
```

şunu yapar:

```text
UXM → Parse → Optimize → Run → Trace
```

Runtime macro call-stack, JSON trace, IDE protokolü ve adım adım izleme için daha uygundur.

Özet:

```text
Native compiler = hızlı exe üretimi
Full tool interpreter = IDE, debug, trace, analiz, eğitim
```

---

## 36. Test Dosyalarında Beklenen Çıktı

Test dosyalarında beklenen çıktı `# EXPECT_OUTPUT:` ile yazılır.

Örnek:

```text
# TEST: FIFO push/pop karakter sırası
# EXPECT_OUTPUT: AB
>>
0(T-1)+k65
@90
0(T-1)+k66
@90
@91
.(T+1)
@91
.(T+1)
```

İleride test runner bu satırı okuyup gerçek çıktı ile karşılaştırabilir.

---

## 37. En Önemli Kurallar

1. Komut içinde boşluk kullanma.

Doğru:

```text
0(T-2)+k10
```

Yanlış:

```text
0 (T-2) + k10
```

2. Meta servislerde frame düzenini unutma.

```text
T-2 arg1
T-1 arg2
T   arg0 / servis merkezi
T+1 sonuç
```

3. Stack LIFO’dur.

4. FIFO ilk giren ilk çıkar mantığıdır.

5. Data alanı string ve tablo için uygundur.

6. Tape aktif çalışma belleğidir.

7. Wild mode güçlüdür ama tehlikelidir.

8. Branch mesafesi komut sayısıdır, byte sayısı değildir.

9. Döngü `[ ]` aktif hücreye bakar.

10. Native tarafta macro inline, interpreter tarafta macro call-stack mantığı vardır.

---

## 38. Kısa Meta Servis Haritası

```text
@0..@19      çekirdek servisler
@20..@39     aritmetik servisler
@40..@59     matematik servisleri
@60..@79     input/output servisleri
@80..@89     pointer ve layout sorgu servisleri
@90..@94     FIFO servisleri
@95..@107    data/tape block, sort, search servisleri
@120..@127   flags, endian, signed, wild layout servisleri
@128..@255   kullanıcı macro alanı
```

---

## 39. Önerilen Çalışma Düzeni

Bir program yazarken şu sırayı izle:

```text
1. Bellek planını yaz.
2. Hangi hücre ne olacak belirle.
3. String ve data tablolarını tanımla.
4. Pointer başlangıç noktasını seç.
5. Meta servis frame düzenini kur.
6. Programı full tool ile trace ederek dene.
7. UIR ve optimizer raporunu incele.
8. Sonra native exe üret.
```

Önerilen komut akışı:

```bat
uxm31_full_tool.exe run program.uxm build\program.trace.ndjson
uxm31_full_tool.exe uir program.uxm build\program.uir.json
uxm31_full_tool.exe opt program.uxm build\program.opt.json
uxm31_compiler_full.exe program.uxm build\program.asm build\program.uir.json build\program.opt.json
nasm -f win64 build\program.asm -o build\program.obj
fbc uxm31_runtime_fb_full.bas build\program.obj -x build\program.exe
build\program.exe
```

---

## 40. Sonuç

UX-MINIMA x64 V3.1 Full, küçük görünen ama bellek, pointer, stack, FIFO, data table, sort, branch, macro ve native x64 üretim mantığını bir araya getiren deneysel bir programlama sistemidir.

Bu dil klasik BASIC veya Python gibi yazılmaz. Bu dilde programcı, doğrudan belleğin üzerinde düşünür. Her hücre bir değişken, her pointer hareketi bir adresleme kararı, her meta servis küçük bir sistem çağrısı, her branch ise işlemci mantığına yakın bir karar noktasıdır.

Bu yüzden UX-MINIMA yalnızca bir ezoterik dil değildir. Aynı zamanda bilgisayar mimarisi, compiler tasarımı, interpreter mantığı, bellek modeli ve düşük seviye programlama eğitimi için kullanılabilecek özel bir deney alanıdır.

```
```
