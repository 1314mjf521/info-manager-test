# 修复数据库锁定问题的最终脚本
# PowerShell 脚本，使用UTF-8编码

Write-Host "=== 修复数据库锁定问题 ===" -ForegroundColor Green

# 1. 检查数据库配置
Write-Host ""
Write-Host "1. 检查数据库配置..." -ForegroundColor Yellow

$configFile = "configs/config.yaml"
if (Test-Path $configFile) {
    $config = Get-Content $configFile -Raw -Encoding UTF8
    Write-Host "当前数据库配置:" -ForegroundColor Cyan
    $dbSection = $config | Select-String -Pattern "database:" -Context 5,5
    if ($dbSection) {
        Write-Host $dbSection -ForegroundColor Gray
    }
} else {
    Write-Host "配置文件不存在: $configFile" -ForegroundColor Red
}

# 2. 优化数据库连接配置
Write-Host ""
Write-Host "2. 优化数据库连接配置..." -ForegroundColor Yellow

$optimizedConfig = @'
database:
  driver: sqlite
  dsn: "data/info_system.db?_journal_mode=WAL&_synchronous=NORMAL&_cache_size=10000&_busy_timeout=30000"
  max_open_conns: 1
  max_idle_conns: 1
  conn_max_lifetime: 3600
  conn_max_idle_time: 1800
  
# SQLite 优化参数说明:
# _journal_mode=WAL: 使用WAL模式，提高并发性能
# _synchronous=NORMAL: 平衡性能和安全性
# _cache_size=10000: 增加缓存大小
# _busy_timeout=30000: 设置忙等待超时为30秒
# max_open_conns=1: SQLite建议单连接
# max_idle_conns=1: 保持一个空闲连接
'@

# 备份原配置
if (Test-Path $configFile) {
    $backupName = "$configFile.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $configFile $backupName
    Write-Host "已备份原配置文件到: $backupName" -ForegroundColor Green
}

