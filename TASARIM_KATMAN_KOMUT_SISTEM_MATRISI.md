# UX-MINIMA Tasarim Katman Komut Sistem Matrisi

Bu belge, tasarim dokumanlari ile aktif kod tabanini ayni tabloda toplar.
Kaynaklar: kullanma kilavuzu, full v31 notlari, IDE protokol/spec belgeleri, pck notlari ve aktif .bas/.ts kodu.

## 1) Katman Matrisi

| Katman | Tasarimda Durum | Kodda Durum | Not |
|---|---|---|---|
| Dil cekirdegi (>,<,+,-,0,.,,,[,]) | Var | Var | Calisan compiler hattinda mevcut |
| Stack/FIFO/Data modeli | Var | Var | Runtime ve full tool tarafinda var |
| Meta servis cagrilari (@N, @#) | Var | Var | Cekirdek meta servisler mevcut |
| Gelismis adresleme (D@T, D@(T-2)+N vb.) | Var | Kismi | Belgede net; aktif compiler hattinda tam degil, final ARGE kaynakta parcali |
| Wild mode layout degisimi | Var | Kismi | Tasarim var, kodda parcali/deneysel |
| JSON trace/UIR/optimizer | Var | Var | full tool + IDE dokumanlariyla uyumlu |
| Native x64 NASM->OBJ->EXE | Var | Kismi | ASM/OBJ uretiliyor; bu ortamda EXE link adimi blokajli |
| VS Code extension entegrasyonu | Var | Var | TypeScript eklenti derleniyor |
| FP/Decimal meta sistemi | Tasarimda guclu | Kismi | UX-FP V1 belgede detayli; runtime/compiler ile tam birlesim eksik |

## 2) Komut/Kabiliyet Matrisi

| Baslik | Tasarim | Kod | Durum |
|---|---|---|---|
| Temel tape islemleri | Desteklenir | Desteklenir | Tam |
| Loop ve kosullu akis | Desteklenir | Desteklenir | Tam |
| String tanim/pprint (sN/pN) | Desteklenir | Desteklenir | Tam |
| Branch yon/flag tabanli | Desteklenir | Desteklenir | Tam |
| Meta cagrilari (core/arith/math/io) | Desteklenir | Desteklenir | Tam |
| Dynamic meta (@#) | Desteklenir | Desteklenir | Tam |
| Host zorlamali meta (@!N) | Oneri/tasarim notu var | Net degil | Gap |
| D@T ailesi adresleme | Belgede var | Kismi/ayri dallarda | Gap |
| Final compiler tek dosyada tam pipeline | Hedefleniyor | Deneysel | Gap |

## 3) Tasarimda Olup Kodda Eksik/Kismi Olanlar

1. Gelismis D@T adresleme ailesinin aktif, stabil ve tek hatta calisiyor olmasi.
2. @!N (host meta force) semantiginin net ve tamamlanmis implementasyonu.
3. FP (decimal) servislerinin cekirdek runtime + compiler + IDE zincirine tam baglanmasi.
4. EXE link adiminin tum ortamlarda deterministik calismasi.

## 4) Kodda Olup Tasarim Belgelerinde Daginik Gecenler

1. IDE tarafinda internal trace ve memory watch implementasyonu (dokumanlarda var ama daginik).
2. Toolchain tarafinda hata toleransli derleme fallback davranislari.
3. Analiz CSV ciktilari ile belge-kod dogrulama artefaktlari.

## 5) Onerilen Kapanis Plani

1. Adresleme semantigini tek kaynakli hale getir (spec -> parser -> emitter).
2. FP servisleri icin minimum calisan cekirdek seti belirle ve runtime'a bagla.
3. Link adimi icin ortam-bagimsiz script/arg standardi tanimla.
4. Her buyuk degisiklikte bu matrisi guncelle.
