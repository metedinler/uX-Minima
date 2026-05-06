# Matris güncelleme kapısı.
# Kod değiştiyse ilgili matrisler güncellenmeden commit yapılmasını engellemek için kontrol scripti.

$changedCode = git status --porcelain | Select-String -Pattern '\.bas|\.ts|\.uxm|\.bat|\.json'
$changedMatrices = git status --porcelain | Select-String -Pattern 'uxm/reports/matrices/current|test_report_v3.csv|dashboard.csv|feature_checks.csv|four_hat|meta_servis|test_matrisi'

if($changedCode -and -not $changedMatrices){
    Write-Host "HATA: Kod/test değişmiş ama matris güncellenmemiş. Commit yapma." -ForegroundColor Red
    exit 1
}
Write-Host "OK: Matris kapısı geçti." -ForegroundColor Green
exit 0
