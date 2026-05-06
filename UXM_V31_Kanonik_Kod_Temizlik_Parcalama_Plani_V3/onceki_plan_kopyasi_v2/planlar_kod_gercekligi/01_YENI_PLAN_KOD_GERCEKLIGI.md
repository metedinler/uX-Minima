# 01_YENI_PLAN_KOD_GERCEKLIGI

Bu projenin tek gercegi koddur. Eski .md, .txt, bilgi ve plan dosyalari aktif karar kaynagi degildir. Hepsi `uxm/legacy/` altina tasinir.

Aktif belgeler sadece iki tanedir:

1. `uxm/plans/00_ESKI_PLAN_OZETI.md`
2. `uxm/plans/01_YENI_PLAN_KOD_GERCEKLIGI.md`

## Mimari hedef

Tek `uxm/` calisma agaci kurulacak. Dort hat korunacak:

1. Native x64 compiler hattı: UXM -> ASM -> OBJ -> EXE.
2. Full tool/interpreter hattı: interpreter, trace, UIR, optimizer, JSON.
3. Final/ARGE compiler hattı: diagnostics, UIR, ASM emitter, final probe.
4. VS Code IDE hattı: syntax, snippets, toolchain, trace/memory/report komutlari.

## Temel kabul kurali

Bir ozellik ancak su kanitlarla tamam sayilir:

1. Kaynak dosya temiz ve derlenebilir.
2. Test dosyasi var.
3. EXPECT_OUTPUT veya EXPECT_STATUS var.
4. Build/runner gercek hata kodu donduruyor.
5. JSON veya CSV raporda sonuc var.
6. Dort hatta karar var: PASS / FAIL / UNSUPPORTED / RESERVED / BROKEN_SOURCE.

## Ilk hedef

En az hamlede calisan sistem:

1. `uxm.exe` native compiler.
2. `uxm_full_tool.exe` interpreter/full tool.
3. `uxm_final.exe` final/ARGE compiler.
4. VS Code eklentisinin bu exe'leri kullanmasi.
5. ASM, OBJ, EXE ve JSON ciktisinin ayri klasorlerde saklanmasi.
6. FP/MAT/MATH servislerinin kalici runtime entegrasyonu.

## Yasaklar

1. Silme yok.
2. Yeni belge cehennemi yok.
3. Kod dosyasina markdown yok.
4. Testsiz VAR yok.
5. Ingilizce calisma gunlugu yok.
6. Soru sorulduysa once cevap verilecek.
7. Her dosya degisikligi ayri commit ve push olacak.
