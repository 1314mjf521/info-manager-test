#!/usr/bin/env pwsh
# 项目清理脚本 - 删除测试阶段产生的临时文件

Write-Host "🧹 开始清理项目..." -ForegroundColor Cyan

# 需要保留的核心脚本
$keepScripts = @(
    "one-click-deploy.ps1",
    "one-click-deploy.sh", 
    "cleanup-project.ps1",
    "build.ps1",
    "deploy.sh",
    "backup.sh",
    "health-check.sh"
)

# 需要保留的核心文档
$keepDocs = @(
    "API_DOCUMENTATION.md",
    "DEPLOYMENT_GUIDE.md", 
    "USER_MANUAL.md",
    "COMPLETE_PERMISSION_MATRIX.md"
)

# 清理scripts目录
Write-Host "📁 清理scripts目录..." -ForegroundColor Yellow
$scriptsPath = "scripts"
if (Test-Path $scriptsPath) {
    $allScripts = Get-ChildItem $scriptsPath -File
    $deletedCount = 0
    
    foreach ($script in $allScripts) {
        if ($script.Name -notin $keepScripts) {
            Remove-Item $script.FullName -Force
            Write-Host "  ❌ 删除: $($script.Name)" -ForegroundColor Red
            $deletedCount++
        } else {
            Write-Host "  ✅ 保留: $($script.Name)" -ForegroundColor Green
        }
    }
    
    Write-Host "  📊 删除了 $deletedCount 个测试脚本" -ForegroundColor Cyan
}

# 清理docs目录
Write-Host "📁 清理docs目录..." -ForegroundColor Yellow
$docsPath = "docs"
if (Test-Path $docsPath) {
    $allDocs = Get-ChildItem $docsPath -File
    $deletedCount = 0
    
    foreach ($doc in $allDocs) {
        if ($doc.Name -notin $keepDocs) {
            Remove-Item $doc.FullName -Force
            Write-Host "  ❌ 删除: $($doc.Name)" -ForegroundColor Red
            $deletedCount++
        } else {
            Write-Host "  ✅ 保留: $($doc.Name)" -ForegroundColor Green
        }
    }
    
    Write-Host "  📊 删除了 $deletedCount 个测试文档" -ForegroundColor Cyan
}

# 清理临时日志文件
Write-Host "📁 清理临时日志..." -ForegroundColor Yellow
$tempLogs = @(
    "build/logs/app.log"
)

foreach ($logFile in $tempLogs) {
    if (Test-Path $logFile) {
        Remove-Item $logFile -Force
        Write-Host "  ❌ 删除: $logFile" -ForegroundColor Red
    }
}

# 清理scripts/verify目录
$verifyPath = "scripts/verify"
if (Test-Path $verifyPath) {
    Remove-Item $verifyPath -Recurse -Force
    Write-Host "  ❌ 删除目录: scripts/verify" -ForegroundColor Red
}

# 清理备份文件
Write-Host "📁 清理备份文件..." -ForegroundColor Yellow
$backupFiles = Get-ChildItem -Recurse -File | Where-Object { 
    $_.Name -like "*.backup*" -or 
    $_.Name -like "*.bak" -or
    $_.Name -like "*~" 
}

foreach ($backup in $backupFiles) {
    Remove-Item $backup.FullName -Force
    Write-Host "  ❌ 删除备份: $($backup.Name)" -ForegroundColor Red
}

# 显示清理后的项目结构
Write-Host ""
Write-Host "🎯 清理完成！当前项目结构:" -ForegroundColor Green
Write-Host ""

Write-Host "📂 保留的核心脚本:" -ForegroundColor Cyan
foreach ($script in $keepScripts) {
    if (Test-Path "scripts/$script") {
        Write-Host "  ✅ scripts/$script" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "📂 保留的核心文档:" -ForegroundColor Cyan
foreach ($doc in $keepDocs) {
    if (Test-Path "docs/$doc") {
        Write-Host "  ✅ docs/$doc" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "📂 项目核心文件:" -ForegroundColor Cyan
$coreFiles = @(
    "README.md",
    "go.mod", 
    "go.sum",
    "configs/config.example.yaml"
)

foreach ($file in $coreFiles) {
    if (Test-Path $file) {
        Write-Host "  ✅ $file" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "🎉 项目清理完成！项目现在干净整洁，可以投入生产使用。" -ForegroundColor Green
Write-Host ""
Write-Host "📋 下一步操作建议:" -ForegroundColor Yellow
Write-Host "  1. 提交清理后的代码到版本控制系统" -ForegroundColor White
Write-Host "  2. 创建发布标签 (如: v1.0.0)" -ForegroundColor White
Write-Host "  3. 使用一键部署脚本部署到生产环境" -ForegroundColor White
Write-Host "  4. 配置监控和备份" -ForegroundColor White