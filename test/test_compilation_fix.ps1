#!/usr/bin/env pwsh
# 测试编译修复脚本

Write-Host "=== 测试编译修复 ===" -ForegroundColor Green

# 测试后端编译
Write-Host "`n1. 测试后端编译..." -ForegroundColor Yellow
try {
    $buildResult = & go build -o build/server.exe ./cmd/server/main.go 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 后端编译成功" -ForegroundColor Green
    } else {
        Write-Host "✗ 后端编译失败:" -ForegroundColor Red
        Write-Host $buildResult -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ 后端编译异常: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 测试前端编译
Write-Host "`n2. 测试前端编译..." -ForegroundColor Yellow
Set-Location frontend

try {
    # 检查前端语法
    $viteResult = & npm run build 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 前端编译成功" -ForegroundColor Green
    } else {
        Write-Host "✗ 前端编译失败:" -ForegroundColor Red
        Write-Host $viteResult -ForegroundColor Red
        Set-Location ..
        exit 1
    }
} catch {
    Write-Host "✗ 前端编译异常: $($_.Exception.Message)" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Set-Location ..

Write-Host "`n=== 编译修复测试完成 ===" -ForegroundColor Green
Write-Host "✓ 后端和前端都编译成功" -ForegroundColor Green