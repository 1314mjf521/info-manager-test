# 前后端集成测试脚本
param(
    [string]$FrontendUrl = "http://localhost:3001",
    [string]$BackendUrl = "http://localhost:8080/api/v1"
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

Write-TestInfo "开始前后端集成测试"
Write-TestInfo "前端地址: $FrontendUrl"
Write-TestInfo "后端地址: $BackendUrl"
Write-TestInfo "=" * 60

# 1. 测试后端API连接
Write-TestInfo "1. 测试后端API连接"
try {
    $healthResponse = Invoke-WebRequest -Uri "$BackendUrl/system/health" -UseBasicParsing -TimeoutSec 5
    Write-TestSuccess "后端健康检查: HTTP $($healthResponse.StatusCode)"
} catch {
    if ($_.Exception.Response.StatusCode -eq 403) {
        Write-TestSuccess "后端API运行正常 (需要认证)"
    } else {
        Write-TestError "后端API连接失败: $($_.Exception.Message)"
        exit 1
    }
}

# 2. 测试前端页面访问
Write-TestInfo "`n2. 测试前端页面访问"
try {
    $frontendResponse = Invoke-WebRequest -Uri $FrontendUrl -UseBasicParsing -TimeoutSec 5
    Write-TestSuccess "前端页面访问: HTTP $($frontendResponse.StatusCode)"
} catch {
    Write-TestError "前端页面访问失败: $($_.Exception.Message)"
    Write-TestError "请确保运行了 npm run dev 并且服务器在端口3001上运行"
    exit 1
}

# 3. 测试登录API
Write-TestInfo "`n3. 测试登录API"

# 测试错误密码
Write-TestInfo "3.1 测试错误密码"
try {
    $loginResponse = Invoke-WebRequest -Uri "$BackendUrl/auth/login" -Method POST -ContentType "application/json" -Body '{"username":"admin","password":"wrongpassword"}' -UseBasicParsing
    Write-TestError "错误密码应该返回400错误，但返回了: $($loginResponse.StatusCode)"
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-TestSuccess "错误密码正确返回400错误"
    } else {
        Write-TestError "错误密码返回了意外的状态码: $($_.Exception.Response.StatusCode)"
    }
}

# 测试正确密码
Write-TestInfo "3.2 测试正确密码"
try {
    $loginResponse = Invoke-WebRequest -Uri "$BackendUrl/auth/login" -Method POST -ContentType "application/json" -Body '{"username":"admin","password":"admin123"}' -UseBasicParsing
    Write-TestSuccess "正确密码登录成功: HTTP $($loginResponse.StatusCode)"
    
    $loginData = $loginResponse.Content | ConvertFrom-Json
    if ($loginData.data.token) {
        Write-TestSuccess "JWT token获取成功"
        $token = $loginData.data.token
    } else {
        Write-TestError "JWT token获取失败"
    }
} catch {
    Write-TestError "正确密码登录失败: $($_.Exception.Message)"
}

# 4. 测试认证后的API访问
if ($token) {
    Write-TestInfo "`n4. 测试认证后的API访问"
    try {
        $headers = @{ Authorization = "Bearer $token" }
        $profileResponse = Invoke-WebRequest -Uri "$BackendUrl/users/profile" -Headers $headers -UseBasicParsing
        Write-TestSuccess "用户资料API访问成功: HTTP $($profileResponse.StatusCode)"
    } catch {
        Write-TestError "用户资料API访问失败: $($_.Exception.Message)"
    }
    
    try {
        $recordsResponse = Invoke-WebRequest -Uri "$BackendUrl/records" -Headers $headers -UseBasicParsing
        Write-TestSuccess "记录列表API访问成功: HTTP $($recordsResponse.StatusCode)"
    } catch {
        Write-TestError "记录列表API访问失败: $($_.Exception.Message)"
    }
}

Write-TestInfo "`n=" * 60
Write-TestInfo "集成测试完成"
Write-TestInfo "请在浏览器中访问 $FrontendUrl 进行手动测试"
Write-TestInfo "使用用户名: admin, 密码: admin123 进行登录测试"