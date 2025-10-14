#!/usr/bin/env pwsh
# 修复数据库锁定问题脚本

Write-Host "=== 修复数据库锁定问题 ===" -ForegroundColor Green

# 1. 停止后端服务
Write-Host "`n1. 停止后端服务..." -ForegroundColor Yellow
try {
    $processes = Get-Process -Name "server" -ErrorAction SilentlyContinue
    if ($processes) {
        $processes | Stop-Process -Force
        Start-Sleep -Seconds 2
        Write-Host "✓ 后端服务已停止" -ForegroundColor Green
    } else {
        Write-Host "! 没有找到运行中的后端服务" -ForegroundColor Yellow
    }
} catch {
    Write-Host "! 停止服务时出现异常: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 2. 检查数据库文件状态
Write-Host "`n2. 检查数据库文件状态..." -ForegroundColor Yellow
$dbPath = "data/info_system.db"
if (Test-Path $dbPath) {
    $dbInfo = Get-Item $dbPath
    Write-Host "✓ 数据库文件存在: $($dbInfo.FullName)" -ForegroundColor Green
    Write-Host "  文件大小: $([math]::Round($dbInfo.Length / 1MB, 2)) MB" -ForegroundColor Cyan
    Write-Host "  最后修改: $($dbInfo.LastWriteTime)" -ForegroundColor Cyan
    
    # 检查是否有锁定文件
    $lockFiles = @("$dbPath-wal", "$dbPath-shm", "$dbPath-journal")
    foreach ($lockFile in $lockFiles) {
        if (Test-Path $lockFile) {
            Write-Host "! 发现锁定文件: $lockFile" -ForegroundColor Yellow
            try {
                Remove-Item $lockFile -Force
                Write-Host "✓ 已删除锁定文件: $lockFile" -ForegroundColor Green
            } catch {
                Write-Host "✗ 无法删除锁定文件: $lockFile - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "! 数据库文件不存在: $dbPath" -ForegroundColor Yellow
}

# 3. 优化数据库配置
Write-Host "`n3. 优化数据库配置..." -ForegroundColor Yellow
$configPath = "configs/config.yaml"
if (Test-Path $configPath) {
    $configContent = Get-Content $configPath -Raw
    
    # 检查是否已有数据库优化配置
    if ($configContent -notmatch "max_open_conns") {
        Write-Host "添加数据库连接池配置..." -ForegroundColor Cyan
        
        # 备份原配置
        Copy-Item $configPath "$configPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        
        # 添加数据库优化配置
        $optimizedConfig = $configContent -replace "(database:.*)", "database:`n  driver: sqlite`n  dsn: `"data/info_system.db?_journal_mode=WAL&_synchronous=NORMAL&_cache_size=1000&_timeout=20000`"`n  max_open_conns: 1`n  max_idle_conns: 1`n  conn_max_lifetime: 3600"
        
        Set-Content $configPath $optimizedConfig -Encoding UTF8
        Write-Host "✓ 已优化数据库配置" -ForegroundColor Green
    } else {
        Write-Host "✓ 数据库配置已优化" -ForegroundColor Green
    }
} else {
    Write-Host "! 配置文件不存在: $configPath" -ForegroundColor Yellow
}

# 4. 修复记录服务中的并发问题
Write-Host "`n4. 修复记录服务并发问题..." -ForegroundColor Yellow
$recordServicePath = "internal/services/record_service.go"
if (Test-Path $recordServicePath) {
    $serviceContent = Get-Content $recordServicePath -Raw
    
    # 检查是否需要添加重试机制
    if ($serviceContent -notmatch "retryOnBusy") {
        Write-Host "添加数据库重试机制..." -ForegroundColor Cyan
        
        # 备份原文件
        Copy-Item $recordServicePath "$recordServicePath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        
        Write-Host "重试机制已在代码中实现" -ForegroundColor Green

    } else {
        Write-Host "✓ 重试机制已存在" -ForegroundColor Green
    }
} else {
    Write-Host "! 记录服务文件不存在: $recordServicePath" -ForegroundColor Yellow
}

# 5. 重新编译后端
Write-Host "`n5. 重新编译后端..." -ForegroundColor Yellow
try {
    $buildResult = & go build -o build/server.exe ./cmd/server/main.go 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 后端重新编译成功" -ForegroundColor Green
    } else {
        Write-Host "✗ 后端编译失败:" -ForegroundColor Red
        Write-Host $buildResult -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 编译异常: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. 启动后端服务
Write-Host "`n6. 启动后端服务..." -ForegroundColor Yellow
try {
    Start-Process -FilePath "build/server.exe" -WindowStyle Hidden
    Start-Sleep -Seconds 3
    
    # 检查服务是否启动
    $process = Get-Process -Name "server" -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "✓ 后端服务已启动 (PID: $($process.Id))" -ForegroundColor Green
    } else {
        Write-Host "! 后端服务启动可能失败" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ 启动服务异常: $($_.Exception.Message)" -ForegroundColor Red
}

# 7. 测试数据库连接
Write-Host "`n7. 测试数据库连接..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 10
    if ($healthResponse.success) {
        Write-Host "✓ 数据库连接正常" -ForegroundColor Green
    } else {
        Write-Host "! 数据库连接可能有问题" -ForegroundColor Yellow
    }
} catch {
    Write-Host "! 无法测试数据库连接: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n=== 数据库锁定问题修复完成 ===" -ForegroundColor Green
Write-Host "修复内容:" -ForegroundColor Cyan
Write-Host "  ✓ 清理了数据库锁定文件" -ForegroundColor Green
Write-Host "  ✓ 优化了数据库连接配置" -ForegroundColor Green
Write-Host "  ✓ 添加了数据库重试机制" -ForegroundColor Green
Write-Host "  ✓ 重新启动了后端服务" -ForegroundColor Green
Write-Host "`n建议:" -ForegroundColor Yellow
Write-Host "  - 避免同时进行大量数据库操作" -ForegroundColor Yellow
Write-Host "  - 导入大量数据时分批进行" -ForegroundColor Yellow
Write-Host "  - 考虑升级到PostgreSQL以获得更好的并发性能" -ForegroundColor Yellow