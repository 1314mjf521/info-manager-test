# 简化的角色管理调试脚本
$BaseUrl = "http://localhost:8080"
$Headers = @{}

# 登录
Write-Host "=== 登录测试 ===" -ForegroundColor Yellow
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
Write-Host "=== 获取角色列表 ===" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles" -Method GET -Headers $Headers
    
    if ($response.success) {
        Write-Host "✓ 获取角色列表成功" -ForegroundColor Green
        Write-Host "角色数量: $($response.data.Count)" -ForegroundColor Cyan
        
        foreach ($role in $response.data) {
            Write-Host "  - ID: $($role.id), 名称: $($role.name), 显示名: $($role.displayName), 状态: $($role.status)" -ForegroundColor White
        }
    } else {
        Write-Host "✗ 获取角色列表失败: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 获取角色列表请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 创建测试角色
Write-Host "=== 创建角色测试 ===" -ForegroundColor Yellow
$roleData = @{
    name = "test_role_debug"
    displayName = "调试测试角色"
    description = "这是一个调试测试角色"
    status = "active"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles" -Method POST -Body $roleData -Headers $Headers
    
    if ($response.success) {
        Write-Host "✓ 创建角色成功" -ForegroundColor Green
        Write-Host "新角色ID: $($response.data.id)" -ForegroundColor Cyan
        $newRoleId = $response.data.id
    } else {
        Write-Host "✗ 创建角色失败: $($response.message)" -ForegroundColor Red
        $newRoleId = $null
    }
} catch {
    Write-Host "✗ 创建角色请求失败: $($_.Exception.Message)" -ForegroundColor Red
    $newRoleId = $null
}

# 如果创建成功，测试更新
if ($newRoleId) {
    Write-Host "=== 更新角色测试 ===" -ForegroundColor Yellow
    $updateData = @{
        displayName = "更新后的调试角色"
        description = "这是更新后的描述"
        status = "active"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$newRoleId" -Method PUT -Body $updateData -Headers $Headers
        
        if ($response.success) {
            Write-Host "✓ 角色更新成功" -ForegroundColor Green
            Write-Host "更新后的显示名称: $($response.data.displayName)" -ForegroundColor Cyan
        } else {
            Write-Host "✗ 角色更新失败: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 角色更新请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 测试状态切换
    Write-Host "=== 切换角色状态测试 ===" -ForegroundColor Yellow
    $statusData = @{
        status = "inactive"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$newRoleId" -Method PUT -Body $statusData -Headers $Headers
        
        if ($response.success) {
            Write-Host "✓ 角色状态切换成功" -ForegroundColor Green
            Write-Host "新状态: $($response.data.status)" -ForegroundColor Cyan
        } else {
            Write-Host "✗ 角色状态切换失败: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 角色状态切换请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 清理：删除测试角色
    Write-Host "=== 删除角色测试 ===" -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$newRoleId" -Method DELETE -Headers $Headers
        
        if ($response.success) {
            Write-Host "✓ 角色删除成功" -ForegroundColor Green
        } else {
            Write-Host "✗ 角色删除失败: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 角色删除请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 获取权限信息
Write-Host "=== 获取权限信息 ===" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions" -Method GET -Headers $Headers
    
    if ($response.success) {
        Write-Host "✓ 获取权限列表成功" -ForegroundColor Green
        Write-Host "权限总数: $($response.data.Count)" -ForegroundColor Cyan
        
        $groupedPermissions = $response.data | Group-Object -Property resource
        foreach ($group in $groupedPermissions) {
            Write-Host "  资源: $($group.Name)" -ForegroundColor White
            foreach ($permission in $group.Group) {
                Write-Host "    - $($permission.displayName) [$($permission.action)/$($permission.scope)]" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "✗ 获取权限列表失败: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 获取权限列表请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 获取权限树
Write-Host "=== 获取权限树 ===" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions/tree" -Method GET -Headers $Headers
    
    if ($response.success) {
        Write-Host "✓ 获取权限树成功" -ForegroundColor Green
        Write-Host "权限树节点数量: $($response.data.Count)" -ForegroundColor Cyan
        
        foreach ($node in $response.data) {
            Write-Host "  - $($node.displayName) [$($node.resource)/$($node.action)]" -ForegroundColor White
            if ($node.children -and $node.children.Count -gt 0) {
                foreach ($child in $node.children) {
                    Write-Host "    - $($child.displayName) [$($child.resource)/$($child.action)/$($child.scope)]" -ForegroundColor Gray
                }
            }
        }
    } else {
        Write-Host "✗ 获取权限树失败: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 获取权限树请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=== 测试完成 ===" -ForegroundColor Green