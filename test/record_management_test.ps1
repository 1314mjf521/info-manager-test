# 记录管理功能测试脚本
Write-Host "=== 记录管理功能测试 ===" -ForegroundColor Green

$frontendUrl = "http://localhost:3000"
$backendUrl = "http://localhost:8080"

# 1. 测试前端服务器
Write-Host "`n1. 测试前端服务器..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $frontendUrl -TimeoutSec 5 -UseBasicParsing
    Write-Host "✓ 前端服务器正常 - 状态: $($response.StatusCode)" -ForegroundColor Green
}
catch {
    Write-Host "✗ 前端服务器错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. 测试后端API
Write-Host "`n2. 测试后端API..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$backendUrl/health" -TimeoutSec 5 -UseBasicParsing
    Write-Host "✓ 后端API正常 - 状态: $($response.StatusCode)" -ForegroundColor Green
}
catch {
    Write-Host "✗ 后端API错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. 测试登录获取token
Write-Host "`n3. 测试登录获取token..." -ForegroundColor Yellow
$loginJson = '{"username":"admin","password":"admin123"}'

try {
    $loginResponse = Invoke-RestMethod -Uri "$backendUrl/api/v1/auth/login" -Method POST -Body $loginJson -ContentType "application/json" -TimeoutSec 10
    
    if ($loginResponse.success -and $loginResponse.data.token) {
        $token = $loginResponse.data.token
        Write-Host "✓ 登录成功，获取到token" -ForegroundColor Green
        Write-Host "  用户: $($loginResponse.data.user.username)" -ForegroundColor Gray
    }
    else {
        Write-Host "✗ 登录失败" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "✗ 登录API失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 4. 测试记录列表API
Write-Host "`n4. 测试记录列表API..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $recordsResponse = Invoke-RestMethod -Uri "$backendUrl/api/v1/records" -Method GET -Headers $headers -TimeoutSec 10
    
    if ($recordsResponse.success) {
        Write-Host "✓ 记录列表API正常" -ForegroundColor Green
        Write-Host "  记录数量: $($recordsResponse.data.records.Count)" -ForegroundColor Gray
        Write-Host "  总数: $($recordsResponse.data.total)" -ForegroundColor Gray
    }
    else {
        Write-Host "✗ 记录列表API响应异常" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ 记录列表API失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. 测试创建记录API
Write-Host "`n5. 测试创建记录API..." -ForegroundColor Yellow
$recordData = @{
    type = "test"
    title = "测试记录"
    content = @{
        description = "这是一个测试记录的内容"
        category = "测试"
    }
    tags = @("测试", "API")
} | ConvertTo-Json -Depth 3

try {
    $createResponse = Invoke-RestMethod -Uri "$backendUrl/api/v1/records" -Method POST -Body $recordData -Headers $headers -TimeoutSec 10
    
    if ($createResponse.success) {
        $recordId = $createResponse.data.id
        Write-Host "✓ 创建记录成功" -ForegroundColor Green
        Write-Host "  记录ID: $recordId" -ForegroundColor Gray
        Write-Host "  标题: $($createResponse.data.title)" -ForegroundColor Gray
    }
    else {
        Write-Host "✗ 创建记录失败" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ 创建记录API失败: $($_.Exception.Message)" -ForegroundColor Red
    $recordId = $null
}

# 6. 测试获取单个记录API
if ($recordId) {
    Write-Host "`n6. 测试获取单个记录API..." -ForegroundColor Yellow
    try {
        $getResponse = Invoke-RestMethod -Uri "$backendUrl/api/v1/records/$recordId" -Method GET -Headers $headers -TimeoutSec 10
        
        if ($getResponse.success) {
            Write-Host "✓ 获取记录成功" -ForegroundColor Green
            Write-Host "  标题: $($getResponse.data.title)" -ForegroundColor Gray
            Write-Host "  类型: $($getResponse.data.type)" -ForegroundColor Gray
        }
        else {
            Write-Host "✗ 获取记录失败" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "✗ 获取记录API失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 7. 测试前端记录管理页面
Write-Host "`n7. 测试前端记录管理页面..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$frontendUrl/records" -TimeoutSec 5 -UseBasicParsing
    Write-Host "✓ 记录管理页面可访问 - 状态: $($response.StatusCode)" -ForegroundColor Green
}
catch {
    Write-Host "✗ 记录管理页面错误: $($_.Exception.Message)" -ForegroundColor Red
}

# 8. 清理测试数据
if ($recordId) {
    Write-Host "`n8. 清理测试数据..." -ForegroundColor Yellow
    try {
        $deleteResponse = Invoke-RestMethod -Uri "$backendUrl/api/v1/records/$recordId" -Method DELETE -Headers $headers -TimeoutSec 10
        
        if ($deleteResponse.success) {
            Write-Host "✓ 测试记录已删除" -ForegroundColor Green
        }
        else {
            Write-Host "⚠️  删除测试记录失败，请手动清理" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "⚠️  删除测试记录失败: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
Write-Host "现在可以在浏览器中测试记录管理功能:" -ForegroundColor Cyan
Write-Host "1. 访问 http://localhost:3000/login 登录" -ForegroundColor White
Write-Host "2. 访问 http://localhost:3000/records 查看记录列表" -ForegroundColor White
Write-Host "3. 点击'新建记录'测试创建功能" -ForegroundColor White
Write-Host "4. 测试编辑、删除等功能" -ForegroundColor White