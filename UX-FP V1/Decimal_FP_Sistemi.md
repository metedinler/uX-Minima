UX-MINIMA V3.1 için en doğru floating point sistemi **binary IEEE-754 taklidi** değil; 
**decimal floating / big-decimal** sistemi olmalı. Çünkü sen `.dan sonra 16 veya 32 hane` istiyorsun. 
Bu, bilimsel hesap, tablo, sinüs tablosu, kimyasal oran, DNA/protein modelleme gibi işlerde daha 
anlaşılır olur.

Aşağıdaki sistemi **UX-FP V1** diye adlandıralım.

---

# UX-FP V1: UX-MINIMA Decimal Floating Point Sistemi

Temel fikir şudur:

```text
Sayı = sign × mantissa × 10^exponent
```

Yani sayı üç parçadan oluşur:

```text
sign      : sayı pozitif mi negatif mi?
mantissa  : asıl rakam dizisi
exponent  : virgülün / noktanın yeri
```

Örnek:

```text
123.456
```

şu şekilde düşünülebilir:

```text
sign      = +
mantissa  = 123456
exponent  = -3
```

Çünkü:

```text
123456 × 10^-3 = 123.456
```

16 hane veya 32 hane hassasiyet istediğimizde mantissa’yı yeterince uzun tutarız.

---

## 1. Neden decimal floating?

Normal bilgisayar float sistemi genellikle binary çalışır. Yani 0.1 gibi sayılar bilgisayarda tam temsil edilemeyebilir. Bizim UX-MINIMA’da hedefimiz daha öğretici, daha kontrol edilebilir, daha açık bir sistem olduğu için decimal mantık daha uygun.

Örneğin:

```text
0.1 + 0.2 = 0.3
```

bekleriz. Binary floating point’te bu bazen:

```text
0.30000000000000004
```

gibi görünebilir. UX-FP decimal sistemde bunu kontrol ederiz.

---

# 2. Hücre düzeni

UX-FP sayıları **Data alanında blok** olarak tutulacak.

Her floating sayı bir data bloğudur.

Önerilen FP blok yapısı:

```text
D:BASE+0   magic değer       = 70   # 'F'
D:BASE+1   precision mode    = 16 veya 32
D:BASE+2   sign              = 0 pozitif, 1 negatif
D:BASE+3   exponent sign     = 0 pozitif, 1 negatif
D:BASE+4   exponent abs      = üs mutlak değeri
D:BASE+5   used limbs        = kullanılan mantissa parça sayısı
D:BASE+6   status            = hata / normalizasyon durumu
D:BASE+7   reserved
D:BASE+8   mantissa limb 0
D:BASE+9   mantissa limb 1
D:BASE+10  mantissa limb 2
...
```

Burada mantissa **base-100** şeklinde saklanacak.

Yani her hücre 0–99 arası iki decimal rakam tutar.

Örnek:

```text
12345678
```

mantissa olarak şu parçalara ayrılır:

```text
12 34 56 78
```

Ama aritmetik kolay olsun diye bellekte **little-endian** tutmak daha iyi:

```text
D:BASE+8   = 78
D:BASE+9   = 56
D:BASE+10  = 34
D:BASE+11  = 12
```

Yani en küçük basamak önce gelir. Toplama, çıkarma, çarpma böyle daha kolay olur.

---

# 3. FP16 ve FP32 blok boyutu

## FP16

Virgülden sonra 16 decimal hane için en az 16 hane gerekir. Base-100 kullandığımız için:

```text
16 decimal hane = 8 limb
```

Ama sadece virgülden sonraki değil, tam kısım için de yer gerekir. Bu yüzden FP16 için mantissa’yı 16 limb yapmak daha mantıklı.

```text
16 limb × 2 rakam = 32 decimal rakam kapasitesi
```

FP16 blok:

```text
Header  = 8 hücre
Mantissa= 16 hücre
Toplam  = 24 hücre
```

Yani:

```text
FP16 blok boyutu = 24 data hücresi
```

## FP32

Virgülden sonra 32 decimal hane için:

```text
32 decimal hane = 16 limb
```

Tam kısma da yer açmak için mantissa’yı 32 limb yapalım.

```text
32 limb × 2 rakam = 64 decimal rakam kapasitesi
```

FP32 blok:

```text
Header  = 8 hücre
Mantissa= 32 hücre
Toplam  = 40 hücre
```

Yani:

```text
FP32 blok boyutu = 40 data hücresi
```

---

# 4. Bellekte örnek sayı

Sayı:

```text
-123.4567
```

Şöyle saklanır:

