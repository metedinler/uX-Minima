




# UX-MINIMA x64 V3.1 Tasarım Belgesi

## Bölüm 1 — Çekirdek Kararlar, Bayrak Sistemi, Hata/Status Byte, Signed/Unsigned, Endian, Carry/Overflow

## 1. V3.1 tasarımının ana kararı

UX-MINIMA x64 V3.1, artık sadece Brainfuck benzeri sembolik bir dil değil; **tape, data, stack, adresleme modu, bayrak sistemi, meta servisler ve x64 NASM çıktı üreten küçük bir operator-machine compiler** olarak tasarlanmalıdır.

Burada temel karar şudur: Çekirdeğe yüksek seviyeli komutlar doldurulmayacak. Yani dile doğrudan `SIN`, `SORT`, `PRINTNUM`, `INPUTNUM`, `FUNCTION`, `LABEL`, `FOR`, `IF THEN ELSE` gibi kelimeler eklenmeyecek. Bunun yerine 6502 mantığına benzeyen ama x64 hedefli çalışan şu omurga kurulacak:

```text
1. Küçük sembolik çekirdek
2. Güçlü adresleme modları
3. Bayrak sistemi
4. Koşullu/koşulsuz relative branch
5. Sabit/dinamik meta komut sistemi
6. Runtime fonksiyonlarına bağlanan meta ABI
7. Safe/Normal/Wild çalışma modu
8. IDE için adım adım çalıştırılabilir interpreter/AST ara katmanı
```

Bu karar önemlidir. Çünkü dil büyüdükçe okunabilirliği artabilir ama kendi karakterini kaybedebilir. UX-MINIMA’nın karakteri, programcıyı bellek, pointer, stack, flag ve akış kontrolüyle yüz yüze bırakmasıdır. Bu yüzden “fonksiyon yazalım” yerine “meta servisle çağrı yapalım”, “label yazalım” yerine “relative branch yapalım”, “değişken yazalım” yerine “adresleme modu kullanalım” daha doğru yoldur.

## 2. Çekirdek komut ailesi korunacak ama V3.1’de bazı işaretler resmileşecek

V3 tasarımında 26 komut vardı:

```text
1  >     sağa git
2  <     sola git
3  +     artır
4  -     azalt
5  0     sıfırla
6  .     karakter bas
7  ,     karakter oku
8  [     döngü/koşul başı
9  ]     döngü/koşul sonu
10 $     push
11 %     pop
12 ?     eşit mi
13 !     büyük mü
14 ;     küçük mü
15 &     AND
16 |     OR
17 ^     XOR
18 ~     NOT
19 @     meta/runtime çağrı
20 sN    string tanımla
21 pN    string bas
22 kN    tekrar makrosu
23 #     yorum
24 :     branch/jump prefix
25 {     SHL / sola kaydır / ikiyle çarp
26 }     SHR / sağa kaydır / ikiye böl
```

V3.1’de bunlara ek olarak **hata/status byte sorgusu için `e` komutu** resmileştirilebilir.

```text
27 e     error/status byte oku
```

`e` komutu aktif hücreye runtime/compiler status byte değerini yazar. Böylece program kendi durumunu sorgulayabilir.

Örnek:

```text
e.
```

Bu örnek doğrudan karakter basmaya çalışır; status değeri görünür ASCII olmayabilir. Daha doğru kullanım, `e` sonrası decimal print meta servisi ile olur:

```text
e@60
```

Burada `e` aktif hücreye hata/status kodunu koyar, `@60` bu sayıyı decimal olarak yazdırır.

## 3. Hata/status byte sistemi

V3.1’de mutlaka ayrı bir **status byte** veya **error byte** olmalıdır. Bu byte runtime durumunu gösterir. Program bunu `e` komutuyla veya meta servisle sorgulayabilir.

Önerilen temel kural:

```text
status = 0 ise her şey normal
status != 0 ise hata, uyarı veya özel çalışma durumu vardır
```

Bu status byte 0–255 arası değer tutar. Böylece 256 adet hata, uyarı veya çalışma kodu tanımlanabilir.

İlk hata/status tablosu şöyle olmalıdır:

```text
0   OK / sorun yok / çalışıyor
1   Genel uyarı
2   Genel hata
3   Geçersiz komut
4   Geçersiz pattern
5   Geçersiz meta id
6   Geçersiz branch hedefi
7   Geçersiz adresleme modu
8   Geçersiz bellek alanı
9   Geçersiz hücre tipi
10  Pointer tape sınırı dışına çıktı
11  Stack overflow
12  Stack underflow
13  Arithmetic overflow
14  Arithmetic underflow
15  Division by zero
16  Data bounds error
17  Tape bounds error
18  Stack bounds error
19  String bounds error
20  Invalid memory layout
21  Invalid endian mode
22  Invalid signed/unsigned mode
23  Invalid safe/wild operation
24  Meta servis argüman hatası
25  Meta servis sonuç yazma hatası
26  EOF görüldü
27  Input bekleme durumu
28  Pattern eşleşme hatası
29  Runtime ABI uyumsuzluğu
30  x64 codegen internal error
31  NASM output warning
32  Reserved
33-63  Compiler ve runtime genel hata alanı
64-127 Kullanıcı programı hata/status alanı
128-191 Wild mode / deneysel hata alanı
192-255 IDE/debugger/simülasyon status alanı
```

Bu tablo sabit olmalıdır. Çünkü IDE, compiler, runtime ve kullanıcı programı aynı hata kodlarını bilmelidir.

## 4. `e` komutunun davranışı

`e` komutu basit ve net olmalıdır:

```text
e = status byte değerini aktif hücreye yaz
```

Örnek:

```text
e@60
```

Anlam:

```text
status byte değerini aktif hücreye al
decimal sayı olarak yazdır
```

`e` komutu status değerini okur ama status değerini sıfırlamaz. Status sıfırlamak için meta servis kullanılmalıdır.

Önerilen meta servisler:

```text
@9   status byte oku
@10  status byte sıfırla
@11  status byte set et
@12  son hata mesajını yazdır
```

Davranış:

```text
@9:
    output = status

@10:
    status = 0

@11:
    status = arg1 veya current

@12:
    status koduna göre açıklama yazdır
```

Böylece hem `e` kısa komutuyla hızlı okuma yapılır hem de meta komutlarla status yönetilir.

## 5. Bayrak sistemi neden gerekli?

6502’de `N`, `V`, `B`, `D`, `I`, `Z`, `C` gibi işlemci bayrakları vardı. UX-MINIMA’da da programın davranışını etkileyen bayraklar olmalıdır. Çünkü signed/unsigned, endian, carry, overflow, compare sonucu, safe/wild gibi durumların tamamını sadece komutlarla yönetmek karmaşık olur.

V3.1’de bir **flag word** veya en azından birden fazla flag byte tutulmalıdır. Basit sürümde tek `FLAGS` word yeterlidir. Daha gelişmiş sürümde ayrı register benzeri alanlar kullanılabilir.

Önerilen flag yapısı:

```text
FLAGS bitleri:
bit 0  Z  zero flag
bit 1  C  carry flag
bit 2  O  overflow flag
bit 3  S  sign flag
bit 4  U  unsigned mode
bit 5  M  signed mode
bit 6  E  endian flag, 0=little, 1=big
bit 7  W  wild mode active
bit 8  B  bounds check active
bit 9  T  trace/debug active
bit 10 F  FIFO stack mode
bit 11 L  LIFO stack mode
bit 12 R  runtime error present
bit 13 D  data dirty/modified
bit 14 P  pointer changed by meta
bit 15 X  reserved/experimental
```

Burada bazı bayraklar aynı anda açık olmamalıdır. Örneğin signed ve unsigned aynı anda aktif olmamalı. FIFO ve LIFO aynı anda aktif olmamalı. Bu tür durumlarda runtime status byte hata kodu üretmelidir.

## 6. Signed / unsigned konusu

Senin önerin doğru: signed/unsigned durumu compiler genelinde bir bayrakla yönetilmeli ama kullanıcı gerektiğinde değiştirebilmelidir.

Varsayılan öneri:

```text
Default compare mode = unsigned
```

Çünkü byte/word/dword hücrelerde doğal davranış unsigned gibidir.

Ama kullanıcı signed karşılaştırma istiyorsa bayrağı değiştirebilmelidir.

Önerilen meta servisler:

```text
@120  unsigned mode set
@121  signed mode set
@122  compare mode sorgula
```

Davranış:

```text
@120:
    FLAGS.U = 1
    FLAGS.M = 0

@121:
    FLAGS.M = 1
    FLAGS.U = 0

@122:
    current = 0 ise unsigned
    current = 1 ise signed
```

Bu durumda `!` ve `;` komutlarının davranışı aktif compare mode’a göre değişir.

Unsigned modda:

```text
! = stackTop > current unsigned
; = stackTop < current unsigned
```

Signed modda:

```text
! = stackTop > current signed
; = stackTop < current signed
```

Bu çok önemlidir. Örneğin byte hücrede 255 değeri unsigned olarak 255’tir, signed olarak -1 gibi yorumlanabilir. Kullanıcı hangi anlamı istediğini bayrakla belirlemelidir.

## 7. İşlem bazında signed/unsigned seçimi

Genel bayrak yetmez; bazı işlemlerde kullanıcı işlem öncesi signed/unsigned modunu geçici olarak seçmek isteyebilir.

Bunun için iki yol olabilir.

Birinci yol: kalıcı mod.

```text
@120
# bundan sonraki compare unsigned
```

İkinci yol: tek işlem için meta compare.

Önerilen meta servisler:

```text
@130  unsigned equal compare
@131  unsigned greater compare
@132  unsigned less compare
@133  signed equal compare
@134  signed greater compare
@135  signed less compare
```

Böylece kullanıcı bayrak modunu değiştirmeden tek seferlik karşılaştırma yapabilir.

Örnek meta frame:

```text
(T-2) = arg1
(T-1) = arg2
(T)   = meta id
(T+1) = result
```

Signed greater için:

```text
0(T-2)+k255
0(T-1)+k1
0(T)+k134
@#
```

Bu, signed yorumda -1 > 1 mi diye bakar. Sonuç 0 olur. Unsigned yorumda 255 > 1 doğru olurdu.

## 8. Carry ve overflow bayrakları

Carry ve overflow mutlaka olmalıdır. Çünkü byte/word/dword aritmetiğinde taşma çok önemlidir.

Carry flag `C`, unsigned taşma veya borrow durumunu gösterebilir.

Overflow flag `O`, signed taşma durumunu gösterebilir.

Örnek byte unsigned toplama:

```text
250 + 10 = 260
```

Byte hücrede sonuç wrap modunda:

```text
260 mod 256 = 4
```

Bu durumda:

```text
result = 4
C flag = 1
O flag = signed yoruma göre hesaplanır
```

Check modda ise:

```text
status = arithmetic overflow
C flag = 1
O flag = uygun şekilde set
```

Önerilen meta servisler:

```text
@140  carry flag oku
@141  carry flag set
@142  carry flag reset
@143  overflow flag oku
@144  overflow flag set
@145  overflow flag reset
@146  zero flag oku
@147  sign flag oku
@148  tüm aritmetik flagleri sıfırla
```

Böylece program, işlemden sonra bayrakları sorgulayabilir.

## 9. Zero ve sign flag

Karşılaştırma ve aritmetik işlemlerden sonra otomatik flag güncellemesi yapılmalıdır.

Önerilen kural:

```text
Her aritmetik işlemden sonra:
    Z = result == 0
    S = signed yorumda result negatif mi?
    C = unsigned carry/borrow
    O = signed overflow
```

Her karşılaştırmadan sonra:

```text
Z = arg1 == arg2
C = unsigned arg1 < arg2 durumunda borrow gibi düşünülebilir
S = signed karşılaştırma sonucuna göre set edilebilir
O = signed compare overflow durumuna göre
```

Fakat burada dikkatli olmak gerekir: Çok karmaşık CPU taklidi yapmak zorunda değiliz. Ama temel bayraklar kararlı davranmalıdır.

## 10. Endian bayrağı

Endian da senin dediğin gibi bayrak olmalıdır. Kullanıcı endian modunu seçebilmeli, sorgulayabilmeli ve meta komutlarla değiştirebilmelidir.

Varsayılan öneri:

```text
Default endian = little-endian
```

Çünkü x64 doğal olarak little-endian’dır.

Önerilen meta servisler:

```text
@150  little-endian mode set
@151  big-endian mode set
@152  endian mode sorgula
```

Davranış:

```text
@150:
    FLAGS.E = 0

@151:
    FLAGS.E = 1

@152:
    current = 0 ise little-endian
    current = 1 ise big-endian
```

Endian bayrağı özellikle şu işlemleri etkiler:

```text
1. word değerini iki byte’a ayırma
2. iki byte’tan word kurma
3. dword değerini dört byte’a ayırma
4. dört byte’tan dword kurma
5. data alanından binary sayı okuma
6. data alanına binary sayı yazma
7. string/binary karışık yorumlama
```

## 11. Word ve dword parçalama endian’a bağlı olmalı

Byte modelinde word saklama:

Little-endian:

```text
word = 0x1234
byte0 = 0x34
byte1 = 0x12
```

Big-endian:

```text
word = 0x1234
byte0 = 0x12
byte1 = 0x34
```

Dword için:

Little-endian:

```text
dword = 0x12345678
byte0 = 0x78
byte1 = 0x56
byte2 = 0x34
byte3 = 0x12
```

Big-endian:

```text
dword = 0x12345678
byte0 = 0x12
byte1 = 0x34
byte2 = 0x56
byte3 = 0x78
```

Bu dönüşümler meta servislerle yapılmalıdır.

Önerilen meta servisler:

```text
@153  word -> two bytes
@154  two bytes -> word
@155  dword -> four bytes
@156  four bytes -> dword
```

Bu servisler endian bayrağına göre davranır.

## 12. Input davranışı

`,` komutu net olarak şöyle davranmalı:

```text
, = karakter okur
giriş yoksa bekler
EOF olursa aktif hücreye 0 yazar
EOF durumunda status = 26
```

Bu çok doğru bir tasarımdır.

Önerilen davranış:

```text
Klavye/console input:
    karakter gelene kadar bekle
    karakter geldiyse current = ASCII/byte value
    status = 0

Dosya/stream input:
    karakter varsa current = byte
    EOF varsa current = 0
    status = 26
```

IDE modunda input kuyruğu boşsa:

```text
status = 27
```

ama program duracak mı, bekleyecek mi, step modunda IDE’ye mi dönecek; bu IDE/interpreter katmanında belirlenmelidir.

## 13. Pattern sistemi 256 mı 512 mi olmalı?

Bence iki seviye olsun.

```text
SAFE compiler pattern bank = 256 pattern
EXTENDED optimizer pattern bank = 512 pattern
```

Sebep şu: 256 pattern, kontrol edilebilir ve 6502 tarzı data-driven tablo için güzel bir sınırdır. Ama x64 tarafında daha fazla optimizasyon gerekirse 512 pattern daha rahat olur.

Önerilen karar:

```text
V3.1 minimum zorunlu pattern bankası = 256
V3.1 extended optimizer = 512
```

Kurallar sert olmalı:

```text
1. En uzun pattern önce gelir.
2. Uzunluk eşitse daha spesifik pattern önce gelir.
3. Döngü içeren pattern, düz tekrarlı patternden önceliklidir.
4. Stack kullanan pattern, basit patternlerden önceliklidir.
5. Meta/branch patternleri özel sınıfa alınır.
6. Aynı uzunluk ve aynı öncelikte DATA tablosunda önce gelen kazanır.
7. Pattern eşleşmesi deterministik olmak zorundadır.
8. Pattern hiçbir zaman string/data direktifinin içine giremez.
9. Pattern loop dengesini bozamaz.
10. Pattern branch hedefini parçalayamaz.
```

Bu kurallar compiler davranışını kararlı yapar.

## 14. Pattern sınıfları

Patternler tek bir karma tablo gibi değil, sınıflara ayrılmalıdır.

Önerilen pattern sınıfları:

```text
P0  no-op ve sadeleştirme patternleri
P1  tekrar aritmetiği patternleri
P2  pointer hareket patternleri
P3  clear/set patternleri
P4  taşıma/kopyalama patternleri
P5  stack patternleri
P6  compare patternleri
P7  bitwise/shift patternleri
P8  loop patternleri
P9  meta patternleri
P10 branch patternleri
P11 addressing patternleri
P12 string/data patternleri
```

Bu sınıflama hem compiler hem IDE için faydalıdır. IDE kullanıcıya “bu kod şu patternle optimize edildi” diye gösterebilir.

## 15. Test seti şart

Bu program yazıldıktan sonra conformance test paketi oluşturulmalı. Bu konu kesinlikle sonraya bırakılabilir ama unutulmamalıdır.

Testler şu gruplarda olmalı:

```text
1. Temel komut testleri
2. Pointer testleri
3. Stack testleri
4. Compare testleri
5. Signed/unsigned testleri
6. Carry/overflow testleri
7. Endian testleri
8. Data/string testleri
9. Meta servis testleri
10. Branch testleri
11. Addressing mode testleri
12. Pattern optimizer testleri
13. Safe mode hata testleri
14. Wild mode davranış testleri
15. IDE/interpreter step testleri
```

Örnek test adı:

```text
test_001_print_A.uxm
test_020_stack_lifo.uxm
test_040_unsigned_gt.uxm
test_041_signed_gt.uxm
test_060_carry_add_byte.uxm
test_080_little_endian_word.uxm
test_081_big_endian_word.uxm
test_100_meta_add.uxm
test_120_branch_forward.uxm
test_140_address_T_plus_1.uxm
```

Bu testler olmadan V3.1 büyüdükçe bozulur.

## 16. Safe/Normal/Wild mode

Bu konuda karar net olmalı. Çalışma modu program içinde runtime’da değiştirilmemeli. Çünkü güvenlik ve compiler varsayımları bozulur.

Çalışma modu pragma/comment ile program başında ayarlanmalı.

Öneri:

```text
#mode safe
#mode normal
#mode wild
```

Eğer hiç mod yazılmazsa ne olsun?

Senin önerine uygun iki olasılık var:

```text
1. Yazılmazsa normal mode
2. Yazılmazsa wild mode
```

Ben güvenlik açısından default’u `normal` yapardım. Ama sen “önceden yazarsan normal, yazmazsan wild olabilir” dedin. Bu retro/deneysel ruh açısından ilginç ama yeni kullanıcıyı tehlikeye atar. Bu yüzden şu uzlaşma daha iyi olabilir:

```text
Compiler default = normal
IDE experimental profile default = wild olabilir
```

Modlar:

```text
SAFE:
    bounds check zorunlu
    stack check zorunlu
    invalid meta id engellenir
    indirect adresleme kapalı
    runtime layout değişimi kapalı
    branch hedef kontrolü açık

NORMAL:
    bounds check seçimlik
    stack check açık
    meta id kontrolü açık
    temel adresleme açık
    layout runtime’da değişmez

WILD:
    indirect adresleme açık
    layout değişimi açık
    tape/data/stack yeniden konumlanabilir
    bazı branch kontrolleri gevşetilebilir
    tüm sorumluluk kullanıcıda
```

## 17. İkinci stack / FIFO fikri

Bu fikir ilginç. Normal stack LIFO’dur:

```text
son giren ilk çıkar
```

FIFO ise kuyruktur:

```text
ilk giren ilk çıkar
```

İkinci bir alan şu şekilde düşünülebilir:

```text
Stack A = LIFO stack
Stack B = FIFO queue
```

Bu ne sağlar?

```text
1. Girdi kuyruğu
2. Olay kuyruğu
3. IDE step event buffer
4. Mesaj kuyruğu
5. Basit producer/consumer modeli
6. BFF/wild mode’da etkileşim kuyruğu
```

Bunu endian gibi bayrakla değiştirmek de mümkün:

```text
FLAGS.F = FIFO mode
FLAGS.L = LIFO mode
```

Ama aynı `$` ve `%` komutlarının davranışını modla değiştirmek kafa karıştırabilir.

Öneri:

```text
$ ve % her zaman LIFO stack için kalsın.
FIFO için meta servisler kullanılsın.
```

Meta servis önerileri:

```text
@160  FIFO push
@161  FIFO pop
@162  FIFO peek
@163  FIFO count
@164  FIFO clear
```

Eğer illa aynı komutlarla mod değiştireceksek:

```text
@165  stack mode LIFO
@166  stack mode FIFO
@167  stack mode sorgula
```

Ama bu daha tehlikeli. Çünkü aynı kaynak kod farklı modda farklı davranır. Ben LIFO komutları sabit tutup FIFO’yu meta servisle vermeyi daha doğru buluyorum.

## 18. IDE/interpreter ara katmanı olmazsa olmaz

Bu dilin IDE’ye bağlanması için compiler’ın yanında bir de **adım adım çalıştırılabilir interpreter/AST yürütme katmanı** gerekir. Bu doğru tespit.

Çünkü IDE şunları canlı göstermeli:

```text
1. Pointer nerede?
2. Aktif hücre değeri ne?
3. Tape bölgesi nasıl değişti?
4. Stack’te ne var?
5. FIFO varsa kuyrukta ne var?
6. Data alanı nasıl görünüyor?
7. FLAGS değeri ne?
8. Status byte ne?
9. Carry/overflow/zero/sign bayrakları ne?
10. Hangi pattern eşleşti?
11. Hangi branch hedefe gitti?
12. Hangi meta servis çağrıldı?
13. Hangi ASM satırı üretildi?
```

Bunun için compiler iki modda çalışmalı:

```text
1. Compile mode:
    .uxm -> token -> pattern -> x64 NASM

2. Trace/interpreter mode:
    .uxm -> token/AST -> step execution -> JSON trace
```

Trace çıktı formatı JSON olabilir.

Örnek JSON satırı:

```json
{"step":12,"token":"+","ptr":0,"cell":66,"flags":0,"status":0,"stack_depth":0,"event":"inc current cell"}
```

Daha geniş:

```json
{"step":40,"token":"@#","ptr":3,"meta_id":22,"arg1":6,"arg2":7,"result":42,"result_cell":4,"flags":{"Z":0,"C":0,"O":0,"S":0},"status":0}
```

Bu dosya IDE tarafından okunur ve canlı gösterilir. Böylece compiler sadece kod üretici değil, aynı zamanda IDE’ye veri sağlayan bir analiz motoru olur.

## 19. AST mi token yürütme mi?

UX-MINIMA gibi sembolik dilde tam AST şart değildir ama faydalıdır.

Üç katman olabilir:

```text
1. Raw source
2. Token stream
3. Annotated token stream / mini AST
```

Mini AST şunları tutar:

```text
token
source_position
expanded_from_macro
pattern_group
branch_target
addressing_mode
meta_call_info
```

Bu, klasik ağaçtan çok “annotated instruction stream” gibi olur. IDE için yeterlidir.

Bence buna AST demektense **UIR — UXM Intermediate Representation** demek daha doğru olabilir.

```text
UXM source -> Lexer -> UIR -> Interpreter trace
UXM source -> Lexer -> UIR -> Pattern optimizer -> x64 ASM
```

## 20. Bölüm 1 sonucu

Bu ilk bölümde V3.1’in kritik altyapısını netleştirdik:

```text
1. e komutu status byte okumak için eklendi.
2. 0..255 arası hata/status kod alanı tanımlandı.
3. Signed/unsigned konusu FLAGS ile yönetilecek.
4. Carry, overflow, zero, sign bayrakları olacak.
5. Endian bir bayrak olacak ve meta servislerle set/reset/sorgu yapılacak.
6. Input davranışı netleşti: karakter okur, yoksa bekler, EOF olursa 0 yazar.
7. Pattern bankası 256 zorunlu, 512 extended olabilir.
8. Pattern öncelik kuralları sertleştirildi.
9. Test seti zorunlu kabul edildi.
10. Safe/Normal/Wild mode ayrımı yapıldı.
11. Runtime’da mod değiştirme olmayacak; mod pragma ile program başında belirlenecek.
12. İkinci stack/FIFO fikri meta servislerle desteklenebilir.
13. IDE için interpreter/trace/JSON ara katmanı şart kabul edildi.
```

Bundan sonraki bölümde V3.1’in **adresleme modlarını** ayrıntılı ve kesin sözdizimiyle yazmak gerekir. Orada `()` parantezini kullanacağız. `[]` sadece döngü olarak kalacak. Tape, data, stack, pointer, stack top, indirect, relative, absolute, frame ve meta-frame adreslemelerini tek tek tanımlayacağız.

**Devam yazarsan Bölüm 2’de adresleme modlarını tam belge olarak yazacağım.**



# UX-MINIMA x64 V3.1 Tasarım Belgesi

## Bölüm 2 — Adresleme Modları, Tape/Data/Stack Erişimi ve 6502 Mantığının x64’e Taşınması

## 21. Adresleme neden V3.1’in kalbidir?

UX-MINIMA’nın ilk halinde programcı tape üzerinde `>` ve `<` ile gezer, aktif hücre üzerinde `+`, `-`, `0`, `.`, `,`, `[`, `]` gibi komutları çalıştırır. Bu öğretici ve sade bir modeldir. Fakat program biraz büyüdüğünde sürekli pointer’ı ileri geri taşımak yorucu olur. 6502’de işimizi kolaylaştıran şeylerden biri adresleme modlarıydı. Aynı komut farklı adresleme biçimleriyle çok daha güçlü hale gelirdi.

UX-MINIMA x64 V3.1’de de aynı mantık kurulmalıdır. Çekirdek komutları büyütmeden, komutların işlem yapacağı bellek yerini daha esnek seçebilmeliyiz.

Örneğin mevcut V3’te:

```text id="xqsm01"
+
```

aktif hücreyi artırır.

V3.1’de ise şu da mümkün olmalıdır:

```text id="vjqa3w"
+(T+1)
```

Bu, pointer’ı oynatmadan pointer’ın bir sağındaki hücreyi artırır.

Bu çok büyük fark yaratır. Çünkü artık her işlem için pointer’ı fiziksel olarak taşıman gerekmez. Komut aynı kalır, adresleme modu değişir. 6502’nin gücü de buydu; `LDA #10`, `LDA $20`, `LDA $2000`, `LDA ($20),Y` gibi aynı yükleme mantığı farklı adresleme biçimleriyle farklı işler yapardı.

---

## 22. Sembol ayrımı

V3.1’de semboller kesin ayrılmalıdır:

```text id="sn4diw"
[ ] = döngü / koşul bloğu
( ) = adresleme ifadesi
{ } = shift left / shift right komutları
:   = branch / jump prefix
@   = meta servis çağrısı
#   = yorum
```

Bu nedenle adresleme için `[]` kullanılmayacak. Çünkü `[]` zaten döngü anlamında kullanılıyor. Adresleme için `()` parantezleri kullanılacak.

Bu karar dili daha okunabilir yapar:

```text id="lzt2rp"
[ ... ]      döngü
+(T+1)       pointer+1 hücresini artır
.(D:0)       data[0] karakterini bas
:+20         koşullu branch
@60          meta servis çağrısı
```

---

## 23. Adresleme komuttan sonra gelir

V3.1’de adresleme ifadesi komuttan sonra gelir.

Örnekler:

```text id="f52f8p"
+(T+1)
-(T-1)
0(T:100)
.(D:0)
$(T+2)
%(T+3)
~(T)
{(T+1)
}(T-1)
```

Komutun arkasında adresleme yoksa varsayılan adresleme aktif tape hücresidir.

Yani:

```text id="4e2mdg"
+
```

şunun kısa yazımıdır:

```text id="vs9xtu"
+(T)
```

Aynı şekilde:

