# 工单流程修复验证脚本

param(
    [string]$BaseUrl = "http://localhost:8080",
    [string]$Token = ""
)

Write-Host "开始验证工单流程修复..." -ForegroundColor Green

# 如果没有提供Token，尝试从环境变量获取
if (-not $Token) {
    $Token = $env:TEST_TOKEN
}

if (-not $Token) {
    Write-Host "请提供认证Token或设置环境变量 TEST_TOKEN" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type" = "application/json"
}

# 测试函数
function Test-ApiCall {
    param(
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers,
        [string]$Body = $null,
        [string]$Description
    )
    
    Write-Host "测试: $Description" -ForegroundColor Yellow
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            Headers = $Headers
            TimeoutSec = 30
        }
        
        if ($Body) {
            $params.Body = $Body
        }
        
        $response = Invoke-RestMethod @params
        Write-Host "   ✓ 成功: $($response.success)" -ForegroundColor Green
        return $response
    } catch {
        Write-Host "   ✗ 失败: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $errorResponse = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $errorContent = $reader.ReadToEnd()
            Write-Host "   错误详情: $errorContent" -ForegroundColor Red
        }
        return $null
    }
}

# 1. 测试服务健康状态
Write-Host "`n1. 检查服务状态..." -ForegroundColor Cyan
$healthResponse = Test-ApiCall -Method "GET" -Url "$BaseUrl/api/v1/health" -Headers @{} -Description "服务健康检查"

if (-not $healthResponse) {
    Write-Host "服务不可用，请检查服务是否正常启动" -ForegroundColor Red
    exit 1
}

# 2. 创建测试工单
Write-Host "`n2. 创建测试工单..." -ForegroundColor Cyan
$createTicketBody = @{
    title = "工单流程测试 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    description = "这是一个用于测试工单流程修复的测试工单"
    type = "bug"
    priority = "normal"
} | ConvertTo-Json

$createResponse = Test-ApiCall -Method "POST" -Url "$BaseUrl/api/v1/tickets" -Headers $headers -Body $createTicketBody -Description "创建测试工单"

if (-not $createResponse -or -not $createResponse.success) {
    Write-Host "创建工单失败，无法继续测试" -ForegroundColor Red
    exit 1
}

$ticketId = $createResponse.data.id
Write-Host "   创建的工单ID: $ticketId" -ForegroundColor Green
Write-Host "   当前状态: $($createResponse.data.status)" -ForegroundColor Green

# 3. 测试工单分配
Write-Host "`n3. 测试工单分配..." -ForegroundColor Cyan
$assignBody = @{
    assignee_id = 1  # 假设用户ID 1存在
    comment = "自动化测试分配"
    auto_accept = $false
} | ConvertTo-Json

$assignResponse = Test-ApiCall -Method "POST" -Url "$BaseUrl/api/v1/tickets/$ticketId/assign" -Headers $headers -Body $assignBody -Description "分配工单"

if ($assignResponse -and $assignResponse.success) {
    Write-Host "   工单状态: $($assignResponse.data.status)" -ForegroundColor Green
}

# 4. 测试接受工单
Write-Host "`n4. 测试接受工单..." -ForegroundColor Cyan
$acceptBody = @{
    comment = "自动化测试接受"
} | ConvertTo-Json

$acceptResponse = Test-ApiCall -Method "POST" -Url "$BaseUrl/api/v1/tickets/$ticketId/accept" -Headers $headers -Body $acceptBody -Description "接受工单"

if ($acceptResponse -and $acceptResponse.success) {
    Write-Host "   工单状态: $($acceptResponse.data.status)" -ForegroundColor Green
}

# 5. 测试审批工单
Write-Host "`n5. 测试审批工单..." -ForegroundColor Cyan
$approveBody = @{
    status = "approved"
    comment = "自动化测试审批通过"
} | ConvertTo-Json

$approveResponse = Test-ApiCall -Method "PUT" -Url "$BaseUrl/api/v1/tickets/$ticketId/status" -Headers $headers -Body $approveBody -Description "审批工单"

if ($approveResponse -and $approveResponse.success) {
    Write-Host "   工单状态: $($approveResponse.data.status)" -ForegroundColor Green
}

# 6. 测试开始处理（这是之前失败的操作）
Write-Host "`n6. 测试开始处理工单..." -ForegroundColor Cyan
$progressBody = @{
    status = "progress"
    comment = "自动化测试开始处理"
} | ConvertTo-Json

$progressResponse = Test-ApiCall -Method "PUT" -Url "$BaseUrl/api/v1/tickets/$ticketId/status" -Headers $headers -Body $progressBody -Description "开始处理工单"

if ($progressResponse -and $progressResponse.success) {
    Write-Host "   ✓ 关键修复验证成功！工单状态: $($progressResponse.data.status)" -ForegroundColor Green
} else {
    Write-Host "   ✗ 关键修复验证失败！这是之前的主要问题" -ForegroundColor Red
}

