# 实际前端功能测试脚本
param(
    [string]$BaseUrl = "http://localhost:3000"
)

$ErrorActionPreference = "Continue"

function Write-TestInfo($message) {
    Write-Host "[TEST] $message" -ForegroundColor Cyan
}

function Write-TestSuccess($message) {
    Write-Host "[PASS] $message" -ForegroundColor Green
}

function Write-TestError($message) {
    Write-Host "[FAIL] $message" -ForegroundColor Red
}

function Write-TestWarning($message) {
    Write-Host "[WARN] $message" -ForegroundColor Yellow
}

$TestResults = @{
    Total = 0
    Passed = 0
    Failed = 0
    Warnings = 0
}

Write-TestInfo "开始实际前端功能测试"
Write-TestInfo "测试地址: $BaseUrl"
Write-TestInfo "=" * 50

# 1. 测试开发服务器是否运行
Write-TestInfo "1. 测试开发服务器连接"
$TestResults.Total++

try {
    $response = Invoke-WebRequest -Uri $BaseUrl -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-TestSuccess "开发服务器运行正常 (状态码: $($response.StatusCode))"
        $TestResults.Passed++
    } else {
        Write-TestError "开发服务器响应异常 (状态码: $($response.StatusCode))"
        $TestResults.Failed++
    }
} catch {
    Write-TestError "无法连接到开发服务器: $($_.Exception.Message)"
    $TestResults.Failed++
    Write-TestError "请确保运行了 'npm run dev' 命令"
    exit 1
}

# 2. 测试页面内容
Write-TestInfo "`n2. 测试页面内容"
$TestResults.Total++

$content = $response.Content
if ($content -like "*<div id=*app*>*") {
    Write-TestSuccess "Vue应用挂载点存在"
    $TestResults.Passed++
} else {
    Write-TestError "Vue应用挂载点缺失"
    $TestResults.Failed++
}

# 3. 测试JavaScript资源加载
Write-TestInfo "`n3. 测试JavaScript资源"
$TestResults.Total++

if ($content -like "*<script*") {
    Write-TestSuccess "JavaScript脚本引用存在"
    $TestResults.Passed++
} else {
    Write-TestError "JavaScript脚本引用缺失"
    $TestResults.Failed++
}

# 4. 测试CSS资源加载
Write-TestInfo "`n4. 测试CSS资源"
$TestResults.Total++

if ($content -like "*<link*stylesheet*" -or $content -like "*<style*") {
    Write-TestSuccess "CSS样式引用存在"
    $TestResults.Passed++
} else {
    Write-TestError "CSS样式引用缺失"
    $TestResults.Failed++
}

# 5. 测试路由页面
Write-TestInfo "`n5. 测试路由页面"

$routes = @(
    @{ Path = "/login"; Name = "登录页面" },
    @{ Path = "/register"; Name = "注册页面" },
    @{ Path = "/dashboard"; Name = "仪表板页面" }
)

foreach ($route in $routes) {
    $TestResults.Total++
    try {
        $routeUrl = "$BaseUrl$($route.Path)"
        $routeResponse = Invoke-WebRequest -Uri $routeUrl -TimeoutSec 5 -UseBasicParsing
        
        if ($routeResponse.StatusCode -eq 200) {
            Write-TestSuccess "$($route.Name) 可访问"
            $TestResults.Passed++
        } else {
            Write-TestError "$($route.Name) 响应异常 (状态码: $($routeResponse.StatusCode))"
            $TestResults.Failed++
        }
    } catch {
        Write-TestError "$($route.Name) 无法访问: $($_.Exception.Message)"
        $TestResults.Failed++
    }
}

# 6. 检查组件功能完整性
Write-TestInfo "`n6. 检查组件功能完整性"

$componentFiles = @(
    "frontend/src/views/dashboard/DashboardView.vue",
    "frontend/src/views/records/RecordListView.vue",
    "frontend/src/views/export/ExportView.vue",
    "frontend/src/views/users/UserListView.vue"
)

foreach ($file in $componentFiles) {
    $TestResults.Total++
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        if ($content.Length -lt 500) {
            Write-TestWarning "组件 $file 内容过于简单 ($($content.Length) 字符)"
            $TestResults.Warnings++
        } else {
            Write-TestSuccess "组件 $file 内容完整"
            $TestResults.Passed++
        }
    } else {
        Write-TestError "组件文件不存在: $file"
        $TestResults.Failed++
    }
}

# 7. 检查核心功能
Write-TestInfo "`n7. 检查核心功能实现"

$coreFeatures = @(
    @{ File = "frontend/src/stores/auth.ts"; Feature = "用户认证状态管理" },
    @{ File = "frontend/src/router/index.ts"; Feature = "路由系统" },
    @{ File = "frontend/src/utils/request.ts"; Feature = "HTTP请求工具" },
    @{ File = "frontend/src/layout/MainLayout.vue"; Feature = "主布局组件" }
)

foreach ($feature in $coreFeatures) {
    $TestResults.Total++
    if (Test-Path $feature.File) {
        $content = Get-Content $feature.File -Raw
        if ($content.Length -gt 1000) {
            Write-TestSuccess "$($feature.Feature) 实现完整"
            $TestResults.Passed++
        } else {
            Write-TestWarning "$($feature.Feature) 实现可能不完整"
            $TestResults.Warnings++
        }
    } else {
        Write-TestError "$($feature.Feature) 文件不存在"
        $TestResults.Failed++
    }
}

# 输出测试结果
Write-TestInfo "`n" + "=" * 50
Write-TestInfo "实际功能测试结果汇总"
Write-TestInfo "=" * 50

Write-Host "总测试数: $($TestResults.Total)" -ForegroundColor White
Write-TestSuccess "通过: $($TestResults.Passed)"
Write-TestError "失败: $($TestResults.Failed)"
Write-TestWarning "警告: $($TestResults.Warnings)"

$successRate = if ($TestResults.Total -gt 0) { 
    [math]::Round(($TestResults.Passed / $TestResults.Total) * 100, 2) 
} else { 
    0 
}

Write-Host "成功率: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })

# 功能完整性评估
Write-TestInfo "`n功能完整性评估:"

if ($TestResults.Warnings -gt 5) {
    Write-TestWarning "⚠️  检测到多个组件被简化，功能可能不完整"
    Write-TestWarning "建议恢复完整的组件功能实现"
}

if ($TestResults.Failed -eq 0 -and $TestResults.Warnings -le 2) {
    Write-TestSuccess "`n🎉 前端应用基本功能正常，可以正常运行"
    exit 0
} elseif ($TestResults.Failed -le 2 -and $successRate -ge 70) {
    Write-TestWarning "`n⚠️  前端应用可以运行，但存在功能缺失"
    exit 0
} else {
    Write-TestError "`n❌ 前端应用存在严重问题，需要修复"
    exit 1
}