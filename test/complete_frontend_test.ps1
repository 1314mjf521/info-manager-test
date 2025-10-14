# 完整的前端测试脚本
param(
    [string]$BuildPath = "build\frontend",
    [int]$TestPort = 8001
)

$ErrorActionPreference = "Stop"

function Write-TestInfo($message) {
    Write-Host "[TEST] $message" -ForegroundColor Cyan
}

function Write-TestSuccess($message) {
    Write-Host "[PASS] $message" -ForegroundColor Green
}

function Write-TestError($message) {
    Write-Host "[FAIL] $message" -ForegroundColor Red
}

$TestResults = @{
    Total = 0
    Passed = 0
    Failed = 0
}

function Test-Condition {
    param(
        [string]$Name,
        [scriptblock]$Condition,
        [string]$ErrorMessage = "Test failed"
    )
    
    $TestResults.Total++
    
    try {
        $result = & $Condition
        if ($result) {
            Write-TestSuccess "$Name"
            $TestResults.Passed++
            return $true
        } else {
            Write-TestError "$Name - $ErrorMessage"
            $TestResults.Failed++
            return $false
        }
    } catch {
        Write-TestError "$Name - Exception: $($_.Exception.Message)"
        $TestResults.Failed++
        return $false
    }
}

Write-TestInfo "开始完整前端测试"
Write-TestInfo "构建路径: $BuildPath"
Write-TestInfo "测试端口: $TestPort"
Write-Host "=" * 60

# 1. 文件存在性测试
Write-TestInfo "1. 文件存在性测试"
Test-Condition "构建目录存在" { Test-Path $BuildPath }
Test-Condition "index.html存在" { Test-Path "$BuildPath\index.html" }

$jsFiles = Get-ChildItem "$BuildPath\assets" -Filter "*.js" -ErrorAction SilentlyContinue
$cssFiles = Get-ChildItem "$BuildPath\assets" -Filter "*.css" -ErrorAction SilentlyContinue

Test-Condition "JavaScript文件存在" { $jsFiles.Count -gt 0 } "未找到JS文件"
Test-Condition "CSS文件存在" { $cssFiles.Count -gt 0 } "未找到CSS文件"

# 2. 文件内容测试
Write-TestInfo "`n2. 文件内容测试"
$indexContent = Get-Content "$BuildPath\index.html" -Raw -ErrorAction SilentlyContinue

Test-Condition "HTML文档类型正确" { $indexContent -like "*<!DOCTYPE html>*" }
Test-Condition "Vue挂载点存在" { $indexContent -like "*<div id=*app*>*" }
Test-Condition "JavaScript引用存在" { $indexContent -like "*<script*" }
Test-Condition "CSS引用存在" { $indexContent -like "*<link*stylesheet*" }

# 3. 启动HTTP服务器测试
Write-TestInfo "`n3. HTTP服务器测试"