# 7. 测试解决工单
Write-Host "`n7. 测试解决工单..." -ForegroundColor Cyan
$resolveBody = @{
    status = "resolved"
    comment = "自动化测试解决工单"
} | ConvertTo-Json

$resolveResponse = Test-ApiCall -Method "PUT" -Url "$BaseUrl/api/v1/tickets/$ticketId/status" -Headers $headers -Body $resolveBody -Description "解决工单"

if ($resolveResponse -and $resolveResponse.success) {
    Write-Host "   工单状态: $($resolveResponse.data.status)" -ForegroundColor Green
}

# 8. 测试关闭工单
Write-Host "`n8. 测试关闭工单..." -ForegroundColor Cyan
$closeBody = @{
    status = "closed"
    comment = "自动化测试关闭工单"
} | ConvertTo-Json

$closeResponse = Test-ApiCall -Method "PUT" -Url "$BaseUrl/api/v1/tickets/$ticketId/status" -Headers $headers -Body $closeBody -Description "关闭工单"

if ($closeResponse -and $closeResponse.success) {
    Write-Host "   工单状态: $($closeResponse.data.status)" -ForegroundColor Green
}

# 9. 测试重新打开工单
Write-Host "`n9. 测试重新打开工单..." -ForegroundColor Cyan
$reopenBody = @{
    comment = "自动化测试重新打开"
} | ConvertTo-Json

$reopenResponse = Test-ApiCall -Method "POST" -Url "$BaseUrl/api/v1/tickets/$ticketId/reopen" -Headers $headers -Body $reopenBody -Description "重新打开工单"

if ($reopenResponse -and $reopenResponse.success) {
    Write-Host "   工单状态: $($reopenResponse.data.status)" -ForegroundColor Green
}

# 10. 获取工单历史
Write-Host "`n10. 获取工单历史..." -ForegroundColor Cyan
$historyResponse = Test-ApiCall -Method "GET" -Url "$BaseUrl/api/v1/tickets/$ticketId/history" -Headers $headers -Description "获取工单历史"

if ($historyResponse -and $historyResponse.success) {
    Write-Host "   历史记录数量: $($historyResponse.data.Count)" -ForegroundColor Green
    foreach ($history in $historyResponse.data) {
        Write-Host "   - $($history.action): $($history.description)" -ForegroundColor Gray
    }
}

# 11. 清理测试数据
Write-Host "`n11. 清理测试数据..." -ForegroundColor Cyan
$deleteResponse = Test-ApiCall -Method "DELETE" -Url "$BaseUrl/api/v1/tickets/$ticketId" -Headers $headers -Description "删除测试工单"

if ($deleteResponse -and $deleteResponse.success) {
    Write-Host "   ✓ 测试工单已清理" -ForegroundColor Green
}

# 总结
Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "测试总结" -ForegroundColor Green
Write-Host "="*50 -ForegroundColor Cyan

$testResults = @(
    @{ Name = "服务健康检查"; Success = $healthResponse -ne $null }
    @{ Name = "创建工单"; Success = $createResponse -and $createResponse.success }
    @{ Name = "分配工单"; Success = $assignResponse -and $assignResponse.success }
    @{ Name = "接受工单"; Success = $acceptResponse -and $acceptResponse.success }
    @{ Name = "审批工单"; Success = $approveResponse -and $approveResponse.success }
    @{ Name = "开始处理"; Success = $progressResponse -and $progressResponse.success }
    @{ Name = "解决工单"; Success = $resolveResponse -and $resolveResponse.success }
    @{ Name = "关闭工单"; Success = $closeResponse -and $closeResponse.success }
    @{ Name = "重新打开"; Success = $reopenResponse -and $reopenResponse.success }
    @{ Name = "获取历史"; Success = $historyResponse -and $historyResponse.success }
    @{ Name = "清理数据"; Success = $deleteResponse -and $deleteResponse.success }
)

$successCount = ($testResults | Where-Object { $_.Success }).Count
$totalCount = $testResults.Count

foreach ($result in $testResults) {
    $status = if ($result.Success) { "✓" } else { "✗" }
    $color = if ($result.Success) { "Green" } else { "Red" }
    Write-Host "$status $($result.Name)" -ForegroundColor $color
}

Write-Host "`n测试结果: $successCount/$totalCount 通过" -ForegroundColor $(if ($successCount -eq $totalCount) { "Green" } else { "Yellow" })

if ($successCount -eq $totalCount) {
    Write-Host "🎉 所有测试通过！工单流程修复成功！" -ForegroundColor Green
} else {
    Write-Host "⚠️  部分测试失败，请检查日志和配置" -ForegroundColor Yellow
}

Write-Host "`n建议下一步操作:" -ForegroundColor Cyan
Write-Host "1. 在浏览器中访问 http://localhost:8080/test/ticket-workflow 进行手动测试" -ForegroundColor White
Write-Host "2. 检查现有工单是否能正常进行状态转换" -ForegroundColor White
Write-Host "3. 验证不同用户角色的权限控制" -ForegroundColor White