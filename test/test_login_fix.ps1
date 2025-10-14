# Test Login Fix
Write-Host "=== Testing Login Fix ===" -ForegroundColor Green

Write-Host "`n1. Checking backend API response format..." -ForegroundColor Yellow

try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    Write-Host "Backend response structure:" -ForegroundColor Cyan
    Write-Host "Has 'success' field: $($response.success -ne $null)" -ForegroundColor White
    Write-Host "Has 'data' field: $($response.data -ne $null)" -ForegroundColor White
    
    if ($response.success -and $response.data) {
        Write-Host "Response format: { success: true, data: {...} }" -ForegroundColor Green
        Write-Host "Token exists in data: $($response.data.token -ne $null)" -ForegroundColor White
        Write-Host "User exists in data: $($response.data.user -ne $null)" -ForegroundColor White
        
        if ($response.data.user) {
            Write-Host "User info:" -ForegroundColor Cyan
            Write-Host "  Username: $($response.data.user.username)" -ForegroundColor White
            Write-Host "  ID: $($response.data.user.id)" -ForegroundColor White
            Write-Host "  Roles: $($response.data.user.roles -join ', ')" -ForegroundColor White
        }
    } else {
        Write-Host "Response format: Direct token response" -ForegroundColor Yellow
        Write-Host "Token exists: $($response.token -ne $null)" -ForegroundColor White
        Write-Host "User exists: $($response.user -ne $null)" -ForegroundColor White
    }
    
} catch {
    Write-Host "Backend login test failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n2. Frontend configuration status..." -ForegroundColor Yellow

# Check if frontend server is running
try {
    $frontendCheck = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 3
    Write-Host "Frontend server: Running" -ForegroundColor Green
} catch {
    Write-Host "Frontend server: Not running" -ForegroundColor Red
    Write-Host "Please start frontend: cd frontend && npm run dev" -ForegroundColor Yellow
}

# Check environment configuration
$envContent = Get-Content "frontend/.env" -Raw
if ($envContent -match "VITE_API_BASE_URL=(.+)") {
    $apiUrl = $matches[1].Trim()
    Write-Host "Frontend API URL: $apiUrl" -ForegroundColor Cyan
    
    if ($apiUrl -eq "http://localhost:8080") {
        Write-Host "API URL configuration: Correct" -ForegroundColor Green
    } else {
        Write-Host "API URL configuration: Incorrect (should be http://localhost:8080)" -ForegroundColor Red
    }
}

Write-Host "`n3. Testing instructions..." -ForegroundColor Yellow
Write-Host "The login issue should now be fixed. Please test:" -ForegroundColor White
Write-Host "1. Open browser and go to http://localhost:3000" -ForegroundColor Cyan
Write-Host "2. Try logging in with:" -ForegroundColor Cyan
Write-Host "   Username: admin" -ForegroundColor White
Write-Host "   Password: admin123" -ForegroundColor White
Write-Host "3. Check browser console for detailed debug logs" -ForegroundColor Cyan

Write-Host "`n4. If login still fails, check:" -ForegroundColor Yellow
Write-Host "- Browser console for JavaScript errors" -ForegroundColor White
Write-Host "- Network tab for API request/response details" -ForegroundColor White
Write-Host "- Ensure both frontend and backend servers are running" -ForegroundColor White

Write-Host "`n=== Fix Applied ===" -ForegroundColor Green
Write-Host "Modified: frontend/src/stores/auth.ts" -ForegroundColor Cyan
Write-Host "Change: Fixed response format handling in login method" -ForegroundColor Cyan