```text id="6b4rae"
.
```

şunun kısa yazımıdır:

```text id="k6j8h6"
.(T)
```

Bu sayede eski V3 kodları bozulmaz. V3.1 adresleme sistemi geriye uyumlu olur.

---

## 24. Temel adresleme alanları

V3.1’de dört ana alan vardır:

```text id="qywqw3"
T = tape alanı
D = data alanı
S = stack alanı
P = pointer değeri
```

Ek olarak:

```text id="vylq9h"
SP = stack top / stack pointer
E  = error/status byte
F  = flags word
```

Bunlar adresleme ifadesinde kullanılabilir veya meta servislerle sorgulanabilir.

---

## 25. Varsayılan aktif tape adresleme: `(T)`

```text id="kqlb07"
(T)
```

aktif tape hücresidir.

Şu komutlar eşdeğerdir:

```text id="6q7m3k"
+
+(T)
```

İkisi de aktif hücreyi artırır.

Byte hücrede x64 karşılığı:

```asm id="n8ikjx"
inc byte [r12 + rbx]
```

Word hücrede:

```asm id="yeeu6w"
inc word [r12 + rbx*2]
```

Dword hücrede:

```asm id="thlf91"
inc dword [r12 + rbx*4]
```

Burada V3.1 register disiplini şöyle kabul edilir:

```text id="asfdrr"
r12 = ux_mem veya tape base
rbx = tape pointer
r13 = stack base
r14 = stack pointer
r15 = geçici register
rax = işlem registerı
```

---

## 26. Pointer göreli tape adresleme: `(T+N)` ve `(T-N)`

```text id="en81mn"
(T+N)
(T-N)
```

pointer’a göre göreli hücre erişimidir.

Örnek:

```text id="dk7eh7"
+(T+1)
```

anlamı:

```text id="hhkx6f"
pointer’ın bir sağındaki hücreyi artır
pointer yerinde kalsın
```

Örnek:

```text id="2jys2o"
0(T-2)
```

anlamı:

```text id="g0pgwj"
pointer’ın iki solundaki hücreyi sıfırla
pointer yerinde kalsın
```

Bu mod, 6502’deki indexed veya relative bellek erişimi mantığına benzer. Çok kullanışlıdır çünkü kısa işlemler için pointer’ı ileri geri taşımaya gerek kalmaz.

Örneğin eski yöntem:

```text id="dgx5j4"
>+<
```

Yeni yöntem:

```text id="xep92n"
+(T+1)
```

İkisi aynı sonucu verebilir ama yeni yöntemde pointer hiç değişmez.

---

## 27. Mutlak tape adresleme: `(T:N)`

```text id="mu7qq1"
(T:N)
```

tape’in N numaralı mutlak hücresine erişir.

Örnek:

```text id="75xrb5"
0(T:100)
+k65(T:100)
```

anlamı:

```text id="zy5ps8"
tape[100] = 65
```

Bu, 6502’deki absolute addressing mantığına benzer. Pointer nerede olursa olsun tape’in 100. hücresine erişilir.

Bunun çok güçlü bir tarafı vardır: Bellek haritasında sabit görev verdiğin hücrelere doğrudan erişebilirsin.

Örneğin:

```text id="r16225"
# tape[0]   = ana sayaç
# tape[10]  = skor
# tape[20]  = can
# tape[100] = geçici buffer
```

Kod:

```text id="m85skt"
0(T:10)
+k5(T:20)
```

Bu skor hücresini sıfırlar, can hücresini 5 yapar.

---

## 28. Data adresleme: `(D:N)`

```text id="oz9qcn"
(D:N)
```

data alanının N numaralı hücresine erişir.

Data alanı stringler, tablolar ve sabit veriler için kullanılır. `sN` ve `pN` direktifleri data alanını kullanır ama V3.1’de ham data erişimi de olmalıdır.

Örnek:

```text id="76l5ly"
.(D:0)
```

anlamı:

```text id="6jnf7u"
data[0] hücresindeki karakteri bas
```

Örnek:

```text id="duswja"
$(D:10)
```

anlamı:

```text id="4rrip7"
data[10] değerini stack’e at
```

Bu, tablo okuma için çok önemlidir. Örneğin sinüs tablosu data alanına yerleştirilirse `(D:N)` ile okunabilir.

---

## 29. Stack adresleme: `(S:N)` ve `(SP)`

Stack normalde `$` ve `%` komutlarıyla LIFO mantığında kullanılır. Fakat gelişmiş kullanım ve IDE/debug modu için stack alanına adresleme ile erişmek yararlı olabilir.

```text id="zsz7s2"
(S:N) = stack alanının N numaralı hücresi
(SP)  = stack top
```

Örnek:

```text id="t6yzma"
.(S:0)
```

stack alanının ilk hücresini karakter olarak basar.

Fakat bu tehlikeli bir moddur. Çünkü stack’in doğrudan kurcalanması LIFO disiplinini bozabilir.

Bu yüzden öneri:

```text id="ydbnxq"
SAFE mode:
    (S:N) yazma kapalı olabilir
    (SP) sadece okuma olabilir

NORMAL mode:
    (SP) okuma/yazma kontrollü
    (S:N) debugger için okunabilir

WILD mode:
    (S:N), (SP) serbest
```

Yani stack adreslemesi V3.1’de tanımlanmalı ama güvenlik moduna göre sınırlandırılmalıdır.

---

## 30. Pointer adresleme: `(P)`

```text id="h7a7h9"
(P)
```

pointer’ın kendisini değer olarak temsil eder.

Örnek düşünce:

```text id="i2e6gc"
%(P)
```

stack’ten pop edip pointer’a yazmak anlamına gelebilir. Ama bu çok tehlikelidir. Çünkü yanlış değer pointer’ı tape dışına çıkarabilir.

Daha güvenli çözüm meta servislerdir:

```text id="b0twj7"
@80 = pointer set
@81 = pointer add
@82 = pointer oku
```

Yine de adresleme belgelerinde `(P)` tanımlanmalıdır. Fakat kullanımı mode’a bağlı olmalıdır.

Öneri:

```text id="0w1b6l"
SAFE mode:
    (P) yazılamaz, sadece @82 ile okunur

NORMAL mode:
    @80/@81 ile kontrollü değişir

WILD mode:
    (P) doğrudan yazılabilir
```

Bu, güçlü ama tehlikeli bir özelliktir.

---

## 31. Error/status adresleme: `(E)`

V3.1’de `e` komutu status byte’ı aktif hücreye alır. Ama adresleme düzeyinde `(E)` pseudo-address de tanımlanabilir.

```text id="8011fh"
(E) = error/status byte
```

Örnek:

```text id="cvajnd"
$(E)
```

status byte’ı stack’e atar.

Örnek:

```text id="u1issd"
0(E)
```

status byte’ı sıfırlar.

Fakat status byte doğrudan yazılırsa hata yönetimi bozulabilir. Bu yüzden öneri:

```text id="cv8acm"
SAFE mode:
    (E) sadece okunabilir

NORMAL mode:
    @10 ile sıfırlanabilir, @11 ile set edilebilir

WILD mode:
    0(E) gibi doğrudan yazım serbest olabilir
```

---

## 32. Flags adresleme: `(F)`

```text id="wcwkbf"
(F) = flags word
```

Bu, signed/unsigned, carry, overflow, endian, zero, sign, trace, wild gibi bayrakları taşır.

Örnek:

```text id="agq0n9"
$(F)
```

flags değerini stack’e atar.

Örnek:

```text id="u3s2nr"
.(F)
```

flags düşük byte’ını karakter olarak basmaya çalışır, genelde anlamlı değildir.

Flags için doğrudan yazma dikkatli olmalıdır. Çünkü yanlış flags değeri signed/unsigned, endian ve stack mode gibi davranışları bozabilir.

Daha güvenli kullanım meta servislerle olmalıdır:

```text id="ozjvc7"
@120 unsigned mode set
@121 signed mode set
@140 carry flag oku
@143 overflow flag oku
@150 little-endian set
@151 big-endian set
```

`(F)` daha çok IDE/debugger ve wild mode için düşünülmelidir.

---

## 33. Indirect tape adresleme: `(*T)`

```text id="4mjbce"
(*T)
```

aktif hücredeki değeri tape adresi kabul eder ve o adresteki hücreye erişir.

Örnek durum:

```text id="yelm2v"
pointer = 0
tape[0] = 100
```

Kod:

```text id="p3o6bd"
+(*T)
```

anlamı:

```text id="9zke8t"
tape[100] değerini artır
```

Bu 6502 indirect addressing mantığına benzer. Çok güçlüdür. Ama aynı zamanda çok tehlikelidir. Çünkü aktif hücrede 999999 gibi bir değer varsa pointer sınır dışına çıkabilir.

Bu yüzden:

```text id="zd2uo6"
SAFE mode:
    indirect kapalı

NORMAL mode:
    indirect sadece bounds check açıkken izinli

WILD mode:
    indirect serbest
```

Indirect adresleme, BFF benzeri deneylere ve self-referential modellerine yaklaşmak için önemlidir.

---

## 34. Relative indirect adresleme: `(*(T+N))`

```text id="z9dcb2"
(*(T+N))
(*(T-N))
```

pointer’a göre N uzaklıktaki hücrede bir adres vardır; o adres tape adresi olarak kullanılır.

Örnek:

```text id="p6vmxd"
(*(T+1))
```

anlamı:

```text id="ryrlzv"
tape[pointer+1] içindeki değeri adres kabul et
o tape adresine eriş
```

Bu, pointer tabloları ve lookup yapıları için çok güçlüdür.

Örnek kullanım fikri:

```text id="refy14"
# tape[p+1] = 200
# +(*(T+1)) => tape[200] artırılır
```

Bu mod, V3.1’in ileri adresleme katmanıdır. Normal programcı için zor olabilir ama compiler/IDE desteklerse çok güçlü olur.

---

## 35. Data indirect adresleme: `(*D:N)` ve `(*(D:N))`

Data alanında adres tablosu tutulabilir. Örneğin data[10] içinde 200 değeri varsa:

```text id="e8v8zt"
(*(D:10))
```

bu değeri tape adresi veya data adresi olarak yorumlayabilir. Burada belirsizlik doğar: Data’daki adres tape adresi mi, data adresi mi?

Bu yüzden iki ayrı biçim daha iyi olur:

```text id="w6a77q"
(*T:D:N) = data[N] içindeki değeri tape adresi kabul et
(*D:D:N) = data[N] içindeki değeri data adresi kabul et
```

Ama bu sözdizimi fazla ağırlaşır. Bu yüzden V3.1 için şimdilik data indirect’i ileri/wild özellik olarak bırakmak daha iyi olur.

Temel V3.1’de şu yeterli:

```text id="fmkpsu"
(D:N) = data mutlak erişim
```

Indirect data erişimi V3.1 belgesinde tanımlanabilir ama SAFE modda kapalı tutulabilir.

---

## 36. Immediate / sabit değer mantığı

6502’de immediate adresleme `#10` gibi yazılırdı. UX-MINIMA’da `#` yorum olduğu için immediate için kullanılmamalıdır.

UX-MINIMA’da sabit değer zaten birkaç yolla veriliyor:

```text id="ulnmpv"
+kN = aktif hücreyi N artır
-kN = aktif hücreyi N azalt
@N  = N numaralı meta servisi çağır
(T:N) = mutlak adres
```

Adresleme ile birlikte şöyle bir yazım düşünülebilir:

```text id="fswmhn"
+k65(T:100)
```

anlamı:

```text id="l7rqr2"
tape[100] += 65
```

Bu güzel ve doğal olur.

Aynı şekilde:

```text id="wfjj6d"
-k5(T+2)
```

anlamı:

```text id="l5ks1l"
tape[pointer+2] -= 5
```

Böylece `kN` repeat macro aynı zamanda immediate miktar gibi çalışır. Compiler bunu tokena açmadan optimize edebilir.

---

## 37. Komutların adresleme ile davranış tablosu

Aşağıdaki tablo V3.1 için temel olmalıdır.

```text id="u0ioif"
Komut      Adresleme alır mı?        Anlam
+          evet                      hedef hücreyi 1 artır
-          evet                      hedef hücreyi 1 azalt
0          evet                      hedef hücreyi sıfırla
.          evet                      hedef hücreyi karakter olarak bas
,          evet                      input karakterini hedef hücreye yaz
$          evet                      hedef hücreyi stack'e push et
%          evet                      stack'ten pop edip hedef hücreye yaz
?          evet                      stackTop == hedef, sonucu hedefe yaz
!          evet                      stackTop > hedef, sonucu hedefe yaz
;          evet                      stackTop < hedef, sonucu hedefe yaz
&          evet                      stackTop AND hedef, sonucu hedefe yaz
|          evet                      stackTop OR hedef, sonucu hedefe yaz
^          evet                      stackTop XOR hedef, sonucu hedefe yaz
~          evet                      hedef hücreye bitwise NOT uygula
{          evet                      hedef hücreyi sola kaydır
}          evet                      hedef hücreyi sağa kaydır
e          evet/özel                 status byte oku, hedefe yaz
@          özel                      meta çağrı, frame pointer'a göre
[          tercihen hayır            aktif hücre kontrol eder
]          hayır                     loop sonu
>          hayır                     pointer sağa gider
<          hayır                     pointer sola gider
:          özel                      branch prefix
```

Önemli karar: `[ ]` adresleme almalı mı?

Bence başlangıçta hayır. Çünkü:

```text id="vw3du3"
[(T+1) ... ]
```

gibi bir yapı mümkün ama kafa karıştırır. Döngü kontrolü aktif hücre üzerinden kalsın. Eğer farklı hücreye göre döngü istenirse programcı pointer’ı oraya götürsün veya flag hücresini aktif hücreye taşısın.

V3.1’de `[ ]` sade kalmalı.

---

## 38. Karşılaştırma komutlarının adresleme davranışı

Mevcut davranış:

```text id="136qiv"
? = stackTop == current
! = stackTop > current
; = stackTop < current
```

Adreslemeli davranış:

```text id="vplp9g"
?(T+1) = stackTop == tape[p+1], sonucu tape[p+1]'e yaz
!(D:10) = stackTop > data[10], sonucu data[10]'a yaz
;(T:100) = stackTop < tape[100], sonucu tape[100]'e yaz
```

Burada sonuç hedef hücreye yazılır. Bu tutarlı ama bazen karşılaştırılan değeri bozar. Alternatif olarak sonuç her zaman aktif hücreye yazılabilirdi. Fakat o zaman adresleme hedefi “karşılaştırma operandı” mı “sonuç hedefi” mi karışır.

Daha temiz kural:

```text id="ddumc2"
Karşılaştırma sonucu hedef adresin içine yazılır.
Değeri korumak istiyorsan önce kopyala.
```

Bu UX-MINIMA’nın düşük seviye karakterine uygundur.

Meta servis compare gerekiyorsa sonuç `(T+1)` gibi frame result hücresine yazılabilir.

---

## 39. Bitwise komutlarının adresleme davranışı

Mevcut davranış:

```text id="4cfh4e"
& = stackTop AND current
| = stackTop OR current
^ = stackTop XOR current
```

Adreslemeli davranış:

```text id="ixgdtw"
&(T+1) = stackTop AND tape[p+1], sonucu tape[p+1]'e yaz
|(T:10) = stackTop OR tape[10], sonucu tape[10]'a yaz
^(D:5) = stackTop XOR data[5], sonucu data[5]'e yaz
```

Bu yapı byte maskeleri için çok güçlü olur.

Örnek:

```text id="mympi3"
# tape[100] değerinin alt nibble'ını al
0(T:0)+k15
$(T:0)
&(T:100)
```

Burada `tape[0] = 15` maske olur. Stack’e atılır. `&(T:100)` tape[100] değerini 15 ile maskeler.

---

## 40. Push/pop adresleme

Stack işlemleri adresleme ile çok güçlenir.

```text id="7q6jy5"
$(T+1)  = tape[p+1] değerini stack'e at
%(T+2)  = stack'ten pop edip tape[p+2]'ye yaz
$(D:10) = data[10] değerini stack'e at
%(T:50) = stack'ten pop edip tape[50]'ye yaz
```

Bu, hücreler arası veri taşımayı kolaylaştırır.

Örneğin:

```text id="oe53fl"
$(T:10)
%(T:20)
```

anlamı:

```text id="8pm3jv"
tape[10] değerini tape[20]'ye taşı
```

Ama dikkat: Bu kopyalama değil, stack üzerinden taşıma gibi davranır. tape[10] değeri silinmez. Stack’e değer kopyalanır, sonra hedefe yazılır.

---

## 41. Ekrana yazma adresleme

```text id="tws2e8"
.(T)
.(T+1)
.(T:100)
.(D:0)
```

Örnek:

```text id="cpxjnp"
.(D:0)
```

data[0] karakterini basar.

Bu, data tablosundan karakter karakter çıktı almak için önemlidir.

String basma için `pN` daha kolaydır. Ama ham data karakterleri için `.(D:N)` yararlıdır.

---

## 42. Input adresleme

```text id="b67cfd"
,(T)
,(T+1)
,(T:100)
```

Örnek:

```text id="ktn5fm"
,(T:50)
```

klavyeden bir karakter okur ve tape[50] hücresine yazar.

Bu, input buffer kurmak için çok yararlıdır.

Örnek 3 karakterlik input buffer:

```text id="qgzjit"
,(T:100)
,(T:101)
,(T:102)
```

Bu, kullanıcıdan üç karakter alıp tape[100..102] hücrelerine yazar.

---

## 43. `e` komutunun adresleme davranışı

```text id="a4r8oz"
e
```

status byte’ı aktif hücreye yazar.

Adreslemeli:

```text id="s8flxw"
e(T+1)
e(T:10)
```

anlamı:

```text id="ceeybt"
status byte değerini hedef hücreye yaz
```

Bu, hata durumunu program içinde saklamak için kullanışlıdır.

Örnek:

```text id="1g0nmp"
e(T:200)
```

status değerini tape[200] hücresine kaydeder.

---

## 44. Meta frame ve adresleme

V3.1 meta çağrı çerçevesi şöyle kabul edilmişti:

```text id="9pp7yw"
(T-2) = arg1
(T-1) = arg2
(T)   = meta id veya çağrı hücresi
(T+1) = result
```

Pointer değişmez.

Bu çerçeve adresleme ile çok net yazılır.

Örnek: 10 + 20 işlemi

```text id="85abb4"
0(T-2)+k10
0(T-1)+k20
@20
```

Eğer `@20` sabit meta çağrı ise:

```text id="2g4ilu"
arg1 = (T-2)
arg2 = (T-1)
result = (T+1)
```

Sonuç `(T+1)` hücresine yazılır.

Dinamik meta çağrı:

```text id="n79wxh"
0(T-2)+k10
0(T-1)+k20
0(T)+k20
@#
```

Burada `(T)` hücresindeki 20 değeri meta id olarak kullanılır.

---

## 45. `@N` ve `@#` adresleme ile nasıl çalışmalı?

`@N` doğrudan N numaralı meta servisi çağırır. Pointer nerede ise frame oraya göre kurulur.

```text id="0i360w"
@20
```

anlamı:

```text id="zpbw7t"
meta 20 çalışır
arg1 = (T-2)
arg2 = (T-1)
result = (T+1)
pointer değişmez
```

`@#` ise aktif hücredeki değeri meta id olarak kullanır.

```text id="scvumu"
@#
```

anlamı:

```text id="4mew4x"
id = (T)
meta id çalışır
arg1 = (T-2)
arg2 = (T-1)
result = (T+1)
pointer değişmez
```

Bu sistem, fonksiyon benzeri yapı sağlar ama çekirdeğe fonksiyon eklemez.

---

## 46. Adresleme ve branch ilişkisi

Branch sistemi token/komut akışını değiştirir. Adresleme ise hangi hücreye erişileceğini belirler. Bu ikisi birbirinden ayrılmalıdır.

Branch komutları:

```text id="bg4c8n"
:+N
:-N
:0+N
:0-N
::+N
::-N
```

Bunlar adresleme almaz. Branch kontrolü aktif hücreye göre yapılır.

Eğer başka bir hücreye göre branch yapmak istiyorsan, önce o hücreyi aktif hücreye taşımalısın veya stack/meta ile flag üretmelisin.

Örnek:

```text id="9cwjjd"
$(T:100)
%(T)
:+20
```

Bu, tape[100] değerini aktif hücreye getirip ona göre branch yapar.

Alternatif olarak ileride branch adreslemeli olabilir:

```text id="l9l7dj"
:+20(T:100)
```

Ama bu V3.1 için fazla karmaşık olur. Branch sade kalmalıdır.

---

## 47. Addressing mode ve pattern optimizer

Adresleme sistemi gelince pattern optimizer daha dikkatli olmalıdır.

Eski pattern:

```text id="qo6ljm"
[->+<]
```

aktif hücre ve sağ hücre arasında çalışır.

Adreslemeli patternler ise daha karmaşık olabilir:

```text id="wln5ft"
+(T+1)
-(T-1)
0(T:100)
```

Pattern optimizer şunları ayırmalıdır:

```text id="d84xn3"
1. Raw command patternleri
2. Addressed command patternleri
3. Branch patternleri
4. Meta frame patternleri
5. Stack/addressing patternleri
```

Örneğin:

```text id="mcfp1c"
>+<
```

ile:

```text id="kqnybo"
+(T+1)
```

aynı etkiyi verebilir ama pointer etkisi farklıdır.

`>+<` pointer’ı geçici olarak taşır ve geri getirir. `+(T+1)` pointer’ı hiç değiştirmez. Sonuç aynı olsa bile trace/debug açısından farklıdır.

Optimizer bu farkı korumalıdır.

---

## 48. Safe mode adresleme kuralları

Safe mode’da adresleme çok kontrollü olmalıdır.

```text id="p08yqm"
SAFE mode izin verilen:
(T)
(T+N)
(T-N)
(T:N)
(D:N)
```

Safe mode’da kapalı veya sınırlı:

```text id="vqn4w4"
(S:N) yazma kapalı
(SP) yazma kapalı
(P) doğrudan yazma kapalı
(E) doğrudan yazma kapalı
(F) doğrudan yazma kapalı
(*T) kapalı
(*(T+N)) kapalı
runtime memory layout değişimi kapalı
```

Bunun amacı yeni kullanıcıyı korumaktır.

---

## 49. Normal mode adresleme kuralları

Normal mode, V3.1’in standart çalışma modudur.

İzin verilen:

