# Matrislerin Sürekli Güncelleme Planı

Kullanıcının izlediği matrisler sistemin ana göstergesidir. Bu nedenle matrisler legacy klasörüne atılmayacak, aktif rapor sistemine taşınacaktır.

## Aktif matris klasörleri

```text
uxm/reports/matrices/current/uxm31_matrix_out/
uxm/reports/matrices/current/UXM_V31_CSV_Matris_Paketi/
```

## VAR yazma şartı

Bir özellik için `VAR` yazılacaksa:

1. Kodda gerçek implementation olacak.
2. Test dosyası olacak.
3. `EXPECT_OUTPUT`, `EXPECT_STATUS` veya eşdeğer beklenen sonuç olacak.
4. Build/test çıktısı olacak.
5. İlgili dört hat satırı güncellenecek.

Bunlar yoksa `KISMEN`, `BROKEN`, `PLAN`, `UNSUPPORTED`, `RESERVED` yazılır.

## Her kod değişikliğinden sonra güncellenecekler

- `meta_servis_matrisi.csv`
- `four_hat_parity.csv`
- `four_hat_parity_full.csv`
- `test_matrisi.csv`
- `feature_checks.csv`
- `high_service_gaps.csv`
- `plan_gaps.csv`
- `tracking_files.csv`
- `dashboard.csv`
