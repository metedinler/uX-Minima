@echo off
setlocal
call build_all.bat
if errorlevel 1 goto fail
for %%F in (tests\*.uxm) do (
echo.
echo ========================================
echo TEST: %%F
echo ========================================
call build_one.bat "%%F"
if errorlevel 1 goto fail
)
echo.
echo Tum testler bitti.
goto end
:fail
echo Test zinciri hata ile durdu.
:end
endlocal