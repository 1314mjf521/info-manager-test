# 角色管理优化测试脚本
param(
    [string]$BaseUrl = "http://localhost:8080",
    [string]$Username = "admin", 
    [string]$Password = "admin123"
)

Write-Host "=== 角色管理优化功能测试 ===" -ForegroundColor Green

# 全局变量
$global:Token = ""
$global:Headers = @{
    "Content-Type" = "application/json"
}

# 登录函数
function Test-Login {
    Write-Host "1. 用户登录..." -ForegroundColor Yellow
    
    $loginData = @{
        username = $Username
        password = $Password
    }
    $loginJson = $loginData | ConvertTo-Json -Depth 3
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginJson -Headers $global:Headers
        
        if ($response.success) {
            $global:Token = $response.data.token
            $global:Headers["Authorization"] = "Bearer $global:Token"
            Write-Host "✓ 登录成功" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ 登录失败: $($response.error.message)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "✗ 登录请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 测试获取权限树
function Test-GetPermissionTree {
    Write-Host "2. 测试获取权限树..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions/tree" -Method GET -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 权限树获取成功" -ForegroundColor Green
            Write-Host "权限树结构数量: $($response.data.Count)" -ForegroundColor Cyan
            return $response.data
        } else {
            Write-Host "✗ 权限树获取失败: $($response.error.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 权限树请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 测试获取角色列表
function Test-GetRoles {
    Write-Host "3. 测试获取角色列表..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles" -Method GET -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 角色列表获取成功" -ForegroundColor Green
            Write-Host "角色数量: $($response.data.Count)" -ForegroundColor Cyan
            
            foreach ($role in $response.data) {
                Write-Host "- ID: $($role.id), 名称: $($role.name), 显示名称: $($role.displayName), 状态: $($role.status)" -ForegroundColor White
            }
            return $response.data
        } else {
            Write-Host "✗ 角色列表获取失败: $($response.error.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 角色列表请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 测试创建角色
function Test-CreateRole {
    Write-Host "4. 测试创建角色..." -ForegroundColor Yellow
    
    $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
    $roleData = @{
        name = "test_role_$timestamp"
        displayName = "测试角色"
        description = "这是一个测试角色"
        status = "active"
    }
    $roleJson = $roleData | ConvertTo-Json -Depth 3
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles" -Method POST -Body $roleJson -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 角色创建成功" -ForegroundColor Green
            Write-Host "新角色ID: $($response.data.id)" -ForegroundColor Cyan
            return $response.data
        } else {
            Write-Host "✗ 角色创建失败: $($response.error.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 角色创建请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 测试更新角色
function Test-UpdateRole($roleId) {
    Write-Host "5. 测试更新角色..." -ForegroundColor Yellow
    
    $updateData = @{
        displayName = "更新后的测试角色"
        description = "这是一个更新后的测试角色"
        status = "active"
    }
    $updateJson = $updateData | ConvertTo-Json -Depth 3
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$roleId" -Method PUT -Body $updateJson -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 角色更新成功" -ForegroundColor Green
            Write-Host "更新后的显示名称: $($response.data.displayName)" -ForegroundColor Cyan
            return $response.data
        } else {
            Write-Host "✗ 角色更新失败: $($response.error.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 角色更新请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 测试获取所有权限
function Test-GetAllPermissions {
    Write-Host "6. 测试获取所有权限..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions" -Method GET -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 权限列表获取成功" -ForegroundColor Green
            Write-Host "权限数量: $($response.data.Count)" -ForegroundColor Cyan
            return $response.data
        } else {
            Write-Host "✗ 权限列表获取失败: $($response.error.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 权限列表请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 测试分配权限
function Test-AssignPermissions($roleId, $permissions) {
    Write-Host "7. 测试分配权限..." -ForegroundColor Yellow
    
    # 获取前几个权限ID进行测试
    $permissionIds = @()
    if ($permissions -and $permissions.Count -gt 0) {
        $maxCount = [Math]::Min(3, $permissions.Count)
        for ($i = 0; $i -lt $maxCount; $i++) {
            $permissionIds += $permissions[$i].id
        }
    }
    
    $permissionData = @{
        permissionIds = $permissionIds
    }
    $permissionJson = $permissionData | ConvertTo-Json -Depth 3
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$roleId/permissions" -Method PUT -Body $permissionJson -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 权限分配成功" -ForegroundColor Green
            Write-Host "分配的权限数量: $($response.data.permissions.Count)" -ForegroundColor Cyan
            return $response.data
        } else {
            Write-Host "✗ 权限分配失败: $($response.error.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 权限分配请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 测试获取角色权限
function Test-GetRolePermissions($roleId) {
    Write-Host "8. 测试获取角色权限..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$roleId/permissions" -Method GET -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 角色权限获取成功" -ForegroundColor Green
            Write-Host "权限数量: $($response.data.Count)" -ForegroundColor Cyan
            
            foreach ($permission in $response.data) {
                Write-Host "- $($permission.displayName): $($permission.resource):$($permission.action)" -ForegroundColor White
            }
            return $response.data
        } else {
            Write-Host "✗ 角色权限获取失败: $($response.error.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 角色权限请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 测试删除角色
function Test-DeleteRole($roleId) {
    Write-Host "9. 测试删除角色..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$roleId" -Method DELETE -Headers $global:Headers
        
        if ($response.success) {
            Write-Host "✓ 角色删除成功" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ 角色删除失败: $($response.error.message)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "✗ 角色删除请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 主测试流程
function Start-Test {
    Write-Host "开始角色管理优化功能测试..." -ForegroundColor Green
    Write-Host "测试服务器: $BaseUrl" -ForegroundColor Cyan
    Write-Host ""
    
    # 1. 登录
    if (-not (Test-Login)) {
        Write-Host "登录失败，终止测试" -ForegroundColor Red
        return
    }
    Write-Host ""
    
    # 2. 获取权限树
    $permissionTree = Test-GetPermissionTree
    Write-Host ""
    
    # 3. 获取角色列表
    $roles = Test-GetRoles
    Write-Host ""
    
    # 4. 创建角色
    $newRole = Test-CreateRole
    if (-not $newRole) {
        Write-Host "角色创建失败，跳过后续测试" -ForegroundColor Red
        return
    }
    Write-Host ""
    
    # 5. 更新角色
    $updatedRole = Test-UpdateRole $newRole.id
    Write-Host ""
    
    # 6. 获取所有权限
    $permissions = Test-GetAllPermissions
    Write-Host ""
    
    # 7. 分配权限
    if ($permissions) {
        $roleWithPermissions = Test-AssignPermissions $newRole.id $permissions
        Write-Host ""
        
        # 8. 获取角色权限
        Test-GetRolePermissions $newRole.id
        Write-Host ""
    }
    
    # 9. 删除角色
    Test-DeleteRole $newRole.id
    Write-Host ""
    
    Write-Host "=== 测试完成 ===" -ForegroundColor Green
}

# 运行测试
Start-Test