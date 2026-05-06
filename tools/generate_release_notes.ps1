param(
    [string]$MasterDoc = "MASTER_TAKIP_DOKUMANI_V31.md",
    [string]$Output = "build/release_notes_auto.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-SectionLines {
    param(
        [string[]]$Lines,
        [string]$Header
    )

    $start = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].Trim() -eq $Header) {
            $start = $i + 1
            break
        }
    }

    if ($start -lt 0) {
        return @()
    }

    $result = New-Object System.Collections.Generic.List[string]
    for ($j = $start; $j -lt $Lines.Count; $j++) {
        $line = $Lines[$j]
        if ($line -match '^##\s+') {
            break
        }
        $result.Add($line)
    }
    return $result
}

function Get-SubsectionLines {
    param(
        [string[]]$Lines,
        [string]$SectionHeader,
        [string]$SubHeader
    )

    $section = Get-SectionLines -Lines $Lines -Header $SectionHeader
    if ($section.Count -eq 0) {
        return @()
    }

    $start = -1
    for ($i = 0; $i -lt $section.Count; $i++) {
        if ($section[$i].Trim() -eq $SubHeader) {
            $start = $i + 1
            break
        }
    }

    if ($start -lt 0) {
        return @()
    }

    $result = New-Object System.Collections.Generic.List[string]
    for ($j = $start; $j -lt $section.Count; $j++) {
        $line = $section[$j]
        if ($line -match '^\s*$') {
            if ($result.Count -gt 0) {
                break
            }
            continue
        }
        if ($line -match '^[A-Za-z].*:$') {
            break
        }
        $result.Add($line)
    }
    return $result
}

function Normalize-Bullets {
    param([string[]]$Lines)

    $out = New-Object System.Collections.Generic.List[string]
    foreach ($line in $Lines) {
        $trimmed = $line.Trim()
        if ($trimmed -eq "") {
            continue
        }
        if ($trimmed -match '^\d+\.\s+') {
            $item = $trimmed -replace '^\d+\.\s+', ''
            $out.Add("- $item")
        } elseif ($trimmed -match '^-\s+') {
            $out.Add($trimmed)
        } else {
            $out.Add("- $trimmed")
        }
    }
    return $out
}

if (-not (Test-Path $MasterDoc)) {
    throw "Master takip dosyasi bulunamadi: $MasterDoc"
}

$content = Get-Content -Path $MasterDoc
$kalan = @(Normalize-Bullets (Get-SubsectionLines -Lines $content -SectionHeader "## 12. Eski-Yeni Plan Senkron Durumu (2026-05-06)" -SubHeader "Kalan:"))
$tamamlanan = @(Normalize-Bullets (Get-SubsectionLines -Lines $content -SectionHeader "## 12. Eski-Yeni Plan Senkron Durumu (2026-05-06)" -SubHeader "Tamamlanan ek maddeler (2026-05-06 devam):"))
$riskler = @(Normalize-Bullets (Get-SectionLines -Lines $content -Header "### Acik Riskler"))

$release = New-Object System.Collections.Generic.List[string]
$release.Add("# UX-MINIMA Otomatik Release Notu")
$release.Add("")
$release.Add("Tarih: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$release.Add("Kaynak: $MasterDoc")
$release.Add("")
$release.Add("## Ozet")
$release.Add("- Bu dosya MASTER takip belgesinden otomatik uretilmistir.")
$release.Add("- Build/test durumunun son dogrulamasi ayri CI veya run_tests ciktisi ile teyit edilmelidir.")
$release.Add("")
$release.Add("## Tamamlananlar")
if ($tamamlanan.Length -eq 0) {
    $release.Add("- Bulunamadi")
} else {
    foreach ($item in $tamamlanan) {
        $release.Add([string]$item)
    }
}
$release.Add("")
$release.Add("## Kalanlar")
if ($kalan.Length -eq 0) {
    $release.Add("- Bulunamadi")
} else {
    foreach ($item in $kalan) {
        $release.Add([string]$item)
    }
}
$release.Add("")
$release.Add("## Acik Riskler")
if ($riskler.Length -eq 0) {
    $release.Add("- Bulunamadi")
} else {
    foreach ($item in $riskler) {
        $release.Add([string]$item)
    }
}

$outDir = Split-Path -Path $Output -Parent
if ($outDir -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

Set-Content -Path $Output -Value $release -Encoding UTF8
Write-Host "Release notu uretildi: $Output"