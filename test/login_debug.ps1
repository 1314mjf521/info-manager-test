# Login Debug Test
Write-Host "=== Login Debug Test ===" -ForegroundColor Green

$loginData = @{ username = "admin"; password = "admin123" }
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"

Write-Host "Login Response:" -ForegroundColor Yellow
$loginResponse | ConvertTo-Json -Depth 5 | Write-Host

Write-Host "`nResponse Properties:" -ForegroundColor Yellow
$loginResponse.PSObject.Properties | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Value)" -ForegroundColor White
}

if ($loginResponse.data) {
    Write-Host "`nData Properties:" -ForegroundColor Yellow
    $loginResponse.data.PSObject.Properties | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Value)" -ForegroundColor White
    }
}

Write-Host "`n=== Login Debug Completed ===" -ForegroundColor Green