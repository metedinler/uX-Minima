# Belge-Kod OK Matrisi

Bu tablo, belgede hedeflenen maddelerin kodda karsiligini ve su anki durumunu gosterir.

| Baslik | Belge Hedefi | Kod Karsiligi | Durum |
|---|---|---|---|
| UXM -> ASM -> OBJ hatti | Calismali | build_all.bat + build_one.bat + NASM | OK |
| EXE uretimi | Calsin | x64 fbc ile runtime baglama (link) adimi | OK |
| D@T ailesi adresleme | Tam destek | uxm31_compiler_fb.bas parser/emitter | OK |
| @!N host meta cagri | Tam destek | uxm31_compiler_fb.bas ParseMeta + IMetaForce | OK |
| @# dinamik meta | Tam destek | compiler/runtime/full tool | OK |
| JSON iz kaydi | Tam destek | uxm31_full_tool_fb.bas | OK |
| UIR cikisi | Tam destek | uxm31_full_tool_fb.bas | OK |
| En iyilestirme raporu | Tam destek | uxm31_full_tool_fb.bas | OK |
| VS Code Internal Trace | Tam destek | ide/uxminima-vscode | OK |
| VS Code Build Native | Tam destek | ide/uxminima-vscode | OK |
| Derleyici adi uxm.exe | Yeni standart | build betikleri + eklenti varsayilani | OK |
| x64 FreeBASIC sabit yolu | Stabil derleme | build betikleri + eklenti ayarlari | OK |
| GitHub release | uxm.exe yayinlansin | v3.1.0 release + asset | OK |

## Not

- D@T ve @!N maddeleri aktif derleyici hattina dogrudan islenmistir.
- Aktif ortamda x64 fbc yolu sabitlenerek EXE uretimi dogrulandi.
