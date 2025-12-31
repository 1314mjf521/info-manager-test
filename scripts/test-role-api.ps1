# 测试角色管理API
param(
    [string]$BaseUrl = "http://localhost:8080"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Role Management API Test ===" -ForegroundColor Green

# 1. Login to get token
Write-Host "1. Logging in..." -ForegroundColor Yellow
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    }
    
    $loginJson = $loginData | ConvertTo-Json -Compress
    $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginJson -ContentType "application/json"
    
    Write-Host "   Login response: $($loginResponse | ConvertTo-Json -Compress)" -ForegroundColor Cyan
    
    if ($loginResponse.data -and $loginResponse.data.token) {
        $token = $loginResponse.data.token
        Write-Host "   Success: Login successful" -ForegroundColor Green
    } elseif ($loginResponse.token) {
        $token = $loginResponse.token
        Write-Host "   Success: Login successful" -ForegroundColor Green
    } else {
        throw "Token not found in login response"
    }
} catch {
    Write-Host "   Error: Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Set request headers
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# 2. Get roles list
Write-Host "2. Getting roles list..." -ForegroundColor Yellow
try {
    $rolesResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/roles" -Method GET -Headers $headers
    
    # Handle different response structures
    $roles = $rolesResponse
    if ($rolesResponse.data) {
        $roles = $rolesResponse.data
    }
    
    Write-Host "   Success: Found $($roles.Count) roles" -ForegroundColor Green
    
    foreach ($role in $roles) {
        Write-Host "     - ID: $($role.id), Name: $($role.name), Display: $($role.displayName), System: $($role.isSystem)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "   Error: Failed to get roles: $($_.Exception.Message)" -ForegroundColor Red
    $roles = @()
}

# 3. Get permissions list
Write-Host "3. Getting permissions list..." -ForegroundColor Yellow
try {
    $permissionsResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions" -Method GET -Headers $headers
    
    # Handle different response structures
    $permissions = $permissionsResponse
    if ($permissionsResponse.data) {
        $permissions = $permissionsResponse.data
    }
    
    Write-Host "   Success: Found $($permissions.Count) permissions" -ForegroundColor Green
    
    # Look for permission ID 1101
    $permission1101 = $permissions | Where-Object { $_.id -eq 1101 }
    if ($permission1101) {
        Write-Host "   Success: Found permission ID 1101: $($permission1101.name) - $($permission1101.displayName)" -ForegroundColor Green
    } else {
        Write-Host "   Warning: Permission ID 1101 not found" -ForegroundColor Red
        Write-Host "   Available export permissions:" -ForegroundColor Yellow
        $exportPermissions = $permissions | Where-Object { $_.resource -eq "export" } | Select-Object id, name, displayName
        if ($exportPermissions) {
            $exportPermissions | Format-Table -AutoSize
        } else {
            Write-Host "     No export permissions found" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "   Error: Failed to get permissions: $($_.Exception.Message)" -ForegroundColor Red
    $permissions = @()
}

# 4. Test permission assignment
Write-Host "4. Testing permission assignment..." -ForegroundColor Yellow
try {
    # Get first non-system role for testing
    $testRole = $roles | Where-Object { $_.isSystem -eq $false } | Select-Object -First 1
    
    if ($testRole) {
        # Get an existing permission ID for testing
        $testPermission = $permissions | Where-Object { $_.resource -eq "export" } | Select-Object -First 1
        
        if ($testPermission) {
            $assignData = @{
                permissionIds = @($testPermission.id)
            }
            
            $assignJson = $assignData | ConvertTo-Json -Compress
            $assignResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/roles/$($testRole.id)/permissions" -Method PUT -Body $assignJson -Headers $headers
            
            Write-Host "   Success: Assigned permission '$($testPermission.name)' to role '$($testRole.name)'" -ForegroundColor Green
        } else {
            Write-Host "   Warning: No test permission found" -ForegroundColor Yellow
            # Try with any available permission
            $anyPermission = $permissions | Select-Object -First 1
            if ($anyPermission) {
                Write-Host "   Trying with permission ID: $($anyPermission.id) - $($anyPermission.name)" -ForegroundColor Yellow
                $assignData = @{
                    permissionIds = @($anyPermission.id)
                }
                
                $assignJson = $assignData | ConvertTo-Json -Compress
                $assignResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/roles/$($testRole.id)/permissions" -Method PUT -Body $assignJson -Headers $headers
                
                Write-Host "   Success: Assigned permission '$($anyPermission.name)' to role '$($testRole.name)'" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "   Warning: No non-system role found for testing" -ForegroundColor Yellow
        Write-Host "   Available roles:" -ForegroundColor Yellow
        foreach ($role in $roles) {
            Write-Host "     - ID: $($role.id), Name: $($role.name), System: $($role.isSystem)" -ForegroundColor Cyan
        }
    }
} catch {
    Write-Host "   Error: Permission assignment failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green