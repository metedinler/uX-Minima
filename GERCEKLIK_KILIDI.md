# GERCEKLIK KILIDI (V31)

Tarih: 2026-05-06
Durum: AKTIF

## Otorite Kod Dosyalari

1. Native compiler: uxm31_compiler_fb.bas
2. Native runtime: uxm31_runtime_fb_full.bas
3. Final/ARGE compiler: final/uxm31_compiler_final.bas
4. Full Tool: uxm31_full_tool_fb.bas
5. VSCode internal: ide/uxminima-vscode/src/
6. FP runtime servisleri: runtime/runtime_fp_services.bas
7. Matrix runtime servisleri: math_extensions/runtime/runtime_matrix_services.bas
8. Math runtime servisleri: math_extensions/runtime/runtime_math_services.bas

## Otorite Matris ve Rapor Dosyalari

1. UXM_V31_Kod_Belge_Matris_Paketi/uxm31_matrix_out/meta_servis_matrisi.csv
2. UXM_V31_Kod_Belge_Matris_Paketi/uxm31_matrix_out/test_matrisi.csv
3. UXM_V31_Kod_Belge_Matris_Paketi/uxm31_matrix_out/UXM_V31_tests_meta_50_120_expect_report.csv
4. UXM_V31_Kod_Belge_Matris_Paketi/uxm31_matrix_out/duplicate_hash_diffs.csv

## Kilit Kararlari

1. 50-120 araligi test kapsaminda EXPECT satiri zorunludur.
2. # EXPECT_OUTPUT formati esas alinacaktir.
3. Ayni adli duplicate dosyalarda hash farki varsa dosya esitlemesi yapilmadan tek otorite ilan edilmeyecektir.
4. Matris guncellemesi kod taramasiyla yapilir; belge tek basina kanit sayilmaz.
5. Silme yok, tasima sadece git mv ile.

## Acik Kilit Konulari

1. Native/Final/Full Tool/VSCode 4-hat tam parite aciklari tamamen kapanmadi.
2. tests_matrix ana test zincirine bagli degil; runner karari acik.
3. Duplicate hash farki olan kritik dosyalar icin otorite secimi acik.
