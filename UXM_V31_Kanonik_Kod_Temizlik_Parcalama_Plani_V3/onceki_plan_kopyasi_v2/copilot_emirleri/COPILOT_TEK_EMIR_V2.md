# COPILOT_TEK_EMIR_V2 - UXM CALISMA ORTAMI TEMIZLIGI VE KOD GERCEKLIGI

Bu dosya disinda plan uretme. Bu dosyadaki sirayi uygula.

## 0. Cevap kurali

- Turkce yaz.
- Kullanici soru sorarsa once cevap ver.
- Plan disi oneri verme.
- Kod yaz denirse belge degil kod yaz.
- Kod dosyasina markdown/sohbet koyma.

## 1. Tek kaynak agaci

Calisma agacinda yeni kok:

`uxm/`

Olusturulacak ana klasorler:

- `uxm/core/native_x64/src/`
- `uxm/core/runtime/`
- `uxm/core/full_tool_interpreter/src/`
- `uxm/core/final_arge/`
- `uxm/ide/vscode/`
- `uxm/tests/core/`
- `uxm/tests/fp/`
- `uxm/tests/matrix/`
- `uxm/tests/math/`
- `uxm/tests/ide/`
- `uxm/tests/final/`
- `uxm/build/asm/current/`
- `uxm/build/asm/archive/`
- `uxm/build/obj/current/`
- `uxm/build/obj/archive/`
- `uxm/build/exe/current/`
- `uxm/reports/matrices/`
- `uxm/reports/json/`
- `uxm/plans/`
- `uxm/legacy/docs_old/`
- `uxm/legacy/matrices_old/`
- `uxm/legacy/raw_chat_extracts/`

## 2. Eski belgeler

Tum eski `.md`, `.txt`, bilgi dosyalari aktif kokten alinacak ve `uxm/legacy/docs_old/` altina git mv ile tasinacak.

Aktif belgeler sadece iki tanedir:

1. `uxm/plans/00_ESKI_PLAN_OZETI.md`
2. `uxm/plans/01_YENI_PLAN_KOD_GERCEKLIGI.md`

Eski matrisler `uxm/legacy/matrices_old/` altina tasinir. Yeni matrisler kod/test sonucundan `uxm/reports/matrices/` altinda uretilir.

## 3. Silme yasagi

- `Remove-Item` yok.
- `del` yok.
- `git rm` yok.
- Tasima: `git mv`.
- Untracked dosyada mecbur kalinirsa `Move-Item` + `git add -A`, ama silme yok.

## 4. Commit/push kurali

Her dosya ayri commit ve push:

```powershell
git add "DOSYA"
git commit -m "kod: DOSYA"
git push
```

Tasima icin:

```powershell
git mv "ESKI" "YENI"
git add -A -- "ESKI" "YENI"
git commit -m "tasima: ESKI -> YENI"
git push
```

## 5. Once klasor, sonra kod

Sirayla uygula:

1. `scripts/01_KLASOR_TEMIZLEME_GIT_MV.ps1 -Apply`
2. `matrisler/03_legacy_tasima_manifesti.csv` dosyasindaki tasimalar.
3. `matrisler/04_aktif_kod_test_build_tasima_manifesti.csv` dosyasindaki tasimalar.
4. Iki plan belgesi yeniden yazilir.
5. Build script pathleri yeni `uxm/` agacina gore duzeltilir.
6. Full tool kaynak markdown/prose kirliliginden temizlenir.
7. Final compiler derlenebilir hale getirilir.
8. Native compiler build ciktisi ayrilir.
9. FP/MAT/MATH runtime ve testleri kalici baglanir.
10. VS Code toolchain yeni exe/json yollarina baglanir.
11. Matrisler kod/test/build sonucundan yeniden uretilir.

## 6. Kabul kuralı

Bir ozellik icin `VAR` yazmak yasak. Sadece su durumlar kullanilir:

- PASS
- FAIL
- UNSUPPORTED
- RESERVED
- BROKEN_SOURCE

PASS icin zorunlu kanit:

1. Kaynak dosya temiz.
2. Derleme veya interpreter calisir.
3. Test var.
4. EXPECT var.
5. Gercek cikti karsilastirilmis.
6. JSON/CSV rapora islenmis.

## 7. Kod hedefi

En az hamlede su sistem ayağa kalkacak:

- `uxm/build/exe/current/uxm.exe`
- `uxm/build/exe/current/uxm_full_tool.exe`
- `uxm/build/exe/current/uxm_final.exe`
- VS Code eklentisi bu exe'leri cagiracak.
- ASM ciktisi: `uxm/build/asm/current/`
- OBJ ciktisi: `uxm/build/obj/current/`
- JSON raporlar: `uxm/reports/json/`
- Matrisler: `uxm/reports/matrices/`

## 8. FP/MAT/MATH karari

- UX-FP decimal/string tabanli FP olarak kalici runtime servisidir.
- IEEE-754 F32/F64/F80 mevcut degildir; bu sprintte PLAN/RESERVED disinda yazilmaz.
- Matrix servisleri kalici runtime servisidir.
- Polinom turev/integral, sayisal turev, trapez, Simpson kalici runtime servisidir.
- Deneysel 4 bit CPU ve 4 noronlu ML testleri compiler ozelligi degil, `tests/experimental` olarak izlenir.