# 更新配置文件中的数据库部分
try {
    $currentConfig = Get-Content $configFile -Raw -Encoding UTF8
    
    # 简单替换整个database配置块
    if ($currentConfig -match '(?s)database:.*?(?=\n\w|\n$|$)') {
        $newConfig = $currentConfig -replace '(?s)database:.*?(?=\n\w|\n$|$)', $optimizedConfig
    } else {
        # 如果没有找到database配置，追加到文件末尾
        $newConfig = $currentConfig + "`n" + $optimizedConfig
    }
    
    Set-Content $configFile $newConfig -Encoding UTF8
    Write-Host "已更新数据库配置" -ForegroundColor Green
} catch {
    Write-Host "更新配置失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. 创建数据库优化脚本
Write-Host ""
Write-Host "3. 创建数据库优化脚本..." -ForegroundColor Yellow

$dbOptimizeScript = @'
-- SQLite 数据库优化脚本
-- 启用WAL模式
PRAGMA journal_mode = WAL;

-- 设置同步模式
PRAGMA synchronous = NORMAL;

-- 增加缓存大小
PRAGMA cache_size = 10000;

-- 设置忙等待超时
PRAGMA busy_timeout = 30000;

-- 启用外键约束
PRAGMA foreign_keys = ON;

-- 优化查询计划
ANALYZE;

-- 重建索引
REINDEX;

-- 清理数据库
VACUUM;
'@

# 确保scripts目录存在
if (!(Test-Path "scripts")) {
    New-Item -ItemType Directory -Path "scripts" -Force | Out-Null
}

Set-Content "scripts/optimize_database.sql" $dbOptimizeScript -Encoding UTF8
Write-Host "已创建数据库优化脚本" -ForegroundColor Green

# 4. 创建数据库连接池优化代码
Write-Host ""
Write-Host "4. 创建数据库连接池优化代码..." -ForegroundColor Yellow

$dbConnectionCode = @'
package database

import (
    "database/sql"
    "time"
    
    "gorm.io/driver/sqlite"
    "gorm.io/gorm"
    "gorm.io/gorm/logger"
)

// OptimizeDatabase 优化数据库连接
func OptimizeDatabase(db *gorm.DB) error {
    sqlDB, err := db.DB()
    if err != nil {
        return err
    }
    
    // 设置连接池参数
    sqlDB.SetMaxOpenConns(1)    // SQLite 建议单连接
    sqlDB.SetMaxIdleConns(1)    // 保持一个空闲连接
    sqlDB.SetConnMaxLifetime(time.Hour)     // 连接最大生存时间
    sqlDB.SetConnMaxIdleTime(30 * time.Minute) // 连接最大空闲时间
    
    // 执行优化SQL
    optimizeSQL := []string{
        "PRAGMA journal_mode = WAL",
        "PRAGMA synchronous = NORMAL", 
        "PRAGMA cache_size = 10000",
        "PRAGMA busy_timeout = 30000",
        "PRAGMA foreign_keys = ON",
    }
    
    for _, sql := range optimizeSQL {
        if err := db.Exec(sql).Error; err != nil {
            return err
        }
    }
    
    return nil
}

// CreateOptimizedConnection 创建优化的数据库连接
func CreateOptimizedConnection(dsn string) (*gorm.DB, error) {
    db, err := gorm.Open(sqlite.Open(dsn), &gorm.Config{
        Logger: logger.Default.LogMode(logger.Silent), // 减少日志输出
        PrepareStmt: true, // 预编译语句
        DisableForeignKeyConstraintWhenMigrating: false,
    })
    
    if err != nil {
        return nil, err
    }
    
    // 应用优化
    if err := OptimizeDatabase(db); err != nil {
        return nil, err
    }
    
    return db, nil
}
'@

if (!(Test-Path "internal/database")) {
    New-Item -ItemType Directory -Path "internal/database" -Force | Out-Null
}

Set-Content "internal/database/optimize.go" $dbConnectionCode -Encoding UTF8
Write-Host "已创建数据库连接优化代码" -ForegroundColor Green

# 5. 创建异步审计日志服务
Write-Host "`n5. 创建异步审计日志服务..." -ForegroundColor Yellow

$asyncAuditCode = @"
package services

import (
    "context"
    "log"
    "sync"
    "time"
    
    "info-management-system/internal/models"
    "gorm.io/gorm"
)

// AsyncAuditService 异步审计服务
type AsyncAuditService struct {
    db       *gorm.DB
    queue    chan *models.AuditLog
    wg       sync.WaitGroup
    ctx      context.Context
    cancel   context.CancelFunc
    batchSize int
    flushInterval time.Duration
}

// NewAsyncAuditService 创建异步审计服务
func NewAsyncAuditService(db *gorm.DB) *AsyncAuditService {
    ctx, cancel := context.WithCancel(context.Background())
    
    service := &AsyncAuditService{
        db:            db,
        queue:         make(chan *models.AuditLog, 1000), // 缓冲队列
        ctx:           ctx,
        cancel:        cancel,
        batchSize:     50,  // 批量处理大小
        flushInterval: 5 * time.Second, // 刷新间隔
    }
    
    // 启动后台处理协程
    service.wg.Add(1)
    go service.processQueue()
    
    return service
}

// LogAsync 异步记录审计日志
func (s *AsyncAuditService) LogAsync(auditLog *models.AuditLog) {
    select {
    case s.queue <- auditLog:
        // 成功加入队列
    default:
        // 队列满了，直接写入数据库
        go func() {
            if err := s.db.Create(auditLog).Error; err != nil {
                log.Printf("审计日志写入失败: %v", err)
            }
        }()
    }
}

// processQueue 处理队列中的审计日志
func (s *AsyncAuditService) processQueue() {
    defer s.wg.Done()
    
    batch := make([]*models.AuditLog, 0, s.batchSize)
    ticker := time.NewTicker(s.flushInterval)
    defer ticker.Stop()
    
    for {
        select {
        case <-s.ctx.Done():
            // 处理剩余的日志
            if len(batch) > 0 {
                s.flushBatch(batch)
            }
            return
            
        case auditLog := <-s.queue:
            batch = append(batch, auditLog)
            
            // 批量大小达到阈值，立即处理
            if len(batch) >= s.batchSize {
                s.flushBatch(batch)
                batch = batch[:0] // 清空切片
            }
            
        case <-ticker.C:
            // 定时刷新
            if len(batch) > 0 {
                s.flushBatch(batch)
                batch = batch[:0] // 清空切片
            }
        }
    }
}

// flushBatch 批量写入审计日志
func (s *AsyncAuditService) flushBatch(batch []*models.AuditLog) {
    if len(batch) == 0 {
        return
    }
    
    // 使用事务批量插入
    err := s.db.Transaction(func(tx *gorm.DB) error {
        return tx.CreateInBatches(batch, len(batch)).Error
    })
    
    if err != nil {
        log.Printf("批量写入审计日志失败: %v", err)
        
        // 失败时逐个尝试写入
        for _, auditLog := range batch {
            if err := s.db.Create(auditLog).Error; err != nil {
                log.Printf("单个审计日志写入失败: %v", err)
            }
        }
    }
}

// Close 关闭异步审计服务
func (s *AsyncAuditService) Close() {
    s.cancel()
    close(s.queue)
    s.wg.Wait()
}
"@

Set-Content "internal/services/async_audit_service.go" $asyncAuditCode -Encoding UTF8
Write-Host "✓ 已创建异步审计日志服务" -ForegroundColor Green

# 6. 创建数据库健康检查脚本
Write-Host "`n6. 创建数据库健康检查脚本..." -ForegroundColor Yellow

$healthCheckScript = @"
#!/usr/bin/env pwsh
# 数据库健康检查脚本

Write-Host "=== 数据库健康检查 ===" -ForegroundColor Green

`$dbFile = "data/info_system.db"

if (!(Test-Path `$dbFile)) {
    Write-Host "✗ 数据库文件不存在: `$dbFile" -ForegroundColor Red
    exit 1
}

