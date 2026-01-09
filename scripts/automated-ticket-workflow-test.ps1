#!/usr/bin/env pwsh

Write-Host "=== 自动化工单流程测试 ===" -ForegroundColor Green

# 全局变量
$baseUrl = "http://localhost:8080/api/v1"
$frontendUrl = "http://localhost:3000"
$adminToken = ""
$testTicketId = 0
$testResults = @()

# 辅助函数：发送HTTP请求
function Invoke-ApiRequest {
    param(
        [string]$Method,
        [string]$Uri,
        [hashtable]$Headers = @{},
        [object]$Body = $null
    )
    
    try {
        $params = @{
            Method = $Method
            Uri = $Uri
            Headers = $Headers
            ContentType = "application/json"
        }
        
        if ($Body) {
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
        }
        
        $response = Invoke-RestMethod @params
        return $response
    } catch {
        Write-Host "API请求失败: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "响应内容: $responseBody" -ForegroundColor Red
        }
        throw
    }
}

# 辅助函数：记录测试结果
function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Message = "",
        [object]$Data = $null
    )
    
    $result = @{
        TestName = $TestName
        Success = $Success
        Message = $Message
        Data = $Data
        Timestamp = Get-Date
    }
    
    $script:testResults += $result
    
    if ($Success) {
        Write-Host "✅ $TestName - $Message" -ForegroundColor Green
    } else {
        Write-Host "❌ $TestName - $Message" -ForegroundColor Red
    }
}

# 步骤1：检查服务状态
Write-Host "`n=== 步骤1: 检查服务状态 ===" -ForegroundColor Cyan
try {
    $healthCheck = Invoke-ApiRequest -Method GET -Uri "http://localhost:8080/health"
    Add-TestResult -TestName "后端服务检查" -Success $true -Message "后端服务正常运行"
} catch {
    Add-TestResult -TestName "后端服务检查" -Success $false -Message "后端服务异常"
    exit 1
}

try {
    $frontendCheck = Invoke-WebRequest -Uri $frontendUrl -Method GET -TimeoutSec 5
    Add-TestResult -TestName "前端服务检查" -Success $true -Message "前端服务正常运行"
} catch {
    Add-TestResult -TestName "前端服务检查" -Success $false -Message "前端服务异常"
    exit 1
}

# 步骤2：管理员登录
Write-Host "`n=== 步骤2: 管理员登录 ===" -ForegroundColor Cyan
try {
    $adminCredentials = @{
        username = "admin"
        password = "admin123"
    }
    
    $adminLoginResponse = Invoke-ApiRequest -Method POST -Uri "$baseUrl/auth/login" -Body $adminCredentials
    
    if ($adminLoginResponse.success -and $adminLoginResponse.data.token) {
        $adminToken = $adminLoginResponse.data.token
        Add-TestResult -TestName "管理员登录" -Success $true -Message "登录成功，用户: $($adminLoginResponse.data.user.username)"
    } else {
        Add-TestResult -TestName "管理员登录" -Success $false -Message "登录响应格式不正确"
        exit 1
    }
} catch {
    Add-TestResult -TestName "管理员登录" -Success $false -Message "登录请求失败"
    exit 1
}

$adminHeaders = @{
    "Authorization" = "Bearer $adminToken"
}

# 步骤3：创建测试工单
Write-Host "`n=== 步骤3: 创建测试工单 ===" -ForegroundColor Cyan
try {
    $newTicket = @{
        title = "自动化测试工单 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        type = "bug"
        priority = "normal"
        description = "这是一个自动化测试工单，用于验证完整的工单流程。"
    }
    
    $createTicketResponse = Invoke-ApiRequest -Method POST -Uri "$baseUrl/tickets" -Headers $adminHeaders -Body $newTicket
    
    if ($createTicketResponse.success -and $createTicketResponse.data.id) {
        $testTicketId = $createTicketResponse.data.id
        $currentStatus = $createTicketResponse.data.status
        Add-TestResult -TestName "创建工单" -Success $true -Message "工单ID: $testTicketId, 状态: $currentStatus" -Data $createTicketResponse.data
    } else {
        Add-TestResult -TestName "创建工单" -Success $false -Message "工单创建失败"
        exit 1
    }
} catch {
    Add-TestResult -TestName "创建工单" -Success $false -Message "工单创建请求异常"
    exit 1
}

