# Test Frontend Fix
Write-Host "=== Testing Frontend Fix ===" -ForegroundColor Green

# Check backend status
Write-Host "`n1. Checking backend status..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET -TimeoutSec 5
    Write-Host "✅ Backend: Running" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend: Not running" -ForegroundColor Red
    Write-Host "Please start backend: go run cmd/server/main.go" -ForegroundColor Yellow
    exit 1
}

# Check frontend status
Write-Host "`n2. Checking frontend status..." -ForegroundColor Yellow
try {
    $frontendResponse = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 3
    Write-Host "✅ Frontend: Running" -ForegroundColor Green
} catch {
    Write-Host "❌ Frontend: Not running" -ForegroundColor Red
    Write-Host "Please start frontend: cd frontend && npm run dev" -ForegroundColor Yellow
    exit 1
}

# Test API endpoints
Write-Host "`n3. Testing API endpoints..." -ForegroundColor Yellow

# Test login
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.success -and $loginResponse.data.token) {
        Write-Host "✅ Login API: Working" -ForegroundColor Green
        $token = $loginResponse.data.token
    } else {
        Write-Host "❌ Login API: Failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Login API: Error - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test records API
try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    $recordsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    
    if ($recordsResponse.success) {
        Write-Host "✅ Records API: Working" -ForegroundColor Green
        Write-Host "Record count: $($recordsResponse.data.total)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Records API: Failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Records API: Error - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Frontend Fix Applied ===" -ForegroundColor Green
Write-Host "Changes made:" -ForegroundColor Yellow
Write-Host "1. Simplified API connection check" -ForegroundColor White
Write-Host "2. Removed problematic health check logic" -ForegroundColor White
Write-Host "3. Streamlined record fetching" -ForegroundColor White
Write-Host "4. Cleaned up duplicate code" -ForegroundColor White

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Refresh browser (Ctrl+F5)" -ForegroundColor White
Write-Host "2. Login with admin/admin123" -ForegroundColor White
Write-Host "3. Go to Records Management" -ForegroundColor White
Write-Host "4. Page should load without connection errors" -ForegroundColor White