```text
sign      = 1
mantissa  = 1234567
exponent  = -4
```

Çünkü:

```text
1234567 × 10^-4 = 123.4567
```

Data bloğu:

```text
D:100+0  = 70       # magic
D:100+1  = 16       # FP16 mode
D:100+2  = 1        # negatif
D:100+3  = 1        # exponent negatif
D:100+4  = 4        # exponent abs
D:100+5  = 4        # used limbs
D:100+6  = 0        # status OK
D:100+7  = 0        # reserved
D:100+8  = 67
D:100+9  = 45
D:100+10 = 23
D:100+11 = 1
```

Çünkü mantissa little-endian base-100:

```text
1234567 = 1 | 23 | 45 | 67
```

Bellekte ters:

```text
67, 45, 23, 1
```

---

# 5. UX-MINIMA macro frame düzeni

UX-FP macro’ları mevcut V3.1 meta frame düzenini kullanmalı.

Genel frame:

```text
T-2 = hedef FP blok adresi
T-1 = A FP blok adresi
T   = B FP blok adresi veya servis / mod değeri
T+1 = sonuç / status
```

Bazı tek operandlı işlemler için:

```text
T-2 = hedef FP blok adresi
T-1 = kaynak FP blok adresi
T   = opsiyonel parametre
T+1 = status
```

Örnek:

```text
>>
0(T-2)+k200   # hedef FP blok D:200
0(T-1)+k100   # A sayısı D:100
0(T)+k140     # B sayısı D:140
@210          # FP_ADD
```

---

# 6. UX-FP macro numara alanı

UX-MINIMA’da `m128..m255` kullanıcı macro alanıydı. Floating point kütüphanesini şu aralıkta tanımlayalım:

```text
m200..m239  UX-FP decimal floating point macro alanı
```

Önerilen macro listesi:

```text
m200  FP_INIT16
m201  FP_INIT32
m202  FP_CLEAR
m203  FP_COPY
m204  FP_NORMALIZE
m205  FP_SET_SIGN
m206  FP_SET_EXP
m207  FP_SET_LIMB
m208  FP_GET_LIMB
m209  FP_PRINT_RAW

m210  FP_ADD
m211  FP_SUB
m212  FP_MUL
m213  FP_DIV
m214  FP_COMPARE
m215  FP_ABS
m216  FP_NEG
m217  FP_ROUND16
m218  FP_ROUND32
m219  FP_TRUNC

m220  FP_FROM_INT
m221  FP_FROM_DEC_STRING
m222  FP_TO_DEC_STRING
m223  FP_PRINT_DEC
m224  FP_SCALE10
m225  FP_ALIGN_EXP
m226  FP_SHIFT_LEFT_DEC
m227  FP_SHIFT_RIGHT_DEC

m230  FP_SIN_TABLE
m231  FP_COS_TABLE
m232  FP_SQRT
m233  FP_HYPOT
m234  FP_POW_INT
```

Burada önemli karar şudur:

**Temel FP işlemleri saf UXM macro ile yapılabilir**, ama 32 hane division, sqrt, sin gibi işlemler çok uzun olur. Bu yüzden iki katmanlı tasarım en iyisi:

```text
Katman 1: UXM macro API
Katman 2: Host meta servis hızlandırıcıları
```

Yani kullanıcı `@210` veya `m210` mantığıyla FP_ADD çağırır. İlk sürümde macro saf UXM olabilir; hızlı sürümde aynı çağrı FreeBASIC runtime meta servisine bağlanabilir.

---

# 7. FP status kodları

Her FP blok içinde `BASE+6` status alanı olacak.

```text
0   OK
1   normalize gerekli
2   mantissa overflow
3   exponent overflow
4   division by zero
5   invalid number
6   precision loss
7   rounded
8   negative zero cleaned
9   underflow
10  NaN benzeri geçersiz durum
```

UX-MINIMA genel status byte ile karışmasın diye FP status kendi blok header’ında tutulur.

---

# 8. Normalizasyon mantığı

Normalizasyonun amacı şudur:

```text
Mantissa başında gereksiz sıfır kalmasın.
Exponent buna göre ayarlansın.
```

Örnek:

```text
mantissa = 00123456
exponent = -4
```

normalleştirilir:

```text
mantissa = 123456
exponent = -4
```

Başta sıfır limb varsa silinir.

Little-endian tutulduğu için en büyük limb en sondadır. O yüzden normalize işlemi mantissa’nın sonundan başlar.

Pseudo mantık:

```text
while used_limbs > 1 and limb[used_limbs-1] = 0:
    used_limbs--
```

