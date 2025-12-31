#!/usr/bin/env pwsh

# 数据库性能优化脚本
# 执行数据库索引优化和性能调优

Write-Host "=== 数据库性能优化脚本 ===" -ForegroundColor Green

# 检查是否存在优化SQL文件
$sqlFile = "scripts/optimize-database.sql"
if (-not (Test-Path $sqlFile)) {
    Write-Host "错误: 找不到优化SQL文件 $sqlFile" -ForegroundColor Red
    exit 1
}

# 读取数据库配置（假设使用SQLite）
$dbPath = "data/info_management.db"

# 检查数据库文件是否存在
if (-not (Test-Path $dbPath)) {
    Write-Host "错误: 找不到数据库文件 $dbPath" -ForegroundColor Red
    Write-Host "请确保应用程序已经运行过并创建了数据库" -ForegroundColor Yellow
    exit 1
}

Write-Host "正在优化数据库: $dbPath" -ForegroundColor Yellow

try {
    # 使用sqlite3命令执行优化SQL
    if (Get-Command sqlite3 -ErrorAction SilentlyContinue) {
        Write-Host "使用sqlite3执行优化..." -ForegroundColor Blue
        sqlite3 $dbPath ".read $sqlFile"
        
        # 执行VACUUM来优化数据库文件
        Write-Host "执行VACUUM优化..." -ForegroundColor Blue
        sqlite3 $dbPath "VACUUM;"
        
        # 执行ANALYZE来更新统计信息
        Write-Host "更新统计信息..." -ForegroundColor Blue
        sqlite3 $dbPath "ANALYZE;"
        
        Write-Host "数据库优化完成!" -ForegroundColor Green
    } else {
        Write-Host "警告: 未找到sqlite3命令" -ForegroundColor Yellow
        Write-Host "请手动执行以下SQL文件: $sqlFile" -ForegroundColor Yellow
    }
} catch {
    Write-Host "优化过程中出现错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 显示数据库信息
Write-Host "`n=== 数据库信息 ===" -ForegroundColor Green
if (Get-Command sqlite3 -ErrorAction SilentlyContinue) {
    Write-Host "数据库大小:" -ForegroundColor Blue
    $dbSize = (Get-Item $dbPath).Length / 1MB
    Write-Host "$([math]::Round($dbSize, 2)) MB" -ForegroundColor White
    
    Write-Host "`n表信息:" -ForegroundColor Blue
    sqlite3 $dbPath ".tables"
    
    Write-Host "`n索引信息:" -ForegroundColor Blue
    sqlite3 $dbPath ".indices"
}

Write-Host "`n优化建议:" -ForegroundColor Green
Write-Host "1. 定期运行此脚本以保持数据库性能" -ForegroundColor White
Write-Host "2. 监控应用程序日志中的慢查询" -ForegroundColor White
Write-Host "3. 考虑定期清理旧的系统日志" -ForegroundColor White
Write-Host "4. 如果数据量很大，考虑使用PostgreSQL或MySQL" -ForegroundColor White

Write-Host "`n=== 优化完成 ===" -ForegroundColor Green