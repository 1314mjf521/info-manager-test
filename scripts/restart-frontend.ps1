#!/usr/bin/env pwsh
# 重启前端开发服务器

Write-Host "🔄 重启前端开发服务器..." -ForegroundColor Cyan

$frontendPath = "frontend"

if (!(Test-Path $frontendPath)) {
    Write-Host "[ERROR] 前端目录不存在" -ForegroundColor Red
    exit 1
}

Push-Location $frontendPath

try {
    Write-Host "🛑 停止现有的开发服务器..." -ForegroundColor Yellow
    
    # 尝试停止可能运行的 npm 进程
    Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -eq "node" } | Stop-Process -Force -ErrorAction SilentlyContinue
    
    Write-Host "🧹 清理所有缓存..." -ForegroundColor Yellow
    
    # 删除 Vite 缓存
    if (Test-Path "node_modules\.vite") {
        Remove-Item "node_modules\.vite" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ 清理 Vite 缓存" -ForegroundColor Green
    }
    
    # 删除构建输出
    if (Test-Path "dist") {
        Remove-Item "dist" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ 清理构建输出" -ForegroundColor Green
    }
    
    # 删除 TypeScript 缓存
    if (Test-Path ".tsbuildinfo") {
        Remove-Item ".tsbuildinfo" -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ 清理 TypeScript 缓存" -ForegroundColor Green
    }
    
    # 删除其他可能的缓存文件
    $cacheFiles = @(".eslintcache", "tsconfig.tsbuildinfo", "vite.config.js.timestamp*")
    foreach ($pattern in $cacheFiles) {
        Get-ChildItem -Path . -Name $pattern -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item $_ -Force -ErrorAction SilentlyContinue
            Write-Host "  ✅ 清理缓存文件: $_" -ForegroundColor Green
        }
    }
    
    Write-Host "🔍 验证关键文件..." -ForegroundColor Yellow
    
    # 检查关键文件
    $keyFiles = @(
        "src/views/auth/LoginView.vue",
        "src/layout/MainLayout.vue",
        "src/stores/auth.ts",
        "src/utils/request.ts",
        "src/config/api.ts",
        "src/types/index.ts"
    )
    
    $allFilesExist = $true
    foreach ($file in $keyFiles) {
        if (Test-Path $file) {
            Write-Host "  ✅ $file" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $file (缺失)" -ForegroundColor Red
            $allFilesExist = $false
        }
    }
    
    if (!$allFilesExist) {
        Write-Host "[ERROR] 发现缺失的关键文件" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "📦 重新安装依赖..." -ForegroundColor Yellow
    npm install --force
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] 依赖安装失败" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  ✅ 依赖安装完成" -ForegroundColor Green
    
    Write-Host "🚀 启动开发服务器..." -ForegroundColor Yellow
    Write-Host "如果仍有问题，请按 Ctrl+C 停止并检查错误信息" -ForegroundColor Cyan
    
    # 启动开发服务器
    npm run dev
    
} catch {
    Write-Host "[ERROR] 重启过程中出现错误: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}