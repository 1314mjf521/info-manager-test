# Debug admin user permissions
$baseUrl = "http://localhost:8080"
$apiUrl = "$baseUrl/api/v1"

Write-Host "=== Debug Admin Permissions ===" -ForegroundColor Green

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
    Write-Host "Token: $($token.Substring(0, 20))..." -ForegroundColor Cyan
} catch {
    Write-Host "Admin login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. Check user profile
Write-Host "`n2. Check user profile..." -ForegroundColor Yellow
try {
    $profileResponse = Invoke-RestMethod -Uri "$apiUrl/auth/profile" -Method GET -Headers $headers
    Write-Host "User profile:" -ForegroundColor White
    Write-Host "  ID: $($profileResponse.id)" -ForegroundColor White
    Write-Host "  Username: $($profileResponse.username)" -ForegroundColor White
    Write-Host "  Email: $($profileResponse.email)" -ForegroundColor White
    Write-Host "  Status: $($profileResponse.status)" -ForegroundColor White
    Write-Host "  Is Active: $($profileResponse.is_active)" -ForegroundColor White
} catch {
    Write-Host "Failed to get user profile: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Check user permissions
Write-Host "`n3. Check user permissions..." -ForegroundColor Yellow
try {
    $permResponse = Invoke-RestMethod -Uri "$apiUrl/permissions/user/1" -Method GET -Headers $headers
    Write-Host "User permissions:" -ForegroundColor White
    if ($permResponse.permissions) {
        foreach ($perm in $permResponse.permissions) {
            Write-Host "  - $($perm.resource):$($perm.action):$($perm.scope)" -ForegroundColor White
        }
    } else {
        Write-Host "  No permissions found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to get user permissions: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Test system health (should work)
Write-Host "`n4. Test system health..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$apiUrl/system/health" -Method GET -Headers $headers
    Write-Host "System health check successful" -ForegroundColor Green
    Write-Host "  Status: $($healthResponse.overall_status)" -ForegroundColor White
} catch {
    Write-Host "System health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Test users endpoint (should work for admin)
Write-Host "`n5. Test users endpoint..." -ForegroundColor Yellow
try {
    $usersResponse = Invoke-RestMethod -Uri "$apiUrl/users?page=1&page_size=5" -Method GET -Headers $headers
    Write-Host "Users endpoint successful" -ForegroundColor Green
    Write-Host "  Total users: $($usersResponse.total)" -ForegroundColor White
} catch {
    Write-Host "Users endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Test roles endpoint (should work for admin)
Write-Host "`n6. Test roles endpoint..." -ForegroundColor Yellow
try {
    $rolesResponse = Invoke-RestMethod -Uri "$apiUrl/roles?page=1&page_size=5" -Method GET -Headers $headers
    Write-Host "Roles endpoint successful" -ForegroundColor Green
    Write-Host "  Total roles: $($rolesResponse.total)" -ForegroundColor White
} catch {
    Write-Host "Roles endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Debug Complete ===" -ForegroundColor Green