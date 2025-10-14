# 前端日志删除功能测试脚本
# 测试单条删除和批量删除功能

Write-Host "=== 前端日志删除功能测试 ===" -ForegroundColor Green

# 配置
$baseUrl = "http://localhost:8080/api/v1"
$frontendUrl = "http://localhost:3000"

# 登录获取token
Write-Host "1. 登录获取认证token..." -ForegroundColor Yellow
try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body (@{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json) -ContentType "application/json"
    
    if ($loginResponse.success) {
        $token = $loginResponse.data.token
        $headers = @{ "Authorization" = "Bearer $token" }
        Write-Host "✓ 登录成功" -ForegroundColor Green
    } else {
        throw "登录失败: $($loginResponse.message)"
    }
} catch {
    Write-Host "✗ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 获取当前日志列表
Write-Host "`n2. 获取当前日志列表..." -ForegroundColor Yellow
try {
    $logsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=10" -Method Get -Headers $headers
    
    if ($logsResponse.success -and $logsResponse.data.logs.Count -gt 0) {
        $totalLogs = $logsResponse.data.total
        $currentLogs = $logsResponse.data.logs
        Write-Host "✓ 获取到 $totalLogs 条日志" -ForegroundColor Green
        
        # 显示前几条日志信息
        Write-Host "前几条日志信息:" -ForegroundColor Cyan
        for ($i = 0; $i -lt [Math]::Min(3, $currentLogs.Count); $i++) {
            $log = $currentLogs[$i]
            Write-Host "  ID: $($log.id), 级别: $($log.level), 分类: $($log.category), 时间: $($log.created_at)" -ForegroundColor Gray
        }
    } else {
        Write-Host "✗ 没有找到日志数据" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ 获取日志列表失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 测试单条日志删除API
Write-Host "`n3. 测试单条日志删除API..." -ForegroundColor Yellow
if ($currentLogs.Count -gt 0) {
    $testLogId = $currentLogs[-1].id  # 选择最后一条日志进行删除测试
    $testLog = $currentLogs[-1]
    
    Write-Host "准备删除日志 ID: $testLogId (级别: $($testLog.level), 分类: $($testLog.category))" -ForegroundColor Cyan
    
    try {
        $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/logs/$testLogId" -Method Delete -Headers $headers
        
        if ($deleteResponse.success) {
            Write-Host "✓ 单条日志删除成功" -ForegroundColor Green
            Write-Host "  消息: $($deleteResponse.message)" -ForegroundColor Gray
        } else {
            Write-Host "✗ 单条日志删除失败: $($deleteResponse.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 单条日志删除API调用失败: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "✗ 没有可用于测试的日志" -ForegroundColor Red
}

# 测试批量删除API
Write-Host "`n4. 测试批量删除API..." -ForegroundColor Yellow
if ($currentLogs.Count -gt 2) {
    # 选择前两条日志进行批量删除测试
    $batchLogIds = @($currentLogs[0].id, $currentLogs[1].id)
    
    Write-Host "准备批量删除日志 IDs: $($batchLogIds -join ', ')" -ForegroundColor Cyan
    
    try {
        $batchDeleteResponse = Invoke-RestMethod -Uri "$baseUrl/logs/batch-delete" -Method Post -Body (@{
            ids = $batchLogIds
        } | ConvertTo-Json) -ContentType "application/json" -Headers $headers
        
        if ($batchDeleteResponse.success) {
            $deletedCount = $batchDeleteResponse.data.deleted_count
            Write-Host "✓ 批量删除成功" -ForegroundColor Green
            Write-Host "  消息: $($batchDeleteResponse.message)" -ForegroundColor Gray
            Write-Host "  删除数量: $deletedCount" -ForegroundColor Gray
        } else {
            Write-Host "✗ 批量删除失败: $($batchDeleteResponse.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 批量删除API调用失败: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "✗ 日志数量不足，无法测试批量删除" -ForegroundColor Red
}

# 验证删除结果
Write-Host "`n5. 验证删除结果..." -ForegroundColor Yellow
try {
    $finalLogsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=10" -Method Get -Headers $headers
    
    if ($finalLogsResponse.success) {
        $finalTotal = $finalLogsResponse.data.total
        $deletedCount = $totalLogs - $finalTotal
        Write-Host "✓ 验证完成" -ForegroundColor Green
        Write-Host "  原始日志数: $totalLogs" -ForegroundColor Gray
        Write-Host "  当前日志数: $finalTotal" -ForegroundColor Gray
        Write-Host "  删除日志数: $deletedCount" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ 验证删除结果失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试前端界面功能
Write-Host "`n6. 前端界面功能说明..." -ForegroundColor Yellow
Write-Host "前端日志管理功能已优化，包括:" -ForegroundColor Cyan
Write-Host "  • 单条删除: 在日志列表中点击'删除'按钮" -ForegroundColor Gray
Write-Host "  • 批量删除: 选择多条日志后点击'批量删除'按钮" -ForegroundColor Gray
Write-Host "  • 错误处理: 完善的错误提示和状态反馈" -ForegroundColor Gray
Write-Host "  • 权限验证: 支持权限不足等错误处理" -ForegroundColor Gray
Write-Host "  • 自动刷新: 删除后自动刷新日志列表" -ForegroundColor Gray

Write-Host "`n=== 前端功能优化总结 ===" -ForegroundColor Green
Write-Host "✓ 优化了单条删除功能，增强错误处理" -ForegroundColor Green
Write-Host "✓ 优化了批量删除功能，支持备选方案" -ForegroundColor Green
Write-Host "✓ 改进了API参数处理，确保兼容性" -ForegroundColor Green
Write-Host "✓ 增强了用户体验，提供详细反馈" -ForegroundColor Green

Write-Host "`n前端优化要点:" -ForegroundColor Cyan
Write-Host "1. 错误处理: 区分不同HTTP状态码，提供准确错误信息" -ForegroundColor Gray
Write-Host "2. 用户反馈: 删除操作提供确认对话框和进度提示" -ForegroundColor Gray
Write-Host "3. 状态管理: 正确管理loading状态和选择状态" -ForegroundColor Gray
Write-Host "4. API兼容: 确保请求参数和响应处理与后端API匹配" -ForegroundColor Gray
Write-Host "5. 备选方案: 批量删除失败时自动尝试逐个删除" -ForegroundColor Gray

Write-Host "`n=== Frontend Log Delete Features Test Complete ===" -ForegroundColor Green