```text id="5v8jvv"
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

Kontrollü izin verilen:

```text id="vzo8cf"
(S:N) okuma
(SP) yazma sadece meta ile
indirect adresleme sadece bounds check açık ise
```

Kapalı:

```text id="u2o3p2"
runtime memory layout değişimi
self-modifying data execution
branch hedef kontrolünü kapatma
```

---

## 50. Wild mode adresleme kuralları

Wild mode deneysel moddur.

İzin verilen:

```text id="vx7ck0"
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
runtime layout değişimi
tape/data/stack swap
data alanından UXM kodu yorumlama
```

Wild mode’da hata yapmak kolaydır. Bu mod normal programlama için değil, yapay yaşam, BFF benzeri deneyler, self-modifying modeller ve ileri compiler araştırmaları içindir.

IDE wild mode’da kullanıcıya sürekli görsel uyarı vermelidir.

---

## 51. Adresleme grammar taslağı

V3.1 adresleme ifadesi şu biçimlerde tanınabilir:

```text id="9lbzzv"
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
```

Burada `N` unsigned decimal sayı olabilir.

İleride hexadecimal destek istenirse:

```text id="o5jdds"
(T:$10)
(D:$FF)
```

gibi bir yazım düşünülebilir. Fakat `$` zaten push komutu olduğu için dikkatli olmak gerekir. Hex için daha güvenli yazım:

```text id="8q34on"
(T:0x10)
(D:0xFF)
```

Ama V3.1 ilk sürümde decimal yeterlidir.

---

## 52. Addressing parser kuralları

Adresleme komuttan hemen sonra gelmelidir.

Geçerli:

```text id="6x4v4h"
+(T+1)
0(T:100)
.(D:0)
$(T-2)
```

Geçersiz veya önerilmeyen:

```text id="oqmu5m"
+ (T+1)
0 (T:100)
. (D:0)
```

Boşluk izinli olsun mu?

Bence compiler toleranslı olabilir ama kaynak kod standardı boşluksuz olmalıdır. Yani parser isterse boşluğu kabul eder ama formatter boşluksuz yazar.

Standart yazım:

```text id="qcq9la"
+(T+1)
```

---

## 53. Adresleme + `kN` repeat macro

Repeat macro adreslemeli komutla birlikte kullanılabilmelidir.

Örnek:

```text id="z4qt4r"
+k65(T:100)
```

anlamı:

```text id="i048s5"
tape[100] += 65
```

Bu çok önemlidir. Yoksa adresli hücreye değer vermek zorlaşır.

Aynı şekilde:

```text id="ryg71h"
-k10(T+1)
```

anlamı:

```text id="mv2zfq"
tape[pointer+1] -= 10
```

Compiler bunu tokena açmak yerine doğrudan optimize edebilir.

---

## 54. Adresleme + string/data ilişkisi

`sN=adres,{metin}` direktifi data alanına string yazar.

Örnek:

```text id="y0ck6k"
s1=0,{ABC}
```

Bu data[0] = A, data[1] = B, data[2] = C, data[3] = 0 gibi düşünülebilir.

Sonra tek tek karakter basmak mümkün olur:

```text id="8o2pvn"
.(D:0)
.(D:1)
.(D:2)
```

Çıktı:

```text id="mk36j9"
ABC
```

Bu `p1` ile aynı sonucu verebilir ama `p1` string sonuna kadar basar, `.(D:N)` tek hücre basar.

---

## 55. Adresleme ile data tablosundan rakam alma

Örnek:

```text id="d7gi5l"
s1=0,{12345678}
```

data[0] ASCII 49, data[1] ASCII 50, data[2] ASCII 51...

Rakam değeri almak için:

```text id="ru61fv"
$(D:0)
%(T)
-k48
```

Bu data[0] karakterini aktif hücreye alır ve 48 çıkararak gerçek rakam değerini elde eder.

Eğer data[0] = `'1'` ise:

```text id="q30uld"
49 - 48 = 1
```

Bu doğru ama tekrar hatırlatalım: Bu sadece tek rakamı verir. Çok basamaklı sayıyı kurmak için `sonuç = sonuç * 10 + digit` gerekir.

---

## 56. Adresleme ile register benzeri hücreler

Programcı tape’in belirli mutlak hücrelerini register gibi kullanabilir.

Örnek öneri:

```text id="h7vgca"
(T:0) = A register
(T:1) = B register
(T:2) = C register
(T:3) = D register
(T:4) = temp
(T:5) = flag
(T:6) = index
(T:7) = counter
```

Kod:

```text id="9boes7"
0(T:0)+k10
0(T:1)+k20
```

Bu, A=10, B=20 gibi düşünülebilir. Böylece UX-MINIMA içinde küçük bir sanal CPU tasarımı bile yapılabilir.

---

## 57. Adresleme ile mini frame sistemi

Meta frame dışında programcı kendi local frame’ini kurabilir.

Pointer bir frame merkezinde durur:

```text id="751xtn"
(T-3) = local0
(T-2) = arg1
(T-1) = arg2
(T)   = call/meta id
(T+1) = result
(T+2) = temp
(T+3) = flag
```

Bu çok güçlü bir düşünce biçimidir. Pointer bir “çalışma çerçevesi”nin merkezidir. Komutlar `(T-2)`, `(T-1)`, `(T+1)` gibi göreli adreslerle çalışır.

Bu, 6502 zero page düzeniyle stack frame mantığının UXM karşılığıdır.

---

## 58. Adresleme sisteminin x64 üretimi

Compiler her adresleme modunu x64 operandına çözer.

Örnekler byte cell için:

```text id="x8i22r"
(T)     -> byte [r12 + rbx]
(T+1)   -> byte [r12 + rbx + 1]
(T-1)   -> byte [r12 + rbx - 1]
(T:100) -> byte [r12 + 100]
(D:10)  -> byte [r12 + DATA_OFFSET + 10]
(S:5)   -> byte [r13 + 5]
```

Word cell için:

```text id="js3gzu"
(T)     -> word [r12 + rbx*2]
(T+1)   -> word [r12 + rbx*2 + 2]
(T:100) -> word [r12 + 200]
(D:10)  -> word [r12 + DATA_OFFSET + 20]
```

Dword cell için:

```text id="g2rkyx"
(T)     -> dword [r12 + rbx*4]
(T+1)   -> dword [r12 + rbx*4 + 4]
(T:100) -> dword [r12 + 400]
(D:10)  -> dword [r12 + DATA_OFFSET + 40]
```

Bu yüzden adresleme parser hücre boyutunu bilmelidir.

---

## 59. Bounds check adresleme ile nasıl çalışır?

Her adresleme modu bounds check gerektirir.

```text id="u2apgb"
(T+N): pointer + N tape sınırı içinde mi?
(T-N): pointer - N negatif oluyor mu?
(T:N): N tape_cells içinde mi?
(D:N): N data_cells içinde mi?
(S:N): N stack_cells içinde mi?
(*T): okunan adres tape_cells içinde mi?
```

Safe mode’da bu kontroller zorunludur.

Normal mode’da kullanıcı kapatabilir ama önerilmez.

Wild mode’da kullanıcı sorumluluğu alır.

---

## 60. Bölüm 2 özeti

Bu bölümde V3.1 adresleme modelini netleştirdik.

Temel kararlar:

```text id="b0cuk4"
1. [] sadece döngü için kalır.
2. () adresleme için kullanılır.
3. Adresleme komuttan sonra gelir.
4. Adresleme yoksa varsayılan hedef (T), yani aktif tape hücresidir.
5. Temel adresleme modları: (T), (T+N), (T-N), (T:N), (D:N)
6. Gelişmiş modlar: (S:N), (SP), (P), (E), (F), (*T), (*(T+N))
7. Stack, pointer, flags ve error/status doğrudan adreslenebilir ama mode’a göre sınırlandırılır.
8. Safe/Normal/Wild mode adresleme izinleri farklıdır.
9. kN repeat macro adreslemeli komutlarla da kullanılabilir.
10. Meta frame adresleme ile çok daha temiz hale gelir.
11. x64 codegen, her adresleme modunu cell size’a göre doğru operand’a çevirmelidir.
```

Bu adresleme sistemiyle UX-MINIMA x64 V3.1, 6502’deki adresleme gücünü kendi tape/data/stack yapısına taşıyabilir. Komut seti küçük kalır ama kullanım alanı çok genişler.

Bundan sonraki bölümde **branch/jump sistemi, `:` prefix kuralları, kısa/uzun dallanma, koşullu branch, koşulsuz branch, branch güvenliği ve compiler’ın NASM label üretimi** yazılmalıdır.

**Devam yazarsan Bölüm 3’te dallanma/branch sistemini tam belge olarak yazacağım.**


UX-MINIMA x64 V3.1 Tasarım Belgesi
Bölüm 3 — Branch / Jump Sistemi, : Prefix Kuralları, Yakın-Uzak Dallanma ve Güvenlik
61. Neden branch sistemi şart?

UX-MINIMA’nın ilk çekirdeğinde akış kontrolü yalnızca şu yapıyla kuruluyordu:

[ ... ]

Bu yapı aktif hücre sıfır değilse çalışır, sıfır olunca çıkar. Bu, Brainfuck tarzı döngü için yeterlidir. Fakat ciddi programlama için tek başına yetmez. Çünkü bölme, kalan bulma, sayı yazdırma, çok basamaklı sayı okuma, tablo tarama, sıralama, karar ağacı, menü sistemi, oyun mantığı ve bilimsel modelleme gibi işler daha esnek dallanma ister.

6502’de bu sorun branch komutlarıyla çözülürdü. Örneğin:

BEQ = zero flag set ise dallan
BNE = zero flag clear ise dallan
BCS = carry set ise dallan
BCC = carry clear ise dallan
BMI = negative ise dallan
BPL = positive ise dallan
JMP = koşulsuz atla

UX-MINIMA x64 V3.1’de aynı ruh korunmalı ama 6502 komut adları doğrudan dile eklenmemelidir. Çünkü UX-MINIMA sembolik operator dili olarak kalmalıdır. Bu nedenle branch sistemi için : prefix kullanılmalıdır.

62. : işaretinin V3.1’deki resmi görevi

V3’te : geleceğe ayrılmış bir semboldü. V3.1’de : artık resmi olarak branch / jump prefix olur.

Karar:

: = branch/jump prefix

Bu şu anlama gelir: : tek başına normal komut değildir. Kendisinden sonra gelen işaretlere ve sayıya göre dallanma komutu oluşturur.

Örnek:

:+20
:-20
:0+20
:0-20
::+20
::-20

Bu yapı label kullanmadan göreli dallanma sağlar.

63. Neden label istemiyoruz?

Label sistemi okunabilir olurdu:

:loop
...
Jloop

Ama bu UX-MINIMA’nın operator dili karakterini bozar. Bir süre sonra dil BASIC veya assembly benzeri kelime/etiket sistemine doğru kayar. Senin itirazın doğru: Bu dilde label yerine 6502’deki branch hissine daha yakın bir göreli atlama sistemi daha uygundur.

Bu nedenle V3.1 kararı:

Label yok.
Relative branch var.
Compiler arka planda NASM label üretir.
Kullanıcı label yazmaz.

Yani kullanıcı :+20 yazar; compiler bunu x64 NASM tarafında kendi ürettiği internal label’a çevirir.

64. Branch token bazlı mı, byte bazlı mı olmalı?

Bu çok önemli bir karar. 6502’de branch genellikle makine kodu byte uzaklığına göre çalışırdı. Ama UX-MINIMA kaynak düzeyinde +k65, s1=0,{metin}, @60, +(T+1) gibi yapılar vardır. Bunların kaynak karakter sayısı, token sayısı ve üretilen machine code byte sayısı aynı değildir.

Üç farklı ölçü vardır:

1. Kaynak karakter sayısı
2. UXM token/instruction sayısı
3. Üretilen x64 machine code byte sayısı

Kullanıcıya x64 machine code byte hesabı yaptırmak doğru değildir. Çünkü pattern optimizer devreye girince aynı kaynak kod farklı uzunlukta ASM üretebilir.

Bu yüzden V3.1 kararı:

Branch uzaklığı UXM instruction/token birimiyle yorumlanır.
Compiler hedef token/instruction noktasına internal NASM label koyar.
NASM gerçek kısa/uzun jump mesafesini kendisi çözer.

Bu en güvenli yoldur.

65. Branch komut ailesi

V3.1 için temel branch komutları şunlardır:

:+N    aktif hücre sıfır değilse N instruction ileri git
:-N    aktif hücre sıfır değilse N instruction geri git
:0+N   aktif hücre sıfırsa N instruction ileri git
:0-N   aktif hücre sıfırsa N instruction geri git
::+N   koşulsuz N instruction ileri git
::-N   koşulsuz N instruction geri git

Burada N decimal sayıdır.

Örnek:

:+10

Anlam:

aktif hücre 0 değilse 10 instruction ileri atla

Örnek:

:-8

Anlam:

aktif hücre 0 değilse 8 instruction geri git

Örnek:

:0+12

Anlam:

aktif hücre 0 ise 12 instruction ileri git

Örnek:

::-20

Anlam:

koşulsuz 20 instruction geri git
66. [ ve ] ile : branch farkı

[ ve ] döngü yapısıdır. Bu yapı hâlâ kalmalıdır. Çünkü Brainfuck tarzı doğal döngü için çok kısa ve güçlüdür.

[ ... ]

aktif hücre sıfır değilken döner.

: branch ise daha genel akış kontrolüdür.

Örneğin şu döngü:

+k10[-]

doğal UXM döngüsüdür.

Ama branch ile şöyle bir yapı kurulabilir:

+k10
-
:-1

Burada mantık “azalt, hâlâ sıfır değilse geri dön” gibi düşünülebilir. Fakat örnekte branch hedef sayısını compiler instruction hesabına göre doğru yazmak gerekir. Bu yüzden branch güçlüdür ama dikkat ister.

[ ] yeni başlayan için daha güvenlidir. : branch ise ileri seviye ve 6502 ruhuna daha yakındır.

67. Branch aktif hücreye göre çalışır

V3.1’de branch varsayılan olarak aktif hücreyi kontrol eder. Yani branch adresleme almaz.

:+N
:0+N

kontrol edilen değer:

(T)

yani aktif tape hücresidir.

Eğer başka bir hücreye göre branch yapmak istiyorsan, önce o hücreyi aktif hücreye getirmen gerekir veya meta/stack ile flag üretmen gerekir.

Örnek:

$(T:100)
%(T)
:+20

Bu kodda tape[100] değeri aktif hücreye alınır ve sonra branch aktif hücreye göre çalışır.

Branch’e doğrudan adresleme eklemiyoruz:

:+20(T:100)

Bu V3.1’de önerilmez. Çünkü branch sözdizimi karmaşıklaşır. Branch sade kalmalıdır.

68. Flag tabanlı branch gerekli mi?

Evet, V3.1’de sadece aktif hücreye göre branch yetmez. Çünkü carry, overflow, zero, sign gibi bayraklar olacaksa bunlara göre branch yapmak da gerekir.

Bunun için : prefix altında ikinci branch ailesi tanımlanabilir.

Önerilen flag branch komutları:

:Z+N   zero flag set ise N ileri
:Z-N   zero flag set ise N geri
:z+N   zero flag clear ise N ileri
:z-N   zero flag clear ise N geri
:C+N   carry flag set ise N ileri
:C-N   carry flag set ise N geri
:c+N   carry flag clear ise N ileri
:c-N   carry flag clear ise N geri
:O+N   overflow flag set ise N ileri
:O-N   overflow flag set ise N geri
:o+N   overflow flag clear ise N ileri
:o-N   overflow flag clear ise N geri
:S+N   sign flag set ise N ileri
:S-N   sign flag set ise N geri
:s+N   sign flag clear ise N ileri
:s-N   sign flag clear ise N geri

Burada büyük harf bayrak set, küçük harf bayrak clear anlamına gelir.

Örnek:

:C+10

Anlam:

carry flag set ise 10 instruction ileri git

Örnek:

:z-6

Anlam:

zero flag clear ise 6 instruction geri git

Bu yapı 6502’deki BEQ/BNE/BCS/BCC/BMI/BPL mantığına çok yakındır ama UXM sembolik yapısını korur.

69. 6502 branch karşılıkları

6502 ile UXM V3.1 branch eşlemesi şöyle düşünülebilir:

6502 BEQ  ≈  :Z+N veya :Z-N
6502 BNE  ≈  :z+N veya :z-N
6502 BCS  ≈  :C+N veya :C-N
6502 BCC  ≈  :c+N veya :c-N
6502 BMI  ≈  :S+N veya :S-N
6502 BPL  ≈  :s+N veya :s-N
6502 JMP  ≈  ::+N veya ::-N

Burada S sign flag olarak kullanılır. 6502’de negative flag vardı. UXM’de bunu sign flag diye adlandırmak daha anlaşılırdır.

70. Aktif hücre branch ve zero flag branch farkı

Aktif hücre branch:

:+N
:0+N

doğrudan aktif hücre değerine bakar.

Zero flag branch:

:Z+N
:z+N

son işlemde oluşan zero flag’e bakar.

Bu ikisi aynı şey değildir.

Örneğin:

0(T)

aktif hücre sıfırlanır. Bu işlem zero flag’i de set edebilir. O anda:

:0+10

ve:

:Z+10

benzer davranabilir.

Ama başka bir işlem flags’i değiştirdiyse aktif hücre ve zero flag farklı anlam taşıyabilir. Bu yüzden belgede ayrım net olmalıdır:

:0+N = aktif hücre şu anda sıfır mı?
:Z+N = son işlem zero flag set etti mi?
71. Compare sonrası branch

Karşılaştırma komutları ?, !, ; sonucu hedef hücreye yazar ve flags’i günceller.

Örnek:

0(T-2)+k10
0(T-1)+k20
$(T-2)
!(T-1)

Bu 10 > 20 kontrolüdür. Sonuç (T-1) içine 0 yazılır. Ayrıca zero flag sonucu 0 olduğu için set edilebilir.

Ardından:

:+10

aktif hücreye bakar. Ama aktif hücre hâlâ (T) ise karşılaştırma sonucu (T-1) içindedir. Bu yüzden branch’in hangi değere baktığını karıştırmamak gerekir.

Daha doğru kullanım:

$(T-2)
!(T-1)
$(T-1)
%(T)
:+10

Bu sonuç flag’ini aktif hücreye alıp ona göre branch yapar.

Alternatif olarak compare sonrası zero flag’e göre branch kullanılabilir ama compare sonucu ve flags kuralı çok iyi belgelenmelidir.

72. Branch güvenliği

Branch sistemi gelince compiler’ın güvenlik kontrolü yapması gerekir.

Safe mode’da branch hedefi mutlaka geçerli instruction sınırına denk gelmelidir. Branch hedefi aşağıdaki alanların içine düşemez:

1. String tanımının ortası
2. Data direktifinin ortası
3. Adresleme ifadesinin ortası
4. Meta çağrı parametresinin ortası
5. kN macro genişletmesinin parçalanmış ortası
6. Compiler directive alanı

Branch hedefi, lexer/IR aşamasında tanımlanmış instruction boundary üzerine düşmelidir.

Bu nedenle compiler kaynak metin üzerinde karakter sayarak branch yapmamalıdır. Önce UIR instruction listesi oluşturulmalı, branch hedefleri bu liste üzerinde hesaplanmalıdır.

73. Branch loop dengesini bozabilir mi?

Evet, bozabilir. Örneğin branch bir [ bloğunun içine atlayabilir veya ] dışına çıkabilir. Bu, çok tehlikeli olabilir.

Safe mode’da kural:

Branch, loop dengesini bozacak şekilde [ ] bloğunun içine veya dışına atlayamaz.

Normal mode’da:

Compiler uyarı verir ama izin verebilir.

Wild mode’da:

Kullanıcı sorumluluğundadır.

Bu kural IDE’de görsel olarak gösterilmelidir. Branch hedefleri çizgilerle veya oklarla gösterilebilir.

74. Branch ve pattern optimizer

Pattern optimizer branch’leri bozmayacak şekilde çalışmalıdır.

Örneğin branch hedefi instruction 20’ye gidiyorsa, optimizer instruction 18–22 arasını tek pattern’e indirirse branch hedefi kaybolabilir. Bu kabul edilemez.

Bu yüzden kural:

Branch hedefi olan instruction optimizer tarafından pattern içine gömülemez.

Yani branch target instruction bir “barrier” sayılmalıdır.

Pattern optimizer şu sınırları aşmamalıdır:

1. Branch source
2. Branch target
3. Loop boundary
4. Meta call boundary
5. Debug breakpoint
6. IDE step marker

Buna optimizer barrier sistemi denebilir.

75. Branch syntax parser

Branch parser şu biçimleri tanımalıdır:

:+N
:-N
:0+N
:0-N
::+N
::-N
:Z+N
:Z-N
:z+N
:z-N
:C+N
:C-N
:c+N
:c-N
:O+N
:O-N
:o+N
:o-N
:S+N
:S-N
:s+N
:s-N

Burada N pozitif decimal sayı olmalıdır.

Geçersiz:

:+0
:-0
:+
:-
:Q+10
:++10
:--10

N=0 anlamsızdır. Branch 0 uzaklığa atlamamalıdır. Eğer kullanıcı özellikle sonsuz döngü istiyorsa ::-1 gibi açık bir geri branch kullanmalıdır.

76. Yakın ve uzak branch ayrımı

6502’de relative branch kısa mesafeliydi. x64’te short jump ve near jump ayrımı vardır. Ama kullanıcı bunu bilmek zorunda kalmamalıdır.

V3.1’de kullanıcı hep aynı syntax’ı kullanır:

:+N
::-N

Compiler/NASM gerekli jump türünü seçer.

Fakat istersek iki seviye ekleyebiliriz:

:+N     normal branch, compiler karar verir
:!+N    zorla long/near branch
:.+N    zorla short branch

Ama bu ilk V3.1 için gereksiz karmaşıklık olur. Daha doğru karar:

Kullanıcı branch uzunluğu seçmez.
Compiler ve NASM çözer.
77. Branch x64 ASM üretimi

Aktif hücre sıfır değilse ileri branch:

:+N

Byte cell için x64 mantığı:

cmp byte [r12 + rbx], 0
jne __ux_branch_target_X

Word cell:

cmp word [r12 + rbx*2], 0
jne __ux_branch_target_X

Dword cell:

cmp dword [r12 + rbx*4], 0
jne __ux_branch_target_X

Aktif hücre sıfırsa branch:

:0+N

x64:

cmp byte [r12 + rbx], 0
je __ux_branch_target_X

Koşulsuz branch:

::+N

x64:

jmp __ux_branch_target_X

Flag branch:

:C+N

x64 tarafında iki yol vardır. Eğer carry flag x64 CPU flag olarak canlı tutuluyorsa:

jc __ux_branch_target_X

Ama runtime/meta çağrıları CPU flaglerini bozabilir. Bu yüzden UXM FLAGS word tutuluyorsa daha güvenli olan şudur:

test word [ux_flags], FLAG_CARRY
jnz __ux_branch_target_X

V3.1’de daha güvenli karar:

UXM bayrakları CPU flaglerine bağlı tutulmaz.
Ayrı FLAGS word içinde tutulur.
Branch, UXM FLAGS word’e bakar.

Bu IDE ve runtime açısından daha tutarlıdır.

78. UXM flags ile x64 CPU flags ayrımı

Bu çok önemli. x64 CPU’nun kendi flagleri vardır. Ama UX-MINIMA’nın bayrakları ayrı tutulmalıdır.

Sebep:

1. Runtime çağrıları x64 CPU flaglerini bozar.
2. Meta servisler host dilde çalışır.
3. IDE interpreter x64 CPU flags kullanmaz.
4. Cross-platform davranış için UXM flags soyut olmalıdır.

Bu yüzden:

UXM FLAGS = runtime/compiler tarafından yönetilen sanal bayraklar
x64 CPU FLAGS = generated ASM’in geçici kullandığı gerçek CPU bayrakları

Branch da UXM FLAGS’e göre yapılmalıdır.

Örneğin carry branch:

mov ax, [ux_flags]
test ax, FLAG_CARRY
jnz __ux_branch_target_X
79. Branch ve status byte ilişkisi

Branch başarısız olursa hata değildir. Koşul sağlanmadıysa program normal devam eder.

Ama branch hedefi geçersizse compiler hatasıdır veya runtime hata değildir; çünkü target compile-time çözülecektir.

Hata kodları:

6 = invalid branch target

Compiler branch hedefini çözemiyorsa ASM üretmemelidir.

Normal branch çalıştığında status değişmemelidir.

Ancak IDE trace modunda branch olayı kaydedilmelidir:

{"step":120,"op":":+10","taken":true,"from":120,"to":130,"status":0}
80. Branch ve IDE trace

IDE için branch olayları çok önemlidir. Çünkü program akışı düz ilerlemez.

Trace kaydı şu bilgileri içermelidir:

step
branch opcode
condition type
condition value
taken true/false
source instruction index
target instruction index
pointer
active cell value
flags
status

Örnek JSON:

{"step":44,"op":":0+8","cond":"current_zero","current":0,"taken":true,"from":44,"to":52,"ptr":10,"flags":2,"status":0}

Bu sayede IDE branch oklarını, izleme çizgisini ve akış grafiğini gösterebilir.

81. Branch ile IF yapısı

Mevcut [ ] ile IF şöyle kuruluyordu:

flag[
p1
0
]

Branch ile IF daha farklı kurulabilir.

Örnek düşünce:

flag aktif hücrede
:0+3
p1
::+2
p2

Bu pseudo örnekte mantık şudur:

flag sıfırsa doğru bloğu atla
p1 yaz
else bloğunu atla
p2 yaz

Gerçek branch uzaklıkları instruction sayısına göre hesaplanmalıdır.

Bu, IF-ELSE kurmayı mümkün kılar. Fakat elle uzaklık saymak zor olabilir. IDE burada yardımcı olmalıdır.

82. Branch ile WHILE döngüsü

Aktif hücre sayaç olsun.

+k10
-
:-1

Bu çok basit gösterimdir ama gerçek instruction uzaklığı doğru hesaplanmalıdır. Daha açık pseudo mantık:

loop_start:
    -
    if current != 0 goto loop_start

UXM relative branch ile:

+k10
-
:-1

Burada :-1 bir önceki instruction’a döner gibi düşünülür. Fakat compiler instruction listesinde - bir instruction, branch bir instruction olduğu için hedef hesabı net olmalıdır.

Kural:

:-1 = branch instruction’dan önceki 1. instruction’a git

Yani :-1 bir önceki instruction’a döner.

83. Branch uzaklık hesabı

Instruction index mantığı:

0: +k10
1: -
2: :-1

:-1 instruction 2’den instruction 1’e gider.

:-2 instruction 2’den instruction 0’a gider.

:+1 instruction 2’den instruction 3’e gider.

Bu kural net olmalıdır:

:+N = current instruction index + N
:-N = current instruction index - N

Burada branch instruction’ın kendisi index hesabına dahildir.

Bu basit ve deterministiktir.

84. Branch ve kN macro ilişkisi

+k10 tek instruction mı, 10 instruction mı?

Bu kritik karardır.

V3.1’de kN macro artık iki farklı şekilde ele alınabilir:

1. Lexer expansion mode:
    +k10 = 10 adet + token

2. Compact instruction mode:
    +k10 = tek instruction, amount=10

Branch sistemi için compact instruction mode daha iyidir. Çünkü kullanıcı +k10 yazdığında bunu tek işlem gibi düşünür.

Önerilen V3.1 kararı:

UIR düzeyinde +k10 tek instruction olarak tutulur.
Codegen isterse add 10 üretir.
İsterse debug için 10 adıma bölebilir.

IDE step modunda iki seçenek olabilir:

macro-step: +k10 tek adım
micro-step: +k10 on adet + adımı gibi gösterilir

Branch hedefleri macro instruction seviyesinde hesaplanmalıdır.

Bu çok önemli bir düzeltmedir. Eski lexer’ın kN’i tamamen açması branch sistemi için uygun değildir.

85. Branch ve pattern bankası ilişkisi

Pattern bankası instruction sınırlarını korumalıdır. Branch hedefi olan instruction’lar optimizer barrier olur.

Örneğin:

0: +k10
1: > 
2: +
3: <
4: :-3

Branch instruction 4’ten instruction 1’e dönüyorsa, optimizer 1–3 arasını tek pattern’e indirebilir mi? Evet, ama hedef instruction 1 pattern başlangıcı olarak korunuyorsa mümkün olabilir. Hedef instruction pattern’in ortasına düşemez.

Kural:

Branch target pattern başlangıcı olabilir.
Branch target pattern ortası olamaz.

Bu compiler için önemlidir.

86. Branch ile sayı yazdırma rutini

Sayı yazdırma için bölme ve kalan gerekir. Branch sistemi bunu mümkün hale getirir.

Decimal print algoritması:

n = sayı
hundreds = 0
while n >= 100:
    n -= 100
    hundreds += 1
tens = 0
while n >= 10:
    n -= 10
    tens += 1
ones = n
print hundreds+48
print tens+48
print ones+48

Bu algoritma için:

1. karşılaştırma
2. koşullu branch
3. geri branch
4. azaltma
5. artırma

gerekir. V3.1 branch sistemi olmadan bu temiz yazılamaz. Branch sistemi ile mümkün olur.

Yine de pratik kullanım için @60 decimal print meta servisi daha iyi olacaktır. Ama eğitim amaçlı UXM decimal print rutini yazılabilir.

87. Branch ile bölme rutini

Bölme algoritması:

quotient = 0
remainder = dividend
while remainder >= divisor:
    remainder -= divisor
    quotient += 1

Bu yapı için remainder >= divisor kontrolü gerekir. UXM’de ! ve ? ile büyüktür/eşittir birleşimi kurulabilir.

Dallanma olmadan bunu yapmak çok zor olur. Branch sistemi geldikten sonra bölme rutini yazılabilir. Bu, 6502’de makine diliyle yaptığımız mantığın aynısıdır.

88. Branch ile bubble sort

Bubble sort için iç içe döngü gerekir:

outer loop
    inner loop
        compare adjacent
        if wrong order:
            swap

[ ] ile de yapılabilir ama branch ile daha assembly-benzeri ve kontrol edilebilir olur.

Gerekli yapılar:

1. dış sayaç
2. iç sayaç
3. liste pointer/index
4. compare
5. conditional branch
6. swap
7. geri branch

Bu nedenle sort rutinleri V3.1 branch sisteminden sonra gerçekçi hale gelir.

89. Branch ve safe/wild mode farkı

Safe mode:

branch target kontrol edilir
loop dengesini bozma engellenir
pattern barrier korunur
string/data içine atlama yasak
invalid branch compile error verir

Normal mode:

branch target kontrol edilir
loop dengesi için warning verilebilir
pattern barrier korunur

Wild mode:

branch target kontrolü gevşetilebilir
loop içine/dışına atlama kullanıcı sorumluluğunda olabilir
self-modifying deneyler için daha serbest davranılabilir

Ama x64 ASM üretiminde yine de NASM label üretimi tutarlı olmalıdır. Wild mode bile compiler’ın bozuk ASM üretmesi anlamına gelmemelidir.

90. Branch ve runtime memory layout değişimi

Eğer Wild mode’da bellek layout’u runtime’da değiştirilebiliyorsa, branch bundan etkilenmemelidir. Çünkü branch kod akışını değiştirir, bellek layout’u veri alanını değiştirir.

Fakat data alanından UXM kodu yorumlama gibi bir mod gelirse branch artık yorumlanan kod içinde de çalışmalıdır. Bu V3.1 ana compiler değil, interpreter/wild experiment konusudur.

Bu yüzden karar:

Compiled x64 branch:
    compile-time instruction listesine göre çalışır.

Interpreter/wild branch:
    runtime instruction stream üzerinde çalışır.

Bu iki sistem ayrı tutulmalıdır.

91. Branch komutlarının UIR temsili

Compiler source’u UIR’a çevirirken branch instruction şöyle tutulabilir:

type = BRANCH
cond = CURRENT_NONZERO / CURRENT_ZERO / ALWAYS / FLAG_SET / FLAG_CLEAR
flag = NONE / Z / C / O / S
direction = FORWARD / BACKWARD
distance = N
source_index = i
target_index = hesaplanmış

Örnek:

:+20

UIR:

{"type":"BRANCH","cond":"CURRENT_NONZERO","direction":"FORWARD","distance":20}

Örnek:

:C-8

UIR:

{"type":"BRANCH","cond":"FLAG_SET","flag":"C","direction":"BACKWARD","distance":8}

Bu UIR hem codegen hem interpreter hem IDE için ortak veri olur.

92. Branch komutları ve hata kodları

Branch ile ilgili hata kodları status tablosunda açık olmalıdır.

Önerilen branch hata kodları:

6   invalid branch target
70  branch target out of range
71  branch target inside data/string directive
72  branch target inside addressing expression
73  branch target breaks safe loop boundary
74  branch target blocked by optimizer barrier
75  invalid branch syntax
76  invalid branch flag
77  zero branch distance
78  branch target unresolved

Compiler bu hataları compile-time verir. Interpreter mode’da runtime branch hatası oluşursa status byte bu kodlardan biri olur.

93. Branch örnekleri
Örnek 1: aktif hücre sıfır değilse atla
+k1
:+2
0+k65.
0+k66.

Mantık:

aktif hücre 1 olduğu için :+2 branch alınır
A basma kısmı atlanabilir
B basılır

Gerçek hedef hesabı instruction index’e göre yapılır.

Örnek 2: aktif hücre sıfırsa atla
0
:0+2
0+k65.
0+k66.

Aktif hücre 0 olduğu için branch alınır.

Örnek 3: koşulsuz geri dön
+k5
-
::-1

Bu sonsuz veya hatalı döngüye dönüşebilir; çünkü koşulsuz geri branch vardır. Bu yüzden dikkatli kullanılmalıdır.

Örnek 4: zero flag branch
0
:Z+2
0+k65.
0+k66.

Eğer 0 işlemi zero flag set ediyorsa branch alınır.

94. Branch ve [ ] birlikte kullanılabilir mi?

Evet, kullanılabilir. Ama safe mode’da compiler kontrol etmelidir.

Örnek:

+k5[
-
:0+2
]

Bu tarz karma yapı mümkündür ama yeni başlayan için önerilmez.

Kural:

Basit döngüler için [ ] kullan.
Assembly-benzeri akış için : branch kullan.
İkisini karıştırıyorsan IDE trace ile kontrol et.
95. Branch sisteminin tasarım sonucu

V3.1 branch sistemi UX-MINIMA’yı büyük ölçüde güçlendirir. Çünkü artık şu işler mümkün hale gelir:

1. IF-ELSE benzeri akış
2. WHILE/FOR benzeri döngülerin elle kurulması
3. Bölme ve kalan algoritması
4. Decimal sayı yazdırma rutini
5. Klavyeden çok basamaklı sayı alma
6. Tablo tarama
7. Bubble sort ve diğer sıralamalar
8. Menü sistemi
9. Karar ağacı
10. 6502 benzeri assembly düşüncesi

Ama branch güçlü olduğu kadar tehlikelidir. Bu yüzden UIR, optimizer barrier, branch target kontrolü, safe/wild mode ayrımı ve IDE trace şarttır.

96. Bölüm 3 özeti

Bu bölümde : prefix ile V3.1 branch sistemini netleştirdik.

Kararlar:

1. Label yok; relative branch var.
2. Branch instruction/token index üzerinden çalışır.
3. Compiler arka planda NASM label üretir.
4. :+N aktif hücre sıfır değilse ileri gider.
5. :-N aktif hücre sıfır değilse geri gider.
6. :0+N aktif hücre sıfırsa ileri gider.
7. :0-N aktif hücre sıfırsa geri gider.
8. ::+N ve ::-N koşulsuz jump’tır.
9. :Z/:z, :C/:c, :O/:o, :S/:s flag tabanlı branch sağlar.
10. UXM flags, x64 CPU flags’ten ayrı tutulur.
11. Branch hedefleri UIR instruction sınırlarına göre hesaplanır.
12. Branch hedefleri optimizer barrier olarak korunur.
13. Safe mode’da loop/data/string içine tehlikeli branch engellenir.
14. Wild mode’da bazı kontroller gevşetilebilir.
15. IDE branch trace üretmelidir.

Bundan sonraki bölümde meta komut sistemi, @N, @#, meta frame, sabit servis numaraları, argüman/sonuç hücreleri, runtime ABI, FreeBASIC/QB64 fonksiyonlarına bağlanma ve kullanıcı tanımlı meta servis alanı yazılmalıdır.

Devam yazarsan Bölüm 4’te meta servis ve runtime ABI tasarımını tam belge olarak yazacağım.

Bu yanıtı tercih ediyorum

UX-MINIMA x64 V3.1 Tasarım Belgesi
Bölüm 3 — Branch / Jump Sistemi, : Prefix Kuralları, Yakın-Uzak Dallanma ve Güvenlik
61. Neden branch sistemi şart?

UX-MINIMA’nın ilk çekirdeğinde akış kontrolü yalnızca şu yapıyla kuruluyordu:

[ ... ]

Bu yapı aktif hücre sıfır değilse çalışır, sıfır olunca çıkar. Bu, Brainfuck tarzı döngü için yeterlidir. Fakat ciddi programlama için tek başına yetmez. Çünkü bölme, kalan bulma, sayı yazdırma, çok basamaklı sayı okuma, tablo tarama, sıralama, karar ağacı, menü sistemi, oyun mantığı ve bilimsel modelleme gibi işler daha esnek dallanma ister.

6502’de bu sorun branch komutlarıyla çözülürdü. Örneğin:

BEQ = zero flag set ise dallan
BNE = zero flag clear ise dallan
BCS = carry set ise dallan
BCC = carry clear ise dallan
BMI = negative ise dallan
BPL = positive ise dallan
JMP = koşulsuz atla

UX-MINIMA x64 V3.1’de aynı ruh korunmalı ama 6502 komut adları doğrudan dile eklenmemelidir. Çünkü UX-MINIMA sembolik operator dili olarak kalmalıdır. Bu nedenle branch sistemi için : prefix kullanılmalıdır.

62. : işaretinin V3.1’deki resmi görevi

V3’te : geleceğe ayrılmış bir semboldü. V3.1’de : artık resmi olarak branch / jump prefix olur.

Karar:

: = branch/jump prefix

Bu şu anlama gelir: : tek başına normal komut değildir. Kendisinden sonra gelen işaretlere ve sayıya göre dallanma komutu oluşturur.

Örnek:

:+20
:-20
:0+20
:0-20
::+20
::-20

Bu yapı label kullanmadan göreli dallanma sağlar.

63. Neden label istemiyoruz?

Label sistemi okunabilir olurdu:

:loop
...
Jloop

Ama bu UX-MINIMA’nın operator dili karakterini bozar. Bir süre sonra dil BASIC veya assembly benzeri kelime/etiket sistemine doğru kayar. Senin itirazın doğru: Bu dilde label yerine 6502’deki branch hissine daha yakın bir göreli atlama sistemi daha uygundur.

Bu nedenle V3.1 kararı:

Label yok.
Relative branch var.
Compiler arka planda NASM label üretir.
Kullanıcı label yazmaz.

Yani kullanıcı :+20 yazar; compiler bunu x64 NASM tarafında kendi ürettiği internal label’a çevirir.

64. Branch token bazlı mı, byte bazlı mı olmalı?

Bu çok önemli bir karar. 6502’de branch genellikle makine kodu byte uzaklığına göre çalışırdı. Ama UX-MINIMA kaynak düzeyinde +k65, s1=0,{metin}, @60, +(T+1) gibi yapılar vardır. Bunların kaynak karakter sayısı, token sayısı ve üretilen machine code byte sayısı aynı değildir.

Üç farklı ölçü vardır:

1. Kaynak karakter sayısı
2. UXM token/instruction sayısı
3. Üretilen x64 machine code byte sayısı

Kullanıcıya x64 machine code byte hesabı yaptırmak doğru değildir. Çünkü pattern optimizer devreye girince aynı kaynak kod farklı uzunlukta ASM üretebilir.

Bu yüzden V3.1 kararı:

Branch uzaklığı UXM instruction/token birimiyle yorumlanır.
Compiler hedef token/instruction noktasına internal NASM label koyar.
NASM gerçek kısa/uzun jump mesafesini kendisi çözer.

Bu en güvenli yoldur.

65. Branch komut ailesi

V3.1 için temel branch komutları şunlardır:

:+N    aktif hücre sıfır değilse N instruction ileri git
:-N    aktif hücre sıfır değilse N instruction geri git
:0+N   aktif hücre sıfırsa N instruction ileri git
:0-N   aktif hücre sıfırsa N instruction geri git
::+N   koşulsuz N instruction ileri git
::-N   koşulsuz N instruction geri git

Burada N decimal sayıdır.

Örnek:

:+10

Anlam:

aktif hücre 0 değilse 10 instruction ileri atla

Örnek:

:-8

Anlam:

aktif hücre 0 değilse 8 instruction geri git

Örnek:

:0+12

Anlam:

aktif hücre 0 ise 12 instruction ileri git

Örnek:

::-20

Anlam:

koşulsuz 20 instruction geri git
66. [ ve ] ile : branch farkı

[ ve ] döngü yapısıdır. Bu yapı hâlâ kalmalıdır. Çünkü Brainfuck tarzı doğal döngü için çok kısa ve güçlüdür.

[ ... ]

aktif hücre sıfır değilken döner.

: branch ise daha genel akış kontrolüdür.

Örneğin şu döngü:

+k10[-]

doğal UXM döngüsüdür.

Ama branch ile şöyle bir yapı kurulabilir:

+k10
-
:-1

Burada mantık “azalt, hâlâ sıfır değilse geri dön” gibi düşünülebilir. Fakat örnekte branch hedef sayısını compiler instruction hesabına göre doğru yazmak gerekir. Bu yüzden branch güçlüdür ama dikkat ister.

[ ] yeni başlayan için daha güvenlidir. : branch ise ileri seviye ve 6502 ruhuna daha yakındır.

67. Branch aktif hücreye göre çalışır

V3.1’de branch varsayılan olarak aktif hücreyi kontrol eder. Yani branch adresleme almaz.

:+N
:0+N

kontrol edilen değer:

(T)

yani aktif tape hücresidir.

Eğer başka bir hücreye göre branch yapmak istiyorsan, önce o hücreyi aktif hücreye getirmen gerekir veya meta/stack ile flag üretmen gerekir.

Örnek:

$(T:100)
%(T)
:+20

Bu kodda tape[100] değeri aktif hücreye alınır ve sonra branch aktif hücreye göre çalışır.

Branch’e doğrudan adresleme eklemiyoruz:

:+20(T:100)

Bu V3.1’de önerilmez. Çünkü branch sözdizimi karmaşıklaşır. Branch sade kalmalıdır.

68. Flag tabanlı branch gerekli mi?

Evet, V3.1’de sadece aktif hücreye göre branch yetmez. Çünkü carry, overflow, zero, sign gibi bayraklar olacaksa bunlara göre branch yapmak da gerekir.

Bunun için : prefix altında ikinci branch ailesi tanımlanabilir.

Önerilen flag branch komutları:

:Z+N   zero flag set ise N ileri
:Z-N   zero flag set ise N geri
:z+N   zero flag clear ise N ileri
:z-N   zero flag clear ise N geri
:C+N   carry flag set ise N ileri
:C-N   carry flag set ise N geri
:c+N   carry flag clear ise N ileri
:c-N   carry flag clear ise N geri
:O+N   overflow flag set ise N ileri
:O-N   overflow flag set ise N geri
:o+N   overflow flag clear ise N ileri
:o-N   overflow flag clear ise N geri
:S+N   sign flag set ise N ileri
:S-N   sign flag set ise N geri
:s+N   sign flag clear ise N ileri
:s-N   sign flag clear ise N geri

Burada büyük harf bayrak set, küçük harf bayrak clear anlamına gelir.

Örnek:

:C+10

Anlam:

carry flag set ise 10 instruction ileri git

Örnek:

:z-6

Anlam:

zero flag clear ise 6 instruction geri git

Bu yapı 6502’deki BEQ/BNE/BCS/BCC/BMI/BPL mantığına çok yakındır ama UXM sembolik yapısını korur.

69. 6502 branch karşılıkları

6502 ile UXM V3.1 branch eşlemesi şöyle düşünülebilir:

6502 BEQ  ≈  :Z+N veya :Z-N
6502 BNE  ≈  :z+N veya :z-N
6502 BCS  ≈  :C+N veya :C-N
6502 BCC  ≈  :c+N veya :c-N
6502 BMI  ≈  :S+N veya :S-N
6502 BPL  ≈  :s+N veya :s-N
6502 JMP  ≈  ::+N veya ::-N

Burada S sign flag olarak kullanılır. 6502’de negative flag vardı. UXM’de bunu sign flag diye adlandırmak daha anlaşılırdır.

70. Aktif hücre branch ve zero flag branch farkı

Aktif hücre branch:

:+N
:0+N

doğrudan aktif hücre değerine bakar.

Zero flag branch:

:Z+N
:z+N

son işlemde oluşan zero flag’e bakar.

Bu ikisi aynı şey değildir.

Örneğin:

0(T)

aktif hücre sıfırlanır. Bu işlem zero flag’i de set edebilir. O anda:

:0+10

ve:

:Z+10

benzer davranabilir.

Ama başka bir işlem flags’i değiştirdiyse aktif hücre ve zero flag farklı anlam taşıyabilir. Bu yüzden belgede ayrım net olmalıdır:

:0+N = aktif hücre şu anda sıfır mı?
:Z+N = son işlem zero flag set etti mi?
71. Compare sonrası branch

Karşılaştırma komutları ?, !, ; sonucu hedef hücreye yazar ve flags’i günceller.

Örnek:

0(T-2)+k10
0(T-1)+k20
$(T-2)
!(T-1)

Bu 10 > 20 kontrolüdür. Sonuç (T-1) içine 0 yazılır. Ayrıca zero flag sonucu 0 olduğu için set edilebilir.

Ardından:

:+10

aktif hücreye bakar. Ama aktif hücre hâlâ (T) ise karşılaştırma sonucu (T-1) içindedir. Bu yüzden branch’in hangi değere baktığını karıştırmamak gerekir.

Daha doğru kullanım:

$(T-2)
!(T-1)
$(T-1)
%(T)
:+10

Bu sonuç flag’ini aktif hücreye alıp ona göre branch yapar.

Alternatif olarak compare sonrası zero flag’e göre branch kullanılabilir ama compare sonucu ve flags kuralı çok iyi belgelenmelidir.

72. Branch güvenliği

Branch sistemi gelince compiler’ın güvenlik kontrolü yapması gerekir.

Safe mode’da branch hedefi mutlaka geçerli instruction sınırına denk gelmelidir. Branch hedefi aşağıdaki alanların içine düşemez:

1. String tanımının ortası
2. Data direktifinin ortası
3. Adresleme ifadesinin ortası
4. Meta çağrı parametresinin ortası
5. kN macro genişletmesinin parçalanmış ortası
6. Compiler directive alanı

Branch hedefi, lexer/IR aşamasında tanımlanmış instruction boundary üzerine düşmelidir.

Bu nedenle compiler kaynak metin üzerinde karakter sayarak branch yapmamalıdır. Önce UIR instruction listesi oluşturulmalı, branch hedefleri bu liste üzerinde hesaplanmalıdır.

73. Branch loop dengesini bozabilir mi?

Evet, bozabilir. Örneğin branch bir [ bloğunun içine atlayabilir veya ] dışına çıkabilir. Bu, çok tehlikeli olabilir.

Safe mode’da kural:

Branch, loop dengesini bozacak şekilde [ ] bloğunun içine veya dışına atlayamaz.

Normal mode’da:

Compiler uyarı verir ama izin verebilir.

Wild mode’da:

Kullanıcı sorumluluğundadır.

Bu kural IDE’de görsel olarak gösterilmelidir. Branch hedefleri çizgilerle veya oklarla gösterilebilir.

74. Branch ve pattern optimizer

Pattern optimizer branch’leri bozmayacak şekilde çalışmalıdır.

Örneğin branch hedefi instruction 20’ye gidiyorsa, optimizer instruction 18–22 arasını tek pattern’e indirirse branch hedefi kaybolabilir. Bu kabul edilemez.

Bu yüzden kural:

Branch hedefi olan instruction optimizer tarafından pattern içine gömülemez.

Yani branch target instruction bir “barrier” sayılmalıdır.

Pattern optimizer şu sınırları aşmamalıdır:

1. Branch source
2. Branch target
3. Loop boundary
4. Meta call boundary
5. Debug breakpoint
6. IDE step marker

Buna optimizer barrier sistemi denebilir.

75. Branch syntax parser

Branch parser şu biçimleri tanımalıdır:

:+N
:-N
:0+N
:0-N
::+N
::-N
:Z+N
:Z-N
:z+N
:z-N
:C+N
:C-N
:c+N
:c-N
:O+N
:O-N
:o+N
:o-N
:S+N
:S-N
:s+N
:s-N

Burada N pozitif decimal sayı olmalıdır.

Geçersiz:

:+0
:-0
:+
:-
:Q+10
:++10
:--10

N=0 anlamsızdır. Branch 0 uzaklığa atlamamalıdır. Eğer kullanıcı özellikle sonsuz döngü istiyorsa ::-1 gibi açık bir geri branch kullanmalıdır.

76. Yakın ve uzak branch ayrımı

6502’de relative branch kısa mesafeliydi. x64’te short jump ve near jump ayrımı vardır. Ama kullanıcı bunu bilmek zorunda kalmamalıdır.

V3.1’de kullanıcı hep aynı syntax’ı kullanır:

:+N
::-N

Compiler/NASM gerekli jump türünü seçer.

Fakat istersek iki seviye ekleyebiliriz:

:+N     normal branch, compiler karar verir
:!+N    zorla long/near branch
:.+N    zorla short branch

Ama bu ilk V3.1 için gereksiz karmaşıklık olur. Daha doğru karar:

Kullanıcı branch uzunluğu seçmez.
Compiler ve NASM çözer.
77. Branch x64 ASM üretimi

Aktif hücre sıfır değilse ileri branch:

:+N

Byte cell için x64 mantığı:

cmp byte [r12 + rbx], 0
jne __ux_branch_target_X

Word cell:

cmp word [r12 + rbx*2], 0
jne __ux_branch_target_X

Dword cell:

cmp dword [r12 + rbx*4], 0
jne __ux_branch_target_X

Aktif hücre sıfırsa branch:

:0+N

x64:

cmp byte [r12 + rbx], 0
je __ux_branch_target_X

Koşulsuz branch:

::+N

x64:

jmp __ux_branch_target_X

Flag branch:

:C+N

x64 tarafında iki yol vardır. Eğer carry flag x64 CPU flag olarak canlı tutuluyorsa:

jc __ux_branch_target_X

Ama runtime/meta çağrıları CPU flaglerini bozabilir. Bu yüzden UXM FLAGS word tutuluyorsa daha güvenli olan şudur:

test word [ux_flags], FLAG_CARRY
jnz __ux_branch_target_X

V3.1’de daha güvenli karar:

UXM bayrakları CPU flaglerine bağlı tutulmaz.
Ayrı FLAGS word içinde tutulur.
Branch, UXM FLAGS word’e bakar.

Bu IDE ve runtime açısından daha tutarlıdır.

78. UXM flags ile x64 CPU flags ayrımı

Bu çok önemli. x64 CPU’nun kendi flagleri vardır. Ama UX-MINIMA’nın bayrakları ayrı tutulmalıdır.

Sebep:

1. Runtime çağrıları x64 CPU flaglerini bozar.
2. Meta servisler host dilde çalışır.
3. IDE interpreter x64 CPU flags kullanmaz.
4. Cross-platform davranış için UXM flags soyut olmalıdır.

Bu yüzden:

UXM FLAGS = runtime/compiler tarafından yönetilen sanal bayraklar
x64 CPU FLAGS = generated ASM’in geçici kullandığı gerçek CPU bayrakları

Branch da UXM FLAGS’e göre yapılmalıdır.

Örneğin carry branch:

mov ax, [ux_flags]
test ax, FLAG_CARRY
jnz __ux_branch_target_X
79. Branch ve status byte ilişkisi

Branch başarısız olursa hata değildir. Koşul sağlanmadıysa program normal devam eder.

Ama branch hedefi geçersizse compiler hatasıdır veya runtime hata değildir; çünkü target compile-time çözülecektir.

Hata kodları:

6 = invalid branch target

Compiler branch hedefini çözemiyorsa ASM üretmemelidir.

Normal branch çalıştığında status değişmemelidir.

Ancak IDE trace modunda branch olayı kaydedilmelidir:

{"step":120,"op":":+10","taken":true,"from":120,"to":130,"status":0}
80. Branch ve IDE trace

IDE için branch olayları çok önemlidir. Çünkü program akışı düz ilerlemez.

Trace kaydı şu bilgileri içermelidir:

step
branch opcode
condition type
condition value
taken true/false
source instruction index
target instruction index
pointer
active cell value
flags
status

Örnek JSON:

{"step":44,"op":":0+8","cond":"current_zero","current":0,"taken":true,"from":44,"to":52,"ptr":10,"flags":2,"status":0}

Bu sayede IDE branch oklarını, izleme çizgisini ve akış grafiğini gösterebilir.

81. Branch ile IF yapısı

Mevcut [ ] ile IF şöyle kuruluyordu:

flag[
p1
0
]

Branch ile IF daha farklı kurulabilir.

Örnek düşünce:

flag aktif hücrede
:0+3
p1
::+2
p2

Bu pseudo örnekte mantık şudur:

flag sıfırsa doğru bloğu atla
p1 yaz
else bloğunu atla
p2 yaz

Gerçek branch uzaklıkları instruction sayısına göre hesaplanmalıdır.

Bu, IF-ELSE kurmayı mümkün kılar. Fakat elle uzaklık saymak zor olabilir. IDE burada yardımcı olmalıdır.

82. Branch ile WHILE döngüsü

Aktif hücre sayaç olsun.

+k10
-
:-1

Bu çok basit gösterimdir ama gerçek instruction uzaklığı doğru hesaplanmalıdır. Daha açık pseudo mantık:

loop_start:
    -
    if current != 0 goto loop_start

UXM relative branch ile:

+k10
-
:-1

Burada :-1 bir önceki instruction’a döner gibi düşünülür. Fakat compiler instruction listesinde - bir instruction, branch bir instruction olduğu için hedef hesabı net olmalıdır.

Kural:

:-1 = branch instruction’dan önceki 1. instruction’a git

Yani :-1 bir önceki instruction’a döner.

83. Branch uzaklık hesabı

Instruction index mantığı:

0: +k10
1: -
2: :-1

:-1 instruction 2’den instruction 1’e gider.

:-2 instruction 2’den instruction 0’a gider.

:+1 instruction 2’den instruction 3’e gider.

Bu kural net olmalıdır:

:+N = current instruction index + N
:-N = current instruction index - N

Burada branch instruction’ın kendisi index hesabına dahildir.

Bu basit ve deterministiktir.

84. Branch ve kN macro ilişkisi

+k10 tek instruction mı, 10 instruction mı?

Bu kritik karardır.

V3.1’de kN macro artık iki farklı şekilde ele alınabilir:

1. Lexer expansion mode:
    +k10 = 10 adet + token

2. Compact instruction mode:
    +k10 = tek instruction, amount=10

Branch sistemi için compact instruction mode daha iyidir. Çünkü kullanıcı +k10 yazdığında bunu tek işlem gibi düşünür.

Önerilen V3.1 kararı:

UIR düzeyinde +k10 tek instruction olarak tutulur.
Codegen isterse add 10 üretir.
İsterse debug için 10 adıma bölebilir.

IDE step modunda iki seçenek olabilir:

macro-step: +k10 tek adım
micro-step: +k10 on adet + adımı gibi gösterilir

Branch hedefleri macro instruction seviyesinde hesaplanmalıdır.

Bu çok önemli bir düzeltmedir. Eski lexer’ın kN’i tamamen açması branch sistemi için uygun değildir.

85. Branch ve pattern bankası ilişkisi

Pattern bankası instruction sınırlarını korumalıdır. Branch hedefi olan instruction’lar optimizer barrier olur.

Örneğin:

0: +k10
1: > 
2: +
3: <
4: :-3

Branch instruction 4’ten instruction 1’e dönüyorsa, optimizer 1–3 arasını tek pattern’e indirebilir mi? Evet, ama hedef instruction 1 pattern başlangıcı olarak korunuyorsa mümkün olabilir. Hedef instruction pattern’in ortasına düşemez.

Kural:

Branch target pattern başlangıcı olabilir.
Branch target pattern ortası olamaz.

Bu compiler için önemlidir.

86. Branch ile sayı yazdırma rutini

Sayı yazdırma için bölme ve kalan gerekir. Branch sistemi bunu mümkün hale getirir.

Decimal print algoritması:

n = sayı
hundreds = 0
while n >= 100:
    n -= 100
    hundreds += 1
tens = 0
while n >= 10:
    n -= 10
    tens += 1
ones = n
print hundreds+48
print tens+48
print ones+48

Bu algoritma için:

1. karşılaştırma
2. koşullu branch
3. geri branch
4. azaltma
5. artırma

gerekir. V3.1 branch sistemi olmadan bu temiz yazılamaz. Branch sistemi ile mümkün olur.

Yine de pratik kullanım için @60 decimal print meta servisi daha iyi olacaktır. Ama eğitim amaçlı UXM decimal print rutini yazılabilir.

87. Branch ile bölme rutini

Bölme algoritması:

quotient = 0
remainder = dividend
while remainder >= divisor:
    remainder -= divisor
    quotient += 1

Bu yapı için remainder >= divisor kontrolü gerekir. UXM’de ! ve ? ile büyüktür/eşittir birleşimi kurulabilir.

Dallanma olmadan bunu yapmak çok zor olur. Branch sistemi geldikten sonra bölme rutini yazılabilir. Bu, 6502’de makine diliyle yaptığımız mantığın aynısıdır.

88. Branch ile bubble sort

Bubble sort için iç içe döngü gerekir:

outer loop
    inner loop
        compare adjacent
        if wrong order:
            swap

[ ] ile de yapılabilir ama branch ile daha assembly-benzeri ve kontrol edilebilir olur.

Gerekli yapılar:

1. dış sayaç
2. iç sayaç
3. liste pointer/index
4. compare
5. conditional branch
6. swap
7. geri branch

Bu nedenle sort rutinleri V3.1 branch sisteminden sonra gerçekçi hale gelir.

89. Branch ve safe/wild mode farkı

Safe mode:

branch target kontrol edilir
loop dengesini bozma engellenir
pattern barrier korunur
string/data içine atlama yasak
invalid branch compile error verir

Normal mode:

branch target kontrol edilir
loop dengesi için warning verilebilir
pattern barrier korunur

Wild mode:

branch target kontrolü gevşetilebilir
loop içine/dışına atlama kullanıcı sorumluluğunda olabilir
self-modifying deneyler için daha serbest davranılabilir

Ama x64 ASM üretiminde yine de NASM label üretimi tutarlı olmalıdır. Wild mode bile compiler’ın bozuk ASM üretmesi anlamına gelmemelidir.

90. Branch ve runtime memory layout değişimi

Eğer Wild mode’da bellek layout’u runtime’da değiştirilebiliyorsa, branch bundan etkilenmemelidir. Çünkü branch kod akışını değiştirir, bellek layout’u veri alanını değiştirir.

Fakat data alanından UXM kodu yorumlama gibi bir mod gelirse branch artık yorumlanan kod içinde de çalışmalıdır. Bu V3.1 ana compiler değil, interpreter/wild experiment konusudur.

Bu yüzden karar:

Compiled x64 branch:
    compile-time instruction listesine göre çalışır.

Interpreter/wild branch:
    runtime instruction stream üzerinde çalışır.

Bu iki sistem ayrı tutulmalıdır.

91. Branch komutlarının UIR temsili

Compiler source’u UIR’a çevirirken branch instruction şöyle tutulabilir:

type = BRANCH
cond = CURRENT_NONZERO / CURRENT_ZERO / ALWAYS / FLAG_SET / FLAG_CLEAR
flag = NONE / Z / C / O / S
direction = FORWARD / BACKWARD
distance = N
source_index = i
target_index = hesaplanmış

Örnek:

:+20

UIR:

{"type":"BRANCH","cond":"CURRENT_NONZERO","direction":"FORWARD","distance":20}

Örnek:

:C-8

UIR:

{"type":"BRANCH","cond":"FLAG_SET","flag":"C","direction":"BACKWARD","distance":8}

Bu UIR hem codegen hem interpreter hem IDE için ortak veri olur.

92. Branch komutları ve hata kodları

Branch ile ilgili hata kodları status tablosunda açık olmalıdır.

Önerilen branch hata kodları:

6   invalid branch target
70  branch target out of range
71  branch target inside data/string directive
72  branch target inside addressing expression
73  branch target breaks safe loop boundary
74  branch target blocked by optimizer barrier
75  invalid branch syntax
76  invalid branch flag
77  zero branch distance
78  branch target unresolved

Compiler bu hataları compile-time verir. Interpreter mode’da runtime branch hatası oluşursa status byte bu kodlardan biri olur.

93. Branch örnekleri
Örnek 1: aktif hücre sıfır değilse atla
+k1
:+2
0+k65.
0+k66.

Mantık:

aktif hücre 1 olduğu için :+2 branch alınır
A basma kısmı atlanabilir
B basılır

Gerçek hedef hesabı instruction index’e göre yapılır.

Örnek 2: aktif hücre sıfırsa atla
0
:0+2
0+k65.
0+k66.

Aktif hücre 0 olduğu için branch alınır.

Örnek 3: koşulsuz geri dön
+k5
-
::-1

Bu sonsuz veya hatalı döngüye dönüşebilir; çünkü koşulsuz geri branch vardır. Bu yüzden dikkatli kullanılmalıdır.

Örnek 4: zero flag branch
0
:Z+2
0+k65.
0+k66.

Eğer 0 işlemi zero flag set ediyorsa branch alınır.

94. Branch ve [ ] birlikte kullanılabilir mi?

Evet, kullanılabilir. Ama safe mode’da compiler kontrol etmelidir.

Örnek:

+k5[
-
:0+2
]

Bu tarz karma yapı mümkündür ama yeni başlayan için önerilmez.

Kural:

Basit döngüler için [ ] kullan.
Assembly-benzeri akış için : branch kullan.
İkisini karıştırıyorsan IDE trace ile kontrol et.
95. Branch sisteminin tasarım sonucu

V3.1 branch sistemi UX-MINIMA’yı büyük ölçüde güçlendirir. Çünkü artık şu işler mümkün hale gelir:

1. IF-ELSE benzeri akış
2. WHILE/FOR benzeri döngülerin elle kurulması
3. Bölme ve kalan algoritması
4. Decimal sayı yazdırma rutini
5. Klavyeden çok basamaklı sayı alma
6. Tablo tarama
7. Bubble sort ve diğer sıralamalar
8. Menü sistemi
9. Karar ağacı
10. 6502 benzeri assembly düşüncesi

Ama branch güçlü olduğu kadar tehlikelidir. Bu yüzden UIR, optimizer barrier, branch target kontrolü, safe/wild mode ayrımı ve IDE trace şarttır.

96. Bölüm 3 özeti

Bu bölümde : prefix ile V3.1 branch sistemini netleştirdik.

Kararlar:

1. Label yok; relative branch var.
2. Branch instruction/token index üzerinden çalışır.
3. Compiler arka planda NASM label üretir.
4. :+N aktif hücre sıfır değilse ileri gider.
5. :-N aktif hücre sıfır değilse geri gider.
6. :0+N aktif hücre sıfırsa ileri gider.
7. :0-N aktif hücre sıfırsa geri gider.
8. ::+N ve ::-N koşulsuz jump’tır.
9. :Z/:z, :C/:c, :O/:o, :S/:s flag tabanlı branch sağlar.
10. UXM flags, x64 CPU flags’ten ayrı tutulur.
11. Branch hedefleri UIR instruction sınırlarına göre hesaplanır.
12. Branch hedefleri optimizer barrier olarak korunur.
13. Safe mode’da loop/data/string içine tehlikeli branch engellenir.
14. Wild mode’da bazı kontroller gevşetilebilir.
15. IDE branch trace üretmelidir.

Bundan sonraki bölümde meta komut sistemi, @N, @#, meta frame, sabit servis numaraları, argüman/sonuç hücreleri, runtime ABI, FreeBASIC/QB64 fonksiyonlarına bağlanma ve kullanıcı tanımlı meta servis alanı yazılmalıdır.

Devam yazarsan Bölüm 4’te meta servis ve runtime ABI tasarımını tam belge olarak yazacağım.

Bu yanıtı tercih ediyorum

# UX-MINIMA x64 V3.1 Tasarım Belgesi

## Bölüm 4 — Meta Servis Sistemi, `@N`, `@#`, Runtime ABI, Komut Ayırıcı Boşluk Kuralı ve Host Fonksiyonları

