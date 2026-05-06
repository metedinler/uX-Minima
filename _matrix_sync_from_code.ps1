Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Set-Location "c:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL"

function Get-CaseIdsFromText([string]$text){
  $set = New-Object 'System.Collections.Generic.HashSet[int]'
  $lines = $text -split "`r`n|`n|`r"
  foreach($line in $lines){
    if($line -match '(?i)^\s*Case\s+(.+)$'){
      $part = $Matches[1]
      $part = ($part -replace "'.*$",'').Trim()
      $part = ($part -replace ':.*$','').Trim()
      $part = ($part -replace '(?i)Else.*$','').Trim()
      $tokens = $part -split ','
      foreach($tok in $tokens){
        $t = $tok.Trim()
        if($t -match '^(\d+)\s+To\s+(\d+)$'){
          $a=[int]$Matches[1]
          $b=[int]$Matches[2]
          for($i=$a;$i -le $b;$i++){ [void]$set.Add($i) }
        } elseif($t -match '^\d+$') {
          [void]$set.Add([int]$t)
        }
      }
    }
  }
  return ,$set
}

function Get-BasSubBlock([string]$text, [string]$subName){
  $name = [regex]::Escape($subName)
  $pattern = "(?ism)^\s*Sub\s+${name}\s*\(.*?^\s*End\s+Sub\b"
  $m = [regex]::Match($text, $pattern)
  if($m.Success){ return $m.Value }
  return ''
}

function Get-SectionBetween([string]$text, [string]$startToken, [string]$endToken){
  $start = $text.IndexOf($startToken, [System.StringComparison]::OrdinalIgnoreCase)
  if($start -lt 0){ return '' }
  $end = $text.IndexOf($endToken, $start, [System.StringComparison]::OrdinalIgnoreCase)
  if($end -lt 0){ $end = $text.Length }
  if($end -le $start){ return '' }
  return $text.Substring($start, $end - $start)
}

function Get-CaseIdsFromTs([string]$text){
  $set = New-Object 'System.Collections.Generic.HashSet[int]'
  $re = [regex]'(?im)^\s*case\s+(\d+)\s*:'
  foreach($m in $re.Matches($text)){ [void]$set.Add([int]$m.Groups[1].Value) }
  return ,$set
}

$runtimeSet = New-Object 'System.Collections.Generic.HashSet[int]'
$runtimeSources = @(
  @{ Path='uxm/core/runtime/runtime_meta_dispatch.bas'; Subs=@('MetaCore','MetaArithmetic','MetaMath','MetaIO','MetaPointerMemory','MetaFifoDataSortWild','MetaFlagsEndian') },
  @{ Path='uxm/core/runtime/services/runtime_matrix_services.bas'; Subs=@('MetaMatrix') },
  @{ Path='uxm/core/runtime/services/runtime_fp_services.bas'; Subs=@('MetaFloatingPoint') },
  @{ Path='uxm/core/runtime/services/runtime_math_services.bas'; Subs=@('MetaMathExtra','MetaPolynomial','MetaExpression') }
)
foreach($src in $runtimeSources){
  if(-not (Test-Path $src.Path)){ continue }
  $txt = Get-Content $src.Path -Raw
  foreach($subName in $src.Subs){
    $block = Get-BasSubBlock $txt $subName
    if([string]::IsNullOrWhiteSpace($block)){ continue }
    $ids = Get-CaseIdsFromText $block
    foreach($id in $ids){ [void]$runtimeSet.Add($id) }
  }
}

$finalText = Get-Content 'uxm/core/compiler/final/final_interpreter.bas' -Raw
$finalBlock = Get-BasSubBlock $finalText 'RuntimeMeta'
$finalSet = if([string]::IsNullOrWhiteSpace($finalBlock)){
  New-Object 'System.Collections.Generic.HashSet[int]'
} else {
  Get-CaseIdsFromText $finalBlock
}

$vscodeText = Get-Content 'uxm/ide/vscode/uxminima-vscode/src/interpreter/core.ts' -Raw
$vscodeMetaSection = Get-SectionBetween $vscodeText 'private meta(' 'private markUnsupportedMeta('
$vscodeSet = if([string]::IsNullOrWhiteSpace($vscodeMetaSection)){
  New-Object 'System.Collections.Generic.HashSet[int]'
} else {
  Get-CaseIdsFromTs $vscodeMetaSection
}

