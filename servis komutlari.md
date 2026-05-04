Mete abi, belgeleri tarayınca iki şey net görünüyor:

1. **İlk kılavuzda `@128..@255` kullanıcı macro alanı** diye ayrılmış.
2. Sonraki genişlemelerde biz bu alanın bir kısmını **standart kütüphanelere** ayırmışız: `m160..m199` matris, `m200..m239` floating point, `m240..m259` polinom/expression/türev/integral gibi. VS Code eklentisindeki meta yardım da `@128..@255` alanını kullanıcı macro alanı olarak gösteriyor; fakat UX-MAT belgesinde `m160..m189` ve `m190..m199` matris alanı olarak ayrılmış durumda.  

Bu yüzden en doğru final ayrım şu olmalı:

```text
@0..@127      çekirdek / runtime host servisleri
@128..@159    kullanıcı tanımlı macro / deney alanı
@160..@199    UX-MAT matris / vektör / array
@200..@239    UX-FP decimal floating point
@240..@259    UX-CALC polinom / expression / türev / integral
@260..@399    ileri bilimsel kütüphane alanları
@400+         ileride genişletilmiş servis alanı / opsiyonel
```

`@!N` ise ayrı anlam taşıyor: **macro aramasını bypass edip doğrudan host/runtime servisini çağırır.** Yani `m210={@!210}` gibi kullanınca kullanıcı `@210` yazar, macro çalışır, macro içinden host FP servisi çağrılır. Bu ayrım VS Code final entegrasyon notlarında da geçiyor. 

---

# 1. Meta çağrı tipleri

| Yazım        | Anlamı                           | Kullanım                                            |
| ------------ | -------------------------------- | --------------------------------------------------- |
| `@N`         | Normal meta/macro çağrısı        | Macro varsa macro açılır; yoksa host servis çalışır |
| `@!N`        | Zorla host/runtime çağrısı       | Macro’yu bypass eder                                |
| `@#`         | Dinamik meta çağrısı             | Aktif hücredeki değer servis numarasıdır            |
| `mN={...}`   | Kullanıcı/macro tanımı           | `@N` ile çağrılır                                   |
| `@128..@159` | Önerilen serbest kullanıcı alanı | Kütüphanelerle çakışmaması için                     |
| `@160+`      | Standart kütüphane alanları      | Matris, FP, istatistik vb.                          |

---

# 2. Çekirdek servis tablosu: `@0..@19`

|     Servis | Ad              | Frame        | Görev                            |
| ---------: | --------------- | ------------ | -------------------------------- |
|       `@0` | OK / no-op      | none         | Status OK / işlem yok            |
|       `@1` | CLS             | none         | Console ekranı temizler          |
|       `@2` | LOCATE 1,1      | none         | Cursor’u başlangıca alır         |
|       `@3` | RANDOM BYTE     | `T+1=result` | 0–255 arası rastgele byte        |
|       `@4` | TIMER           | `T+1=result` | Timer tabanlı değer              |
|       `@5` | NEWLINE         | none         | Yeni satır basar                 |
|       `@6` | PRINT META INFO | none         | `[UXM META]` gibi bilgi basar    |
|       `@7` | VERSION MAJOR   | `T+1`        | Major version; tasarımda ayrıldı |
|       `@8` | VERSION MINOR   | `T+1`        | Minor version; tasarımda ayrıldı |
|       `@9` | STATUS READ     | `T+1=status` | Status byte okur                 |
|      `@10` | STATUS CLEAR    | none         | Status / ERR bayrağını temizler  |
|      `@11` | STATUS SET      | `T-1=status` | Status değerini set eder         |
|      `@12` | STATUS PRINT    | none         | Status açıklamasını basar        |
|      `@13` | ERR FLAG SET    | none         | FLAGS.R bayrağını 1 yapar        |
|      `@14` | ERR FLAG RESET  | none         | FLAGS.R bayrağını 0 yapar        |
|      `@15` | ERR FLAG READ   | `T+1=R`      | FLAGS.R değerini okur            |
| `@16..@19` | Reserved core   | —            | Çekirdek için boş bırakılmalı    |

`@3 RANDOM BYTE`, `@4 TIMER` ve `@46 SQRT` artık opsiyonel değil, bilimsel/GA/istatistik tarafı için çekirdek servis kabul edilmeli. `metaServices.ts` içinde `@3`, `@4`, temel status ve aritmetik servisleri zaten tanımlı. 

