@echo off
setlocal
powershell -ExecutionPolicy Bypass -File tools\generate_release_notes.ps1 -MasterDoc MASTER_TAKIP_DOKUMANI_V31.md -Output build\release_notes_auto.md
if errorlevel 1 goto fail
echo [OK] release notu hazir: build\release_notes_auto.md
goto end
:fail
echo HATA: release notu uretimi basarisiz.
exit /b 1
:end
endlocal