# 测试记录导入功能优化效果
# 编码：UTF-8

Write-Host "=== 测试记录导入功能优化效果 ===" -ForegroundColor Green

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

# 函数：创建测试记录类型
function Create-TestRecordType {
    param($token)
    
    Write-Host "创建测试记录类型..." -ForegroundColor Yellow
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $recordTypeData = @{
        name = "test_import_type"
        displayName = "测试导入类型"
        description = "用于测试导入功能的记录类型"
        schema = @{
            type = "object"
            properties = @{
                content = @{
                    type = "string"
                    description = "内容"
                }
                category = @{
                    type = "string"
                    description = "分类"
                }
            }
            required = @("content")
        } | ConvertTo-Json -Depth 10
        isActive = $true
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types" -Method Post -Body $recordTypeData -Headers $headers
        if ($response.success) {
            Write-Host "✓ 测试记录类型创建成功" -ForegroundColor Green
            return $true
        } else {
            Write-Host "! 记录类型可能已存在，继续测试" -ForegroundColor Yellow
            return $true
        }
    } catch {
        Write-Host "! 创建记录类型失败，但继续测试: $($_.Exception.Message)" -ForegroundColor Yellow
        return $true
    }
}

# 函数：生成测试数据
function Generate-TestData {
    param($count)
    
    $testData = @()
    for ($i = 1; $i -le $count; $i++) {
        $testData += @{
            title = "测试记录 $i"
            content = "这是第 $i 条测试记录的内容"
            category = "测试分类"
            tags = @("测试", "导入", "批量")
        }
    }
    
    return $testData
}

# 函数：测试单次导入
function Test-SingleImport {
    param($token, $recordCount)
    
    Write-Host "`n--- 测试单次导入 $recordCount 条记录 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $testRecords = Generate-TestData -count $recordCount
    $importData = @{
        type = "test_import_type"
        records = $testRecords
    } | ConvertTo-Json -Depth 10
    
    $startTime = Get-Date
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records/import" -Method Post -Body $importData -Headers $headers -TimeoutSec 60
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($response.success) {
            $successCount = ($response.data | Where-Object { $_.success -ne $false }).Count
            Write-Host "✓ 导入成功: $successCount/$recordCount 条记录" -ForegroundColor Green
            Write-Host "  耗时: $([math]::Round($duration, 2)) ms" -ForegroundColor Gray
            return @{
                success = $true
                count = $successCount
                duration = $duration
                errors = @()
            }
        } else {
            Write-Host "✗ 导入失败: $($response.error.message)" -ForegroundColor Red
            return @{
                success = $false
                count = 0
                duration = $duration
                errors = @($response.error.message)
            }
        }
    } catch {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        $errorMessage = $_.Exception.Message
        
        Write-Host "✗ 导入请求失败: $errorMessage" -ForegroundColor Red
        Write-Host "  耗时: $([math]::Round($duration, 2)) ms" -ForegroundColor Gray
        
        # 检查是否是数据库锁问题
        if ($errorMessage -like "*database is locked*" -or $errorMessage -like "*SQLITE_BUSY*") {
            Write-Host "  ⚠️  检测到数据库锁问题！" -ForegroundColor Red
        }
        
        return @{
            success = $false
            count = 0
            duration = $duration
            errors = @($errorMessage)
        }
    }
}

# 函数：测试并发导入
function Test-ConcurrentImport {
    param($token, $concurrency, $recordsPerRequest)
    
    Write-Host "`n--- 测试并发导入 ($concurrency 个并发请求，每个 $recordsPerRequest 条记录) ---" -ForegroundColor Cyan
    
    $jobs = @()
    $startTime = Get-Date
    
    # 启动并发任务
    for ($i = 1; $i -le $concurrency; $i++) {
        $job = Start-Job -ScriptBlock {
            param($baseUrl, $token, $recordsPerRequest, $jobId)
            
            $headers = @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            }
            
            $testRecords = @()
            for ($j = 1; $j -le $recordsPerRequest; $j++) {
                $testRecords += @{
                    title = "并发测试记录 Job$jobId-$j"
                    content = "这是并发任务 $jobId 的第 $j 条记录"
                    category = "并发测试"
                    tags = @("并发", "测试", "Job$jobId")
                }
            }
            
            $importData = @{
                type = "test_import_type"
                records = $testRecords
            } | ConvertTo-Json -Depth 10
            
            try {
                $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records/import" -Method Post -Body $importData -Headers $headers -TimeoutSec 60
                return @{
                    jobId = $jobId
                    success = $response.success
                    data = $response.data
                    error = $null
                }
            } catch {
                return @{
                    jobId = $jobId
                    success = $false
                    data = $null
                    error = $_.Exception.Message
                }
            }
        } -ArgumentList $baseUrl, $token, $recordsPerRequest, $i
        
        $jobs += $job
    }
    
    # 等待所有任务完成
    Write-Host "等待并发任务完成..." -ForegroundColor Yellow
    $results = $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job
    
    $endTime = Get-Date
    $totalDuration = ($endTime - $startTime).TotalMilliseconds
    
    # 分析结果
    $successJobs = ($results | Where-Object { $_.success }).Count
    $failedJobs = $results.Count - $successJobs
    $lockErrors = ($results | Where-Object { $_.error -like "*database is locked*" -or $_.error -like "*SQLITE_BUSY*" }).Count
    
    Write-Host "并发测试结果:" -ForegroundColor White
    Write-Host "  成功任务: $successJobs/$($results.Count)" -ForegroundColor Green
    Write-Host "  失败任务: $failedJobs" -ForegroundColor Red
    Write-Host "  数据库锁错误: $lockErrors" -ForegroundColor $(if ($lockErrors -gt 0) { "Red" } else { "Green" })
    Write-Host "  总耗时: $([math]::Round($totalDuration, 2)) ms" -ForegroundColor Gray
    
    return @{
        totalJobs = $results.Count
        successJobs = $successJobs
        failedJobs = $failedJobs
        lockErrors = $lockErrors
        duration = $totalDuration
        results = $results
    }
}

