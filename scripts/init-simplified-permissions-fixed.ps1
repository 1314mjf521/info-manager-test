# 初始化简化权限系统脚本

Write-Host "=== 初始化简化权限系统 ===" -ForegroundColor Green

# API基础URL
$baseUrl = "http://localhost:8080/api/v1"

# 管理员token（需要先登录获取）
$adminToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MzUyMTU0NzQsInVzZXJfaWQiOjF9.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8"

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

try {
    Write-Host "1. 初始化简化权限..." -ForegroundColor Yellow
    $response = Invoke-RestMethod -Uri "$baseUrl/permissions/initialize-simplified" -Method POST -Headers $headers
    Write-Host "   权限初始化完成" -ForegroundColor Green
    
    Write-Host "=== 简化权限系统初始化完成 ===" -ForegroundColor Green
    
} catch {
    Write-Host "初始化失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "错误详情: $($_.Exception)" -ForegroundColor Red
}