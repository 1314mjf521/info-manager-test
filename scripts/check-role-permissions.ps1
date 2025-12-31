# 检查角色权限脚本

Write-Host "=== 检查工单申请人角色权限 ===" -ForegroundColor Green

# 使用curl调用API检查权限
$headers = @{
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MzUyMTU0NzQsInVzZXJfaWQiOjF9.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8"
    "Content-Type" = "application/json"
}

try {
    Write-Host "获取所有角色..." -ForegroundColor Yellow
    $rolesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles" -Method GET -Headers $headers
    
    foreach ($role in $rolesResponse.data) {
        if ($role.name -like "*申请*") {
            Write-Host "角色: $($role.name) (ID: $($role.id))" -ForegroundColor Cyan
            
            # 获取角色权限
            $permissionsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles/$($role.id)/permissions" -Method GET -Headers $headers
            
            Write-Host "权限列表:" -ForegroundColor White
            foreach ($permission in $permissionsResponse.data) {
                if ($permission.name -like "*ticket*") {
                    Write-Host "  - $($permission.name): $($permission.display_name)" -ForegroundColor Green
                }
            }
            Write-Host ""
        }
    }
    
    Write-Host "=== 检查完成 ===" -ForegroundColor Green
    
} catch {
    Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "响应内容: $($_.Exception.Response)" -ForegroundColor Red
}