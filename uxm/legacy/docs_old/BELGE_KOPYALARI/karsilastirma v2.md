Aşağıda **UX-MINIMA V2 komut setini** toparladım. Bu listeye `?`, `!`, `^` karşılaştırma komutlarını da dahil ettim.

# UX-MINIMA V2 Komutları

| Komut | Adı              | Görevi                                                                                                                    |
| ----- | ---------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `>`   | Pointer sağa     | Aktif tape hücresinden bir sonraki hücreye geçer.                                                                         |
| `<`   | Pointer sola     | Aktif tape hücresinden bir önceki hücreye geçer.                                                                          |
| `+`   | Artır            | Aktif hücre değerini 1 artırır.                                                                                           |
| `-`   | Azalt            | Aktif hücre değerini 1 azaltır.                                                                                           |
| `0`   | Sıfırla          | Aktif hücreyi 0 yapar.                                                                                                    |
| `.`   | Karakter bas     | Aktif hücre değerini karakter/ASCII olarak ekrana basar.                                                                  |
| `,`   | Karakter oku     | Klavyeden bir karakter alır ve aktif hücreye yazar.                                                                       |
| `[`   | Döngü/koşul başı | Aktif hücre 0 ise `]` sonrasına atlar; 0 değilse bloğa girer.                                                             |
| `]`   | Döngü sonu       | İlgili `[` noktasına geri döner. Aktif hücre 0 olana kadar döngü sürer.                                                   |
| `$`   | Push             | Aktif hücre değerini UX-MINIMA’nın kendi user stack alanına atar.                                                         |
| `%`   | Pop              | UX user stack’ten son değeri alır ve aktif hücreye yazar.                                                                 |
| `?`   | Eşit mi?         | Stack’teki son değer ile aktif hücreyi karşılaştırır. Eşitse aktif hücreye `1`, değilse `0` yazar.                        |
| `!`   | Büyük mü?        | Stack’teki son değer aktif hücreden büyükse aktif hücreye `1`, değilse `0` yazar.                                         |
| `^`   | Küçük mü?        | Stack’teki son değer aktif hücreden küçükse aktif hücreye `1`, değilse `0` yazar.                                         |
| `&`   | İkiyle çarp      | Aktif hücre değerini 2 ile çarpar.                                                                                        |
| `\|`  | İkiye böl        | Aktif hücre değerini 2’ye böler.                                                                                          |
| `@`   | Meta çağrı       | Aktif hücredeki değeri runtime servis numarası gibi kullanır. FreeBASIC runtime’daki `ux_meta_call` fonksiyonunu çağırır. |

> Not: Tablo içinde `|` karakteri Markdown tablo ayırıcı olduğu için `\|` şeklinde gösterdim. Dildeki gerçek komut sadece `|` işaretidir.

---

# Tekrar Makrosu

Bu normal komut değildir; yazımı kolaylaştıran lexer kısaltmasıdır.

| Yazım  | Anlamı                              |
| ------ | ----------------------------------- |
| `+k65` | 65 tane `+` yazılmış gibi davranır. |
| `-k10` | 10 tane `-` yazılmış gibi davranır. |
| `>k20` | 20 tane `>` yazılmış gibi davranır. |
| `<k5`  | 5 tane `<` yazılmış gibi davranır.  |
| `$k3`  | 3 tane `$` yazılmış gibi davranır.  |

Örnek:

```text
+k65.
```

Şuna eşdeğerdir:

```text
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++.
```

Çıktı:

```text
A
```

---

# String / Data Direktifleri

Bunlar tek karakterli komut değil; compiler direktifidir.

| Yazım            | Görevi                                                     |
| ---------------- | ---------------------------------------------------------- |
| `s1=0,{Merhaba}` | String 1’i `ux_data` alanında 0. hücreden itibaren saklar. |
| `p1`             | String 1’i ekrana basar.                                   |
| `s2=100,{Test}`  | String 2’yi data alanında 100. hücreden itibaren saklar.   |
| `p2`             | String 2’yi ekrana basar.                                  |

Örnek:

```text
s1=0,{Merhaba Mete abi}
p1
```

Çıktı:

```text
Merhaba Mete abi
```

---

# Meta Komutları

`@` komutu, aktif hücredeki değeri runtime servis numarası olarak kullanır.

Örneğin:

