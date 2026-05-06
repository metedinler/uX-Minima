# COPILOT ICIN TEK EMIR DOSYASI - UXM V31 KOD GERCEKLIGI

Bu repoda yeni belge yazmak yasak. Once kod gercekligi duzeltilecek.

## Degistirilemez kurallar

1. Silme yok. Tasima varsa sadece `git mv` kullan.
2. Her islemden once:
   - `git status --short`
   - `git branch --show-current`
   - `git diff --stat`
   komutlarini calistir ve sonucu `reports/once_git_durum.txt` icine yaz.
3. Bir turda en fazla 3 kaynak dosya degistir.
4. Bir kod dosyasina markdown, aciklama metni, ``` fence, blogger yazisi veya sohbet cevabi koyma.
5. Belgede plan degistirme, yeni plan uretme, matris sisirme yok. Kod ve test sonucu yoksa `VAR` yazma.
6. Tum cevaplar Turkce olacak. Kaynak kod icinde Turkce karakter kullanma; yorum gerekiyorsa ASCII Turkce yaz.
7. Hata olursa gizleme. `PASS`, `FAIL`, `UNSUPPORTED`, `RESERVED`, `BROKEN_SOURCE` disinda durum kullanma.

## Dört hat korunacak

HAT1_NATIVE_X64:
- uxm31_compiler_fb.bas
- uxm31_runtime_fb.bas
- uxm31_runtime_fb_full.bas
- build_all.bat
- build_one.bat
- run_tests.bat

HAT2_FULL_TOOL_INTERPRETER:
- uxm31_full_tool_fb.bas
- uxm31_full_tool_fb_2.bas sadece kurtarilacak kaynak parcasi ise kullanilacak

HAT3_FINAL_ARGE_COMPILER:
- final/uxm31_compiler_final.bas
- final/build_final.bat
- build_final_compiler.bat
- run_final_probe.bat

HAT4_VSCODE_EXTENSION:
- ide/uxminima-vscode/package.json
- ide/uxminima-vscode/src/*.ts
- ide/uxminima-vscode/syntaxes
- ide/uxminima-vscode/snippets

## Uygulama sirasi

### Adim 0 - Repo guvenligi

```powershell
git status --short > reports/00_before_status.txt
git diff --stat > reports/00_before_diffstat.txt
git switch -c fix/uxm-v31-code-reality
```

### Adim 1 - .bas kaynak kirliligi temizligi

Hedef: FreeBASIC kaynak dosyalarindan markdown/prose bloklarini ayikla.

Kontrol komutu:
```powershell
rg -n "```|Tamam Mete abi|# Dosya|devam yazarsan|Blogger|Markdown" --glob "*.bas"
```

Kabul kriteri:
- Hicbir aktif .bas dosyasinda markdown fence veya sohbet cumlesi kalmayacak.
- Kaldirilan ham metin `legacy/raw_chat_extracts/` altina `.md` olarak tasinacak, silinmeyecek.

### Adim 2 - Batch hata kodlari

Hedef: build betikleri hata halinde gercekten non-zero donsun.

Duzeltilecek dosyalar:
- build_all.bat
- build_one.bat
- build_final_compiler.bat
- run_tests.bat

Kabul kriteri:
- `:fail` sonunda `exit /b 1`
- basarili `:end` sonunda `exit /b 0`
- run_tests alt build hatasini yutmayacak.

### Adim 3 - Final compiler derlenebilirlik

Hedef: `final/uxm31_compiler_final.bas` derlenecek.

Kontrol:
```powershell
fbc -lang fb final\uxm31_compiler_final.bas -x build\uxm31_compiler_final.exe
```

Oncelikli hata siniflari:
- `#Lang "fb"` ilk anlamli satir olacak.
- `instr`, `ptr`, `dir`, `sp` gibi reserve/arka-uç isimleri degistirilecek.
- Tek satir `If ... ElseIf ...` zincirleri FreeBASIC uyumlu cok satir yapilacak.

Kabul kriteri:
- build\uxm31_compiler_final.exe uretilir.
- `run_final_probe.bat` hata kodu 0 doner.

### Adim 4 - Full tool temiz kaynak

Hedef: `uxm31_full_tool_fb.bas` derlenebilir tek kaynak olacak.

Kontrol:
```powershell
fbc -lang fb uxm31_full_tool_fb.bas -x uxm31_full_tool.exe
```

Kabul kriteri:
- Interpreter/trace/UIR/optimizer komutlari calisir.
- `uxm31_full_tool_fb_2.bas` ya temiz kaynak olarak yeniden adlandirilir ya da legacy/raw altina tasinir.

### Adim 5 - FP/MAT/MATH entegrasyon dogrulama

Kosulacak test setleri:
```powershell
.\run_tests.bat
```

Zorunlu test klasorleri:
- tests
- tests_matrix
- math_extensions\tests_math
- tests_fp

Kabul kriteri:
- Her testin EXPECT_OUTPUT satiri okunur.
- Gercek cikti ile beklenen cikti karsilastirilir.
- Sonuc `reports/test_results.csv` dosyasina yazilir.
- EXPECT olmayan test PASS sayilmaz.

### Adim 6 - 4 hat parite matrisi

Kod ve test sonucu olmadan VAR yazma.

Matris satir kararlari:
- PASS: ilgili hatta testle gecmis
- FAIL: test var ama gecmiyor
- UNSUPPORTED: bilincli desteklenmiyor ve hata/status tanimli
- RESERVED: ayrilmis ama tasarlanmamis
- BROKEN_SOURCE: kaynak dosya derlenemiyor

Cikti:
- reports/four_hat_conformance.csv
- reports/feature_reality.csv
- reports/service_reality.csv

## Kod yazmadan once yasaklar

- Sadece belge duzeltip is bitmis gibi yazma.
- 27 satir kod + 300 satir belge uretme.
- Ayni fonksiyon bolgesini rastgele degistirme.
- Matrise VAR yazip test kosmadan gecme.
- Eski dosyayi silme.
- Ingilizce aciklama yazma.