## 101. Ön düzeltme: boşluk artık komut ayırıcıdır

V3.1’de boşluk karakteri artık daha ciddi ele alınmalıdır. Önceki tasarımda compiler boşlukları çoğunlukla yok sayabilirdi. Fakat adresleme modları, branch komutları, meta komutlar ve IDE/debugger katmanı geldiği için boşluk artık **komut ayırıcı** olarak kullanılmalıdır.

Bu nedenle şu yazımlar geçersiz olmalıdır:

```text
+ (T+1)
0 (T:100)
. (D:0)
```

Bunlar syntax error vermelidir.

Doğru yazım:

```text
+(T+1)
0(T:100)
.(D:0)
```

Çünkü `+(T+1)` tek bir adreslemeli komuttur. Araya boşluk girerse compiler bunu iki ayrı şey gibi görmelidir: `+` komutu ve `(T+1)` gibi tek başına kalan geçersiz adres ifadesi.

Bu kural çok önemlidir. Çünkü programcı isterse kodu yan yana yazabilir:

```text
0(T:0)+k65(T:0).(T:0)
```

İsterse boşlukla ayırabilir:

```text
0(T:0) +k65(T:0) .(T:0)
```

İsterse alt alta yazabilir:

```text
0(T:0)
+k65(T:0)
.(T:0)
```