`e` komutu ve status/ERR bayrağı için önerilen standart macro yardımcıları:

```text
m128={e}
m129={e@60}
m130={@!13}
m131={@!14}
m132={@!10@!14}
```

Anlam:

```text
m128  status byte'ı aktif hücreye al
m129  status byte'ı decimal yazdır
m130  ERR bayrağını set et
m131  ERR bayrağını reset et
m132  status ve ERR bayrağını birlikte temizle
```

---

# 3. Aritmetik servisler: `@20..@39`

|     Servis | Ad                  | Frame                    | Görev                           |
| ---------: | ------------------- | ------------------------ | ------------------------------- |
|      `@20` | ADD                 | `T-2 + T-1 -> T+1`       | Toplama                         |
|      `@21` | SUB                 | `T-2 - T-1 -> T+1`       | Çıkarma                         |
|      `@22` | MUL                 | `T-2 * T-1 -> T+1`       | Çarpma                          |
|      `@23` | DIV                 | `T-2 / T-1 -> T+1`       | Bölme; sıfıra bölmede status=15 |
|      `@24` | MOD                 | `T-2 mod T-1 -> T+1`     | Kalan                           |
|      `@25` | MIN                 | `min(T-2,T-1)->T+1`      | Minimum                         |
|      `@26` | MAX                 | `max(T-2,T-1)->T+1`      | Maksimum                        |
|      `@27` | ABS                 | `abs(T-1)->T+1`          | Mutlak değer                    |
|      `@28` | NEG                 | `-T-1 -> T+1`            | İşaret çevirme                  |
|      `@29` | CMP                 | `T-2 ? T-1 -> T+1/flags` | Karşılaştırma                   |
|      `@30` | RND_RANGE           | `min=T-2 max=T-1 -> T+1` | Önerilen: aralıklı random       |
|      `@31` | RND_SEED            | `seed=T-1`               | Önerilen: random seed           |
|      `@32` | RND_FLOAT01         | `T+1`                    | Önerilen: 0..1 fixed/FP         |
|      `@33` | DIV_UNSIGNED        | `T-2/T-1 -> T+1`         | Unsigned bölme                  |
|      `@34` | DIV_SIGNED          | `T-2/T-1 -> T+1`         | Signed bölme                    |
|      `@35` | MOD_UNSIGNED        | `T-2 mod T-1`            | Unsigned kalan                  |
|      `@36` | MOD_SIGNED          | `T-2 mod T-1`            | Signed kalan                    |
| `@37..@39` | Reserved arithmetic | —                        | Gelecek aritmetik               |

Kılavuzda `@20..@39` aritmetik servis aralığı olarak ayrılmış; `@20..@24` temel servisler tabloda açık geçiyor. 

---

# 4. Matematik / bilimsel servisler: `@40..@59`

|     Servis | Ad            | Frame                        | Görev                  |
| ---------: | ------------- | ---------------------------- | ---------------------- |
|      `@40` | SIN           | `sin(T-1)->T+1`              | Derece cinsinden sinüs |
|      `@41` | COS           | `cos(T-1)->T+1`              | Derece cinsinden cos   |
|      `@42` | TAN           | `tan(T-1)->T+1`              | Derece cinsinden tan   |
|      `@43` | HYPOT         | `sqrt((T-2)^2+(T-1)^2)->T+1` | Hipotenüs              |
|      `@44` | ASIN          | `T-1 -> T+1`                 | Arcsin                 |
|      `@45` | ACOS          | `T-1 -> T+1`                 | Arccos                 |
|      `@46` | SQRT          | `sqrt(T-1)->T+1`             | Karekök                |
|      `@47` | SINH          | `T-1 -> T+1`                 | Hiperbolik sinüs       |
|      `@48` | COSH          | `T-1 -> T+1`                 | Hiperbolik cos         |
|      `@49` | TANH          | `T-1 -> T+1`                 | Hiperbolik tan         |
| `@50..@51` | Reserved math | —                            | Boş                    |
|      `@52` | ASINH         | `T-1 -> T+1`                 | Asinh                  |
|      `@53` | ACOSH         | `T-1 -> T+1`                 | Acosh                  |
|      `@54` | ATANH         | `T-1 -> T+1`                 | Atanh                  |
|      `@55` | LOG           | `T-1 -> T+1`                 | Log                    |
|      `@56` | EXP           | `T-1 -> T+1`                 | Üstel                  |
|      `@57` | POW           | `T-2 ^ T-1 -> T+1`           | Üs alma                |
|      `@58` | DEG_TO_RAD    | `T-1 -> T+1`                 | Derece → radyan        |
|      `@59` | RAD_TO_DEG    | `T-1 -> T+1`                 | Radyan → derece        |

