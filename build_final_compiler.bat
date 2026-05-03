@echo off
setlocal
if not exist build mkdir build
fbc final\uxm31_compiler_final.bas -x build\uxm31_compiler_final.exe
if errorlevel 1 goto fail
echo OK: build\uxm31_compiler_final.exe olustu.
goto end
:fail
echo HATA: final compiler derlenemedi.
:end
endlocal
