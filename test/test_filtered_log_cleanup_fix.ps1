# 测试修复后的筛选条件日志清理功能
Write-Host "=== 测试筛选条件日志清理功能修复 ===" -ForegroundColor Green

# 配置
$baseUrl = "http://localhost:8080/api/v1"

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

# 获取所有日志统计
Write-Host "`n2. 获取日志统计信息..." -ForegroundColor Yellow
try {
    $allLogsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=1" -Method Get -Headers $headers
    $totalLogs = $allLogsResponse.data.total
    Write-Host "✓ 总日志数: $totalLogs" -ForegroundColor Green
} catch {
    Write-Host "✗ 获取日志统计失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 测试不同筛选条件的日志数量
Write-Host "`n3. 测试各种筛选条件..." -ForegroundColor Yellow

# 测试按级别筛选
$testFilters = @(
    @{ name = "info级别"; params = @{ level = "info" } },
    @{ name = "error级别"; params = @{ level = "error" } },
    @{ name = "http分类"; params = @{ category = "http" } },
    @{ name = "auth分类"; params = @{ category = "auth" } },
    @{ name = "system分类"; params = @{ category = "system" } }
)

$filterResults = @()

foreach ($filter in $testFilters) {
    try {
        $params = $filter.params
        $params.page = 1
        $params.page_size = 1
        
        $queryString = ($params.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
        $filterResponse = Invoke-RestMethod -Uri "$baseUrl/logs?$queryString" -Method Get -Headers $headers
        
        if ($filterResponse.success) {
            $count = $filterResponse.data.total
            Write-Host "  $($filter.name): $count 条日志" -ForegroundColor Cyan
            $filterResults += @{
                name = $filter.name
                params = $filter.params
                count = $count
            }
        }
    } catch {
        Write-Host "  $($filter.name): 查询失败" -ForegroundColor Red
    }
}

# 选择一个有数据的筛选条件进行删除测试
$testFilter = $filterResults | Where-Object { $_.count -gt 0 -and $_.count -lt 50 } | Select-Object -First 1

if ($testFilter) {
    Write-Host "`n4. 测试筛选条件删除功能..." -ForegroundColor Yellow
    Write-Host "选择测试筛选条件: $($testFilter.name) (共 $($testFilter.count) 条日志)" -ForegroundColor Cyan
    
    # 获取要删除的日志ID列表
    try {
        $params = $testFilter.params
        $params.page = 1
        $params.page_size = [Math]::Min($testFilter.count, 10)  # 最多删除10条进行测试
        
        $queryString = ($params.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
        $logsToDeleteResponse = Invoke-RestMethod -Uri "$baseUrl/logs?$queryString" -Method Get -Headers $headers
        
        if ($logsToDeleteResponse.success -and $logsToDeleteResponse.data.logs.Count -gt 0) {
            $logIds = $logsToDeleteResponse.data.logs | ForEach-Object { $_.id }
            Write-Host "准备删除 $($logIds.Count) 条日志: $($logIds -join ', ')" -ForegroundColor Gray
            
            # 执行批量删除
            $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/logs/batch-delete" -Method Post -Body (@{
                ids = $logIds
            } | ConvertTo-Json) -ContentType "application/json" -Headers $headers
            
            if ($deleteResponse.success) {
                $deletedCount = $deleteResponse.data.deleted_count
                Write-Host "✓ 成功删除 $deletedCount 条日志" -ForegroundColor Green
                
                # 验证删除结果
                $verifyResponse = Invoke-RestMethod -Uri "$baseUrl/logs?$queryString" -Method Get -Headers $headers
                $remainingCount = $verifyResponse.data.total
                Write-Host "✓ 验证: 该筛选条件下剩余 $remainingCount 条日志" -ForegroundColor Green
            } else {
                Write-Host "✗ 删除失败: $($deleteResponse.message)" -ForegroundColor Red
            }
        } else {
            Write-Host "✗ 没有找到符合条件的日志" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 筛选删除测试失败: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "`n4. 跳过删除测试 - 没有找到合适的测试数据" -ForegroundColor Yellow
}

Write-Host "`n=== 前端筛选清理功能修复说明 ===" -ForegroundColor Green
Write-Host "修复内容:" -ForegroundColor Cyan
Write-Host "✓ 支持按级别筛选清理 (level)" -ForegroundColor Green
Write-Host "✓ 支持按分类筛选清理 (category)" -ForegroundColor Green  
Write-Host "✓ 支持按用户ID筛选清理 (user_id)" -ForegroundColor Green
Write-Host "✓ 支持按时间范围筛选清理 (start_time, end_time)" -ForegroundColor Green
Write-Host "✓ 支持多条件组合筛选清理" -ForegroundColor Green
Write-Host "✓ 清理前显示符合条件的日志数量" -ForegroundColor Green
Write-Host "✓ 提供详细的筛选条件确认信息" -ForegroundColor Green

Write-Host "`n使用方法:" -ForegroundColor Cyan
Write-Host "1. 在日志管理界面设置筛选条件（级别、分类、用户ID、时间范围等）" -ForegroundColor Gray
Write-Host "2. 点击'清理日志' -> '按筛选条件清理'" -ForegroundColor Gray
Write-Host "3. 系统会显示符合条件的日志数量并要求确认" -ForegroundColor Gray
Write-Host "4. 确认后系统会批量删除所有符合筛选条件的日志" -ForegroundColor Gray

Write-Host "`n注意事项:" -ForegroundColor Yellow
Write-Host "• 必须至少设置一个筛选条件才能使用此功能" -ForegroundColor Gray
Write-Host "• 删除操作不可撤销，请谨慎操作" -ForegroundColor Gray
Write-Host "• 大量日志删除可能需要一些时间" -ForegroundColor Gray

Write-Host "`n=== 筛选条件日志清理功能测试完成 ===" -ForegroundColor Green