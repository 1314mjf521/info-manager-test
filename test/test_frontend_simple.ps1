# Simple Frontend Role Management Test
$BaseUrl = "http://localhost:8080"

Write-Host "=== Frontend Role Management Test ===" -ForegroundColor Green

# Login
$loginData = '{"username":"admin","password":"admin123"}'
try {
    $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.success) {
        Write-Host "Login: SUCCESS" -ForegroundColor Green
        $token = $loginResponse.data.token
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
    } else {
        Write-Host "Login: FAILED" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Login: ERROR - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test Roles API
Write-Host "Testing Roles API..." -ForegroundColor Yellow
try {
    $rolesResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles" -Method GET -Headers $headers
    
    if ($rolesResponse.success) {
        Write-Host "Roles API: SUCCESS" -ForegroundColor Green
        Write-Host "Roles count: $($rolesResponse.data.Count)" -ForegroundColor Cyan
        
        # Check required fields
        $firstRole = $rolesResponse.data[0]
        $hasDisplayName = $null -ne $firstRole.displayName
        $hasStatus = $null -ne $firstRole.status
        $hasPermissions = $null -ne $firstRole.permissions
        $hasUserCount = $null -ne $firstRole.userCount
        
        Write-Host "Has displayName: $hasDisplayName" -ForegroundColor $(if($hasDisplayName){"Green"}else{"Red"})
        Write-Host "Has status: $hasStatus" -ForegroundColor $(if($hasStatus){"Green"}else{"Red"})
        Write-Host "Has permissions: $hasPermissions" -ForegroundColor $(if($hasPermissions){"Green"}else{"Red"})
        Write-Host "Has userCount: $hasUserCount" -ForegroundColor $(if($hasUserCount){"Green"}else{"Red"})
    } else {
        Write-Host "Roles API: FAILED" -ForegroundColor Red
    }
} catch {
    Write-Host "Roles API: ERROR - $($_.Exception.Message)" -ForegroundColor Red
}

# Test Permissions Tree API
Write-Host "Testing Permissions Tree API..." -ForegroundColor Yellow
try {
    $treeResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions/tree" -Method GET -Headers $headers
    
    if ($treeResponse.success) {
        Write-Host "Permissions Tree API: SUCCESS" -ForegroundColor Green
        Write-Host "Tree nodes count: $($treeResponse.data.Count)" -ForegroundColor Cyan
        
        # Check tree structure
        $hasChildren = $false
        foreach ($node in $treeResponse.data) {
            if ($node.children -and $node.children.Count -gt 0) {
                $hasChildren = $true
                break
            }
        }
        
        Write-Host "Has tree structure: $hasChildren" -ForegroundColor $(if($hasChildren){"Green"}else{"Yellow"})
    } else {
        Write-Host "Permissions Tree API: FAILED" -ForegroundColor Red
    }
} catch {
    Write-Host "Permissions Tree API: ERROR - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Frontend Checklist ===" -ForegroundColor Green
Write-Host "Please verify in browser:" -ForegroundColor Yellow
Write-Host "- Role list displays correctly with displayName and status" -ForegroundColor White
Write-Host "- Permission tree shows hierarchical structure" -ForegroundColor White
Write-Host "- Permission tree supports expand/collapse" -ForegroundColor White
Write-Host "- Permission tree supports select all/none" -ForegroundColor White
Write-Host "- Permission assignment dialog works" -ForegroundColor White
Write-Host "- Permission save functionality works" -ForegroundColor White
Write-Host "- Role status toggle works" -ForegroundColor White
Write-Host "- Role CRUD operations work" -ForegroundColor White

Write-Host ""
Write-Host "Visit: http://localhost:3000/admin/roles" -ForegroundColor Cyan
Write-Host "=== Test Complete ===" -ForegroundColor Green