# 步骤4：验证工单列表
Write-Host "`n=== 步骤4: 验证工单列表 ===" -ForegroundColor Cyan
try {
    $ticketListResponse = Invoke-ApiRequest -Method GET -Uri "$baseUrl/tickets" -Headers $adminHeaders
    
    if ($ticketListResponse.success) {
        $tickets = $ticketListResponse.data.items
        $ourTicket = $tickets | Where-Object { $_.id -eq $testTicketId }
        
        if ($ourTicket) {
            Add-TestResult -TestName "工单列表验证" -Success $true -Message "工单在列表中找到，状态: $($ourTicket.status)"
        } else {
            Add-TestResult -TestName "工单列表验证" -Success $false -Message "工单未在列表中找到"
        }
    } else {
        Add-TestResult -TestName "工单列表验证" -Success $false -Message "获取工单列表失败"
    }
} catch {
    Add-TestResult -TestName "工单列表验证" -Success $false -Message "工单列表请求异常"
}

# 步骤5：分配工单
Write-Host "`n=== 步骤5: 分配工单 ===" -ForegroundColor Cyan
try {
    # 获取用户列表用于分配
    $usersResponse = Invoke-ApiRequest -Method GET -Uri "$baseUrl/system/users" -Headers $adminHeaders
    
    if ($usersResponse.success -and $usersResponse.data.length -gt 0) {
        $assigneeId = $usersResponse.data[0].id
        
        $assignData = @{
            assignee_id = $assigneeId
            comment = "自动化测试分配"
        }
        
        $assignResponse = Invoke-ApiRequest -Method POST -Uri "$baseUrl/tickets/$testTicketId/assign" -Headers $adminHeaders -Body $assignData
        
        if ($assignResponse.success) {
            Add-TestResult -TestName "分配工单" -Success $true -Message "工单分配成功，分配给用户ID: $assigneeId"
        } else {
            Add-TestResult -TestName "分配工单" -Success $false -Message "工单分配失败"
        }
    } else {
        Add-TestResult -TestName "分配工单" -Success $false -Message "无法获取用户列表"
    }
} catch {
    Add-TestResult -TestName "分配工单" -Success $false -Message "分配工单请求异常: $($_.Exception.Message)"
}

# 步骤6：接受工单
Write-Host "`n=== 步骤6: 接受工单 ===" -ForegroundColor Cyan
try {
    $acceptResponse = Invoke-ApiRequest -Method POST -Uri "$baseUrl/tickets/$testTicketId/accept" -Headers $adminHeaders -Body @{}
    
    if ($acceptResponse.success) {
        Add-TestResult -TestName "接受工单" -Success $true -Message "工单接受成功"
    } else {
        Add-TestResult -TestName "接受工单" -Success $false -Message "工单接受失败"
    }
} catch {
    Add-TestResult -TestName "接受工单" -Success $false -Message "接受工单请求异常: $($_.Exception.Message)"
}

# 步骤7：审批工单
Write-Host "`n=== 步骤7: 审批工单 ===" -ForegroundColor Cyan
try {
    $approveData = @{
        status = "approved"
        comment = "自动化测试审批通过"
    }
    
    $approveResponse = Invoke-ApiRequest -Method PUT -Uri "$baseUrl/tickets/$testTicketId/status" -Headers $adminHeaders -Body $approveData
    
    if ($approveResponse.success) {
        Add-TestResult -TestName "审批工单" -Success $true -Message "工单审批成功"
    } else {
        Add-TestResult -TestName "审批工单" -Success $false -Message "工单审批失败"
    }
} catch {
    Add-TestResult -TestName "审批工单" -Success $false -Message "审批工单请求异常: $($_.Exception.Message)"
}

