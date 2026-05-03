Mete abi, aşağıdaki metni **UX-MINIMA V2 için mini kitapçık** gibi düşünebilirsin. En başta net söyleyeyim: Şu anki V2 dilimiz **string basma, hücre işlemleri, repeat macro, stack, loop, meta çağrı, x64 ASM üretimi** yapar. Ama gerçek anlamda oyun, bilimsel hesap, genetik algoritma ve 4 nöronlu makine öğrenmesi için **karşılaştırma, sayı yazdırma, değişken/dizi sözdizimi, rastgele sayı, fonksiyon/makro sistemi** gibi V3 ekleri gerekir. İlk paylaştığın UX-MINIMA tasarımı pattern tabanlı sembolik compiler mantığına dayanıyordu; aşağıdaki kılavuz bu mantığı büyütüyor. 

# UX-MINIMA V2 Kullanma Kılavuzu

UX-MINIMA, hücrelerden oluşan bir bellek alanı üzerinde çalışan sembolik bir mini dildir. Program, bir hücre işaretçisiyle bellekte sağa-sola gider, hücre değerlerini artırır/azaltır, karakter basar, input alır, stack kullanır ve özel runtime servisleri çağırır.

Temel çalışma modeli şudur:

```text
Kaynak dosya: .uxm / .txt
        ↓
FreeBASIC ile yazılmış UX-MINIMA compiler
        ↓
Token + pattern optimizer
        ↓
Windows x64 NASM .asm çıktısı
        ↓
NASM ile .obj
        ↓
FreeBASIC runtime ile .exe
```

Derleme sırası:

```bash
fbc uxm_v2_compiler.bas -x uxm_v2_compiler.exe
uxm_v2_compiler.exe
nasm -f win64 test.asm -o build.obj
fbc uxm_v2_runtime.bas build.obj -x program.exe
program.exe
```

# Bellek mantığı

UX-MINIMA V2’de üç ana alan var:

```text
ux_tape   = aktif hücre işlemleri için ana bellek
ux_data   = string, ileride değişken ve diziler için data alanı
ux_stack  = $ ve % komutlarıyla çalışan özel LIFO stack
```

CPU stack ayrı, UX-MINIMA stack ayrıdır. Bu önemli. Windows x64’te CPU stack çağrı düzeni için kullanılır; biz `$` ve `%` için kendi `ux_stack` alanımızı kullanıyoruz. Böylece FreeBASIC runtime çağrıları bozulmaz.

# Komutlar

```text
>      sağ hücreye git
<      sol hücreye git
+      aktif hücreyi 1 artır
-      aktif hücreyi 1 azalt
0      aktif hücreyi sıfırla
.      aktif hücreyi karakter olarak bas
,      klavyeden karakter al
[ ]    aktif hücre sıfır değilken döngü
@      meta/runtime servis çağrısı
$      aktif hücreyi UX stack’e push et
%      UX stack’ten pop et
&      aktif hücreyi 2 ile çarp
|      aktif hücreyi 2’ye böl
```

Repeat macro:

```text
+k65   65 tane + anlamına gelir
-k10   10 tane - anlamına gelir
>k20   20 hücre sağa git
<k5    5 hücre sola git
```

String tanımı:

```text
s1=0,{Merhaba Mete abi}
p1
```

Burada `s1` string numarasıdır, `0` data alanındaki başlangıç hücresidir, `{...}` string içeriğidir. `p1` string 1’i basar.

# Programlama mantığı

UX-MINIMA’da klasik değişken isimleri yoktur. Hücreler vardır.

```text
tape[0] = birinci değişken
tape[1] = ikinci değişken
tape[2] = geçici alan
tape[3] = sayaç
```

Örneğin:

```text
+k65.
```

Bu şunu yapar:

```text
tape[0] = tape[0] + 65
tape[0] karakter olarak basılır
```

ASCII 65 = `A`, yani çıktı:

```text
A
```

İki hücreyle `AB` basmak:

```text
+k65>+k66<.>.
```

Açıklama:

```text
+k65   hücre 0 = 65
>      hücre 1’e geç
+k66   hücre 1 = 66
<      hücre 0’a dön
.      A bas
>.     hücre 1’e geç, B bas
```

# V2 ile doğrudan yazılabilecek örnek programlar

## 1. Merhaba programı

```text
s1=0,{Merhaba Mete abi}
p1
```

Beklenen çıktı:

```text
Merhaba Mete abi
```

## 2. İki satır yazdırma

