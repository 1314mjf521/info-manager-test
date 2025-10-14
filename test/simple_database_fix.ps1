#!/usr/bin/env pwsh
# 简化的数据库修复脚本

Write-Host "=== 简化数据库修复 ===" -ForegroundColor Green

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
    Write-Host "! 停止服务时出现异常" -ForegroundColor Yellow
}

# 2. 清理数据库锁定文件
Write-Host "`n2. 清理数据库锁定文件..." -ForegroundColor Yellow
$dbPath = "data/info_system.db"
if (Test-Path $dbPath) {
    Write-Host "✓ 数据库文件存在" -ForegroundColor Green
    
    # 检查并删除锁定文件
    $lockFiles = @("$dbPath-wal", "$dbPath-shm", "$dbPath-journal")
    foreach ($lockFile in $lockFiles) {
        if (Test-Path $lockFile) {
            Write-Host "! 发现锁定文件: $lockFile" -ForegroundColor Yellow
            try {
                Remove-Item $lockFile -Force
                Write-Host "✓ 已删除锁定文件: $lockFile" -ForegroundColor Green
            } catch {
                Write-Host "✗ 无法删除锁定文件: $lockFile" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "! 数据库文件不存在: $dbPath" -ForegroundColor Yellow
}

# 3. 重新编译后端
Write-Host "`n3. 重新编译后端..." -ForegroundColor Yellow
try {
    $buildResult = & go build -o build/server.exe ./cmd/server/main.go 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 后端重新编译成功" -ForegroundColor Green
    } else {
        Write-Host "✗ 后端编译失败:" -ForegroundColor Red
        Write-Host $buildResult -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 编译异常" -ForegroundColor Red
}

# 4. 启动后端服务
Write-Host "`n4. 启动后端服务..." -ForegroundColor Yellow
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
    Write-Host "✗ 启动服务异常" -ForegroundColor Red
}

# 5. 测试数据库连接
Write-Host "`n5. 测试数据库连接..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 10
    if ($healthResponse.success) {
        Write-Host "✓ 数据库连接正常" -ForegroundColor Green
    } else {
        Write-Host "! 数据库连接可能有问题" -ForegroundColor Yellow
    }
} catch {
    Write-Host "! 无法测试数据库连接" -ForegroundColor Yellow
}

Write-Host "`n=== 简化数据库修复完成 ===" -ForegroundColor Green
Write-Host "修复内容:" -ForegroundColor Cyan
Write-Host "  ✓ 清理了数据库锁定文件" -ForegroundColor Green
Write-Host "  ✓ 重新编译了后端代码" -ForegroundColor Green
Write-Host "  ✓ 重新启动了后端服务" -ForegroundColor Green