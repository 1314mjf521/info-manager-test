# Simple Frontend Login Test
Write-Host "=== Frontend Login Test ===" -ForegroundColor Green

$frontendUrl = "http://localhost:3000"
$backendUrl = "http://localhost:8080"

Write-Host "1. Testing frontend server..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $frontendUrl -TimeoutSec 5 -UseBasicParsing
    Write-Host "Frontend OK - Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Frontend ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "2. Testing backend server..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$backendUrl/api/v1/system/health" -TimeoutSec 5 -UseBasicParsing
    Write-Host "Backend OK - Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Backend ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "3. Testing login page..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$frontendUrl/login" -TimeoutSec 5 -UseBasicParsing
    Write-Host "Login page OK - Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Login page ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "4. Checking config files..." -ForegroundColor Yellow
$files = @(
    "frontend/src/config/api.ts",
    "frontend/src/stores/auth.ts", 
    "frontend/src/router/index.ts",
    "frontend/src/views/auth/LoginView.vue"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "$file - EXISTS" -ForegroundColor Green
    } else {
        Write-Host "$file - MISSING" -ForegroundColor Red
    }
}

Write-Host "`nTest completed. Check browser console for detailed debug info." -ForegroundColor Cyan