# Teknik Not ve Eklenti Calistirma

## Onemli teknik not

Bu ortamda fbc, obj link adiminda hata verebiliyor; bu yuzden EXE uretimi her makinede garanti degil.
Buna ragmen su an derleyici hatti UXM -> ASM -> OBJ seviyesinde calisir durumda.
Eklenti icinde de bu nedenle build komutu artik link dusse bile isi tamamen iptal etmiyor.

## Eklentiyi calistirma adimlari

1. uxminima-vscode klasorunu VS Code'da ac.
2. F5 ile Extension Development Host baslat.
3. Bir .uxm dosyasinda once UX-MINIMA: Internal Trace komutunu calistir.
4. Ardindan UX-MINIMA: Build Native komutunu calistirip ASM/OBJ uretimini dogrula.

## Uygulama onerisi

1. Kisa vadede ana basari kriteri: ASM ve OBJ uretiminin deterministik calismasi.
2. EXE adimini ortama bagli best-effort kabul et; hata durumunda artefaktlari koru.
3. Sonraki asamada final hedef: uxm31_compiler_final.bas dosyasini derlenir hale getirip full tool zincirini tek hatta toparla.