```text
s1=0,{UX-MINIMA V2}
s2=100,{Windows x64 NASM uretir}

p1
0+++++@
p2
```

Burada `0+++++@` meta servis 5 olarak düşünülür: yeni satır basar.

Çıktı:

```text
UX-MINIMA V2
Windows x64 NASM uretir
```

## 3. Harf basma

```text
s1=0,{Harf: }
p1
+k65.
```

Çıktı:

```text
Harf: A
```

## 4. Klavyeden karakter alıp basma

```text
s1=0,{Bir tusa bas: }
s2=100,{Bastigin tus: }

p1
,
0+++++@
p2
.
```

Mantık:

```text
p1    mesaj bas
,     klavyeden karakter al
p2    ikinci mesajı bas
.     alınan karakteri bas
```

## 5. Stack testi

```text
s1=0,{Stack testi: }
p1
+k65$>%.
```

Açıklama:

```text
+k65   hücre 0 = 65
$      65’i UX stack’e at
>      hücre 1’e geç
%      stack’ten al, hücre 1’e koy
.      hücre 1’i bas
```

Çıktı:

```text
Stack testi: A
```

## 6. Hücre taşıma pattern testi

```text
s1=0,{Move pattern testi: }
p1
+k65[->+<]>.
```

`[->+<]` pattern optimizer tarafından şuna indirgenebilir:

```text
tape[ptr+1] += tape[ptr]
tape[ptr] = 0
```

Çıktı:

```text
Move pattern testi: A
```

# Basit oyun örnekleri

Şimdi dürüst ayrımı yapalım. V2 ile “tam oyun mantığı” sınırlıdır, çünkü henüz `IF`, `ELSE`, sayı karşılaştırma, skor yazdırma, random sayı gösterme gibi yüksek seviye komutlar yoktur. Ama eğitim amaçlı küçük oyun benzeri programlar yazabiliriz.

## Oyun 1: Tuş yakalama oyunu

Bu V2’ye uygundur.

```text
s1=0,{Tusa basma oyunu}
s2=100,{Bir tusa bas: }
s3=200,{Senin tusun: }

p1
0+++++@
p2
,
0+++++@
p3
.
```

Bu oyun değildir ama oyunların input/output temelidir. Kullanıcıdan karakter alır ve geri gösterir.

## Oyun 2: Hafıza kartı mini testi

Bu da V2’ye uygundur. Program bir harf gösterir, sonra kullanıcıdan tekrar basmasını ister. Henüz eşitlik kontrolü olmadığı için kontrol yapmaz, ama oyun iskeletidir.

```text
s1=0,{Hafiza testi}
s2=100,{Harf: A}
s3=200,{Simdi A tusuna bas: }
s4=300,{Girdigin karakter: }

p1
0+++++@
p2
0+++++@
p3
,
0+++++@
p4
.
```

## Oyun 3: Zar atma ekranı — V2.5 gerekir

Runtime’da meta servis 3 random döndürüyor, ama V2’de sayısal değeri güzel yazdırma yok. Bu yüzden şu program random üretir ama çıktıyı sayı olarak değil, karakter olarak basma eğilimindedir:

```text
s1=0,{Zar atiliyor...}
p1
0+++++@
0+++@
.
```

Burada `0+++@` meta 3 çağrısıdır. Meta 3 random değer döndürür. Ancak dönen değeri sayı olarak yazdırmak için V3’te `print_number` gerekir.

Bu yüzden oyunlar için V3’e şu meta servisi eklemek gerekir:

```text
meta 9 = aktif hücreyi sayı olarak yazdır
```

Daha doğru V3 zar oyunu şöyle olurdu:

```text
s1=0,{Zar atiliyor...}
s2=100,{Sonuc: }

p1
0+++++@
0+++@      ; random al
p2
@n9        ; sayi olarak yazdir, V3 komutu
```

# Bilimsel hesap programı

V2’de toplama, çıkarma, ikiyle çarpma ve ikiye bölme yapılabilir. Fakat sayıyı ekrana “123” diye yazdırmak için henüz sayı yazdırma runtime’ı yoktur. Bu yüzden bilimsel hesap için iki seviye veriyorum.

## V2 ile basit hesap: 32 × 2 = 64, karakter basma

```text
s1=0,{32 ikiyle carpilir, ASCII 64 basilir: }
p1
+k32&.
```

`&` hücreyi ikiyle çarpar. 32 × 2 = 64. ASCII 64 = `@`.

Çıktı:

```text
32 ikiyle carpilir, ASCII 64 basilir: @
```

## V3 için bilimsel hesap syntax önerisi

