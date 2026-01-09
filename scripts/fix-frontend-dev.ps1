#!/usr/bin/env pwsh
# 修复前端开发环境问题

Write-Host "🔧 修复前端开发环境..." -ForegroundColor Cyan

# 进入前端目录
$frontendPath = "frontend"
if (!(Test-Path $frontendPath)) {
    Write-Host "[ERROR] 前端目录不存在" -ForegroundColor Red
    exit 1
}

Push-Location $frontendPath

try {
    Write-Host "🧹 清理缓存和临时文件..." -ForegroundColor Yellow
    
    # 删除 node_modules/.vite 缓存
    if (Test-Path "node_modules/.vite") {
        Remove-Item "node_modules/.vite" -Recurse -Force
        Write-Host "  ✅ 清理 Vite 缓存" -ForegroundColor Green
    }
    
    # 删除 dist 目录
    if (Test-Path "dist") {
        Remove-Item "dist" -Recurse -Force
        Write-Host "  ✅ 清理构建输出" -ForegroundColor Green
    }
    
    # 清理 TypeScript 缓存
    if (Test-Path ".tsbuildinfo") {
        Remove-Item ".tsbuildinfo" -Force
        Write-Host "  ✅ 清理 TypeScript 缓存" -ForegroundColor Green
    }
    
    Write-Host "📦 重新安装依赖..." -ForegroundColor Yellow
    
    # 重新安装依赖
    npm install
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] 依赖安装失败" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  ✅ 依赖安装完成" -ForegroundColor Green
    
    Write-Host "🔍 检查关键文件..." -ForegroundColor Yellow
    
    # 检查关键文件是否存在
    $keyFiles = @(
        "src/utils/request.ts",
        "src/stores/auth.ts", 
        "src/config/api.ts",
        "src/router/index.ts",
        "src/main.ts",
        "src/App.vue"
    )
    
    $missingFiles = @()
    foreach ($file in $keyFiles) {
        if (!(Test-Path $file)) {
            $missingFiles += $file
            Write-Host "  ❌ 缺失文件: $file" -ForegroundColor Red
        } else {
            Write-Host "  ✅ 文件存在: $file" -ForegroundColor Green
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Host "[ERROR] 发现缺失文件，需要手动修复" -ForegroundColor Red
        Write-Host "缺失的文件:" -ForegroundColor Yellow
        foreach ($file in $missingFiles) {
            Write-Host "  - $file" -ForegroundColor Red
        }
        exit 1
    }
    
    Write-Host "🚀 启动开发服务器..." -ForegroundColor Yellow
    
    # 启动开发服务器
    Write-Host "正在启动前端开发服务器..." -ForegroundColor Cyan
    Write-Host "如果出现错误，请按 Ctrl+C 停止，然后手动运行 npm run dev" -ForegroundColor Yellow
    
    npm run dev
    
} catch {
    Write-Host "[ERROR] 修复过程中出现错误: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}