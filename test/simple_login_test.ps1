# Simple Login Test
Write-Host "=== Login Fix Test ===" -ForegroundColor Green

# Test frontend
Write-Host "1. Testing frontend..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -UseBasicParsing
    Write-Host "Frontend OK - Status: $($response.StatusCode)" -ForegroundColor Green
}
catch {
    Write-Host "Frontend ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test backend
Write-Host "2. Testing backend..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 5 -UseBasicParsing
    Write-Host "Backend OK - Status: $($response.StatusCode)" -ForegroundColor Green
}
catch {
    Write-Host "Backend ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test login API
Write-Host "3. Testing login API..." -ForegroundColor Yellow
$loginJson = '{"username":"admin","password":"admin123"}'

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginJson -ContentType "application/json" -TimeoutSec 10
    
    if ($response.success -and $response.data.token) {
        Write-Host "Login API SUCCESS!" -ForegroundColor Green
        Write-Host "Token exists: YES" -ForegroundColor Gray
        Write-Host "User: $($response.data.user.username)" -ForegroundColor Gray
    }
    else {
        Write-Host "Login API response format issue" -ForegroundColor Red
    }
}
catch {
    Write-Host "Login API FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nTest completed. Now test in browser:" -ForegroundColor Cyan
Write-Host "1. Go to http://localhost:3000/login" -ForegroundColor White
Write-Host "2. Username: admin" -ForegroundColor White  
Write-Host "3. Password: admin123" -ForegroundColor White
Write-Host "4. Click login and check browser console" -ForegroundColor White