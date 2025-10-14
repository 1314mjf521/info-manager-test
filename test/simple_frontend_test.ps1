# 简单的前端构建测试脚本

param(
    [string]$BuildPath = "build\frontend"
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 颜色输出函数
function Write-Info($message) {
    Write-Host "[INFO] $message" -ForegroundColor Green
}

function Write-Success($message) {
    Write-Host "[SUCCESS] $message" -ForegroundColor Cyan
}

function Write-Error($message) {
    Write-Host "[ERROR] $message" -ForegroundColor Red
}

# 测试结果统计
$TestResults = @{
    Total = 0
    Passed = 0
    Failed = 0
}

function Test-File {
    param(
        [string]$Name,
        [string]$Path
    )
    
    $TestResults.Total++
    
    if (Test-Path $Path) {
        Write-Success "✓ $Name - 文件存在"
        $TestResults.Passed++
        return $true
    } else {
        Write-Error "✗ $Name - 文件不存在: $Path"
        $TestResults.Failed++
        return $false
    }
}

# 开始测试
Write-Info "开始前端构建测试"
Write-Info "构建路径: $BuildPath"
Write-Info "=" * 50

# 1. 测试构建目录是否存在
Write-Info "1. 测试构建目录"
Test-File -Name "构建目录" -Path $BuildPath

# 2. 测试核心文件
Write-Info "`n2. 测试核心文件"
$indexPath = Join-Path $BuildPath "index.html"
Test-File -Name "index.html" -Path $indexPath

# 3. 测试资源文件
Write-Info "`n3. 测试资源文件"
$jsFiles = Get-ChildItem -Path $BuildPath -Filter "*.js" -File
$cssFiles = Get-ChildItem -Path $BuildPath -Filter "*.css" -File

if ($jsFiles.Count -gt 0) {
    Write-Success "✓ JavaScript文件 - 找到 $($jsFiles.Count) 个文件"
    $TestResults.Passed++
} else {
    Write-Error "✗ JavaScript文件 - 未找到JS文件"
    $TestResults.Failed++
}
$TestResults.Total++

if ($cssFiles.Count -gt 0) {
    Write-Success "✓ CSS文件 - 找到 $($cssFiles.Count) 个文件"
    $TestResults.Passed++
} else {
    Write-Error "✗ CSS文件 - 未找到CSS文件"
    $TestResults.Failed++
}
$TestResults.Total++

# 4. 测试文件大小
Write-Info "`n4. 测试文件大小"
if (Test-Path $indexPath) {
    $indexSize = (Get-Item $indexPath).Length
    if ($indexSize -gt 0) {
        Write-Success "✓ index.html大小: $indexSize 字节"
        $TestResults.Passed++
    } else {
        Write-Error "✗ index.html文件为空"
        $TestResults.Failed++
    }
    $TestResults.Total++
}

# 5. 计算总文件大小
Write-Info "`n5. 构建统计"
$allFiles = Get-ChildItem -Path $BuildPath -Recurse -File
$totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)

Write-Info "总文件数: $($allFiles.Count)"
Write-Info "总大小: $totalSizeMB MB"

# 6. 检查index.html内容
Write-Info "`n6. 检查index.html内容"
if (Test-Path $indexPath) {
    $content = Get-Content $indexPath -Raw
    
    if ($content -like "*<!DOCTYPE html>*") {
        Write-Success "✓ HTML文档类型声明存在"
        $TestResults.Passed++
    } else {
        Write-Error "✗ HTML文档类型声明缺失"
        $TestResults.Failed++
    }
    $TestResults.Total++
    
    if ($content -like "*<div id=*app*>*") {
        Write-Success "✓ Vue应用挂载点存在"
        $TestResults.Passed++
    } else {
        Write-Error "✗ Vue应用挂载点缺失"
        $TestResults.Failed++
    }
    $TestResults.Total++
    
    if ($content -like "*<script*") {
        Write-Success "✓ JavaScript脚本引用存在"
        $TestResults.Passed++
    } else {
        Write-Error "✗ JavaScript脚本引用缺失"
        $TestResults.Failed++
    }
    $TestResults.Total++
}

# 输出测试结果
Write-Info "`n" + "=" * 50
Write-Info "测试结果汇总"
Write-Info "=" * 50

Write-Info "总测试数: $($TestResults.Total)"
Write-Success "通过: $($TestResults.Passed)"
Write-Error "失败: $($TestResults.Failed)"

$successRate = if ($TestResults.Total -gt 0) { 
    [math]::Round(($TestResults.Passed / $TestResults.Total) * 100, 2) 
} else { 
    0 
}

Write-Info "成功率: $successRate%"

if ($TestResults.Failed -eq 0) {
    Write-Success "`n🎉 所有测试通过！前端构建成功。"
    exit 0
} elseif ($successRate -ge 80) {
    Write-Host "`n⚠️  大部分测试通过，但有一些问题需要注意。" -ForegroundColor Yellow
    exit 0
} else {
    Write-Error "`n❌ 测试失败较多，请检查前端构建配置。"
    exit 1
}