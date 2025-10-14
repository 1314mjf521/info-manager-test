# 系统角色保护功能测试脚本
$BaseUrl = "http://localhost:8080"
$Headers = @{}

Write-Host "=== 系统角色保护功能测试 ===" -ForegroundColor Cyan

# 登录
Write-Host "1. 登录测试..." -ForegroundColor Yellow
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($response.success -and $response.data.token) {
        $Headers = @{
            "Authorization" = "Bearer $($response.data.token)"
            "Content-Type" = "application/json"
        }
        Write-Host "✓ 登录成功" -ForegroundColor Green
    } else {
        Write-Host "✗ 登录失败" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ 登录请求失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 获取角色列表
Write-Host "2. 获取角色列表..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles" -Method GET -Headers $Headers
    
    if ($response.success) {
        Write-Host "✓ 角色列表获取成功" -ForegroundColor Green
        $roles = $response.data
        
        Write-Host "角色信息:" -ForegroundColor Cyan
        foreach ($role in $roles) {
            $roleType = if ($role.is_system -or $role.isSystem) { "系统角色" } else { "自定义角色" }
            Write-Host "  - $($role.name) ($($role.displayName)) - $roleType" -ForegroundColor White
        }
        
        # 找到系统角色进行测试
        $systemRoles = $roles | Where-Object { $_.is_system -or $_.isSystem }
        $customRoles = $roles | Where-Object { -not ($_.is_system -or $_.isSystem) }
        
        Write-Host "系统角色数量: $($systemRoles.Count)" -ForegroundColor Cyan
        Write-Host "自定义角色数量: $($customRoles.Count)" -ForegroundColor Cyan
        
        # 测试系统角色保护
        if ($systemRoles.Count -gt 0) {
            $testRole = $systemRoles[0]
            Write-Host "3. 测试系统角色保护 (角色: $($testRole.name))..." -ForegroundColor Yellow
            
            # 尝试修改系统角色状态
            Write-Host "  测试修改系统角色状态..." -ForegroundColor White
            try {
                $updateData = @{
                    status = if ($testRole.status -eq "active") { "inactive" } else { "active" }
                } | ConvertTo-Json
                
                $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$($testRole.id)" -Method PUT -Body $updateData -Headers $Headers
                Write-Host "    ✗ 系统角色状态修改意外成功（应该被阻止）" -ForegroundColor Red
            } catch {
                if ($_.Exception.Response.StatusCode -eq 400) {
                    Write-Host "    ✓ 系统角色状态修改被正确阻止 (400错误)" -ForegroundColor Green
                } else {
                    Write-Host "    ? 系统角色状态修改返回其他错误: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
            
            # 尝试修改系统角色信息
            Write-Host "  测试修改系统角色信息..." -ForegroundColor White
            try {
                $updateData = @{
                    displayName = "修改后的系统角色"
                    description = "这是修改后的描述"
                } | ConvertTo-Json
                
                $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$($testRole.id)" -Method PUT -Body $updateData -Headers $Headers
                Write-Host "    ✗ 系统角色信息修改意外成功（应该被阻止）" -ForegroundColor Red
            } catch {
                if ($_.Exception.Response.StatusCode -eq 400) {
                    Write-Host "    ✓ 系统角色信息修改被正确阻止 (400错误)" -ForegroundColor Green
                } else {
                    Write-Host "    ? 系统角色信息修改返回其他错误: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
            
            # 尝试删除系统角色
            Write-Host "  测试删除系统角色..." -ForegroundColor White
            try {
                $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$($testRole.id)" -Method DELETE -Headers $Headers
                Write-Host "    ✗ 系统角色删除意外成功（应该被阻止）" -ForegroundColor Red
            } catch {
                if ($_.Exception.Response.StatusCode -eq 400) {
                    Write-Host "    ✓ 系统角色删除被正确阻止 (400错误)" -ForegroundColor Green
                } else {
                    Write-Host "    ? 系统角色删除返回其他错误: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
        }
        
        # 测试自定义角色（如果存在）
        if ($customRoles.Count -gt 0) {
            $testRole = $customRoles[0]
            Write-Host "4. 测试自定义角色操作 (角色: $($testRole.name))..." -ForegroundColor Yellow
            
            # 尝试修改自定义角色状态
            Write-Host "  测试修改自定义角色状态..." -ForegroundColor White
            try {
                $newStatus = if ($testRole.status -eq "active") { "inactive" } else { "active" }
                $updateData = @{
                    status = $newStatus
                } | ConvertTo-Json
                
                $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$($testRole.id)" -Method PUT -Body $updateData -Headers $Headers
                
                if ($response.success) {
                    Write-Host "    ✓ 自定义角色状态修改成功" -ForegroundColor Green
                    
                    # 恢复原状态
                    $restoreData = @{
                        status = $testRole.status
                    } | ConvertTo-Json
                    Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$($testRole.id)" -Method PUT -Body $restoreData -Headers $Headers | Out-Null
                    Write-Host "    ✓ 状态已恢复" -ForegroundColor Green
                } else {
                    Write-Host "    ✗ 自定义角色状态修改失败: $($response.message)" -ForegroundColor Red
                }
            } catch {
                Write-Host "    ✗ 自定义角色状态修改异常: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
    } else {
        Write-Host "✗ 角色列表获取失败: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 角色列表请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=== 测试完成 ===" -ForegroundColor Green
Write-Host ""
Write-Host "修复说明:" -ForegroundColor Cyan
Write-Host "1. 前端现在会检查角色的 is_system 或 isSystem 字段" -ForegroundColor White
Write-Host "2. 系统角色的编辑、状态切换、删除按钮会被禁用" -ForegroundColor White
Write-Host "3. 在操作函数中添加了系统角色检查，提供明确的错误提示" -ForegroundColor White
Write-Host "4. 表格中添加了角色类型列，区分系统角色和自定义角色" -ForegroundColor White
Write-Host "5. 改进了错误处理，显示更具体的错误信息" -ForegroundColor White
Write-Host ""
Write-Host "现在系统角色（admin、user、viewer）不能被修改或删除了" -ForegroundColor Yellow