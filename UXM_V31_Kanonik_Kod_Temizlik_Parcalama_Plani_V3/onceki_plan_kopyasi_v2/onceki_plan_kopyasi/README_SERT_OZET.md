# UXM V31 Kod Gercekligi - Sert Analiz Ozeti

Kok klasor: `calisilan/uxm31_FULL_FINAL_REAL`

## Net hukum

Bu zipte en genis surum gercekten `uxm31_FULL_FINAL_REAL` altinda toplanmis. Ancak bu, temiz ve tamamen calisir surum anlamina gelmiyor.

Temel sorun belge eksigi degil. Sorunlar:

1. Aktif kaynak, final kaynak, full tool, VS Code eklentisi ve matrisler ayni anda degistirilmis.
2. `.bas` olmasi gereken bazi dosyalara dogrudan sohbet/markdown cevabi yapistirilmis.
3. Matrislerde `VAR` yazan satirlarin bir kismi derleme ve test kaniti ile kilitlenmemis.
4. Build betikleri hata kodunu guvenilir dondurmuyor.
5. Final compiler hatti derleme hatalari tasiyor.
6. VS Code eklentisi var, fakat final compiler/full tool kiriksa eklenti komutlari zincirleme kirilir.

## Dört hat korunacak ama su an esit degil

- HAT1 Native x64: kismen calisir kanitlari var; current source daha temiz gorunuyor.
- HAT2 Full Tool: kaynak markdown ile kirli; onarim sart.
- HAT3 Final/ARGE: dosya var; derleme loglari hata gosteriyor; onarim sart.
- HAT4 VS Code: eklenti var; ancak toolchain final/full exe kaynaklarina bagimli.

## FP / Matrix / Turev / Integral gercegi

- Core math 40-49: scaled/fixed math olarak var; IEEE float degil.
- UX-FP 200-224: decimal/string tabanli FP servisleri var; tests_fp mevcut; ancak IEEE-754 degil.
- UX-MAT 160-176: matrix runtime ve testler var; 4 hat paritesi kesin degil.
- UX-MATH 240-254: polinom turev/integral, sayisal turev, trapez ve Simpson runtime/testleri var; entegrasyon kismen var, tum hatlarda kapali degil.

## Bir sonraki dogru hareket

Kod yazmadan yeni belge yazma. Once:

1. Git branch ac.
2. Aktif `.bas` dosyalarindan markdown/prose temizle.
3. Batch hata kodlarini duzelt.
4. Final compiler derlenebilir hale getir.
5. Full tool derlenebilir hale getir.
6. tests + tests_matrix + tests_fp + tests_math kos.
7. Matrisleri test sonucundan yeniden uret.

Detayli emir dosyasi: `copilot_emirleri/COPILOT_TEK_EMIR.md`.
