# UX-MINIMA V3.1 Dil Özeti

UX-MINIMA, tape/stack/data/FIFO tabanlı, Brainfuck kökenli fakat meta servislerle genişletilmiş deneysel bir dildir.

## Temel komutlar

| Komut | Görev |
|---|---|
| `>` | Pointer sağa |
| `<` | Pointer sola |
| `+` | Hücre artır |
| `-` | Hücre azalt |
| `0` | Hücre sıfırla |
| `.` | Karakter bas |
| `,` | Karakter oku |
| `[` `]` | Döngü |
| `$` | Stack push |
| `%` | Stack pop |
| `?` `!` `;` | Eşit, büyük, küçük karşılaştırma |
| `&` `|` `^` `~` | Bitwise işlemler |
| `{` `}` | SHL / SHR |
| `@N` | Meta servis |
| `@#` | Dinamik meta servis |

## Kısaltma

`+k65` aktif hücreyi 65 artırır. `0+k65.` A basar.

## Adresleme

`(T)`, `(T-2)`, `(T+1)`, `(T:10)`, `(D:0)`, `(S:0)`, `(SP)`, `(P)`, `(E)`, `(F)`, `(*T)`, `(*(T+1))`.

Komut içinde boşluk yoktur: `0(T-2)+k10` doğru, `0 (T-2)` hatalıdır.

## Meta frame

`T-2=arg1`, `T-1=arg2`, `T=arg0`, `T+1=result`.
