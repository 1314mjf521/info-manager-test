# 验证数据库锁定修复效果的测试脚本
# PowerShell 脚本，使用UTF-8编码

Write-Host "=== 验证数据库锁定修复效果 ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080"
$token = ""

# 登录获取token
Write-Host ""
Write-Host "1. 登录获取token..." -ForegroundColor Yellow
try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method Post -Body (@{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json) -ContentType "application/json"
    
    $token = $loginResponse.data.token
    Write-Host "✓ 登录成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# 并发测试函数
function Test-ConcurrentOperations {
    param(
        [int]$ThreadCount = 5,
        [int]$OperationsPerThread = 10
    )
    
    Write-Host ""
    Write-Host "2. 执行并发操作测试 ($ThreadCount 线程, 每线程 $OperationsPerThread 操作)..." -ForegroundColor Yellow
    
    $jobs = @()
    $startTime = Get-Date
    
    # 启动多个并发任务
    for ($i = 1; $i -le $ThreadCount; $i++) {
        $job = Start-Job -ScriptBlock {
            param($baseUrl, $headers, $threadId, $operations)
            
            $results = @()
            
            for ($j = 1; $j -le $operations; $j++) {
                try {
                    # 创建记录
                    $recordData = @{
                        type = "concurrent_test"
                        title = "并发测试记录 T$threadId-$j"
                        content = @{
                            description = "这是线程 $threadId 的第 $j 个测试记录"
                            thread_id = $threadId
                            operation_id = $j
                            timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
                        }
                        tags = @("并发测试", "线程$threadId")
                    }
                    
                    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records" -Method Post -Body ($recordData | ConvertTo-Json -Depth 3) -Headers $headers
                    
                    if ($response.success) {
                        $results += @{
                            thread_id = $threadId
                            operation_id = $j
                            success = $true
                            record_id = $response.data.id
                            latency = 0
                        }
                    } else {
                        $results += @{
                            thread_id = $threadId
                            operation_id = $j
                            success = $false
                            error = "API返回失败"
                        }
                    }
                    
                    # 短暂延迟避免过于密集的请求
                    Start-Sleep -Milliseconds 100
                    
                } catch {
                    $results += @{
                        thread_id = $threadId
                        operation_id = $j
                        success = $false
                        error = $_.Exception.Message
                    }
                }
            }
            
            return $results
        } -ArgumentList $baseUrl, $headers, $i, $OperationsPerThread
        
        $jobs += $job
    }
    
    # 等待所有任务完成
    Write-Host "等待并发任务完成..." -ForegroundColor Cyan
    $allResults = @()
    
    foreach ($job in $jobs) {
        $result = Receive-Job -Job $job -Wait
        $allResults += $result
        Remove-Job -Job $job
    }
    
    $endTime = Get-Date
    $totalTime = ($endTime - $startTime).TotalSeconds
    
    # 统计结果
    $totalOperations = $allResults.Count
    $successfulOperations = ($allResults | Where-Object { $_.success -eq $true }).Count
    $failedOperations = $totalOperations - $successfulOperations
    $successRate = if ($totalOperations -gt 0) { ($successfulOperations / $totalOperations * 100) } else { 0 }
    
    Write-Host ""
    Write-Host "并发测试结果:" -ForegroundColor Cyan
    Write-Host "  总操作数: $totalOperations" -ForegroundColor Gray
    Write-Host "  成功操作: $successfulOperations" -ForegroundColor Green
    Write-Host "  失败操作: $failedOperations" -ForegroundColor Red
    Write-Host "  成功率: $($successRate.ToString('F2'))%" -ForegroundColor Cyan
    Write-Host "  总耗时: $($totalTime.ToString('F2')) 秒" -ForegroundColor Gray
    Write-Host "  平均TPS: $(($totalOperations / $totalTime).ToString('F2'))" -ForegroundColor Gray
    
    # 检查是否有数据库锁定错误
    $lockErrors = $allResults | Where-Object { $_.success -eq $false -and $_.error -like "*database is locked*" }
    if ($lockErrors.Count -gt 0) {
        Write-Host "  数据库锁定错误: $($lockErrors.Count)" -ForegroundColor Red
        Write-Host "✗ 仍然存在数据库锁定问题" -ForegroundColor Red
        return $false
    } else {
        Write-Host "  数据库锁定错误: 0" -ForegroundColor Green
        Write-Host "✓ 未发现数据库锁定问题" -ForegroundColor Green
        return $true
    }
}

# 测试批量导入操作
function Test-BatchImport {
    Write-Host ""
    Write-Host "3. 测试批量导入操作..." -ForegroundColor Yellow
    
    try {
        # 准备批量导入数据
        $importData = @{
            type = "batch_test"
            records = @()
        }
        
        for ($i = 1; $i -le 20; $i++) {
            $importData.records += @{
                title = "批量导入测试记录 $i"
                content = @{
                    description = "这是第 $i 个批量导入的测试记录"
                    batch_id = "batch_$(Get-Date -Format 'yyyyMMddHHmmss')"
                    index = $i
                }
                tags = @("批量导入", "测试")
            }
        }
        
        $startTime = Get-Date
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records/import" -Method Post -Body ($importData | ConvertTo-Json -Depth 3) -Headers $headers
        $endTime = Get-Date
        
        $importTime = ($endTime - $startTime).TotalSeconds
        
        if ($response.success) {
            Write-Host "✓ 批量导入成功" -ForegroundColor Green
            Write-Host "  导入记录数: $($importData.records.Count)" -ForegroundColor Gray
            Write-Host "  导入耗时: $($importTime.ToString('F2')) 秒" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "✗ 批量导入失败" -ForegroundColor Red
            return $false
        }
        
    } catch {
        if ($_.Exception.Message -like "*database is locked*") {
            Write-Host "✗ 批量导入时发生数据库锁定错误" -ForegroundColor Red
            return $false
        } else {
            Write-Host "✗ 批量导入失败: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

# 测试数据库状态
function Test-DatabaseStatus {
    Write-Host ""
    Write-Host "4. 检查数据库状态..." -ForegroundColor Yellow
    
    $dbFile = "data/info_system.db"
    
    if (Test-Path $dbFile) {
        $fileSize = (Get-Item $dbFile).Length
        Write-Host "✓ 数据库文件存在，大小: $(($fileSize / 1MB).ToString('F2')) MB" -ForegroundColor Green
        
        # 检查WAL文件
        $walFile = "$dbFile-wal"
        if (Test-Path $walFile) {
            $walSize = (Get-Item $walFile).Length
            Write-Host "✓ WAL文件存在，大小: $(($walSize / 1KB).ToString('F2')) KB" -ForegroundColor Green
            Write-Host "  WAL模式已启用，有助于提高并发性能" -ForegroundColor Cyan
        } else {
            Write-Host "! WAL文件不存在，可能未启用WAL模式" -ForegroundColor Yellow
        }
        
        return $true
    } else {
        Write-Host "✗ 数据库文件不存在" -ForegroundColor Red
        return $false
    }
}

# 执行所有测试
$testResults = @()

# 测试1: 数据库状态检查
$testResults += Test-DatabaseStatus

# 测试2: 并发操作测试
$testResults += Test-ConcurrentOperations -ThreadCount 3 -OperationsPerThread 5

# 测试3: 批量导入测试
$testResults += Test-BatchImport

# 汇总测试结果
Write-Host ""
Write-Host "=== 测试结果汇总 ===" -ForegroundColor Green

$passedTests = ($testResults | Where-Object { $_ -eq $true }).Count
$totalTests = $testResults.Count

Write-Host "通过测试: $passedTests / $totalTests" -ForegroundColor Cyan

if ($passedTests -eq $totalTests) {
    Write-Host "✓ 所有测试通过，数据库锁定问题已修复" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ 部分测试失败，数据库锁定问题可能仍然存在" -ForegroundColor Red
    exit 1
}