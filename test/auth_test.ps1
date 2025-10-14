# Auth Test
Write-Host "=== Auth Test ===" -ForegroundColor Green

# Test login
$loginData = @{ username = "admin"; password = "admin123" }
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
$token = $loginResponse.token
$userId = $loginResponse.user.id

Write-Host "Login successful, User ID: $userId" -ForegroundColor Green
Write-Host "Token: $($token.Substring(0, 20))..." -ForegroundColor Cyan

# Test a simple authenticated endpoint
$headers = @{ "Authorization" = "Bearer $token" }

# Try to get user profile (this should work)
Write-Host "`nTesting user profile endpoint..." -ForegroundColor Yellow
try {
    $profileResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/profile" -Method GET -Headers $headers
    Write-Host "✓ User profile retrieved successfully" -ForegroundColor Green
    Write-Host "Username: $($profileResponse.data.username)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ User profile failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Auth Test Completed ===" -ForegroundColor Green