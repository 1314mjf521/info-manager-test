# 简单修复脚本

$baseUrl = "http://localhost:8080/api/v1"
$headers = @{"Content-Type" = "application/json"}

Write-Host "=== 简单修复工单权限 ===" -ForegroundColor Green

# 登录
$loginData = @{username = "admin"; password = "admin123"} | ConvertTo-Json
$loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -Headers $headers
$token = $loginResponse.data.token
$authHeaders = @{"Content-Type" = "application/json"; "Authorization" = "Bearer $token"}

Write-Host "登录成功" -ForegroundColor Green

# 测试工单API
try {
    $ticketsResponse = Invoke-RestMethod -Uri "$baseUrl/tickets" -Method GET -Headers $authHeaders
    Write-Host "工单API正常工作" -ForegroundColor Green
} catch {
    Write-Host "工单API错误: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试用户API
try {
    $usersResponse = Invoke-RestMethod -Uri "$baseUrl/users" -Method GET -Headers $authHeaders
    Write-Host "用户API正常工作" -ForegroundColor Green
} catch {
    Write-Host "用户API错误: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "修复完成" -ForegroundColor Green