Ama komutun kendi gövdesi parçalanamaz. Yani adresleme komutun bitişiğine yazılmalıdır.

## 102. V3.1 lexer için boşluk kuralı

Lexer şu kuralı uygulamalıdır:

```text
Boşluk, tab ve yeni satır komut ayırıcıdır.
Komut içi boşluk yasaktır.
Adresleme ifadesi komuta bitişik olmalıdır.
Meta komut numarası @ işaretine bitişik olmalıdır.
Branch gövdesi : işaretine bitişik olmalıdır.
Repeat macro kN komuta bitişik olmalıdır.
```

Geçerli:

```text
+k65
+k65(T:10)
@60
@#
:+20
:z-10
```

Geçersiz:

```text
+ k65
+k 65
+k65 (T:10)
@ 60
: +20
:z -10
```

Bu kural IDE için de iyidir. IDE formatter kodu ister tek satıra dizer, ister alt alta yazar; ama her komut atomik kalır.

## 103. Meta servis sistemi neden gerekli?

UX-MINIMA çekirdeği küçük kalmalıdır. Çekirdeğe `SIN`, `COS`, `SORT`, `PRINTNUM`, `INPUTNUM`, `MUL`, `DIV`, `MOD`, `CURSOR`, `RANDOM` gibi komutları doğrudan eklersek dil büyür ve karakterini kaybeder. Bunun yerine bu işler meta servisler üzerinden yapılmalıdır.

Meta servis sistemi, UX-MINIMA’nın host tarafa açılan kapısıdır. Host taraf FreeBASIC, QB64, QBasic tarzı runtime, daha sonra C DLL, sistem API veya IDE runtime olabilir.

Temel karar:

```text
UX-MINIMA çekirdeği küçük kalır.
Gelişmiş işler @N ve @# ile çağrılan meta servislerle yapılır.
```

Bu model 6502 dünyasındaki ROM rutinleri, KERNAL çağrıları veya işletim sistemi servisleri gibi düşünülebilir. Programcı çekirdekte kalır ama gerektiğinde hazır runtime hizmeti çağırır.

## 104. İki tür meta çağrı olacak: `@N` ve `@#`

V3.1’de meta çağrı iki biçimde olmalıdır:

```text
@N  = N numaralı sabit meta servisi çağır
@#  = aktif hücredeki değeri meta servis numarası kabul et ve onu çağır
```

Örnek:

```text
@60
```

Bu, 60 numaralı meta servisi çağırır. Eğer `@60` decimal sayı yazdırma servisi ise, ilgili değeri decimal olarak ekrana basar.

Örnek:

```text
0(T)+k60
@#
```

Burada aktif hücreye 60 yazılır. `@#` aktif hücredeki 60 değerini meta id olarak alır ve 60 numaralı servisi çalıştırır.

Bu ayrım çok önemlidir:

```text
@60 = compile-time sabit servis çağrısı
@#  = runtime dinamik servis çağrısı
```

## 105. Eski `0+k65@` sistemi yerine yeni sistem

V3’te meta çağrı şöyle düşünülmüştü:

```text
0+k65@
```

Yani aktif hücreye 65 yazılır, sonra `@` bu değeri servis id olarak kullanır. V3.1’de bu hâlâ `@#` ile yapılabilir:

```text
0+k65
@#
```

Ama sabit servis çağrısı için daha kısa ve daha okunur biçim:

```text
@65
```

olmalıdır.

Bu, hem kaynak kodu kısaltır hem de compiler’ın meta çağrısını daha iyi analiz etmesini sağlar.

## 106. Meta frame: argüman ve sonuç düzeni

Meta servisler için sabit bir çağrı sözleşmesi olmazsa sistem karışır. V3.1’de meta frame şu şekilde sabitlenmelidir:

```text
(T-2) = arg1
(T-1) = arg2
(T)   = çağrı merkezi / @# için meta id
(T+1) = result
```

Pointer meta çağrıdan önce neredeyse, çağrıdan sonra da aynı yerde kalmalıdır.

Kesin kural:

```text
Meta servis pointer’ı değiştirmez.
Meta servis stack pointer’ı değiştirmez; sadece açıkça stack servisi ise değiştirir.
Meta servis sonucu varsayılan olarak (T+1) hücresine yazar.
Meta servis hata durumunu status byte’a yazar.
Meta servis gerekli flagleri günceller.
```

Örnek: 10 + 20 toplama.

```text
0(T-2)+k10
0(T-1)+k20
@20
```

Eğer `@20 = add` ise sonuç:

```text
(T+1) = 30
```

Pointer hâlâ `(T)` üzerindedir.

## 107. Dinamik meta frame örneği: `@#`

Aynı toplama işlemi dinamik meta id ile şöyle yazılabilir:

```text
0(T-2)+k10
0(T-1)+k20
0(T)+k20
@#
```

Burada:

```text
(T-2) = 10
(T-1) = 20
(T)   = 20 yani add servis id
@#    = (T) içindeki id’yi çağır
(T+1) = 30
```

Bu sistem, fonksiyon çağrısına benzer ama çekirdeğe fonksiyon eklemez.

## 108. Meta servislerin input/output kuralları

Her meta servis için şu bilgiler belgelenmelidir:

```text
id
ad
girdi hücreleri
çıktı hücresi
status etkisi
flags etkisi
stack etkisi
pointer etkisi
cell type etkisi
signed/unsigned etkisi
endian etkisi
safe/normal/wild izin durumu
```

Örneğin:

```text
@20 ADD
input  = (T-2), (T-1)
output = (T+1)
flags  = Z, C, O, S güncellenir
status = 0 veya overflow hata kodu
pointer = değişmez
stack = değişmez
```

Bu imza tablosu olmadan meta sistemi büyüdüğünde kaos olur.

## 109. Meta servis id alanları

Meta servis numaraları sabit bölgelere ayrılmalıdır.

Önerilen alan:

```text
0-19     çekirdek runtime ve status servisleri
20-39    aritmetik ve karşılaştırma servisleri
40-59    matematik/bilimsel servisler
60-79    input/output ve decimal dönüşüm servisleri
80-99    pointer, memory ve layout servisleri
100-119  safe/normal/wild ve debug servisleri
120-159  flag, signed/unsigned, endian servisleri
160-179  FIFO/queue ve gelişmiş stack servisleri
180-199  data/table/string servisleri
200-223  sort/search/list servisleri
224-239  IDE/trace servisleri
240-255  kullanıcı/deneysel servis alanı
```

Bu alanlar sabit kalmalıdır. Böylece `@60` her zaman aynı şeyi ifade eder.

## 110. Temel meta servis tablosu

Başlangıç için önerilen servisler:

```text
@0    no-op
@1    ekran temizle
@2    cursor home
@3    random byte
@4    timer düşük byte/değer
@5    newline
@6    meta test mesajı
@7    test value 7
@8    test value 8
@9    status byte oku
@10   status byte sıfırla
@11   status byte set et
@12   son hata mesajını yazdır
```

Bu servisler runtime’ın en temel dış dünya kapısıdır.

Özellikle `@5` newline için standart olmalıdır. `.` ile CR/LF basmak mümkün olsa da taşınabilir ve okunur kullanım `@5` olmalıdır.

## 111. Aritmetik meta servisler

Aritmetik servisler:

```text
@20   ADD: arg1 + arg2
@21   SUB: arg1 - arg2
@22   MUL: arg1 * arg2
@23   DIV: arg1 / arg2
@24   MOD: arg1 mod arg2
@25   MIN: min(arg1,arg2)
@26   MAX: max(arg1,arg2)
@27   ABS: abs(arg1)
@28   NEG: -arg1
@29   CMP: genel karşılaştırma
```

Davranış:

```text
input  = (T-2), (T-1)
output = (T+1)
```

Tek argümanlı servislerde `arg1 = (T-1)` veya `arg1 = (T-2)` seçilebilir. Tutarlılık için şu karar önerilir:

```text
Tek argümanlı servislerde input = (T-1)
Çift argümanlı servislerde input = (T-2), (T-1)
Output her zaman = (T+1)
```

Örnek çarpma:

```text
0(T-2)+k6
0(T-1)+k7
@22
```

Sonuç:

```text
(T+1) = 42
```

## 112. Division by zero davranışı

`@23` ve `@24` için bölünen/bölen kontrolü yapılmalıdır.

Eğer `arg2 = 0` ise:

```text
status = 15 division by zero
result = 0
Z flag = 1
O flag = 1 veya hata flagi
```

Program bunu şöyle kontrol edebilir:

```text
@23
e
:+10
```

Yani bölme sonrası status sıfır değilse hata bloğuna gider.

## 113. Carry, overflow ve flags etkisi

Aritmetik servisler şu bayrakları güncellemelidir:

```text
Z = result == 0
S = signed yorumda result negatif mi?
C = unsigned carry/borrow var mı?
O = signed overflow var mı?
```

Bu bayraklar UXM FLAGS alanında tutulur. x64 CPU flags’e güvenilmez.

Örnek:

```text
0(T-2)+k250
0(T-1)+k10
@20
:c+20
```

Byte hücrede 250 + 10 carry üretir. `:c+20` carry set ise branch yapar.

## 114. Signed/unsigned meta servisler

Mode servisleri:

```text
@120  unsigned mode set
@121  signed mode set
@122  compare mode sorgula
```

Tek işlem compare servisleri:

```text
@130  unsigned equal
@131  unsigned greater
@132  unsigned less
@133  signed equal
@134  signed greater
@135  signed less
```

Bu servisler result hücresine 0 veya 1 yazar ve flagleri günceller.

Örnek:

```text
0(T-2)+k255
0(T-1)+k1
@131
```

Unsigned greater: 255 > 1 doğru, result 1.

```text
0(T-2)+k255
0(T-1)+k1
@134
```

Signed greater: byte yorumunda 255 = -1 kabul edilirse -1 > 1 yanlış, result 0.

## 115. Endian meta servisleri

Endian servisleri:

```text
@150  little-endian mode set
@151  big-endian mode set
@152  endian mode sorgula
@153  word -> two bytes
@154  two bytes -> word
@155  dword -> four bytes
@156  four bytes -> dword
```

Endian bayrağı sadece çok byte’lı yorumlamalarda etkili olur. Byte hücrede tek hücrelik işlem endian’dan etkilenmez. Ama word/dword parçalama veya data’dan binary değer okuma endian’a bağlıdır.

Örnek dword parçalama:

```text
(T-1) = dword değer
@155
```

Çıktı düzeni servis imzasında net olmalıdır. Öneri:

```text
@155 dword -> four bytes:
input  = (T-1)
output = (T+1),(T+2),(T+3),(T+4)
endian bayrağına göre byte sırası belirlenir
```

## 116. Matematik ve bilimsel meta servisler

Bilimsel servisler çekirdeğe komut olarak eklenmemeli, meta olarak verilmeli.

Öneri:

```text
@40   sin lookup / integer scaled sin
@41   cos lookup
@42   tan lookup
@43   hypotenuse
@44   arcsin lookup
@45   arccos lookup
@46   sqrt
@47   pow small/integer
@48   log lookup/approx
@49   exp lookup/approx
```

Bu servislerde gerçek floating point yerine başlangıçta ölçekli integer kullanılmalıdır.

Örneğin:

```text
sin(30 derece) = 50
```

100 ölçekli yorum:

```text
0 = 0.00
50 = 0.50
100 = 1.00
```

Bu UX-MINIMA için yeterince pratiktir.

## 117. Input/output meta servisleri

I/O servisleri:

```text
@5    newline
@60   decimal sayı yazdır
@61   stackTop decimal yazdır
@62   decimal sayı oku
@63   boşluk bas
@64   cursor x,y ayarla
@65   karakter/özel kullanıcı başlangıcı olabilir
@66   string/data adresinden yazdır
@67   hex sayı yazdır
@68   binary sayı yazdır
@69   input line oku
```

`@60` olmazsa olmazdır. Çünkü `.` karakter basar, sayı basmaz.

Örnek:

```text
0(T-1)+k123
@60
```

Burada `@60` hangi hücreyi yazdıracak?

Tutarlı karar gerekir. İki seçenek var:

```text
Seçenek A: @60 input = (T-1)
Seçenek B: @60 input = (T+1)
```

Bence `@60` için input `(T-1)` olmalıdır. Çünkü yazdırılacak değer argüman gibi verilir.

```text
0(T-1)+k123
@60
```

ekrana `123` yazar.

## 118. Klavyeden decimal sayı alma

`@62` decimal sayı okuma servisi olmalıdır.

Önerilen davranış:

```text
@62:
    kullanıcıdan decimal sayı okur
    sonucu (T+1) hücresine yazar
    status = 0 veya input error
    pointer değişmez
```

Örnek:

```text
s1=0,{Sayi gir: }
p1
@62
```

Sonuç `(T+1)` hücresine yazılır.

Sonucu kullanmak için:

```text
$(T+1)
```

veya:

```text
%(T)
```

ile aktif hücreye alınabilir.

## 119. Pointer ve memory meta servisleri

Pointer servisleri:

```text
@80   pointer set
@81   pointer add
@82   pointer oku
@83   pointer bounds sorgula
@84   tape size oku
@85   data size oku
@86   stack size oku
@87   cell bits oku
@88   cell bytes oku
@89   memory layout bilgisi yazdır
```

Önerilen imzalar:

```text
@80 pointer set:
input  = (T-1)
output = none
pointer = input değerine ayarlanır
status = sınır hatası varsa 10

@81 pointer add:
input = (T-1)
pointer += input
status = sınır hatası varsa 10

@82 pointer oku:
output = (T+1)
```

Burada `@80` ve `@81` pointer’ı değiştirdiği için özel servislerdir. Normal meta servislerin pointer değiştirmeme kuralının istisnasıdır. Bu istisna servis imza tablosunda açıkça yazılmalıdır.

## 120. Memory layout değiştirme servisleri

Bu servisler sadece Wild mode’da açık olmalıdır.

```text
@100  memory layout sorgula
@101  tape/data/stack layout değiştir
@102  tape/data swap
@103  data alanından UXM kodu yorumla
@104  current region executable/code-like kabul et
@105  memory snapshot al
@106  memory snapshot yükle
```

Safe ve Normal mode’da bunlar hata vermelidir:

```text
status = 23 invalid safe/wild operation
```

Bunlar BFF benzeri deneyler için kapı açar ama normal programlama için tehlikelidir.

## 121. Flag meta servisleri

Flag servisleri:

```text
@140  carry flag oku
@141  carry flag set
@142  carry flag reset
@143  overflow flag oku
@144  overflow flag set
@145  overflow flag reset
@146  zero flag oku
@147  sign flag oku
@148  aritmetik flagleri sıfırla
@149  tüm flags word oku
```

Ek mode servisleri:

```text
@120  unsigned mode set
@121  signed mode set
@150  little-endian set
@151  big-endian set
```

Flag okuma servisleri sonucu `(T+1)` hücresine yazmalıdır.

Örnek:

```text
@140
```

Carry flag değerini `(T+1)` içine yazar.

## 122. FIFO / ikinci stack servisleri

Senin önerdiğin ikinci stack veya FIFO fikri meta servis olarak desteklenmelidir. `$` ve `%` LIFO stack olarak kalmalıdır. FIFO ayrı meta servislerle yönetilmelidir.

```text
@160  FIFO push
@161  FIFO pop
@162  FIFO peek
@163  FIFO count
@164  FIFO clear
@165  stack mode LIFO sorgula/set
@166  FIFO mode sorgula/set
@167  stack/fifo durumunu yazdır
```

Benim önerim:

```text
$ ve % her zaman LIFO stack için kalır.
FIFO sadece @160-@164 servisleriyle kullanılır.
```

Çünkü aynı `$` `%` komutlarının mode’a göre değişmesi debug etmeyi zorlaştırır.

## 123. Data/table/string meta servisleri

Data alanını sadece string için değil, sayısal tablo için de kullanmak istiyoruz. Bu nedenle data servisleri gerekir:

```text
@180  data byte oku
@181  data byte yaz
@182  data cell oku
@183  data cell yaz
@184  data string yazdır
@185  data decimal digit oku
@186  data decimal string -> number
@187  number -> data decimal string
@188  data block copy
@189  data block clear
```

Örnek: `s1=0,{12345678}` içinden ilk rakamı almak.

```text
# data[0] = ASCII '1' = 49
0(T-1)+k0
@185
```

`@185` data decimal digit oku ise:

```text
input  = (T-1) data index
output = (T+1) digit value
```

Sonuç 1 olur.

## 124. Sort/search/list meta servisleri

Sıralama çekirdekte yapılabilir ama uzun olur. Bu yüzden pratik kullanım için meta servisler olmalıdır.

```text
@200  byte liste küçükten büyüğe sırala
@201  byte liste büyükten küçüğe sırala
@202  word liste küçükten büyüğe sırala
@203  word liste büyükten küçüğe sırala
@204  dword liste küçükten büyüğe sırala
@205  dword liste büyükten küçüğe sırala
@206  linear search
@207  binary search
@208  min index bul
@209  max index bul
```

Bu servislerin input çerçevesi net olmalıdır.

Öneri:

```text
(T-2) = başlangıç adresi
(T-1) = eleman sayısı
@200
(T+1) = status/result
```

Liste tape üzerinde çalışır. Data üzerinde çalışacak sürümler ayrıca gerekirse `@210+` alanına konabilir.

## 125. IDE/trace meta servisleri

IDE için bazı servisler sadece debug amaçlı olabilir:

```text
@224  trace event yaz
@225  memory dump iste
@226  tape viewer marker koy
@227  breakpoint iste
@228  step pause
@229  watch cell ekle
@230  watch cell sil
@231  flags dump
@232  stack dump
@233  data dump
```

Native compile modunda bunlar no-op veya debug runtime çağrısı olabilir. IDE/interpreter modunda aktif çalışır.

Bu servisler programın eğitim ve görselleştirme tarafını çok güçlendirir.

## 126. Kullanıcı tanımlı meta servis alanı

240–255 arası kullanıcı/deneysel servis alanı olabilir:

```text
@240-@255 = user meta services
```

Bu servisler runtime tarafında kullanıcı tarafından tanımlanabilir. Örneğin IDE veya compiler ayar dosyasında:

```text
meta 240 = custom_random
meta 241 = custom_sensor_read
meta 242 = custom_plot_bar
```

Veya FreeBASIC runtime’da tabloya eklenebilir.

Burada dikkat: Program taşınabilirliği için kullanıcı meta servislerinin imza tablosu dosyada belgelenmelidir.

## 127. Meta servis kayıt tablosu

Runtime içinde bir meta dispatch tablosu olmalıdır.

Mantık:

```text
id alınır
servis tablosunda id bulunur
servis izin modu kontrol edilir
servis çağrılır
result/status/flags güncellenir
```

Pseudo yapı:

```text
meta_table[id]:
    name
    function_pointer
    allowed_modes
    input_spec
    output_spec
    flags_policy
```

FreeBASIC/QB64 tarafında function pointer sistemi sınırlı olabilir. Bu durumda `SELECT CASE id` ile başlanabilir. Daha sonra C/DLL tarafında dispatch table yapılabilir.

## 128. Runtime ABI genişletmesi

Eski runtime çağrısı şöyle düşünülmüştü:

```text
ux_meta_call(id)
```

Bu artık yetmez. Çünkü meta servislerin tape, data, stack, flags, status, pointer, cell type bilgisine erişmesi gerekiyor.

V3.1 için önerilen ABI:

```text
ux_meta_call_ex(id, state_ptr)
```

Burada `state_ptr`, UXM çalışma durumunu gösterir.

`ux_state` yapısı şöyle olmalıdır:

```text
mem_base
mem_size
tape_offset
tape_cells
stack_offset
stack_cells
data_offset
data_cells
cell_bits
cell_bytes
pointer
stack_pointer
fifo_head
fifo_tail
fifo_count
flags_word
status_byte
mode
trace_enabled
```

Meta servis bu state üzerinden her şeye erişebilir.

## 129. x64 tarafında meta çağrı

Windows x64 ABI’de ilk argüman `RCX`, ikinci argüman `RDX` ile verilir. Bu yüzden x64 NASM çıktısı şöyle olabilir:

```asm
mov ecx, 20
lea rdx, [ux_state]
call ux_meta_call_ex
```

`@#` için:

```asm
mov ecx, dword [current_cell]
lea rdx, [ux_state]
call ux_meta_call_ex
```

Burada cell type byte/word/dword ise id uygun şekilde zero-extend edilmelidir.

## 130. Runtime register disiplini

x64 codegen şu registerları kullanıyorsa:

```text
r12 = ux_mem base
rbx = tape pointer
r13 = stack base
r14 = stack pointer
r15 = temp
```

Runtime çağrısından sonra bu registerların bozulmaması gerekir.

İki çözüm var.

Birinci çözüm: Runtime bu registerları korur. Fakat Windows x64 ABI’de bazı registerlar zaten non-volatile’dır. Yine de farklı derleyici davranışları için dikkat gerekir.

İkinci çözüm: Caller yani generated ASM çağrıdan önce/sonra state’i memory’ye yazar ve geri yükler.

V3.1 için daha güvenli karar:

```text
Pointer, stack pointer, flags, status gerçek kaynak olarak ux_state içinde tutulur.
Registerlar hız için cache gibi kullanılabilir ama meta çağrısından önce state senkronize edilir.
Meta çağrısından sonra state yeniden yüklenir.
```

Bu biraz yavaş ama doğru ve IDE dostudur.

