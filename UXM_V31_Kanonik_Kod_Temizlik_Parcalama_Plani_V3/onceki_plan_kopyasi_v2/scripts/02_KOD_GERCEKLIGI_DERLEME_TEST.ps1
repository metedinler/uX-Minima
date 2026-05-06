# 02_KOD_GERCEKLIGI_DERLEME_TEST.ps1
$ErrorActionPreference = "Continue"
New-Item -ItemType Directory -Force uxm/reports/json, uxm/reports/logs, uxm/build/exe/current, uxm/build/asm/current, uxm/build/obj/current | Out-Null

$results = @()
function Add-Result($name,$cmd,$exit){
  $script:results += [PSCustomObject]@{ Name=$name; Command=$cmd; ExitCode=$exit; Time=(Get-Date).ToString("s") }
}

# Bu komutlar klasor tasinmasindan sonra yeni pathlere gore guncellenecek.
cmd /c "uxm\scripts\build_all.bat" *> uxm\reports\logs\build_all.log
Add-Result "native_build" "uxm/scripts/build_all.bat" $LASTEXITCODE

cmd /c "uxm\scripts\build_final_compiler.bat" *> uxm\reports\logs\build_final.log
Add-Result "final_build" "uxm/scripts/build_final_compiler.bat" $LASTEXITCODE

cmd /c "uxm\scripts\run_tests.bat" *> uxm\reports\logs\run_tests.log
Add-Result "run_tests" "uxm/scripts/run_tests.bat" $LASTEXITCODE

$results | ConvertTo-Json -Depth 4 | Set-Content uxm\reports\json\build_test_summary.json -Encoding UTF8
$results | Export-Csv -NoTypeInformation -Encoding UTF8 uxm\reports\matrices\build_test_summary.csv
