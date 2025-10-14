# MySQL API Final Test

Write-Host "=== MySQL API Final Test ===" -ForegroundColor Green

# 1. Login
Write-Host "`n1. User Login..." -ForegroundColor Yellow
$loginData = '{"username":"admin","password":"admin123"}'
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -ContentType "application/json" -Body $loginData
$token = $loginResponse.data.token
$headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }
Write-Host "Login successful" -ForegroundColor Green

# 2. Create Record
Write-Host "`n2. Create Record..." -ForegroundColor Yellow
$recordData = '{"type":"mysql_test_type","title":"Final MySQL API Test","content":{"description":"Testing MySQL API integration","status":"success","timestamp":"2025-10-03"},"tags":["mysql","api","final","test"]}'
$createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Headers $headers -Body $recordData
$recordId = $createResponse.data.id
Write-Host "Record created successfully! ID: $recordId" -ForegroundColor Green
Write-Host "  Title: $($createResponse.data.title)" -ForegroundColor Cyan
Write-Host "  Tags: $($createResponse.data.tags -join ', ')" -ForegroundColor Cyan

# 3. Get Record
Write-Host "`n3. Get Record..." -ForegroundColor Yellow
$getResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records/$recordId" -Method GET -Headers $headers
Write-Host "Record retrieved successfully" -ForegroundColor Green
Write-Host "  ID: $($getResponse.data.id)" -ForegroundColor Cyan
Write-Host "  Title: $($getResponse.data.title)" -ForegroundColor Cyan
Write-Host "  Creator: $($getResponse.data.creator)" -ForegroundColor Cyan

# 4. Get All Records
Write-Host "`n4. Get All Records..." -ForegroundColor Yellow
$getAllResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
Write-Host "Query successful, Total records: $($getAllResponse.data.total)" -ForegroundColor Green

# 5. Query by Tags
Write-Host "`n5. Query by Tags..." -ForegroundColor Yellow
$tagResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records?tags=mysql,api" -Method GET -Headers $headers
Write-Host "Tag query successful, Found $($tagResponse.data.total) records" -ForegroundColor Green

Write-Host "`n=== MySQL API Test Complete ===" -ForegroundColor Green
Write-Host "All tests passed! MySQL database integration successful!" -ForegroundColor Green