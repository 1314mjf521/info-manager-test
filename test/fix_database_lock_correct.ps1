#!/usr/bin/env pwsh
# 修复数据库锁定问题的正确脚本

Write-Host "=== 修复数据库锁定问题 ===" -ForegroundColor Green

# 1. 停止现有服务
Write-Host "`n1. 停止现有服务..." -ForegroundColor Yellow
$processes = Get-Process -Name "server" -ErrorAction SilentlyContinue
if ($processes) {
    Write-Host "发现运行中的服务，正在停止..." -ForegroundColor Yellow
    $processes | Stop-Process -Force
    Start-Sleep -Seconds 3
    Write-Host "服务已停止" -ForegroundColor Green
} else {
    Write-Host "没有发现运行中的服务" -ForegroundColor Cyan
}

# 2. 备份数据库
Write-Host "`n2. 备份数据库..." -ForegroundColor Yellow
$dbFile = "data/info_system.db"
if (Test-Path $dbFile) {
    $backupFile = "data/info_system.db.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $dbFile $backupFile
    Write-Host "数据库已备份到: $backupFile" -ForegroundColor Green
} else {
    Write-Host "数据库文件不存在，跳过备份" -ForegroundColor Yellow
}

# 3. 优化数据库配置
Write-Host "`n3. 优化数据库配置..." -ForegroundColor Yellow
$configFile = "configs/config.yaml"

if (Test-Path $configFile) {
    # 备份配置文件
    $configBackup = "$configFile.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $configFile $configBackup
    Write-Host "配置文件已备份到: $configBackup" -ForegroundColor Green
    
    # 读取当前配置
    $config = Get-Content $configFile -Raw
    
    # 更新数据库配置
    $newDsn = 'data/info_system.db?_journal_mode=WAL&_synchronous=NORMAL&_cache_size=10000&_busy_timeout=30000'
    
    # 替换DSN配置
    if ($config -match 'dsn:\s*"([^"]*)"') {
        $config = $config -replace 'dsn:\s*"[^"]*"', "dsn: `"$newDsn`""
        Write-Host "已更新DSN配置" -ForegroundColor Green
    } else {
        Write-Host "未找到DSN配置，可能需要手动添加" -ForegroundColor Yellow
    }
    
    # 添加连接池配置
    if ($config -notmatch 'max_open_conns:') {
        $config += "`n  max_open_conns: 1"
        $config += "`n  max_idle_conns: 1"
        $config += "`n  conn_max_lifetime: 3600"
        $config += "`n  conn_max_idle_time: 1800"
        Write-Host "已添加连接池配置" -ForegroundColor Green
    }
    
    # 保存配置
    Set-Content $configFile $config -Encoding UTF8
    Write-Host "配置文件已更新" -ForegroundColor Green
} else {
    Write-Host "配置文件不存在: $configFile" -ForegroundColor Red
}

# 4. 创建数据库优化SQL脚本
Write-Host "`n4. 创建数据库优化脚本..." -ForegroundColor Yellow
if (!(Test-Path "scripts")) {
    New-Item -ItemType Directory -Path "scripts" -Force | Out-Null
}

$optimizeSQL = @"
-- SQLite 数据库优化脚本
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA cache_size = 10000;
PRAGMA busy_timeout = 30000;
PRAGMA foreign_keys = ON;
ANALYZE;
REINDEX;
"@

Set-Content "scripts/optimize_database.sql" $optimizeSQL -Encoding UTF8
Write-Host "数据库优化脚本已创建" -ForegroundColor Green

# 5. 应用数据库优化
Write-Host "`n5. 应用数据库优化..." -ForegroundColor Yellow
if (Test-Path $dbFile) {
    try {
        # 检查是否有sqlite3命令
        $sqlite3 = Get-Command sqlite3 -ErrorAction SilentlyContinue
        if ($sqlite3) {
            & sqlite3 $dbFile ".read scripts/optimize_database.sql"
            Write-Host "数据库优化已应用" -ForegroundColor Green
        } else {
            Write-Host "sqlite3命令不可用，将在服务启动时自动优化" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "数据库优化失败，但不影响服务启动: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "数据库文件不存在，将在首次启动时创建" -ForegroundColor Yellow
}

# 6. 重新编译服务
Write-Host "`n6. 重新编译服务..." -ForegroundColor Yellow
try {
    $buildResult = & go build -o build/server.exe ./cmd/server/main.go 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "服务编译成功" -ForegroundColor Green
    } else {
        Write-Host "服务编译失败:" -ForegroundColor Red
        Write-Host $buildResult -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "编译异常: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 7. 启动优化后的服务
Write-Host "`n7. 启动优化后的服务..." -ForegroundColor Yellow
try {
    Start-Process -FilePath "build/server.exe" -WindowStyle Hidden
    Start-Sleep -Seconds 5
    
    # 检查服务状态
    $newProcess = Get-Process -Name "server" -ErrorAction SilentlyContinue
    if ($newProcess) {
        Write-Host "服务启动成功，PID: $($newProcess.Id)" -ForegroundColor Green
    } else {
        Write-Host "服务启动失败" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "启动服务异常: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 8. 验证数据库状态
Write-Host "`n8. 验证数据库状态..." -ForegroundColor Yellow
if (Test-Path $dbFile) {
    $fileSize = (Get-Item $dbFile).Length
    Write-Host "数据库文件大小: $(($fileSize / 1MB).ToString('F2')) MB" -ForegroundColor Cyan
    
    # 检查WAL文件
    $walFile = "$dbFile-wal"
    if (Test-Path $walFile) {
        $walSize = (Get-Item $walFile).Length
        Write-Host "WAL文件大小: $(($walSize / 1KB).ToString('F2')) KB" -ForegroundColor Cyan
        Write-Host "WAL模式已启用" -ForegroundColor Green
    } else {
        Write-Host "WAL文件不存在，可能尚未启用WAL模式" -ForegroundColor Yellow
    }
} else {
    Write-Host "数据库文件不存在" -ForegroundColor Red
}

Write-Host "`n=== 数据库锁定问题修复完成 ===" -ForegroundColor Green
Write-Host "主要优化措施:" -ForegroundColor Cyan
Write-Host "1. 启用WAL模式提高并发性能" -ForegroundColor Gray
Write-Host "2. 优化数据库连接池配置" -ForegroundColor Gray
Write-Host "3. 增加忙等待超时时间到30秒" -ForegroundColor Gray
Write-Host "4. 设置合理的缓存大小" -ForegroundColor Gray
Write-Host "5. 使用单连接避免竞争" -ForegroundColor Gray

Write-Host "`n建议:" -ForegroundColor Yellow
Write-Host "- 监控WAL文件大小，定期执行PRAGMA wal_checkpoint" -ForegroundColor Gray
Write-Host "- 如果仍有问题，考虑升级到PostgreSQL" -ForegroundColor Gray
Write-Host "- 定期备份数据库文件" -ForegroundColor Gray