@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%" >nul
set FBC64=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe
if exist "%FBC64%" (
set FBC=%FBC64%
) else (
set FBC=fbc
)
set NASM=nasm
if "%~1"=="" goto usage
set "SRC=%~f1"
set MODE=%~2
set ARGEPARSE_COMPAT=1
if /I "%MODE%"=="R" set ARGEPARSE_COMPAT=0
set NAME=%~n1
set ASM=build\%NAME%.asm
set OBJ=build\%NAME%.o
set EXE=build\%NAME%.exe
set ASM_AR=build\program.asm
set OBJ_AR=build\program.obj
set EXE_AR=build\program.exe
if not exist build mkdir build
if not exist uxm.exe (
echo Derleyici bulunamadi. build_all.bat calistiriliyor...
call build_all.bat
if errorlevel 1 goto fail
)
echo [1/4] UXM -> ASM: %SRC%
uxm.exe "%SRC%" "%ASM%"
if errorlevel 1 goto fail
if not exist "%ASM%" (
if exist "%ASM_AR%" (
copy /y "%ASM_AR%" "%ASM%" >nul
) else (
echo HATA: ASM cikisi bulunamadi: %ASM%
goto fail
)
)
if "%ARGEPARSE_COMPAT%"=="1" copy /y "%ASM%" "%ASM_AR%" >nul
echo [2/4] ASM -> OBJ
%NASM% -f win64 "%ASM%" -o "%OBJ%"
if errorlevel 1 goto fail
if "%ARGEPARSE_COMPAT%"=="1" copy /y "%OBJ%" "%OBJ_AR%" >nul
echo [3/4] Runtime + OBJ -> EXE
%FBC% -x "%EXE%" "uxm\core\runtime\uxm31_runtime_fb_full.bas" "%OBJ%"
if errorlevel 1 goto fail
if "%ARGEPARSE_COMPAT%"=="1" copy /y "%EXE%" "%EXE_AR%" >nul
echo [4/4] Calistiriliyor...
"%EXE%"
if errorlevel 1 goto fail
if "%ARGEPARSE_COMPAT%"=="1" (
echo [ARGE] program alias aktif: program.asm/program.obj/program.exe
) else (
echo [ARGE] R modu: sadece gercek adli artefaktlar uretildi.
)
goto end
:usage
echo Kullanim:
echo   build_one.bat tests\test01_print_A.uxm
echo   build_one.bat tests\test01_print_A.uxm R
echo     R = sadece gercek adlar; ARGE program.* alias dosyalari uretilmez.
goto end
:fail
echo HATA: build_one.bat basarisiz oldu.
popd >nul
endlocal & exit /b 1
:end
popd >nul
endlocal & exit /b 0