---

# 5. I/O servisleri: `@60..@79`

|     Servis | Ad              | Frame          | Görev                                        |
| ---------: | --------------- | -------------- | -------------------------------------------- |
|      `@60` | PRINT ARG2      | `T-1`          | Arg2 değerini decimal basar                  |
|      `@61` | PRINT RESULT    | `T+1`          | Sonuç hücresini decimal basar                |
|      `@62` | PRINT STACK POP | stack          | Stack pop edip decimal basar                 |
|      `@63` | READ DECIMAL    | `input -> T+1` | Decimal sayı okur                            |
|      `@64` | PRINT SPACE     | none           | Boşluk basar                                 |
| `@65..@66` | Reserved I/O    | —              | Boş                                          |
|      `@67` | PRINT HEX       | `T-1`          | Hex basar                                    |
|      `@68` | PRINT BIN       | `T-1`          | Binary basar                                 |
|      `@69` | PRINT CHAR/RAW  | `T-1`          | Önerilen                                     |
| `@70..@79` | Reserved I/O    | —              | Console / screen ile çakışmaması için dikkat |

İlk kılavuzda `@60..@79` input/output alanı olarak ayrılmış. 

---

# 6. Pointer / layout servisleri: `@80..@89`

| Servis | Ad            | Frame      | Görev                         |
| -----: | ------------- | ---------- | ----------------------------- |
|  `@80` | SET POINTER   | `T-1 -> P` | Pointer’ı taşır               |
|  `@81` | ADD POINTER   | `P += T-1` | Pointer’a ekleme              |
|  `@82` | GET POINTER   | `P -> T+1` | Pointer değerini döndürür     |
|  `@83` | POINTER VALID | `T+1`      | Pointer geçerli mi            |
|  `@84` | TAPE CELLS    | `T+1`      | Tape cell sayısını döndürür   |
|  `@85` | DATA CELLS    | `T+1`      | Data cell sayısını döndürür   |
|  `@86` | STACK CELLS   | `T+1`      | Stack cell sayısını döndürür  |
|  `@87` | CELL BITS     | `T+1`      | Hücre bit genişliği           |
|  `@88` | CELL BYTES    | `T+1`      | Hücre byte genişliği          |
|  `@89` | PRINT LAYOUT  | none       | Bellek layout bilgisini basar |

---

# 7. FIFO servisleri: `@90..@94`

| Servis | Ad         | Frame | Görev                           |
| -----: | ---------- | ----- | ------------------------------- |
|  `@90` | FIFO PUSH  | `T-1` | FIFO’ya değer atar              |
|  `@91` | FIFO POP   | `T+1` | FIFO’dan ilk değeri alır        |
|  `@92` | FIFO PEEK  | `T+1` | FIFO ilk değeri çıkarmadan okur |
|  `@93` | FIFO COUNT | `T+1` | FIFO eleman sayısı              |
|  `@94` | FIFO CLEAR | none  | FIFO temizler                   |

---

# 8. Data / tape block / sort servisleri: `@95..@107`

