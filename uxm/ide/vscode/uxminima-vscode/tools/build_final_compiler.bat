@echo off
setlocal
fbc uxm31_compiler_final.bas -x uxm31_compiler_final.exe
if errorlevel 1 goto fail
uxm31_compiler_final.exe --input examples\final_probe.uxm --mode all --asm build\final_probe.asm --uir build\final_probe.uir.json --diag build\final_probe.diag.json --trace build\final_probe.trace.ndjson --opt build\final_probe.opt.json
goto end
:fail
echo build failed
:end
endlocal
