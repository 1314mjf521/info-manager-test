# 快速API测试脚本

$baseUrl = "http://localhost:8080/api/v1"
$headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== 快速API测试 ===" -ForegroundColor Green

# 1. 测试健康检查
Write-Host "1. 测试健康检查..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET
    Write-Host "✓ 后端服务正常运行" -ForegroundColor Green
} catch {
    Write-Host "✗ 后端服务不可用: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. 测试登录
Write-Host "2. 测试登录..." -ForegroundColor Yellow
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -Headers $headers
    if ($loginResponse.success -and $loginResponse.data.token) {
        $token = $loginResponse.data.token
        $authHeaders = @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $token"
        }
        Write-Host "✓ 登录成功" -ForegroundColor Green
    } else {
        throw "登录响应格式不正确"
    }
} catch {
    Write-Host "✗ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. 测试工单API
Write-Host "3. 测试工单API..." -ForegroundColor Yellow
try {
    $ticketsResponse = Invoke-RestMethod -Uri "$baseUrl/tickets" -Method GET -Headers $authHeaders
    Write-Host "✓ 工单API正常" -ForegroundColor Green
    Write-Host "  响应格式: $($ticketsResponse.GetType().Name)" -ForegroundColor Cyan
    if ($ticketsResponse.total -ne $null) {
        Write-Host "  工单总数: $($ticketsResponse.total)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "✗ 工单API失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  状态码: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
}

# 4. 测试用户API
Write-Host "4. 测试用户API..." -ForegroundColor Yellow
try {
    $usersResponse = Invoke-RestMethod -Uri "$baseUrl/users" -Method GET -Headers $authHeaders
    Write-Host "✓ 用户API正常" -ForegroundColor Green
} catch {
    Write-Host "✗ 用户API失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. 测试权限API
Write-Host "5. 测试权限API..." -ForegroundColor Yellow
try {
    $permissionsResponse = Invoke-RestMethod -Uri "$baseUrl/permissions" -Method GET -Headers $authHeaders
    Write-Host "✓ 权限API正常" -ForegroundColor Green
    if ($permissionsResponse.permissions) {
        $ticketPerms = $permissionsResponse.permissions | Where-Object { $_.name -like "ticket*" }
        Write-Host "  工单权限数量: $($ticketPerms.Count)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "✗ 权限API失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== 测试完成 ===" -ForegroundColor Green