## 131. Meta servis pointer değiştirebilir mi?

Genel kural:

```text
Meta servis pointer değiştirmez.
```

İstisnalar:

```text
@80 pointer set
@81 pointer add
@101 memory layout değiştir
@102 tape/data swap
@103 data kodu yorumla
```

Bu istisnalar imza tablosunda açıkça yazılmalıdır.

Meta servis pointer değiştirdiyse FLAGS içinde `P` bayrağı set edilebilir:

```text
FLAGS.P = pointer changed by meta
```

Program isterse bunu sorgulayabilir.

## 132. Meta servis stack değiştirebilir mi?

Genel kural:

```text
Meta servis stack değiştirmez.
```

İstisnalar:

```text
@61 stackTop decimal yazdır
@160 FIFO push
@161 FIFO pop
özel stack servisleri
```

LIFO stack `$` ve `%` ile yönetilir. Meta servislerin gelişigüzel stack değiştirmesi programı bozar. Bu yüzden her servis için stack etkisi belgelenmelidir.

## 133. Meta servis flags güncellemesi

Her servis flags güncellemez. Servisler flags davranışına göre sınıflandırılmalıdır:

```text
FLAGS_NONE      bayraklara dokunmaz
FLAGS_ARITH     Z,C,O,S günceller
FLAGS_LOGIC     Z,S günceller, C/O temizler
FLAGS_COMPARE   Z,C,S/O uygun şekilde günceller
FLAGS_STATUS    sadece status etkiler
FLAGS_CUSTOM    servis özel davranır
```

Örneğin:

```text
@20 ADD = FLAGS_ARITH
@40 SIN = FLAGS_ARITH veya FLAGS_LOGIC
@60 PRINT_DECIMAL = FLAGS_NONE
@80 POINTER_SET = FLAGS_STATUS + FLAGS.P
```

Bu kurallar belgelenmelidir.

## 134. Meta servis status davranışı

Her meta servis işlem sonunda status byte’ı güncellemelidir.

Önerilen kural:

```text
Başarılı meta servis status=0 yapar.
Hata oluşursa status uygun hata koduna set edilir.
Bazı servisler status’u koruyabilir ama bu özel olarak belgelenmelidir.
```

Bu kural programcının hata yakalamasını kolaylaştırır.

Örnek:

```text
@23
e
:+20
```

Bölme başarılıysa status 0 kalır. Sıfıra bölme varsa status 15 olur ve branch alınır.

## 135. Meta servis ve mode izinleri

Her servis hangi modda çalışabileceğini bilmelidir.

Örnek:

```text
@20 ADD:
SAFE/NORMAL/WILD

@80 POINTER_SET:
NORMAL/WILD
SAFE içinde bounds check ile izinli olabilir

@101 LAYOUT_CHANGE:
sadece WILD

@103 DATA_EXECUTE:
sadece WILD

@224 TRACE_EVENT:
IDE/TRACE mode
```

Eğer servis mevcut modda yasaksa:

```text
status = 23 invalid safe/wild operation
```

## 136. Meta servis ve cell type

Meta servisler byte/word/dword hücre tipine göre davranmalıdır.

Örneğin `@20 ADD`:

```text
byte  result 0..255
word  result 0..65535
dword result 0..4294967295
```

Overflow/wrap/check davranışı compiler/runtime ayarına göre olmalıdır.

Meta servis state içinden `cell_bits` ve `cell_bytes` bilgilerini okumalıdır.

## 137. Meta servis ve endian

Endian özellikle çok hücreli dönüşümlerde etkilidir.

Şu servisler endian bayrağına bakmalıdır:

```text
@153 word -> two bytes
@154 two bytes -> word
@155 dword -> four bytes
@156 four bytes -> dword
@186 data decimal/binary convert
@188 data block copy gerekirse
```

Basit `@20 ADD` gibi servisler endian’dan etkilenmez. Çünkü zaten hücre değeri olarak okur.

## 138. Meta servis ve signed/unsigned

Şu servisler signed/unsigned moddan etkilenir:

```text
@21 SUB flag yorumları
@23 DIV signed/unsigned bölme seçimi
@24 MOD signed/unsigned kalan seçimi
@29 CMP
@130-135 compare servisleri
```

`@23 DIV` için iki seçenek vardır:

```text
Genel mode’a göre signed/unsigned bölme
veya ayrı servisler
```

Daha net tasarım:

```text
@23 unsigned/signed mode’a göre DIV
@33 unsigned DIV
@34 signed DIV
@24 mode’a göre MOD
@35 unsigned MOD
@36 signed MOD
```

Böylece kullanıcı ister genel modla, ister doğrudan servisle çalışabilir.

## 139. Meta servis ve user-defined UXM macro

Kullanıcı UX-MINIMA kodunu meta komut gibi tanımlamak istemişti. Bu iki aşamalı düşünülmelidir.

V3.1’de:

```text
@N host runtime servisidir.
```

Yani FreeBASIC/QB64/C tarafında yazılmış servis çalışır.

İleri deneysel modda:

```text
mN={UXM kodu}
```

gibi compile-time macro meta olabilir. Ama bu V3.1’in temel zorunluluğu değildir. Çünkü runtime dynamic `@#` ile UXM macro çağırmak compiler açısından zorlaşır.

Öneri:

```text
V3.1:
    host meta services

V3.2/IDE:
    compile-time UXM macro expansion

Wild/experimental:
    data alanından UXM kodu yorumlama
```

## 140. Meta servis ve IDE trace

Her meta çağrı trace dosyasına yazılmalıdır.

Örnek JSON:

```json
{"step":51,"instr":"@20","meta_id":20,"name":"ADD","ptr":10,"arg1":6,"arg2":7,"result":13,"result_cell":11,"status":0,"flags":{"Z":0,"C":0,"O":0,"S":0}}
```

`@#` için:

```json
{"step":52,"instr":"@#","dynamic_id":22,"name":"MUL","ptr":10,"arg1":6,"arg2":7,"result":42,"result_cell":11,"status":0}
```

Bu IDE açısından çok değerlidir. Kullanıcı runtime fonksiyonunun ne aldığını ve ne döndürdüğünü görür.

## 141. Meta servis ve compile report

Compiler, kullanılan meta servisleri compile report içinde listelemelidir.

Örnek:

```json
{"meta_used":[20,22,60,120,150],"requires_runtime":["ADD","MUL","PRINT_DECIMAL","UNSIGNED_MODE","LITTLE_ENDIAN"]}
```

Böylece IDE veya build sistemi hangi runtime servislerinin gerektiğini bilir.

## 142. Meta servis ve güvenlik

Wild mode dışındaki servisler memory layout’u bozmamalıdır.

Tehlikeli servisler:

```text
pointer set
layout change
data execute
indirect memory write
stack raw write
flags raw write
status raw write
```

Bu servisler safe mode’da kapalı veya kısıtlı olmalıdır.

Meta servis çağrısından önce runtime şunları kontrol etmelidir:

```text
id geçerli mi?
servis bu modda izinli mi?
argüman adresleri geçerli mi?
result adresi yazılabilir mi?
cell type geçerli mi?
division by zero var mı?
```

## 143. Meta servislerin host tarafı

Host taraf başlangıçta FreeBASIC olabilir. Daha sonra QB64 runtime, C DLL veya başka backend olabilir.

Ama servis davranışı aynı kalmalıdır. Yani `@20` FreeBASIC runtime’da da, C runtime’da da ADD olmalıdır.

Bu yüzden meta servisler dil standardının parçası olmalıdır, sadece runtime detayı olmamalıdır.

## 144. FreeBASIC/QB64 fonksiyonlarından yararlanma

Senin dediğin gibi çekirdeğe fonksiyon yazdırmak yerine host dilin fonksiyonları kullanılmalıdır.

Örneğin:

```text
@40 sin
@41 cos
@42 tan
@46 sqrt
```

FreeBASIC runtime içinde bunlar `SIN`, `COS`, `TAN`, `SQR` gibi fonksiyonlarla yazılabilir. QB64 runtime’da da benzer fonksiyonlar vardır.

Burada sayı ölçeği net olmalıdır. Örneğin:

```text
input derece = integer
output = sin(input) * 1000
```

veya:

```text
input radyan_scaled
output scaled
```

Başlangıç için derece ve 1000 ölçekli integer daha anlaşılır olabilir.

## 145. Meta servis dokümantasyon formatı

Her servis belgede şu formatla yazılmalıdır:

```text
ID:
Ad:
Mod:
Input:
Output:
Flags:
Status:
Pointer:
Stack:
Endian:
Signed:
Açıklama:
Örnek:
```

Örnek:

```text
ID: @22
Ad: MUL
Mod: SAFE/NORMAL/WILD
Input: (T-2)=arg1, (T-1)=arg2
Output: (T+1)=arg1*arg2
Flags: Z,C,O,S güncellenir
Status: 0 veya overflow
Pointer: değişmez
Stack: değişmez
Endian: etkisiz
Signed: mode’a göre veya unsigned default
Açıklama: İki hücre değerini çarpar.
Örnek: 0(T-2)+k6 0(T-1)+k7 @22
```

Bu format kullanıcı kılavuzunda aynen kullanılmalıdır.

## 146. Meta servis çağrısında adresleme kullanılacak mı?

`@N` kendi başına frame merkezine göre çalışır. Yani `@20(T:100)` gibi bir yazım V3.1’de önerilmez.

Neden?

Çünkü meta servis frame mantığına göre çalışır. Eğer meta çağrıya ayrıca adresleme eklersen, frame merkezi mi değişiyor, meta id mi başka yerden okunuyor, result nereye yazılıyor karışır.

Bu nedenle karar:

```text
@N ve @# adresleme almaz.
Meta frame pointer’ın bulunduğu konuma göre kurulur.
```

Başka frame kullanmak istiyorsan pointer’ı oraya götürürsün veya `@80` ile pointer set edersin.

## 147. `@#` için aktif hücre değeri korunur mu?

`@#` aktif hücredeki id’yi okur. Sonucu `(T+1)` hücresine yazar. Aktif hücre yani `(T)` bozulmamalıdır.

Kesin kural:

```text
@# aktif hücredeki meta id’yi okur ama (T) değerini değiştirmez.
```

Bu sayede aynı id tekrar çağrılabilir.

## 148. Meta servis sonucu neden `(T+1)`?

Sonucu `(T+1)` hücresine yazmak mantıklıdır çünkü:

```text
(T-2), (T-1) = inputlar
(T) = çağrı merkezi / id
(T+1) = sonuç
```

Bu küçük frame, pointer merkezli düşünmeyi kolaylaştırır. Programcı çağrı sırasında pointer’ı kaybetmez.

Örneğin:

```text
0(T-2)+k6
0(T-1)+k7
@22
.(T+1)
```

Eğer sonuç 42 ise `.(T+1)` ASCII `*` basar. Decimal yazmak için:

```text
$(T+1)
%(T-1)
@60
```

veya `@60` doğrudan `(T+1)` yazacak şekilde tasarlanırsa daha kolay olur. Ama standartta `@60` input `(T-1)` alıyorsa, result önce `(T-1)` konumuna taşınmalıdır. Bu nedenle bazı I/O servislerinde input hücresi konusu ayrıca netleştirilmelidir.

## 149. `@60` için özel karar

Decimal print çok sık kullanılacağı için `@60` iki modu destekleyebilir.

Öneri:

```text
@60:
    eğer (T-1) dolu/aktif arg olarak kullanılıyorsa (T-1) yazdır
    aksi halde (T+1) yazdır
```

Ama bu belirsizdir. Daha iyi karar:

```text
@60 = (T-1) değerini decimal yazdır
@61 = (T+1) değerini decimal yazdır
@62 = stackTop decimal yazdır
@63 = aktif hücre decimal yazdır
```

Bu daha açık olur.

Güncellenmiş I/O:

```text
@60  print decimal arg cell (T-1)
@61  print decimal result cell (T+1)
@62  print decimal stackTop
@63  read decimal input -> (T+1)
@64  space
@65  cursor x,y
```

Bu şekilde karışıklık azalır.

## 150. Bölüm 4 özeti

Bu bölümde V3.1 meta servis sistemi netleştirildi.

Ana kararlar:

```text
1. Boşluk komut ayırıcıdır.
2. Komut içi boşluk syntax error verir.
3. +(T+1) geçerli, + (T+1) geçersizdir.
4. @N sabit meta servis çağrısıdır.
5. @# aktif hücredeki id ile dinamik meta servis çağrısıdır.
6. Meta frame: (T-2)=arg1, (T-1)=arg2, (T)=id/merkez, (T+1)=result.
7. Meta servis pointer’ı değiştirmez; sadece özel pointer servisleri istisnadır.
8. Meta servis stack’i değiştirmez; sadece stack/FIFO servisleri istisnadır.
9. Meta servisler status byte ve flags word ile entegre çalışır.
10. Meta servis id alanları sabit olmalıdır.
11. Aritmetik, bilimsel, I/O, pointer, endian, signed/unsigned, FIFO, data, sort ve IDE servisleri numara aralıklarına ayrıldı.
12. Runtime ABI `ux_meta_call_ex(id,state_ptr)` biçiminde genişletilmelidir.
13. Runtime state içinde memory layout, pointer, stack pointer, flags, status, cell type ve mode bilgileri olmalıdır.
14. IDE trace her meta çağrıyı JSON olarak kaydetmelidir.
15. Kullanıcı tanımlı meta servisler 240-255 alanında tutulabilir.
```

Bundan sonraki bölümde **UIR/interpreter/IDE ara katmanı, JSON trace formatı, adım adım yürütme, canlı tape-stack-data-flags görüntüleme, compile report ve test sistemi** belgelenmelidir.

Devam yazarsan Bölüm 5’i yazacağım.

# UX-MINIMA x64 V3.1 Tasarım Belgesi

## Bölüm 5 — UIR, Interpreter Katmanı, IDE Bağlantısı, JSON Trace, Compile Report ve Test Sistemi

## 151. Neden compiler yanında interpreter katmanı da gerekli?

UX-MINIMA x64 V3.1 artık sadece `.uxm` dosyasını okuyup `.asm` üreten basit bir compiler değildir. Tape, stack, data, flags, status byte, meta servisler, branch sistemi, adresleme modları ve wild mode gibi yapılar geldikçe programı sadece derlemek yetmez. Programcının kod çalışırken ne olduğunu görmesi gerekir.

Bu yüzden compiler yanında bir de **adım adım çalıştırılabilir interpreter/debug katmanı** olmalıdır.

Bu katman şu amaçlarla kullanılır:

```text
1. IDE içinde kodu adım adım çalıştırmak
2. Tape hücrelerini canlı göstermek
3. Stack/FIFO durumunu göstermek
4. Data alanını göstermek
5. Pointer konumunu göstermek
6. FLAGS word ve status byte değerlerini göstermek
7. Branch alındı mı alınmadı mı göstermek
8. Meta servis çağrılarını göstermek
9. Pattern eşleşmelerini göstermek
10. Runtime hatalarını kaynak satırına bağlamak
11. JSON trace dosyası üretmek
12. Test sisteminde beklenen/gerçek sonucu karşılaştırmak
```

Yani V3.1’de iki ayrı çalışma yolu olmalıdır:

```text
Compile yolu:
.uxm -> lexer -> UIR -> pattern optimizer -> x64 NASM -> obj/exe
Debug yolu:
.uxm -> lexer -> UIR -> interpreter -> JSON trace -> IDE görünümü
```

Bu iki yol aynı kaynak analizini paylaşmalıdır. Böylece compiler başka, interpreter başka davranmaz.

## 152. AST yerine UIR daha uygun

UX-MINIMA klasik anlamda ağaç yapılı bir dil değildir. BASIC veya Python gibi expression tree, statement tree, function tree yapısı yoktur. Daha çok ardışık komutlardan oluşur. Bu yüzden tam klasik AST yerine **UIR — UXM Intermediate Representation** daha uygundur.

UIR, açıklamalı komut akışı demektir.

Her UIR instruction şunları tutmalıdır:

```text
1. Komut türü
2. Kaynak dosyadaki konumu
3. Satır ve sütun
4. Orijinal metin
5. Macro expansion bilgisi
6. Adresleme modu
7. Branch hedefi
8. Meta servis id
9. Pattern sınıfı
10. Güvenlik modu gereksinimi
11. Hangi bellek alanına eriştiği
12. Hangi flagleri etkilediği
13. Hangi status kodunu üretebileceği
```

Örnek UIR instruction:

```json
{"id":12,"op":"+","addr":{"space":"T","mode":"relative","offset":1},"source":{"line":5,"col":1,"text":"+(T+1)"}}
```

Branch instruction:

```json
{"id":30,"op":"branch","form":":z+20","condition":"zero_set","direction":"forward","distance":20,"target_id":50,"source":{"line":9,"col":1}}
```

Meta instruction:

```json
{"id":44,"op":"meta","form":"@22","meta_id":22,"dynamic":false,"frame":{"arg1":"T-2","arg2":"T-1","result":"T+1"},"source":{"line":14,"col":1}}
```

Bu yapı hem compiler hem interpreter hem IDE için ortak dil olur.

## 153. Lexer, parser ve UIR akışı

V3.1 analiz hattı şöyle olmalıdır:

```text
1. Kaynak dosya okunur.
2. UTF-8 BOM varsa temizlenir.
3. Satır sonları normalize edilir.
4. Pragma/comment ayarları okunur.
5. Lexer komutları ayırır.
6. Komut içi boşluk hataları yakalanır.
7. Adresleme ifadeleri parse edilir.
8. Branch ifadeleri parse edilir.
9. Meta çağrılar parse edilir.
10. kN tekrar makroları işlenir.
11. UIR instruction listesi oluşturulur.
12. Branch hedefleri hesaplanır.
13. Güvenlik/mode kontrolleri yapılır.
14. Pattern optimizer sınırları işaretlenir.
15. Compile veya interpreter yolu seçilir.
```

Burada çok önemli nokta şudur: `+ (T+1)` gibi komut içi boşluklar lexer aşamasında syntax error vermelidir. Çünkü boşluk artık komut ayırıcıdır.

Geçerli:

```text
+(T+1)
```

Geçersiz:

```text
+ (T+1)
```

Bu hata UIR’e geçmeden yakalanmalıdır.

## 154. Komut ayırıcı olarak boşluk ve yeni satır

V3.1 kaynak kodu hem yan yana hem alt alta yazılabilmelidir.

Geçerli tek satır:

```text
0(T:0) +k65(T:0) .(T:0)
```

Geçerli alt alta:

```text
0(T:0)
+k65(T:0)
.(T:0)
```

Geçerli bitişik eski stil:

```text
0+k65.
```

Ama adresleme, meta, branch ve macro parçalanamaz.

Geçersiz örnekler:

```text
+ (T+1)
@ 60
: z+20
+k 65
+k65 (T:10)
```

Bu kurallar IDE formatter tarafından da korunmalıdır.

## 155. UIR instruction türleri

UIR içinde instruction türleri net olmalıdır.

Önerilen türler:

```text
OP_MOVE_RIGHT
OP_MOVE_LEFT
OP_INC
OP_DEC
OP_CLEAR
OP_PUTC
OP_GETC
OP_LOOP_BEGIN
OP_LOOP_END
OP_PUSH
OP_POP
OP_CMP_EQ
OP_CMP_GT
OP_CMP_LT
OP_AND
OP_OR
OP_XOR
OP_NOT
OP_SHL
OP_SHR
OP_STATUS_READ
OP_META_CALL
OP_BRANCH
OP_STRING_DEF
OP_STRING_PRINT
OP_COMMENT
OP_NOP
```

Branch ve meta özel instruction olarak tutulmalıdır. Çünkü bunlar tek karakterli basit komut gibi değildir.

Adresleme alanı her uygun instruction’a bağlanır:

```json
{"op":"OP_INC","addr":{"space":"T","kind":"relative","offset":1}}
```

Adresleme yoksa default:

```json
{"op":"OP_INC","addr":{"space":"T","kind":"current","offset":0}}
```

## 156. Interpreter çalışma durumu: UXM State

Interpreter ve runtime aynı state modelini kullanmalıdır. Bu çok önemlidir. Aksi halde IDE’de görülen davranış ile native exe davranışı ayrılabilir.

UXM state şu alanları tutmalıdır:

```text
mem_base
mem_size
tape_offset
tape_cells
stack_offset
stack_cells
data_offset
data_cells
cell_bits
cell_bytes
pointer
stack_pointer
fifo_head
fifo_tail
fifo_count
flags_word
status_byte
mode
overflow_mode
endian_mode
signed_mode
trace_enabled
step_counter
instruction_pointer
```

Interpreter belleği gerçek dizi olarak tutabilir:

```text
ux_mem[0..65535]
```

Bu belleğin içinde tape, stack ve data alanları layout ayarına göre bölünür.

## 157. Interpreter adım mantığı

Interpreter her adımda tek UIR instruction çalıştırır.

Genel döngü:

```text
while ip < instruction_count:
    instr = UIR[ip]
    execute(instr)
    write_trace_event()
    if branch_taken:
        ip = target_ip
    else:
        ip = ip + 1
```

Her instruction çalıştıktan sonra trace yazılmalıdır. Trace açık değilse sadece son durum tutulabilir. IDE step mode’da trace açık olmalıdır.

## 158. JSON trace neden gerekli?

IDE ile compiler/interpreter arasındaki iletişim için dosya tabanlı JSON trace çok uygundur. Çünkü IDE hangi dilde yazılırsa yazılsın JSON okuyabilir.

Trace şunları sağlar:

```text
1. Her adımın kaydı
2. Hangi komut çalıştı?
3. Pointer neredeydi?
4. Hangi hücre değişti?
5. Stack değişti mi?
6. Data değişti mi?
7. Flags değişti mi?
8. Status değişti mi?
9. Branch alındı mı?
10. Meta servis ne yaptı?
11. Hata oluştu mu?
```

Bu trace dosyası sonradan da incelenebilir. Yani IDE kapansa bile programın çalışma kaydı kalır.

## 159. JSON trace satır formatı

Trace dosyası iki şekilde olabilir:

```text
1. JSON array
2. JSON Lines / NDJSON
```

Bence büyük programlar için **JSON Lines** daha iyidir. Her satır ayrı JSON nesnesi olur.

Örnek:

```json
{"step":1,"ip":0,"op":"OP_CLEAR","source":"0(T:0)","ptr":0,"status":0,"flags":0,"writes":[{"space":"T","index":0,"old":0,"new":0}]}
```

Örnek increment:

```json
{"step":2,"ip":1,"op":"OP_INC","source":"+k65(T:0)","ptr":0,"status":0,"flags":0,"writes":[{"space":"T","index":0,"old":0,"new":65}]}
```

Örnek output:

```json
{"step":3,"ip":2,"op":"OP_PUTC","source":".(T:0)","ptr":0,"read":{"space":"T","index":0,"value":65},"output":"A","status":0}
```

Meta örneği:

```json
{"step":20,"ip":19,"op":"OP_META_CALL","source":"@22","meta_id":22,"name":"MUL","ptr":10,"args":[6,7],"result":42,"result_cell":{"space":"T","index":11},"status":0,"flags":{"Z":0,"C":0,"O":0,"S":0}}
```

Branch örneği:

```json
{"step":30,"ip":29,"op":"OP_BRANCH","source":":z+12","condition":"zero_set","taken":true,"target_ip":41,"flags":{"Z":1,"C":0,"O":0,"S":0},"status":0}
```

Bu format IDE için çok okunabilir olur.

## 160. Trace snapshot ve delta

Her adımda tüm 64 KB belleği JSON’a yazmak çok şişkin olur. Bu yüzden trace satırında sadece değişen hücreler yazılmalıdır.

Buna delta trace denir.

Örnek:

```json
{"step":7,"writes":[{"space":"T","index":5,"old":12,"new":13}]}
```

Ama IDE başlarken ilk state snapshot’a ihtiyaç duyar.

Başlangıç snapshot:

```json
{"type":"snapshot","cell_bits":8,"tape_cells":32768,"stack_cells":8192,"data_cells":24576,"pointer":0,"stack_pointer":0,"flags":0,"status":0}
```

Sonra delta eventler gelir.

IDE isterse trace’i baştan oynatarak her adımı tekrar kurabilir.

## 161. Memory viewer için ayrı dump dosyaları

Trace dışında IDE için zaman zaman memory dump üretilebilir.

Örnek dosyalar:

```text
program.trace.ndjson
program.compile.json
program.memory_tape.json
program.memory_stack.json
program.memory_data.json
program.asm
```

Ama her adımda tüm memory dump üretilmemeli. Kullanıcı isterse snapshot alınmalı.

Meta servis:

```text
@225 = memory dump iste
```

IDE/interpreter bu isteği görünce dump dosyası yazabilir.

## 162. Compile report dosyası

Her derlemede bir compile report üretilmelidir.

Önerilen dosya:

```text
program.compile.json
```

İçeriği:

```json
{"source":"program.uxm","version":"3.1","mode":"normal","cell_bits":8,"memory":{"tape_kb":32,"stack_kb":8,"data_kb":24},"instruction_count":120,"patterns_used":18,"meta_used":[20,22,60],"warnings":[],"errors":[]}
```

Pattern raporu:

```json
{"patterns":[{"pattern":"+k65","class":"repeat_arith","count":1,"asm":"add byte [r12+rbx],65"},{"pattern":"[->+<]","class":"move_add_clear","count":3}]}
```

Branch raporu:

```json
{"branches":[{"source":":z+12","from_ip":20,"target_ip":32,"safe":true},{"source":"::-40","from_ip":90,"target_ip":50,"safe":true}]}
```

Bu rapor IDE ve test sistemi için çok değerlidir.

## 163. Pattern optimizer trace’i

Pattern optimizer kaynak kodu sessizce değiştirmemeli. Hangi patternin nerede uygulandığı kaydedilmelidir.

Örnek:

```json
{"pattern_event":{"ip_start":10,"ip_end":74,"pattern":"+ repeated 65","replacement":"ADD_CELL 65","class":"repeat_arith"}}
```

Bu IDE’de şöyle gösterilebilir:

```text
+k65 -> add byte [current],65
```

Eğer branch hedefi pattern sınırı oluşturduysa raporda görünmeli:

```json
{"optimizer_note":"pattern split because branch target at ip 40"}
```

Bu, debug açısından çok önemlidir.

## 164. Interpreter ile native output tutarlılığı

V3.1’de en önemli kalite kuralı şudur:

```text
Interpreter sonucu ile native x64 sonucu aynı olmalıdır.
```

Bunun için her instruction’ın iki uygulaması aynı spec’ten beslenmelidir:

```text
UIR execute spec -> interpreter
UIR codegen spec -> x64 emitter
```

Örneğin `+(T+1)` için interpreter:

```text
tape[pointer+1] += 1
```

x64 codegen:

```asm
inc byte [r12 + rbx + 1]
```

Bu ikisinin aynı bayrak/status davranışı üretmesi gerekir.

## 165. Test sistemi neden şart?

UX-MINIMA V3.1 karmaşık hale geliyor. Bayrak, endian, meta, branch, adresleme, pattern optimizer ve wild mode geldikçe küçük değişiklikler eski davranışı bozabilir. Bu yüzden test sistemi şarttır.

Testler sadece “program çalıştı mı?” dememeli; beklenen tape, stack, data, flags, status ve output değerlerini kontrol etmelidir.

Örnek test tanımı:

```json
{"name":"print_A","source":"0+k65.","expect":{"output":"A","status":0,"tape":{"0":65}}}
```

Branch testi:

```json
{"name":"branch_zero_forward","source":"0:0+2+k65.+k66.","expect":{"output":"B","status":0}}
```

Meta testi:

