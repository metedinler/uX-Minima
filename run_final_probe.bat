@echo off
setlocal
if not exist build mkdir build
if not exist build\uxm31_compiler_final.exe call build_final_compiler.bat
build\uxm31_compiler_final.exe --input final\examples\final_probe.uxm --mode all --asm build\final_probe.asm --uir build\final_probe.uir.json --diag build\final_probe.diag.json --trace build\final_probe.trace.ndjson --opt build\final_probe.opt.json
endlocal