|       Servis | Ad                  | Frame                                 | Görev                       |
| -----------: | ------------------- | ------------------------------------- | --------------------------- |
|        `@95` | DATA READ           | `D[T-1] -> T+1`                       | Data alanından okur         |
|        `@96` | DATA WRITE          | `D[T-2] = T-1`                        | Data alanına yazar          |
|        `@97` | DATA DIGIT          | `D[T-1] ASCII digit -> T+1`           | ASCII rakamı sayıya çevirir |
|        `@98` | DATA BLOCK COPY     | `src=T-2 dst=T-1 count=T`             | Data blok kopyalar          |
|        `@99` | DATA BLOCK CLEAR    | `dst=T-2 count=T-1`                   | Data blok temizler          |
|       `@100` | TAPE SORT ASC       | `start=T-2 count=T-1`                 | Tape küçükten büyüğe        |
|       `@101` | TAPE SORT DESC      | `start=T-2 count=T-1`                 | Tape büyükten küçüğe        |
|       `@102` | DATA SORT ASC       | `start=T-2 count=T-1`                 | Data küçükten büyüğe        |
|       `@103` | DATA SORT DESC      | `start=T-2 count=T-1`                 | Data büyükten küçüğe        |
|       `@104` | TAPE SEARCH         | `start=T-2 count=T-1 target=T -> T+1` | Tape lineer arama           |
|       `@105` | DATA SEARCH         | `start=T-2 count=T-1 target=T -> T+1` | Data lineer arama           |
|       `@106` | TAPE BLOCK COPY     | `src=T-2 dst=T-1 count=T`             | Tape blok kopyalar          |
|       `@107` | TAPE BLOCK CLEAR    | `dst=T-2 count=T-1`                   | Tape blok temizler          |
| `@108..@109` | Reserved block/data | —                                     | Boş                         |

Bu servisler `metaServices.ts` dosyasında da doğrudan listelenmiş. 

---

# 9. Console / screen servisleri: `@110..@119`

Bu aralığı biz sonradan **EXE çift tıklayınca kapanmasın, terminal/ekran kontrolü olsun** diye ayırdık. Bunlar standarda alınmalı ama bazı dosyalara henüz tam gömülmemiş olabilir.

|       Servis | Ad                     | Frame             | Görev                              |
| -----------: | ---------------------- | ----------------- | ---------------------------------- |
|       `@110` | SCREEN_PAUSE / WAITKEY | none veya `T+1`   | Bir tuş bekler; program kapanmasın |
|       `@111` | SCREEN_WAITKEY         | none              | Tuş bekleme                        |
|       `@112` | SCREEN_CLEAR           | none              | Console temizle                    |
|       `@113` | SCREEN_LOCATE          | `row=T-2 col=T-1` | Cursor konumlandır                 |
|       `@114` | SCREEN_COLOR           | `fg=T-2 bg=T-1`   | Console renk                       |
|       `@115` | SCREEN_INFO            | none              | UXM ekran bilgisi                  |
|       `@116` | SCREEN_WIDE            | none              | Console width/height ayarı         |
| `@117..@119` | Reserved screen        | —                 | Grafik/console için boş            |

Kısa pause macro’su için önerilen:

```text
m110={,(T:100)}
```

veya host sürüm:

```text
m110={@!110}
```

---

# 10. Flags / endian / layout servisleri: `@120..@127`

| Servis | Ad                 | Frame                             | Görev                                      |
| -----: | ------------------ | --------------------------------- | ------------------------------------------ |
| `@120` | UNSIGNED MODE      | none                              | Unsigned moda geçer                        |
| `@121` | SIGNED MODE        | none                              | Signed moda geçer                          |
| `@122` | SIGNED QUERY       | `T+1`                             | Signed mod açık mı                         |
| `@123` | LITTLE ENDIAN      | none                              | Little endian                              |
| `@124` | BIG ENDIAN         | none                              | Big endian                                 |
| `@125` | ENDIAN QUERY       | `T+1`                             | Endian bayrağı                             |
| `@126` | FLAGS QUERY        | `T+1`                             | Flags word                                 |
| `@127` | WILD LAYOUT CHANGE | `tapeKB=T-2 stackKB=T-1 dataKB=T` | Sadece wild mode: bellek layout değiştirir |

Bu aralık hem kılavuzda hem `metaServices.ts` içinde var. 

Not: `FLAGS QUERY` sonucunda bit `12` değeri `R` yani runtime error present bayrağıdır. Bu bit, `@13/@14/@15` ve `@10/@11` status yönetimi ile tutarlı kalmalıdır.

---

# 11. Kullanıcı tanımlı / library alanı ayrımı

Burada eski ve yeni ayrımı netleştirmek lazım.

## Eski / ilk karar

|       Aralık | İlk anlam             |
| -----------: | --------------------- |
| `@128..@255` | Kullanıcı macro alanı |

Bu karar kılavuzda ve VS Code meta yardımında geçiyor; native compiler tarafında compile-time inline, interpreter/full tool tarafında runtime macro call-stack olarak çalışacağı yazılmış.  

## Güncel / genişletilmiş öneri

