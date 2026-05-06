Evet Mete abi, adresleme modları UX-Minima’nın en kritik tarafı.
Çünkü bu dilin asıl gücü yeni kelimeler eklemekten değil, **aynı küçük komutları farklı bellek alanlarına uygulatmaktan** geliyor.

Tasarım belgesindeki doğru karar şu: `[]` döngü için, `()` adresleme için ayrılmış. Adresleme komuttan hemen sonra ve boşluksuz yazılmalı; örneğin `+(T+1)` doğru, `+ (T+1)` yanlış kabul ediliyor.

---

# 1. UX-Minima’da adresleme ne demek?

Normal Brainfuck tarzında `+` sadece aktif hücreye etki eder:

```text
+
```

UX-Minima’da bunun açık hali:

```text
+(T)
```

Yani:

```text
+      = aktif tape hücresini artır
+(T)   = aktif tape hücresini artır
```

Ama V3.1 adresleme sistemiyle aynı `+` komutu başka yerlere de uygulanabilir:

```text
+(T+1)     pointer’ın bir sağındaki tape hücresini artır
+(T:100)   tape[100] hücresini artır
+(D:5)     data[5] hücresini artır
+(S:0)     stack[0] hücresini artır
+(D@T)     data[tape[pointer]] hücresini artır
```

Yani komut değişmiyor; **hedef adres değişiyor**.

Bu, 6502’deki şu mantığa benzer:

```text
LDA #10       immediate
LDA $20       zero page
LDA $2000     absolute
LDA ($20),Y   indirect indexed
```

UX-Minima’da da:

```text
+(T)
+(T+1)
+(T:100)
+(D@T+2)
```

aynı fikrin tape/data/stack tabanlı karşılığıdır.

---

# 2. Mevcut adresleme modları

Kılavuzda ve tasarım belgesinde geçen ana adresleme tablosu şudur: `(T)`, `(T+N)`, `(T-N)`, `(T:N)`, `(D:N)`, `(S:N)`, `(SP)`, `(P)`, `(E)`, `(F)`, `(*T)`, `(*(T+N))`, `(D@T)`, `(D@T+N)`, `(D@T-N)`, `(D@(T-2)+N)` gibi biçimler mevcut veya hedef standart olarak tanımlanmış durumda.

Şimdi bunları tek tek açıklayayım.

---

## 2.1 `(T)` — aktif tape hücresi

```text
+(T)
.(T)
0(T)
```

Anlam:

```text
tape[pointer]
```

Kısa yazım:

```text
+
.
0
```

hepsi varsayılan olarak `(T)` üzerinde çalışır.

Kullanım:

```text
0+k65.
```

Bu:

```text
aktif hücreyi sıfırla
65 yap
A karakteri olarak bas
```

---

## 2.2 `(T+N)` — pointer’a göre sağ/ileri hücre

```text
+(T+1)
0(T+2)
.(T+3)
```

Anlam:

```text
tape[pointer + N]
```

Pointer yer değiştirmez. Sadece komut hedef hücreye uygulanır.

Örnek:

```text
0(T+1)+k65(T+1)
.(T+1)
```

Bu aktif pointer’ı oynatmadan sağdaki hücreye `A` yazar.

Bunun eski karşılığı şuna benzerdi:

```text
>0+k65.<
```

Ama bu pointer’ı oynatır. `+(T+1)` tipi adresleme ise pointer’ı sabit tutar.

Bu fark trace/debug için çok önemlidir. Tasarım belgesi de `>+<` ile `+(T+1)` aynı sonucu verse bile pointer etkisinin farklı olduğunu ve optimizer’ın bunu koruması gerektiğini söylüyor. 

---

## 2.3 `(T-N)` — pointer’a göre sol/geri hücre

```text
+(T-1)
0(T-2)
.(T-3)
```

Anlam:

```text
tape[pointer - N]
```

Örnek:

```text
>>>
0(T-2)+k65(T-2)
.(T-2)
```

Pointer 3’te dururken tape[1] üzerine işlem yapılabilir.

Bu, frame mantığı için çok değerlidir.

---

## 2.4 `(T:N)` — mutlak tape adresi

```text
0(T:100)
+k65(T:100)
.(T:100)
```

Anlam:

```text
tape[N]
```

Pointer nerede olursa olsun tape’in N numaralı hücresine erişilir.

Bu, sanal register tasarlamak için çok kullanışlıdır:

```text
(T:0) = A register
(T:1) = B register
(T:2) = C register
(T:3) = temp
```

Örnek:

```text
0(T:0)+k10
0(T:1)+k20
```

Bu tape[0] = 10, tape[1] = 20 gibi çalışır. Tasarım belgesinde bu sanal CPU/register fikri özellikle anlatılmış. 

---

## 2.5 `(D:N)` — mutlak data adresi

```text
.(D:0)
+(D:10)
$(D:20)
```

Anlam:

```text
data[N]
```

Data alanı sabit tablolar, stringler, lookup table, matematik tabloları veya biyolojik kodon tablosu gibi veriler için uygundur.

Örnek:

```text
s1=0,{ABC}
p1
```

String data alanına yerleşir. `(D:N)` ile doğrudan o hücrelere erişilebilir.

---

## 2.6 `(S:N)` — stack hücresi

```text
+(S:0)
.(S:1)
```

Anlam:

```text
stack[N]
```

Bu doğrudan stack belleğine erişimdir.

Dikkat: Bu mod güçlü ama tehlikelidir. Çünkü stack normalde `$` ve `%` ile LIFO mantığında kullanılmalıdır. `(S:N)` doğrudan erişim, stack içeriğini elle kurcalamak demektir.

Bu yüzden Safe mode’da kapalı veya sınırlı olması doğru olur. Tasarım belgesi Safe mode’da `(S:N)` yazmanın kapalı, Normal mode’da kontrollü, Wild mode’da açık olabileceğini söylüyor.

---

## 2.7 `(SP)` — stack top / stack pointer civarı

```text
.(SP)
+(SP)
```

Anlam:

```text
stack top
```

Burada dikkatli olmak gerekir. `(SP)` iki farklı anlam taşıyabilir:

1. Stack pointer değeri
2. Stack’in tepe hücresi

Kılavuzda `(SP)` “stack’in tepe hücresi” olarak verilmiş. 

Benim önerim:

```text
(SP)  = stack top hücresi
(P)   = tape pointer değeri
```

şeklinde kalmalı.

Ama `(SP)` yazma işlemi kontrollü olmalı. Çünkü stack pointer düzenini bozabilir.

---

## 2.8 `(P)` — pointer değeri

```text
.(P)
0(P)
```

Anlam:

```text
pointer register / pointer değeri
```

Okuma çok mantıklı:

```text
(P) -> aktif pointer kaç?
```

Yazma ise tehlikelidir:

```text
0(P)+k100
```

böyle bir kullanım pointer’ı doğrudan 100’e taşıyabilir.

Bu, `@80 SET POINTER` meta servisiyle zaten yapılabiliyor. Bu yüzden `(P)` yazma sadece Normal/Wild modda veya meta üzerinden olmalı.

---

## 2.9 `(E)` — status byte

```text
e
e(T+1)
.(E)
```

Anlam:

```text
status/error byte
```

Tasarımda `e` komutu status byte okumak için resmileştirilmiş. Status kodları da ayrı bir hata sistemi olarak tanımlanmış. 

`(E)` adresleme ise status byte’ı doğrudan adreslenebilir hale getirir.

Bence:

```text
(E) okuma = güvenli
(E) yazma = sadece meta veya wild
```

olmalı.

Çünkü kullanıcı gelişigüzel status yazarsa hata sistemi anlamını kaybeder.

---

## 2.10 `(F)` — flags word

