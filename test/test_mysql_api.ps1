# MySQL API 测试脚本

Write-Host "=== MySQL API 测试开始 ===" -ForegroundColor Green

# 等待服务器启动
Start-Sleep -Seconds 5

# 1. 健康检查
Write-Host "`n1. 健康检查..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET
    Write-Host "✓ 健康检查成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 健康检查失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. 登录
Write-Host "`n2. 用户登录..." -ForegroundColor Yellow
$loginData = '{"username":"admin","password":"admin123"}'
try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -ContentType "application/json" -Body $loginData
    $token = $loginResponse.data.token
    $headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }
    Write-Host "✓ 登录成功，获取到token" -ForegroundColor Green
} catch {
    Write-Host "✗ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. 创建记录类型
Write-Host "`n3. 创建记录类型..." -ForegroundColor Yellow
$recordTypeData = '{"name":"mysql_api_test","display_name":"MySQL API Test","table_name":"mysql_api_test_records"}'
try {
    $createTypeResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/record-types" -Method POST -Headers $headers -Body $recordTypeData
    Write-Host "✓ 记录类型创建成功，ID: $($createTypeResponse.data.id)" -ForegroundColor Green
} catch {
    Write-Host "✗ 记录类型创建失败: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "可能记录类型已存在，继续测试..." -ForegroundColor Yellow
    } else {
        exit 1
    }
}

# 4. 创建记录
Write-Host "`n4. 创建记录..." -ForegroundColor Yellow
$recordData = '{"type":"mysql_api_test","title":"MySQL API Test Record","content":{"description":"Testing MySQL database integration","status":"active"},"tags":["mysql","api","test"]}'
try {
    $createRecordResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Headers $headers -Body $recordData
    $recordId = $createRecordResponse.data.id
    Write-Host "✓ 记录创建成功，ID: $recordId" -ForegroundColor Green
} catch {
    Write-Host "✗ 记录创建失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "状态码: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    exit 1
}

# 5. 查询记录
Write-Host "`n5. 查询记录..." -ForegroundColor Yellow
try {
    $getRecordResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records/$recordId" -Method GET -Headers $headers
    Write-Host "✓ 记录查询成功，标题: $($getRecordResponse.data.title)" -ForegroundColor Green
} catch {
    Write-Host "✗ 记录查询失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. 查询所有记录
Write-Host "`n6. 查询所有记录..." -ForegroundColor Yellow
try {
    $getAllRecordsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    Write-Host "✓ 查询成功，总记录数: $($getAllRecordsResponse.data.total)" -ForegroundColor Green
} catch {
    Write-Host "✗ 查询所有记录失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== MySQL API 测试完成 ===" -ForegroundColor Green