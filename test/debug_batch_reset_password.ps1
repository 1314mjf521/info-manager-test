# Debug batch reset password API response
$baseUrl = "http://localhost:8080"
$apiUrl = "$baseUrl/api/v1"

Write-Host "=== Debug Batch Reset Password ===" -ForegroundColor Green

# 1. Admin login
Write-Host "`n1. Admin login..." -ForegroundColor Yellow
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$apiUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.token
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    Write-Host "Admin login successful" -ForegroundColor Green
} catch {
    Write-Host "Admin login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. Create a test user
Write-Host "`n2. Creating test user..." -ForegroundColor Yellow
$userData = @{
    username = "resettest"
    email = "resettest@example.com"
    displayName = "Reset Test User"
    password = "test123"
    status = "active"
} | ConvertTo-Json

try {
    $userResponse = Invoke-RestMethod -Uri "$apiUrl/admin/users" -Method POST -Body $userData -Headers $headers
    $testUserId = $userResponse.id
    Write-Host "Test user created with ID: $testUserId" -ForegroundColor Green
} catch {
    Write-Host "Failed to create test user: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. Test batch reset password API
Write-Host "`n3. Testing batch reset password API..." -ForegroundColor Yellow
$resetData = @{
    user_ids = @($testUserId)
} | ConvertTo-Json

try {
    Write-Host "Request data: $resetData" -ForegroundColor Cyan
    $resetResponse = Invoke-RestMethod -Uri "$apiUrl/admin/users/batch-reset-password" -Method POST -Body $resetData -Headers $headers
    
    Write-Host "API Response:" -ForegroundColor Green
    Write-Host "Full response: $($resetResponse | ConvertTo-Json -Depth 5)" -ForegroundColor White
    
    if ($resetResponse.success) {
        Write-Host "Success: $($resetResponse.success)" -ForegroundColor Green
        Write-Host "Data: $($resetResponse.data | ConvertTo-Json -Depth 3)" -ForegroundColor Cyan
        
        if ($resetResponse.data.results) {
            Write-Host "Results found in data.results:" -ForegroundColor Green
            foreach ($result in $resetResponse.data.results) {
                Write-Host "  - User: $($result.username)" -ForegroundColor White
                Write-Host "    Email: $($result.email)" -ForegroundColor White
                Write-Host "    Success: $($result.success)" -ForegroundColor White
                Write-Host "    New Password: $($result.new_password)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "No results found in data.results" -ForegroundColor Red
        }
    } else {
        Write-Host "API returned success: false" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Batch reset password failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
}

# 4. Clean up test user
Write-Host "`n4. Cleaning up test user..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "$apiUrl/admin/users/$testUserId" -Method DELETE -Headers $headers
    Write-Host "Test user deleted" -ForegroundColor Green
} catch {
    Write-Host "Failed to delete test user: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Debug Complete ===" -ForegroundColor Green