Bilimsel hesap için dile şu üst seviye komutları eklemek gerekir:

```text
v0=10          değişken/hücre 0'a 10 koy
v1=20          değişken/hücre 1'e 20 koy
add v2,v0,v1   v2 = v0 + v1
mul v3,v2,5    v3 = v2 * 5
pn v3          sayısal değer yazdır
```

Buna göre örnek bilimsel hesap:

```text
s1=0,{Ortalama hesaplama}
p1
nl

v0=10
v1=20
v2=30
v3=40

add v10,v0,v1
add v10,v10,v2
add v10,v10,v3
div v10,v10,4

s2=100,{Ortalama: }
p2
pn v10
```

Bu V2’de doğrudan çalışmaz; V3 için hedef syntax’tır. Ama mimari olarak çok doğrudur, çünkü `ux_data` alanını değişken/dizi alanına çevirmiş oluruz.

# Genetik algoritma örneği

Genetik algoritma için gereken kavramlar:

```text
popülasyon
gen
fitness
seçilim
çaprazlama
mutasyon
nesil döngüsü
```

V2 sembolik dille bunu tamamen yazmak çok zor ve okunmaz olur. Ama UX-MINIMA V3 için şöyle bir mini sözdizimi tasarlayabiliriz.

## Genetik algoritma eğitim örneği: 4 bit hedef bulma

Hedef:

```text
1011
```

Her birey 4 bitten oluşsun:

```text
birey = [g0, g1, g2, g3]
```

Fitness:

```text
hedef bit ile aynı olan gen sayısı
```

V3 tarzı program:

```text
s1=0,{Genetik algoritma: 4 bit hedef bulma}
s2=100,{Hedef: 1011}
s3=200,{En iyi birey: }
s4=300,{Fitness: }

p1
nl
p2
nl

; hedef dizi
arr target,4
target[0]=1
target[1]=0
target[2]=1
target[3]=1

; popülasyon: 4 birey x 4 gen
arr pop,16
randbit pop[0]
randbit pop[1]
randbit pop[2]
randbit pop[3]

randbit pop[4]
randbit pop[5]
randbit pop[6]
randbit pop[7]

randbit pop[8]
randbit pop[9]
randbit pop[10]
randbit pop[11]

randbit pop[12]
randbit pop[13]
randbit pop[14]
randbit pop[15]

; fitness hesapla
fitness f0,pop[0..3],target
fitness f1,pop[4..7],target
fitness f2,pop[8..11],target
fitness f3,pop[12..15],target

best best_id, f0,f1,f2,f3

p3
print_individual pop,best_id
nl
p4
print_fitness best_id
```

Bunu gerçek V3’e taşımak için gereken yeni komutlar:

```text
arr             data alanında dizi ayır
randbit         0 veya 1 üret
fitness         iki 4-bit diziyi karşılaştır
best            en iyi fitness değerini seç
print_individual bireyi yazdır
```

Burada UX-MINIMA’nın avantajı şudur: data alanı zaten var. Yani popülasyonu `ux_data` içinde tutabiliriz.

Bellek yerleşimi şöyle olabilir:

```text
data[0..3]      hedef
data[100..115]  popülasyon
data[200..203]  fitness değerleri
```

Düşük seviye V2’ye daha yakın gösterim:

```text
s1=0,{GA demo: hedef 1011}
p1
0+++++@

; data alanı ileride hedef ve popülasyon için kullanılacak
; V2 şu an stringleri data alanına koyuyor
; V3'te sayısal data atamaları eklenecek
```

# Yapay zeka / makine öğrenmesi: 4 nöron örneği

Burada da dürüst ayrım yapalım. Gerçek makine öğrenmesi için şu işlemler gerekir:

```text
çarpma
toplama
ağırlıklar
bias
aktivasyon fonksiyonu
hata hesaplama
ağırlık güncelleme
```

V2’de bunlar tam yok. Ama V3 hedefi olarak çok güzel bir örnek kurabiliriz.

## 4 nöronlu basit model

Model:

```text
Girişler:
x0, x1

Nöronlar:
n0 = x0*w00 + x1*w01 + b0
n1 = x0*w10 + x1*w11 + b1
n2 = x0*w20 + x1*w21 + b2
n3 = x0*w30 + x1*w31 + b3
```

Basit aktivasyon:

```text
n > eşik ise 1, değilse 0
```

V3 tarzı UX-MINIMA program:

