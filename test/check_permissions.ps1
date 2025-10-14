# Check User Permissions
Write-Host "=== Checking User Permissions ===" -ForegroundColor Green

# Login as admin
$loginData = @{ username = "admin"; password = "admin123" }
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
$token = $loginResponse.token
$userId = $loginResponse.user.id

Write-Host "Login successful, User ID: $userId" -ForegroundColor Green

# Check user permissions
$headers = @{ "Authorization" = "Bearer $token" }
try {
    $permResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions/user/$userId" -Method GET -Headers $headers
    Write-Host "`nUser Permissions:" -ForegroundColor Yellow
    
    if ($permResponse.data.permissions) {
        foreach ($perm in $permResponse.data.permissions) {
            Write-Host "  Resource: $($perm.resource), Action: $($perm.action), Scope: $($perm.scope)" -ForegroundColor White
        }
    } else {
        Write-Host "  No permissions found" -ForegroundColor Red
    }
} catch {
    Write-Host "Failed to get permissions: $($_.Exception.Message)" -ForegroundColor Red
}

# Check roles
try {
    $rolesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/roles" -Method GET -Headers $headers
    Write-Host "`nAvailable Roles:" -ForegroundColor Yellow
    
    if ($rolesResponse.data.roles) {
        foreach ($role in $rolesResponse.data.roles) {
            Write-Host "  Role: $($role.name) - $($role.description)" -ForegroundColor White
        }
    }
} catch {
    Write-Host "Failed to get roles: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Permission Check Completed ===" -ForegroundColor Green