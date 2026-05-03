# Kodda Olup Belgede Acik ve Toplu Gecmeyenler

Bu rapor, sistemde bulunan fakat kullanici kilavuzu ve ana tasarim belgelerinde daiginik kalan ozellikleri toplar.

## 1) IDE Internal Interpreter
- VS Code eklentisi yalnizca dis toolchain degil, internal trace/memory watch akisina da sahip.
- Bu akisin sinirlari ve farklari ana kilavuzda daha belirgin anlatilmali.

## 2) Toolchain Hata Dayanikliligi
- Native build zinciri, link adiminda hata oldugunda asm/obj artefaktlarini koruyarak ilerleyebiliyor.
- Bu davranis kullaniciya "kismi basari" modeli olarak dokumante edilmeli.

## 3) Analiz Artefaktlari
- ANALIZ_*.csv ve ANALIZ_KARSILASTIRMA.md dosyalari belge-kod dogrulama icin kullaniliyor.
- Ana kilavuzda bu dosyalarin amaci ve nasil okunacagi aciklanmali.

## 4) Coklu Derleyici Hatlari
- Ayni depoda clean compiler, aktif compiler, final/ARGE compiler hatlari bir arada.
- "Hangi dosya otoriter kaynak?" sorusuna tek satir cevap veren bir kaynak-oncelik tablosu eklenmeli.

## 5) Build Script Gercek Cikis Durumu
- Bazı batch scriptler hata durumunda da 0 donus kodu verebiliyor.
- CI/otomasyon icin log-icerik temelli basarisizlik kontrolu gerek.

## Kapanis
Bu maddeler kodda fiilen bulunan davranislardir. Ana kullanma kilavuzu ve tasarim belgelerine net bolumler halinde eklendiginde onboarding ve bakim maliyeti duser.
