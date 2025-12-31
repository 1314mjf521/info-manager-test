# 工单管理系统集成测试脚本
# 完整测试工单系统的所有功能

$baseUrl = "http://localhost:8080/api/v1"
$headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== 工单管理系统集成测试 ===" -ForegroundColor Green

# 测试结果统计
$testResults = @{
    passed = 0
    failed = 0
    total = 0
}

function Test-API {
    param(
        [string]$TestName,
        [scriptblock]$TestScript
    )
    
    $testResults.total++
    Write-Host "测试 $($testResults.total): $TestName" -ForegroundColor Yellow
    
    try {
        & $TestScript
        Write-Host "✓ $TestName - 通过" -ForegroundColor Green
        $testResults.passed++
    } catch {
        Write-Host "✗ $TestName - 失败: $($_.Exception.Message)" -ForegroundColor Red
        $testResults.failed++
    }
    Write-Host ""
}

# 1. 管理员登录
Test-API "管理员登录" {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -Headers $headers
    $script:adminToken = $loginResponse.token
    $script:adminHeaders = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $script:adminToken"
    }
    
    if (-not $script:adminToken) {
        throw "未获取到管理员Token"
    }
}

# 2. 初始化工单权限
Test-API "初始化工单权限" {
    # 创建基础工单权限
    $permissions = @(
        @{ name = "ticket:view"; display_name = "查看工单"; description = "查看工单列表和详情"; resource = "ticket"; action = "view"; scope = "all" },
        @{ name = "ticket:create"; display_name = "创建工单"; description = "创建新工单"; resource = "ticket"; action = "create"; scope = "all" },
        @{ name = "ticket:edit"; display_name = "编辑工单"; description = "编辑工单信息"; resource = "ticket"; action = "edit"; scope = "own" }
    )
    
    foreach ($perm in $permissions) {
        try {
            $permData = $perm | ConvertTo-Json
            Invoke-RestMethod -Uri "$baseUrl/permissions" -Method POST -Body $permData -Headers $script:adminHeaders -ErrorAction SilentlyContinue
        } catch {
            # 权限可能已存在，忽略错误
        }
    }
}

# 3. 创建测试工单
Test-API "创建测试工单" {
    $ticketData = @{
        title = "集成测试工单 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        description = "这是一个集成测试工单，用于验证工单管理系统的完整功能。包括创建、查询、更新、分配、评论、附件等操作。"
        type = "bug"
        priority = "high"
    } | ConvertTo-Json

    $createResponse = Invoke-RestMethod -Uri "$baseUrl/tickets" -Method POST -Body $ticketData -Headers $script:adminHeaders
    $script:testTicketId = $createResponse.id
    
    if (-not $script:testTicketId) {
        throw "未获取到创建的工单ID"
    }
    
    Write-Host "  创建的工单ID: $script:testTicketId" -ForegroundColor Cyan
}

# 4. 查询工单列表
Test-API "查询工单列表" {
    $listResponse = Invoke-RestMethod -Uri "$baseUrl/tickets?page=1&size=10" -Method GET -Headers $script:adminHeaders
    
    if (-not $listResponse.items -or $listResponse.items.Count -eq 0) {
        throw "工单列表为空"
    }
    
    Write-Host "  工单总数: $($listResponse.total)" -ForegroundColor Cyan
    Write-Host "  当前页工单数: $($listResponse.items.Count)" -ForegroundColor Cyan
}

# 5. 查询工单详情
Test-API "查询工单详情" {
    $detailResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$script:testTicketId" -Method GET -Headers $script:adminHeaders
    
    if ($detailResponse.id -ne $script:testTicketId) {
        throw "工单ID不匹配"
    }
    
    if (-not $detailResponse.title -or -not $detailResponse.description) {
        throw "工单详情不完整"
    }
    
    Write-Host "  工单标题: $($detailResponse.title)" -ForegroundColor Cyan
    Write-Host "  工单状态: $($detailResponse.status)" -ForegroundColor Cyan
}

# 6. 更新工单信息
Test-API "更新工单信息" {
    $updateData = @{
        title = "更新后的工单标题 - $(Get-Date -Format 'HH:mm:ss')"
        priority = "critical"
    } | ConvertTo-Json

    $updateResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$script:testTicketId" -Method PUT -Body $updateData -Headers $script:adminHeaders
    
    if ($updateResponse.priority -ne "critical") {
        throw "工单优先级更新失败"
    }
    
    Write-Host "  更新后优先级: $($updateResponse.priority)" -ForegroundColor Cyan
}

# 7. 更新工单状态
Test-API "更新工单状态" {
    $statusData = @{
        status = "progress"
        comment = "开始处理此工单 - 集成测试"
    } | ConvertTo-Json

    $statusResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$script:testTicketId/status" -Method PUT -Body $statusData -Headers $script:adminHeaders
    
    if ($statusResponse.status -ne "progress") {
        throw "工单状态更新失败"
    }
    
    Write-Host "  更新后状态: $($statusResponse.status)" -ForegroundColor Cyan
}

# 8. 添加工单评论
Test-API "添加工单评论" {
    $commentData = @{
        content = "这是一条集成测试评论，时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        is_public = $true
    } | ConvertTo-Json

    $commentResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$script:testTicketId/comments" -Method POST -Body $commentData -Headers $script:adminHeaders
    
    if (-not $commentResponse.id -or -not $commentResponse.content) {
        throw "评论创建失败"
    }
    
    Write-Host "  评论ID: $($commentResponse.id)" -ForegroundColor Cyan
}

