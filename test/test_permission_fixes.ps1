# 测试权限问题修复的脚本
# 编码：UTF-8

Write-Host "=== 测试权限问题修复 ===" -ForegroundColor Green

# 设置基础变量
$baseUrl = "http://localhost:8080"
$adminToken = ""
$userToken = ""

# 函数：获取管理员Token
function Get-AdminToken {
    Write-Host "正在获取管理员Token..." -ForegroundColor Yellow
    
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method Post -Body $loginData -ContentType "application/json"
        if ($response.success) {
            Write-Host "✓ 管理员登录成功" -ForegroundColor Green
            return $response.data.token
        } else {
            Write-Host "✗ 管理员登录失败: $($response.error.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 管理员登录请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 函数：创建测试用户
function Create-TestUser {
    param($adminToken)
    
    Write-Host "正在创建测试用户..." -ForegroundColor Yellow
    
    $userData = @{
        username = "testuser"
        email = "testuser@example.com"
        displayName = "测试用户"
        password = "testpass123"
        status = "active"
    } | ConvertTo-Json -Depth 10
    
    $headers = @{
        "Authorization" = "Bearer $adminToken"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/admin/users" -Method Post -Body $userData -Headers $headers
        if ($response.success) {
            Write-Host "✓ 测试用户创建成功，ID: $($response.data.id)" -ForegroundColor Green
            return $response.data.id
        } else {
            Write-Host "✗ 测试用户创建失败: $($response.error.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 测试用户创建请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 函数：获取测试用户Token
function Get-TestUserToken {
    Write-Host "正在获取测试用户Token..." -ForegroundColor Yellow
    
    $loginData = @{
        username = "testuser"
        password = "testpass123"
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method Post -Body $loginData -ContentType "application/json"
        if ($response.success) {
            Write-Host "✓ 测试用户登录成功" -ForegroundColor Green
            return $response.data.token
        } else {
            Write-Host "✗ 测试用户登录失败: $($response.error.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 测试用户登录请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 函数：测试权限验证
function Test-PermissionValidation {
    param($adminToken, $userToken)
    
    Write-Host "`n--- 测试权限验证 ---" -ForegroundColor Cyan
    
    # 测试管理员权限
    Write-Host "测试管理员权限..." -ForegroundColor Yellow
    
    $adminHeaders = @{
        "Authorization" = "Bearer $adminToken"
        "Content-Type" = "application/json"
    }
    
    try {
        # 测试获取用户列表（需要管理员权限）
        $response = Invoke-RestMethod -Uri "$baseUrl/admin/users" -Method Get -Headers $adminHeaders
        if ($response.success) {
            Write-Host "  ✓ 管理员可以访问用户列表" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 管理员无法访问用户列表: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ 管理员访问用户列表失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    try {
        # 测试获取角色列表（需要管理员权限）
        $response = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method Get -Headers $adminHeaders
        if ($response.success) {
            Write-Host "  ✓ 管理员可以访问角色列表" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 管理员无法访问角色列表: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ 管理员访问角色列表失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 测试普通用户权限
    Write-Host "测试普通用户权限..." -ForegroundColor Yellow
    
    $userHeaders = @{
        "Authorization" = "Bearer $userToken"
        "Content-Type" = "application/json"
    }
    
    try {
        # 测试普通用户访问管理员接口（应该被拒绝）
        $response = Invoke-RestMethod -Uri "$baseUrl/admin/users" -Method Get -Headers $userHeaders
        Write-Host "  ✗ 普通用户不应该能访问用户列表" -ForegroundColor Red
    } catch {
        if ($_.Exception.Response.StatusCode -eq 403) {
            Write-Host "  ✓ 普通用户正确被拒绝访问用户列表" -ForegroundColor Green
        } else {
            Write-Host "  ? 普通用户访问用户列表返回意外错误: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    try {
        # 测试普通用户访问自己的资料（应该允许）
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/users/profile" -Method Get -Headers $userHeaders
        if ($response.success) {
            Write-Host "  ✓ 普通用户可以访问自己的资料" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 普通用户无法访问自己的资料: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ 普通用户访问资料失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 函数：测试权限树获取
function Test-PermissionTree {
    param($adminToken)
    
    Write-Host "`n--- 测试权限树获取 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $adminToken"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/permissions/tree" -Method Get -Headers $headers
        if ($response.success) {
            Write-Host "✓ 权限树获取成功" -ForegroundColor Green
            $permissions = $response.data
            Write-Host "  权限树节点数量: $($permissions.Count)" -ForegroundColor Cyan
            
            # 检查权限树结构
            foreach ($permission in $permissions) {
                if ($permission.displayName) {
                    Write-Host "  - $($permission.displayName)" -ForegroundColor Gray
                    if ($permission.children -and $permission.children.Count -gt 0) {
                        foreach ($child in $permission.children) {
                            Write-Host "    - $($child.displayName)" -ForegroundColor DarkGray
                        }
                    }
                }
            }
        } else {
            Write-Host "✗ 权限树获取失败: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 权限树获取请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 函数：测试角色权限分配
function Test-RolePermissionAssignment {
    param($adminToken)
    
    Write-Host "`n--- 测试角色权限分配 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $adminToken"
        "Content-Type" = "application/json"
    }
    
    try {
        # 获取角色列表
        $rolesResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method Get -Headers $headers
        if ($rolesResponse.success -and $rolesResponse.data.Count -gt 0) {
            $testRole = $rolesResponse.data[0]
            Write-Host "测试角色: $($testRole.displayName)" -ForegroundColor Yellow
            
            # 获取权限列表
            $permissionsResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/permissions" -Method Get -Headers $headers
            if ($permissionsResponse.success -and $permissionsResponse.data.Count -gt 0) {
                $testPermissions = $permissionsResponse.data | Select-Object -First 3
                $permissionIds = $testPermissions | ForEach-Object { $_.id }
                
                # 分配权限
                $assignData = @{
                    permissionIds = $permissionIds
                } | ConvertTo-Json -Depth 10
                
                $assignResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles/$($testRole.id)/permissions" -Method Post -Body $assignData -Headers $headers
                if ($assignResponse.success) {
                    Write-Host "✓ 角色权限分配成功" -ForegroundColor Green
                    
                    # 验证权限分配
                    $checkResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles/$($testRole.id)/permissions" -Method Get -Headers $headers
                    if ($checkResponse.success) {
                        Write-Host "✓ 权限分配验证成功，当前权限数量: $($checkResponse.data.Count)" -ForegroundColor Green
                    } else {
                        Write-Host "✗ 权限分配验证失败: $($checkResponse.error.message)" -ForegroundColor Red
                    }
                } else {
                    Write-Host "✗ 角色权限分配失败: $($assignResponse.error.message)" -ForegroundColor Red
                }
            } else {
                Write-Host "! 没有找到可用的权限" -ForegroundColor Yellow
            }
        } else {
            Write-Host "! 没有找到可用的角色" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ 角色权限分配测试失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 函数：清理测试数据
function Cleanup-TestData {
    param($adminToken)
    
    Write-Host "`n--- 清理测试数据 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $adminToken"
        "Content-Type" = "application/json"
    }
    
    # 删除测试用户
    try {
        $usersResponse = Invoke-RestMethod -Uri "$baseUrl/admin/users" -Method Get -Headers $headers
        if ($usersResponse.success) {
            foreach ($user in $usersResponse.data.items) {
                if ($user.username -eq "testuser") {
                    try {
                        $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/admin/users/$($user.id)" -Method Delete -Headers $headers
                        if ($deleteResponse.success) {
                            Write-Host "  ✓ 删除测试用户成功" -ForegroundColor Green
                        }
                    } catch {
                        Write-Host "  ✗ 删除测试用户失败" -ForegroundColor Red
                    }
                    break
                }
            }
        }
    } catch {
        Write-Host "  ✗ 清理测试用户失败" -ForegroundColor Red
    }
}

# 主执行流程
try {
    # 获取管理员Token
    $adminToken = Get-AdminToken
    if (-not $adminToken) {
        Write-Host "无法获取管理员Token，测试终止" -ForegroundColor Red
        exit 1
    }
    
    # 创建测试用户
    $testUserId = Create-TestUser -adminToken $adminToken
    if (-not $testUserId) {
        Write-Host "无法创建测试用户，跳过用户权限测试" -ForegroundColor Yellow
    } else {
        # 获取测试用户Token
        $userToken = Get-TestUserToken
        if ($userToken) {
            # 测试权限验证
            Test-PermissionValidation -adminToken $adminToken -userToken $userToken
        }
    }
    
    # 测试权限树获取
    Test-PermissionTree -adminToken $adminToken
    
    # 测试角色权限分配
    Test-RolePermissionAssignment -adminToken $adminToken
    
    # 清理测试数据
    if ($testUserId) {
        Cleanup-TestData -adminToken $adminToken
    }
    
    Write-Host "`n=== 权限问题修复测试完成 ===" -ForegroundColor Green
    
} catch {
    Write-Host "测试过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}