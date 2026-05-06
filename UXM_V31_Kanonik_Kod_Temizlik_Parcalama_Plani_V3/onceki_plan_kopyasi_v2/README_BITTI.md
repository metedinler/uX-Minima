# UXM V31 Calisma Ortami Temizlik ve Calisan Sistem Plani V2

Bu paket onceki plani silmez; `onceki_plan_kopyasi/` altinda saklar ve ustune V2 uygular.

## Net karar

1. Yeni aktif calisma kok klasoru: `uxm/`.
2. Eski `.md`, `.txt`, bilgi dosyalari aktif kaynak degil; `uxm/legacy/docs_old/` altina tasinacak.
3. Eski `.csv`, `.xlsx` matrisler aktif karar degil; `uxm/legacy/matrices_old/` altina tasinacak.
4. Aktif plan belgesi sadece iki adet olacak:
   - `uxm/plans/00_ESKI_PLAN_OZETI.md`
   - `uxm/plans/01_YENI_PLAN_KOD_GERCEKLIGI.md`
5. Tek gerceklik: kod + build + test + EXPECT + JSON/CSV sonucudur.
6. Silmek yasak; `git mv` kullanilacak.
7. Her dosya ayri commit ve push yapilacak.
8. Copilot plan disi oneri yazmayacak, Turkce cevap verecek.

## Bu paketteki ana dosyalar

- `copilot_emirleri/COPILOT_TEK_EMIR_V2.md`
- `scripts/01_KLASOR_TEMIZLEME_GIT_MV.ps1`
- `scripts/02_KOD_GERCEKLIGI_DERLEME_TEST.ps1`
- `scripts/03_COMMIT_PER_FILE_PUSH.ps1`
- `matrisler/02_yeni_klasor_sistemi.csv`
- `matrisler/03_legacy_tasima_manifesti.csv`
- `matrisler/04_aktif_kod_test_build_tasima_manifesti.csv`
- `matrisler/13_minimum_hamle_plani.csv`
- `mimari/UXM_COMPILER_MIMARI_KOD_GERCEKLIGI.md`
- `mimari/COPILOT_CALISMA_MODELI.md`

## Kritik gercek

Mevcut zip icinde VS Code eklentisi var. FP/MAT/MATH servisleri ve testleri de var. Fakat full tool kaynaginda markdown/sohbet kirliligi, final compiler hattinda derleme riski ve build/test artefaktlarinda daginiklik var.

Bu yuzden ilk is yeni kod yazmak degil, calisma agacini temizleyip kaynak otoritesini ayirmaktir.

## Durum

Bu paket plan ve emir paketidir. Kaynak kod degistirilmedi.

BITTI.
