# Belge-Kod OK Matrisi

Bu tablo, belgede hedeflenen maddelerin kodda karsiligini ve su anki durumunu gosterir.

| Baslik | Belge Hedefi | Kod Karsiligi | Durum |
|---|---|---|---|
| UXM -> ASM -> OBJ hatti | Calismali | build_all.bat + build_one.bat + NASM | OK |
| EXE uretimi | Calsin | fbc runtime baglama (link) adimi | Ortama bagli |
| D@T ailesi adresleme | Tam destek | uxm31_compiler_fb.bas parser/emitter | OK |
| @!N host meta cagri | Tam destek | uxm31_compiler_fb.bas ParseMeta + IMetaForce | OK |
| @# dinamik meta | Tam destek | compiler/runtime/full tool | OK |
| JSON iz kaydi | Tam destek | uxm31_full_tool_fb.bas | OK |
| UIR cikisi | Tam destek | uxm31_full_tool_fb.bas | OK |
| En iyilestirme raporu | Tam destek | uxm31_full_tool_fb.bas | OK |
| VS Code Internal Trace | Tam destek | ide/uxminima-vscode | OK |
| VS Code Build Native | Tam destek | ide/uxminima-vscode | OK |
| Derleyici adi uxm.exe | Yeni standart | build betikleri + eklenti varsayilani | OK |

## Not

- D@T ve @!N maddeleri aktif derleyici hattina dogrudan islenmistir.
- EXE uretimi icin temel akisin cogu ortamda calismasi beklenir; yine de baglama adimi ortama bagli fark gosterebilir.
