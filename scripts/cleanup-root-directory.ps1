#!/usr/bin/env pwsh
# 根目录清理脚本 - 清理项目根目录的临时文件和测试文件

Write-Host "🧹 开始清理项目根目录..." -ForegroundColor Cyan

# 需要保留的核心文件
$keepFiles = @(
    # Go项目核心文件
    "go.mod",
    "go.sum",
    "Makefile",
    "Dockerfile",
    
    # 配置文件
    ".env.example",
    ".gitignore",
    ".gitattributes",
    
    # 文档文件
    "README.md",
    
    # Docker配置
    "docker-compose.yml"
)

# 需要保留的核心目录
$keepDirectories = @(
    ".git",
    ".vscode",
    "cmd",
    "internal", 
    "configs",
    "docs",
    "scripts",
    "data",
    "logs",
    "uploads",
    "build"
)

# 需要删除的临时文件和测试文件
$deleteFiles = @(
    # 临时可执行文件
    "info-management-system.exe",
    "server.exe",
    
    # 临时批处理文件
    "build.bat",
    "deploy-now.bat", 
    "rebuild-and-start.bat",
    "start.bat",
    
    # 临时日志文件
    "admin_server.log",
    "debug_server.log",
    
    # 测试文件
    "test-file.txt",
    "test-permission-tree.html",
    "check_permissions.go",
    
    # 临时文档
    "PERMISSION_FIX_GUIDE.md",
    "PROJECT_STRUCTURE.md", 
    "README_Windows.md",
    
    # 临时配置文件
    ".env",
    "docker-compose.elasticsearch.yml",
    
    # CSV模板文件（移动到templates目录）
    "工单导入模板.csv",
    "记录导入模板.csv"
)

# 需要删除的临时目录
$deleteDirectories = @(
    "backend_fixes",
    "deployments",
    "exports", 
    "frontend",
    "test",
    ".kiro"
)

Write-Host "📁 清理临时文件..." -ForegroundColor Yellow

$deletedFilesCount = 0
foreach ($file in $deleteFiles) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        Write-Host "  ❌ 删除文件: $file" -ForegroundColor Red
        $deletedFilesCount++
    }
}

Write-Host "📁 清理临时目录..." -ForegroundColor Yellow

$deletedDirsCount = 0
foreach ($dir in $deleteDirectories) {
    if (Test-Path $dir) {
        Remove-Item $dir -Recurse -Force
        Write-Host "  ❌ 删除目录: $dir" -ForegroundColor Red
        $deletedDirsCount++
    }
}

# 创建templates目录并移动CSV模板文件（如果存在的话）
if ((Test-Path "工单导入模板.csv") -or (Test-Path "记录导入模板.csv")) {
    Write-Host "📁 创建templates目录..." -ForegroundColor Yellow
    
    if (!(Test-Path "templates")) {
        New-Item -ItemType Directory -Path "templates" -Force | Out-Null
        Write-Host "  ✅ 创建目录: templates" -ForegroundColor Green
    }
    
    if (Test-Path "工单导入模板.csv") {
        Move-Item "工单导入模板.csv" "templates/" -Force
        Write-Host "  📦 移动: 工单导入模板.csv -> templates/" -ForegroundColor Cyan
    }
    
    if (Test-Path "记录导入模板.csv") {
        Move-Item "记录导入模板.csv" "templates/" -Force
        Write-Host "  📦 移动: 记录导入模板.csv -> templates/" -ForegroundColor Cyan
    }
}

# 清理空目录
Write-Host "📁 清理空目录..." -ForegroundColor Yellow
$emptyDirs = Get-ChildItem -Directory | Where-Object { 
    (Get-ChildItem $_.FullName -Recurse -Force | Measure-Object).Count -eq 0 
}

foreach ($emptyDir in $emptyDirs) {
    if ($emptyDir.Name -notin $keepDirectories) {
        Remove-Item $emptyDir.FullName -Force
        Write-Host "  ❌ 删除空目录: $($emptyDir.Name)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "🎯 根目录清理完成！" -ForegroundColor Green
Write-Host "  📊 删除了 $deletedFilesCount 个临时文件" -ForegroundColor Cyan
Write-Host "  📊 删除了 $deletedDirsCount 个临时目录" -ForegroundColor Cyan

Write-Host ""
Write-Host "📂 当前项目结构:" -ForegroundColor Cyan

# 显示清理后的根目录结构
Write-Host ""
Write-Host "📁 核心目录:" -ForegroundColor Yellow
$coreDirectories = Get-ChildItem -Directory | Where-Object { $_.Name -in $keepDirectories }
foreach ($dir in $coreDirectories) {
    Write-Host "  ✅ $($dir.Name)/" -ForegroundColor Green
}

Write-Host ""
Write-Host "📄 核心文件:" -ForegroundColor Yellow
$coreFiles = Get-ChildItem -File | Where-Object { $_.Name -in $keepFiles }
foreach ($file in $coreFiles) {
    Write-Host "  ✅ $($file.Name)" -ForegroundColor Green
}

# 检查是否有templates目录
if (Test-Path "templates") {
    Write-Host ""
    Write-Host "📁 模板目录:" -ForegroundColor Yellow
    $templateFiles = Get-ChildItem "templates" -File
    foreach ($template in $templateFiles) {
        Write-Host "  📋 templates/$($template.Name)" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "🎉 项目根目录现在干净整洁！" -ForegroundColor Green
Write-Host ""
Write-Host "📋 项目现在的标准结构:" -ForegroundColor Yellow
Write-Host "  📁 cmd/           - 应用程序入口" -ForegroundColor White
Write-Host "  📁 internal/      - 内部代码包" -ForegroundColor White  
Write-Host "  📁 configs/       - 配置文件" -ForegroundColor White
Write-Host "  📁 docs/          - 文档" -ForegroundColor White
Write-Host "  📁 scripts/       - 部署脚本" -ForegroundColor White
Write-Host "  📁 data/          - 数据文件" -ForegroundColor White
Write-Host "  📁 logs/          - 日志文件" -ForegroundColor White
Write-Host "  📁 uploads/       - 上传文件" -ForegroundColor White
Write-Host "  📁 build/         - 编译输出" -ForegroundColor White
Write-Host "  📄 go.mod         - Go模块文件" -ForegroundColor White
Write-Host "  📄 go.sum         - Go依赖锁定" -ForegroundColor White
Write-Host "  📄 README.md      - 项目说明" -ForegroundColor White
Write-Host "  📄 Dockerfile     - Docker配置" -ForegroundColor White
Write-Host "  📄 Makefile       - 构建脚本" -ForegroundColor White