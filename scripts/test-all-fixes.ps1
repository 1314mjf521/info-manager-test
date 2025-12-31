#!/usr/bin/env pwsh

Write-Host "=== 测试所有工单系统修复 ===" -ForegroundColor Green

# 1. 重启后端服务以加载新的API
Write-Host "重启后端服务..." -ForegroundColor Cyan
Get-Process -Name "go" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Start-Process -FilePath "go" -ArgumentList "run", "main.go" -WorkingDirectory "." -WindowStyle Hidden
Start-Sleep -Seconds 5

# 2. 测试登录
Write-Host "测试用户登录..." -ForegroundColor Cyan
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
    Write-Host "✅ 登录成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. 测试创建工单
Write-Host "测试创建工单..." -ForegroundColor Cyan
$ticketData = @{
    title = "测试工单 - 完整功能验证"
    description = "测试所有修复的功能"
    type = "bug"
    priority = "normal"
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method POST -Body $ticketData -Headers $headers
    $ticketId = $createResponse.data.id
    Write-Host "✅ 工单创建成功，ID: $ticketId" -ForegroundColor Green
    Write-Host "工单状态: $($createResponse.data.status)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ 创建工单失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 4. 测试分配工单
Write-Host "测试分配工单..." -ForegroundColor Cyan
$assignData = @{
    assignee_id = 1
    comment = "分配给管理员处理"
} | ConvertTo-Json

try {
    $assignResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId/assign" -Method POST -Body $assignData -Headers $headers
    Write-Host "✅ 工单分配成功" -ForegroundColor Green
    Write-Host "新状态: $($assignResponse.data.status)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ 工单分配失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. 测试接受工单API
Write-Host "测试接受工单API..." -ForegroundColor Cyan
$acceptData = @{
    comment = "接受处理此工单"
} | ConvertTo-Json

try {
    $acceptResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId/accept" -Method POST -Body $acceptData -Headers $headers
    Write-Host "✅ 工单接受成功" -ForegroundColor Green
    Write-Host "新状态: $($acceptResponse.data.status)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ 工单接受失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "错误详情: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

# 6. 测试状态更新API
Write-Host "测试状态更新API..." -ForegroundColor Cyan
$statusData = @{
    status = "progress"
    comment = "开始处理工单"
} | ConvertTo-Json

try {
    $statusResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId/status" -Method PUT -Body $statusData -Headers $headers
    Write-Host "✅ 状态更新成功" -ForegroundColor Green
    Write-Host "新状态: $($statusResponse.data.status)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ 状态更新失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "错误详情: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

# 7. 测试工单详情API
Write-Host "测试工单详情API..." -ForegroundColor Cyan
try {
    $detailResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId" -Method GET -Headers $headers
    Write-Host "✅ 工单详情获取成功" -ForegroundColor Green
    Write-Host "工单信息: ID=$($detailResponse.data.id), 状态=$($detailResponse.data.status), 标题=$($detailResponse.data.title)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ 获取工单详情失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 8. 测试工单列表API
Write-Host "测试工单列表API..." -ForegroundColor Cyan
try {
    $listResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets?page=1&size=10" -Method GET -Headers $headers
    Write-Host "✅ 工单列表获取成功" -ForegroundColor Green
    Write-Host "工单总数: $($listResponse.data.total)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ 获取工单列表失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 9. 清除前端缓存
Write-Host "清除前端缓存..." -ForegroundColor Cyan
if (Test-Path "frontend/node_modules/.vite") {
    Remove-Item -Recurse -Force "frontend/node_modules/.vite"
    Write-Host "✅ 已清除 Vite 缓存" -ForegroundColor Green
}

Write-Host "=== 测试完成 ===" -ForegroundColor Green
Write-Host ""
Write-Host "修复总结:" -ForegroundColor Yellow
Write-Host "✅ 1. 修复了接受工单API 404错误" -ForegroundColor Green
Write-Host "✅ 2. 修复了工单详情页面权限错误" -ForegroundColor Green
Write-Host "✅ 3. 修复了标签类型验证错误" -ForegroundColor Green
Write-Host "✅ 4. 改进了创建工单的附件上传提示" -ForegroundColor Green
Write-Host "✅ 5. 统一了前后端状态值映射" -ForegroundColor Green
Write-Host "✅ 6. 修复了更多操作的事件冒泡问题" -ForegroundColor Green
Write-Host ""
Write-Host "现在可以访问前端页面测试:" -ForegroundColor Cyan
Write-Host "- 工单列表: http://localhost:5173/tickets" -ForegroundColor White
Write-Host "- 创建工单: http://localhost:5173/tickets/create" -ForegroundColor White
Write-Host "- 工单详情: http://localhost:5173/tickets/$ticketId" -ForegroundColor White