```json
{"name":"meta_mul","source":"0(T-2)+k6 0(T-1)+k7 @22","expect":{"tape_relative":{"1":42},"status":0}}
```

## 166. Test dosya yapısı

Önerilen test klasörü:

```text
tests/
  basic/
    test_001_print_A.uxm
    test_002_loop_star.uxm
  addressing/
    test_020_T_plus_1.uxm
    test_021_T_abs.uxm
    test_022_D_abs.uxm
  stack/
    test_040_lifo.uxm
    test_041_stack_underflow.uxm
  flags/
    test_060_zero_flag.uxm
    test_061_carry_flag.uxm
    test_062_overflow_flag.uxm
  endian/
    test_080_little_word.uxm
    test_081_big_word.uxm
  meta/
    test_100_add.uxm
    test_101_mul.uxm
    test_102_div_zero.uxm
  branch/
    test_120_branch_forward.uxm
    test_121_branch_back.uxm
    test_122_flag_branch.uxm
  pattern/
    test_140_repeat_opt.uxm
    test_141_branch_pattern_boundary.uxm
  wild/
    test_200_indirect.uxm
```

Her `.uxm` yanında `.expect.json` olabilir.

Örnek:

```text
test_100_add.uxm
test_100_add.expect.json
```

## 167. Test runner davranışı

Test runner şu işleri yapmalıdır:

```text
1. Test kaynak dosyasını oku.
2. Compiler parse/UIR aşamasından geçir.
3. Interpreter modda çalıştır.
4. Trace üret.
5. Beklenen output/status/memory/flags ile karşılaştır.
6. İstenirse native ASM üret.
7. NASM + runtime ile exe üret.
8. Native çıktıyı interpreter çıktısıyla karşılaştır.
9. PASS/FAIL raporu yaz.
```

Bu özellikle compiler geliştirme sürecinde şarttır.

## 168. IDE mimarisi

IDE şu bileşenlerden oluşmalıdır:

```text
1. Kaynak kod editörü
2. UIR/token viewer
3. Pattern viewer
4. ASM viewer
5. Tape viewer
6. Stack viewer
7. FIFO viewer
8. Data viewer
9. Flags/status paneli
10. Meta call paneli
11. Branch paneli
12. Output console
13. Trace timeline
14. Memory layout editor
15. Test runner paneli
```

Bu IDE basit başlasa bile bu paneller hedeflenmelidir.

## 169. IDE’de tape viewer

Tape viewer hücreleri tablo gibi göstermelidir.

Örnek:

```text
Index   Value   ASCII   Mark
0       65      A       pointer
1       10      LF
2       0       .
3       255     .
```

Pointer hücresi farklı renkle gösterilir. Değişen hücreler son adımda işaretlenir.

Cell type byte/word/dword seçimine göre değer gösterimi değişir.

Gösterim modları:

```text
decimal
hex
binary
ASCII
signed
unsigned
```

## 170. IDE’de stack viewer

Stack viewer LIFO yapıyı göstermelidir.

```text
SP=3
top -> 67 C
       66 B
       65 A
```

FIFO varsa ayrı panelde:

```text
FIFO count=3
front -> 10
         20
back  -> 30
```

Stack underflow/overflow olursa status paneli bunu göstermelidir.

## 171. IDE’de data viewer

Data viewer stringleri ve ham değerleri göstermelidir.

Örnek:

```text
Data index  Value  ASCII
0           85     U
1           88     X
2           77     M
3           0      NUL
100         65     A
```

String tanımları ayrıca listelenmelidir:

```text
s1 @ data[0] = "UXM"
s2 @ data[100] = "A harfi"
```

## 172. IDE’de flags/status paneli

Flags paneli canlı olmalıdır.

```text
Z zero      0
C carry     1
O overflow  0
S sign      0
U unsigned  1
M signed    0
E endian    little
W wild      0
B bounds    1
T trace     1
```

Status:

```text
status = 0 OK
```

Hata olursa:

```text
status = 15 Division by zero
```

## 173. IDE’de branch paneli

Branch paneli tüm branch instructionları listelemelidir.

```text
IP   Source   Condition      Target   Last taken
20   :z+12    zero set       32       yes
55   ::-20    always         35       yes
70   :c+8     carry set      78       no
```

Bu, relative branch mantığını kullanıcıya öğretir.

## 174. IDE’de meta paneli

Meta paneli kullanılan servisleri göstermelidir.

```text
ID   Name          Calls   Last args   Last result
20   ADD           3       10,20       30
22   MUL           1       6,7         42
60   PRINT_DEC     4       123         -
```

Meta servis hatası varsa burada gösterilir.

## 175. IDE’de ASM viewer

Compiler’ın ürettiği x64 NASM kodu IDE’de görüntülenmelidir. Her ASM bloğu kaynak komuta bağlanmalıdır.

Örnek:

```text
UXM: +(T+1)
ASM:
inc byte [r12 + rbx + 1]
```

Meta çağrı:

```text
UXM: @22
ASM:
mov ecx,22
lea rdx,[ux_state]
call ux_meta_call_ex
```

Bu compiler öğrenmek isteyen kullanıcı için çok değerlidir.

## 176. IDE’de memory layout editor

Program başında memory layout ayarlanabilir:

```text
Tape  = 32 KB
Stack = 8 KB
Data  = 24 KB
Cell  = byte
Mode  = normal
Endian = little
Compare = unsigned
```

Bu ayarlar kaynak dosyaya pragma/comment olarak yazılabilir.

Örnek:

```text
#uxm v3.1
#mode normal
#cell byte
#memory tape=32k stack=8k data=24k
#endian little
#compare unsigned
#overflow wrap
#bounds on
```

## 177. Pragma ayarları runtime’da değiştirilmeyecek

Çalışma modu program başında belirlenmelidir. Özellikle safe/normal/wild mode runtime’da değişmemelidir.

Kural:

```text
#mode safe/normal/wild compile-time ayardır.
Program çalışırken mode değişmez.
```

Endian, signed/unsigned, carry/overflow gibi bayraklar meta servislerle değişebilir. Ama çalışma modu değişmemelidir. Çünkü compiler güvenlik ve codegen kararlarını buna göre verir.

## 178. Compile-time pragma ile runtime flag farkı

Pragma:

```text
#mode normal
#cell byte
#memory tape=32k stack=8k data=24k
```

Bunlar compile-time ve runtime layout kararlarıdır.

Meta flag:

```text
@120 unsigned mode set
@121 signed mode set
@150 little endian
@151 big endian
```

Bunlar program sırasında değişebilir.

Ayrım net olmalıdır:

```text
Mode/layout/cell type = program başında sabit
Signed/endian/flags = runtime değişebilir
```

Cell type çalışma sırasında değiştirilecekse bu sadece wild mode deneysel servisle yapılmalıdır. Normal modda cell type sabit kalmalıdır.

## 179. Interpreter wild mode

Wild mode’da interpreter çok dikkatli olmalıdır ama kullanıcıya izin vermelidir.

Wild mode özellikleri:

```text
indirect adresleme
layout değiştirme
data alanından kod yorumlama
raw stack/data/tape erişimi
flags/status doğrudan yazma
```

Interpreter wild mode’da her tehlikeli işlem için trace’e uyarı yazmalıdır:

```json
{"step":90,"warning":"wild indirect write","addr":5000,"value":123}
```

IDE de bunu kırmızı/sarı işaretlemelidir.

## 180. Native compiler ve wild mode

Wild mode native x64 üretimde daha tehlikelidir. Çünkü interpreter’da kontrol kolaydır; native kodda hatalar programı bozabilir.

Bu yüzden V3.1’de wild mode için iki seçenek olmalıdır:

```text
1. Wild interpreter only
2. Wild native compile with explicit allow flag
```

Örneğin compiler komutu:

```text
uxmc program.uxm --mode wild --allow-native-wild
```

Aksi halde wild program sadece interpreter/IDE modunda çalıştırılır.

## 181. Hata ve uyarı raporu

Compiler hataları ve uyarıları ayrı tutulmalıdır.

Runtime status byte program çalışırken oluşan durumu gösterir. Compiler hataları kaynak analizinde oluşur.

Compile report:

```json
{"errors":[{"code":"E034","message":"addressing expression separated by whitespace","line":10,"col":2}],"warnings":[{"code":"W002","message":"branch leaves loop block","line":20}]}
```

Runtime trace:

```json
{"step":40,"status":15,"message":"division by zero"}
```

Bu ayrım çok önemlidir.

## 182. Hata kodu alanları

Runtime status byte 0–255 idi. Compiler hata kodları ise daha geniş metinsel olabilir:

```text
E001 syntax error
E002 invalid token
E003 invalid addressing
E004 invalid branch
E005 invalid meta id
E006 memory layout error
E007 pattern conflict
E008 unsafe operation in safe mode
```

Runtime status byte kısa ve program tarafından okunabilir kalmalıdır. Compiler hataları daha açıklamalı olabilir.

## 183. Testlerde trace kullanımı

Test runner başarısız olduğunda trace dosyasının son birkaç adımını göstermelidir.

Örnek FAIL raporu:

```text
FAIL test_102_div_zero
Expected status: 15
Actual status: 0
Last steps:
38 @23 DIV arg1=10 arg2=0 result=0 status=0
39 e status read -> 0
```

Bu sayede hata hızlı bulunur.

## 184. Testlerde native/interpreter karşılaştırması

Her test için iki sonuç alınabilir:

```text
Interpreter result
Native result
```

Bunlar karşılaştırılır.

Karşılaştırılacak alanlar:

```text
stdout
status
selected tape cells
selected data cells
stack depth
flags
exit code
```

Eğer interpreter ve native farklıysa compiler/codegen hatası vardır.

## 185. Minimal test beklenen dosyası

Örnek `.expect.json`:

```json
{"output":"A","status":0,"flags":{"Z":0},"tape":{"0":65},"stack_depth":0}
```

Daha gelişmiş:

```json
{"output":"42","status":0,"tape_relative":{"1":42},"meta_used":[22,61],"trace_must_contain":[{"op":"OP_META_CALL","meta_id":22}]}
```

## 186. Dokümantasyon üretimi

Compiler kendi komut tablosundan dokümantasyon üretebilmelidir. Özellikle meta servis tablosu büyüdükçe elle belge güncellemek zorlaşır.

Kaynak tablo:

```text
meta_services.json
commands.json
errors.json
patterns.json
```

Bunlardan şu belgeler üretilebilir:

```text
pck.md
meta_reference.md
error_codes.md
addressing_modes.md
test_catalog.md
```

Bu IDE içinde de yardım sistemi olarak kullanılabilir.

## 187. Pattern bankası ve test ilişkisi

Her pattern için en az bir test olmalıdır.

Örnek pattern:

```text
[->+<]
```

Test:

```text
+k10[->+<]
```

Beklenen:

```json
{"tape":{"0":0,"1":10}}
```

Repeat pattern:

```text
+k65
```

Beklenen:

```json
{"tape":{"0":65}}
```

Branch boundary pattern testi de olmalıdır. Çünkü optimizer branch hedeflerini bozamaz.

## 188. UIR dosyası saklanmalı mı?

Evet, opsiyonel olarak saklanmalıdır.

Dosya:

```text
program.uir.json
```

Bu dosya IDE’nin kaynak kodu tekrar parse etmeden program yapısını görmesini sağlar.

İçerik:

```json
{"version":"3.1","instructions":[{"id":0,"op":"OP_CLEAR","addr":{"space":"T","kind":"absolute","index":0}},{"id":1,"op":"OP_INC","amount":65,"addr":{"space":"T","kind":"absolute","index":0}}]}
```

Bu dosya compiler debug için de yararlıdır.

## 189. ASM map dosyası

UXM komutları ile ASM satırları arasında map dosyası olmalıdır.

Dosya:

```text
program.asmmap.json
```

Örnek:

```json
{"uxm_ip":10,"source_line":5,"asm_lines":[120,121,122],"op":"OP_META_CALL","text":"@22"}
```

Bu IDE’de UXM komutuna tıklayınca ASM karşılığını göstermeyi sağlar.

## 190. Runtime state dump

Program sonunda runtime state dump alınabilir.

Dosya:

```text
program.final_state.json
```

Örnek:

```json
{"pointer":0,"stack_pointer":0,"status":0,"flags":0,"tape_sample":{"0":65,"1":0,"2":0},"output":"A"}
```

Test runner bunu kullanabilir.

## 191. IDE için komut çalıştırma protokolü

IDE compiler/interpreter ile dosya tabanlı konuşabilir.

Örnek komut dosyası:

```json
{"command":"run","source":"program.uxm","mode":"trace","max_steps":10000,"breakpoints":[20,55],"watch":["T:0","T:1","F","E"]}
```

Cevap:

```json
{"status":"ok","trace":"program.trace.ndjson","compile_report":"program.compile.json"}
```

Step komutu:

```json
{"command":"step","session":"abc123","count":1}
```

Cevap:

```json
{"status":"ok","step":51,"ip":20,"pointer":3,"flags":0,"status_byte":0}
```

Bu ileride IDE entegrasyonunu kolaylaştırır.

## 192. Breakpoint sistemi

Breakpoint UIR instruction id üzerinden kurulmalıdır.

```text
breakpoint ip=50
```

Kaynak satır breakpoint’i UIR id’ye çevrilir.

Breakpoint geldiğinde interpreter durur ve IDE’ye durum döner.

Trace event:

```json
{"event":"breakpoint","ip":50,"step":120}
```

## 193. Watch sistemi

IDE kullanıcıya şu hücreleri izletebilmelidir:

```text
T:0
T+1
D:100
S:0
SP
P
F
E
```

Watch formatı adresleme modlarıyla uyumlu olmalıdır.

Örnek:

```json
{"watch":{"T:0":65,"T+1":10,"F":4,"E":0}}
```

## 194. Step limit ve sonsuz döngü koruması

Interpreter sonsuz döngüye girebilir. Bu yüzden step limit olmalıdır.

Varsayılan:

```text
max_steps = 100000
```

Aşılırsa:

```text
status = runtime warning veya interpreter halt
```

Trace:

```json
{"event":"step_limit_exceeded","max_steps":100000}
```

IDE kullanıcıya “devam et” seçeneği verebilir.

## 195. Deterministik random

Testlerde random servisleri deterministik olmalıdır. `@3 random byte` normal çalışmada rastgele üretebilir ama test modunda seed sabit olmalıdır.

Meta servis:

```text
@3 random byte
```

Test pragma:

```text
#seed 12345
```

Böylece test sonuçları tekrarlanabilir.

## 196. Standart dosya uzantıları

Önerilen uzantılar:

```text
.uxm        kaynak kod
.asm        NASM çıktı
.obj        NASM obj
.exe        final program
.uir.json   UIR ara temsil
.trace.ndjson adım trace
.compile.json compile raporu
.expect.json test beklentisi
.final_state.json final runtime state
.asmmap.json UXM->ASM haritası
```

Bu standart IDE ve test sistemi için önemlidir.

## 197. Geliştirme sırası

V3.1’i geliştirirken sıra şöyle olmalıdır:

```text
1. Lexer/parser ve boşluk kuralı
2. UIR instruction formatı
3. Adresleme parser
4. State modeli
5. Interpreter temel komutları
6. JSON trace
7. Meta servis dispatch
8. Branch parser ve interpreter
9. x64 codegen güncellemesi
10. Pattern optimizer sınırları
11. Compile report
12. Test runner
13. IDE protokol dosyaları
```

Önce interpreter gelirse IDE ve test çok kolaylaşır. Sonra x64 codegen aynı UIR’den üretilebilir.

## 198. Kullanıcı kılavuzunda anlatılması gerekenler

PCK ve kullanıcı kılavuzu V3.1’e göre güncellenmelidir.

Yeni bölümler:

```text
1. Boşluk komut ayırıcıdır
2. Adresleme için () kullanılır
3. [] sadece döngüdür
4. : branch prefix’tir
5. @N ve @# meta çağrıdır
6. e status byte okur
7. FLAGS ve status sistemi
8. Safe/Normal/Wild mode
9. UIR/interpreter/IDE trace
10. Test yazma
```

Özellikle yeni başlayan için şu cümle vurgulanmalıdır:

```text
Komutun içinde boşluk olmaz; komutlar arasında boşluk olur.
```

## 199. Bölüm 5 özeti

Bu bölümde V3.1’in IDE ve interpreter altyapısını belirledik.

Ana kararlar:

```text
1. Compiler yanında adım adım interpreter katmanı olacak.
2. AST yerine UIR kullanılacak.
3. UIR açıklamalı instruction stream olacak.
4. Interpreter ve native compiler aynı UIR’den beslenecek.
5. JSON Lines trace üretilecek.
6. Compile report JSON üretilecek.
7. Pattern optimizer olayları raporlanacak.
8. Branch ve meta çağrılar trace içinde ayrıntılı görünecek.
9. IDE tape, stack, FIFO, data, flags, status, branch, meta ve ASM panelleri gösterecek.
10. Test sistemi interpreter ve native çıktıları karşılaştıracak.
11. Watch, breakpoint, step limit ve deterministic random desteklenecek.
12. Standart dosya uzantıları belirlendi.
```

## 200. V3.1 belgesinin mevcut durumu

Şu ana kadar V3.1 tasarımında beş ana bölüm tamamlandı:

```text
Bölüm 1: Çekirdek kararlar, flags, status, signed/unsigned, endian, pattern, mode
Bölüm 2: Adresleme modları, tape/data/stack/pointer erişimi
Bölüm 3: Branch/jump sistemi, : prefix, flag branch, hedef güvenliği
Bölüm 4: Meta servis sistemi, @N, @#, runtime ABI, servis tablosu
Bölüm 5: UIR, interpreter, IDE, JSON trace, compile report, test sistemi
```

Bundan sonra yazılması gereken son büyük bölüm, **V3.1 Nihai Standart Özeti ve Uygulama Planı** olmalıdır. Orada tüm kararlar tek tabloda toplanmalı, zorunlu özellikler ve ileri/opsiyonel özellikler ayrılmalı, compiler dosya mimarisi, runtime dosya mimarisi ve geliştirme yol haritası netleştirilmelidir.

Devam yazarsan Bölüm 6’da nihai standart özetini ve uygulama planını yazacağım.

Haklısın Mete abi; burada eksik olan şey şu ayrımın açık yazılmamasıydı:

```text
0(T-2)+k10
0(T-1)+k20
0(T)+k20
@#
```

Bu yazımda **pointer hücre hücre gezmiyor**. Bu, Brainfuck yürüyüş tarzı değil; **adreslemeli 6502 tarzı erişim**. Yani pointer bir “frame merkezi”nde duruyor, komutlar onun çevresindeki hücrelere doğrudan erişiyor.

Senin dediğin şu yazım ise BF/cursor tarzı yürüyüştür:

```text
0+k10 > 0+k20 > 0+k20 @#
```

Bu da doğru bir stil olur. Burada pointer gerçekten hücre hücre ilerler. İki stil farklıdır, ikisi de gerekli.

Ama şu yazım:

```text
0(T-2)+k10 >
0(T-1)+k20 >
0(T)+k20
@# >
```

dikkatli kullanılmazsa frame’i bozar. Çünkü ilk `>` sonrası pointer değişir; artık `(T-1)` eski merkeze göre değil, yeni pointer’a göre hesaplanır. Yani adreslemeli frame yazarken `>` kullanmak çoğu zaman hata olur.

Resmi ayrım şöyle olmalı:

```text
BF tarzı:
Komut aktif hücrede çalışır, > ve < ile gerçekten yürürsün.

Adreslemeli tarz:
Pointer frame merkezinde sabit kalır, (T-2), (T-1), (T+1) gibi hücrelere doğrudan erişirsin.
```

Bu, komut stokunu heba etmek değil. Tam tersine `>` `<` hâlâ tarama, dizi üzerinde gezinme, doğal BF döngüsü, veri akışı ve pointer tabanlı algoritmalar için gereklidir. Adresleme modları ise sürekli ileri geri gidip gelmeyi azaltır.

Aşağıda Bölüm 6’yı bu düzeltmelerle yazıyorum.

# UX-MINIMA x64 V3.1 Tasarım Belgesi

## Bölüm 6 — Nihai Standart Özeti, Programlama Stilleri, Flag Kuralları, Matematik Ölçeği, Macro Sistemi ve Uygulama Planı

## 201. V3.1’in temel felsefesi

UX-MINIMA x64 V3.1, iki düşünce biçimini birlikte taşımalıdır. Birincisi Brainfuck tarzı pointer yürütme modelidir. Bu modelde programcı aktif hücre üzerinde işlem yapar, `>` ve `<` ile fiziksel olarak hücreler arasında gezer. İkincisi 6502 tarzı adreslemeli erişim modelidir. Bu modelde pointer bir merkez gibi durur, komutlar `(T+1)`, `(T-2)`, `(T:100)`, `(D:0)` gibi adresleme ifadeleriyle farklı hücrelere doğrudan erişir.

Bu iki model birbirinin düşmanı değildir. Tam tersine V3.1’in gerçek gücü bunları birlikte kullanmasından gelir.

Brainfuck tarzı şudur:

```text
0+k10 > 0+k20 > 0+k20 @#
```

Bu kodda pointer gerçekten hücre hücre ilerler. Eğer başlangıçta pointer `tape[0]` üzerindeyse, sonunda pointer `tape[2]` üzerindedir. Bu durumda `@#` çalıştığında meta frame şöyle olur:

```text
(T-2) = tape[0] = 10
(T-1) = tape[1] = 20
(T)   = tape[2] = 20 meta id
(T+1) = tape[3] sonuç hücresi
```

Adreslemeli tarz ise şudur:

```text
0(T-2)+k10
0(T-1)+k20
0(T)+k20
@#
```

Bu kodda pointer hiç hareket etmez. Programcı pointer’ın zaten frame merkezinde olduğunu varsayar. Mesela pointer `tape[10]` üzerindeyse:

```text
(T-2) = tape[8]
(T-1) = tape[9]
(T)   = tape[10]
(T+1) = tape[11]
```

Yani bu yazım “otomatik oraya gidiyor” gibi görünür ama aslında gitmez; compiler hedef adresi doğrudan hesaplar. Bu 6502’de `STA $1000` yazmaya benzer. İşlem yapılır ama akümülatör veya programcı pointer’ı o adrese “taşınmış” sayılmaz.

## 202. `>` ve `<` komutları heba edilmiyor

Adresleme modları geldikten sonra `>` ve `<` gereksiz hale gelmez. Bunlar hâlâ dilin en temel komutlarındandır.

`>` ve `<` şu işler için gereklidir:

```text
1. BF tarzı saf pointer programlama
2. Dizi/tape üzerinde tarama
3. Doğal [ ] döngüleriyle hücre hücre gezinme
4. Biyolojik dizi, protein dizisi, tape simülasyonu
5. Input buffer üzerinde ilerleme
6. String veya byte akışı işleme
7. Wild/BFF benzeri modellerde hareketli head davranışı
```

Adresleme modları ise şu işler için gereklidir:

```text
1. Frame tabanlı meta çağrı
2. Komşu hücrelere pointer’ı bozmadan erişme
3. Mutlak tape/data erişimi
4. 6502 tarzı register/zero-page benzeri düzen
5. Daha okunur arithmetic/meta kodu
6. IDE/debug sırasında pointer stabilitesi
```

Bu nedenle iki stil resmi olarak belgelenmelidir:

```text
Cursor Style:
> ve < ile yürürsün.

Addressed Style:
() adresleme ile hedef hücreyi seçersin, pointer sabit kalır.
```

## 203. Komut içi boşluk yasağı kesin kuraldır

V3.1’de boşluk komut ayırıcıdır. Bu nedenle komut içi boşluk syntax error verir.

Geçerli:

```text
+(T+1)
0(T:100)
.(D:0)
@60
:+20
+k65(T:10)
```

Geçersiz:

```text
+ (T+1)
0 (T:100)
. (D:0)
@ 60
: +20
+k65 (T:10)
```

Programcı isterse komutları yan yana yazar:

```text
0(T:0)+k65(T:0).(T:0)
```

İsterse boşlukla ayırır:

```text
0(T:0) +k65(T:0) .(T:0)
```

İsterse alt alta yazar:

```text
0(T:0)
+k65(T:0)
.(T:0)
```

Ama bir komutun gövdesi parçalanmaz.

## 204. Meta frame iki stilde de kurulabilir

Meta frame resmi olarak şöyledir:

```text
(T-2) = arg1
(T-1) = arg2
(T)   = meta id veya çağrı merkezi
(T+1) = result
```

Adreslemeli yazım:

```text
0(T-2)+k10
0(T-1)+k20
0(T)+k20
@#
```

Cursor/BF yazım:

```text
0+k10 > 0+k20 > 0+k20 @#
```

Bu iki yazım aynı frame mantığına ulaşabilir ama başlangıç pointer konumu farklı düşünülür. Adreslemeli yazımda pointer zaten merkezde durur. Cursor yazımda pointer argümanlardan merkeze doğru yürür.

Bu ayrım kullanıcı kılavuzunda örneklerle anlatılmalıdır. Yoksa programcı “neden `>` yok?” diye haklı olarak karışıklık yaşar.

## 205. Adreslemeli komuttan sonra `>` kullanmanın etkisi

Şu yazım:

```text
0(T-2)+k10 >
0(T-1)+k20 >
0(T)+k20
@#
```

ilk bakışta mantıklı görünür ama dikkatli olunmalıdır. Çünkü `>` pointer’ı değiştirir. Pointer değişince sonraki `(T-1)`, `(T)` ve `(T+1)` ifadelerinin referans merkezi de değişir.

Örnek: başlangıç pointer `p=10` olsun.

İlk satır:

```text
0(T-2)+k10
```

`tape[8] = 10` yapar.

Sonra `>` çalışır, pointer `p=11` olur.

İkinci satır:

```text
0(T-1)+k20
```

artık `tape[10] = 20` yapar. Eski frame’e göre `tape[9]` beklenirken, pointer değiştiği için hedef değişmiştir.

Bu nedenle adreslemeli frame yazarken `>` `<` genellikle kullanılmaz. Eğer kullanılacaksa, programcı pointer merkezinin değiştiğini bilmelidir.

## 206. V3.1 resmi programlama stilleri

V3.1 kılavuzunda üç stil tanımlanmalıdır.

Birinci stil: saf cursor style.

```text
0+k10 > 0+k20 > 0+k20 @#
```

Bu stil Brainfuck’e en yakındır.

İkinci stil: addressed frame style.

```text
0(T-2)+k10
0(T-1)+k20
0(T)+k20
@#
```

Bu stil 6502 adresleme mantığına yakındır.

Üçüncü stil: mixed style.

```text
> > 
0(T-2)+k10
0(T-1)+k20
0(T)+k20
@#
< <
```

Burada pointer önce bir frame merkezine taşınır, sonra adreslemeli frame kullanılır, sonra geri dönülür.

Bu üç stil de geçerlidir. IDE, hangi stilin kullanıldığını görsel olarak gösterebilir.

## 207. Hiperbolik fonksiyonlar meta servis tablosuna eklenmelidir

Önceki tabloda trigonometrik servisler vardı:

```text
@40 sin
@41 cos
@42 tan
@43 hypotenuse
@44 arcsin
@45 arccos
@46 sqrt
```

Buna hiperbolik fonksiyonlar da eklenmelidir:

```text
@47  sinh
@48  cosh
@49  tanh
@52  asinh
@53  acosh
@54  atanh
```

`@43 hypotenuse` kalmalıdır. Çünkü bu trigonometrik/hendese hesaplarda çok yararlıdır.

Önerilen bilimsel meta alanı:

