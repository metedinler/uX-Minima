@echo off
setlocal
set FBC64=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe
if exist "%FBC64%" (
set FBC=%FBC64%
) else (
set FBC=fbc
)
set NASM=nasm
if "%~1"=="" goto usage
set SRC=%~1
set NAME=%~n1
set ASM=build\%NAME%.asm
set OBJ=build\%NAME%.o
set EXE=build\%NAME%.exe
if not exist build mkdir build
if not exist uxm.exe (
echo Derleyici bulunamadi. Once build_all.bat calistir.
goto fail
)
echo [1/4] UXM -> ASM: %SRC%
uxm.exe "%SRC%" "%ASM%"
if errorlevel 1 goto fail
echo [2/4] ASM -> OBJ
%NASM% -f win64 "%ASM%" -o "%OBJ%"
if errorlevel 1 goto fail
echo [3/4] Runtime + OBJ -> EXE
%FBC% -x "%EXE%" uxm31_runtime_fb_full.bas "%OBJ%"
if errorlevel 1 goto fail
echo [4/4] Calistiriliyor...
"%EXE%"
goto end
:usage
echo Kullanim:
echo   build_one.bat tests\test01_print_A.uxm
goto end
:fail
echo HATA: build_one.bat basarisiz oldu.
:end
endlocal