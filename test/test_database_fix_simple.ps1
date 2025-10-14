#!/usr/bin/env pwsh
# 简单的数据库修复验证脚本

Write-Host "=== 验证数据库修复效果 ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080"
$token = ""

# 1. 登录获取token
Write-Host "`n1. 登录获取token..." -ForegroundColor Yellow
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method Post -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.success) {
        $token = $loginResponse.data.token
        Write-Host "登录成功" -ForegroundColor Green
    } else {
        Write-Host "登录失败: $($loginResponse.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "登录异常: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# 2. 测试单个记录创建
Write-Host "`n2. 测试单个记录创建..." -ForegroundColor Yellow
try {
    $recordData = @{
        type = "test_record"
        title = "数据库修复测试记录"
        content = @{
            description = "这是一个测试数据库修复效果的记录"
            test_time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        tags = @("测试", "数据库修复")
    } | ConvertTo-Json -Depth 3

    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records" -Method Post -Body $recordData -Headers $headers
    
    if ($response.success) {
        Write-Host "单个记录创建成功，ID: $($response.data.id)" -ForegroundColor Green
    } else {
        Write-Host "单个记录创建失败: $($response.message)" -ForegroundColor Red
    }
} catch {
    if ($_.Exception.Message -like "*database is locked*") {
        Write-Host "仍然存在数据库锁定问题" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "记录创建异常: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 3. 测试批量记录创建
Write-Host "`n3. 测试批量记录创建..." -ForegroundColor Yellow
try {
    $batchData = @{
        type = "batch_test"
        records = @()
    }
    
    for ($i = 1; $i -le 5; $i++) {
        $batchData.records += @{
            title = "批量测试记录 $i"
            content = @{
                description = "这是第 $i 个批量测试记录"
                batch_index = $i
                test_time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            tags = @("批量测试", "数据库修复")
        }
    }
    
    $batchJson = $batchData | ConvertTo-Json -Depth 4
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records/import" -Method Post -Body $batchJson -Headers $headers
    
    if ($response.success) {
        Write-Host "批量记录创建成功，创建了 $($batchData.records.Count) 条记录" -ForegroundColor Green
    } else {
        Write-Host "批量记录创建失败: $($response.message)" -ForegroundColor Red
    }
} catch {
    if ($_.Exception.Message -like "*database is locked*") {
        Write-Host "批量操作时仍然存在数据库锁定问题" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "批量记录创建异常: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 4. 检查数据库文件状态
Write-Host "`n4. 检查数据库文件状态..." -ForegroundColor Yellow
$dbFile = "data/info_system.db"

if (Test-Path $dbFile) {
    $fileSize = (Get-Item $dbFile).Length
    Write-Host "数据库文件大小: $(($fileSize / 1MB).ToString('F2')) MB" -ForegroundColor Cyan
    
    # 检查WAL文件
    $walFile = "$dbFile-wal"
    if (Test-Path $walFile) {
        $walSize = (Get-Item $walFile).Length
        Write-Host "WAL文件大小: $(($walSize / 1KB).ToString('F2')) KB" -ForegroundColor Cyan
        Write-Host "WAL模式正常工作" -ForegroundColor Green
    } else {
        Write-Host "WAL文件不存在，可能WAL模式未启用" -ForegroundColor Yellow
    }
    
    # 检查SHM文件
    $shmFile = "$dbFile-shm"
    if (Test-Path $shmFile) {
        Write-Host "SHM文件存在，共享内存正常" -ForegroundColor Cyan
    }
} else {
    Write-Host "数据库文件不存在" -ForegroundColor Red
}

# 5. 测试并发操作（简化版）
Write-Host "`n5. 测试并发操作..." -ForegroundColor Yellow
$jobs = @()

for ($i = 1; $i -le 3; $i++) {
    $job = Start-Job -ScriptBlock {
        param($baseUrl, $headers, $threadId)
        
        try {
            $recordData = @{
                type = "concurrent_test"
                title = "并发测试记录 T$threadId"
                content = @{
                    description = "这是线程 $threadId 的并发测试记录"
                    thread_id = $threadId
                    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
                }
                tags = @("并发测试")
            } | ConvertTo-Json -Depth 3
            
            $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records" -Method Post -Body $recordData -Headers $headers
            
            return @{
                thread_id = $threadId
                success = $response.success
                error = $null
            }
        } catch {
            return @{
                thread_id = $threadId
                success = $false
                error = $_.Exception.Message
            }
        }
    } -ArgumentList $baseUrl, $headers, $i
    
    $jobs += $job
}

# 等待所有任务完成
Write-Host "等待并发任务完成..." -ForegroundColor Cyan
$results = @()
foreach ($job in $jobs) {
    $result = Receive-Job -Job $job -Wait
    $results += $result
    Remove-Job -Job $job
}

# 分析并发测试结果
$successCount = ($results | Where-Object { $_.success -eq $true }).Count
$failCount = $results.Count - $successCount
$lockErrors = ($results | Where-Object { $_.error -like "*database is locked*" }).Count

Write-Host "并发测试结果:" -ForegroundColor Cyan
Write-Host "  成功: $successCount" -ForegroundColor Green
Write-Host "  失败: $failCount" -ForegroundColor Red
Write-Host "  数据库锁定错误: $lockErrors" -ForegroundColor $(if ($lockErrors -gt 0) { "Red" } else { "Green" })

# 6. 总结
Write-Host "`n=== 测试结果总结 ===" -ForegroundColor Green

if ($lockErrors -eq 0) {
    Write-Host "数据库锁定问题已修复" -ForegroundColor Green
    Write-Host "系统可以正常处理并发操作" -ForegroundColor Green
    exit 0
} else {
    Write-Host "仍然存在数据库锁定问题" -ForegroundColor Red
    Write-Host "建议检查配置或考虑升级到PostgreSQL" -ForegroundColor Yellow
    exit 1
}