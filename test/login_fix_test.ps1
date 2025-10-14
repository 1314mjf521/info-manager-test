# 登录修复测试脚本
Write-Host "=== 登录修复测试 ===" -ForegroundColor Green

# 测试前端服务器
Write-Host "1. 测试前端服务器..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -UseBasicParsing
    Write-Host "前端服务器正常 - 状态: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "前端服务器错误: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "请确保运行: cd frontend && npm run dev" -ForegroundColor Yellow
    exit 1
}

# 测试后端API
Write-Host "2. 测试后端API..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/system/health" -TimeoutSec 5 -UseBasicParsing
    Write-Host "后端API正常 - 状态: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "后端API错误: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "请确保后端服务正在运行" -ForegroundColor Yellow
    exit 1
}

# 测试登录API
Write-Host "3. 测试登录API..." -ForegroundColor Yellow
$loginData = @{
    username = "admin"
    password = "admin123"
}
$loginJson = $loginData | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginJson -ContentType "application/json" -TimeoutSec 10
    
    if ($response.success -and $response.data.token) {
        Write-Host "登录API测试成功!" -ForegroundColor Green
        Write-Host "Token: $($response.data.token.Substring(0, 20))..." -ForegroundColor Gray
        Write-Host "用户: $($response.data.user.username)" -ForegroundColor Gray
    } else {
        Write-Host "登录API响应格式异常" -ForegroundColor Red
        Write-Host "响应: $($response | ConvertTo-Json)" -ForegroundColor Gray
    }
} catch {
    Write-Host "登录API测试失败: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $errorBody = $reader.ReadToEnd()
        Write-Host "错误详情: $errorBody" -ForegroundColor Gray
    }
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
Write-Host "如果所有测试通过，现在可以在浏览器中测试登录功能:" -ForegroundColor Cyan
Write-Host "1. 访问 http://localhost:3000/login" -ForegroundColor White
Write-Host "2. 输入用户名: admin" -ForegroundColor White
Write-Host "3. 输入密码: admin123" -ForegroundColor White
Write-Host "4. 点击登录按钮" -ForegroundColor White
Write-Host "5. 查看浏览器控制台的调试信息" -ForegroundColor White