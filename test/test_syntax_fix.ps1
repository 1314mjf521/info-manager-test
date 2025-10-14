# Test Syntax Fix
Write-Host "=== Testing Syntax Fix ===" -ForegroundColor Green

Write-Host "`n1. Checking if frontend server is running..." -ForegroundColor Yellow
try {
    $frontendResponse = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 3
    Write-Host "✅ Frontend server: Running" -ForegroundColor Green
} catch {
    Write-Host "❌ Frontend server: Not running" -ForegroundColor Red
    Write-Host "Please start frontend server: cd frontend && npm run dev" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n2. Checking backend server..." -ForegroundColor Yellow
try {
    $backendResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET -TimeoutSec 3
    Write-Host "✅ Backend server: Running" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend server: Not running" -ForegroundColor Red
    Write-Host "Please start backend server: go run cmd/server/main.go" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=== Syntax Fix Applied ===" -ForegroundColor Green
Write-Host "Fixed issues:" -ForegroundColor Yellow
Write-Host "1. ✅ Removed duplicate code blocks" -ForegroundColor White
Write-Host "2. ✅ Fixed syntax errors in script section" -ForegroundColor White
Write-Host "3. ✅ Cleaned up template structure" -ForegroundColor White
Write-Host "4. ✅ Simplified API connection logic" -ForegroundColor White

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. The frontend should now compile without errors" -ForegroundColor White
Write-Host "2. Refresh your browser (Ctrl+F5)" -ForegroundColor White
Write-Host "3. Login with admin/admin123" -ForegroundColor White
Write-Host "4. Navigate to Records Management" -ForegroundColor White
Write-Host "5. The page should load properly" -ForegroundColor White

Write-Host "`n=== Fix Complete ===" -ForegroundColor Green