$serverJob = $null
try {
    # 启动Python HTTP服务器
    $serverJob = Start-Job -ScriptBlock {
        param($path, $port)
        Set-Location $path
        python -m http.server $port
    } -ArgumentList (Resolve-Path $BuildPath), $TestPort
    
    # 等待服务器启动
    Start-Sleep -Seconds 3
    
    $baseUrl = "http://localhost:$TestPort"
    
    # 测试主页
    try {
        $response = Invoke-WebRequest -Uri $baseUrl -TimeoutSec 10 -UseBasicParsing
        Test-Condition "主页HTTP响应正常" { $response.StatusCode -eq 200 }
        Test-Condition "主页内容包含Vue应用" { $response.Content -like "*<div id=*app*>*" }
    } catch {
        Write-TestError "无法访问主页: $($_.Exception.Message)"
        $TestResults.Failed += 2
        $TestResults.Total += 2
    }
    
    # 测试静态资源
    $mainJsFile = $jsFiles | Where-Object { $_.Name -like "*index-*.js" } | Select-Object -First 1
    if ($mainJsFile) {
        try {
            $jsUrl = "$baseUrl/assets/$($mainJsFile.Name)"
            $jsResponse = Invoke-WebRequest -Uri $jsUrl -TimeoutSec 10 -UseBasicParsing
            Test-Condition "主JS文件可访问" { $jsResponse.StatusCode -eq 200 }
        } catch {
            Write-TestError "无法访问JS文件: $($_.Exception.Message)"
            $TestResults.Failed++
        }
        $TestResults.Total++
    }
    
    $mainCssFile = $cssFiles | Where-Object { $_.Name -like "*index-*.css" } | Select-Object -First 1
    if ($mainCssFile) {
        try {
            $cssUrl = "$baseUrl/assets/$($mainCssFile.Name)"
            $cssResponse = Invoke-WebRequest -Uri $cssUrl -TimeoutSec 10 -UseBasicParsing
            Test-Condition "主CSS文件可访问" { $cssResponse.StatusCode -eq 200 }
        } catch {
            Write-TestError "无法访问CSS文件: $($_.Exception.Message)"
            $TestResults.Failed++
        }
        $TestResults.Total++
    }
    
} finally {
    # 停止HTTP服务器
    if ($serverJob) {
        Stop-Job $serverJob -ErrorAction SilentlyContinue
        Remove-Job $serverJob -ErrorAction SilentlyContinue
    }
}

# 4. 构建统计
Write-TestInfo "`n4. 构建统计"
$allFiles = Get-ChildItem $BuildPath -Recurse -File
$totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)

Write-Host "文件总数: $($allFiles.Count)" -ForegroundColor Yellow
Write-Host "总大小: $totalSizeMB MB" -ForegroundColor Yellow
Write-Host "JS文件数: $($jsFiles.Count)" -ForegroundColor Yellow
Write-Host "CSS文件数: $($cssFiles.Count)" -ForegroundColor Yellow

Test-Condition "文件数量合理" { $allFiles.Count -gt 10 -and $allFiles.Count -lt 200 }
Test-Condition "总大小合理" { $totalSizeMB -gt 0.5 -and $totalSizeMB -lt 50 }

# 5. 开发服务器测试
Write-TestInfo "`n5. 开发服务器测试"
$devServerJob = $null
try {
    # 启动开发服务器
    $devServerJob = Start-Job -ScriptBlock {
        Set-Location "frontend"
        npm run dev
    }
    
    # 等待开发服务器启动
    Start-Sleep -Seconds 10
    
    try {
        $devResponse = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -UseBasicParsing
        Test-Condition "开发服务器可访问" { $devResponse.StatusCode -eq 200 }
    } catch {
        Write-TestError "开发服务器无法访问: $($_.Exception.Message)"
        $TestResults.Failed++
    }
    $TestResults.Total++
    
} finally {
    # 停止开发服务器
    if ($devServerJob) {
        Stop-Job $devServerJob -ErrorAction SilentlyContinue
        Remove-Job $devServerJob -ErrorAction SilentlyContinue
    }
}

# 输出测试结果
Write-Host "`n" + "=" * 60
Write-TestInfo "测试结果汇总"
Write-Host "=" * 60

Write-Host "总测试数: $($TestResults.Total)" -ForegroundColor White
Write-TestSuccess "通过: $($TestResults.Passed)"
Write-TestError "失败: $($TestResults.Failed)"

$successRate = if ($TestResults.Total -gt 0) { 
    [math]::Round(($TestResults.Passed / $TestResults.Total) * 100, 2) 
} else { 
    0 
}

Write-Host "成功率: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })

if ($TestResults.Failed -eq 0) {
    Write-TestSuccess "`n🎉 所有测试通过！前端应用构建和运行正常。"
    exit 0
} elseif ($successRate -ge 80) {
    Write-Host "`n⚠️  大部分测试通过，前端应用基本正常。" -ForegroundColor Yellow
    exit 0
} else {
    Write-TestError "`n❌ 测试失败较多，前端应用可能存在问题。"
    exit 1
}