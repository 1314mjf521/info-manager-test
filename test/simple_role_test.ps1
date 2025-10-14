# 简单的角色管理测试
$BaseUrl = "http://localhost:8080"
$Username = "admin"
$Password = "admin123"

Write-Host "=== 角色管理测试 ===" -ForegroundColor Green

# 登录
Write-Host "1. 登录..." -ForegroundColor Yellow
$loginData = @{
    username = $Username
    password = $Password
} | ConvertTo-Json

$headers = @{
    "Content-Type" = "application/json"
}

try {
    $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -Headers $headers
    
    if ($loginResponse.success) {
        Write-Host "✓ 登录成功" -ForegroundColor Green
        $token = $loginResponse.data.token
        $headers["Authorization"] = "Bearer $token"
    } else {
        Write-Host "✗ 登录失败: $($loginResponse.error.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ 登录请求失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 获取角色列表
Write-Host "2. 获取角色列表..." -ForegroundColor Yellow
try {
    $rolesResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles" -Method GET -Headers $headers
    
    if ($rolesResponse.success) {
        Write-Host "✓ 角色列表获取成功" -ForegroundColor Green
        Write-Host "角色数量: $($rolesResponse.data.Count)" -ForegroundColor Cyan
        
        foreach ($role in $rolesResponse.data) {
            Write-Host "- ID: $($role.id), 名称: $($role.name), 显示名称: $($role.displayName), 状态: $($role.status)" -ForegroundColor White
        }
    } else {
        Write-Host "✗ 角色列表获取失败: $($rolesResponse.error.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 角色列表请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 获取权限列表
Write-Host "3. 获取权限列表..." -ForegroundColor Yellow
try {
    $permissionsResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions" -Method GET -Headers $headers
    
    if ($permissionsResponse.success) {
        Write-Host "✓ 权限列表获取成功" -ForegroundColor Green
        Write-Host "权限数量: $($permissionsResponse.data.Count)" -ForegroundColor Cyan
    } else {
        Write-Host "✗ 权限列表获取失败: $($permissionsResponse.error.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 权限列表请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 获取权限树
Write-Host "4. 获取权限树..." -ForegroundColor Yellow
try {
    $treeResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions/tree" -Method GET -Headers $headers
    
    if ($treeResponse.success) {
        Write-Host "✓ 权限树获取成功" -ForegroundColor Green
        Write-Host "权限树节点数量: $($treeResponse.data.Count)" -ForegroundColor Cyan
    } else {
        Write-Host "✗ 权限树获取失败: $($treeResponse.error.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 权限树请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=== 测试完成 ===" -ForegroundColor Green