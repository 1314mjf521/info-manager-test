#!/usr/bin/env pwsh
# 修复所有前端文件中的@/导入路径

Write-Host "🔧 修复所有前端文件中的@/导入路径..." -ForegroundColor Cyan

$frontendPath = "frontend"

if (!(Test-Path $frontendPath)) {
    Write-Host "[ERROR] 前端目录不存在" -ForegroundColor Red
    exit 1
}

Push-Location $frontendPath

try {
    Write-Host "📝 批量修复所有Vue和TypeScript文件中的@/导入..." -ForegroundColor Yellow
    
    # 获取所有需要修复的文件
    $files = Get-ChildItem -Path "src" -Recurse -Include "*.vue", "*.ts" | Where-Object { $_.Name -ne "env.d.ts" }
    
    $totalFiles = $files.Count
    $processedFiles = 0
    
    foreach ($file in $files) {
        $processedFiles++
        $relativePath = $file.FullName.Replace((Get-Location).Path + "\src\", "")
        Write-Progress -Activity "修复导入路径" -Status "处理文件: $relativePath" -PercentComplete (($processedFiles / $totalFiles) * 100)
        
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($content -and $content.Contains("@/")) {
            $originalContent = $content
            
            # 计算相对路径深度
            $depth = ($file.DirectoryName.Replace((Get-Location).Path + "\src", "").Split('\') | Where-Object { $_ -ne "" }).Count
            $relativePath = "../" * $depth
            if ($depth -eq 0) { $relativePath = "./" }
            
            # 替换所有的@/导入
            $content = $content -replace "@/utils/", "${relativePath}utils/"
            $content = $content -replace "@/stores/", "${relativePath}stores/"
            $content = $content -replace "@/config/", "${relativePath}config/"
            $content = $content -replace "@/types", "${relativePath}types"
            $content = $content -replace "@/api/", "${relativePath}api/"
            $content = $content -replace "@/components/", "${relativePath}components/"
            $content = $content -replace "@/layout/", "${relativePath}layout/"
            $content = $content -replace "@/views/", "${relativePath}views/"
            $content = $content -replace "@/router", "${relativePath}router"
            
            # 只有内容发生变化时才写入文件
            if ($content -ne $originalContent) {
                $content | Out-File -FilePath $file.FullName -Encoding UTF8
                Write-Host "  ✅ 修复: $($file.Name)" -ForegroundColor Green
            }
        }
    }
    
    Write-Progress -Activity "修复导入路径" -Completed
    
    Write-Host "🧹 清理缓存..." -ForegroundColor Yellow
    
    # 清理 Vite 缓存
    if (Test-Path "node_modules/.vite") {
        Remove-Item "node_modules/.vite" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ 清理 Vite 缓存" -ForegroundColor Green
    }
    
    # 清理其他缓存
    $cacheFiles = @("dist", ".tsbuildinfo", "tsconfig.tsbuildinfo")
    foreach ($cache in $cacheFiles) {
        if (Test-Path $cache) {
            Remove-Item $cache -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  ✅ 清理: $cache" -ForegroundColor Green
        }
    }
    
    Write-Host "✅ 所有导入路径修复完成！" -ForegroundColor Green
    Write-Host "📊 处理了 $processedFiles 个文件" -ForegroundColor Cyan
    
    Write-Host "🚀 启动开发服务器..." -ForegroundColor Yellow
    npm run dev
    
} catch {
    Write-Host "[ERROR] 修复失败: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}