```text
0+@
```

şu anlama gelir:

```text
aktif hücre = 1
meta servis 1 çağır
```

Önerilen mevcut meta servis tablosu:

| Meta ID | Görevi                        |
| ------- | ----------------------------- |
| `0`     | Boş işlem / no-op             |
| `1`     | Ekranı temizle / CLS          |
| `2`     | İmleci ekran başına al / HOME |
| `3`     | Rastgele değer üret           |
| `4`     | Timer/zaman değeri üret       |
| `5`     | Yeni satır bas                |
| `6`     | UX-MINIMA meta mesajı bas     |
| `7`     | Test değeri döndürür          |
| `8`     | Test değeri döndürür          |

Örnek yeni satır:

```text
0+++++@
```

Açıklama:

```text
0       aktif hücreyi sıfırla
+++++   aktif hücreyi 5 yap
@       meta servis 5 çağır
```

---

# Karşılaştırma Komutları

Karşılaştırma komutları **stack + aktif hücre** mantığıyla çalışır.

Genel şablon:

```text
<sol değer>$<sağ değer><karşılaştırma komutu>
```

Burada:

```text
$  sol değeri stack’e atar
?  eşitlik kontrolü yapar
!  büyüktür kontrolü yapar
^  küçüktür kontrolü yapar
```

Karşılaştırma sonucu aktif hücreye yazılır:

```text
1 = doğru
0 = yanlış
```

## `?` eşitlik

```text
+k65$0+k65?
```

Anlamı:

```text
65 == 65 mi?
```

Sonuç:

```text
aktif hücre = 1
```

## `!` büyüktür

```text
+k70$0+k65!
```

Anlamı:

```text
70 > 65 mi?
```

Sonuç:

```text
aktif hücre = 1
```

## `^` küçüktür

```text
+k40$0+k65^
```

Anlamı:

```text
40 < 65 mi?
```

Sonuç:

```text
aktif hücre = 1
```

---

# IF Mantığı

UX-MINIMA’da ayrı bir `IF THEN` kelimesi yoktur. Bunun yerine karşılaştırma sonucu `[` `]` bloğuna sokulur.

Şablon:

```text
<karşılaştırma>[
    yapılacak işler
    0
]
```

Blok sonunda `0` koymak önemlidir. Çünkü `[` `]` aslında döngüdür. Flag sıfırlanmazsa sonsuz döngü olabilir.

Örnek:

```text
s1=0,{Esitlik dogru}

+k65$0+k65?[
p1
0
]
```

Anlamı:

```text
Eğer 65 == 65 ise:
    "Esitlik dogru" yaz
```

---

# Biyolojik / Kimyasal Modelleme İçin Komutların Yorumu

Tape hücrelerini bilimsel modelde şöyle kullanabiliriz:

```text
tape[0] = A maddesi
tape[1] = B maddesi
tape[2] = C maddesi
```

Basit reaksiyon:

```text
A → B
```

UX-MINIMA:

```text
+k10[->+<]
```

Açıklama:

```text
A = 10
A sıfır olana kadar:
    A’dan 1 eksilt
    B’ye 1 ekle
```

DNA/protein için:

```text
A = 1
C = 2
G = 3
T = 4
```

Bir baz A mı diye kontrol:

```text
s1=0,{Baz A bulundu}

+k1$0+k1?[
p1
0
]
```

Eşik kontrolü:

```text
s1=0,{Esik asildi}

+k12$0+k10![
p1
0
]
```

Anlamı:

```text
12 > 10 ise "Esik asildi" yaz
```

---

# Kısa Komut Özeti

```text
>       sağ hücreye geç
<       sol hücreye geç
+       aktif hücreyi artır
-       aktif hücreyi azalt
0       aktif hücreyi sıfırla
.       aktif hücreyi karakter olarak bas
,       klavyeden karakter oku
[       döngü/koşul başlangıcı
]       döngü/koşul sonu
$       UX stack push
%       UX stack pop
?       eşitlik karşılaştırması
!       büyüktür karşılaştırması
^       küçüktür karşılaştırması
&       ikiyle çarp
|       ikiye böl
@       runtime/meta servis çağır
+kN     N defa + üret
-kN     N defa - üret
>kN     N defa > üret
<kN     N defa < üret
sN=X,{metin}  string tanımla
pN      string bas
```