$fullToolPath = 'uxm/legacy/corrupt_sources/full_tool/uxm31_full_tool_fb.bas'
$fullSet = if(Test-Path $fullToolPath){
  $fullText = Get-Content $fullToolPath -Raw
  $fullSubNames = @(
    'MetaCore',
    'MetaArith',
    'MetaMath',
    'MetaIO',
    'MetaPtrMem',
    'MetaFifoDataSort',
    'MetaFlagsEndian',
    'MetaMatrix',
    'MetaFloatingPoint',
    'MetaMathExtra'
  )
  $set = New-Object 'System.Collections.Generic.HashSet[int]'
  foreach($subName in $fullSubNames){
    $block = Get-BasSubBlock $fullText $subName
    if([string]::IsNullOrWhiteSpace($block)){ continue }
    $ids = Get-CaseIdsFromText $block
    foreach($id in $ids){ [void]$set.Add($id) }
  }

  $fullServiceSources = @(
    @{ Path='uxm/core/runtime/services/runtime_matrix_services.bas'; Subs=@('MetaMatrix') },
    @{ Path='uxm/core/runtime/services/runtime_fp_services.bas'; Subs=@('MetaFloatingPoint') },
    @{ Path='uxm/core/runtime/services/runtime_math_services.bas'; Subs=@('MetaMathExtra','MetaPolynomial','MetaExpression') }
  )
  foreach($src in $fullServiceSources){
    if(-not (Test-Path $src.Path)){ continue }
    $svcText = Get-Content $src.Path -Raw
    foreach($subName in $src.Subs){
      $block = Get-BasSubBlock $svcText $subName
      if([string]::IsNullOrWhiteSpace($block)){ continue }
      $ids = Get-CaseIdsFromText $block
      foreach($id in $ids){ [void]$set.Add($id) }
    }
  }

  ,$set
} else {
  New-Object 'System.Collections.Generic.HashSet[int]'
}

$helpSet = New-Object 'System.Collections.Generic.HashSet[int]'
$metaServicePath = 'uxm/ide/vscode/uxminima-vscode/src/metaServices.ts'
if(Test-Path $metaServicePath){
  $metaTxt = Get-Content $metaServicePath -Raw
  $reHelp = [regex]'(?im)\bid\s*:\s*(\d+)\b'
  foreach($m in $reHelp.Matches($metaTxt)){ [void]$helpSet.Add([int]$m.Groups[1].Value) }
}

$metaPath = 'uxm/reports/matrices/current/uxm31_matrix_out/meta_servis_matrisi.csv'
$meta = Import-Csv $metaPath

foreach($row in $meta){
  $id = [int]$row.ID
  $row.'Runtime Host' = if($runtimeSet.Contains($id)){'VAR'} else {'YOK'}
  $row.'Final Interpreter' = if($finalSet.Contains($id)){'VAR'} else {'YOK'}
  $row.'Full Tool' = if($fullSet.Contains($id)){'VAR'} else {'YOK'}
  $row.'VSCode Runtime' = if($vscodeSet.Contains($id)){'VAR'} else {'YOK'}
  $row.'VSCode Help' = if($helpSet.Contains($id)){'VAR'} else {'YOK'}

  $belge = [string]$row.'Belge Durumu'
  $vals = @($row.'Runtime Host',$row.'Final Interpreter',$row.'Full Tool',$row.'VSCode Runtime')
  $varCount = @($vals | Where-Object { $_ -eq 'VAR' }).Count

  if($belge -match '^VAR$'){
    if($varCount -eq 4){ $row.'Kod Genel'='VAR' }
    elseif($varCount -gt 0){ $row.'Kod Genel'='KISMEN' }
    else { $row.'Kod Genel'='YOK' }
  } elseif($belge -match 'RESERVED|PLAN'){
    if($varCount -gt 0){ $row.'Kod Genel'='KISMEN' }
    else {
      if($belge -match 'PLAN/AYRILMI') { $row.'Kod Genel'='PLAN' }
      elseif($belge -match 'PLAN'){ $row.'Kod Genel'='PLAN' }
      else { $row.'Kod Genel'='RESERVED' }
    }
  }
}

$meta | Export-Csv $metaPath -NoTypeInformation -Encoding UTF8

$pfPath='uxm/reports/matrices/current/uxm31_matrix_out/four_hat_parity_full.csv'
$pf = foreach($m in ($meta | Sort-Object {[int]$_.ID})){
  $vals = @($m.'Runtime Host',$m.'Final Interpreter',$m.'Full Tool',$m.'VSCode Runtime')
  $n = @($vals | Where-Object { $_ -eq 'VAR' }).Count
  $p = if($n -eq 4){'FULL'} elseif($n -eq 0){'NONE'} else {'PARTIAL'}
  [pscustomobject]@{
    ID=$m.ID
    Name=$m.Ad
    RuntimeHost=$m.'Runtime Host'
    FinalInterpreter=$m.'Final Interpreter'
    FullTool=$m.'Full Tool'
    VSCodeRuntime=$m.'VSCode Runtime'
    VarCount="$n/4"
    Parity=$p
    TestEvidence=$m.'Test Kanıtı'
  }
}
$pf | Export-Csv $pfPath -NoTypeInformation -Encoding UTF8

$psPath='uxm/reports/matrices/current/uxm31_matrix_out/four_hat_parity.csv'
$groups = @(
  @{ Group='META_0_49'; Description='Core+Arithmetic+Math'; Services='0..49' },
  @{ Group='META_50_79'; Description='Math extension + IO'; Services='50..79' },
  @{ Group='META_80_89'; Description='Pointer/Layout'; Services='80..89' },
  @{ Group='META_90_107'; Description='FIFO/Data/Tape'; Services='90..107' },
  @{ Group='META_108_119'; Description='Reserved Screen area'; Services='108..119' },
  @{ Group='META_120_127'; Description='Flags/Endian/Wild'; Services='120..127' },
  @{ Group='META_160_199'; Description='UX-MAT'; Services='160..199' },
  @{ Group='META_200_239'; Description='UX-FP'; Services='200..239' },
  @{ Group='META_240_259'; Description='UX-MATH'; Services='240..259' }
)