```text
@40  sin
@41  cos
@42  tan
@43  hypotenuse
@44  arcsin
@45  arccos
@46  sqrt
@47  sinh
@48  cosh
@49  tanh
@52  asinh
@53  acosh
@54  atanh
@55  log
@56  exp
@57  pow
@58  degrees_to_radians_scaled
@59  radians_to_degrees_scaled
```

`@50` ve `@51` daha önce sort için ayrılmıştı; bu yüzden bilimsel servislerde 50–51’i kullanmamak daha temiz olur.

## 208. Trigonometrik sayı ölçeği cell type’a bağlı olmalıdır

Önceki anlatımda bir yerde 100, başka yerde 1000 ölçeği geçti. Bu kafa karıştırır. V3.1 standardında bu net olmalıdır.

Senin önerin mantıklı:

```text
BYTE  scale = 100
WORD  scale = 1000
DWORD scale = 10000
```

Bu durumda:

```text
sin(30°) = 0.5
BYTE  sonuç = 50
WORD  sonuç = 500
DWORD sonuç = 5000
```

Fakat sin/cos/tan negatif değer de üretebilir. Byte modunda negatif değer konusu dikkat ister. İki yol vardır.

Birinci yol signed yorum:

```text
BYTE signed scale 100:
-100..100 arası değer signed byte olarak yorumlanır.
```

Bu durumda byte hücrede `-50` değeri teknik olarak 206 gibi saklanır ama signed yorumla -50 kabul edilir.

İkinci yol biased yorum:

```text
BYTE biased scale 100:
0 gerçek -100
100 gerçek 0
200 gerçek +100
```

Bu daha görsel olabilir ama aritmetik için karışık olur.

Resmi öneri:

```text
Trig/hyperbolic servisleri signed mode’a saygı duyar.
BYTE scale = 100
WORD scale = 1000
DWORD scale = 10000
Negatif sonuçlar signed yorumla döndürülür.
Unsigned mode’da negatif sonuç oluşursa status uyarısı verilir veya wrap edilir.
```

Bence bu en temiz karar. Çünkü signed/unsigned bayrak sistemimiz zaten var.

## 209. Tangent ve hiperbolik fonksiyonlarda overflow kuralı

`tan`, `sinh`, `cosh`, `atanh` gibi fonksiyonlar taşmaya çok açıktır. Bu yüzden bilimsel meta servislerde overflow davranışı net olmalıdır.

Kural:

```text
Sonuç hücre tipinin kapasitesini aşıyorsa:
status = 13 arithmetic overflow
O flag = 1
C flag = uygun şekilde set edilir
result = overflow mode’a göre wrap veya clamp
```

Burada iki davranış olabilir:

```text
overflow wrap:
sonuç hücreye sığacak şekilde sarar.

overflow check/clamp:
sonuç maksimum/minimum değere kırpılır veya 0 yazılır; status hata verir.
```

Bilimsel servislerde bence `check/clamp` daha güvenlidir. Çünkü `tan(90)` gibi bir durumda wrap sessizce anlamsız değer üretir.

Öneri:

```text
Bilimsel meta servislerde varsayılan: overflow check + status.
Wild mode’da wrap serbest olabilir.
```

## 210. Meta servis flags güncelleme kuralları

Meta servislerin flags davranışı resmi olarak sınıflandırılmalıdır. Aksi halde branch sistemi güvenilir olmaz.

UXM FLAGS alanındaki temel bayraklar:

```text
Z = zero
C = carry / no-borrow / unsigned compare flag
O = signed overflow
S = sign
U = unsigned mode
M = signed mode
E = endian
W = wild mode
B = bounds check
T = trace/debug
P = pointer changed
R = runtime error
```

Her meta servis şu flag policy sınıflarından birine sahip olmalıdır:

```text
FLAGS_NONE
FLAGS_ARITH_ADD
FLAGS_ARITH_SUB
FLAGS_ARITH_MUL
FLAGS_ARITH_DIV
FLAGS_LOGIC
FLAGS_COMPARE
FLAGS_SHIFT
FLAGS_STATUS
FLAGS_POINTER
FLAGS_CUSTOM
```

## 211. FLAGS_NONE

Bu servisler flags değiştirmez.

Örnek:

```text
@5 newline
@60 print decimal
@64 cursor
@12 hata mesajı yazdır
```

Kural:

```text
Z,C,O,S değişmez.
Status hata yoksa 0 olabilir.
```

Bu servisler hesap sonucu üretmediği için branch kararlarını bozmamalıdır.

## 212. FLAGS_ARITH_ADD

Toplama servisleri:

```text
@20 ADD
```

Kurallar:

```text
result = arg1 + arg2
Z = result == 0
S = result sign bit set mi?
C = unsigned carry out oluştu mu?
O = signed overflow oluştu mu?
```

Byte örnek:

```text
250 + 10 = 260
byte result = 4
C = 1
O = signed yoruma göre hesaplanır
```

Signed overflow örneği byte signed:

```text
100 + 50 = 150
signed byte aralığı -128..127
O = 1
```

## 213. FLAGS_ARITH_SUB

Çıkarma servisleri:

```text
@21 SUB
```

6502 ruhuna yakın olması için C flag şu şekilde tanımlanmalıdır:

```text
C = 1 ise borrow yok
C = 0 ise borrow var
```

Kurallar:

```text
result = arg1 - arg2
Z = result == 0
S = result sign bit set mi?
C = unsigned arg1 >= arg2 ise 1, değilse 0
O = signed overflow oluştu mu?
```

Bu karar önemlidir. Böylece `:c` ve `:C` branchleri 6502’deki `BCS/BCC` mantığına benzer.

## 214. FLAGS_ARITH_MUL

Çarpma servisleri:

```text
@22 MUL
```

Kurallar:

```text
result = arg1 * arg2
Z = result == 0
S = result sign bit set mi?
C = unsigned sonuç hücre kapasitesini aştı mı?
O = signed sonuç hücre kapasitesini aştı mı?
```

Byte modda:

```text
20 * 20 = 400
byte kapasite 255
C = 1
```

Signed modda signed aralık da kontrol edilir.

## 215. FLAGS_ARITH_DIV

Bölme servisleri:

```text
@23 DIV
@24 MOD
```

Kurallar:

```text
arg2 == 0 ise:
    status = 15 division by zero
    Z = 1
    O = 1
    C = 1
    result = 0

arg2 != 0 ise:
    result = arg1 / arg2 veya arg1 MOD arg2
    Z = result == 0
    S = result sign bit set mi?
    C = 0
    O = 0
```

Signed/unsigned mod bölmenin yorumunu etkiler.

## 216. FLAGS_LOGIC

Bitwise servisler ve çekirdek bitwise komutları:

```text
&
|
^
~
```

Kurallar:

```text
Z = result == 0
S = sign bit set mi?
C = 0
O = 0
```

Logic işlemler carry/overflow üretmez. Bu yüzden temizlemek daha deterministik olur.

## 217. FLAGS_SHIFT

Shift komutları:

```text
{
}
```

Kurallar:

```text
SHL:
    C = dışarı atılan en yüksek bit
    result = value << 1
    Z = result == 0
    S = sign bit
    O = signed overflow yorumu, gerekiyorsa set

SHR:
    C = dışarı atılan en düşük bit
    result = value >> 1
    Z = result == 0
    S = sign bit
    O = 0
```

Signed arithmetic shift ileride ayrı servis olabilir. Mevcut `}` logical shift right olarak kalmalıdır.

## 218. FLAGS_COMPARE

Karşılaştırma komutları ve compare meta servisleri:

```text
?
!
;
@29 CMP
@130-@135 compare servisleri
```

Resmi karar:

```text
Karşılaştırma flags’i arg1 - arg2 mantığıyla üretilir.
```

Kurallar:

```text
Z = arg1 == arg2
C = unsigned arg1 >= arg2 ise 1, değilse 0
S = signed farkın sign biti
O = signed çıkarma overflow’u
```

Boolean sonuç ayrıca hedef hücreye veya `(T+1)` sonucuna yazılır.

Örneğin `!` için:

```text
result = arg1 > arg2 ? 1 : 0
flags = arg1 - arg2 karşılaştırma flags’i
```

Bu sayede eşitlik için `:z`, eşit değil için `:Z`, unsigned küçük için `:C`, unsigned büyük/eşit için `:c` kullanılabilir.

## 219. FLAGS_STATUS

Status servisleri:

```text
@9 status oku
@10 status sıfırla
@11 status set et
e
```

Kurallar:

```text
Z = status == 0
S = status sign bit, genelde kullanılmaz
C/O değişmez veya 0 yapılır
```

Bence status okuma sonrası `Z` güncellenmelidir. Çünkü hata kontrolü kolaylaşır:

```text
e
:Z+10
```

Burada `:Z` zero clear demektir; status 0 değilse hata vardır.

Ama aktif hücre branch de kullanılabilir:

```text
e
:+10
```

## 220. FLAGS_POINTER

Pointer servisleri:

```text
@80 pointer set
@81 pointer add
@82 pointer read
```

Kurallar:

```text
@80/@81 pointer başarılı değişirse:
    P = 1
    status = 0
    Z = pointer == 0
    S = 0
    C/O = 0

pointer sınır dışı ise:
    status = 10
    R = 1
```

`@82 pointer read` pointer değiştirmez; sonucu `(T+1)` yazar.

## 221. User-defined UXM macro artık V3.1 kapsamına alınmalı

Önceki öneride UXM macro’yu ileri sürüme bırakmıştım. Senin kararına göre bunu V3.1’de, baştan syntax varsa desteklemeliyiz. Bence bu yapılabilir ama iki tür macro’yu ayırmak gerekir.

Birinci tür: compile-time UXM macro.

```text
m65={UXM kodu}
```

Sonra:

```text
@65
```

görülünce compiler bunu host meta servis gibi değil, tanımlı UXM macro olarak ele alabilir.

İkinci tür: host meta servis.

```text
@20
@60
@120
```

Bunlar FreeBASIC/QB64/C runtime servisidir.

Çakışma olursa öncelik kuralı şarttır.

## 222. Meta id çakışma kuralı

Eğer kullanıcı `m65={...}` tanımladıysa ve aynı zamanda `@65` host servis alanındaysa ne olacak?

Önerilen kural:

```text
0-239 arası sistem/standart host meta servisleridir.
240-255 kullanıcı macro/meta alanıdır.
```

Ama kullanıcı 65 istiyorsa?

Sen kullanıcıya serbestlik istiyorsun. O zaman mode’a göre kural koyabiliriz:

```text
SAFE/NORMAL:
    0-239 sistem servisleri korunur.
    Kullanıcı macro 240-255 arası tanımlanır.

WILD:
    Kullanıcı isterse sistem meta id üstüne yazabilir.
```

Bu iyi bir denge olur.

Örnek safe kullanım:

```text
m240={+k10.}
@240
```

Wild kullanım:

```text
#mode wild
m65={+k65.}
@65
```

Burada `@65` artık kullanıcı macro olabilir.

## 223. UXM macro tanım syntax’ı

Önerilen syntax:

```text
mN={UXM kodu}
```

Örnek:

```text
m240={0+k65.}
@240
```

Bu `A` basar.

Macro içinde boşluk komut ayırıcı olarak kullanılabilir:

```text
m240={0+k65 .}
```

Ama komut içi boşluk yine yasaktır.

Geçersiz:

```text
m240={+ (T+1)}
```

Geçerli:

```text
m240={+(T+1)}
```

## 224. UXM macro çalıştırma modeli

İki seçenek vardır.

Birinci seçenek inline expansion:

```text
@240
```

compile-time’da `m240` içeriğiyle değiştirilir.

Avantaj:

```text
Hızlıdır.
Native x64 codegen kolaydır.
Pattern optimizer macro içini görebilir.
```

Dezavantaj:

```text
Recursive macro risklidir.
@# ile runtime dinamik çağrı zorlaşır.
```

İkinci seçenek interpreter-call macro:

`@240` runtime’da macro instruction listesine girer ve sonra geri döner.

Avantaj:

```text
@# ile dinamik çağrı mümkün olur.
IDE’de fonksiyon gibi izlenebilir.
```

Dezavantaj:

```text
Native codegen zorlaşır.
Call stack gerekir.
```

V3.1 için önerim:

```text
NORMAL mode:
    UXM macro compile-time inline expansion.

WILD/IDE mode:
    UXM macro interpreter-call olarak da çalışabilir.
```

Böylece ikisi de desteklenir.

## 225. UXM macro recursion kuralı

Macro kendi kendini çağırırsa sonsuz genişleme olabilir.

Safe/Normal mode:

```text
Recursive macro yasak.
Macro expansion depth sınırı var.
```

Önerilen sınır:

```text
macro_depth_max = 32
```

Wild mode:

```text
Recursive macro izinli olabilir ama step limit zorunludur.
```

## 226. `@#` ile UXM macro çağrısı

Dinamik meta çağrı `@#`, aktif hücredeki id’ye bakar.

Eğer id bir host servis ise host servis çalışır. Eğer id bir UXM macro ise macro çalışır.

Dispatch sırası:

```text
1. Kullanıcı macro tablosunda id var mı?
2. Mode izin veriyor mu?
3. Yoksa host meta servis tablosuna bak.
4. Hiçbiri yoksa status = 5 invalid meta id.
```

Safe/Normal mode’da sistem id koruma kuralı uygulanır.

Wild mode’da kullanıcı macro host servis üstüne yazabilir.

## 227. Macro ve pointer davranışı

Host meta servislerde pointer genelde değişmez. UXM macro ise normal UXM kodudur; içinde `>` `<` varsa pointer değişebilir.

Bu yüzden macro tanımı için iki seçenek olmalıdır:

```text
mN={...}       normal macro, pointer değişebilir
mfN={...}      framed macro, girişte pointer kaydedilir, çıkışta geri alınır
```

Ama `mfN` yeni syntax getirir. Basitlik için başlangıçta şu kural daha iyi:

```text
UXM macro normal kod gibi çalışır.
Pointer değiştirirse değiştirir.
Programcı sorumludur.
```

IDE macro sonunda pointer değişimini gösterebilir.

Host meta servislerde ise pointer değişmez kuralı korunur.

## 228. Macro ve flags/status davranışı

UXM macro içindeki komutlar flags/status ne yapıyorsa aynen yapar. Macro bitince son komutun bıraktığı flags/status geçerlidir.

Host meta servislerde flags policy önceden bellidir. UXM macro’da bu doğal yürütme sonucudur.

Bu belgede açık yazılmalıdır:

```text
Host @N servisleri imza tablosuna göre flags günceller.
UXM macro @N çağrıları, macro içindeki son çalıştırılan komutların bıraktığı flags/status ile biter.
```

## 229. Macro ve adresleme

Macro içinde adresleme kullanılabilir.

Örnek:

```text
m240={0(T-2)+k10 0(T-1)+k20 @20}
```

Bu macro çağrıldığı noktadaki pointer merkezine göre çalışır. Bu çok güçlüdür. Çünkü macro, frame-relative kod gibi davranabilir.

Bu, küçük fonksiyon benzeri yapılar için idealdir.

## 230. Macro ve güvenlik

Safe mode’da macro şu kontrollerden geçmelidir:

```text
1. Syntax geçerli mi?
2. Branch hedefleri geçerli mi?
3. Loop dengesi doğru mu?
4. Mode dışı adresleme var mı?
5. Macro recursion var mı?
6. Sistem meta id üstüne yazılmış mı?
```

Wild mode’da çoğu serbest olabilir ama syntax yine geçerli olmalıdır.

Senin dediğin gibi:

```text
Syntax varsa ve UXM kod çalışıyorsa macro çalışır.
```

Bu, Wild mode için resmi kural olabilir.

## 231. V3.1 feature sınıfları

V3.1’de özellikleri üç sınıfa ayırmak gerekir.

Olmazsa olmaz:

```text
Çekirdek 27 komut
Adresleme ()
Branch :
Meta @N/@#
Status e
Flags
Safe/Normal/Wild mode
UIR/interpreter
JSON trace
x64 NASM codegen
```

Güçlü standart:

```text
Meta servis tablosu
Endian/signed/unsigned servisleri
Carry/overflow/zero/sign flags
Decimal print/input
Pointer servisleri
Data/table servisleri
UXM macro mN={...}
```

Deneysel ama V3.1 içinde:

```text
Wild mode memory layout değişimi
Indirect adresleme
FIFO servisleri
Data’dan UXM kod yorumlama
User macro sistem id override
```

Bunlar ayrı sürüm değil, aynı V3.1 içinde mode’a bağlı olmalıdır.

## 232. Nihai komut ve sembol tablosu

V3.1 sembol rolleri:

```text
>      pointer sağa
<      pointer sola
+      artır
-      azalt
0      sıfırla
.      karakter bas
,      karakter oku
[      loop begin
]      loop end
$      push
%      pop
?      eşit karşılaştır
!      büyük karşılaştır
;      küçük karşılaştır
&      AND
|      OR
^      XOR
~      NOT
@N     sabit meta/macro çağrı
@#     dinamik meta/macro çağrı
sN     string tanımla
pN     string bas
mN     UXM macro tanımla
kN     tekrar/immediate miktar
#      yorum/pragma
:      branch prefix
{      SHL
}      SHR
e      status byte oku
( )    adresleme
```

## 233. Nihai adresleme özet tablosu

```text
(T)        aktif tape hücresi
(T+N)      pointer + N
(T-N)      pointer - N
(T:N)      mutlak tape hücresi
(D:N)      mutlak data hücresi
(S:N)      stack hücresi
(SP)       stack top
(P)        pointer değeri
(E)        status byte
(F)        flags word
(*T)       aktif hücredeki değeri tape adresi say
(*(T+N))   T+N hücresindeki değeri tape adresi say
```

Safe/Normal/Wild mode bu adreslerin hangisine izin verileceğini belirler.

## 234. Nihai branch özet tablosu

```text
:+N     current != 0 ise ileri
:-N     current != 0 ise geri
:0+N    current == 0 ise ileri
:0-N    current == 0 ise geri
::+N    koşulsuz ileri
::-N    koşulsuz geri
:z+N    zero flag set ise ileri
:z-N    zero flag set ise geri
:Z+N    zero flag clear ise ileri
:Z-N    zero flag clear ise geri
:c+N    carry flag set ise ileri
:c-N    carry flag set ise geri
:C+N    carry flag clear ise ileri
:C-N    carry flag clear ise geri
:o+N    overflow flag set ise ileri
:o-N    overflow flag set ise geri
:O+N    overflow flag clear ise ileri
:O-N    overflow flag clear ise geri
:s+N    sign flag set ise ileri
:s-N    sign flag set ise geri
:S+N    sign flag clear ise ileri
:S-N    sign flag clear ise geri
```

## 235. Nihai meta/macro dispatch kuralı

`@N` veya `@#` çağrısında dispatch sırası:

```text
1. UXM macro tablosunda id var mı?
2. Mode buna izin veriyor mu?
3. Varsa UXM macro çalıştır.
4. Yoksa host meta servis tablosuna bak.
5. Host servis varsa çalıştır.
6. Hiçbiri yoksa status = 5 invalid meta id.
```

Safe/Normal mode’da sistem id koruması olabilir. Wild mode’da kullanıcı sistem id üstüne yazabilir.

## 236. Geliştirme uygulama planı

V3.1’i kodlarken sıra şöyle olmalıdır:

```text
1. Lexer boşluk/komut ayırıcı kuralı
2. UIR instruction modeli
3. Adresleme parser
4. State/flags/status modeli
5. Interpreter temel komutlar
6. JSON trace
7. Branch parser/interpreter
8. Meta servis dispatch
9. UXM macro parser
10. Macro inline/interpreter-call sistemi
11. x64 NASM codegen
12. Pattern optimizer
13. Compile report
14. Test runner
15. IDE protokol dosyaları
```

Bence özellikle interpreter önce yazılmalıdır. Çünkü IDE, test ve dil davranışı orada netleşir. Sonra x64 codegen daha güvenli yazılır.

## 237. Eleştirel sonuç

Senin “acaba `>` basmamız gerekmez miydi?” sorunu çok yerinde. Çünkü bu dilin iki ruhu var. Eğer sadece adresleme kullanırsak Brainfuck ruhu zayıflar. Eğer sadece `>` `<` kullanırsak 6502 tarzı pratik adresleme gücü kaybolur.

En iyi çözüm ikisini de resmi yapmak:

```text
Pointer yürütme = dilin BF ruhu
Adresleme = dilin 6502/x64 gücü
```

Bu sayede UX-MINIMA x64 V3.1 hem eğitimsel kalır hem de ciddi algoritmalar yazılabilir hale gelir.

Nihai karar şu olmalı:

```text
Adresleme modu pointer’ı hareket ettirmez.
> ve < pointer’ı hareket ettirir.
Meta frame adresleme ile kurulabilir.
Aynı frame cursor style ile de kurulabilir.
İki stil de standarttır.
```

Bu ayrım kullanıcı kılavuzunda en başlarda anlatılmalıdır.

Haklısın Mete abi. Bu üç noktayı **V3.1 standardında düzeltmek gerekir**.

# V3.1 Tasarım Düzeltmeleri

## 1. Signed / unsigned için iki bayrak olmamalı

Önceki tasarımda şunu yazmıştım:

```text
U = unsigned mode
M = signed mode
```

Bu gerçekten hata üretir. Çünkü aynı anda ikisi de 1 olabilir, ikisi de 0 olabilir, runtime bunu kontrol etmek zorunda kalır. Gereksiz karmaşıklık.

Doğru tasarım tek bayrak olmalı:

```text
SGN = signed mode flag
```

Kural:

```text
SGN = 0  unsigned mode
SGN = 1  signed mode
```

Bu yeterlidir.

Güncellenmiş FLAGS taslağı şöyle olmalı:

```text
bit 0   Z      zero flag
bit 1   C      carry flag
bit 2   O      overflow flag
bit 3   S      sign flag
bit 4   SGN    signed mode flag, 0=unsigned, 1=signed
bit 5   END    endian flag, 0=little-endian, 1=big-endian
bit 6   WILD   wild mode aktif bilgisi, runtime’da değişmez
bit 7   BND    bounds check aktif
bit 8   TRC    trace/debug aktif
bit 9   FIFO   FIFO yardımcı kuyruk aktif/var
bit 10  ERR    runtime error present
bit 11  DIRTY  data/memory modified
bit 12  PCHG   pointer changed by özel servis
bit 13  RSV1   reserved
bit 14  RSV2   reserved
bit 15  RSV3   reserved
```

Böylece signed/unsigned karmaşası biter.

Meta servisler de şöyle güncellenmeli:

```text
@120  unsigned mode set  -> SGN = 0
@121  signed mode set    -> SGN = 1
@122  signed mode sorgula -> result = SGN
```

Yani `@122` artık 0 veya 1 döndürür:

```text
0 = unsigned
1 = signed
```

Bu daha sağlam.

---

## 2. Kullanıcı meta servisleri 128 üstü olmalı

Evet, bunu değiştirmemek daha doğru. Meta ID alanı şöyle sabitlenmeli:

```text
0-127     standart sistem/host meta servisleri
128-255   kullanıcı tanımlı meta servisler ve UXM macro alanı
```

Böylece sistem servisleriyle kullanıcı macro’ları birbirine karışmaz.

Kural:

```text
@0 - @127    standart runtime/host servisleridir.
@128 - @255  kullanıcı servisleri veya UXM macro servisleridir.
```

Eğer kullanıcı `m20={...}` gibi sistem alanına macro tanımlamaya çalışırsa:

```text
Normal mode:
    hata verir veya tanımı reddeder.

Wild mode:
    yine varsayılan olarak uyarı/hata versin; sistem servis üstüne yazma özel pragma isterse açılabilir.
```

Bence burada senin dediğin gibi iç yapıyı karıştırmayalım. Sadece kontrol ve hata olsun.

Önerilen hata:

```text
status = 5   invalid meta id / protected meta id
```

Compiler tarafı için:

```text
E_META_PROTECTED_ID
```

Örnek geçerli:

```text
m128={0+k65.}
@128
```

Örnek geçersiz:

```text
m60={0+k65.}
```

Çünkü `@60` standart decimal print alanındadır.

Böylece sistem sade kalır.

---

## 3. `mfN` framed macro şimdilik gereksiz

Önce `mfN={...}` gibi “pointer’ı girişte kaydet, çıkışta geri al” tipi bir framed macro önermiştim. Ama senin dediğin daha doğru: Bu dilde programcı zaten pointer yönetimini öğrenmeli. Pointer’ı macro içinde değiştiriyorsa, geri almak da programcının sorumluluğu olmalı.

Yani V3.1’de sadece şu yeterli:

```text
mN={...}
```

Kural:

```text
UXM macro normal UXM kodu gibi çalışır.
Pointer değiştirirse değiştirir.
Stack değiştirirse değiştirir.
Flags değiştirirse değiştirir.
Status değiştirirse değiştirir.
Geri almak programcının sorumluluğundadır.
```

Bu dilin karakterine daha uygun.

Örnek:

```text
m128={0+k65.}
@128
```

Bu `A` basar.

Pointer değiştiren macro:

```text
m129={>+<}
@129
```

Burada macro kendi içinde pointer’ı sağa götürüp artırır, sonra geri döndürür. Bu düzgün macro’dur.

Ama şu macro:

```text
m130={>+}
@130
```

pointer’ı sağda bırakır. Bu hata değildir. Programcı bunu bilerek yapıyorsa geçerlidir.

Bu kural sade ve güçlü.

---

# Güncellenmiş resmi macro kuralı

V3.1 için şöyle yazalım:

```text
mN={UXM kodu}
```

Burada:

```text
N = 128..255 arası olmalıdır.
Macro içeriği normal UXM kodudur.
Macro çağrıldığında normal kod gibi çalışır.
Pointer korunmaz.
Stack korunmaz.
Flags korunmaz.
Status korunmaz.
Programcı sorumludur.
```

Çağrı:

```text
@128
```

veya dinamik çağrı:

```text
0+k128
@#
```

`@#` için dispatch sırası:

```text
1. ID 128..255 aralığında kullanıcı macro tablosunda var mı?
2. Varsa macro çalışır.
3. Yoksa host meta servis tablosuna bakılır.
4. Hiçbiri yoksa status = 5 invalid meta id.
```

Ama standart host servisler 0–127 arasında kalacağı için çakışma azalır.

---

# Düzeltilmiş dispatch kuralı

Önceki dispatch sırasını şöyle düzeltelim:

```text
@N veya @# çağrıldığında:

1. id 0..127 arasındaysa:
       standart host/runtime meta servis tablosuna bakılır.
       yoksa status = 5.

2. id 128..255 arasındaysa:
       önce kullanıcı UXM macro tablosuna bakılır.
       varsa macro normal UXM kodu gibi çalışır.
       yoksa kullanıcı host servis tablosuna bakılır.
       o da yoksa status = 5.

3. id hücre tipine göre 0..255 dışına taşıyorsa:
       status = 5 veya id maskelenir; safe/normal modda hata tercih edilir.
```

Bu daha net.

---

# Güncellenmiş kısa standart

```text
SGN flag:
    0 = unsigned
    1 = signed

END flag:
    0 = little-endian
    1 = big-endian

Meta ID:
    0-127   sistem/host servisleri
    128-255 kullanıcı macro/servis alanı

Macro:
    mN={...}
    N = 128..255
    normal UXM kodu gibi çalışır
    pointer/stack/flags koruma otomatik yapılmaz
```

Bence bu düzeltmelerle V3.1 daha temiz oldu. Özellikle signed/unsigned için tek bayrak kararı çok iyi; iki bayrak gerçekten ileride bela çıkarırdı.
