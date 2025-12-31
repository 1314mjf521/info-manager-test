#!/usr/bin/env pwsh

# 系统性能监控脚本
# 监控工单系统的性能指标

param(
    [int]$Duration = 60,  # 监控持续时间（秒）
    [int]$Interval = 5    # 监控间隔（秒）
)

Write-Host "=== 工单系统性能监控 ===" -ForegroundColor Green
Write-Host "监控时长: $Duration 秒" -ForegroundColor Blue
Write-Host "监控间隔: $Interval 秒" -ForegroundColor Blue
Write-Host "开始时间: $(Get-Date)" -ForegroundColor Blue

# 创建监控日志目录
$logDir = "logs/performance"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$logFile = "$logDir/performance_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# 监控函数
function Get-SystemMetrics {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # CPU使用率
    $cpu = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1
    $cpuUsage = [math]::Round($cpu.CounterSamples[0].CookedValue, 2)
    
    # 内存使用率
    $totalMemory = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    $availableMemory = (Get-Counter "\Memory\Available MBytes").CounterSamples[0].CookedValue / 1024
    $memoryUsage = [math]::Round((($totalMemory - $availableMemory) / $totalMemory) * 100, 2)
    
    # 磁盘使用率
    $disk = Get-Counter "\PhysicalDisk(_Total)\% Disk Time" -SampleInterval 1 -MaxSamples 1
    $diskUsage = [math]::Round($disk.CounterSamples[0].CookedValue, 2)
    
    # 进程信息
    $process = Get-Process -Name "info-management-system" -ErrorAction SilentlyContinue
    $processInfo = if ($process) {
        @{
            CPU = [math]::Round($process.CPU, 2)
            Memory = [math]::Round($process.WorkingSet64 / 1MB, 2)
            Threads = $process.Threads.Count
        }
    } else {
        @{
            CPU = 0
            Memory = 0
            Threads = 0
        }
    }
    
    # 数据库文件大小
    $dbPath = "data/info_management.db"
    $dbSize = if (Test-Path $dbPath) {
        [math]::Round((Get-Item $dbPath).Length / 1MB, 2)
    } else {
        0
    }
    
    return @{
        Timestamp = $timestamp
        CPU = $cpuUsage
        Memory = $memoryUsage
        Disk = $diskUsage
        Process = $processInfo
        DatabaseSize = $dbSize
    }
}

# 检查服务健康状态
function Test-ServiceHealth {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 5
        return @{
            Status = "Healthy"
            ResponseTime = (Measure-Command { 
                Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 5 
            }).TotalMilliseconds
        }
    } catch {
        return @{
            Status = "Unhealthy"
            ResponseTime = -1
            Error = $_.Exception.Message
        }
    }
}

# 开始监控
$startTime = Get-Date
$endTime = $startTime.AddSeconds($Duration)
$metrics = @()

Write-Host "`n开始监控..." -ForegroundColor Yellow
Write-Host "按 Ctrl+C 提前停止监控" -ForegroundColor Gray

try {
    while ((Get-Date) -lt $endTime) {
        $metric = Get-SystemMetrics
        $health = Test-ServiceHealth
        
        $metric.Health = $health
        $metrics += $metric
        
        # 显示当前状态
        Write-Host "`r[$($metric.Timestamp)] CPU: $($metric.CPU)% | 内存: $($metric.Memory)% | 磁盘: $($metric.Disk)% | 服务: $($health.Status) | 响应: $($health.ResponseTime)ms" -NoNewline -ForegroundColor Cyan
        
        # 记录到日志文件
        $logEntry = "$($metric.Timestamp),CPU:$($metric.CPU)%,Memory:$($metric.Memory)%,Disk:$($metric.Disk)%,ProcessCPU:$($metric.Process.CPU),ProcessMemory:$($metric.Process.Memory)MB,Threads:$($metric.Process.Threads),DBSize:$($metric.DatabaseSize)MB,Health:$($health.Status),ResponseTime:$($health.ResponseTime)ms"
        Add-Content -Path $logFile -Value $logEntry
        
        Start-Sleep -Seconds $Interval
    }
} catch {
    Write-Host "`n监控被中断" -ForegroundColor Yellow
}

Write-Host "`n`n=== 监控报告 ===" -ForegroundColor Green

# 计算统计信息
$avgCPU = [math]::Round(($metrics | Measure-Object -Property CPU -Average).Average, 2)
$maxCPU = ($metrics | Measure-Object -Property CPU -Maximum).Maximum
$avgMemory = [math]::Round(($metrics | Measure-Object -Property Memory -Average).Average, 2)
$maxMemory = ($metrics | Measure-Object -Property Memory -Maximum).Maximum
$avgDisk = [math]::Round(($metrics | Measure-Object -Property Disk -Average).Average, 2)
$maxDisk = ($metrics | Measure-Object -Property Disk -Maximum).Maximum

$healthyCount = ($metrics | Where-Object { $_.Health.Status -eq "Healthy" }).Count
$totalCount = $metrics.Count
$healthRate = if ($totalCount -gt 0) { [math]::Round(($healthyCount / $totalCount) * 100, 2) } else { 0 }

$avgResponseTime = if ($healthyCount -gt 0) {
    [math]::Round(($metrics | Where-Object { $_.Health.Status -eq "Healthy" } | ForEach-Object { $_.Health.ResponseTime } | Measure-Object -Average).Average, 2)
} else {
    0
}

Write-Host "监控时长: $((Get-Date) - $startTime)" -ForegroundColor Blue
Write-Host "采样次数: $totalCount" -ForegroundColor Blue

Write-Host "`n系统资源:" -ForegroundColor Yellow
Write-Host "  CPU使用率: 平均 $avgCPU% | 最高 $maxCPU%" -ForegroundColor White
Write-Host "  内存使用率: 平均 $avgMemory% | 最高 $maxMemory%" -ForegroundColor White
Write-Host "  磁盘使用率: 平均 $avgDisk% | 最高 $maxDisk%" -ForegroundColor White

Write-Host "`n服务健康:" -ForegroundColor Yellow
Write-Host "  健康率: $healthRate% ($healthyCount/$totalCount)" -ForegroundColor White
Write-Host "  平均响应时间: $avgResponseTime ms" -ForegroundColor White

# 性能建议
Write-Host "`n性能建议:" -ForegroundColor Green
if ($avgCPU -gt 80) {
    Write-Host "⚠️  CPU使用率过高，建议优化查询或增加服务器资源" -ForegroundColor Red
}
if ($avgMemory -gt 80) {
    Write-Host "⚠️  内存使用率过高，建议检查内存泄漏或增加内存" -ForegroundColor Red
}
if ($avgDisk -gt 80) {
    Write-Host "⚠️  磁盘使用率过高，建议优化数据库或使用SSD" -ForegroundColor Red
}
if ($healthRate -lt 95) {
    Write-Host "⚠️  服务健康率较低，建议检查服务稳定性" -ForegroundColor Red
}
if ($avgResponseTime -gt 1000) {
    Write-Host "⚠️  响应时间过长，建议优化数据库查询" -ForegroundColor Red
}

if ($avgCPU -lt 50 -and $avgMemory -lt 50 -and $healthRate -gt 95 -and $avgResponseTime -lt 500) {
    Write-Host "✅ 系统运行良好" -ForegroundColor Green
}

Write-Host "`n详细日志已保存到: $logFile" -ForegroundColor Blue
Write-Host "=== 监控完成 ===" -ForegroundColor Green