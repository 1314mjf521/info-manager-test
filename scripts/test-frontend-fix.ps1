#!/usr/bin/env pwsh
# 测试前端修复

Write-Host "🧪 测试前端路径解析修复..." -ForegroundColor Cyan

$frontendPath = "frontend"

if (!(Test-Path $frontendPath)) {
    Write-Host "[ERROR] 前端目录不存在" -ForegroundColor Red
    exit 1
}

Push-Location $frontendPath

try {
    Write-Host "🔍 验证关键文件存在..." -ForegroundColor Yellow
    
    $keyFiles = @(
        "src/views/auth/LoginView.vue",
        "src/views/auth/RegisterView.vue", 
        "src/layout/MainLayout.vue",
        "src/views/dashboard/DashboardView.vue"
    )
    
    foreach ($file in $keyFiles) {
        if (Test-Path $file) {
            Write-Host "  ✅ $file" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $file (缺失)" -ForegroundColor Red
            exit 1
        }
    }
    
    Write-Host "🚀 启动开发服务器测试..." -ForegroundColor Yellow
    Write-Host "如果看到 'ready in' 消息，说明修复成功" -ForegroundColor Cyan
    Write-Host "按 Ctrl+C 可以停止服务器" -ForegroundColor Yellow
    
    # 启动开发服务器
    npm run dev
    
} catch {
    Write-Host "[ERROR] 测试失败: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}