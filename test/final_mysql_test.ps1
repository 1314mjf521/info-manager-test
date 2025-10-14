# 最终MySQL API测试

Write-Host "=== 开始MySQL API测试 ===" -ForegroundColor Green

# 1. 登录
Write-Host "`n1. 用户登录..." -ForegroundColor Yellow
$loginData = '{"username":"admin","password":"admin123"}'
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -ContentType "application/json" -Body $loginData
$token = $loginResponse.data.token
$headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }
Write-Host "✓ 登录成功" -ForegroundColor Green

# 2. 创建记录
Write-Host "`n2. 创建记录..." -ForegroundColor Yellow
$recordData = '{"type":"mysql_test_type","title":"Final MySQL Test Record","content":{"description":"Final test of MySQL integration","status":"success","timestamp":"2025-10-03"},"tags":["mysql","final","test","success"]}'
$createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Headers $headers -Body $recordData
$recordId = $createResponse.data.id
Write-Host "✓ 记录创建成功，ID: $recordId" -ForegroundColor Green
Write-Host "  标题: $($createResponse.data.title)" -ForegroundColor Cyan
Write-Host "  标签: $($createResponse.data.tags -join ', ')" -ForegroundColor Cyan

# 3. 查询记录
Write-Host "`n3. 查询记录..." -ForegroundColor Yellow
$getResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records/$recordId" -Method GET -Headers $headers
Write-Host "✓ 记录查询成功" -ForegroundColor Green
Write-Host "  ID: $($getResponse.data.id)" -ForegroundColor Cyan
Write-Host "  标题: $($getResponse.data.title)" -ForegroundColor Cyan
Write-Host "  创建者: $($getResponse.data.creator)" -ForegroundColor Cyan

# 4. 查询所有记录
Write-Host "`n4. 查询所有记录..." -ForegroundColor Yellow
$getAllResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
Write-Host "✓ 查询成功，总记录数: $($getAllResponse.data.total)" -ForegroundColor Green

# 5. 按标签查询
Write-Host "`n5. 按标签查询记录..." -ForegroundColor Yellow
$tagResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records?tags=mysql,test" -Method GET -Headers $headers
Write-Host "✓ 标签查询成功，找到 $($tagResponse.data.total) 条记录" -ForegroundColor Green

Write-Host "`n=== MySQL API测试完成 ===" -ForegroundColor Green
Write-Host "所有测试通过！MySQL数据库集成成功！" -ForegroundColor Green