```text
s1=0,{4 noronlu mini yapay zeka}
s2=100,{Giris: x0=1, x1=0}
s3=200,{Cikislar: }

p1
nl
p2
nl

; girişler
v x0,1
v x1,0

; ağırlıklar
v w00,2
v w01,1
v w10,1
v w11,3
v w20,2
v w21,2
v w30,4
v w31,1

; bias
v b0,0
v b1,0
v b2,-1
v b3,1

; nöron 0
mul t0,x0,w00
mul t1,x1,w01
add n0,t0,t1
add n0,n0,b0
step y0,n0,1

; nöron 1
mul t0,x0,w10
mul t1,x1,w11
add n1,t0,t1
add n1,n1,b1
step y1,n1,1

; nöron 2
mul t0,x0,w20
mul t1,x1,w21
add n2,t0,t1
add n2,n2,b2
step y2,n2,1

; nöron 3
mul t0,x0,w30
mul t1,x1,w31
add n3,t0,t1
add n3,n3,b3
step y3,n3,1

p3
pn y0
space
pn y1
space
pn y2
space
pn y3
nl
```

Bu V3 için okunabilir hedef dildir. V2’nin altında ise bu işlemler `ux_data` hücrelerinde tutulur ve x64 ASM’ye çevrilir.

## 4 nöronlu sistemi UX-MINIMA’ya uygun düşünmek

Bellek planı:

```text
data[0]  = x0
data[1]  = x1

data[10] = w00
data[11] = w01
data[12] = w10
data[13] = w11
data[14] = w20
data[15] = w21
data[16] = w30
data[17] = w31

data[20] = b0
data[21] = b1
data[22] = b2
data[23] = b3

data[30] = n0
data[31] = n1
data[32] = n2
data[33] = n3

data[40] = y0
data[41] = y1
data[42] = y2
data[43] = y3
```

Yani UX-MINIMA’nın data alanı ileride tam anlamıyla küçük bir yapay zeka hafızası olabilir.

# V3 için gerekli yeni komutlar

Senin hedeflediğin oyun, bilimsel hesap, genetik algoritma ve yapay zeka örnekleri için V3’te şunları eklemek gerekir:

```text
nl              yeni satır
space           boşluk bas
pn hücre        sayıyı decimal yazdır
v isim,değer    değişken tanımla
arr isim,n      dizi tanımla
set a,b         değer ata
add c,a,b       c = a + b
sub c,a,b       c = a - b
mul c,a,b       c = a * b
div c,a,b       c = a / b
mod c,a,b       c = a mod b
cmp a,b         karşılaştır
ifz / ifnz      sıfırsa / sıfır değilse dallan
rand a,max      random sayı üret
randbit a       0/1 üret
step y,x,t      x > t ise y=1, değilse y=0
```

Bu komutlar doğrudan dilin “yüksek seviye direktifleri” olur. Compiler bunları ya pattern’e ya da runtime çağrılarına indirger.

# V2’den V3’e geçiş stratejisi

Bence sıradaki mimari hamle şu olmalı:

```text
1. Mevcut V2 sembolik çekirdek korunacak.
2. ux_data alanı değişken/dizi alanı olarak resmileşecek.
3. Stringler data alanında kalacak.
4. V3 parser, satır tabanlı yüksek seviye komutları okuyacak.
5. Bu komutlar yine x64 NASM üretecek.
6. Runtime’a sayı yazdırma, random, math helper eklenecek.
```

Örneğin `pn v10` komutu generated ASM’de şöyle bir runtime çağrısına dönüşebilir:

```asm
lea rcx, [ux_data + offset_v10]
mov edx, CELL_BITS
call ux_print_number_cell
```

`rand v0,6` komutu:

```asm
mov ecx, 6
call ux_rand_range
mov [ux_data + offset_v0], eax
```

# Özet hüküm

UX-MINIMA V2 şudur:

```text
sembolik hücre dili
string/data alanı var
özel UX stack var
FreeBASIC runtime ile ekrana basıyor
Windows x64 NASM üretiyor
```

Oyun, bilimsel hesap, genetik algoritma ve 4 nöronlu yapay zeka içinse V3 gerekir. V3’te UX-MINIMA şu hale gelir:

```text
sembolik çekirdek
+
string direktifleri
+
değişken/dizi sistemi
+
sayı yazdırma
+
random
+
aritmetik runtime
+
kontrol akışı
```

Bence bu yol doğru. Çünkü önce küçük ve çalışan çekirdeği kuruyoruz; sonra üzerine bilimsel ve yapay zeka denemeleri yapılabilecek daha okunabilir katmanı ekliyoruz.