|       Aralık | Final önerilen anlam                           |
| -----------: | ---------------------------------------------- |
| `@128..@159` | Gerçek kullanıcı tanımlı macro / deney alanı   |
| `@160..@199` | UX-MAT / matris, vektör, array                 |
| `@200..@239` | UX-FP / decimal floating point                 |
| `@240..@259` | UX-CALC / polinom, expression, türev, integral |
| `@260..@289` | UX-STAT / istatistik                           |
| `@290..@319` | UX-GA / genetik algoritma                      |
| `@320..@349` | UX-ML / neural network                         |
| `@350..@379` | UX-BIO / DNA, RNA, protein                     |
| `@380..@399` | UX-SIM / grid, hücresel otomasyon              |
|      `@400+` | Genişletilmiş servis alanı                     |

Benim önerim: **final standarda göre kullanıcıya güvenli serbest alan `@128..@159` olsun.** Çünkü `@160+` tarafını artık bilimsel kütüphaneler için ayırdık.

---

# 12. UX-MAT servisleri: `@160..@199`

UX-MAT belgesinde `m160..m189` temel servis, `m190..m199` ileri servisler için ayrılmıştır; ayrıca safe/normal modda çalışması ve `@!N` host hızlandırıcıya gitmesi kararlaştırılmış. 

|       Servis |        Macro | Ad                    | Frame                                             | Görev                                   |
| -----------: | -----------: | --------------------- | ------------------------------------------------- | --------------------------------------- |
|       `@160` |       `m160` | MAT_INIT              | `T-4 base, T-3 rows, T-2 cols, T-1 type, T scale` | Matris başlat                           |
|       `@161` |       `m161` | MAT_CLEAR             | `T-4 base`                                        | Matris verisini temizle                 |
|       `@162` |       `m162` | MAT_SET               | `T-4 base, T-3 row, T-2 col, T-1 value`           | Eleman yaz                              |
|       `@163` |       `m163` | MAT_GET               | `T-4 base, T-3 row, T-2 col -> T+1`               | Eleman oku                              |
|       `@164` |       `m164` | MAT_FILL              | `T-4 base, T-1 value`                             | Tüm matrisi doldur                      |
|       `@165` |       `m165` | MAT_COPY              | `T-4 dst, T-3 src`                                | Matris kopyala                          |
|       `@166` |       `m166` | MAT_PRINT             | `T-3 base`                                        | Matris yazdır                           |
|       `@167` |       `m167` | MAT_ADD               | `T-4 dst, T-3 A, T-2 B`                           | Matris toplama                          |
|       `@168` |       `m168` | MAT_SUB               | `T-4 dst, T-3 A, T-2 B`                           | Matris çıkarma                          |
|       `@169` |       `m169` | MAT_SCALAR_MUL        | `T-4 dst, T-3 A, T-2 scalar`                      | Skaler çarp                             |
|       `@170` |       `m170` | MAT_MUL               | `T-4 dst, T-3 A, T-2 B`                           | Matris çarpımı                          |
|       `@171` |       `m171` | MAT_TRANSPOSE_COPY    | `T-4 dst, T-3 A`                                  | Transpose kopya                         |
|       `@172` |       `m172` | MAT_IDENTITY          | `T-4 dst, T-3 size, T-2 type, T-1 scale`          | Birim matris                            |
|       `@173` |       `m173` | MAT_TRACE             | `T-3 A -> T+1`                                    | Köşegen toplamı                         |
|       `@174` |       `m174` | MAT_SHAPE             | `T-3 A`                                           | Şekil bilgisi                           |
|       `@175` |       `m175` | MAT_DET2              | `T-3 A -> T+1`                                    | 2x2 determinant                         |
|       `@176` |       `m176` | MAT_PRINT_RAW         | `T-3 A`                                           | Ham matris yazdır                       |
|       `@177` |       `m177` | MAT_ROW_SWAP          | `T-4 base, T-3 r1, T-2 r2`                        | Satır değiştir                          |
|       `@178` |       `m178` | MAT_ROW_SCALE         | `T-4 base, T-3 row, T-2 scalar`                   | Satır ölçekle                           |
|       `@179` |       `m179` | MAT_ROW_ADD           | `T-4 base, T-3 dstRow, T-2 srcRow, T-1 scalar`    | Satır ekleme                            |
|       `@180` |       `m180` | VEC_DOT               | `T-3 A, T-2 B -> T+1`                             | Vektör dot product                      |
|       `@181` |       `m181` | VEC_NORM2_INT         | `T-3 A -> T+1`                                    | Norm kare                               |
|       `@182` |       `m182` | MAT_COMPARE_SHAPE     | `T-3 A, T-2 B -> T+1`                             | Boyut karşılaştır                       |
|       `@183` |       `m183` | MAT_IS_SQUARE         | `T-3 A -> T+1`                                    | Kare matris mi                          |
|       `@184` |       `m184` | MAT_TO_SCREEN_CHARS   | `T-3 A, T-2 zeroCh, T-1 nonZeroCh`                | Matrisi ASCII ekran gibi bas            |
|       `@185` |       `m185` | MAT_FROM_SCREEN_CHARS | `T-4 base, T-3 dataStart`                         | Ayrılmış / V1.1                         |
| `@186..@189` | `m186..m189` | Reserved MAT V1       | —                                                 | Boş                                     |
| `@190..@199` | `m190..m199` | Advanced MAT reserved | —                                                 | Gauss, inverse, eigen vb. için ayrılmış |

