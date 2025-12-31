# 验证权限系统脚本

Write-Host "=== 验证权限系统 ===" -ForegroundColor Green

# 获取管理员token
$loginData = @{username="admin"; password="admin123"} | ConvertTo-Json
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
$adminToken = $loginResponse.data.token

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

Write-Host "1. 检查权限模块分布..." -ForegroundColor Yellow
$permissionsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions" -Method GET -Headers $headers
$permissions = $permissionsResponse.data
$groupedPermissions = $permissions | Group-Object resource

Write-Host "   权限模块统计:" -ForegroundColor Cyan
$groupedPermissions | ForEach-Object { 
    Write-Host "     $($_.Name): $($_.Count) 个权限" -ForegroundColor White
}

Write-Host ""
Write-Host "2. 检查工单权限详情..." -ForegroundColor Yellow
$ticketPermissions = $permissions | Where-Object { $_.resource -eq "ticket" }
Write-Host "   工单权限列表:" -ForegroundColor Cyan
$ticketPermissions | ForEach-Object {
    $displayName = if ($_.display_name) { $_.display_name } else { "未设置" }
    Write-Host "     $($_.name): $displayName" -ForegroundColor White
}

Write-Host ""
Write-Host "3. 检查角色权限分配..." -ForegroundColor Yellow
$rolesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles" -Method GET -Headers $headers
$roles = $rolesResponse.data

$roles | ForEach-Object {
    $rolePermissions = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles/$($_.id)/permissions" -Method GET -Headers $headers
    $ticketPerms = $rolePermissions.data | Where-Object { $_.resource -eq "ticket" }
    Write-Host "   角色 '$($_.name)' (ID: $($_.id)): $($ticketPerms.Count) 个工单权限" -ForegroundColor White
}

Write-Host ""
Write-Host "=== 验证完成 ===" -ForegroundColor Green