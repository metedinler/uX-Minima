# COPILOT TEK EMİR V3 — UXM kanonik kod temizliği, parçalama ve matris güncelleme

Bu emir plan dışı öneri istemez. Önce soruya cevap ver, sonra işlem yap.

## Değişmez kurallar

1. Türkçe cevap ver. Türkçe düşün. İngilizce açıklama yazma.
2. Kullanıcı kod yaz diyorsa belge üretme; önce kodu yaz.
3. Silmek yasak. `git mv` kullan. Untracked dosyada `Move-Item` kullan. `Remove-Item` yok.
4. Aktif gerçeklik: kod + build + test + EXPECT + JSON/CSV matris.
5. Eski `.md`, `.txt`, bilgi dosyaları aktif gerçeklik değildir. Hepsi `uxm/legacy/docs_old/` altına taşınır.
6. Aktif belge sadece iki plan dosyasıdır:
   - `uxm/docs/plans/current/00_ESKI_PLAN_OZETI.md`
   - `uxm/docs/plans/current/01_YENI_PLAN_KOD_GERCEKLIGI.md`
7. Kullanıcının iki matris klasörü aktif izleme sistemidir, legacy değildir:
   - `uxm/reports/matrices/current/uxm31_matrix_out/`
   - `uxm/reports/matrices/current/UXM_V31_CSV_Matris_Paketi/`
8. Kod dosyasına sohbet, markdown, üçlü backtick, açıklama metni koymak yasaktır.
9. `VAR` yazmak için derleme/test/EXPECT kanıtı gerekir. Kanıt yoksa `KISMEN`, `BROKEN`, `PLAN`, `UNSUPPORTED` yaz.
10. Benzer isimli dosyalarda kanonik olmayanı geliştirme. Önce `matrisler/03_kanonik_dosya_secim_matrisi.csv` kararına bak.

## İlk iş: çalışma klasörünü temizle

V3 klasör sistemi kurulmadan kod yamalama yok.

Sıra:

1. Git durumunu kaydet.
2. `uxm/` ağacını kur.
3. Kanonik kodu `uxm/core/` altına taşı.
4. VSCode eklentisini `uxm/ide/vscode/` altına taşı, `node_modules` aktif hattan çıkar.
5. Testleri `uxm/tests/` altında sınıflandır.
6. Build çıktıları `uxm/build/` altına ayrılır.
7. Eski belgeleri `uxm/legacy/docs_old/` altına taşı.
8. Kırık full tool kaynaklarını `uxm/legacy/corrupt_sources/full_tool/` altına taşı.
9. Matris klasörlerini `uxm/reports/matrices/current/` altına taşı.
10. Her dosya/klasör taşımasından sonra commit ve push yap.

## Kanonik dosyalar

- Native compiler: `uxm31_compiler_fb.bas`
- Full runtime host: `uxm31_runtime_fb_full.bas`
- FP runtime: `runtime/runtime_fp_services.bas`
- Matrix runtime: `math_extensions/runtime/runtime_matrix_services.bas`
- Math/türev/integral runtime: `math_extensions/runtime/runtime_math_services.bas`
- Final compiler/interpreter onarım hedefi: `final/uxm31_compiler_final.bas`
- Compiler parser ekleri:
  - `math_extensions/compiler/arge_parse_math_additions.bas`
  - `math_extensions/compiler/arge_parse_matrix_additions.bas`
- VSCode IDE: `ide/uxminima-vscode`

## Aktif hatta yasak dosyalar

- `uxm31_full_tool_fb.bas`
- `uxm31_full_tool_fb_2.bas`
- `legacy/duplicates/tools/uxm31_full_tool_fb.bas`
- `uxm31_compiler_fb.clean.bas`
- `legacy/duplicates/compiler/uxm31_compiler_fb.bas`
- `uxm31_runtime_fb.bas`
- Eski `.md` ve `.txt` belgeleri

Bunlar silinmez, legacy/karantina altına taşınır.

## İkinci iş: büyük kodları parçala

Temizlik bitmeden parçalama yok.

Parçalama sırası:

1. Native compiler dosyası:
   - `native_cli.bas`
   - `native_lexer_parser.bas`
   - `native_addressing.bas`
   - `native_meta_parse.bas`
   - `native_asm_emit.bas`
   - `native_validation.bas`
   - `native_main.bas`
2. Runtime host:
   - `runtime_host.bas`
   - `runtime_memory.bas`
   - `runtime_io.bas`
   - `runtime_status_flags.bas`
   - `runtime_meta_dispatch.bas`
   - `services/*.bas`
3. Final compiler onarımı:
   - Önce derleme hatalarını düzelt.
   - Sonra final modüllere ayır.
4. VSCode interpreter:
   - `src/interpreter/core.ts`
   - `src/interpreter/parser.ts`
   - `src/interpreter/metaRuntime.ts`
   - `src/interpreter/memory.ts`
   - `src/interpreter/trace.ts`

Her parçalama adımından sonra build/test/matris güncelle.

## Kod aktarım kuralı

- `D@T` adresleme kodu `uxm31_compiler_fb.bas` içinden alınacak.
- FP, Matrix, Math servisleri mevcut runtime servis modüllerinden alınacak.
- JSON/trace/UIR/DIAG/OPT final compiler ve VSCode toolchain içinden alınacak.
- Full tool bas dosyalarından doğrudan kod alınmayacak; önce markdown temizleme + derleme testi.

## Matris güncelleme zorunluluğu

Her çalışmadan sonra şu matrisler güncellenecek:

- `uxm/reports/matrices/current/uxm31_matrix_out/meta_servis_matrisi.csv`
- `uxm/reports/matrices/current/uxm31_matrix_out/four_hat_parity.csv`
- `uxm/reports/matrices/current/uxm31_matrix_out/four_hat_parity_full.csv`
- `uxm/reports/matrices/current/uxm31_matrix_out/test_matrisi.csv`
- `uxm/reports/matrices/current/UXM_V31_CSV_Matris_Paketi/feature_checks.csv`
- `uxm/reports/matrices/current/UXM_V31_CSV_Matris_Paketi/high_service_gaps.csv`
- `uxm/reports/matrices/current/UXM_V31_CSV_Matris_Paketi/plan_gaps.csv`
- `uxm/reports/matrices/current/UXM_V31_CSV_Matris_Paketi/tracking_files.csv`