---

# 13. UX-FP decimal floating point: `@200..@239`

|       Servis |  Macro | Ad                 | Frame                             | Görev                 |
| -----------: | -----: | ------------------ | --------------------------------- | --------------------- |
|       `@200` | `m200` | FP_INIT16          | `T-2 base`                        | FP16 blok başlat      |
|       `@201` | `m201` | FP_INIT32          | `T-2 base`                        | FP32 blok başlat      |
|       `@202` | `m202` | FP_ZERO            | `T-2 base`                        | Sayıyı sıfırla        |
|       `@203` | `m203` | FP_COPY            | `T-2 dst, T-1 src`                | FP kopyala            |
|       `@204` | `m204` | FP_NORMALIZE       | `T-2 base`                        | Normalize et          |
|       `@205` | `m205` | FP_SET_SIGN        | `T-2 base, T-1 sign`              | İşaret ayarla         |
|       `@206` | `m206` | FP_SET_EXP         | `T-2 base, T-1 expSign, T expAbs` | Üs ayarla             |
|       `@207` | `m207` | FP_SET_LIMB        | `T-2 base, T-1 limb, T value`     | Mantissa limb yaz     |
|       `@208` | `m208` | FP_GET_LIMB        | `T-2 base, T-1 limb -> T+1`       | Mantissa limb oku     |
|       `@209` | `m209` | FP_PRINT_RAW       | `T-1 base`                        | Ham FP bas            |
|       `@210` | `m210` | FP_ADD             | `T-2 dst, T-1 A, T B`             | FP toplama            |
|       `@211` | `m211` | FP_SUB             | `T-2 dst, T-1 A, T B`             | FP çıkarma            |
|       `@212` | `m212` | FP_MUL             | `T-2 dst, T-1 A, T B`             | FP çarpma             |
|       `@213` | `m213` | FP_DIV             | `T-2 dst, T-1 A, T B`             | FP bölme              |
|       `@214` | `m214` | FP_COMPARE         | `T-1 A, T B -> T+1`               | Karşılaştır           |
|       `@215` | `m215` | FP_ABS             | `T-2 dst, T-1 src`                | Mutlak değer          |
|       `@216` | `m216` | FP_NEG             | `T-2 dst, T-1 src`                | Negatifle             |
|       `@217` | `m217` | FP_ROUND16         | `T-2 base`                        | 16 hane yuvarla       |
|       `@218` | `m218` | FP_ROUND32         | `T-2 base`                        | 32 hane yuvarla       |
|       `@219` | `m219` | FP_TRUNC           | `T-2 base`                        | Kesir at / trunc      |
|       `@220` | `m220` | FP_FROM_INT        | `T-2 dst, T-1 int`                | Integer’dan FP        |
|       `@221` | `m221` | FP_FROM_DEC_STRING | `T-2 dst, T-1 dataStringStart`    | Decimal string’den FP |
|       `@222` | `m222` | FP_TO_DEC_STRING   | `T-2 src, T-1 outStringStart`     | FP’yi stringe yaz     |
|       `@223` | `m223` | FP_PRINT_DEC       | `T-1 base`                        | Decimal yazdır        |
|       `@224` | `m224` | FP_SCALE10         | `T-2 base, T-1 shift`             | 10 tabanlı ölçekle    |
|       `@225` | `m225` | FP_ALIGN_EXP       | internal                          | Üs hizalama           |
|       `@226` | `m226` | FP_SHIFT_LEFT_DEC  | internal                          | Decimal sola kaydır   |
|       `@227` | `m227` | FP_SHIFT_RIGHT_DEC | internal                          | Decimal sağa kaydır   |
| `@228..@229` |      — | Reserved FP        | —                                 | Boş                   |
|       `@230` | `m230` | FP_SQRT            | `T-2 dst, T-1 src`                | FP karekök            |
|       `@231` | `m231` | FP_HYPOT           | `T-2 dst, T-1 A, T B`             | FP hipotenüs          |
|       `@232` | `m232` | FP_SIN             | `T-2 dst, T-1 src`                | FP sin                |
|       `@233` | `m233` | FP_COS             | `T-2 dst, T-1 src`                | FP cos                |
|       `@234` | `m234` | FP_TAN             | `T-2 dst, T-1 src`                | FP tan                |
|       `@235` | `m235` | FP_LOG             | öneri                             | Log                   |
|       `@236` | `m236` | FP_EXP             | öneri                             | Exp                   |
|       `@237` | `m237` | FP_POW             | öneri                             | Pow                   |
| `@238..@239` |      — | Reserved FP        | —                                 | Boş                   |

