#!/usr/bin/env pwsh

Write-Host "=== 测试前端启动 ===" -ForegroundColor Green

# 检查前端目录
if (-not (Test-Path "frontend")) {
    Write-Host "❌ 前端目录不存在" -ForegroundColor Red
    exit 1
}

# 检查 package.json
if (-not (Test-Path "frontend/package.json")) {
    Write-Host "❌ package.json 不存在" -ForegroundColor Red
    exit 1
}

# 检查 node_modules
if (-not (Test-Path "frontend/node_modules")) {
    Write-Host "⚠️ node_modules 不存在，正在安装依赖..." -ForegroundColor Yellow
    Set-Location frontend
    npm install
    Set-Location ..
}

Write-Host "✅ 前端环境检查完成" -ForegroundColor Green

# 检查语法错误
Write-Host "检查 TypeScript 语法..." -ForegroundColor Cyan
Set-Location frontend

# 运行 TypeScript 检查
$tscResult = & npx tsc --noEmit 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ TypeScript 语法检查通过" -ForegroundColor Green
} else {
    Write-Host "❌ TypeScript 语法错误:" -ForegroundColor Red
    Write-Host $tscResult -ForegroundColor Red
}

Set-Location ..

Write-Host "=== 前端启动测试完成 ===" -ForegroundColor Green