Eğer bütün mantissa sıfırsa:

```text
sign = 0
exponent = 0
used_limbs = 1
limb[0] = 0
```

---

# 9. Toplama mantığı

FP_ADD için iki sayı toplanmadan önce exponent eşitlenir.

Örnek:

```text
A = 12345 × 10^-2  = 123.45
B = 678   × 10^-1  = 67.8
```

Exponentler:

```text
A exponent = -2
B exponent = -1
```

Aynı exponent’e getirmek gerekir:

```text
B = 6780 × 10^-2
```

Sonra mantissa toplanır:

```text
12345 + 6780 = 19125
```

Sonuç:

```text
19125 × 10^-2 = 191.25
```

UX-FP ADD adımları:

```text
1. A ve B exponent oku.
2. Küçük exponent’i hedef exponent yap.
3. Büyük exponentli sayının mantissa’sını 10 fark kadar kaydır.
4. Sign aynıysa mantissa topla.
5. Sign farklıysa büyük mutlak değerden küçüğü çıkar.
6. Sonucu normalize et.
7. Precision 16/32 sınırını uygula.
```

---

# 10. Çarpma mantığı

Çarpma daha nettir.

```text
A = mantA × 10^expA
B = mantB × 10^expB
```

Sonuç:

```text
R = mantA × mantB × 10^(expA + expB)
```

Yani:

```text
result_sign = signA XOR signB
result_exp  = expA + expB
result_mant = mantA * mantB
```

Mantissa base-100 limb çarpımı klasik uzun çarpma ile yapılır.

Pseudo:

```text
for i = 0 to usedA-1
    carry = 0
    for j = 0 to usedB-1
        temp = result[i+j] + A[i] * B[j] + carry
        result[i+j] = temp mod 100
        carry = temp / 100
    next
    result[i+usedB] += carry
next
```

Bu işlem UXM macro ile yazılabilir çünkü her limb 0–99 arasıdır.

---

# 11. Bölme mantığı

Bölme en zor kısımdır.

Temel formül:

```text
A / B = mantA / mantB × 10^(expA - expB)
```

Ama decimal hassasiyet için mantA’yı önce büyütürüz.

FP16 için:

```text
mantA_scaled = mantA × 10^16
```

FP32 için:

```text
mantA_scaled = mantA × 10^32
```

Sonra integer division yapılır:

```text
result_mant = mantA_scaled / mantB
result_exp = expA - expB - scale
```

Yani division sistemi aslında büyük integer bölmedir.

İlk aşamada division macro çok uzun olur. Bu yüzden önerim:

```text
m213 FP_DIV
```

iki modda çalışsın:

```text
safe macro mode:
    yavaş ama öğretici long division

host accelerated mode:
    FreeBASIC runtime meta servisi ile hızlı big-decimal division
```

---

# 12. 16 hane / 32 hane seçimi

Her FP blokta precision tutulur:

```text
D:BASE+1 = 16 veya 32
```

Ama bu “toplam mantissa hane sayısı” değil, “virgülden sonra hedef hane” olarak yorumlanmalı.

Böylece:

```text
FP16 = .dan sonra 16 hane
FP32 = .dan sonra 32 hane
```

Round işlemi:

```text
m217 FP_ROUND16
m218 FP_ROUND32
```

Virgülden sonra fazla hane varsa yuvarlar.

Örnek:

```text
1.234567890123456789
```

FP16:

```text
1.2345678901234568
```

FP32:

```text
1.23456789012345678900000000000000
```

---

# 13. FP blok örnekleri

## A = 12.34

```text
mantissa = 1234
exponent = -2
```

D:100 bloğu:

```text
D:100 = 70
D:101 = 16
D:102 = 0
D:103 = 1
D:104 = 2
D:105 = 2
D:106 = 0
D:107 = 0
D:108 = 34
D:109 = 12
```

## B = 5.6

```text
mantissa = 56
exponent = -1
```

D:140 bloğu:

```text
D:140 = 70
D:141 = 16
D:142 = 0
D:143 = 1
D:144 = 1
D:145 = 1
D:146 = 0
D:147 = 0
D:148 = 56
```

## R = A + B

```text
12.34 + 5.6 = 17.94
```

R bloğu D:180:

```text
mantissa = 1794
exponent = -2
limbs = 94, 17
```

---

# 14. UXM kullanım örneği

Aşağıdaki kullanımda sayılar hazır data bloklarında var kabul edilir.

```text
# FP ADD örneği
# A = D:100
# B = D:140
# R = D:180

>>
0(T-2)+k180
0(T-1)+k100
0(T)+k140
@210
```

