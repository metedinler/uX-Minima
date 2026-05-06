# UXM Compiler Mimari Aciklamasi - Kod Gercekligi

Bu mimari belgesi eski planlara gore degil, zip icindeki kaynak agacinin mevcut durumuna gore yazildi.

## 1. Dil yuzeyi

UXM, brainfuck benzeri basit bellek/tape fikrinden baslamis; daha sonra meta servisler, adresleme modlari, macro, stack, FIFO, data alanlari, matrix, decimal FP ve matematik servisleri eklenmis bir deneysel dildir.

## 2. Native x64 compiler hatti

Otorite kaynak: `uxm31_compiler_fb.bas`.

Bu hat UXM kaynak dosyasini okuyup x64 NASM tarzi ASM uretmeye calisir. Build ciktisi su sekilde ayrilmalidir:

- ASM: `uxm/build/asm/current/`
- OBJ/O: `uxm/build/obj/current/`
- EXE: `uxm/build/exe/current/uxm.exe`
- Log/JSON: `uxm/reports/json/native_build.json`

Bu hat projede en fazla gercek build artefakti olan hattir. Ancak build script hata kodlari duzeltilmeden guvenilir kabul edilemez.

## 3. Runtime katmani

Otorite kaynaklar:

- `uxm31_runtime_fb.bas`
- `uxm31_runtime_fb_full.bas`
- `runtime/runtime_fp_services.bas`
- `math_extensions/runtime/runtime_matrix_services.bas`
- `math_extensions/runtime/runtime_math_services.bas`

Runtime katmani meta servislerin gercek davranisini tasir. FP, matrix ve turev/integral burada kalici ortak servis olarak yer almalidir. Bunlar tak-cikar deney dosyasi gibi degil, runtime_full icine bagli ortak servis katmani olarak ele alinmalidir.

## 4. Full tool / interpreter hatti

Otorite aday kaynak: `uxm31_full_tool_fb.bas`.

Mevcut durum kiriktir. Dosya sohbet/markdown metni ile basladigi icin FreeBASIC kaynagi gibi kabul edilemez. Bu hattin hedefi:

- Interpreter
- Step trace
- UIR JSON
- Optimizer JSON
- Runtime servis denemeleri
- IDE protokol ciktisi

Once kaynak temizlenecek, sonra derlenecek.

## 5. Final / ARGE compiler hatti

Otorite kaynak: `final/uxm31_compiler_final.bas`.

Bu hat tek merkez final compiler hedefidir. Diagnostics, UIR, optimizer, interpreter ve ASM emitter ayni dosyada toplanmis gorunur. Ancak derleme riskleri vardir. `#Lang "fb"` ilk anlamli satir olmali; reserved isimler duzeltilmeli; build script hata kodu guvenilir hale getirilmelidir.

## 6. VS Code IDE hatti

Otorite kaynaklar:

- `ide/uxminima-vscode/package.json`
- `ide/uxminima-vscode/src/*.ts`
- `ide/uxminima-vscode/syntaxes/*`
- `ide/uxminima-vscode/snippets/*`

Eklenti vardir. Fakat eklenti tek basina compiler degildir. Kullandigi native/final/full exe dosyalari derlenmiyorsa VS Code komutlari da tamam sayilmaz.

## 7. Matris ve rapor ilkesi

Matrisler kaynak degildir. Matris, kod ve test sonucundan yeniden uretilen izleme aracidir. Eski matrisler `legacy/matrices_old` altinda saklanir. Yeni matrisler `uxm/reports/matrices` altinda koddan uretilir.