---

# 14. UX-CALC / polinom / expression: `@240..@259`

Burada dikkat: eski belgelerde `@240..@255 kullanıcı tanımlı` gibi bir ara karar geçmiş; fakat son tasarımda `@240+` alanını polinom/expression/türev/integral için ayırdık. Bu nedenle **final standarda göre `@240..@259` kullanıcı alanı değil, UX-CALC alanı olmalı.**

|       Servis |  Macro | Ad                   | Frame                                  | Görev                                            |
| -----------: | -----: | -------------------- | -------------------------------------- | ------------------------------------------------ |
|       `@240` | `m240` | POLY_DERIV           | `T-2 dst, T-1 src`                     | Polinom türevi                                   |
|       `@241` | `m241` | POLY_INTEGRAL        | `T-2 dst, T-1 src, T C`                | Polinom integrali                                |
|       `@242` | `m242` | POLY_EVAL            | `T-2 polyBase, T-1 x -> T+1`           | Polinom hesapla                                  |
|       `@243` | `m243` | POLY_PRINT           | `T-1 polyBase`                         | Polinom yazdır                                   |
|       `@244` | `m244` | POLY_CLEAR           | `T-2 base, T-1 count`                  | Polinom blok temizle                             |
| `@245..@249` |      — | Reserved POLY        | —                                      | Boş                                              |
|       `@250` | `m250` | EXPR_EVAL            | `T-2 exprBase, T-1 x -> T+1`           | RPN expression hesapla                           |
|       `@251` | `m251` | NUM_DERIV            | `T-2 exprBase, T-1 x, T h -> T+1`      | Sayısal türev                                    |
|       `@252` | `m252` | NUM_INTEGRAL_TRAP    | `T-4 expr, T-3 a, T-2 b, T-1 n -> T+1` | Trapez integral                                  |
|       `@253` | `m253` | NUM_INTEGRAL_SIMPSON | `T-4 expr, T-3 a, T-2 b, T-1 n -> T+1` | Simpson integral                                 |
|       `@254` | `m254` | EXPR_PRINT_RPN       | `T-1 exprBase`                         | RPN expression yazdır                            |
|       `@255` |      — | Reserved / bridge    | —                                      | Eski kullanıcı alanı ile çakışmasın diye boş tut |

---

# 15. Önerilen ileri bilimsel alanlar

Bunlar henüz tam runtime standardı değil, ama kütüphane alanı olarak ayrılmalı.

## UX-STAT: `@260..@289`

|       Servis | Ad                     | Görev              |
| -----------: | ---------------------- | ------------------ |
|       `@260` | STAT_SUM               | Toplam             |
|       `@261` | STAT_MEAN              | Ortalama           |
|       `@262` | STAT_MIN               | Minimum            |
|       `@263` | STAT_MAX               | Maksimum           |
|       `@264` | STAT_VARIANCE          | Varyans            |
|       `@265` | STAT_STDDEV            | Standart sapma     |
|       `@266` | STAT_COVARIANCE        | Kovaryans          |
|       `@267` | STAT_CORRELATION       | Pearson korelasyon |
|       `@268` | STAT_LINEAR_REGRESSION | Basit regresyon    |
|       `@269` | STAT_HISTOGRAM         | Histogram          |
| `@270..@289` | Reserved STAT          | ANOVA, t-test vb.  |

