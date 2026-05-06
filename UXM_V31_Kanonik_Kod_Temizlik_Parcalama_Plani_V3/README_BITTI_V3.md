# UXM V31 Kanonik Kod Temizlik ve Parçalama Planı V3

Bitti.

Bu paket V2 planını iptal etmez; V2'nin geçerli iskeletini korur fakat eksik olan üç şeyi ekler:

1. Benzer isimli dosyalar arasında **kanonik gerçek dosya** seçimi.
2. Kullanıcının önemli dediği iki matris klasörünün aktif izleme sistemi yapılması:
   - `uxm31_matrix_out`
   - `UXM_V31_CSV_Matris_Paketi`
3. Büyük tek dosya kodların parçalanma ve yeni `uxm/` ağacına taşınma planı.

## Sert sonuç

- V2'nin klasör temizliği fikri geçerli.
- V2, kanonik dosya kararında ve mevcut matrisleri plana bağlamada eksik.
- `uxm31_compiler_fb.bas` native compiler için kanonik dosyadır.
- `uxm31_runtime_fb_full.bas` runtime host için kanonik dosyadır.
- `runtime/runtime_fp_services.bas`, `math_extensions/runtime/runtime_matrix_services.bas`, `math_extensions/runtime/runtime_math_services.bas` gerçek servis modülleridir.
- `final/uxm31_compiler_final.bas` gelişmiş final/compiler/interpreter kodudur ama mevcut build loglarına göre kırık onarım hedefidir.
- `uxm31_full_tool_fb.bas`, `uxm31_full_tool_fb_2.bas` ve `legacy/duplicates/tools/uxm31_full_tool_fb.bas` aktif kaynak değildir; markdown/sohbet karışmış kırık dosyadır.

## Ana emir dosyası

Copilot'a verilecek ana dosya:

```text
copilot_emirleri/COPILOT_TEK_EMIR_V3.md
```

## Ana matrisler

- `matrisler/03_kanonik_dosya_secim_matrisi.csv`
- `matrisler/05_klasor_temizleme_gitmv_manifesti.csv`
- `matrisler/06_buyuk_kod_parcalama_plani.csv`
- `matrisler/07_ozellik_aktarim_ve_baglanti_matrisi.csv`
- `matrisler/10_mevcut_matrisler_v3_izleme_plani.csv`
- `matrisler/13_v2_gecerlilik_ve_v3_duzeltme_matrisi.csv`