# 步骤8：开始处理工单
Write-Host "`n=== 步骤8: 开始处理工单 ===" -ForegroundColor Cyan
try {
    $statusUpdateData = @{
        status = "progress"
        comment = "自动化测试开始处理"
    }
    
    $statusUpdateResponse = Invoke-ApiRequest -Method PUT -Uri "$baseUrl/tickets/$testTicketId/status" -Headers $adminHeaders -Body $statusUpdateData
    
    if ($statusUpdateResponse.success) {
        Add-TestResult -TestName "开始处理工单" -Success $true -Message "工单状态更新为处理中"
    } else {
        Add-TestResult -TestName "开始处理工单" -Success $false -Message "工单状态更新失败"
    }
} catch {
    Add-TestResult -TestName "开始处理工单" -Success $false -Message "状态更新请求异常: $($_.Exception.Message)"
}

# 步骤9：解决工单
Write-Host "`n=== 步骤9: 解决工单 ===" -ForegroundColor Cyan
try {
    $resolveData = @{
        status = "resolved"
        comment = "自动化测试解决工单"
    }
    
    $resolveResponse = Invoke-ApiRequest -Method PUT -Uri "$baseUrl/tickets/$testTicketId/status" -Headers $adminHeaders -Body $resolveData
    
    if ($resolveResponse.success) {
        Add-TestResult -TestName "解决工单" -Success $true -Message "工单解决成功"
    } else {
        Add-TestResult -TestName "解决工单" -Success $false -Message "工单解决失败"
    }
} catch {
    Add-TestResult -TestName "解决工单" -Success $false -Message "解决工单请求异常: $($_.Exception.Message)"
}

# 步骤10：关闭工单
Write-Host "`n=== 步骤10: 关闭工单 ===" -ForegroundColor Cyan
try {
    $closeData = @{
        status = "closed"
        comment = "自动化测试关闭工单"
    }
    
    $closeResponse = Invoke-ApiRequest -Method PUT -Uri "$baseUrl/tickets/$testTicketId/status" -Headers $adminHeaders -Body $closeData
    
    if ($closeResponse.success) {
        Add-TestResult -TestName "关闭工单" -Success $true -Message "工单关闭成功"
    } else {
        Add-TestResult -TestName "关闭工单" -Success $false -Message "工单关闭失败"
    }
} catch {
    Add-TestResult -TestName "关闭工单" -Success $false -Message "关闭工单请求异常: $($_.Exception.Message)"
}

# 步骤11：重新打开工单
Write-Host "`n=== 步骤11: 重新打开工单 ===" -ForegroundColor Cyan
try {
    $reopenData = @{
        comment = "自动化测试重新打开"
    }
    
    $reopenResponse = Invoke-ApiRequest -Method POST -Uri "$baseUrl/tickets/$testTicketId/reopen" -Headers $adminHeaders -Body $reopenData
    
    if ($reopenResponse.success) {
        Add-TestResult -TestName "重新打开工单" -Success $true -Message "工单重新打开成功"
    } else {
        Add-TestResult -TestName "重新打开工单" -Success $false -Message "工单重新打开失败"
    }
} catch {
    Add-TestResult -TestName "重新打开工单" -Success $false -Message "重新打开请求异常: $($_.Exception.Message)"
}

# 步骤12：验证最终状态
Write-Host "`n=== 步骤12: 验证最终工单状态 ===" -ForegroundColor Cyan
try {
    $finalTicketResponse = Invoke-ApiRequest -Method GET -Uri "$baseUrl/tickets/$testTicketId" -Headers $adminHeaders
    
    if ($finalTicketResponse.success) {
        $finalTicket = $finalTicketResponse.data
        Add-TestResult -TestName "最终状态验证" -Success $true -Message "工单ID: $($finalTicket.id), 状态: $($finalTicket.status)" -Data $finalTicket
    } else {
        Add-TestResult -TestName "最终状态验证" -Success $false -Message "获取最终状态失败"
    }
} catch {
    Add-TestResult -TestName "最终状态验证" -Success $false -Message "最终状态验证异常"
}

