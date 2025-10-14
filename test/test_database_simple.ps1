#!/usr/bin/env pwsh
# 简单的数据库修复验证脚本

Write-Host "=== 验证数据库修复效果 ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080"

# 1. 检查服务状态
Write-Host "`n1. 检查服务状态..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/health" -Method Get -TimeoutSec 5
    Write-Host "服务运行正常" -ForegroundColor Green
} catch {
    Write-Host "服务未运行或无法访问: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "请先运行修复脚本启动服务" -ForegroundColor Yellow
    exit 1
}

# 2. 登录获取token
Write-Host "`n2. 登录获取token..." -ForegroundColor Yellow
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

# 3. 测试记录创建
Write-Host "`n3. 测试记录创建..." -ForegroundColor Yellow
$testResults = @()

for ($i = 1; $i -le 5; $i++) {
    try {
        $recordData = @{
            type = "test_record"
            title = "数据库测试记录 $i"
            content = @{
                description = "这是第 $i 个测试记录"
                test_time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            tags = @("测试", "数据库")
        } | ConvertTo-Json -Depth 3

        $startTime = Get-Date
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records" -Method Post -Body $recordData -Headers $headers
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($response.success) {
            $testResults += @{
                index = $i
                success = $true
                duration = $duration
                error = $null
            }
            Write-Host "记录 $i 创建成功，耗时: $($duration.ToString('F0'))ms" -ForegroundColor Green
        } else {
            $testResults += @{
                index = $i
                success = $false
                duration = $duration
                error = $response.message
            }
            Write-Host "记录 $i 创建失败: $($response.message)" -ForegroundColor Red
        }
        
        # 短暂延迟
        Start-Sleep -Milliseconds 200
        
    } catch {
        $testResults += @{
            index = $i
            success = $false
            duration = 0
            error = $_.Exception.Message
        }
        
        if ($_.Exception.Message -like "*database is locked*") {
            Write-Host "记录 $i 创建失败: 数据库锁定错误" -ForegroundColor Red
        } else {
            Write-Host "记录 $i 创建异常: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# 4. 分析测试结果
Write-Host "`n4. 分析测试结果..." -ForegroundColor Yellow
$successCount = ($testResults | Where-Object { $_.success -eq $true }).Count
$failCount = $testResults.Count - $successCount
$lockErrors = ($testResults | Where-Object { $_.error -like "*database is locked*" }).Count
$avgDuration = if ($successCount -gt 0) { 
    ($testResults | Where-Object { $_.success -eq $true } | Measure-Object -Property duration -Average).Average 
} else { 0 }

Write-Host "测试结果统计:" -ForegroundColor Cyan
Write-Host "  总测试数: $($testResults.Count)" -ForegroundColor Gray
Write-Host "  成功数: $successCount" -ForegroundColor Green
Write-Host "  失败数: $failCount" -ForegroundColor Red
Write-Host "  数据库锁定错误: $lockErrors" -ForegroundColor $(if ($lockErrors -gt 0) { "Red" } else { "Green" })
Write-Host "  平均响应时间: $($avgDuration.ToString('F0'))ms" -ForegroundColor Cyan

# 5. 检查数据库文件状态
Write-Host "`n5. 检查数据库文件状态..." -ForegroundColor Yellow
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
} else {
    Write-Host "数据库文件不存在" -ForegroundColor Red
}

# 6. 总结
Write-Host "`n=== 测试结果总结 ===" -ForegroundColor Green

if ($lockErrors -eq 0 -and $successCount -eq $testResults.Count) {
    Write-Host "数据库锁定问题已完全修复" -ForegroundColor Green
    Write-Host "所有测试都成功完成" -ForegroundColor Green
    exit 0
} elseif ($lockErrors -eq 0 -and $successCount -gt 0) {
    Write-Host "数据库锁定问题已修复" -ForegroundColor Green
    Write-Host "但存在其他问题，请检查失败的测试" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "仍然存在数据库锁定问题" -ForegroundColor Red
    Write-Host "建议检查配置或考虑升级到PostgreSQL" -ForegroundColor Yellow
    exit 1
}