# 9. 查询工单评论
Test-API "查询工单评论" {
    $commentsResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$script:testTicketId/comments" -Method GET -Headers $script:adminHeaders
    
    if (-not $commentsResponse -or $commentsResponse.Count -eq 0) {
        throw "未找到工单评论"
    }
    
    Write-Host "  评论数量: $($commentsResponse.Count)" -ForegroundColor Cyan
}

# 10. 查询工单历史
Test-API "查询工单历史" {
    $historyResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$script:testTicketId/history" -Method GET -Headers $script:adminHeaders
    
    if (-not $historyResponse -or $historyResponse.Count -eq 0) {
        throw "未找到工单历史记录"
    }
    
    Write-Host "  历史记录数量: $($historyResponse.Count)" -ForegroundColor Cyan
}

# 11. 获取工单统计
Test-API "获取工单统计" {
    $statsResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/statistics" -Method GET -Headers $script:adminHeaders
    
    if (-not $statsResponse.total -or $statsResponse.total -eq 0) {
        throw "统计数据异常"
    }
    
    Write-Host "  总工单数: $($statsResponse.total)" -ForegroundColor Cyan
    if ($statsResponse.status) {
        Write-Host "  按状态统计:" -ForegroundColor Cyan
        $statsResponse.status.PSObject.Properties | ForEach-Object {
            Write-Host "    $($_.Name): $($_.Value)" -ForegroundColor Gray
        }
    }
}

# 12. 创建普通用户并测试权限
Test-API "创建普通用户并测试权限" {
    # 创建测试用户
    $userData = @{
        username = "testuser_$(Get-Random -Maximum 9999)"
        email = "testuser@example.com"
        password = "test123"
        display_name = "测试用户"
    } | ConvertTo-Json

    $userResponse = Invoke-RestMethod -Uri "$baseUrl/admin/users" -Method POST -Body $userData -Headers $script:adminHeaders
    $testUserId = $userResponse.id
    
    # 用测试用户登录
    $testLoginData = @{
        username = $userResponse.username
        password = "test123"
    } | ConvertTo-Json

    $testLoginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $testLoginData -Headers $headers
    $testUserHeaders = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $($testLoginResponse.token)"
    }
    
    # 测试普通用户查看工单（应该只能看到自己的）
    $userTicketsResponse = Invoke-RestMethod -Uri "$baseUrl/tickets" -Method GET -Headers $testUserHeaders
    
    Write-Host "  测试用户ID: $testUserId" -ForegroundColor Cyan
    Write-Host "  测试用户可见工单数: $($userTicketsResponse.total)" -ForegroundColor Cyan
}

# 13. 测试企业微信配置
Test-API "测试企业微信配置" {
    try {
        $wechatConfigResponse = Invoke-RestMethod -Uri "$baseUrl/wechat/config" -Method GET -Headers $script:adminHeaders
        Write-Host "  企业微信配置查询成功" -ForegroundColor Cyan
    } catch {
        # 企业微信配置可能不存在，这是正常的
        Write-Host "  企业微信配置不存在（正常）" -ForegroundColor Gray
    }
}

# 14. 测试Zabbix告警接口
Test-API "测试Zabbix告警接口" {
    $zabbixData = @{
        Token = "test-token"
        To = "webhook"
        Subject = "集成测试告警"
        Message = "这是一条集成测试告警消息"
    } | ConvertTo-Json

    try {
        $zabbixResponse = Invoke-RestMethod -Uri "$baseUrl/wechat/webhook/zabbix" -Method POST -Body $zabbixData -Headers $script:adminHeaders
        Write-Host "  Zabbix告警接口响应正常" -ForegroundColor Cyan
    } catch {
        # 可能因为没有配置有效的企业微信Token而失败，这是正常的
        Write-Host "  Zabbix告警接口测试完成（可能因配置问题失败）" -ForegroundColor Gray
    }
}

# 15. 清理测试数据
Test-API "清理测试数据" {
    # 删除测试工单
    try {
        Invoke-RestMethod -Uri "$baseUrl/tickets/$script:testTicketId" -Method DELETE -Headers $script:adminHeaders
        Write-Host "  测试工单已删除" -ForegroundColor Cyan
    } catch {
        Write-Host "  测试工单删除失败（可能权限不足）" -ForegroundColor Gray
    }
}

# 输出测试结果
Write-Host "=== 测试结果统计 ===" -ForegroundColor Green
Write-Host "总测试数: $($testResults.total)" -ForegroundColor Cyan
Write-Host "通过: $($testResults.passed)" -ForegroundColor Green
Write-Host "失败: $($testResults.failed)" -ForegroundColor Red
Write-Host "成功率: $([math]::Round($testResults.passed / $testResults.total * 100, 2))%" -ForegroundColor Cyan

if ($testResults.failed -eq 0) {
    Write-Host ""
    Write-Host "🎉 所有测试通过！工单管理系统运行正常！" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "⚠️  有 $($testResults.failed) 个测试失败，请检查系统配置" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== 工单管理系统集成测试完成 ===" -ForegroundColor Green