# 前后端集成测试脚本
param(
    [string]$BackendUrl = "http://localhost:8080"
)

Write-Host "=== 前后端集成测试 ===" -ForegroundColor Cyan

# 测试后端API
Write-Host "1. 测试后端连接..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$BackendUrl/api/v1/system/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "后端API状态: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "后端API错误: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试正确的登录凭据
Write-Host "`n2. 测试正确登录..." -ForegroundColor Yellow
try {
    $loginData = '{"username":"admin","password":"admin123"}'
    $response = Invoke-WebRequest -Uri "$BackendUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json" -UseBasicParsing
    Write-Host "正确登录状态: $($response.StatusCode)" -ForegroundColor Green
    $data = $response.Content | ConvertFrom-Json
    Write-Host "获得token: $($data.token.Substring(0,20))..." -ForegroundColor Green
} catch {
    Write-Host "正确登录失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试错误的登录凭据
Write-Host "`n3. 测试错误登录..." -ForegroundColor Yellow
try {
    $wrongData = '{"username":"admin","password":"wrongpass"}'
    $response = Invoke-WebRequest -Uri "$BackendUrl/api/v1/auth/login" -Method POST -Body $wrongData -ContentType "application/json" -UseBasicParsing
    Write-Host "错误登录不应该成功: $($response.StatusCode)" -ForegroundColor Red
} catch {
    Write-Host "错误登录正确返回错误: $($_.Exception.Response.StatusCode)" -ForegroundColor Green
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Cyan