# Complete Login Test
Write-Host "=== Complete Login Test ===" -ForegroundColor Green

# Test 1: Frontend server
Write-Host "`n1. Testing frontend server..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -UseBasicParsing
    Write-Host "✓ Frontend server OK - Status: $($response.StatusCode)" -ForegroundColor Green
}
catch {
    Write-Host "✗ Frontend server ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please run: cd frontend && npm run dev" -ForegroundColor Yellow
    exit 1
}

# Test 2: Backend server
Write-Host "`n2. Testing backend server..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 5 -UseBasicParsing
    Write-Host "✓ Backend server OK - Status: $($response.StatusCode)" -ForegroundColor Green
}
catch {
    Write-Host "✗ Backend server ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please ensure backend is running" -ForegroundColor Yellow
    exit 1
}

# Test 3: Login page access
Write-Host "`n3. Testing login page access..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/login" -TimeoutSec 5 -UseBasicParsing
    Write-Host "✓ Login page accessible - Status: $($response.StatusCode)" -ForegroundColor Green
}
catch {
    Write-Host "✗ Login page ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Backend login API
Write-Host "`n4. Testing backend login API..." -ForegroundColor Yellow
$loginJson = '{"username":"admin","password":"admin123"}'

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginJson -ContentType "application/json" -TimeoutSec 10
    
    if ($response.success -and $response.data.token) {
        Write-Host "✓ Backend login API works!" -ForegroundColor Green
        Write-Host "  Token: $($response.data.token.Substring(0, 30))..." -ForegroundColor Gray
        Write-Host "  User: $($response.data.user.username)" -ForegroundColor Gray
        Write-Host "  Roles: $($response.data.user.roles -join ', ')" -ForegroundColor Gray
        $global:testToken = $response.data.token
    }
    else {
        Write-Host "✗ Backend login API response format issue" -ForegroundColor Red
        Write-Host "Response: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor Gray
    }
}
catch {
    Write-Host "✗ Backend login API FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            Write-Host "Error details: $errorBody" -ForegroundColor Gray
        }
        catch {
            Write-Host "Could not read error details" -ForegroundColor Gray
        }
    }
}

# Test 5: Protected API with token
if ($global:testToken) {
    Write-Host "`n5. Testing protected API with token..." -ForegroundColor Yellow
    try {
        $headers = @{
            "Authorization" = "Bearer $global:testToken"
            "Content-Type" = "application/json"
        }
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/profile" -Method GET -Headers $headers -TimeoutSec 10
        
        if ($response.success) {
            Write-Host "✓ Protected API works with token!" -ForegroundColor Green
            Write-Host "  Profile: $($response.data.username)" -ForegroundColor Gray
        }
        else {
            Write-Host "✗ Protected API response issue" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "✗ Protected API FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "All backend tests completed. Now test the frontend login flow:" -ForegroundColor White
Write-Host ""
Write-Host "Manual Test Steps:" -ForegroundColor Yellow
Write-Host "1. Open browser and go to: http://localhost:3000/login" -ForegroundColor White
Write-Host "2. Enter username: admin" -ForegroundColor White  
Write-Host "3. Enter password: admin123" -ForegroundColor White
Write-Host "4. Click Login button" -ForegroundColor White
Write-Host "5. Check if you are redirected to dashboard" -ForegroundColor White
Write-Host "6. Open browser console (F12) to see debug logs" -ForegroundColor White
Write-Host ""
Write-Host "Expected Result:" -ForegroundColor Green
Write-Host "- Login should succeed" -ForegroundColor White
Write-Host "- Should redirect to /dashboard" -ForegroundColor White
Write-Host "- Should see dashboard with user info" -ForegroundColor White
Write-Host "- Console should show successful login logs" -ForegroundColor White