```text
.(F)
?(F)
```

Anlam:

```text
flags word
```

Flags içinde Z, C, O, S, signed/unsigned, endian, bounds, wild gibi bitler bulunur.

`(F)` okuma çok faydalıdır:

```text
flags değerini programa al
```

Ama `(F)` yazma tehlikelidir. Çünkü kullanıcı doğrudan flags yazarsa sistem modunu bozabilir.

Benim önerim:

```text
(F) okuma = Normal mode’da olabilir
(F) yazma = sadece Wild mode veya özel meta servis
```

---

## 2.11 `(*T)` — tape indirect

```text
.(*T)
+(*T)
```

Anlam:

```text
addr = tape[pointer]
hedef = tape[addr]
```

Yani aktif hücredeki değer bir tape adresi sayılır.

Örnek:

```text
tape[pointer] = 100
+(*T)
```

Bu:

```text
tape[100]++
```

demektir.

Bu çok güçlüdür. Pointer, indeks tablosu, jump table, lookup table gibi işler yapılabilir.

Ama tehlikelidir. Çünkü aktif hücrede saçma bir adres varsa sınır dışına çıkılır. Bu yüzden Safe mode’da kapalı, Normal/Wild’da bounds check ile açılmalı. Tasarım belgesi Safe mode’da indirect adreslemeyi kapalı, Wild mode’da açık göstermiştir.

---

## 2.12 `(*(T+N))` ve `(*(T-N))` — göreli indirect tape

```text
+(*(T+1))
.(*(T-2))
```

Anlam:

```text
addr = tape[pointer + N]
hedef = tape[addr]
```

Bu, 6502’deki indexed indirect / indirect indexed mantığına en yakın alanlardan biridir.

Örnek:

```text
tape[pointer+1] = 200
.(*(T+1))
```

Bu:

```text
tape[200] karakter olarak bas
```

demektir.

Bence bu mode çok değerli ama Safe mode’a konmamalı.

---

## 2.13 `(D@T)` — data indirect by active tape cell

```text
.(D@T)
+(D@T)
```

Anlam:

```text
addr = tape[pointer]
hedef = data[addr]
```

Yani aktif tape hücresi data adresi olarak kullanılır.

Bu çok önemli. Çünkü data alanında tablo varsa, tape hücresindeki indeksle tablo okunabilir.

Örnek:

```text
tape[pointer] = 5
.(D@T)
```

Bu:

```text
data[5] karakterini bas
```

demektir.

Biyoloji örneğine bağlarsak:

```text
tape[pointer] = kodon_id
data[kodon_id] = amino_asit_kodu
```

Böylece:

```text
(D@T)
```

ile kodon tablosu okunabilir.

---

## 2.14 `(D@T+N)` ve `(D@T-N)`

```text
.(D@T+1)
.(D@T-1)
```

Anlam:

```text
addr = tape[pointer] + N
hedef = data[addr]
```

Bu lookup table içinde offset kullanmaya yarar.

Örnek:

```text
data[kodon_id + 0] = amino acid id
data[kodon_id + 1] = hydropathy score
data[kodon_id + 2] = molecular weight index
```

O zaman:

```text
(D@T)     amino acid id
(D@T+1)   hidrofobiklik skoru
(D@T+2)   molekül ağırlığı indeksi
```

Bence bu mod çok değerli.

---

## 2.15 `(D@(T-2)+N)` / `(D@(T-1)+N)` / `(D@(T)+N)`

Bu aile daha gelişmiş frame lookup sistemidir.

Örnek:

```text
(D@(T-2)+3)
```

Anlam:

```text
base = tape[pointer - 2]
hedef = data[base + 3]
```

Bu özellikle meta frame mantığına çok uyar:

```text
(T-2) = arg1 / base address
(T-1) = arg2 / index
(T)   = meta id
(T+1) = result
```

Örnek kullanım:

```text
(D@(T-2)+N)
```

ile `T-2` hücresinde duran taban adresin N offset sonrası okunabilir.

Bu şu işler için çok yararlı:

```text
lookup table
struct alanı okuma
record sistemi
kodon tablosu
matris satır başlangıcı
polinom katsayı bloğu
```

Kılavuzda bu ailenin birkaç biçimi açık yazılmış: `(D@(T-2)+N)`, `(D@(T-1)+N)`, `(D@(T)+N)` gibi. 

---

# 3. Safe / Normal / Wild ayrımı

Adresleme modlarını tek başına düşünmemek gerekir. Asıl güvenlik mode sisteminden gelir.

## Safe mode

Safe mode’da izin verilenler:

```text
(T)
(T+N)
(T-N)
(T:N)
(D:N)
```

Yani kullanıcı tape ve data üzerinde kontrollü çalışır. Stack, pointer, flags, indirect gibi riskli alanlar kapalıdır. Tasarım belgesi Safe mode’da `(*T)`, `(*(T+N))`, `(P)`, `(E)`, `(F)` yazma gibi işlemleri kapalı veya sınırlı sayıyor. 

## Normal mode

Normal mode’da standart çalışma yapılır.

İzin verilenler:

```text
(T)
(T+N)
(T-N)
(T:N)
(D:N)
(SP) okuma
(E) okuma
(F) okuma
@80/@81/@82 ile pointer yönetimi
```

Kontrollü izin verilenler:

```text
(S:N) okuma
indirect adresleme bounds check açık ise
```



## Wild mode

Wild mode deneysel ve güçlü moddur.

Açılabilecekler:

```text
(S:N)
(SP)
(P)
(E)
(F)
(*T)
(*(T+N))
runtime layout değişimi
tape/data/stack swap
data alanından UXM kodu yorumlama
```

Bu mode normal kullanıcı için değil; yapay yaşam, self-modifying program, compiler araştırması, simülasyon gibi işler içindir. 

---

# 4. Daha fazla adresleme modu eklenebilir miydi?

Evet, eklenebilir.
Ama her yeni adresleme modu gerçekten gerekli mi diye çok dikkatli düşünmek gerekir.

Ben adresleme modlarını üç sınıfa ayırırdım:

```text
A) Standart çekirdek adresleme
B) Extended / Wild adresleme
C) Eklenmemesi gereken veya şimdilik bekletilecek adresleme
```

---

# 5. Eklenebilecek mantıklı adresleme modları

## 5.1 `(SP+N)` ve `(SP-N)` — stack pointer relative

Bence en mantıklı yeni adaylardan biri budur.

Şu an `(S:N)` mutlak stack hücresi, `(SP)` ise stack top mantığı veriyor. Ama frame mantığı için şunlar çok faydalı olur:

```text
(SP-1)
(SP-2)
(SP+1)
```

Anlam:

```text
stack[sp - 1]
stack[sp - 2]
stack[sp + 1]
```

Kullanım:

```text
.(SP-1)
+(SP-2)
```

Ne işe yarar?

```text
stack frame
local değişken
argüman okuma
çağrı simülasyonu
macro call frame
recursive yapı
```

Risk:

```text
stack sınırı aşılabilir
SP yanlışsa stack bozulur
```

Karar:

```text
Safe: yok
Normal: sadece okuma
Wild: okuma/yazma
```

Ben bunu **eklenebilir** buluyorum.

---

## 5.2 `(D@T+N)` zaten var; bunun genelleştirilmiş hali: `(D@(T+K)+N)`

Bu ailenin bazı biçimleri zaten var:

```text
(D@(T-2)+N)
(D@(T-1)+N)
(D@(T)+N)
```

Bunu genel hale getirmek mümkün:

```text
(D@(T+K)+N)
(D@(T-K)+N)
```

Anlam:

```text
base = tape[pointer + K]
hedef = data[base + N]
```

Bu çok güçlüdür.

Örnek:

