param([switch]$Apply)
# 01_KLASOR_TEMIZLEME_GIT_MV.ps1
# Varsayilan kuru kosumdur. Gercek tasima icin -Apply kullan.

$ErrorActionPreference = "Stop"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
New-Item -ItemType Directory -Force reports | Out-Null

git status --short | Set-Content reports\before_cleanup_status.txt -Encoding UTF8
git diff --stat | Set-Content reports\before_cleanup_diffstat.txt -Encoding UTF8

$dirs = @(
"uxm/core/native_x64/src",
"uxm/core/runtime",
"uxm/core/full_tool_interpreter/src",
"uxm/core/final_arge",
"uxm/ide/vscode",
"uxm/tests/core",
"uxm/tests/fp",
"uxm/tests/matrix",
"uxm/tests/math",
"uxm/tests/ide",
"uxm/tests/final",
"uxm/tests/experimental",
"uxm/build/asm/current",
"uxm/build/asm/archive",
"uxm/build/obj/current",
"uxm/build/obj/archive",
"uxm/build/exe/current",
"uxm/build/exe/archive",
"uxm/build/logs/archive",
"uxm/reports/matrices",
"uxm/reports/json",
"uxm/reports/logs",
"uxm/plans",
"uxm/legacy/docs_old/$stamp",
"uxm/legacy/matrices_old/$stamp",
"uxm/legacy/raw_chat_extracts/$stamp",
"uxm/legacy/other_old/$stamp"
)
foreach($d in $dirs){ if($Apply){ New-Item -ItemType Directory -Force $d | Out-Null } ; Write-Output "DIR $d" }

# Aktif md kuralı: sadece iki plan dosyası kalacak.
# Diger md/txt/csv/xlsx eski bilgi sayilir ve manifest ile tasinir.
Write-Output "Klasorler hazir. Tasima icin matrisler/03 ve 04 manifestlerindeki git mv komutlari uygulanacak."
