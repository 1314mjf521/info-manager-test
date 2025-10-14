# Role Management API Test
$BaseUrl = "http://localhost:8080"

Write-Host "=== Role Management API Test ===" -ForegroundColor Green

# Test 1: Login
Write-Host "1. Testing login..." -ForegroundColor Yellow
$loginBody = '{"username":"admin","password":"admin123"}'
try {
    $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
    
    if ($loginResponse.success) {
        Write-Host "✓ Login successful" -ForegroundColor Green
        $token = $loginResponse.data.token
        $authHeaders = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
    } else {
        Write-Host "✗ Login failed: $($loginResponse.error.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Login request failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Get roles
Write-Host "2. Testing get roles..." -ForegroundColor Yellow
try {
    $rolesResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles" -Method GET -Headers $authHeaders
    
    if ($rolesResponse.success) {
        Write-Host "✓ Get roles successful" -ForegroundColor Green
        Write-Host "   Roles count: $($rolesResponse.data.Count)" -ForegroundColor Cyan
        
        foreach ($role in $rolesResponse.data) {
            $displayName = if ($role.displayName) { $role.displayName } else { "N/A" }
            $status = if ($role.status) { $role.status } else { "N/A" }
            Write-Host "   - ID: $($role.id), Name: $($role.name), Display: $displayName, Status: $status" -ForegroundColor White
        }
    } else {
        Write-Host "✗ Get roles failed: $($rolesResponse.error.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Get roles request failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Get permissions
Write-Host "3. Testing get permissions..." -ForegroundColor Yellow
try {
    $permissionsResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions" -Method GET -Headers $authHeaders
    
    if ($permissionsResponse.success) {
        Write-Host "✓ Get permissions successful" -ForegroundColor Green
        Write-Host "   Permissions count: $($permissionsResponse.data.Count)" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Get permissions failed: $($permissionsResponse.error.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Get permissions request failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Get permissions tree
Write-Host "4. Testing get permissions tree..." -ForegroundColor Yellow
try {
    $treeResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions/tree" -Method GET -Headers $authHeaders
    
    if ($treeResponse.success) {
        Write-Host "✓ Get permissions tree successful" -ForegroundColor Green
        Write-Host "   Tree nodes count: $($treeResponse.data.Count)" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Get permissions tree failed: $($treeResponse.error.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Get permissions tree request failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Create a test role
Write-Host "5. Testing create role..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$createRoleBody = @{
    name = "test_role_$timestamp"
    displayName = "Test Role"
    description = "This is a test role"
    status = "active"
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles" -Method POST -Body $createRoleBody -Headers $authHeaders
    
    if ($createResponse.success) {
        Write-Host "✓ Create role successful" -ForegroundColor Green
        Write-Host "   New role ID: $($createResponse.data.id)" -ForegroundColor Cyan
        $testRoleId = $createResponse.data.id
        
        # Test 6: Update the role
        Write-Host "6. Testing update role..." -ForegroundColor Yellow
        $updateRoleBody = @{
            displayName = "Updated Test Role"
            description = "This is an updated test role"
            status = "active"
        } | ConvertTo-Json
        
        try {
            $updateResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$testRoleId" -Method PUT -Body $updateRoleBody -Headers $authHeaders
            
            if ($updateResponse.success) {
                Write-Host "✓ Update role successful" -ForegroundColor Green
                Write-Host "   Updated display name: $($updateResponse.data.displayName)" -ForegroundColor Cyan
            } else {
                Write-Host "✗ Update role failed: $($updateResponse.error.message)" -ForegroundColor Red
            }
        } catch {
            Write-Host "✗ Update role request failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        # Test 7: Delete the role
        Write-Host "7. Testing delete role..." -ForegroundColor Yellow
        try {
            $deleteResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$testRoleId" -Method DELETE -Headers $authHeaders
            
            if ($deleteResponse.success) {
                Write-Host "✓ Delete role successful" -ForegroundColor Green
            } else {
                Write-Host "✗ Delete role failed: $($deleteResponse.error.message)" -ForegroundColor Red
            }
        } catch {
            Write-Host "✗ Delete role request failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
    } else {
        Write-Host "✗ Create role failed: $($createResponse.error.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Create role request failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=== Test Complete ===" -ForegroundColor Green