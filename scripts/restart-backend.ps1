#!/usr/bin/env pwsh

Write-Host "=== 重启后端服务 ===" -ForegroundColor Green

# 停止现有的Go进程
Write-Host "停止现有的后端服务..." -ForegroundColor Cyan
Get-Process -Name "go" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process -Name "main" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# 等待进程完全停止
Start-Sleep -Seconds 3

# 启动新的后端服务
Write-Host "启动后端服务..." -ForegroundColor Cyan
Start-Process -FilePath "go" -ArgumentList "run", "main.go" -WorkingDirectory "." -WindowStyle Hidden

# 等待服务启动
Start-Sleep -Seconds 5

# 测试服务是否正常启动
Write-Host "测试服务启动状态..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/health" -Method GET -TimeoutSec 10
    Write-Host "✅ 后端服务启动成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 后端服务启动失败或未响应" -ForegroundColor Red
    Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=== 后端服务重启完成 ===" -ForegroundColor Green