# 测试前端权限数据处理
$baseUrl = "http://localhost:8080"

# 登录
$loginData = @{ username = "admin"; password = "admin123" } | ConvertTo-Json -Compress
$loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
$token = $loginResponse.data.token

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host "=== Frontend Permission Data Test ===" -ForegroundColor Green

# 1. 测试权限树API
Write-Host "1. Testing permissions tree API..." -ForegroundColor Yellow
try {
    $treeResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/permissions/tree" -Method GET -Headers $headers
    Write-Host "   Success: Tree API returned $($treeResponse.data.Count) tree nodes" -ForegroundColor Green
    
    # 计算总权限数量
    $totalPermissions = 0
    foreach ($node in $treeResponse.data) {
        $totalPermissions++
        if ($node.children) {
            $totalPermissions += $node.children.Count
            foreach ($child in $node.children) {
                if ($child.children) {
                    $totalPermissions += $child.children.Count
                }
            }
        }
    }
    Write-Host "   Total permissions in tree: $totalPermissions" -ForegroundColor Cyan
    
    # 检查是否有足够的权限数据（前端要求>50）
    if ($totalPermissions -ge 50) {
        Write-Host "   ✓ Sufficient permissions for frontend ($totalPermissions >= 50)" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Insufficient permissions for frontend ($totalPermissions < 50)" -ForegroundColor Red
    }
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. 测试普通权限API
Write-Host "2. Testing regular permissions API..." -ForegroundColor Yellow
try {
    $permissionsResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/permissions" -Method GET -Headers $headers
    Write-Host "   Success: Regular API returned $($permissionsResponse.Count) permissions" -ForegroundColor Green
    
    if ($permissionsResponse.Count -ge 50) {
        Write-Host "   ✓ Sufficient permissions for frontend ($($permissionsResponse.Count) >= 50)" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Insufficient permissions for frontend ($($permissionsResponse.Count) < 50)" -ForegroundColor Red
    }
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. 测试角色权限分配（使用真实权限ID）
Write-Host "3. Testing role permission assignment with real permission ID..." -ForegroundColor Yellow
try {
    # 获取一个真实的权限ID
    $realPermission = $permissionsResponse | Where-Object { $_.resource -eq "export" } | Select-Object -First 1
    
    if ($realPermission) {
        Write-Host "   Using permission ID: $($realPermission.id) - $($realPermission.name)" -ForegroundColor Cyan
        
        # 为角色4分配这个权限
        $assignData = @{ permissionIds = @($realPermission.id) } | ConvertTo-Json -Compress
        $assignResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/admin/roles/4/permissions" -Method PUT -Body $assignData -Headers $headers
        
        Write-Host "   ✓ Successfully assigned permission to role 4" -ForegroundColor Green
    } else {
        Write-Host "   ✗ No suitable permission found for testing" -ForegroundColor Red
    }
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
Write-Host "Frontend should now work correctly with real backend data." -ForegroundColor Yellow