# 检查数据库文件大小
`$fileSize = (Get-Item `$dbFile).Length
Write-Host "数据库文件大小: `$((`$fileSize / 1MB).ToString('F2')) MB" -ForegroundColor Cyan

# 检查WAL文件
`$walFile = "`$dbFile-wal"
if (Test-Path `$walFile) {
    `$walSize = (Get-Item `$walFile).Length
    Write-Host "WAL文件大小: `$((`$walSize / 1KB).ToString('F2')) KB" -ForegroundColor Cyan
} else {
    Write-Host "WAL文件不存在（可能未启用WAL模式）" -ForegroundColor Yellow
}

# 检查SHM文件
`$shmFile = "`$dbFile-shm"
if (Test-Path `$shmFile) {
    Write-Host "SHM文件存在" -ForegroundColor Cyan
} else {
    Write-Host "SHM文件不存在" -ForegroundColor Yellow
}

Write-Host "`n=== 数据库健康检查完成 ===" -ForegroundColor Green
"@

Set-Content "scripts/check_database_health.ps1" $healthCheckScript -Encoding UTF8
Write-Host "✓ 已创建数据库健康检查脚本" -ForegroundColor Green

# 7. 重启服务以应用优化
Write-Host "`n7. 重启服务以应用优化..." -ForegroundColor Yellow

# 停止现有服务
$processes = Get-Process -Name "server" -ErrorAction SilentlyContinue
if ($processes) {
    Write-Host "停止现有服务..." -ForegroundColor Yellow
    $processes | Stop-Process -Force
    Start-Sleep -Seconds 2
}

# 重新编译
Write-Host "重新编译服务..." -ForegroundColor Yellow
try {
    & go build -o build/server.exe ./cmd/server/main.go
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 编译成功" -ForegroundColor Green
    } else {
        Write-Host "✗ 编译失败" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ 编译异常: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 启动服务
Write-Host "启动优化后的服务..." -ForegroundColor Yellow
Start-Process -FilePath "build/server.exe" -WindowStyle Hidden
Start-Sleep -Seconds 3

# 检查服务状态
$newProcess = Get-Process -Name "server" -ErrorAction SilentlyContinue
if ($newProcess) {
    Write-Host "✓ 服务启动成功，PID: $($newProcess.Id)" -ForegroundColor Green
} else {
    Write-Host "✗ 服务启动失败" -ForegroundColor Red
}

Write-Host "`n=== 数据库锁定问题修复完成 ===" -ForegroundColor Green
Write-Host "主要优化措施:" -ForegroundColor Cyan
Write-Host "1. 启用WAL模式提高并发性能" -ForegroundColor Gray
Write-Host "2. 优化数据库连接池配置" -ForegroundColor Gray  
Write-Host "3. 增加忙等待超时时间" -ForegroundColor Gray
Write-Host "4. 实现异步审计日志服务" -ForegroundColor Gray
Write-Host "5. 批量处理减少数据库操作频率" -ForegroundColor Gray