```text
(D@(T+2)+5)
```

anlam:

```text
data[tape[pointer+2] + 5]
```

Bu model:

```text
struct
record
table
matrix row base
protein/codon lookup
sanal nesne alanları
```

için çok uygun.

Karar:

```text
Normal: bounds check ile olabilir
Wild: tam açık
```

Bence bu **çok mantıklı**.

---

## 5.3 `(T@D:N)` — data değerini tape adresi saymak

Şu an `D@T`, tape değerini data adresi sayıyor.

Tersi de düşünülebilir:

```text
(T@D:N)
```

Anlam:

```text
addr = data[N]
hedef = tape[addr]
```

Bu ne işe yarar?

```text
data alanında pointer table tutmak
tape üzerinde dinamik hedef seçmek
sabit tabloya göre tape alanı seçmek
```

Örnek:

```text
data[10] = 500
+(T@D:10)
```

Bu:

```text
tape[500]++
```

olur.

Bu güçlü ama biraz karmaşık.

Karar:

```text
Safe: yok
Normal: belki yok
Wild: olabilir
```

Ben bunu **extended/wild aday** olarak görürüm.

---

## 5.4 `(D@D:N)` — data içindeki değeri data adresi saymak

```text
(D@D:10)
```

Anlam:

```text
addr = data[10]
hedef = data[addr]
```

Bu data içinde pointer table yapmayı sağlar.

Ne işe yarar?

```text
string table
lookup table
symbol table
codon table
matrix row pointer
graph adjacency table
```

Ama tehlikesi var: data alanı artık hem veri hem pointer alanı olur.

Karar:

```text
Normal: kontrollü olabilir
Wild: açık olabilir
```

Bence bu da eklenebilir ama çekirdeğe hemen koymak şart değil.

---

## 5.5 `(D:BASE+I)` veya `(D:N+T)` — base + index adresleme

Şu tarz bir şey düşünülebilirdi:

```text
(D:100+T)
(D:100+P)
```

Anlam:

```text
data[100 + pointer]
```

Bu tablo okuma için çok güzel olurdu.

Örnek:

```text
.(D:100+T)
```

pointer kaçsa data[100+pointer] okunur.

Biyoloji örneğinde:

```text
data[100 + codon_id]
```

çok iş görür.

Ama syntax dikkatli seçilmeli.

Bence daha temiz yazım:

```text
(D:100+P)
```

Burada `P` pointer değeridir.

Karar:

```text
Çok faydalı.
Ama mevcut D@T ailesi ile çakışmadan tasarlanmalı.
```

Bunu **yüksek öncelikli aday** görüyorum.

---

## 5.6 `(T:BASE+P)` — mutlak tape base + pointer

```text
(T:100+P)
```

Anlam:

```text
tape[100 + pointer]
```

Bu da array alanı açmak için iyi olur.

Örnek:

```text
# tape[100..199] = buffer
+(T:100+P)
```

Bu, pointer’ı buffer içinde index gibi kullanır.

Bence mantıklı.

Ama bunun yerine pointer’ı zaten tape üzerinde gezdirmek de mümkün. O yüzden `D:BASE+P` kadar kritik değil.

---

## 5.7 `(R:N)` — register bank adresleme

Eğer ileride UX-Minima içinde register bank tanımlanırsa:

```text
(R:0)
(R:1)
(R:2)
```

gibi bir mode olabilir.

Ama şimdilik gereksiz. Çünkü `(T:0)`, `(T:1)` zaten sanal register gibi kullanılabiliyor.

Karar:

```text
Eklemeye gerek yok.
```

---

## 5.8 `(I:N)` — immediate value adresleme

Şu an immediate mantığı `+kN`, `-kN`, `0+kN` ile çözülüyor.

Ama genel olarak şöyle bir syntax düşünülebilir:

```text
$(I:65)
?(I:10)
```

Anlam:

```text
değer doğrudan komuta verilir
```

Bu güzel olurdu ama mevcut minimal karakter yapısını büyütür.

Alternatif:

```text
0+k65
$
```

zaten immediate push gibi çalışabiliyor.

Karar:

```text
Çekirdeğe koyma.
Macro/kütüphane ile çözülebilir.
```

---

## 5.9 `(B:N)` — byte-level raw addressing

Şu an adresleme hücre tabanlıdır. Yani `#cell word` ise `(T:1)` byte offset değil, hücre offset’tir.

Ama bazen byte düzeyinde ham erişim gerekir:

```text
(B:100)
```

Anlam:

```text
ux_mem[100] raw byte
```

Bu çok güçlüdür.

Ne işe yarar?

```text
binary dosya
struct packing
endian test
raw memory dump
compiler deneyleri
```

Ama tehlikelidir. Hücre modelini bypass eder.

Karar:

```text
Sadece Wild mode.
```

Bence ileride `RAW` veya `B` ailesi eklenebilir ama çekirdek standarda hemen alınmamalı.

---

## 5.10 `(M:N)` — tüm 64KB memory absolute

Şu an T/D/S ayrılmış alanlar var.

Ama wild mode için:

```text
(M:N)
```

anlamı:

```text
ux_mem raw cell/byte N
```

olabilir.

Bu, tape/data/stack sınırlarını aşar.

Ne işe yarar?

```text
memory viewer
self-modifying model
VM simülasyonu
6502 memory map denemesi
```

Ama çok tehlikeli.

Karar:

```text
Safe: hayır
Normal: hayır
Wild: opsiyonel
```

---

## 5.11 `(PC)` veya `(IP)` — instruction pointer

Branch ve trace için düşünülebilir:

```text
(IP)
```

Anlam:

```text
current instruction index
```

Bu interpreter/trace için güzel ama native runtime’da anlamı karmaşık.

Çünkü native EXE’de instruction index doğrudan tutulmayabilir.

Karar:

```text
IDE/final interpreter için olabilir.
Native core için şart değil.
```

---

## 5.12 `(A:N)` — array descriptor adresleme

Eğer matrix, FP, bio, table gibi üst sistemler çok büyürse:

```text
(A:array_id,index)
```

gibi bir şey akla gelir.

Ama bu artık yüksek seviye olur. UX-Minima’nın minimal karakterini bozar.

Karar:

```text
Compiler çekirdeğine koyma.
Kütüphane/macro ile çöz.
```

---

# 6. Benim önerdiğim nihai adresleme sınıfları

## 6.1 Core / standart kalması gerekenler

Bunlar kesin kalmalı:

```text
(T)
(T+N)
(T-N)
(T:N)
(D:N)
(S:N)
(SP)
(P)
(E)
(F)
(*T)
(*(T+N))
(*(T-N))
(D@T)
(D@T+N)
(D@T-N)
(D@(T+K)+N)
```

Bunlar UX-Minima’nın düşük seviyeli, 6502 benzeri karakterine uygun.

---

## 6.2 Eklenmesi mantıklı olanlar

Bunları ciddi düşünürdüm:

```text
(SP+N)
(SP-N)
(D:BASE+P)
(T:BASE+P)
(D@D:N)
(T@D:N)
(M:N)    sadece wild
(B:N)    sadece wild raw byte
```

Öncelik sıralamam:

```text
1. (SP+N) / (SP-N)
2. (D:BASE+P)
3. (D@(T+K)+N) genel biçimi
4. (D@D:N)
5. (T@D:N)
6. (B:N) wild raw byte
7. (M:N) wild full memory
```

---

## 6.3 Eklenmemesi gerekenler

Şunları şimdilik önermem:

```text
(R:N)        register bank
(I:N)        immediate adresleme
(A:...)      yüksek seviye array adresleme
(LABEL)      label adresleme
(FUNC:...)   fonksiyon/local değişken adresleme
```

Neden?

