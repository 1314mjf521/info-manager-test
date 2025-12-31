#!/usr/bin/env pwsh

Write-Host "=== 测试新的工单API接口 ===" -ForegroundColor Green

# 等待服务启动
Start-Sleep -Seconds 3

# 1. 登录获取token
Write-Host "1. 登录获取token..." -ForegroundColor Cyan
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

# 2. 创建测试工单
Write-Host "2. 创建测试工单..." -ForegroundColor Cyan
$ticketData = @{
    title = "API测试工单"
    description = "测试accept/reject接口"
    type = "bug"
    priority = "normal"
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method POST -Body $ticketData -Headers $headers
    $ticketId = $createResponse.data.id
    Write-Host "✅ 工单创建成功，ID: $ticketId" -ForegroundColor Green
} catch {
    Write-Host "❌ 创建工单失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. 分配工单
Write-Host "3. 分配工单..." -ForegroundColor Cyan
$assignData = @{
    assignee_id = 1
    comment = "分配给管理员"
} | ConvertTo-Json

try {
    $assignResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId/assign" -Method POST -Body $assignData -Headers $headers
    Write-Host "✅ 工单分配成功，状态: $($assignResponse.data.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ 工单分配失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. 测试接受工单API
Write-Host "4. 测试接受工单API..." -ForegroundColor Cyan
$acceptData = @{
    comment = "接受处理"
} | ConvertTo-Json

try {
    $acceptResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId/accept" -Method POST -Body $acceptData -Headers $headers
    Write-Host "✅ 接受工单成功，状态: $($acceptResponse.data.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ 接受工单失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "错误详情: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

# 5. 创建另一个工单测试拒绝功能
Write-Host "5. 创建工单测试拒绝功能..." -ForegroundColor Cyan
try {
    $createResponse2 = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method POST -Body $ticketData -Headers $headers
    $ticketId2 = $createResponse2.data.id
    Write-Host "✅ 第二个工单创建成功，ID: $ticketId2" -ForegroundColor Green
    
    # 分配工单
    $assignResponse2 = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId2/assign" -Method POST -Body $assignData -Headers $headers
    Write-Host "✅ 第二个工单分配成功" -ForegroundColor Green
    
    # 测试拒绝工单API
    Write-Host "6. 测试拒绝工单API..." -ForegroundColor Cyan
    $rejectData = @{
        comment = "拒绝处理"
    } | ConvertTo-Json
    
    $rejectResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId2/reject" -Method POST -Body $rejectData -Headers $headers
    Write-Host "✅ 拒绝工单成功，状态: $($rejectResponse.data.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ 拒绝工单测试失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "错误详情: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

# 6. 测试重新打开工单API
Write-Host "7. 测试重新打开工单API..." -ForegroundColor Cyan
try {
    # 先将工单状态改为已关闭
    $closeData = @{
        status = "closed"
        comment = "关闭工单"
    } | ConvertTo-Json
    
    $closeResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId/status" -Method PUT -Body $closeData -Headers $headers
    Write-Host "✅ 工单关闭成功" -ForegroundColor Green
    
    # 测试重新打开
    $reopenData = @{
        comment = "重新打开工单"
    } | ConvertTo-Json
    
    $reopenResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId/reopen" -Method POST -Body $reopenData -Headers $headers
    Write-Host "✅ 重新打开工单成功，状态: $($reopenResponse.data.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ 重新打开工单失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "错误详情: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

Write-Host "=== API测试完成 ===" -ForegroundColor Green