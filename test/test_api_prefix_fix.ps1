# API前缀重复问题修复验证脚本
$BaseUrl = "http://localhost:8080"
$Headers = @{}

Write-Host "=== API前缀重复问题修复验证 ===" -ForegroundColor Cyan

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

# 测试正确的API路径
Write-Host "2. 测试正确的API路径..." -ForegroundColor Yellow

$testApis = @(
    @{ Name = "角色列表"; Url = "/api/v1/roles"; Method = "GET" },
    @{ Name = "用户列表"; Url = "/api/v1/users"; Method = "GET" },
    @{ Name = "权限列表"; Url = "/api/v1/permissions"; Method = "GET" },
    @{ Name = "权限树"; Url = "/api/v1/permissions/tree"; Method = "GET" }
)

foreach ($api in $testApis) {
    try {
        Write-Host "  测试 $($api.Name)..." -ForegroundColor White
        $response = Invoke-RestMethod -Uri "$BaseUrl$($api.Url)" -Method $api.Method -Headers $Headers
        
        if ($response.success) {
            Write-Host "    ✓ $($api.Name) 请求成功" -ForegroundColor Green
            if ($response.data) {
                $count = if ($response.data.Count) { $response.data.Count } else { "未知" }
                Write-Host "      数据量: $count" -ForegroundColor Cyan
            }
        } else {
            Write-Host "    ✗ $($api.Name) 请求失败: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "    ✗ $($api.Name) 请求异常: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 测试错误的API路径（应该返回404）
Write-Host "3. 测试错误的API路径（应该返回404）..." -ForegroundColor Yellow

$errorApis = @(
    @{ Name = "重复前缀角色列表"; Url = "/api/v1/api/v1/roles" },
    @{ Name = "重复前缀权限树"; Url = "/api/v1/api/v1/permissions/tree" }
)

foreach ($api in $errorApis) {
    try {
        Write-Host "  测试 $($api.Name)..." -ForegroundColor White
        $response = Invoke-RestMethod -Uri "$BaseUrl$($api.Url)" -Method GET -Headers $Headers
        Write-Host "    ✗ $($api.Name) 意外成功（应该返回404）" -ForegroundColor Red
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Host "    ✓ $($api.Name) 正确返回404" -ForegroundColor Green
        } else {
            Write-Host "    ? $($api.Name) 返回其他错误: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

Write-Host "=== 测试完成 ===" -ForegroundColor Green
Write-Host ""
Write-Host "修复说明:" -ForegroundColor Cyan
Write-Host "1. 移除了前端组件中重复的 /api/v1 前缀" -ForegroundColor White
Write-Host "2. HTTP请求工具已经配置了baseURL包含 /api/v1" -ForegroundColor White
Write-Host "3. 前端组件只需要使用相对路径，如 '/roles' 而不是 '/api/v1/roles'" -ForegroundColor White
Write-Host "4. 修复了角色管理和用户管理组件中的所有API调用" -ForegroundColor White
Write-Host ""
Write-Host "现在前端应该能正常访问后端API了" -ForegroundColor Yellow