Çünkü UX-Minima’nın çekirdek kararı yüksek seviyeli kelime/soyutlama eklemek değil; küçük sembolik çekirdeği güçlü adresleme ve meta servislerle büyütmek. Tasarım belgesi de yüksek seviyeli `FUNCTION`, `LABEL`, `FOR`, `IF THEN ELSE` gibi kelimelerin çekirdeğe doldurulmamasını açıkça söylüyor. 

---

# 7. Adresleme eklerken dikkat edilmesi gereken en büyük risk

Her yeni adresleme modu şunları gerektirir:

```text
1. Parser desteği
2. Native codegen desteği
3. Runtime interpreter desteği
4. Final compiler desteği
5. VS Code internal interpreter desteği
6. Syntax highlighting desteği
7. Diagnostics desteği
8. Test dosyası
9. Safe/Normal/Wild izin kuralı
10. Bounds davranışı
```

Yani bir adresleme modunu sadece parser’a eklemek yetmez.

Örneğin `(D@D:N)` eklenirse:

```text
Native compiler parse edecek mi?
Final compiler parse edecek mi?
ASM emitter adresi hesaplayacak mı?
Interpreter aynı sonucu verecek mi?
VS Code memory watch bunu gösterecek mi?
Safe mode bunu reddedecek mi?
Wild mode izin verecek mi?
Testi var mı?
```

Bunların hepsi cevaplanmalı.

---

# 8. Biyoloji / protein dizileme açısından en değerli adresleme modları

Senin biyoloji fikrine göre en değerli modlar şunlar:

## Kodon tablosu için

```text
(D@T)
(D@T+N)
(D@(T+K)+N)
(D:BASE+P)
```

Çünkü:

```text
T veya T+K = kodon id
D alanı    = kodon -> amino acid tablosu
```

Örnek mantık:

```text
tape[pointer] = codon_id
data[codon_id] = amino_acid_id
```

Okuma:

```text
(D@T)
```

Eğer her kodon için birden fazla bilgi tutulacaksa:

```text
data[codon_id*4 + 0] = amino acid id
data[codon_id*4 + 1] = charge
data[codon_id*4 + 2] = hydropathy
data[codon_id*4 + 3] = molecular weight index
```

Bunun için en güzel adresleme şu olurdu:

```text
(D:BASE+T*SCALE+N)
```

Ama bu çok karmaşık. Daha minimal çözüm:

```text
önce codon_id*4 hesapla
sonra (D@T+N) kullan
```

Yani compiler’a karmaşık adresleme eklemek yerine hesaplamayı UXM programına bırakmak daha uygun.

---

# 9. En kritik önerim

Ben UX-Minima için adresleme sistemini şöyle kilitlerdim:

## Resmi V3.1 adresleme

```text
(T)
(T+N)
(T-N)
(T:N)
(D:N)
(S:N)
(SP)
(P)
(E)
(F)
(*T)
(*(T+N))
(*(T-N))
(D@T)
(D@T+N)
(D@T-N)
(D@(T+K)+N)
```

## V3.2 aday adresleme

```text
(SP+N)
(SP-N)
(D:BASE+P)
(T:BASE+P)
(D@D:N)
(T@D:N)
```

## Wild-only deneysel adresleme

```text
(B:N)
(M:N)
```

---

# 10. Son karar

Evet, daha fazla adresleme modu olabilirdi.

Ama hepsini eklemek doğru olmaz.

Benim teknik kararım:

```text
V3.1’de mevcut adresleme ailesi yeterince güçlü.
Öncelikli eksik varsa bu (SP±N) ve base+pointer adreslemedir.
Biyoloji, matris, tablo, lookup, protein/codon işleri için en yararlı genişleme (D:BASE+P) veya genelleştirilmiş (D@(T+K)+N) olur.
Raw memory gibi modlar sadece Wild mode’da kalmalı.
Immediate, register bank, array descriptor gibi modlar compiler çekirdeğine girmemeli; macro/kütüphane ile çözülmeli.
```

En kısa hüküm:

```text
Adresleme sistemi büyütülebilir; fakat çekirdeği büyütmeden, Safe/Normal/Wild sınırlarıyla ve her yeni mod için parser + native + final + full tool + VS Code + test desteği şartıyla büyütülmeli.
```

Bence ilk eklenecek adresleme modları şunlar olmalı:

```text
(SP+N)
(SP-N)
(D:BASE+P)
(D@(T+K)+N) genel form
```

Bunlar UX-Minima’nın karakterine uygun, güçlü ve bilimsel/tablolu işlemler için gerçekten işe yarar.

Mete abi, çok iyi soru. Adreslemeyi anlamanın en kolay yolu şu:

**Tape’i 50 kutuluk bir raf gibi düşün.**
Her kutunun altında bir numara var. Pointer da şu an hangi kutuya baktığını gösteren parmak gibi.

Aşağıdaki anlatımda bütün örneklerde başlangıç pointer’ı:

```text
P = 20
```

Yani pointer 20 numaralı hücreyi gösteriyor.

Tasarımda `[]` döngü için, `()` ise adresleme için ayrılmıştır. Yani `+(T+1)` gibi yazınca `+` komutu çalışır ama hedef hücreyi `(T+1)` adresleme ifadesi belirler. Bu karar UX-Minima’nın çekirdek tasarımında açıkça belirtilmiştir. 

---

# 1. Başlangıç Tape’i

Aşağıdaki tape bizim örnek tape’imiz olsun.

```text
Adres:  01  02  03  04  05  06  07  08  09  10
Değer:  11  04  28  09  14  02  31  08  17  05

Adres:  11  12  13  14  15  16  17  18  19  20
Değer:  22  01  19  06  40  03  13  30  44  07
                                                   ^
                                                   P

Adres:  21  22  23  24  25  26  27  28  29  30
Değer:  12  00  21  09  33  18  02  55  04  10

Adres:  31  32  33  34  35  36  37  38  39  40
Değer:  65  66  67  68  69  70  15  16  23  24

Adres:  41  42  43  44  45  46  47  48  49  50
Değer:  25  26  27  28  29  30  31  32  99 100
```

Burada:

```text
P = 20
T = tape
T[P] = tape[20] = 7
```

Yani pointer’ın baktığı hücre 20. hücredir ve değeri 7’dir.

---

# 2. Data ve Stack alanımız

Tape dışında iki alan daha düşünelim.

## Data alanı

Data alanını tablo gibi düşün. Sabit veriler, karakter tabloları, kodon tabloları, matris verileri burada olabilir.

```text
Data adres: 01  02  03  04  05  06  07  08  09  10
Data değer: 100 65  66  67  68  69  77  88  99  42

Data adres: 11  12  13  14  15  16  17  18  19  20
Data değer: 05  40  72 101 115  03  04  05  06  07

Data adres: 21  22  23  24  25  26  27  28  29  30
Data değer: 08  09  10  11  12  13  14  15  16 200

Data adres: 31  32  33  34  35
Data değer: 201 202 203 204 205
```

## Stack alanı

Stack’i üst üste dizilmiş tabak gibi düşün. Son giren ilk çıkar.

```text
Stack adres: 01  02  03  04  05
Stack değer: 05  10  15  20  25
                              ^
                              SP
```

Burada:

```text
SP = 5
Stack top = stack[5] = 25
```

---

# 3. Komut ve adresleme ayrımı

UX-Minima’da komut ayrı şeydir, adresleme ayrı şeydir.

Örnek:

```text
+
```

Bu, aktif hücreyi artırır.

Açık yazımı:

```text
+(T)
```

Yani:

```text
komut     = +
adresleme = (T)
```

Şu ise başka bir hücreyi artırır:

```text
+(T+1)
```

Burada:

```text
komut     = +
adresleme = (T+1)
```