## UX-GA: `@290..@319`

|       Servis | Ad           | Görev             |
| -----------: | ------------ | ----------------- |
|       `@290` | GA_INIT_POP  | Popülasyon başlat |
|       `@291` | GA_FITNESS   | Fitness hesapla   |
|       `@292` | GA_SELECT    | Seçim             |
|       `@293` | GA_CROSSOVER | Çaprazlama        |
|       `@294` | GA_MUTATE    | Mutasyon          |
|       `@295` | GA_ELITISM   | Elitizm           |
| `@296..@319` | Reserved GA  | İleri GA          |

## UX-ML: `@320..@349`

|       Servis | Ad                    | Görev                   |
| -----------: | --------------------- | ----------------------- |
|       `@320` | ML_DENSE_FORWARD      | Dense layer ileri geçiş |
|       `@321` | ML_ACT_STEP           | Step aktivasyon         |
|       `@322` | ML_ACT_RELU           | ReLU                    |
|       `@323` | ML_ACT_SIGMOID_APPROX | Yaklaşık sigmoid        |
|       `@324` | ML_PERCEPTRON_UPDATE  | Perceptron update       |
|       `@325` | ML_LOSS_MSE           | Ortalama kare hata      |
| `@326..@349` | Reserved ML           | Backprop vb.            |

## UX-BIO: `@350..@379`

|       Servis | Ad               | Görev                     |
| -----------: | ---------------- | ------------------------- |
|       `@350` | BIO_GC_RATIO     | GC oranı                  |
|       `@351` | BIO_TRANSCRIBE   | DNA → RNA                 |
|       `@352` | BIO_COMPLEMENT   | Complement                |
|       `@353` | BIO_KMER_COUNT   | k-mer sayımı              |
|       `@354` | BIO_MOTIF_SEARCH | Motif arama               |
|       `@355` | BIO_TRANSLATE    | Kodon → aminoasit         |
| `@356..@379` | Reserved BIO     | Protein/peptit analizleri |

## UX-SIM: `@380..@399`

|       Servis | Ad                   | Görev                 |
| -----------: | -------------------- | --------------------- |
|       `@380` | SIM_GRID_STEP        | Grid simülasyon adımı |
|       `@381` | SIM_LIFE_STEP        | Conway Life           |
|       `@382` | SIM_DIFFUSE          | Difüzyon              |
|       `@383` | SIM_RANDOM_SEED_GRID | Rastgele grid         |
|       `@384` | SIM_PRINT_GRID       | Grid bas              |
| `@385..@399` | Reserved SIM         | İleri simülasyon      |

---

# 16. Final önerilen servis haritası

```text
@0..@19       CORE / status / rnd / timer
@20..@39      ARITHMETIC
@40..@59      MATH / SCI
@60..@79      I/O
@80..@89      POINTER / LAYOUT QUERY
@90..@94      FIFO
@95..@107     DATA/TAPE BLOCK / SORT / SEARCH
@108..@109    RESERVED
@110..@119    SCREEN / CONSOLE
@120..@127    FLAGS / ENDIAN / SIGNED / WILD LAYOUT

@128..@159    USER MACRO SAFE AREA
@160..@199    UX-MAT / MATRIX / VECTOR / ARRAY
@200..@239    UX-FP / DECIMAL FLOATING POINT
@240..@259    UX-CALC / POLY / EXPR / DERIV / INTEGRAL
@260..@289    UX-STAT / STATISTICS
@290..@319    UX-GA / GENETIC ALGORITHM
@320..@349    UX-ML / MACHINE LEARNING
@350..@379    UX-BIO / DNA/RNA/PROTEIN
@380..@399    UX-SIM / GRID / CELLULAR AUTOMATA
@400+         EXTENDED / FUTURE
```

Kısa karar: **eski belgelerde `@128..@255` kullanıcı alanı diye geçiyor ama final standarda göre bunu daraltıp `@128..@159` kullanıcıya bırakmak daha doğru.** Çünkü `@160+` alanı artık standart bilimsel kütüphane alanına dönüştü.