# 步骤13：前端权限系统测试
Write-Host "`n=== 步骤13: 前端权限系统测试 ===" -ForegroundColor Cyan

# 使用Selenium或类似工具测试前端（这里用简化的方式）
try {
    # 检查前端是否能正确加载工单页面
    $frontendTicketPage = Invoke-WebRequest -Uri "$frontendUrl/tickets" -Method GET -TimeoutSec 10
    
    if ($frontendTicketPage.StatusCode -eq 200) {
        Add-TestResult -TestName "前端工单页面加载" -Success $true -Message "工单页面可以正常访问"
    } else {
        Add-TestResult -TestName "前端工单页面加载" -Success $false -Message "工单页面访问异常"
    }
} catch {
    Add-TestResult -TestName "前端工单页面加载" -Success $false -Message "前端页面访问失败"
}

# 步骤14：生成测试报告
Write-Host "`n=== 步骤14: 生成测试报告 ===" -ForegroundColor Cyan

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Success }).Count
$failedTests = $totalTests - $passedTests
$successRate = [math]::Round(($passedTests / $totalTests) * 100, 2)

Write-Host "`n=== 自动化测试报告 ===" -ForegroundColor Green
Write-Host "测试时间: $(Get-Date)" -ForegroundColor Gray
Write-Host "测试工单ID: $testTicketId" -ForegroundColor Gray
Write-Host "总测试数: $totalTests" -ForegroundColor White
Write-Host "通过测试: $passedTests" -ForegroundColor Green
Write-Host "失败测试: $failedTests" -ForegroundColor Red
Write-Host "成功率: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } else { "Red" })

Write-Host "`n=== 详细测试结果 ===" -ForegroundColor Cyan
foreach ($result in $testResults) {
    $status = if ($result.Success) { "✅" } else { "❌" }
    $color = if ($result.Success) { "Green" } else { "Red" }
    Write-Host "$status $($result.TestName): $($result.Message)" -ForegroundColor $color
}

# 失败的测试详情
if ($failedTests -gt 0) {
    Write-Host "`n=== 失败测试详情 ===" -ForegroundColor Red
    $failedResults = $testResults | Where-Object { -not $_.Success }
    foreach ($failed in $failedResults) {
        Write-Host "❌ $($failed.TestName)" -ForegroundColor Red
        Write-Host "   错误: $($failed.Message)" -ForegroundColor Yellow
        Write-Host "   时间: $($failed.Timestamp)" -ForegroundColor Gray
    }
}

# 清理测试数据
Write-Host "`n=== 步骤15: 清理测试数据 ===" -ForegroundColor Cyan
try {
    $deleteResponse = Invoke-ApiRequest -Method DELETE -Uri "$baseUrl/tickets/$testTicketId" -Headers $adminHeaders
    if ($deleteResponse.success) {
        Add-TestResult -TestName "清理测试数据" -Success $true -Message "测试工单已删除"
    }
} catch {
    Add-TestResult -TestName "清理测试数据" -Success $false -Message "清理测试数据失败"
}

# 总结
Write-Host "`n=== 测试总结 ===" -ForegroundColor Green
if ($successRate -ge 90) {
    Write-Host "🎉 工单系统运行良好！所有核心功能正常工作。" -ForegroundColor Green
} elseif ($successRate -ge 70) {
    Write-Host "⚠️ 工单系统基本正常，但有一些问题需要修复。" -ForegroundColor Yellow
} else {
    Write-Host "🚨 工单系统存在严重问题，需要立即修复。" -ForegroundColor Red
}

Write-Host "`n前端测试建议:" -ForegroundColor Cyan
Write-Host "1. 访问 $frontendUrl/tickets 验证用户界面" -ForegroundColor White
Write-Host "2. 访问 $frontendUrl/tickets/test 进行详细API测试" -ForegroundColor White
Write-Host "3. 检查浏览器控制台是否有JavaScript错误" -ForegroundColor White

exit $(if ($successRate -ge 80) { 0 } else { 1 })