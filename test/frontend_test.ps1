# 前端功能测试脚本
# 测试前端应用的各项功能

param(
    [string]$BaseUrl = "http://localhost:3000",
    [string]$ApiUrl = "http://192.168.100.15:8080/api/v1",
    [switch]$Verbose = $false
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 颜色输出函数
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Info($message) {
    Write-ColorOutput Green "[INFO] $message"
}

function Write-Warning($message) {
    Write-ColorOutput Yellow "[WARN] $message"
}

function Write-Error($message) {
    Write-ColorOutput Red "[ERROR] $message"
}

function Write-Success($message) {
    Write-ColorOutput Cyan "[SUCCESS] $message"
}

# 测试结果统计
$TestResults = @{
    Total = 0
    Passed = 0
    Failed = 0
    Skipped = 0
}

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Method = "GET",
        [hashtable]$Headers = @{},
        [object]$Body = $null,
        [int]$ExpectedStatus = 200
    )
    
    $TestResults.Total++
    
    try {
        Write-Info "测试: $Name"
        Write-Info "URL: $Url"
        
        $params = @{
            Uri = $Url
            Method = $Method
            Headers = $Headers
            UseBasicParsing = $true
        }
        
        if ($Body) {
            $params.Body = $Body | ConvertTo-Json
            $params.ContentType = "application/json"
        }
        
        $response = Invoke-WebRequest @params
        
        if ($response.StatusCode -eq $ExpectedStatus) {
            Write-Success "✓ $Name - 状态码: $($response.StatusCode)"
            $TestResults.Passed++
            return $true
        } else {
            Write-Error "✗ $Name - 期望状态码: $ExpectedStatus, 实际: $($response.StatusCode)"
            $TestResults.Failed++
            return $false
        }
        
    } catch {
        Write-Error "✗ $Name - 错误: $($_.Exception.Message)"
        $TestResults.Failed++
        return $false
    }
}

function Test-FrontendPage {
    param(
        [string]$Name,
        [string]$Path,
        [string[]]$ExpectedContent = @()
    )
    
    $TestResults.Total++
    
    try {
        $url = "$BaseUrl$Path"
        Write-Info "测试页面: $Name"
        Write-Info "URL: $url"
        
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing
        
        if ($response.StatusCode -eq 200) {
            $content = $response.Content
            $allContentFound = $true
            
            foreach ($expectedText in $ExpectedContent) {
                if ($content -notlike "*$expectedText*") {
                    Write-Warning "页面缺少预期内容: $expectedText"
                    $allContentFound = $false
                }
            }
            
            if ($allContentFound) {
                Write-Success "✓ $Name - 页面加载成功，内容完整"
                $TestResults.Passed++
                return $true
            } else {
                Write-Error "✗ $Name - 页面内容不完整"
                $TestResults.Failed++
                return $false
            }
        } else {
            Write-Error "✗ $Name - 状态码: $($response.StatusCode)"
            $TestResults.Failed++
            return $false
        }
        
    } catch {
        Write-Error "✗ $Name - 错误: $($_.Exception.Message)"
        $TestResults.Failed++
        return $false
    }
}

# 开始测试
Write-Info "开始前端功能测试"
Write-Info "前端地址: $BaseUrl"
Write-Info "API地址: $ApiUrl"
Write-Info "=" * 50

# 1. 测试前端服务是否运行
Write-Info "1. 测试前端服务连接"
Test-FrontendPage -Name "前端首页" -Path "/" -ExpectedContent @("信息管理系统")

# 2. 测试静态资源
Write-Info "`n2. 测试静态资源"
Test-Endpoint -Name "CSS资源" -Url "$BaseUrl/assets/index.css" -ExpectedStatus 200
Test-Endpoint -Name "JS资源" -Url "$BaseUrl/assets/index.js" -ExpectedStatus 200

# 3. 测试路由页面
Write-Info "`n3. 测试路由页面"
$routes = @(
    @{ Name = "登录页面"; Path = "/login"; Content = @("登录", "用户名", "密码") },
    @{ Name = "注册页面"; Path = "/register"; Content = @("注册", "用户名", "邮箱") }
)

foreach ($route in $routes) {
    Test-FrontendPage -Name $route.Name -Path $route.Path -ExpectedContent $route.Content
}

# 4. 测试API连接
Write-Info "`n4. 测试API连接"
Test-Endpoint -Name "API健康检查" -Url "$ApiUrl/health" -ExpectedStatus 200

# 5. 测试认证API
Write-Info "`n5. 测试认证相关API"