Burada:

```text
T-2 = result base
T-1 = A base
T   = B base
@210 = FP_ADD
```

---

# 15. UX-FP için meta servis önerisi

Mevcut runtime’da `@128..@255` kullanıcı macro alanı olarak düşünülmüştü. Native taraf macro’ları inline açıyor. Ama floating point için daha iyi tasarım şu:

```text
@200..@239 host accelerated floating point servisleri
m200..m239 pure UXM fallback macro’ları
```

Yani:

```text
@210 = hızlı FP_ADD
m210 = saf UXM FP_ADD macro
```

Eğer runtime `@210` destekliyorsa onu kullanırız. Desteklemiyorsa compiler macro olarak `m210` açar.

Bu iki seviyeli sistem çok iyi olur:

```text
Eğitim için: saf UXM macro
Performans için: FreeBASIC runtime meta servis
```

---

# 16. UX-FP servis tablosu

```text
@200 / m200   FP_INIT16
@201 / m201   FP_INIT32
@202 / m202   FP_CLEAR
@203 / m203   FP_COPY
@204 / m204   FP_NORMALIZE
@205 / m205   FP_SET_SIGN
@206 / m206   FP_SET_EXP
@207 / m207   FP_SET_LIMB
@208 / m208   FP_GET_LIMB
@209 / m209   FP_PRINT_RAW

@210 / m210   FP_ADD
@211 / m211   FP_SUB
@212 / m212   FP_MUL
@213 / m213   FP_DIV
@214 / m214   FP_COMPARE
@215 / m215   FP_ABS
@216 / m216   FP_NEG
@217 / m217   FP_ROUND16
@218 / m218   FP_ROUND32
@219 / m219   FP_TRUNC

@220 / m220   FP_FROM_INT
@221 / m221   FP_FROM_DEC_STRING
@222 / m222   FP_TO_DEC_STRING
@223 / m223   FP_PRINT_DEC
@224 / m224   FP_SCALE10
@225 / m225   FP_ALIGN_EXP
@226 / m226   FP_SHIFT_LEFT_DEC
@227 / m227   FP_SHIFT_RIGHT_DEC

@230 / m230   FP_SQRT
@231 / m231   FP_HYPOT
@232 / m232   FP_SIN
@233 / m233   FP_COS
@234 / m234   FP_TAN
```

---

# 17. Data alanında FP kütüphane düzeni

Önerilen standart bloklar:

```text
D:0..99       sabitler ve geçici alan
D:100..139    FP A
D:140..179    FP B
D:180..219    FP R
D:220..259    FP TMP1
D:260..299    FP TMP2
D:300..399    string buffer
```

Örneğin:

```text
FP16 A   = D:100
FP16 B   = D:140
FP16 R   = D:180
FP32 A   = D:500
FP32 B   = D:540
FP32 R   = D:580
```

---

# 18. Makro olarak gerçek başlangıç taslağı

UXM içinde doğrudan şu macro tanımlanabilir:

```text
# UX-FP V1 küçük başlangıç kütüphanesi

# m200: FP_INIT16
# T-2 = base
m200={
0(D:0)
}

# m202: FP_CLEAR
# T-2 = base
m202={
# Bu macro gerçek sürümde D:base+0..base+23 aralığını temizlemeli.
# UXM V3.1 doğrudan D:(T-2+n) adreslemeyi desteklemediği için
# bunu host meta servis veya gelişmiş indirect data addressing ile yapmak daha doğru.
}

# m216: FP_NEG
# T-1 = source base
# T-2 = dest base
m216={
# sign flip macro
}
```

Burada kritik bir nokta var Mete abi:

Mevcut V3.1 adresleme sisteminde:

```text
(D:N)
```

mutlak data adresi destekleniyor. Ama:

```text
(D:T+N)
```

gibi dinamik data adresleme henüz yok.

Floating point macro’ları için bu gerekir.

Bu yüzden FP sistemiyle birlikte şu adresleme modunu eklemek çok iyi olur:

```text
(D@T)       T hücresindeki değeri data adresi kabul et
(D@T+N)     T hücresindeki değer + N data adresi
(D@T- N)    T hücresindeki değer - N data adresi
```

Veya daha temiz:

```text
(D* T)
(D* T+8)
```

Ama sen parantezde karışıklık olmasın demiştin. Bence şu daha net:

```text
(D:T)       zaten T mi mutlak mı karışır
(D@T)       daha anlaşılır
(D@T+8)
```

Bu eklenirse FP macro’ları gerçekten saf UXM ile yazılabilir.

