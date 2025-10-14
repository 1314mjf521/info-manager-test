# Simple API Connection Test
Write-Host "=== API Connection Test ===" -ForegroundColor Green

$backendUrl = "http://localhost:8080"
$apiUrl = "$backendUrl/api/v1"

Write-Host "`nTesting backend connection..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri $backendUrl -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "Backend service is running (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "Backend service is not running: $_" -ForegroundColor Red
    Write-Host "Please start the backend service on localhost:8080" -ForegroundColor Yellow
}

Write-Host "`nTesting API endpoints..." -ForegroundColor Yellow

try {
    $healthResponse = Invoke-WebRequest -Uri "$apiUrl/system/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "Health check passed" -ForegroundColor Green
} catch {
    Write-Host "Health check failed: $_" -ForegroundColor Red
}

try {
    $recordTypesResponse = Invoke-WebRequest -Uri "$apiUrl/record-types" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "Record types API working" -ForegroundColor Green
} catch {
    Write-Host "Record types API failed: $_" -ForegroundColor Red
}

Write-Host "`nPort check..." -ForegroundColor Yellow
$portCheck = netstat -an | findstr ":8080"
if ($portCheck) {
    Write-Host "Port 8080 is in use:" -ForegroundColor Green
    Write-Host $portCheck -ForegroundColor White
} else {
    Write-Host "Port 8080 is not in use" -ForegroundColor Red
}

Write-Host "`n=== Solutions ===" -ForegroundColor Green
Write-Host "1. Start the Go backend service" -ForegroundColor White
Write-Host "2. Check if port 8080 is available" -ForegroundColor White
Write-Host "3. Verify database connection" -ForegroundColor White
Write-Host "4. Check firewall settings" -ForegroundColor White