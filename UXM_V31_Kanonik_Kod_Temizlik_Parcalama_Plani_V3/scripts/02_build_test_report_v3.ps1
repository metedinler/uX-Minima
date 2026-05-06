# UXM V3 build/test/rapor scripti
$ErrorActionPreference = "Continue"

$FBC64="C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe"
$FBC = $(if (Test-Path $FBC64) { $FBC64 } else { "fbc" })
$NASM="nasm"

New-Item -ItemType Directory -Force -Path "uxm/build/asm/current","uxm/build/obj/current","uxm/build/exe/current","uxm/build/logs","uxm/reports/json" | Out-Null

# Native compiler build
& $FBC -lang fb "uxm/core/compiler/native/uxm31_compiler_fb.bas" -x "uxm/build/exe/current/uxm.exe" *> "uxm/build/logs/build_native_compiler.log"
$nativeOk = ($LASTEXITCODE -eq 0)

# Test runner: her klasörü ayrı raporlar
$testDirs = @("uxm/tests/native","uxm/tests/fp","uxm/tests/matrix","uxm/tests/math")
$rows = @()
foreach($d in $testDirs){
    if(!(Test-Path $d)){ continue }
    foreach($f in Get-ChildItem $d -Filter *.uxm){
        $name=$f.BaseName
        $asm="uxm/build/asm/current/$name.asm"
        $obj="uxm/build/obj/current/$name.o"
        $exe="uxm/build/exe/current/$name.exe"
        $log="uxm/build/logs/$name.log"
        if($nativeOk){
            & "uxm/build/exe/current/uxm.exe" $f.FullName $asm *> $log
            $asmOk = ($LASTEXITCODE -eq 0)
            if($asmOk){ & $NASM -f win64 $asm -o $obj *>> $log }
            $objOk = ($LASTEXITCODE -eq 0)
            if($objOk){ & $FBC -x $exe "uxm/core/runtime/uxm31_runtime_fb_full.bas" $obj *>> $log }
            $linkOk = ($LASTEXITCODE -eq 0)
            if($linkOk){ & $exe *>> $log }
            $runOk = ($LASTEXITCODE -eq 0)
        } else {
            $asmOk=$false; $objOk=$false; $linkOk=$false; $runOk=$false
        }
        $expect = Select-String -Path $f.FullName -Pattern '^#\s*EXPECT_' -Quiet
        $rows += [PSCustomObject]@{Test=$f.FullName; HasExpect=$expect; ASM=$asmOk; OBJ=$objOk; LINK=$linkOk; RUN=$runOk; Log=$log}
    }
}
$rows | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 "uxm/reports/json/test_report_v3.json"
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 "uxm/reports/matrices/current/test_report_v3.csv"

Write-Host "Build/test raporu üretildi: uxm/reports/json/test_report_v3.json"
