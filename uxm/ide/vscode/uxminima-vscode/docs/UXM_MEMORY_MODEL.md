# UX-MINIMA Bellek Modeli

Varsayılan:

```uxm
#cell byte
#memory tape=32,stack=8,data=24
```

Toplam 64 KB olmalıdır. Hücre tipi byte/word/dword olabilir.

Tape aktif çalışma alanıdır. Stack LIFO’dur. Data string ve tablo içindir. FIFO queue ayrı mantıksal kuyruktur.

IDE memory watch şu alanları gösterir:

- Tape window: pointer çevresi
- Stack: SP çevresi
- FIFO: ilk 16 eleman
- Data: sıfır olmayan ilk hücreler
- Flags/status
- Program output
