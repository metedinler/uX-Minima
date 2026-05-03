@echo off
setlocal
set FBC64=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe
if exist "%FBC64%" (
set FBC=%FBC64%
) else (
set FBC=fbc
)
set NASM=nasm
echo [1/4] Compiler derleniyor...
%FBC% -lang fb uxm31_compiler_fb.bas -x uxm.exe
if errorlevel 1 goto fail
if exist uxm31_compiler.exe del /q uxm31_compiler.exe >nul 2>nul
copy /y uxm.exe uxm31_compiler.exe >nul
echo [2/4] Test klasoru hazirlaniyor...
if not exist build mkdir build
echo [OK] Derleyici hazir: uxm.exe
echo.
echo Kullanim:
echo   build_one.bat tests\test01_print_A.uxm
echo.
goto end
:fail
echo HATA: build_all.bat basarisiz oldu.
:end
endlocal