Yani komut aynı, hedef değişti.

---

# 4. En temel komutlar

Önce komutları genç birine anlatır gibi özetleyelim.

| Komut      | Basit anlamı                                             |            |
| ---------- | -------------------------------------------------------- | ---------- |
| `>`        | Pointer’ı bir sağa götürür                               |            |
| `<`        | Pointer’ı bir sola götürür                               |            |
| `+`        | Hedef hücreyi 1 artırır                                  |            |
| `+kN`      | Hedef hücreyi N kadar artırır                            |            |
| `-`        | Hedef hücreyi 1 azaltır                                  |            |
| `-kN`      | Hedef hücreyi N kadar azaltır                            |            |
| `0`        | Hedef hücreyi sıfırlar                                   |            |
| `.`        | Hedef hücredeki değeri karakter olarak basar             |            |
| `,`        | Girişten karakter okur, hedef hücreye yazar              |            |
| `[`        | Aktif hücre sıfır değilse döngüye girer                  |            |
| `]`        | Aktif hücre sıfır değilse döngü başına döner             |            |
| `$`        | Hedef hücredeki değeri stack’e atar                      |            |
| `%`        | Stack’ten değer alır, hedef hücreye yazar                |            |
| `?`        | Stack’ten gelen değer ile hedef hücre eşit mi diye bakar |            |
| `!`        | Stack’ten gelen değer hedef hücreden büyük mü diye bakar |            |
| `;`        | Stack’ten gelen değer hedef hücreden küçük mü diye bakar |            |
| `&`        | Bitwise AND                                              |            |
| `          | `                                                        | Bitwise OR |
| `^`        | Bitwise XOR                                              |            |
| `~`        | Bitwise NOT                                              |            |
| `{`        | Sola bit kaydırma, yani yaklaşık 2 ile çarpma            |            |
| `}`        | Sağa bit kaydırma, yani yaklaşık 2’ye bölme              |            |
| `e`        | Status/error değerini hedef hücreye yazar                |            |
| `@N`       | N numaralı meta servisi çağırır                          |            |
| `@#`       | Aktif hücredeki sayıyı meta servis numarası sayar        |            |
| `@!N`      | Macro’yu atlayıp doğrudan host/runtime servisi çağırır   |            |
| `sN=...`   | String/data tanımlar                                     |            |
| `pN`       | Tanımlı string’i basar                                   |            |
| `mN={...}` | Macro tanımlar                                           |            |
| `:...`     | Relative branch/jump                                     |            |

Şimdi her adresleme modunu tek tek gerçek hücrelerle gösterelim.

---

# 5. `(T)` — aktif tape hücresi

## Anlam

```text
(T) = pointer’ın baktığı tape hücresi
```

Bizde:

```text
P = 20
(T) = tape[20]
tape[20] = 7
```

## Komut

```text
+(T)
```

Kısa yazımı:

```text
+
```

## İlk hâl

```text
Adres:  18  19  20  21  22
Değer:  30  44  07  12  00
                 ^
                 P
```

## İşlem

```text
+(T)
```

Yani:

```text
tape[20] = tape[20] + 1
tape[20] = 7 + 1 = 8
```

## Son hâl

```text
Adres:  18  19  20  21  22
Değer:  30  44  08  12  00
                 ^
                 P
```

Pointer yer değiştirmedi. Sadece 20. hücre değişti.

---

# 6. `(T+N)` — pointer’ın sağındaki hücre

## Anlam

```text
(T+N) = tape[P + N]
```

Mesela:

```text
(T+2) = tape[20 + 2] = tape[22]
```

## Komut

```text
+k5(T+2)
```

Bu, pointer’ın iki sağındaki hücreyi 5 artırır.

## İlk hâl

```text
Adres:  20  21  22  23  24
Değer:  07  12  00  21  09
         ^
         P
```

## İşlem

```text
+k5(T+2)
```

Hedef:

```text
P + 2 = 20 + 2 = 22
tape[22] = 0
```

Sonuç:

```text
tape[22] = 0 + 5 = 5
```

## Son hâl

```text
Adres:  20  21  22  23  24
Değer:  07  12  05  21  09
         ^
         P
```

Pointer hâlâ 20’de. Sadece 22. hücre değişti.

---

# 7. `(T-N)` — pointer’ın solundaki hücre

## Anlam

```text
(T-N) = tape[P - N]
```

Mesela:

```text
(T-2) = tape[20 - 2] = tape[18]
```

## Komut

```text
-(T-2)
```

## İlk hâl

```text
Adres:  17  18  19  20  21
Değer:  13  30  44  07  12
                 ^
                 P
```

## İşlem

```text
-(T-2)
```

Hedef:

```text
P - 2 = 18
tape[18] = 30
```

Sonuç:

```text
tape[18] = 30 - 1 = 29
```

## Son hâl

```text
Adres:  17  18  19  20  21
Değer:  13  29  44  07  12
                 ^
                 P
```

Pointer değişmedi.

---

# 8. `(T:N)` — mutlak tape adresi

## Anlam

```text
(T:N) = tape[N]
```

Pointer nerede olursa olsun N numaralı tape hücresine gider.

## Komut

```text
0(T:31)
```

## İlk hâl

```text
Adres:  29  30  31  32  33
Değer:  04  10  65  66  67

Pointer hâlâ:
Adres:  18  19  20  21  22
Değer:  30  44  07  12  00
                 ^
                 P
```

## İşlem

```text
0(T:31)
```

Hedef:

```text
tape[31]
```

Sonuç:

```text
tape[31] = 0
```

## Son hâl

```text
Adres:  29  30  31  32  33
Değer:  04  10  00  66  67

Pointer hâlâ:
Adres:  18  19  20  21  22
Değer:  30  44  07  12  00
                 ^
                 P
```

Bu çok önemlidir: pointer 20’de kalır ama 31. hücre değişir.

---

# 9. `(D:N)` — data alanındaki mutlak adres

## Anlam

```text
(D:N) = data[N]
```

Tape değil, data alanı hedef alınır.

## Komut

```text
+k1(D:2)
```

Data[2] başlangıçta 65 idi. 65 ASCII’de `A` karakteridir.

## İlk hâl

```text
Data adres: 01  02  03  04  05
Data değer:100 65  66  67  68
                ^
              D:2
```

## İşlem

```text
+k1(D:2)
```

Sonuç:

```text
data[2] = 65 + 1 = 66
```

## Son hâl

```text
Data adres: 01  02  03  04  05
Data değer:100 66  66  67  68
                ^
              D:2
```

Tape hiç değişmedi. Pointer da değişmedi.

---

# 10. `(S:N)` — stack alanındaki mutlak hücre

## Anlam

```text
(S:N) = stack[N]
```

## Komut

```text
+k2(S:3)
```

## İlk hâl

```text
Stack adres: 01  02  03  04  05
Stack değer: 05  10  15  20  25
                     ^
                    S:3
```

## İşlem

```text
+k2(S:3)
```

Sonuç:

```text
stack[3] = 15 + 2 = 17
```

## Son hâl

```text
Stack adres: 01  02  03  04  05
Stack değer: 05  10  17  20  25
                     ^
                    S:3
```

Bu güçlüdür ama dikkat ister. Çünkü stack normalde `$` ve `%` ile kullanılır. `(S:N)` stack’in içine elle girmek gibidir.

---

# 11. `(SP)` — stack’in tepe hücresi

## Anlam

Burada eğitim için şöyle kabul ediyoruz:

```text
SP = stack top
SP = 5
(SP) = stack[5]
```

## Komut

```text
+(SP)
```

## İlk hâl

```text
Stack adres: 01  02  03  04  05
Stack değer: 05  10  15  20  25
                                 ^
                                 SP
```