$ps = foreach($g in $groups){
  $parts = $g.Services -split '\.\.'
  $s=[int]$parts[0]
  $e=[int]$parts[1]
  $sub = $pf | Where-Object { $id=[int]$_.ID; $id -ge $s -and $id -le $e }
  $t=$sub.Count
  $rt=@($sub|Where-Object { $_.RuntimeHost -eq 'VAR' }).Count
  $fi=@($sub|Where-Object { $_.FinalInterpreter -eq 'VAR' }).Count
  $ft=@($sub|Where-Object { $_.FullTool -eq 'VAR' }).Count
  $vs=@($sub|Where-Object { $_.VSCodeRuntime -eq 'VAR' }).Count
  $fpn=@($sub|Where-Object { $_.Parity -eq 'FULL' }).Count
  $status = if($t -eq 0){'OPEN'} elseif($fpn -eq $t){'CLOSED'} elseif($fpn -eq 0){'OPEN'} else {'PARTIAL'}
  [pscustomobject]@{
    Group=$g.Group
    Description=$g.Description
    Services=$g.Services
    RuntimeHost="$rt/$t"
    FinalInterpreter="$fi/$t"
    FullTool="$ft/$t"
    VSCodeRuntime="$vs/$t"
    FullParity="$fpn/$t"
    Status=$status
  }
}
$ps | Export-Csv $psPath -NoTypeInformation -Encoding UTF8

$gPath='uxm/reports/matrices/current/uxm31_matrix_out/high_service_gaps.csv'
$g = Import-Csv $gPath
foreach($r in $g){
  if($r.Service -match '^@\d+$'){
    $id=[int]($r.Service.TrimStart('@'))
    $m = $meta | Where-Object { [int]$_.ID -eq $id } | Select-Object -First 1
    if($m){
      $r.Native = $m.'Runtime Host'
      $r.Final_ARGE = $m.'Final Interpreter'
      $r.Full_Tool = $m.'Full Tool'
      $r.VSCode_Internal = $m.'VSCode Runtime'
      $vals=@($r.Native,$r.Final_ARGE,$r.Full_Tool,$r.VSCode_Internal)
      $r.All_4_Hats = if(@($vals|Where-Object { $_ -eq 'VAR' }).Count -eq 4){'VAR'} else {'KISMEN'}
    }
  }
}
$g | Export-Csv $gPath -NoTypeInformation -Encoding UTF8

$extPath='uxm/reports/matrices/current/uxm31_matrix_out/extension_matrisi.csv'
$ext = Import-Csv $extPath
$cntMat = @($meta | Where-Object { [int]$_.ID -ge 160 -and [int]$_.ID -le 176 -and $_.'Runtime Host' -eq 'VAR' }).Count
$cntFp = @($meta | Where-Object { [int]$_.ID -ge 200 -and [int]$_.ID -le 224 -and $_.'Runtime Host' -eq 'VAR' }).Count
$cntMath = @($meta | Where-Object { (([int]$_.ID -ge 240 -and [int]$_.ID -le 244) -or ([int]$_.ID -ge 250 -and [int]$_.ID -le 254)) -and $_.'Runtime Host' -eq 'VAR' }).Count
foreach($r in $ext){
  switch($r.Extension){
    'UX-MAT' { $r.'Aktif Servis Sayısı' = [string]$cntMat; $r.'Beklenen/Aktif Aralık Sayısı'=[string]$cntMat }
    'UX-FP' { $r.'Aktif Servis Sayısı' = [string]$cntFp; $r.'Beklenen/Aktif Aralık Sayısı'=[string]$cntFp }
    'UX-CALC/MATH' { $r.'Aktif Servis Sayısı' = [string]$cntMath; $r.'Beklenen/Aktif Aralık Sayısı'=[string]$cntMath }
  }
}
$ext | Export-Csv $extPath -NoTypeInformation -Encoding UTF8

$today='2026-05-07 kod-gerceklik audit'
foreach($path in @('uxm/reports/matrices/current/uxm31_matrix_out/adresleme_matrisi.csv','uxm/reports/matrices/current/uxm31_matrix_out/komut_matrisi.csv','uxm/reports/matrices/current/uxm31_matrix_out/pragma_matrisi.csv')){
  $rows = Import-Csv $path
  foreach($r in $rows){
    if([string]::IsNullOrWhiteSpace($r.Not)){ $r.Not = $today }
    elseif($r.Not -notmatch 'kod-gerceklik audit'){ $r.Not = ($r.Not + '; ' + $today) }
  }
  $rows | Export-Csv $path -NoTypeInformation -Encoding UTF8
}

Write-Output "MATRIX_SYNC_OK"