# 测试登录API（预期失败，因为没有提供凭据）
try {
    $loginData = @{
        username = "test"
        password = "test"
    }
    
    Test-Endpoint -Name "登录API" -Url "$ApiUrl/auth/login" -Method "POST" -Body $loginData -ExpectedStatus 401
} catch {
    Write-Warning "登录API测试跳过（可能后端未运行）"
    $TestResults.Skipped++
}

# 6. 测试记录管理API
Write-Info "`n6. 测试记录管理API"
try {
    Test-Endpoint -Name "记录列表API" -Url "$ApiUrl/records" -ExpectedStatus 401
} catch {
    Write-Warning "记录API测试跳过（需要认证）"
    $TestResults.Skipped++
}

# 7. 测试文件管理API
Write-Info "`n7. 测试文件管理API"
try {
    Test-Endpoint -Name "文件列表API" -Url "$ApiUrl/files" -ExpectedStatus 401
} catch {
    Write-Warning "文件API测试跳过（需要认证）"
    $TestResults.Skipped++
}

# 8. 测试前端构建文件
Write-Info "`n8. 测试前端构建文件"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BuildDir = Join-Path $ProjectRoot "build\frontend"

if (Test-Path $BuildDir) {
    Write-Success "✓ 构建目录存在: $BuildDir"
    
    $indexPath = Join-Path $BuildDir "index.html"
    if (Test-Path $indexPath) {
        Write-Success "✓ index.html存在"
        $TestResults.Passed++
    } else {
        Write-Error "✗ index.html不存在"
        $TestResults.Failed++
    }
    $TestResults.Total++
    
    $assetsDir = Join-Path $BuildDir "assets"
    if (Test-Path $assetsDir) {
        $assetFiles = Get-ChildItem -Path $assetsDir -File
        Write-Success "✓ assets目录存在，包含 $($assetFiles.Count) 个文件"
        $TestResults.Passed++
    } else {
        Write-Error "✗ assets目录不存在"
        $TestResults.Failed++
    }
    $TestResults.Total++
    
} else {
    Write-Warning "构建目录不存在，请先运行构建脚本"
    $TestResults.Skipped += 2
    $TestResults.Total += 2
}

# 9. 测试响应式设计
Write-Info "`n9. 测试响应式设计"
try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/" -UseBasicParsing
    $content = $response.Content
    
    if ($content -like "*viewport*" -and $content -like "*responsive*") {
        Write-Success "✓ 响应式设计元素存在"
        $TestResults.Passed++
    } else {
        Write-Warning "响应式设计元素可能缺失"
        $TestResults.Failed++
    }
    $TestResults.Total++
} catch {
    Write-Warning "响应式设计测试跳过"
    $TestResults.Skipped++
    $TestResults.Total++
}

# 10. 性能测试
Write-Info "`n10. 性能测试"
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $response = Invoke-WebRequest -Uri "$BaseUrl/" -UseBasicParsing
    $stopwatch.Stop()
    
    $loadTime = $stopwatch.ElapsedMilliseconds
    
    if ($loadTime -lt 3000) {
        Write-Success "✓ 页面加载时间: ${loadTime}ms (良好)"
        $TestResults.Passed++
    } elseif ($loadTime -lt 5000) {
        Write-Warning "页面加载时间: ${loadTime}ms (一般)"
        $TestResults.Passed++
    } else {
        Write-Error "✗ 页面加载时间: ${loadTime}ms (较慢)"
        $TestResults.Failed++
    }
    $TestResults.Total++
} catch {
    Write-Warning "性能测试跳过"
    $TestResults.Skipped++
    $TestResults.Total++
}

# 输出测试结果
Write-Info "`n" + "=" * 50
Write-Info "测试结果汇总"
Write-Info "=" * 50

Write-Info "总测试数: $($TestResults.Total)"
Write-Success "通过: $($TestResults.Passed)"
Write-Error "失败: $($TestResults.Failed)"
Write-Warning "跳过: $($TestResults.Skipped)"

$successRate = if ($TestResults.Total -gt 0) { 
    [math]::Round(($TestResults.Passed / $TestResults.Total) * 100, 2) 
} else { 
    0 
}

Write-Info "成功率: $successRate%"

if ($TestResults.Failed -eq 0) {
    Write-Success "`n🎉 所有测试通过！前端应用运行正常。"
    exit 0
} elseif ($successRate -ge 80) {
    Write-Warning "`n⚠️  大部分测试通过，但有一些问题需要注意。"
    exit 0
} else {
    Write-Error "`n❌ 测试失败较多，请检查前端应用配置。"
    exit 1
}