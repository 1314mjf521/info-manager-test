# 角色管理调试脚本
param(
    [string]$BaseUrl = "http://localhost:8080"
)

# 全局变量
$global:Headers = @{}
$global:Token = ""

# 登录函数
function Login {
    Write-Host "=== 登录测试 ===" -ForegroundColor Yellow
    
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        
        if ($response.success -and $response.data.token) {
            $global:Token = $response.data.token
            $global:Headers = @{
                "Authorization" = "Bearer $($global:Token)"
                "Content-Type" = "application/json"
            }
            Write-Host "✓ 登录成功" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ 登录失败: $($response.message)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "✗ 登录请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 获取角色列表
function Test-GetRoles {
    Write-Host "=== 获取角色列表 ===" -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles" -Method GET -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 获取角色列表成功" -ForegroundColor Green
            Write-Host "角色数量: $($response.data.Count)" -ForegroundColor Cyan
            
            foreach ($role in $response.data) {
                Write-Host "  - ID: $($role.id), 名称: $($role.name), 显示名: $($role.displayName), 状态: $($role.status)" -ForegroundColor White
            }
            return $response.data
        } else {
            Write-Host "✗ 获取角色列表失败: $($response.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 获取角色列表请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 测试创建角色
function Test-CreateRole {
    Write-Host "=== 创建角色测试 ===" -ForegroundColor Yellow
    
    $roleData = @{
        name = "test_role_$(Get-Date -Format 'yyyyMMddHHmmss')"
        displayName = "测试角色"
        description = "这是一个测试角色"
        status = "active"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles" -Method POST -Body $roleData -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 创建角色成功" -ForegroundColor Green
            Write-Host "新角色ID: $($response.data.id)" -ForegroundColor Cyan
            return $response.data
        } else {
            Write-Host "✗ 创建角色失败: $($response.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 创建角色请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 测试更新角色
function Test-UpdateRole {
    param($roleId)
    
    Write-Host "=== 更新角色测试 ===" -ForegroundColor Yellow
    
    $updateData = @{
        displayName = "更新后的测试角色"
        description = "这是更新后的描述"
        status = "active"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$roleId" -Method PUT -Body $updateData -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 角色更新成功" -ForegroundColor Green
            Write-Host "更新后的显示名称: $($response.data.displayName)" -ForegroundColor Cyan
            return $response.data
        } else {
            Write-Host "✗ 角色更新失败: $($response.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 角色更新请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 测试切换角色状态
function Test-ToggleRoleStatus {
    param($roleId, $currentStatus)
    
    Write-Host "=== 切换角色状态测试 ===" -ForegroundColor Yellow
    
    $newStatus = if ($currentStatus -eq "active") { "inactive" } else { "active" }
    
    $updateData = @{
        status = $newStatus
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$roleId" -Method PUT -Body $updateData -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 角色状态切换成功" -ForegroundColor Green
            Write-Host "新状态: $($response.data.status)" -ForegroundColor Cyan
            return $response.data
        } else {
            Write-Host "✗ 角色状态切换失败: $($response.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 角色状态切换请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 获取权限树
function Test-GetPermissionTree {
    Write-Host "=== 获取权限树测试 ===" -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions/tree" -Method GET -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 获取权限树成功" -ForegroundColor Green
            Write-Host "权限树节点数量: $($response.data.Count)" -ForegroundColor Cyan
            
            foreach ($node in $response.data) {
                Write-Host "  - $($node.displayName) ($($node.resource)_$($node.action))" -ForegroundColor White
                if ($node.children -and $node.children.Count -gt 0) {
                    foreach ($child in $node.children) {
                        Write-Host "    - $($child.displayName) ($($child.resource)_$($child.action)_$($child.scope))" -ForegroundColor Gray
                    }
                }
            }
            return $response.data
        } else {
            Write-Host "✗ 获取权限树失败: $($response.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 获取权限树请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 获取所有权限
function Test-GetAllPermissions {
    Write-Host "=== 获取所有权限测试 ===" -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions" -Method GET -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 获取所有权限成功" -ForegroundColor Green
            Write-Host "权限总数: $($response.data.Count)" -ForegroundColor Cyan
            
            $groupedPermissions = $response.data | Group-Object -Property resource
            foreach ($group in $groupedPermissions) {
                Write-Host "  资源: $($group.Name)" -ForegroundColor White
                foreach ($permission in $group.Group) {
                    Write-Host "    - $($permission.displayName) ($($permission.action)_$($permission.scope))" -ForegroundColor Gray
                }
            }
            return $response.data
        } else {
            Write-Host "✗ 获取所有权限失败: $($response.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 获取所有权限请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 测试权限分配
function Test-AssignPermissions {
    param($roleId, $permissions)
    
    Write-Host "=== 权限分配测试 ===" -ForegroundColor Yellow
    
    # 选择前5个权限进行测试
    $selectedPermissions = $permissions | Select-Object -First 5 | ForEach-Object { $_.id }
    
    $assignData = @{
        permissionIds = $selectedPermissions
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$roleId/permissions" -Method PUT -Body $assignData -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 权限分配成功" -ForegroundColor Green
            Write-Host "分配的权限数量: $($response.data.permissions.Count)" -ForegroundColor Cyan
            return $response.data
        } else {
            Write-Host "✗ 权限分配失败: $($response.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 权限分配请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 删除测试角色
function Test-DeleteRole {
    param($roleId)
    
    Write-Host "=== 删除角色测试 ===" -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$roleId" -Method DELETE -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 角色删除成功" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ 角色删除失败: $($response.message)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "✗ 角色删除请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 主测试流程
function Main {
    Write-Host "开始角色管理功能调试测试..." -ForegroundColor Cyan
    
    # 1. 登录
    if (-not (Login)) {
        Write-Host "登录失败，退出测试" -ForegroundColor Red
        return
    }
    
    # 2. 获取角色列表
    $roles = Test-GetRoles
    if (-not $roles) {
        Write-Host "获取角色列表失败，退出测试" -ForegroundColor Red
        return
    }
    
    # 3. 获取权限信息
    $permissions = Test-GetAllPermissions
    $permissionTree = Test-GetPermissionTree
    
    # 4. 创建测试角色
    $newRole = Test-CreateRole
    if (-not $newRole) {
        Write-Host "创建角色失败，跳过后续测试" -ForegroundColor Red
        return
    }
    
    # 5. 更新角色
    $updatedRole = Test-UpdateRole -roleId $newRole.id
    
    # 6. 切换角色状态
    if ($updatedRole) {
        $toggledRole = Test-ToggleRoleStatus -roleId $newRole.id -currentStatus $updatedRole.status
    }
    
    # 7. 分配权限
    if ($permissions -and $newRole) {
        Test-AssignPermissions -roleId $newRole.id -permissions $permissions
    }
    
    # 8. 清理：删除测试角色
    if ($newRole) {
        Test-DeleteRole -roleId $newRole.id
    }
    
    Write-Host "=== 测试完成 ===" -ForegroundColor Green
}

# 运行主测试
Main