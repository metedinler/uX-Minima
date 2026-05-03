# UX-MINIMA V3.1 Master Takip Dokumani

Mete abi, bu dosya artik tek kaynak takip belgesidir.
Amac: daginik belgelerde degisen karar ve hedefleri tek yerde, ayni anlatim disiplini ile toplamak.

## 1. Neden bu belge var?

Belgelerde ayni konu farkli tarihlerde farkli sekilde guncellendi.
Bu nedenle su ihtiyac dogdu:

- Tek otorite belge olsun.
- Teknik gercek durum ile hedef durum ayri ayri yazilsin.
- Yapilacaklar sirali ve takip edilebilir olsun.
- Her buyuk degisiklikte hangi dosyanin guncellenecegi net olsun.

Bu belge bu ihtiyaci karsilar.

## 2. Belge Hiyerarsisi (Okuma Sirasi)

1. Bu dosya: MASTER_TAKIP_DOKUMANI_V31.md
2. Birlesik kullanim klavuzu: KULLANIM_KILAVUZU_BIRLESIK_V31.md
3. Teknik gercekler: TEKNIK_NOT_VE_EKLENTI_CALISTIRMA.md
4. Belge-kod farklari: BELGEDE_OLUP_KODDA_OLMAYANLAR_RAPORU.md
5. Kapsam matrisi: TASARIM_KATMAN_KOMUT_SISTEM_MATRISI.md
6. Kaynak arsiv: BELGE_KOPYALARI/

Kural:
Bu dosya plan ve disiplin dosyasidir.
Diger dosyalar bu dosyanin alt kanit ve detay dosyalaridir.

## 3. Kesin Teknik Gercek Durum

1. Aktif repo: calisilan/uxm31_FULL_FINAL_REAL ve origin senkronu tamam.
2. x64 FreeBASIC yolu build betiklerine ve eklenti ayarlarina sabitlendi.
3. Derleyici hatti UXM -> ASM -> OBJ -> EXE olarak calisir durumda.
4. run_tests.bat zinciri bastan sona tamamlanir.
5. VS Code eklentisi Internal Trace ve Build Native komutlari aktif.
6. GitHub release v3.1.0 olusturuldu ve uxm.exe asset olarak yayinlandi.

## 4. Hedef Mimari (Tek Cumle)

Tek kaynakli parser-emitter semantigi ile, aktif compiler + full tool + runtime + VS Code eklentisinin ayni dil davranisini vermesi.

## 5. Onceliklendirilmis Is Paketi

### A. Birlestirme (en onemli)

1. D@T adresleme ailesini aktif hatti tek kaynakli semantik ile kapat.
2. @!N host meta force davranisini aktif hatta standartlastir.
3. final/arge ve aktif compiler arasinda otoriter parser-emitter katmanini tekillestir.

Basari olcutu:

- Ayni test dosyasi active/final hatlarda ayni parse-emission sonucunu vermeli.

### B. Calisirlik ve Dogrulama

1. ASM ve OBJ uretimi deterministik kalsin.
2. EXE adimi best-effort olarak kosulsun.
3. Link dusse bile log + asm + obj saklansin.

Basari olcutu:

- Derleme raporunda ASM/OBJ kesin, EXE ortam-bagimli olarak etiketlenmeli.

### C. FP Entegrasyonu

1. UX-FP V1 icin minimum cekirdek macro setini sec.
2. Bu seti runtime ve compiler zincirine testlerle bagla.
3. Sonra genisletilmis FP servislerine gec.

Basari olcutu:

- En az bir FP smoke test aktif hatta otomatik gecmeli.

## 6. Eklenti Calisma Protokolu

1. ide/uxminima-vscode klasorunu ac.
2. F5 ile Extension Development Host baslat.
3. Bir .uxm dosyasinda Internal Trace calistir.
4. Ardindan Build Native calistir.
5. ASM/OBJ ciktilarini dogrula.

Not:
Bu protokolde basari kriteri once ASM/OBJ'dir.
EXE sonucu ortam bagimli kabul edilir.

## 7. Belge Disiplini (Bundan Sonra)

1. Yeni karar once bu dosyaya yazilir.
2. Sonra ilgili detay dosyasi guncellenir.
3. Commit mesaji Turkce olur.
4. Buyuk degisiklikte matris ve gap raporu ayni turda guncellenir.

## 8. Kaynaklar (Bu belgeyi besleyenler)

- uX_Minima_Kullanim Klavuzu.md
- ux_minima_full v31.md
- ux_minima_IDE_vscode.md
- ux_minimax_ide_tasarimi_dusuncesi.md
- yeni tasarim eksiklikler.md
- gercek_durum.md
- BELGE_KOPYALARI/ altindaki tum detay belgeler

## 9. Takip Formati

Bu formati kullan:

### Son Guncelleme

- Tarih: 2026-05-04
- Ozet: x64 toolchain sabitlendi, test zinciri tamamlandi, VSIX paketlendi ve release acildi.
- Degisen dosyalar: build_all.bat, build_one.bat, ide/uxminima-vscode/package.json, ide/uxminima-vscode/src/toolchain.ts, tests/test32_wild_layout_change.uxm, README.md, .vscode/settings.json
- Sonraki adim: remaining belge dosyalarinda yeni teknik gerceklerin yansimasi ve dokuman dili son cilasi.

### Acik Riskler

1. Link adimi ortam farki.
2. Active/final semantik sapmasi.
3. FP entegrasyonunun yari kalma riski.

Bu dosya, su andan itibaren operasyonel ana belge olarak kullanilacaktir.
