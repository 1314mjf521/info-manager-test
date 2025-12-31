#!/usr/bin/env pwsh

Write-Host "=== 修复前端缓存问题 ===" -ForegroundColor Green

# 停止开发服务器（如果在运行）
Write-Host "停止可能运行的开发服务器..." -ForegroundColor Cyan
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# 清除 Vite 缓存
Write-Host "清除 Vite 缓存..." -ForegroundColor Cyan
if (Test-Path "frontend/node_modules/.vite") {
    Remove-Item -Recurse -Force "frontend/node_modules/.vite"
    Write-Host "✅ 已清除 .vite 缓存" -ForegroundColor Green
}

# 清除 dist 目录
if (Test-Path "frontend/dist") {
    Remove-Item -Recurse -Force "frontend/dist"
    Write-Host "✅ 已清除 dist 目录" -ForegroundColor Green
}

# 重新安装依赖
Write-Host "重新安装依赖..." -ForegroundColor Cyan
Set-Location frontend
Remove-Item -Recurse -Force "node_modules" -ErrorAction SilentlyContinue
npm install

Write-Host "✅ 前端缓存清理完成" -ForegroundColor Green
Write-Host "现在可以重新启动开发服务器: npm run dev" -ForegroundColor Yellow

Set-Location ..