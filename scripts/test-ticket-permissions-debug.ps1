#!/usr/bin/env pwsh

Write-Host "=== 测试工单权限调试 ===" -ForegroundColor Green

# 启动后端服务
Write-Host "启动后端服务..." -ForegroundColor Cyan
Start-Process -FilePath "go" -ArgumentList "run", "main.go" -WorkingDirectory "." -WindowStyle Hidden

# 等待服务启动
Start-Sleep -Seconds 3

# 测试登录并获取权限
Write-Host "测试用户登录和权限..." -ForegroundColor Cyan

$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    # 登录
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    Write-Host "✅ 登录成功" -ForegroundColor Green
    
    $token = $loginResponse.data.token
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 获取用户信息和权限
    $userResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/me" -Method GET -Headers $headers
    Write-Host "✅ 获取用户信息成功" -ForegroundColor Green
    Write-Host "用户角色: $($userResponse.data.roles -join ', ')" -ForegroundColor Yellow
    
    # 获取权限列表
    $permissionsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/permissions" -Method GET -Headers $headers
    Write-Host "✅ 获取权限列表成功" -ForegroundColor Green
    Write-Host "权限数量: $($permissionsResponse.data.Count)" -ForegroundColor Yellow
    
    # 显示工单相关权限
    $ticketPermissions = $permissionsResponse.data | Where-Object { $_ -like "ticket:*" }
    Write-Host "工单相关权限:" -ForegroundColor Cyan
    $ticketPermissions | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
    
    # 测试工单统计API
    Write-Host "测试工单统计API..." -ForegroundColor Cyan
    try {
        $statsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/tickets/statistics" -Method GET -Headers $headers
        Write-Host "✅ 工单统计API调用成功" -ForegroundColor Green
        Write-Host "统计数据: $($statsResponse.data | ConvertTo-Json -Compress)" -ForegroundColor Yellow
    } catch {
        Write-Host "❌ 工单统计API调用失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 测试工单列表API
    Write-Host "测试工单列表API..." -ForegroundColor Cyan
    try {
        $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/tickets?page=1&size=10" -Method GET -Headers $headers
        Write-Host "✅ 工单列表API调用成功" -ForegroundColor Green
        Write-Host "工单数量: $($ticketsResponse.data.total)" -ForegroundColor Yellow
    } catch {
        Write-Host "❌ 工单列表API调用失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ 测试失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=== 权限调试测试完成 ===" -ForegroundColor Green