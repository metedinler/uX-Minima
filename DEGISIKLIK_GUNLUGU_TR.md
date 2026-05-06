# DEGISIKLIK GUNLUGU (TR)

## 2026-05-06

1. tests/ ve tests_matrix icinde 50-120 meta kullanan testlerde eksik # EXPECT_OUTPUT satirlari eklendi.
2. 50-120 test kapsami raporu yeniden uretildi:
   - UXM_V31_tests_meta_50_120_expect_report.csv
   - UXM_V31_Kod_Belge_Matris_Paketi/uxm31_matrix_out/UXM_V31_tests_meta_50_120_expect_report.csv
3. Matrix cikti klasorunde test_matrisi.csv guncellendi.
4. Duplicate kaynaklar icin hash fark raporu uretildi:
   - UXM_V31_Kod_Belge_Matris_Paketi/uxm31_matrix_out/duplicate_hash_diffs.csv
   - UXM_V31_Kod_Belge_Matris_Paketi/UXM_V31_CSV_Matris_Paketi/duplicate_hash_diffs.csv
5. GERCEKLIK_KILIDI.md olusturuldu.
6. 4-hat parity tam yeniden uretildi:
   - UXM_V31_Kod_Belge_Matris_Paketi/uxm31_matrix_out/four_hat_parity_full.csv
   - UXM_V31_Kod_Belge_Matris_Paketi/uxm31_matrix_out/four_hat_parity.csv
   - UXM_V31_Kod_Belge_Matris_Paketi/UXM_V31_CSV_Matris_Paketi/four_hat_parity_full.csv
   - UXM_V31_Kod_Belge_Matris_Paketi/UXM_V31_CSV_Matris_Paketi/four_hat_parity.csv
7. tests_matrix klasoru ana test zincirine baglandi (run_tests.bat).
8. duplicate NO satirlari icin otorite secimi ve git-mv esitleme manifestleri uretildi:
   - UXM_V31_Kod_Belge_Matris_Paketi/uxm31_matrix_out/duplicate_authority_selection.csv
   - UXM_V31_Kod_Belge_Matris_Paketi/UXM_V31_CSV_Matris_Paketi/duplicate_authority_selection.csv
   - UXM_V31_Kod_Belge_Matris_Paketi/uxm31_matrix_out/gitmv_esitleme_manifest.csv
   - UXM_V31_Kod_Belge_Matris_Paketi/UXM_V31_CSV_Matris_Paketi/gitmv_esitleme_manifest.csv

## Sonraki Operasyon Adimi

1. gitmv_esitleme_manifest.csv icindeki PENDING adimlarini sira ile uygula.
2. 4-hat parity aciklarini 50-120 odakli satir bazli takip et.
3. tests_matrix icin CI/runner performans raporu ekle.
