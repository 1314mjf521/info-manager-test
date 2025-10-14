# 测试批量删除死锁修复
# 编码：UTF-8

Write-Host "=== 测试批量删除死锁修复 ===" -ForegroundColor Green

# 设置基础变量
$baseUrl = "http://localhost:8080"
$adminToken = ""

# 函数：获取管理员Token
function Get-AdminToken {
    Write-Host "正在获取管理员Token..." -ForegroundColor Yellow
    
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method Post -Body $loginData -ContentType "application/json"
        if ($response.success) {
            Write-Host "✓ 管理员登录成功" -ForegroundColor Green
            return $response.data.token
        } else {
            Write-Host "✗ 管理员登录失败: $($response.error.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 管理员登录请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 函数：创建测试记录
function Create-TestRecords {
    param($token, $count = 5)
    
    Write-Host "`n--- 创建测试记录 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $recordIds = @()
    
    for ($i = 1; $i -le $count; $i++) {
        $recordData = @{
            type = "test"
            title = "批量删除测试记录 $i"
            content = @{
                description = "这是用于测试批量删除的记录 $i"
                priority = "medium"
            }
            tags = @("测试", "批量删除")
        } | ConvertTo-Json -Depth 10
        
        try {
            $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records" -Method Post -Body $recordData -Headers $headers
            if ($response.success) {
                $recordIds += $response.data.id
                Write-Host "✓ 创建测试记录 $i (ID: $($response.data.id))" -ForegroundColor Green
            } else {
                Write-Host "✗ 创建测试记录 $i 失败: $($response.message)" -ForegroundColor Red
            }
        } catch {
            Write-Host "✗ 创建测试记录 $i 请求失败: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        # 添加短暂延迟
        Start-Sleep -Milliseconds 100
    }
    
    return $recordIds
}

# 函数：测试批量删除
function Test-BatchDelete {
    param($token, $recordIds)
    
    Write-Host "`n--- 测试批量删除 ---" -ForegroundColor Cyan
    
    if (-not $recordIds -or $recordIds.Count -eq 0) {
        Write-Host "✗ 没有可用的记录ID进行测试" -ForegroundColor Red
        return $false
    }
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $deleteData = @{
        record_ids = $recordIds
    } | ConvertTo-Json -Depth 10
    
    Write-Host "正在批量删除 $($recordIds.Count) 条记录..." -ForegroundColor Yellow
    Write-Host "记录ID: $($recordIds -join ', ')" -ForegroundColor Gray
    
    $startTime = Get-Date
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records/batch" -Method Delete -Body $deleteData -Headers $headers -TimeoutSec 30
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($response.success) {
            Write-Host "✓ 批量删除测试成功" -ForegroundColor Green
            Write-Host "  执行时间: $([math]::Round($duration, 2)) ms" -ForegroundColor Gray
            Write-Host "  删除记录数: $($recordIds.Count)" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "✗ 批量删除测试失败: $($response.message)" -ForegroundColor Red
            Write-Host "  执行时间: $([math]::Round($duration, 2)) ms" -ForegroundColor Gray
            return $false
        }
    } catch {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        Write-Host "✗ 批量删除请求失败: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  执行时间: $([math]::Round($duration, 2)) ms" -ForegroundColor Gray
        
        # 检查是否是超时错误
        if ($_.Exception.Message -like "*timeout*" -or $_.Exception.Message -like "*timed out*") {
            Write-Host "! 检测到超时，可能存在死锁问题" -ForegroundColor Yellow
        }
        
        return $false
    }
}

# 函数：测试批量状态更新
function Test-BatchStatusUpdate {
    param($token)
    
    Write-Host "`n--- 测试批量状态更新 ---" -ForegroundColor Cyan
    
    # 先创建一些测试记录
    $recordIds = Create-TestRecords -token $token -count 3
    
    if (-not $recordIds -or $recordIds.Count -eq 0) {
        Write-Host "✗ 没有可用的记录ID进行测试" -ForegroundColor Red
        return $false
    }
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $updateData = @{
        record_ids = $recordIds
        status = "published"
    } | ConvertTo-Json -Depth 10
    
    Write-Host "正在批量更新 $($recordIds.Count) 条记录状态..." -ForegroundColor Yellow
    
    $startTime = Get-Date
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records/batch-status" -Method Put -Body $updateData -Headers $headers -TimeoutSec 30
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($response.success) {
            Write-Host "✓ 批量状态更新测试成功" -ForegroundColor Green
            Write-Host "  执行时间: $([math]::Round($duration, 2)) ms" -ForegroundColor Gray
            
            # 清理测试记录
            Test-BatchDelete -token $token -recordIds $recordIds | Out-Null
            
            return $true
        } else {
            Write-Host "✗ 批量状态更新测试失败: $($response.message)" -ForegroundColor Red
            Write-Host "  执行时间: $([math]::Round($duration, 2)) ms" -ForegroundColor Gray
            return $false
        }
    } catch {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        Write-Host "✗ 批量状态更新请求失败: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  执行时间: $([math]::Round($duration, 2)) ms" -ForegroundColor Gray
        
        # 尝试清理测试记录
        try {
            Test-BatchDelete -token $token -recordIds $recordIds | Out-Null
        } catch {
            Write-Host "! 清理测试记录失败" -ForegroundColor Yellow
        }
        
        return $false
    }
}

# 函数：并发测试
function Test-ConcurrentBatchOperations {
    param($token)
    
    Write-Host "`n--- 并发批量操作测试 ---" -ForegroundColor Cyan
    
    # 创建多组测试记录
    $allRecordIds = @()
    for ($i = 1; $i -le 3; $i++) {
        $recordIds = Create-TestRecords -token $token -count 2
        $allRecordIds += ,@($recordIds)
    }
    
    if ($allRecordIds.Count -eq 0) {
        Write-Host "✗ 无法创建测试记录" -ForegroundColor Red
        return $false
    }
    
    Write-Host "正在执行并发批量删除测试..." -ForegroundColor Yellow
    
    # 并发执行批量删除
    $jobs = @()
    for ($i = 0; $i -lt $allRecordIds.Count; $i++) {
        $recordIds = $allRecordIds[$i]
        if ($recordIds -and $recordIds.Count -gt 0) {
            $job = Start-Job -ScriptBlock {
                param($url, $token, $ids)
                
                $headers = @{
                    "Authorization" = "Bearer $token"
                    "Content-Type" = "application/json"
                }
                
                $deleteData = @{
                    record_ids = $ids
                } | ConvertTo-Json -Depth 10
                
                try {
                    $startTime = Get-Date
                    $response = Invoke-RestMethod -Uri "$url/api/v1/records/batch" -Method Delete -Body $deleteData -Headers $headers -TimeoutSec 30
                    $endTime = Get-Date
                    $duration = ($endTime - $startTime).TotalMilliseconds
                    
                    return @{
                        success = $response.success
                        duration = $duration
                        recordCount = $ids.Count
                        message = if ($response.success) { "成功" } else { $response.message }
                    }
                } catch {
                    $endTime = Get-Date
                    $duration = ($endTime - $startTime).TotalMilliseconds
                    
                    return @{
                        success = $false
                        duration = $duration
                        recordCount = $ids.Count
                        message = $_.Exception.Message
                    }
                }
            } -ArgumentList $baseUrl, $token, $recordIds
            
            $jobs += $job
        }
    }
    
    # 等待所有任务完成
    $results = $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job
    
    # 分析结果
    $successCount = ($results | Where-Object { $_.success }).Count
    $totalCount = $results.Count
    $avgDuration = ($results | Measure-Object -Property duration -Average).Average
    
    Write-Host "并发批量删除测试结果:" -ForegroundColor White
    Write-Host "  成功: $successCount/$totalCount" -ForegroundColor $(if ($successCount -eq $totalCount) { "Green" } else { "Yellow" })
    Write-Host "  平均执行时间: $([math]::Round($avgDuration, 2)) ms" -ForegroundColor Gray
    
    # 显示详细结果
    for ($i = 0; $i -lt $results.Count; $i++) {
        $result = $results[$i]
        $status = if ($result.success) { "✓" } else { "✗" }
        $color = if ($result.success) { "Green" } else { "Red" }
        Write-Host "  任务 $($i+1): $status $($result.recordCount) 条记录, $([math]::Round($result.duration, 2)) ms - $($result.message)" -ForegroundColor $color
    }
    
    return $successCount -eq $totalCount
}

# 主执行流程
try {
    # 获取管理员Token
    $adminToken = Get-AdminToken
    if (-not $adminToken) {
        Write-Host "无法获取管理员Token，测试终止" -ForegroundColor Red
        exit 1
    }
    
    # 创建测试记录
    $testRecordIds = Create-TestRecords -token $adminToken -count 5
    
    if ($testRecordIds -and $testRecordIds.Count -gt 0) {
        # 测试批量删除
        $deleteSuccess = Test-BatchDelete -token $adminToken -recordIds $testRecordIds
        
        if ($deleteSuccess) {
            Write-Host "✓ 批量删除死锁问题已修复" -ForegroundColor Green
        } else {
            Write-Host "✗ 批量删除仍存在问题" -ForegroundColor Red
        }
    }
    
    # 测试批量状态更新
    $updateSuccess = Test-BatchStatusUpdate -token $adminToken
    
    if ($updateSuccess) {
        Write-Host "✓ 批量状态更新正常工作" -ForegroundColor Green
    } else {
        Write-Host "✗ 批量状态更新存在问题" -ForegroundColor Red
    }
    
    # 并发测试
    $concurrentSuccess = Test-ConcurrentBatchOperations -token $adminToken
    
    if ($concurrentSuccess) {
        Write-Host "✓ 并发批量操作测试通过" -ForegroundColor Green
    } else {
        Write-Host "✗ 并发批量操作存在问题" -ForegroundColor Red
    }
    
    Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
    
    if ($deleteSuccess -and $updateSuccess -and $concurrentSuccess) {
        Write-Host "所有测试通过，批量删除死锁问题已修复" -ForegroundColor Green
    } else {
        Write-Host "部分测试失败，请检查相关问题" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "测试过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}