# UXM V3 temiz çalışma ağacı kurulum scripti
# Silme yok. git mv veya Move-Item fallback.
# Çalıştırmadan önce repo kökünde olduğundan emin ol.

$ErrorActionPreference = "Stop"

function Ensure-Dir($p) {
    if (!(Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
}

function Move-GitSafe($src, $dst) {
    if (!(Test-Path -LiteralPath $src)) { Write-Host "YOK: $src"; return }
    Ensure-Dir (Split-Path -Parent $dst)
    git ls-files --error-unmatch -- "$src" *> $null
    if ($LASTEXITCODE -eq 0) {
        git mv "$src" "$dst"
    } else {
        Move-Item -LiteralPath $src -Destination $dst
        git add "$dst"
    }
    git status --short
}

# 1. Ana klasörler
$dirs = @(
"uxm/core/compiler/native",
"uxm/core/compiler/final",
"uxm/core/compiler/extensions",
"uxm/core/runtime/services",
"uxm/ide/vscode",
"uxm/tests/native",
"uxm/tests/fp",
"uxm/tests/matrix",
"uxm/tests/math",
"uxm/tests/final",
"uxm/tests/ide",
"uxm/build/asm/current",
"uxm/build/asm/archive",
"uxm/build/obj/current",
"uxm/build/obj/archive",
"uxm/build/exe/current",
"uxm/build/logs",
"uxm/reports/json",
"uxm/reports/matrices/current",
"uxm/reports/matrices/archive",
"uxm/docs/plans/current",
"uxm/docs/architecture",
"uxm/legacy/docs_old",
"uxm/legacy/duplicates",
"uxm/legacy/corrupt_sources/full_tool",
"uxm/legacy/node_modules_snapshot",
"uxm/legacy/build_old/imported"
)
$dirs | ForEach-Object { Ensure-Dir $_ }

git add uxm

git status --short | Out-File -Encoding UTF8 "uxm/build/logs/git_status_before_cleaning.txt"

# 2. Kanonik kaynaklar
Move-GitSafe "uxm31_compiler_fb.bas" "uxm/core/compiler/native/uxm31_compiler_fb.bas"
Move-GitSafe "uxm31_runtime_fb_full.bas" "uxm/core/runtime/uxm31_runtime_fb_full.bas"
Move-GitSafe "runtime/runtime_fp_services.bas" "uxm/core/runtime/services/runtime_fp_services.bas"
Move-GitSafe "math_extensions/runtime/runtime_matrix_services.bas" "uxm/core/runtime/services/runtime_matrix_services.bas"
Move-GitSafe "math_extensions/runtime/runtime_math_services.bas" "uxm/core/runtime/services/runtime_math_services.bas"
Move-GitSafe "final/uxm31_compiler_final.bas" "uxm/core/compiler/final/uxm31_compiler_final.bas"
Move-GitSafe "math_extensions/compiler/arge_parse_math_additions.bas" "uxm/core/compiler/extensions/arge_parse_math_additions.bas"
Move-GitSafe "math_extensions/compiler/arge_parse_matrix_additions.bas" "uxm/core/compiler/extensions/arge_parse_matrix_additions.bas"

# 3. Kırık/kanonik olmayan kaynaklar
Move-GitSafe "uxm31_full_tool_fb.bas" "uxm/legacy/corrupt_sources/full_tool/uxm31_full_tool_fb.bas"
Move-GitSafe "uxm31_full_tool_fb_2.bas" "uxm/legacy/corrupt_sources/full_tool/uxm31_full_tool_fb_2.bas"
Move-GitSafe "uxm31_compiler_fb.clean.bas" "uxm/legacy/duplicates/compiler/uxm31_compiler_fb.clean.bas"
Move-GitSafe "uxm31_runtime_fb.bas" "uxm/legacy/duplicates/runtime/uxm31_runtime_fb.bas"

# 4. Testler
Get-ChildItem tests -Filter *.uxm -ErrorAction SilentlyContinue | ForEach-Object { Move-GitSafe $_.FullName "uxm/tests/native/$($_.Name)" }
Get-ChildItem tests_fp -Filter *.uxm -ErrorAction SilentlyContinue | ForEach-Object { Move-GitSafe $_.FullName "uxm/tests/fp/$($_.Name)" }
Get-ChildItem tests_matrix -Filter *.uxm -ErrorAction SilentlyContinue | ForEach-Object { Move-GitSafe $_.FullName "uxm/tests/matrix/$($_.Name)" }
Get-ChildItem math_extensions/tests_math -Filter *.uxm -ErrorAction SilentlyContinue | ForEach-Object { Move-GitSafe $_.FullName "uxm/tests/math/$($_.Name)" }
Get-ChildItem final/examples -Filter *.uxm -ErrorAction SilentlyContinue | ForEach-Object { Move-GitSafe $_.FullName "uxm/tests/final/$($_.Name)" }
Get-ChildItem ide/uxminima-vscode/examples -Filter *.uxm -ErrorAction SilentlyContinue | ForEach-Object { Move-GitSafe $_.FullName "uxm/tests/ide/$($_.Name)" }

# 5. Matrisler aktif rapor sistemine
Move-GitSafe "UXM_V31_Kod_Belge_Matris_Paketi/uxm31_matrix_out" "uxm/reports/matrices/current/uxm31_matrix_out"
Move-GitSafe "UXM_V31_Kod_Belge_Matris_Paketi/UXM_V31_CSV_Matris_Paketi" "uxm/reports/matrices/current/UXM_V31_CSV_Matris_Paketi"

# 6. IDE; node_modules aktif hattan çıkacak
Move-GitSafe "ide/uxminima-vscode/node_modules" "uxm/legacy/node_modules_snapshot/ide_node_modules"
Move-GitSafe "ide/uxminima-vscode" "uxm/ide/vscode"

# 7. Eski build artefaktları
Move-GitSafe "build" "uxm/legacy/build_old/imported/build"

# 8. Eski bilgi belgeleri: kökte kalan md/txt dosyaları legacy'ye taşınır
Get-ChildItem -File -Include *.md,*.txt -ErrorAction SilentlyContinue | ForEach-Object {
    Move-GitSafe $_.FullName "uxm/legacy/docs_old/$($_.Name)"
}

# 9. Eski belge klasörleri
Move-GitSafe "BELGE_KOPYALARI" "uxm/legacy/docs_old/BELGE_KOPYALARI"
Move-GitSafe "UX-FP V1" "uxm/legacy/docs_old/UX-FP V1"

# 10. Aktif iki plan dosyası iskeleti
@" 
# Eski Plan Özeti

Bu dosya kod gerçekliğiyle yeniden üretilecektir.
"@ | Set-Content -Encoding UTF8 "uxm/docs/plans/current/00_ESKI_PLAN_OZETI.md"
@" 
# Yeni Plan Kod Gerçekliği

Bu dosya build/test/matris kanıtıyla güncellenecektir.
"@ | Set-Content -Encoding UTF8 "uxm/docs/plans/current/01_YENI_PLAN_KOD_GERCEKLIGI.md"

git add uxm
Write-Host "V3 temizlik ağacı hazır. Şimdi dosya dosya commit/push scriptini çalıştır."