## İşlem

```text
+(SP)
```

Sonuç:

```text
stack[5] = 25 + 1 = 26
```

## Son hâl

```text
Stack adres: 01  02  03  04  05
Stack değer: 05  10  15  20  26
                                 ^
                                 SP
```

Bu mod, stack’in en üstündeki değeri hızlı okumak veya değiştirmek için kullanılır.

---

# 12. `(P)` — pointer değerinin kendisi

## Anlam

```text
(P) = pointer register
```

Yani bu tape hücresi değil, pointer’ın kendi sayısıdır.

Bizde başlangıçta:

```text
P = 20
```

## Komut

```text
+(P)
```

## İlk hâl

```text
Pointer:
P = 20

Tape:
Adres:  19  20  21
Değer:  44  07  12
             ^
             P
```

## İşlem

```text
+(P)
```

Bu şuna benzer:

```text
P = P + 1
P = 21
```

## Son hâl

```text
Pointer:
P = 21

Tape:
Adres:  19  20  21  22
Değer:  44  07  12  00
                 ^
                 P
```

Burada hiçbir tape hücresi değişmedi.
Sadece pointer 20’den 21’e geçti.

Bu yüzden `(P)` yazma güçlü ama tehlikelidir.

---

# 13. `(E)` — status/error byte

## Anlam

```text
(E) = sistemin hata/status değeri
```

Mesela status şöyle olsun:

```text
E = 15
```

15 genellikle “division by zero” gibi bir hata kodu olabilir.

## Komut

```text
0(E)
```

## İlk hâl

```text
Status:
E = 15
```

## İşlem

```text
0(E)
```

Sonuç:

```text
E = 0
```

## Son hâl

```text
Status:
E = 0
```

Ama dikkat: Normal programda status byte’ı doğrudan yazmak yerine meta servisle temizlemek daha güvenlidir.

Daha güvenli kullanım:

```text
e(T+1)
```

Bu, status değerini tape’te bir hücreye kopyalar.

Örnek:

```text
E = 15
P = 20
T+1 = tape[21]
```

İlk hâl:

```text
Adres:  20  21  22
Değer:  07  12  00
         ^
         P
```

Komut:

```text
e(T+1)
```

Son hâl:

```text
Adres:  20  21  22
Değer:  07  15  00
         ^
         P
```

Yani status değeri tape[21] içine yazıldı.

---

# 14. `(F)` — flags word

## Anlam

```text
(F) = flags
```

Flags içinde şöyle durumlar olabilir:

```text
Z = zero
C = carry
O = overflow
S = sign
B = bounds check
W = wild mode
```

Diyelim:

```text
F = 128
```

Bu sadece örnek bir flags değeridir.

## Komut

```text
0(F)
```

## İlk hâl

```text
Flags:
F = 128
```

## İşlem

```text
0(F)
```

Sonuç:

```text
F = 0
```

## Son hâl

```text
Flags:
F = 0
```

Bu da tehlikelidir. Çünkü flags’i sıfırlarsan sistemin mod bilgileri bozulabilir.

Daha güvenli kullanım, flags’i okumaktır:

```text
.(F)
```

Ama direkt karakter basacağı için ekranda okunabilir bir sayı gibi görünmeyebilir. Decimal yazdırmak için meta servis gerekir.

---

# 15. `(*T)` — tape indirect

Bu en önemli adresleme modlarından biridir.

## Anlam

```text
(*T) = tape[tape[P]]
```

Yani aktif hücredeki sayı bir adres kabul edilir.

Bizde:

```text
P = 20
tape[20] = 7
```

O zaman:

```text
(*T) = tape[7]
```

Çünkü tape[20] içinde 7 yazıyor.

## Komut

```text
+(*T)
```

## İlk hâl

```text
Adres:  06  07  08        19  20  21
Değer:  02  31  08        44  07  12
             ^                 ^
          hedef               P

P = 20
tape[20] = 7
hedef = tape[7]
```

## İşlem

```text
+(*T)
```

Sonuç:

```text
tape[7] = 31 + 1 = 32
```

## Son hâl

```text
Adres:  06  07  08        19  20  21
Değer:  02  32  08        44  07  12
             ^                 ^
          hedef               P
```

Pointer değişmedi. Aktif hücre de değişmedi.
Ama aktif hücrenin gösterdiği adres değişti.

Bunu şöyle düşün:

```text
tape[20] bana diyor ki: "Git 7. hücreye bak."
```

---

# 16. `(*(T+N))` — pointer çevresindeki hücreyi adres gibi kullanma

## Anlam

```text
(*(T+N)) = tape[tape[P+N]]
```

Örnek:

```text
(*(T+1))
```

Bizde:

```text
P = 20
P+1 = 21
tape[21] = 12
```

O zaman:

```text
(*(T+1)) = tape[12]
```

## Komut

```text
+(*(T+1))
```

## İlk hâl

```text
Adres:  11  12  13        20  21  22
Değer:  22  01  19        07  12  00
             ^             ^   ^
          hedef            P  P+1

tape[21] = 12
hedef = tape[12]
```

## İşlem

```text
+(*(T+1))
```

Sonuç:

```text
tape[12] = 1 + 1 = 2
```

## Son hâl

```text
Adres:  11  12  13        20  21  22
Değer:  22  02  19        07  12  00
             ^             ^   ^
          hedef            P  P+1
```

Bu, dolaylı adreslemedir. Hücrede sayı var; o sayı başka hücrenin adresi gibi kullanılır.

---

# 17. `(*(T-N))` — pointer’ın solundaki hücreyi adres gibi kullanma

## Anlam

```text
(*(T-N)) = tape[tape[P-N]]
```

Örnek:

```text
(*(T-2))
```

Bizde:

```text
P = 20
P-2 = 18
tape[18] = 30
```

O zaman:

```text
(*(T-2)) = tape[30]
```

## Komut

```text
+(*(T-2))
```

## İlk hâl

```text
Adres:  18  19  20        29  30  31
Değer:  30  44  07        04  10  65
         ^       ^             ^
        P-2      P           hedef

tape[18] = 30
hedef = tape[30]
```

## İşlem

```text
+(*(T-2))
```

Sonuç:

```text
tape[30] = 10 + 1 = 11
```

## Son hâl

```text
Adres:  18  19  20        29  30  31
Değer:  30  44  07        04  11  65
         ^       ^             ^
        P-2      P           hedef
```

---

# 18. `(D@T)` — tape değeriyle data tablosuna gitme

Bu biyoloji, matris, tablo, kodon gibi işler için çok önemlidir.

## Anlam

```text
(D@T) = data[tape[P]]
```

Bizde:

```text
P = 20
tape[20] = 7
```

O zaman:

```text
(D@T) = data[7]
```

Data[7] başlangıçta 77.

## Komut

```text
+(D@T)
```

## İlk hâl

```text
Tape:
Adres:  19  20  21
Değer:  44  07  12
             ^
             P

Data:
Adres:  06  07  08
Değer:  69  77  88
             ^
          hedef
```

## İşlem

```text
+(D@T)
```

Hesap:

```text
tape[20] = 7
hedef = data[7]
data[7] = 77 + 1 = 78
```

## Son hâl

```text
Tape:
Adres:  19  20  21
Değer:  44  07  12
             ^
             P

Data:
Adres:  06  07  08
Değer:  69  78  88
             ^
          hedef
```

Tape değişmedi. Data tablosundan bir yer değişti.

---

# 19. `(D@T+N)` — data tablosunda offset kullanma

## Anlam

```text
(D@T+N) = data[tape[P] + N]
```

Örnek:

```text
(D@T+2)
```

Bizde:

```text
tape[20] = 7
7 + 2 = 9
```

O zaman:

```text
(D@T+2) = data[9]
```

## Komut

```text
+(D@T+2)
```

## İlk hâl

```text
Tape:
Adres:  20
Değer:  07
         ^
         P

Data:
Adres:  07  08  09  10
Değer:  77  88  99  42
                 ^
              hedef
```

## İşlem

```text
+(D@T+2)
```

Sonuç:

```text
data[9] = 99 + 1 = 100
```

## Son hâl

```text
Data:
Adres:  07  08  09  10
Değer:  77  88 100  42
                 ^
              hedef
```

Bu şuna benzer:

```text
tablodaki başlangıç adresini tape’ten al
sonra 2 hücre ileri git
orada işlem yap
```

---

# 20. `(D@T-N)` — data tablosunda geriye offset

## Anlam

```text
(D@T-N) = data[tape[P] - N]
```

Örnek:

```text
(D@T-2)
```

Bizde:

```text
tape[20] = 7
7 - 2 = 5
```

O zaman:

```text
(D@T-2) = data[5]
```

## Komut

```text
+(D@T-2)
```

## İlk hâl

```text
Data:
Adres:  04  05  06  07
Değer:  67  68  69  77
             ^
          hedef
```

## İşlem

```text
+(D@T-2)
```

Sonuç:

```text
data[5] = 68 + 1 = 69
```

## Son hâl

```text
Data:
Adres:  04  05  06  07
Değer:  67  69  69  77
             ^
          hedef
```

---

# 21. `(D@(T-2)+N)` — tape’teki başka hücreyi base adres yapmak

Bu biraz daha ileri seviye ama mantığı basit.

## Anlam

```text
(D@(T-2)+N) = data[tape[P-2] + N]
```

Bizde:

```text
P = 20
P-2 = 18
tape[18] = 30
```

Örnek:

```text
(D@(T-2)+3)
```

O zaman:

```text
tape[18] = 30
30 + 3 = 33
hedef = data[33]
```

## Komut

```text
+(D@(T-2)+3)
```

## İlk hâl

```text
Tape:
Adres:  18  19  20
Değer:  30  44  07
         ^       ^
        P-2      P

Data:
Adres:  30  31  32  33  34
Değer: 200 201 202 203 204
                     ^
                  hedef
```

## İşlem

```text
+(D@(T-2)+3)
```

Sonuç:

```text
data[33] = 203 + 1 = 204
```

## Son hâl

```text
Data:
Adres:  30  31  32  33  34
Değer: 200 201 202 204 204
                     ^
                  hedef
```

Bu yapı şuna çok benzer:

```text
T-2 hücresinde bir tablo başlangıcı var.
Ben o tablonun 3. offsetindeki veriyi değiştiriyorum.
```

Bu protein/kodon tablosu, matris satırı, polinom katsayıları gibi şeyler için çok işe yarar.

---

# 22. `(D@(T+K)+N)` — genel tablo/base adresleme

Bu, biraz daha genel yazımdır.

## Anlam

```text
(D@(T+K)+N) = data[tape[P+K] + N]
```

Örnek:

```text
(D@(T+1)+4)
```

Bizde:

```text
P = 20
P+1 = 21
tape[21] = 12
12 + 4 = 16
hedef = data[16]
```

## Komut

```text
+(D@(T+1)+4)
```

## İlk hâl

```text
Tape:
Adres:  20  21  22
Değer:  07  12  00
         ^   ^
         P  P+1

Data:
Adres:  15  16  17
Değer: 115 03  04
             ^
          hedef
```

## İşlem

```text
+(D@(T+1)+4)
```

Sonuç:

```text
data[16] = 3 + 1 = 4
```

## Son hâl

```text
Data:
Adres:  15  16  17
Değer: 115 04  04
             ^
          hedef
```

Bu mode çok güçlüdür çünkü pointer çevresindeki hücreleri “tablo başlangıç adresi” gibi kullanabilirsin.

---

# 23. Örnek: Aynı komut, farklı adresleme

Şimdi sadece `+` komutunu düşün.

Başlangıçta:

```text
P = 20
tape[20] = 7
tape[21] = 12
tape[7]  = 31
data[7]  = 77
```

Aynı `+` komutu farklı hedeflerde bambaşka yerleri değiştirir:

| Komut      | Hedef hesap                  | Değişen yer       |
| ---------- | ---------------------------- | ----------------- |
| `+`        | `tape[20]`                   | tape[20]: 7 → 8   |
| `+(T+1)`   | `tape[21]`                   | tape[21]: 12 → 13 |
| `+(T-2)`   | `tape[18]`                   | tape[18]: 30 → 31 |
| `+(T:31)`  | `tape[31]`                   | tape[31]: 65 → 66 |
| `+(D:7)`   | `data[7]`                    | data[7]: 77 → 78  |
| `+(*T)`    | `tape[tape[20]] = tape[7]`   | tape[7]: 31 → 32  |
| `+(D@T)`   | `data[tape[20]] = data[7]`   | data[7]: 77 → 78  |
| `+(D@T+2)` | `data[tape[20]+2] = data[9]` | data[9]: 99 → 100 |

Gördüğün gibi komut aynı:

```text
+
```

Ama adresleme değişince hedef değişiyor.

---

# 24. Bunu çocuklara nasıl anlatırız?

Şöyle anlat:

```text
Komut = ne yapacağım?
Adresleme = nereye yapacağım?
```

Örnek:

```text
+       = artır
(T)     = şu an baktığım kutu
(T+2)   = baktığım kutunun 2 sağındaki kutu
(T:31)  = doğrudan 31 numaralı kutu
(D:7)   = data rafındaki 7 numaralı kutu
(*T)    = şu kutunun içinde yazan numaraya git
(D@T)   = şu kutunun içindeki numarayı data rafında adres kabul et
```

Yani:

```text
+(T+2)
```

şu demek:

```text
Artır,
ama aktif kutuyu değil,
aktif kutudan 2 sağdaki kutuyu artır.
```

---

# 25. Core komutlar adresleme ile nasıl çalışır?

Şimdi her komutu basitçe açıklayalım.

## `>` — pointer sağa

```text
>
```

İlk hâl:

```text
Adres:  19  20  21
Değer:  44  07  12
             ^
             P
```

Son hâl:

```text
Adres:  19  20  21
Değer:  44  07  12
                 ^
                 P
```

Pointer 20’den 21’e geçti. Değerler değişmedi.

---

## `<` — pointer sola

```text
<
```

İlk hâl:

```text
Adres:  19  20  21
Değer:  44  07  12
             ^
             P
```

Son hâl:

```text
Adres:  19  20  21
Değer:  44  07  12
         ^
         P
```

Pointer 20’den 19’a geçti.

---

## `+` / `+kN` — artır

```text
+
+k5
+k5(T+2)
```

Örnek:

```text
+k5(T+2)
```

Hedef:

```text
tape[22]
```

Sonuç:

```text
tape[22] = tape[22] + 5
```

---

## `-` / `-kN` — azalt

```text
-
-k3
-k3(T-1)
```

Örnek:

```text
-k3(T-1)
```

Hedef:

```text
tape[19]
```

Başta tape[19] = 44 ise:

```text
tape[19] = 44 - 3 = 41
```

---

## `0` — sıfırla

```text
0(T:31)
```

Başta tape[31] = 65 ise:

```text
tape[31] = 0
```

---

## `.` — karakter bas

```text
.(T:31)
```

Başta tape[31] = 65 ise:

```text
65 ASCII = A
```

Ekrana:

```text
A
```

basar.

---

## `,` — karakter oku

```text
,(T)
```

Kullanıcı klavyeden `B` girerse:

```text
B = ASCII 66
tape[20] = 66
```

---

## `$` — stack’e at

```text
$(T)
```

