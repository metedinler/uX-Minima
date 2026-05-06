# Değişen her dosyayı ayrı commit + push yapar.
# Dikkat: Çok fazla dosya varsa uzun sürer. Kullanıcı bunu özellikle istedi.

$ErrorActionPreference = "Continue"
$changes = git status --porcelain | ForEach-Object { $_.Substring(3) } | Where-Object { $_ -ne "" }
foreach($p in $changes){
    git add -- "$p"
    $safe = $p -replace '[^A-Za-z0-9_.\/-]+','_'
    git commit -m "uxm-v3: dosya guncelle $safe"
    if($LASTEXITCODE -eq 0){ git push }
}