---

# 19. FP için gerekli yeni adresleme

UX-FP için olmazsa olmaz adresleme:

```text
(D@T)
(D@T+N)
(D@T-N)
```

Anlamı:

```text
T hücresindeki değer data base kabul edilir.
N kadar offset eklenir.
```

Örnek:

```text
# T hücresinde 100 var
.(D@T+8)
```

Bu:

```text
D:108
```

hücresini okur.

Bu olmadan her FP işlemini sadece sabit D adresleriyle yazmak gerekir, bu da kütüphaneyi kullanışsız yapar.

---

# 20. FP için gerekli yeni meta servisler

Eğer saf macro uzun gelirse host meta servisler eklenir.

Runtime tarafında `@200..@239` açılır.

Frame:

```text
T-2 = result base
T-1 = A base
T   = B base / parameter
T+1 = status
```

Örnek:

```text
>>
0(T-2)+k180
0(T-1)+k100
0(T)+k140
@210
```

Runtime:

```text
@210:
    resultBase = T-2
    aBase      = T-1
    bBase      = T
    FP_ADD(resultBase, aBase, bBase)
    T+1 = status
```

---

# 21. FP print mantığı

FP_PRINT_DEC şu işi yapar:

```text
1. sign oku
2. mantissa limblerini en büyükten küçüğe oku
3. exponent’e göre nokta yerini bul
4. tam kısmı bas
5. nokta bas
6. fractional kısmı precision kadar bas
```

Örnek:

```text
mantissa = 1234567
exponent = -4
precision = 16
```

Yazdırma:

```text
123.4567000000000000
```

FP32:

```text
123.45670000000000000000000000000000
```

---

# 22. Önerdiğim gerçek geliştirme sırası

Bunu doğrudan projeye eklemek için sıralama şöyle olmalı:

```text
1. UXM V3.1 adresleme sistemine (D@T+N) ekle.
2. Runtime’a @200..@239 FP servislerini ekle.
3. FP blok okuma/yazma yardımcılarını FreeBASIC runtime’a yaz.
4. FP_INIT16, FP_INIT32, FP_FROM_INT, FP_PRINT_DEC ekle.
5. FP_ADD ve FP_SUB ekle.
6. FP_MUL ekle.
7. FP_DIV ekle.
8. FP_ROUND16 / FP_ROUND32 ekle.
9. VS Code extension docs içine UX-FP dokümanı koy.
10. Copilot instructions içine UX-FP kurallarını ekle.
```

---

# 23. İlk minimum çalışan FP hedefi

İlk çalışan sürümde sadece şunları yapalım:

```text
@200 FP_INIT16
@201 FP_INIT32
@220 FP_FROM_INT
@223 FP_PRINT_DEC
@210 FP_ADD
@212 FP_MUL
```

Bu yeterli olur.

Örnek program:

```text
# A = 12
# B = 34
# R = A + B

>>
0(T-2)+k100
@200

0(T-2)+k140
@200

0(T-2)+k180
@200

0(T-2)+k100
0(T-1)+k12
@220

0(T-2)+k140
0(T-1)+k34
@220

0(T-2)+k180
0(T-1)+k100
0(T)+k140
@210

0(T-1)+k180
@223
```

Beklenen çıktı:

```text
46.0000000000000000
```

---

# 24. Son kararım

Mete abi, UX-MINIMA için en doğru floating point sistemi şu olmalı:

```text
Adı:
    UX-FP V1

Tip:
    Decimal floating point / big decimal

Temsil:
    sign + exponent + base-100 mantissa

Hassasiyet:
    FP16 = virgülden sonra 16 hane
    FP32 = virgülden sonra 32 hane

Bellek:
    Data alanında FP blokları

Macro alanı:
    m200..m239

Host hızlandırıcı:
    @200..@239

Zorunlu ek adresleme:
    (D@T)
    (D@T+N)
    (D@T-N)

Temel işlemler:
    INIT, CLEAR, COPY, NORMALIZE
    FROM_INT, FROM_DEC_STRING, PRINT_DEC
    ADD, SUB, MUL, DIV
    ROUND16, ROUND32
```

Bence ilk kodlama adımı şu olmalı:

```text
uxm31_runtime_fb_full.bas içine @200..@239 FP servislerini ekleyelim.
```

Çünkü 16/32 haneli decimal floating point’i saf UXM macro olarak yazmak mümkün ama çok uzun olur. Önce runtime hızlandırıcıyla doğru matematiği kurmak, sonra aynı mantığın saf UXM macro sürümünü parça parça yazmak daha sağlıklı olur.
