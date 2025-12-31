# 工单管理系统测试脚本
# 测试工单的创建、查询、更新、分配等功能

$baseUrl = "http://localhost:8080/api/v1"
$headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== 工单管理系统测试 ===" -ForegroundColor Green

# 1. 登录获取Token
Write-Host "1. 用户登录..." -ForegroundColor Yellow
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -Headers $headers
    $token = $loginResponse.token
    $headers["Authorization"] = "Bearer $token"
    Write-Host "✓ 登录成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. 创建测试工单
Write-Host "2. 创建测试工单..." -ForegroundColor Yellow
$ticketData = @{
    title = "测试工单 - 系统功能验证"
    description = "这是一个测试工单，用于验证工单管理系统的基本功能。包括创建、查询、更新、分配等操作。"
    type = "bug"
    priority = "normal"
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/tickets" -Method POST -Body $ticketData -Headers $headers
    $ticketId = $createResponse.id
    Write-Host "✓ 工单创建成功，ID: $ticketId" -ForegroundColor Green
    Write-Host "  标题: $($createResponse.title)" -ForegroundColor Cyan
    Write-Host "  状态: $($createResponse.status)" -ForegroundColor Cyan
    Write-Host "  优先级: $($createResponse.priority)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 创建工单失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. 查询工单列表
Write-Host "3. 查询工单列表..." -ForegroundColor Yellow
try {
    $listResponse = Invoke-RestMethod -Uri "$baseUrl/tickets?page=1&size=10" -Method GET -Headers $headers
    Write-Host "✓ 工单列表查询成功" -ForegroundColor Green
    Write-Host "  总数: $($listResponse.total)" -ForegroundColor Cyan
    Write-Host "  当前页: $($listResponse.page)" -ForegroundColor Cyan
    
    if ($listResponse.stats) {
        Write-Host "  统计信息:" -ForegroundColor Cyan
        Write-Host "    总工单: $($listResponse.stats.total)" -ForegroundColor Cyan
        Write-Host "    待处理: $($listResponse.stats.open)" -ForegroundColor Cyan
        Write-Host "    处理中: $($listResponse.stats.progress)" -ForegroundColor Cyan
        Write-Host "    已解决: $($listResponse.stats.resolved)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "✗ 查询工单列表失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. 查询工单详情
Write-Host "4. 查询工单详情..." -ForegroundColor Yellow
try {
    $detailResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$ticketId" -Method GET -Headers $headers
    Write-Host "✓ 工单详情查询成功" -ForegroundColor Green
    Write-Host "  ID: $($detailResponse.id)" -ForegroundColor Cyan
    Write-Host "  标题: $($detailResponse.title)" -ForegroundColor Cyan
    Write-Host "  状态: $($detailResponse.status)" -ForegroundColor Cyan
    Write-Host "  创建时间: $($detailResponse.created_at)" -ForegroundColor Cyan
    if ($detailResponse.creator) {
        Write-Host "  创建人: $($detailResponse.creator.username)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "✗ 查询工单详情失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. 更新工单状态
Write-Host "5. 更新工单状态..." -ForegroundColor Yellow
$statusData = @{
    status = "progress"
    comment = "开始处理此工单"
} | ConvertTo-Json

try {
    $statusResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$ticketId/status" -Method PUT -Body $statusData -Headers $headers
    Write-Host "✓ 工单状态更新成功" -ForegroundColor Green
    Write-Host "  新状态: $($statusResponse.status)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 更新工单状态失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. 添加工单评论
Write-Host "6. 添加工单评论..." -ForegroundColor Yellow
$commentData = @{
    content = "这是一条测试评论，用于验证工单评论功能。"
    is_public = $true
} | ConvertTo-Json

try {
    $commentResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$ticketId/comments" -Method POST -Body $commentData -Headers $headers
    Write-Host "✓ 工单评论添加成功" -ForegroundColor Green
    Write-Host "  评论ID: $($commentResponse.id)" -ForegroundColor Cyan
    Write-Host "  内容: $($commentResponse.content)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 添加工单评论失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 7. 查询工单评论
Write-Host "7. 查询工单评论..." -ForegroundColor Yellow
try {
    $commentsResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$ticketId/comments" -Method GET -Headers $headers
    Write-Host "✓ 工单评论查询成功" -ForegroundColor Green
    Write-Host "  评论数量: $($commentsResponse.Count)" -ForegroundColor Cyan
    foreach ($comment in $commentsResponse) {
        Write-Host "    评论 $($comment.id): $($comment.content)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "✗ 查询工单评论失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 8. 查询工单历史
Write-Host "8. 查询工单历史..." -ForegroundColor Yellow
try {
    $historyResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$ticketId/history" -Method GET -Headers $headers
    Write-Host "✓ 工单历史查询成功" -ForegroundColor Green
    Write-Host "  历史记录数量: $($historyResponse.Count)" -ForegroundColor Cyan
    foreach ($history in $historyResponse) {
        Write-Host "    $($history.created_at): $($history.action) - $($history.description)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "✗ 查询工单历史失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 9. 获取工单统计
Write-Host "9. 获取工单统计..." -ForegroundColor Yellow
try {
    $statsResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/statistics" -Method GET -Headers $headers
    Write-Host "✓ 工单统计查询成功" -ForegroundColor Green
    Write-Host "  总工单数: $($statsResponse.total)" -ForegroundColor Cyan
    if ($statsResponse.status) {
        Write-Host "  按状态统计:" -ForegroundColor Cyan
        $statsResponse.status.PSObject.Properties | ForEach-Object {
            Write-Host "    $($_.Name): $($_.Value)" -ForegroundColor Cyan
        }
    }
    if ($statsResponse.type) {
        Write-Host "  按类型统计:" -ForegroundColor Cyan
        $statsResponse.type.PSObject.Properties | ForEach-Object {
            Write-Host "    $($_.Name): $($_.Value)" -ForegroundColor Cyan
        }
    }
} catch {
    Write-Host "✗ 获取工单统计失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 10. 测试企业微信配置（可选）
Write-Host "10. 测试企业微信配置..." -ForegroundColor Yellow
try {
    $wechatConfigResponse = Invoke-RestMethod -Uri "$baseUrl/wechat/config" -Method GET -Headers $headers
    Write-Host "✓ 企业微信配置查询成功" -ForegroundColor Green
    Write-Host "  Webhook URL: $($wechatConfigResponse.webhook_url)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 查询企业微信配置失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  这是正常的，如果没有配置企业微信的话" -ForegroundColor Gray
}

Write-Host "=== 工单管理系统测试完成 ===" -ForegroundColor Green
Write-Host "测试工单ID: $ticketId" -ForegroundColor Yellow
Write-Host "请在前端界面中查看创建的测试工单" -ForegroundColor Yellow