# Belgede Olup Kodda Olmayanlar Raporu

Operasyonel takip referansi:
MASTER_TAKIP_DOKUMANI_V31.md

Bu rapor, ayrintili belge kopyalari ile aktif kod tabani arasindaki farklari cikarmak icin hazirlandi.
Kaynak belge klasoru: BELGE_KOPYALARI/
Kod taramasi: uxm31_*.bas, final/uxm31_compiler_final.bas, ide/uxminima-vscode/src, ide/uxminima-vscode/docs

## 1) Belgede var, kodda net bulunamayan veya parcali olanlar

1. Tam ve stabil final derleyici zinciri (tek hat)
- Belgelerde final hedefi ve tam zincir anlatiliyor.
- Kodda final hattinin parcalari var, ancak final dosyada deneysel/arge notlari baskin.

2. FP macro kutuphanesinin cekirdek zincire tam entegrasyonu
- Belgelerde UX-FP V1 ve macro odakli FP stratejisi cok detayli.
- Kodda FP yonu dokuman ve parcali kaynak seviyesinde; ana compiler/runtime/IDE akisinda tam kapanis yok.

3. Tum ortamlarda garantili EXE link adimi
- Belgede native EXE adimi standart akista anlatiliyor.
- Gercekte bu ortamda fbc obj link adimi bazi makinelerde hata verebiliyor.

## 2) Belgede iddia var, kodda karsiligi bulunanlar (False Gap degil)

1. JSON trace / UIR / optimizer
- Kodda mevcut (full tool ve final tarafinda).

2. FIFO servisleri (@90..@94)
- Runtime, full tool ve extension meta tablosunda mevcut.

3. Wild layout change (@127)
- Runtime tarafinda mevcut, extension docs/meta tarafinda mevcut.

4. Internal Trace ve Build Native komutlari
- Extension tarafinda mevcut komutlar ve toolchain akislari var.

5. D@T adresleme ailesi
- Aktif derleyici hattinda parser/emitter destegi eklendi.

6. @!N host zorlamali meta semantigi
- Aktif derleyici hattinda ParseMeta ve meta bayragi desteği eklendi.

## 3) Oncelikli kapatma sirasi

1. final/arge ile aktif hat arasinda tek otoriter parser/emitter katmani belirle.
2. FP macro kutuphanesi icin minimum calisan cekirdek seti sec ve testlerini aktif hatta ekle.
3. Link adimi icin ortam-bagimsiz fallback akisini standartlastir (ASM->OBJ kesin, EXE best-effort).

## 4) Sonuc

Belge-kod farklarinin buyuk kismi "ozellik yok" degil, "ozellik var ama tek hat ve stabil kapanmamis" tipindedir.
Bu nedenle bir sonraki teknik adim, yeni ozellik eklemekten cok ana hatta birlestirme ve standardizasyon olmalidir.