Başta:

```text
tape[20] = 7
stack top = 25
```

Komut:

```text
$(T)
```

Sonuç:

```text
7 stack’e eklenir
```

Stack:

```text
Önce:
Stack adres: 01  02  03  04  05
Stack değer: 05  10  15  20  25

Sonra:
Stack adres: 01  02  03  04  05  06
Stack değer: 05  10  15  20  25  07
```

---

## `%` — stack’ten al

```text
%(T+1)
```

Stack’in tepesindeki değer 7 ise:

```text
%(T+1)
```

şunu yapar:

```text
stack’ten 7 al
tape[21] = 7
```

Tape:

```text
Önce:
Adres:  20  21  22
Değer:  07  12  00
         ^
         P

Sonra:
Adres:  20  21  22
Değer:  07  07  00
         ^
         P
```

---

## `?` — eşit mi?

Karşılaştırma için önce bir değeri stack’e atarsın.

Örnek:

```text
$(T)
?(T+1)
```

Başta:

```text
tape[20] = 7
tape[21] = 12
```

İşlem:

```text
$(T)      stack’e 7 atar
?(T+1)    stack’ten 7 alır, tape[21] ile karşılaştırır
```

Soru:

```text
7 == 12 mi?
```

Cevap:

```text
hayır, sonuç 0
```

Sonuç genelde hedef hücreye yazılır:

```text
tape[21] = 0
```

---

## `!` — büyük mü?

```text
$(T+1)
!(T)
```

Başta:

```text
tape[21] = 12
tape[20] = 7
```

Soru:

```text
12 > 7 mi?
```

Cevap:

```text
evet, sonuç 1
```

Sonuç:

```text
tape[20] = 1
```

---

## `;` — küçük mü?

```text
$(T)
;(T+1)
```

Başta:

```text
tape[20] = 7
tape[21] = 12
```

Soru:

```text
7 < 12 mi?
```

Cevap:

```text
evet, sonuç 1
```

Sonuç:

```text
tape[21] = 1
```

---

## `&` — AND

```text
$(T)
&(T+1)
```

Başta:

```text
tape[20] = 7
tape[21] = 12
```

Binary olarak:

```text
7  = 00000111
12 = 00001100
AND= 00000100 = 4
```

Sonuç:

```text
tape[21] = 4
```

---

## `|` — OR

```text
$(T)
|(T+1)
```

```text
7  = 00000111
12 = 00001100
OR = 00001111 = 15
```

Sonuç:

```text
tape[21] = 15
```

---

## `^` — XOR

```text
$(T)
^(T+1)
```

```text
7   = 00000111
12  = 00001100
XOR = 00001011 = 11
```

Sonuç:

```text
tape[21] = 11
```

---

## `~` — NOT

```text
~(T)
```

Byte modda:

```text
tape[20] = 7
7 = 00000111
NOT = 11111000 = 248
```

Sonuç:

```text
tape[20] = 248
```

---

## `{` — sola kaydır

```text
{(T)
```

Başta:

```text
tape[20] = 7
```

Sonuç:

```text
7 << 1 = 14
tape[20] = 14
```

Bu çoğu durumda 2 ile çarpmaya benzer.

---

## `}` — sağa kaydır

```text
}(T)
```

Başta:

```text
tape[20] = 7
```

Sonuç:

```text
7 >> 1 = 3
tape[20] = 3
```

Bu çoğu durumda 2’ye bölmeye benzer.

---

## `e` — status oku

```text
e(T+1)
```

Başta:

```text
status E = 15
tape[21] = 12
```

Sonuç:

```text
tape[21] = 15
```

---

## `@N` — meta servis çağır

Örnek:

```text
@20
```

`@20` genelde toplama servisi gibi düşünülebilir.

Meta servislerde çoğu zaman hücreler frame gibi kullanılır:

```text
T-2 = arg1
T-1 = arg2
T   = meta id veya aktif alan
T+1 = result
```

Örnek:

```text
tape[18] = 5
tape[19] = 9
P = 20
@20
```

Sonuç:

```text
tape[21] = 5 + 9 = 14
```

Grafik:

```text
Önce:
Adres:  18  19  20  21
Değer:  05  09  07  12
         ^   ^   ^   ^
        A1  A2   P  sonuç yeri

Sonra:
Adres:  18  19  20  21
Değer:  05  09  07  14
                 ^
                 P
```

---

## `@#` — dinamik meta çağrısı

```text
@#
```

Bu, aktif hücredeki değeri meta servis numarası kabul eder.

Bizde:

```text
P = 20
tape[20] = 7
```

O zaman:

```text
@#
```

şu anlama gelir:

```text
@7 çağır
```

Yani servis numarası kaynak kodda sabit değil, tape’teki değerden gelir.

---

## `@!N` — doğrudan host/runtime servisi

```text
@!210
```

Bu, macro varsa bile onu atlayıp doğrudan runtime/host servis çağırmak içindir.

Özellikle standart kütüphanelerde şuna benzer kullanılır:

```text
m210={@!210}
```

Kullanıcı `@210` dediğinde macro çalışır, macro içinden gerçek runtime servisi çağrılır.

---

## `sN=...` — string/data tanımı

Örnek:

```text
s1=1,{ABC}
```

Bu data alanına `A`, `B`, `C` karakterlerini yazar.

```text
A = 65
B = 66
C = 67
```

Data:

```text
Data adres: 01  02  03
Data değer: 65  66  67
```

---

## `pN` — string bas

```text
p1
```

`p1`, `s1` ile tanımlanan string’i basar.

Örnek:

```text
s1=1,{ABC}
p1
```

Çıktı:

```text
ABC
```

---

## `mN={...}` — macro tanımı

Örnek:

```text
m128={+k5.}
```

Sonra:

```text
@128
```

dediğinde macro içindeki kod çalışır.

Yani:

```text
+k5.
```

çalışır.

---

## `:` — branch / jump

Basit düşün:

```text
:+3
```

şu anki instruction’dan 3 adım ileri git demektir.

Koşullu biçimleri de olabilir:

```text
:0+3
:z+3
:c-2
```

Ama bunu adresleme gibi değil, akış kontrolü gibi düşünmek gerekir.

---

# 26. Kısa büyük özet

Adresleme modlarını anlamak için şunu ezberle:

```text
Komut = ne yapılacak?
Adresleme = nereye yapılacak?
```

Örnek:

```text
+(T)
```

```text
aktif tape hücresini artır
```

```text
+(T+2)
```

```text
aktif hücrenin 2 sağındaki tape hücresini artır
```

```text
+(T:31)
```

```text
31 numaralı tape hücresini artır
```

```text
+(D:7)
```

```text
7 numaralı data hücresini artır
```

```text
+(*T)
```

```text
aktif hücrede yazan numarayı tape adresi kabul et, o hücreyi artır
```

```text
+(D@T)
```

```text
aktif hücrede yazan numarayı data adresi kabul et, data’daki o hücreyi artır
```

```text
+(D@(T-2)+3)
```

```text
pointer’ın 2 solundaki hücrede yazan sayıyı data başlangıcı kabul et,
oradan 3 ileri git,
o data hücresini artır
```

---

# 27. En kolay benzetme

Tape’i mahalle gibi düşün:

```text
(T)       = şu an durduğun ev
(T+2)     = iki ev sağdaki ev
(T-2)     = iki ev soldaki ev
(T:31)    = doğrudan 31 numaralı ev
(*T)      = şu evin kapısında yazan numaralı eve git
(D@T)     = şu evin kapısında yazan numarayı data defterinde ara
(D@T+2)   = defterdeki o satırdan iki satır sonrasına bak
```

Bu mantık oturunca UX-Minima’nın adresleme sistemi çok kolaylaşır.
