# 用户管理API测试脚本
$BaseUrl = "http://localhost:8080"
$Headers = @{}

Write-Host "=== 用户管理API测试 ===" -ForegroundColor Cyan

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

# 测试用户列表API
Write-Host "2. 测试用户列表API..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/users" -Method GET -Headers $Headers
    
    if ($response.success) {
        Write-Host "✓ 用户列表获取成功" -ForegroundColor Green
        $users = $response.data.items
        Write-Host "  用户数量: $($users.Count)" -ForegroundColor Cyan
        
        foreach ($user in $users) {
            Write-Host "    - $($user.username) ($($user.displayName)) - $($user.status)" -ForegroundColor White
        }
    } else {
        Write-Host "✗ 用户列表获取失败: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 用户列表请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试创建用户
Write-Host "3. 测试创建用户..." -ForegroundColor Yellow
$userData = @{
    username = "test_user_$(Get-Date -Format 'yyyyMMddHHmmss')"
    email = "test@example.com"
    displayName = "测试用户"
    password = "test123456"
    status = "active"
    description = "这是一个测试用户"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/users" -Method POST -Body $userData -Headers $Headers
    
    if ($response.success) {
        Write-Host "✓ 用户创建成功" -ForegroundColor Green
        Write-Host "  新用户ID: $($response.data.id)" -ForegroundColor Cyan
        $newUserId = $response.data.id
    } else {
        Write-Host "✗ 用户创建失败: $($response.message)" -ForegroundColor Red
        $newUserId = $null
    }
} catch {
    Write-Host "✗ 用户创建请求失败: $($_.Exception.Message)" -ForegroundColor Red
    $newUserId = $null
}

# 如果创建成功，测试其他操作
if ($newUserId) {
    # 测试获取用户详情
    Write-Host "4. 测试获取用户详情..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/users/$newUserId" -Method GET -Headers $Headers
        
        if ($response.success) {
            Write-Host "✓ 用户详情获取成功" -ForegroundColor Green
            Write-Host "  用户名: $($response.data.username)" -ForegroundColor Cyan
        } else {
            Write-Host "✗ 用户详情获取失败: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 用户详情请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 测试更新用户
    Write-Host "5. 测试更新用户..." -ForegroundColor Yellow
    $updateData = @{
        displayName = "更新后的测试用户"
        description = "这是更新后的描述"
        status = "active"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/users/$newUserId" -Method PUT -Body $updateData -Headers $Headers
        
        if ($response.success) {
            Write-Host "✓ 用户更新成功" -ForegroundColor Green
            Write-Host "  更新后的显示名称: $($response.data.displayName)" -ForegroundColor Cyan
        } else {
            Write-Host "✗ 用户更新失败: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 用户更新请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 测试角色分配
    Write-Host "6. 测试角色分配..." -ForegroundColor Yellow
    $roleData = @{
        roleIds = @(2) # 分配普通用户角色
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/users/$newUserId/roles" -Method PUT -Body $roleData -Headers $Headers
        
        if ($response.success) {
            Write-Host "✓ 角色分配成功" -ForegroundColor Green
            Write-Host "  分配的角色数量: $($response.data.roles.Count)" -ForegroundColor Cyan
        } else {
            Write-Host "✗ 角色分配失败: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 角色分配请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 清理：删除测试用户
    Write-Host "7. 清理测试用户..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/users/$newUserId" -Method DELETE -Headers $Headers
        
        if ($response.success) {
            Write-Host "✓ 用户删除成功" -ForegroundColor Green
        } else {
            Write-Host "✗ 用户删除失败: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 用户删除请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "=== 测试完成 ===" -ForegroundColor Green
Write-Host ""
Write-Host "修复说明:" -ForegroundColor Cyan
Write-Host "1. 创建了用户管理处理器 (user_handler.go)" -ForegroundColor White
Write-Host "2. 扩展了用户服务，添加了用户管理相关方法" -ForegroundColor White
Write-Host "3. 在应用程序中添加了用户管理路由" -ForegroundColor White
Write-Host "4. 用户管理功能需要管理员权限" -ForegroundColor White
Write-Host ""
Write-Host "现在用户管理界面应该能正常工作了" -ForegroundColor Yellow