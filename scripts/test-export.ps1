# Test Export Functionality
Write-Host "=== TESTING EXPORT FUNCTIONALITY ===" -ForegroundColor Green

# Login as admin
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
$token = $loginResponse.data.token

Write-Host "Logged in as admin" -ForegroundColor Yellow

$headers = @{
    "Authorization" = "Bearer $token"
}

# Test CSV export
try {
    Write-Host "Testing CSV export..." -ForegroundColor Cyan
    $exportUrl = "http://localhost:8080/api/v1/tickets/export?format=csv"
    $response = Invoke-WebRequest -Uri $exportUrl -Method GET -Headers $headers
    
    Write-Host "✅ CSV EXPORT SUCCESS!" -ForegroundColor Green
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Content Type: $($response.Headers['Content-Type'])" -ForegroundColor Gray
    Write-Host "Content Length: $($response.Content.Length) bytes" -ForegroundColor Gray
    
    # Save to file
    $tempDir = $env:TEMP
    $csvFile = Join-Path $tempDir "exported_tickets.csv"
    $response.Content | Out-File -FilePath $csvFile -Encoding UTF8
    Write-Host "Exported to: $csvFile" -ForegroundColor Cyan
    
    # Show first few lines
    $lines = Get-Content $csvFile -TotalCount 5
    Write-Host "First 5 lines of exported CSV:" -ForegroundColor Yellow
    $lines | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    
} catch {
    Write-Host "❌ CSV EXPORT FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody" -ForegroundColor Red
    }
}

Write-Host "`n=== EXPORT TEST COMPLETED ===" -ForegroundColor Green