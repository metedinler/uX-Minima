# UXM V31 Güncellenmiş Plan ve Manifest

Bu dosya, verilen zip içindeki kod dosyaları, test klasörleri, Git geçmişi, `UXM_V31_Kod_Belge_Matris_Paketi` ve mevcut raporlar dikkate alınarak hazırlanmıştır. Dosya silme veya taşıma yapılmamıştır; bu belge yalnızca uygulanacak planı ve manifesti verir.

## Kısa gerçek durum

- Kod yapısı hâlâ **4 ayrı hat** içeriyor:
  1. Native compiler/runtime
  2. Final/ARGE compiler
  3. Full Tool
  4. VS Code internal interpreter / IDE
- Plan hedefi “mümkünse” değil, **zorunlu 4 hat davranış standardıdır**.
- Sprint 1 `e / ERR / STATUS` tarafı büyük ölçüde kapanmış görünüyor.
- FP, Matrix, türev, integral ve polinom tarafı native/runtime düzeyinde ilerlemiş; ancak 4 hatta standart davranış kapalı değildir.
- Aynı adlı ama farklı içerikli kaynak dosyalar vardır; otorite kaynaklar kilitlenmeden yeni patch tehlikelidir.
- `tests_matrix` klasörü vardır ancak ana `run_tests.bat` zincirine bağlı olmayabilir.
- Copilot tarafından `Remove-Item`, overwrite veya silme/yeniden yazma riski doğuran işlemler görüldüğü için işlem günlüğü ve onay kuralı zorunludur.

## Kod gerçekliğine göre ana açıklar

| Konu | Kod gerçekliği | Açık |
|---|---|---|
| Sprint 1 | `@9..@15` dört hatta büyük ölçüde var | Plan dosyası plan+uygulama raporu olarak karışmış |
| Compiler adı | `uxm.exe` standardizasyonu izleri var | Plan maddelerinde ayrı takip kalemi eksik |
| FP 200+ | `runtime/runtime_fp_services.bas` içinde yoğun var | Final / Full Tool / VSCode 4 hat paritesi yok |
| Matrix 160+ | `math_extensions/runtime/runtime_matrix_services.bas` ve `tests_matrix` var | Ana runner ve diğer hat paritesi eksik |
| Türev/İntegral 240+ | `math_extensions/runtime/runtime_math_services.bas` var | Diğer hatlar eksik/kısmi |
| Klasör düzeni | MD, CSV, kaynak ve kopyalar dağınık | `git mv` manifestiyle düzenlenmeli, silme yok |

## Otorite kaynak önerisi

| Otorite | Mevcut dosya |
|---|---|
| Native compiler | `uxm31_compiler_fb.bas` |
| Native runtime | `uxm31_runtime_fb_full.bas` |
| Final/ARGE compiler | `final/uxm31_compiler_final.bas` |
| Full Tool | `uxm31_full_tool_fb.bas` |
| VS Code internal | `ide/uxminima-vscode/src/*.ts` |
| FP services | `runtime/runtime_fp_services.bas` |
| Matrix services | `math_extensions/runtime/runtime_matrix_services.bas` |
| Math/Derivative/Integral services | `math_extensions/runtime/runtime_math_services.bas` |

## Klasör düzenleme hedefi

```text
src/
  native/
    compiler/
    runtime/
  final/
  tools/full_tool/
  ide/vscode/
  runtime_services/
    fp/
    matrix/
    math/
lib/
tests/
  core/
  fp/
  matrix/
  math/
docs/
  master/
  plans/
  architecture/
  user_guides/
  reports/
  archive/
legacy/
  compiler/
  runtime/
  tools/
  docs/
build/
  asm/
  obj/
  exe/
  logs/
  reports/
```

## Uygulama kuralları

1. Dosya silmek yasak.
2. `Remove-Item` yasak.
3. `Copy-Item -Force` ile overwrite yasak.
4. Taşıma sadece `git mv` ile yapılacak.
5. Her işlemden önce `git status --short -b` alınacak.
6. Her işlemden sonra `DEGISIKLIK_GUNLUGU_TR.md` güncellenecek.
7. Commit/push ancak Mete abi “COMMIT ET” dediğinde yapılacak.
8. Her dosya ayrı commit istenirse önce dosya listesi dondurulacak.
9. Matrisler koddan yeniden üretilecek; eski raporlar tarihsel kabul edilecek.
10. Legacy klasörüne alınan dosya kendi kaynak klasör adı altında korunacak; üst üste atılmayacak.

## Sürekli güncellenecek takip dosyaları

- `MASTER_TAKIP_DOKUMANI_V31.md`
- `GERCEKLIK_KILIDI.md` yeni oluşturulacak
- `DEGISIKLIK_GUNLUGU_TR.md` yeni oluşturulacak
- `BELGE_KOD_OK_MATRISI.md`
- `BELGEDE_OLUP_KODDA_OLMAYANLAR_RAPORU.md`
- `KODDA_OLUP_BELGEDE_OLMAYANLAR_RAPORU.md`
- `UXM_V31_Kod_Belge_Matris_Paketi/SPRINT_1_E_ERR_STANDARTLASMA_PLANI.md`
- `UXM_V31_Kod_Belge_Matris_Paketi/uxm31_matrix_out/*.csv`

## Öncelikli bir sonraki iş

Kod yazmadan önce:

1. `GERCEKLIK_KILIDI.md` oluştur.
2. `4_Hat_Parity` matrisini koddan üret.
3. Duplicate kaynakların hash farkını kesinleştir.
4. `tests_matrix` ana test zincirine bağlanacak mı, önce planla.
5. Klasör düzenleme için `Move_Manifest` içindeki `git mv` komutlarını sırayla uygula.
