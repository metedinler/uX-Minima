param(
  [Parameter(Mandatory=$true)][string]$File,
  [string]$Message = "guncelle: $File"
)
# 03_COMMIT_PER_FILE_PUSH.ps1
$ErrorActionPreference = "Stop"

git status --short
if(-not (Test-Path $File)){
  Write-Error "Dosya bulunamadi: $File"
}

git add -- "$File"
git commit -m $Message -- "$File"
git push
