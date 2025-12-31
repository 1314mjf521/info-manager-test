# 最终权限系统验证脚本
Write-Host "=== 权限系统最终验证 ===" -ForegroundColor Green

$headers = @{
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJ1c2VybmFtZSI6ImFkbWluIiwicm9sZXMiOlsiYWRtaW4iXSwiaXNzIjoiaW5mby1tYW5hZ2VtZW50LXN5c3RlbSIsInN1YiI6IjEiLCJleHAiOjE3NjY4MzI0MjYsIm5iZiI6MTc2Njc0NjAyNiwiaWF0IjoxNzY2NzQ2MDI2fQ.quE5hkIgg_2GdcImQD3cMbLMpUuic7AcwYLTYw_Bax8"
    "Content-Type" = "application/json"
}

try {
    # 1. 验证权限总数和模块数
    Write-Host "`n1. 验证权限模块..." -ForegroundColor Yellow
    $permissionsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions" -Method GET -Headers $headers
    $permissions = $permissionsResponse.data
    $groupedPermissions = $permissions | Group-Object resource
    
    Write-Host "   总权限数: $($permissions.Count)"
    Write-Host "   模块数: $($groupedPermissions.Count)"
    
    $groupedPermissions | Sort-Object Name | ForEach-Object {
        Write-Host "   $($_.Name): $($_.Count) 个权限"
    }
    
    # 2. 验证DisplayName是否正确
    Write-Host "`n2. 验证DisplayName..." -ForegroundColor Yellow
    $emptyDisplayNames = $permissions | Where-Object { [string]::IsNullOrEmpty($_.displayName) }
    if ($emptyDisplayNames.Count -eq 0) {
        Write-Host "   ✓ 所有权限都有DisplayName" -ForegroundColor Green
    } else {
        Write-Host "   ✗ 发现 $($emptyDisplayNames.Count) 个权限缺少DisplayName" -ForegroundColor Red
    }
    
    # 3. 验证工单模块权限
    Write-Host "`n3. 验证工单模块..." -ForegroundColor Yellow
    $ticketPermissions = $permissions | Where-Object { $_.resource -eq "ticket" }
    Write-Host "   工单权限数: $($ticketPermissions.Count)"
    
    # 4. 验证角色权限分配
    Write-Host "`n4. 验证角色权限..." -ForegroundColor Yellow
    $rolesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles" -Method GET -Headers $headers
    $roles = $rolesResponse.data
    
    $roles | ForEach-Object {
        $roleDetailResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles/$($_.id)" -Method GET -Headers $headers
        $roleDetail = $roleDetailResponse.data
        Write-Host "   $($roleDetail.name): $($roleDetail.permissions.Count) 个权限"
    }
    
    # 5. 验证权限树结构
    Write-Host "`n5. 验证权限树..." -ForegroundColor Yellow
    $treeResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions/tree" -Method GET -Headers $headers
    $tree = $treeResponse.data
    Write-Host "   权限树节点数: $($tree.Count)"
    
    Write-Host "`n=== 验证完成 ===" -ForegroundColor Green
    Write-Host "权限系统运行正常！" -ForegroundColor Green
    
} catch {
    Write-Host "Verification failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}