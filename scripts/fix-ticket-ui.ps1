#!/usr/bin/env pwsh

Write-Host "=== 修复工单界面显示问题 ===" -ForegroundColor Green

# 1. 检查后端是否运行
Write-Host "检查后端服务..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/health" -Method GET -TimeoutSec 5
    Write-Host "✅ 后端服务正常运行" -ForegroundColor Green
} catch {
    Write-Host "❌ 后端服务未运行，正在启动..." -ForegroundColor Yellow
    Start-Process -FilePath "go" -ArgumentList "run", "main.go" -WorkingDirectory "." -WindowStyle Hidden
    Start-Sleep -Seconds 5
}

# 2. 测试权限API
Write-Host "测试权限API..." -ForegroundColor Cyan
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 检查权限
    $permissionsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/permissions" -Method GET -Headers $headers
    $ticketPermissions = $permissionsResponse.data | Where-Object { $_ -like "ticket:*" }
    
    Write-Host "✅ 找到 $($ticketPermissions.Count) 个工单权限" -ForegroundColor Green
    
    if ($ticketPermissions.Count -eq 0) {
        Write-Host "❌ 没有找到工单权限，需要初始化权限" -ForegroundColor Red
        Write-Host "运行权限初始化脚本..." -ForegroundColor Yellow
        & "scripts/init-ticket-permissions.ps1"
    }
    
} catch {
    Write-Host "❌ 权限API测试失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. 清除前端缓存
Write-Host "清除前端缓存..." -ForegroundColor Cyan
if (Test-Path "frontend/node_modules/.vite") {
    Remove-Item -Recurse -Force "frontend/node_modules/.vite"
    Write-Host "✅ 已清除 Vite 缓存" -ForegroundColor Green
}

# 4. 提供调试信息
Write-Host "=== 调试信息 ===" -ForegroundColor Yellow
Write-Host "1. 访问权限调试页面: http://localhost:5173/tickets/debug" -ForegroundColor Cyan
Write-Host "2. 访问工单管理页面: http://localhost:5173/tickets" -ForegroundColor Cyan
Write-Host "3. 如果按钮和统计不显示，检查权限配置" -ForegroundColor Cyan

Write-Host "=== 修复完成 ===" -ForegroundColor Green