# Sprint 1 Plani - e Komutu ve ERR Bayragi Standartlasmasi

## Hedef
Dort hat (Native, Final, Full Tool, VSCode Internal) arasinda status ve hata bayragi davranisini gizli fark olmadan standartlastirmak.

## Sprint Kapsami
1. Komut semantigi
- e komutu: aktif hucreye status byte yazar.

2. Core meta servisleri
- @9  STATUS READ
- @10 STATUS CLEAR
- @11 STATUS SET
- @12 STATUS PRINT
- @13 ERR FLAG SET
- @14 ERR FLAG RESET
- @15 ERR FLAG READ

3. Bayrak semantigi
- FLAGS.R (runtime error present) ile status tutarlidir.
- status == 0 ise FLAGS.R = 0
- status != 0 ise FLAGS.R = 1

4. Macro yardimci seti
- m128={e}
- m129={e@60}
- m130={@!13}
- m131={@!14}
- m132={@!10@!14}

## Hat Bazli Gorevler

### A) Native Compiler + Runtime
1. Runtime dispatch tablosunda @13, @14, @15 davranisini ekle.
2. e komutu sonrasi status/FLAGS.R tutarliligini regression test ile dogrula.
3. test42 ve test43 icin ASM/EXE artifact uret.

### B) Final/ARGE Compiler
1. Interpreter tarafinda @13/@14/@15 davranisini native ile esit yap.
2. ASM emit tarafinda status ve ERR bayragi etkisini native ile ayni kil.
3. UIR/diag ciktilarinda bu servisleri acik adla raporla.

### C) Full Tool
1. @13/@14/@15 dispatchini ekle.
2. e + macro yardimcilari ile native ile ayni sonuc uret.
3. Trace ciktilarinda status ve FLAGS.R degerlerini adim bazinda goster.

### D) VSCode Internal Interpreter
1. Desteklenen servislerde native semantik birebir uygula.
2. Desteklenmeyen servislerde bilincli-desteklenmiyor tanisini acikca uret.
3. Help/diagnostic panelinde e, @13, @14, @15 aciklamalarini ekle.

## Test Backlogu
1. tests/test42_error_flag_set_reset.uxm
- Senaryo: @13 set -> @15 read -> @14 reset -> @15 read
- Beklenen: 1 sonra 0

2. tests/test43_error_macro_helpers.uxm
- Senaryo: m130, m131, m132, m129 birlikte
- Beklenen: status/ERR birlikte temizlenir ve sayisal cikti tutarlidir

## Done Criteria
1. Meta servis matrisi satirlari @13..@15 standard adi ile guncel.
2. Dort hatta gizli fark yok.
3. Her fark ya kapatildi ya bilincli desteklenmiyor olarak aciklandi.
4. test42 ve test43 artifact kayitlari test matrisi ve raporda gorunur.
5. Master takip dosyasi Sprint 1 basladi durumunda.

## Sprint 1 Anlik Uygulama Durumu
1. Full Tool: `@!` parse/dispatch ve `@11/@13/@14/@15` kodu eklendi.
2. Final/ARGE: flag-branch ASM emit kosullari tamamlandi, core ERR servisleri eklendi.
3. VSCode Internal: `@11/@13/@14/@15` runtime semantigi eklendi.
4. Native runtime: `@11/@13/@14/@15` ERR servis paritesi tamamlandi.
5. Dogrulama: `tests/test42_error_flag_set_reset.uxm` cikti `10`, `tests/test43_error_macro_helpers.uxm` cikti `100`.

## Sprint 1 Izleme Guncellemesi (2026-05-06)

1. `test42` ve `test43` dosyalarina harness-uyumlu `# EXPECT_OUTPUT` satirlari eklendi.
2. 50-120 odakli testlerde EXPECT kapsami tamlandi; kapsam raporunda `HasExpect=YES` oldu.
3. Kanit dosyalari:
	- `UXM_V31_tests_meta_50_120_expect_report.csv`
	- `UXM_V31_Kod_Belge_Matris_Paketi/uxm31_matrix_out/UXM_V31_tests_meta_50_120_expect_report.csv`
4. Matris ciktisi `test_matrisi.csv` Sprint 1 artifact durumuna gore guncellendi.
