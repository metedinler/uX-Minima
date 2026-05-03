# UX-MINIMA Meta Servis Haritası

| Aralık | Anlam |
|---|---|
| `@0..@19` | Çekirdek servisler |
| `@20..@39` | Aritmetik servisler |
| `@40..@59` | Matematik servisleri |
| `@60..@79` | I/O servisleri |
| `@80..@89` | Pointer/layout servisleri |
| `@90..@94` | FIFO servisleri |
| `@95..@107` | Data/tape block, sort, search servisleri |
| `@120..@127` | Flags, endian, signed, wild layout servisleri |
| `@128..@255` | Kullanıcı macro alanı |

Önemli servisler:

- `@20`: Toplama. `T-2 + T-1 -> T+1`
- `@23`: Bölme. `T-2 / T-1 -> T+1`
- `@40`: Sinüs. `sin(T-1) -> T+1`
- `@43`: Hipotenüs.
- `@61`: `T+1` sonucunu decimal basar.
- `@90`: FIFO push.
- `@91`: FIFO pop.
- `@95`: Data read.
- `@96`: Data write.
- `@100`: Tape sort ascending.
- `@101`: Tape sort descending.
- `@127`: Wild mode layout change.
