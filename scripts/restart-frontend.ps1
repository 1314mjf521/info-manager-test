#!/usr/bin/env pwsh

Write-Host "=== 重启前端服务 ===" -ForegroundColor Green

# 停止所有 node 进程
Write-Host "停止现有的 Node.js 进程..." -ForegroundColor Cyan
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# 等待进程完全停止
Start-Sleep -Seconds 2

# 清除 Vite 缓存
Write-Host "清除 Vite 缓存..." -ForegroundColor Cyan
if (Test-Path "frontend/node_modules/.vite") {
    Remove-Item -Recurse -Force "frontend/node_modules/.vite"
    Write-Host "✅ 已清除 .vite 缓存" -ForegroundColor Green
}

# 进入前端目录并启动开发服务器
Write-Host "启动前端开发服务器..." -ForegroundColor Cyan
Set-Location frontend

# 启动开发服务器
Write-Host "正在启动 Vite 开发服务器..." -ForegroundColor Yellow
Write-Host "请在浏览器中访问: http://localhost:5173" -ForegroundColor Green
Write-Host "按 Ctrl+C 停止服务器" -ForegroundColor Yellow

npm run dev