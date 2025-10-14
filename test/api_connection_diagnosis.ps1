# API连接诊断脚本
# 检查前端与后端API的连接状态

Write-Host "=== API连接诊断 ===" -ForegroundColor Green

# 检查后端服务状态
Write-Host "`n1. 检查后端服务状态..." -ForegroundColor Yellow

$backendUrl = "http://localhost:8080"
$apiUrl = "$backendUrl/api/v1"

try {
    Write-Host "测试后端基础连接: $backendUrl" -ForegroundColor Cyan
    $response = Invoke-WebRequest -Uri $backendUrl -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✓ 后端服务响应正常 (状态码: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "✗ 后端服务无响应: $_" -ForegroundColor Red
    Write-Host "请检查后端服务是否在 localhost:8080 端口运行" -ForegroundColor Yellow
}

# 检查API健康状态
Write-Host "`n2. 检查API健康状态..." -ForegroundColor Yellow

try {
    Write-Host "测试API健康检查: $apiUrl/system/health" -ForegroundColor Cyan
    $healthResponse = Invoke-WebRequest -Uri "$apiUrl/system/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    $healthData = $healthResponse.Content | ConvertFrom-Json
    Write-Host "✓ API健康检查通过" -ForegroundColor Green
    Write-Host "响应内容: $($healthResponse.Content)" -ForegroundColor White
} catch {
    Write-Host "✗ API健康检查失败: $_" -ForegroundColor Red
}

# 检查记录类型API
Write-Host "`n3. 检查记录类型API..." -ForegroundColor Yellow

try {
    Write-Host "测试记录类型API: $apiUrl/record-types" -ForegroundColor Cyan
    $recordTypesResponse = Invoke-WebRequest -Uri "$apiUrl/record-types" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✓ 记录类型API响应正常 (状态码: $($recordTypesResponse.StatusCode))" -ForegroundColor Green
    Write-Host "响应内容: $($recordTypesResponse.Content)" -ForegroundColor White
} catch {
    Write-Host "✗ 记录类型API失败: $_" -ForegroundColor Red
}

# 检查记录管理API
Write-Host "`n4. 检查记录管理API..." -ForegroundColor Yellow

try {
    Write-Host "测试记录管理API: $apiUrl/records" -ForegroundColor Cyan
    $recordsResponse = Invoke-WebRequest -Uri "$apiUrl/records" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✓ 记录管理API响应正常 (状态码: $($recordsResponse.StatusCode))" -ForegroundColor Green
    Write-Host "响应内容: $($recordsResponse.Content)" -ForegroundColor White
} catch {
    Write-Host "✗ 记录管理API失败: $_" -ForegroundColor Red
}

# 检查端口占用
Write-Host "`n5. 检查端口占用情况..." -ForegroundColor Yellow

try {
    $portCheck = netstat -an | findstr ":8080"
    if ($portCheck) {
        Write-Host "✓ 端口8080有服务监听:" -ForegroundColor Green
        Write-Host $portCheck -ForegroundColor White
    } else {
        Write-Host "✗ 端口8080没有服务监听" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 端口检查失败: $_" -ForegroundColor Red
}

# 检查前端配置
Write-Host "`n6. 检查前端API配置..." -ForegroundColor Yellow

$apiConfigPath = "frontend/src/config/api.ts"
if (Test-Path $apiConfigPath) {
    $apiConfig = Get-Content $apiConfigPath -Raw
    if ($apiConfig -match "localhost:8080") {
        Write-Host "✓ 前端API配置指向 localhost:8080" -ForegroundColor Green
    } else {
        Write-Host "✗ 前端API配置可能不正确" -ForegroundColor Red
        Write-Host "当前配置:" -ForegroundColor Yellow
        $apiConfig -split "`n" | Where-Object { $_ -match "BASE_URL" } | ForEach-Object { Write-Host $_ -ForegroundColor White }
    }
} else {
    Write-Host "✗ 前端API配置文件不存在" -ForegroundColor Red
}

# 提供解决方案
Write-Host "`n=== 解决方案建议 ===" -ForegroundColor Green

Write-Host "`n如果后端服务未运行：" -ForegroundColor Cyan
Write-Host "1. 确保Go后端服务已启动并监听8080端口" -ForegroundColor White
Write-Host "2. 检查后端服务日志是否有错误信息" -ForegroundColor White
Write-Host "3. 确认数据库连接是否正常" -ForegroundColor White

Write-Host "`n如果API响应异常：" -ForegroundColor Cyan
Write-Host "1. 检查后端API路由配置是否正确" -ForegroundColor White
Write-Host "2. 确认CORS设置允许前端域名访问" -ForegroundColor White
Write-Host "3. 检查API认证和权限设置" -ForegroundColor White

Write-Host "`n如果网络连接问题：" -ForegroundColor Cyan
Write-Host "1. 检查防火墙设置是否阻止了8080端口" -ForegroundColor White
Write-Host "2. 确认localhost解析是否正常" -ForegroundColor White
Write-Host "3. 尝试使用127.0.0.1:8080替代localhost:8080" -ForegroundColor White

Write-Host "`n临时解决方案：" -ForegroundColor Cyan
Write-Host "1. 前端会自动使用模拟数据，可以继续开发和测试" -ForegroundColor White
Write-Host "2. 修复后端连接后，点击刷新按钮即可恢复正常" -ForegroundColor White
Write-Host "3. 检查浏览器开发者工具的网络面板查看具体错误" -ForegroundColor White