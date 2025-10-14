# 前端登录跳转功能测试脚本
# 测试日期: 2025-01-04

Write-Host "=== 前端登录跳转功能测试 ===" -ForegroundColor Green
Write-Host "测试时间: $(Get-Date)" -ForegroundColor Gray

# 测试配置
$frontendUrl = "http://localhost:3000"
$testTimeout = 10

Write-Host "`n1. 检查前端开发服务器状态..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri $frontendUrl -TimeoutSec $testTimeout -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ 前端服务器运行正常 (状态码: $($response.StatusCode))" -ForegroundColor Green
        Write-Host "   响应大小: $($response.Content.Length) 字符" -ForegroundColor Gray
    } else {
        Write-Host "❌ 前端服务器响应异常 (状态码: $($response.StatusCode))" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ 无法连接到前端服务器: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   请确认开发服务器已启动: npm run dev" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n2. 测试关键路由访问..." -ForegroundColor Yellow

$routes = @(
    @{ path = "/"; name = "首页" },
    @{ path = "/login"; name = "登录页" },
    @{ path = "/register"; name = "注册页" },
    @{ path = "/dashboard"; name = "仪表板" },
    @{ path = "/records"; name = "记录管理" }
)

$routeResults = @()

foreach ($route in $routes) {
    try {
        $url = "$frontendUrl$($route.path)"
        $response = Invoke-WebRequest -Uri $url -TimeoutSec $testTimeout -UseBasicParsing
        $status = if ($response.StatusCode -eq 200) { "✅" } else { "❌" }
        $routeResults += @{
            Path = $route.path
            Name = $route.name
            Status = $response.StatusCode
            Size = $response.Content.Length
            Success = $response.StatusCode -eq 200
        }
        Write-Host "   $status $($route.name) ($($route.path)) - $($response.StatusCode) - $($response.Content.Length) 字符" -ForegroundColor $(if ($response.StatusCode -eq 200) { "Green" } else { "Red" })
    } catch {
        $routeResults += @{
            Path = $route.path
            Name = $route.name
            Status = "Error"
            Size = 0
            Success = $false
        }
        Write-Host "   ❌ $($route.name) ($($route.path)) - 错误: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n3. 检查前端配置文件..." -ForegroundColor Yellow

$configFiles = @(
    "frontend/src/config/api.ts",
    "frontend/src/stores/auth.ts",
    "frontend/src/router/index.ts",
    "frontend/src/views/auth/LoginView.vue"
)

$configResults = @()

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        $size = $content.Length
        $configResults += @{
            File = $file
            Exists = $true
            Size = $size
        }
        Write-Host "   ✅ $file - $size 字符" -ForegroundColor Green
        
        # 检查关键配置
        if ($file -eq "frontend/src/config/api.ts") {
            if ($content -match "BASE_URL.*localhost:8080") {
                Write-Host "      ✅ API地址配置正确 (localhost:8080)" -ForegroundColor Green
            } else {
                Write-Host "      ⚠️  API地址可能需要检查" -ForegroundColor Yellow
            }
        }
        
        if ($file -eq "frontend/src/views/auth/LoginView.vue") {
            if ($content -match "router\.push|router\.replace") {
                Write-Host "      ✅ 包含路由跳转逻辑" -ForegroundColor Green
            } else {
                Write-Host "      ❌ 缺少路由跳转逻辑" -ForegroundColor Red
            }
        }
    } else {
        $configResults += @{
            File = $file
            Exists = $false
            Size = 0
        }
        Write-Host "   ❌ $file - 文件不存在" -ForegroundColor Red
    }
}

Write-Host "`n4. 检查后端API连接..." -ForegroundColor Yellow

$backendUrl = "http://localhost:8080"
try {
    $response = Invoke-WebRequest -Uri "$backendUrl/api/v1/system/health" -TimeoutSec 5 -UseBasicParsing
    Write-Host "   ✅ 后端API服务正常 (状态码: $($response.StatusCode))" -ForegroundColor Green
    $backendAvailable = $true
} catch {
    Write-Host "   ❌ 后端API服务不可用: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "      这可能导致登录功能无法正常工作" -ForegroundColor Yellow
    $backendAvailable = $false
}

Write-Host "`n=== 测试结果汇总 ===" -ForegroundColor Green

$successfulRoutes = ($routeResults | Where-Object { $_.Success }).Count
$totalRoutes = $routeResults.Count
$configFilesExist = ($configResults | Where-Object { $_.Exists }).Count
$totalConfigFiles = $configResults.Count

Write-Host "路由访问: $successfulRoutes/$totalRoutes 成功" -ForegroundColor $(if ($successfulRoutes -eq $totalRoutes) { "Green" } else { "Yellow" })
Write-Host "配置文件: $configFilesExist/$totalConfigFiles 存在" -ForegroundColor $(if ($configFilesExist -eq $totalConfigFiles) { "Green" } else { "Red" })
Write-Host "后端连接: $(if ($backendAvailable) { '可用' } else { '不可用' })" -ForegroundColor $(if ($backendAvailable) { "Green" } else { "Red" })

Write-Host "`n=== 登录跳转问题诊断 ===" -ForegroundColor Cyan

if (-not $backendAvailable) {
    Write-Host "🔍 主要问题: 后端API服务不可用" -ForegroundColor Red
    Write-Host "   解决方案: 启动后端服务器 (端口8080)" -ForegroundColor Yellow
    Write-Host "   命令: go run cmd/server/main.go 或 ./start.bat" -ForegroundColor Gray
}

if ($successfulRoutes -lt $totalRoutes) {
    Write-Host "🔍 路由问题: 部分路由无法访问" -ForegroundColor Yellow
    Write-Host "   这可能是正常的，因为某些路由需要认证" -ForegroundColor Gray
}

Write-Host "`n=== 建议的测试步骤 ===" -ForegroundColor Cyan
Write-Host "1. 确保后端服务器运行在 localhost:8080" -ForegroundColor White
Write-Host "2. 在浏览器中访问 http://localhost:3000/login" -ForegroundColor White
Write-Host "3. 输入测试用户名和密码进行登录" -ForegroundColor White
Write-Host "4. 观察浏览器控制台的调试信息" -ForegroundColor White
Write-Host "5. 检查登录成功后是否正确跳转到首页" -ForegroundColor White

Write-Host "`n测试完成时间: $(Get-Date)" -ForegroundColor Gray