# 函数：清理测试数据
function Cleanup-TestData {
    param($token)
    
    Write-Host "`n清理测试数据..." -ForegroundColor Yellow
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    try {
        # 获取测试记录
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records?type=test_import_type&page_size=1000" -Method Get -Headers $headers
        if ($response.success -and $response.data.records.Count -gt 0) {
            Write-Host "找到 $($response.data.records.Count) 条测试记录，正在删除..." -ForegroundColor Gray
            
            # 批量删除
            $recordIds = $response.data.records | ForEach-Object { $_.id }
            $deleteData = @{
                record_ids = $recordIds
            } | ConvertTo-Json -Depth 10
            
            $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/records/batch" -Method Delete -Body $deleteData -Headers $headers
            if ($deleteResponse.success) {
                Write-Host "✓ 测试记录清理完成" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "! 清理测试数据时出错: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 主执行流程
try {
    # 获取管理员Token
    $adminToken = Get-AdminToken
    if (-not $adminToken) {
        Write-Host "无法获取管理员Token，测试终止" -ForegroundColor Red
        exit 1
    }
    
    # 创建测试记录类型
    Create-TestRecordType -token $adminToken
    
    # 测试不同规模的单次导入
    Write-Host "`n=== 单次导入测试 ===" -ForegroundColor Magenta
    $singleImportResults = @()
    
    @(5, 10, 20, 50) | ForEach-Object {
        $result = Test-SingleImport -token $adminToken -recordCount $_
        $singleImportResults += $result
        Start-Sleep -Seconds 1  # 间隔1秒
    }
    
    # 测试并发导入
    Write-Host "`n=== 并发导入测试 ===" -ForegroundColor Magenta
    $concurrentResults = @()
    
    # 测试不同并发级别
    @(
        @{concurrency=2; records=10},
        @{concurrency=3; records=10},
        @{concurrency=5; records=5}
    ) | ForEach-Object {
        $result = Test-ConcurrentImport -token $adminToken -concurrency $_.concurrency -recordsPerRequest $_.records
        $concurrentResults += $result
        Start-Sleep -Seconds 2  # 间隔2秒
    }
    
    # 生成测试报告
    Write-Host "`n=== 测试报告 ===" -ForegroundColor Magenta
    
    Write-Host "`n单次导入测试结果:" -ForegroundColor White
    $singleImportResults | ForEach-Object {
        $status = if ($_.success) { "✓" } else { "✗" }
        Write-Host "  $status $($_.count) 条记录 - $([math]::Round($_.duration, 2)) ms" -ForegroundColor $(if ($_.success) { "Green" } else { "Red" })
        if ($_.errors.Count -gt 0) {
            $_.errors | ForEach-Object { Write-Host "    错误: $_" -ForegroundColor Red }
        }
    }
    
    Write-Host "`n并发导入测试结果:" -ForegroundColor White
    $concurrentResults | ForEach-Object {
        $successRate = [math]::Round(($_.successJobs / $_.totalJobs) * 100, 1)
        Write-Host "  $($_.totalJobs) 个并发任务 - 成功率: $successRate% - 锁错误: $($_.lockErrors)" -ForegroundColor $(if ($_.lockErrors -eq 0) { "Green" } else { "Red" })
    }
    
    # 计算总体优化效果
    $totalLockErrors = ($concurrentResults | Measure-Object -Property lockErrors -Sum).Sum
    $totalFailures = ($singleImportResults | Where-Object { -not $_.success }).Count + ($concurrentResults | Measure-Object -Property failedJobs -Sum).Sum
    
    Write-Host "`n=== 优化效果评估 ===" -ForegroundColor Magenta
    if ($totalLockErrors -eq 0) {
        Write-Host "🎉 优化成功！未检测到数据库锁问题" -ForegroundColor Green
    } else {
        Write-Host "⚠️  仍存在 $totalLockErrors 个数据库锁错误，需要进一步优化" -ForegroundColor Yellow
    }
    
    if ($totalFailures -eq 0) {
        Write-Host "✅ 所有导入操作均成功完成" -ForegroundColor Green
    } else {
        Write-Host "❌ 共有 $totalFailures 个导入操作失败" -ForegroundColor Red
    }
    
    # 清理测试数据
    Cleanup-TestData -token $adminToken
    
    Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
    
} catch {
    Write-Host "测试过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}