#!/usr/bin/env pwsh

Write-Host "=== 测试工单导航修复 ===" -ForegroundColor Green

# 1. 检查API是否正常
Write-Host "`n1. 测试API连接..." -ForegroundColor Yellow

try {
    # 测试登录
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.token) {
        Write-Host "✓ 登录成功" -ForegroundColor Green
        $token = $loginResponse.token
        
        # 测试工单API
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        
        $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $headers
        Write-Host "✓ 工单API正常工作" -ForegroundColor Green
        
        # 测试用户权限
        $userResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/profile" -Method GET -Headers $headers
        Write-Host "✓ 用户API正常工作" -ForegroundColor Green
        
        if ($userResponse.permissions) {
            $hasTicketPermission = $userResponse.permissions | Where-Object { $_.name -like "*ticket*" }
            if ($hasTicketPermission) {
                Write-Host "✓ 用户具有工单权限" -ForegroundColor Green
            } else {
                Write-Host "⚠ 用户没有工单权限" -ForegroundColor Yellow
            }
        }
        
    } else {
        Write-Host "✗ 登录失败" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ API连接失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "请确保服务器正在运行 (运行 .\start.bat)" -ForegroundColor Yellow
    exit 1
}

# 2. 检查前端导航配置
Write-Host "`n2. 检查前端导航配置..." -ForegroundColor Yellow

$layoutFile = "frontend/src/layout/MainLayout.vue"
if (Test-Path $layoutFile) {
    $content = Get-Content $layoutFile -Raw
    if ($content -match "工单管理") {
        Write-Host "✓ 导航菜单已包含工单管理" -ForegroundColor Green
    } else {
        Write-Host "✗ 导航菜单缺少工单管理" -ForegroundColor Red
    }
    
    if ($content -match "ticket:view") {
        Write-Host "✓ 工单权限配置正确" -ForegroundColor Green
    } else {
        Write-Host "✗ 工单权限配置错误" -ForegroundColor Red
    }
} else {
    Write-Host "✗ 找不到布局文件" -ForegroundColor Red
}

# 3. 检查路由配置
Write-Host "`n3. 检查路由配置..." -ForegroundColor Yellow

$routerFile = "frontend/src/router/index.ts"
if (Test-Path $routerFile) {
    $content = Get-Content $routerFile -Raw
    if ($content -match "/tickets") {
        Write-Host "✓ 工单路由已配置" -ForegroundColor Green
    } else {
        Write-Host "✗ 工单路由未配置" -ForegroundColor Red
    }
} else {
    Write-Host "✗ 找不到路由文件" -ForegroundColor Red
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
Write-Host "如果所有检查都通过，请:" -ForegroundColor Yellow
Write-Host "1. 重启前端开发服务器 (npm run dev)" -ForegroundColor White
Write-Host "2. 刷新浏览器页面" -ForegroundColor White
Write-Host "3. 检查导航栏是否显示工单管理" -ForegroundColor White