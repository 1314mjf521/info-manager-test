#!/usr/bin/env pwsh
# 修复API参数问题的脚本

Write-Host "🔧 API Parameter Fix Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# 获取admin token
$loginData = @{ username = "admin"; password = "admin123" } | ConvertTo-Json
$response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
$token = $response.data.token
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "✅ Got admin token" -ForegroundColor Green

# 测试和修复各种API参数问题
Write-Host "`n🧪 Testing API parameter formats..." -ForegroundColor Yellow

# 1. 测试工单创建
Write-Host "`n1. Testing ticket creation..." -ForegroundColor Cyan
$ticketData = @{
    title = "Test Ticket"
    description = "Test ticket description"
    type = "bug"
    priority = "medium"
    status = "open"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method POST -Headers $headers -Body $ticketData -ContentType "application/json"
    Write-Host "✅ Ticket creation working" -ForegroundColor Green
} catch {
    Write-Host "❌ Ticket creation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Request body: $ticketData" -ForegroundColor Gray
}

# 2. 测试文件上传
Write-Host "`n2. Testing file upload..." -ForegroundColor Cyan
try {
    # 创建一个简单的测试文件
    $testContent = "Test file content"
    $testFile = [System.Text.Encoding]::UTF8.GetBytes($testContent)
    
    # 使用multipart/form-data格式
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    $bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"test.txt`"",
        "Content-Type: text/plain$LF",
        $testContent,
        "--$boundary--$LF"
    ) -join $LF
    
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/upload" -Method POST -Headers @{ "Authorization" = "Bearer $token"; "Content-Type" = "multipart/form-data; boundary=$boundary" } -Body $bodyLines
    Write-Host "✅ File upload working" -ForegroundColor Green
} catch {
    Write-Host "❌ File upload failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. 测试系统配置更新
Write-Host "`n3. Testing system config update..." -ForegroundColor Cyan
$configData = @{
    key = "test_setting"
    value = "test_value"
    description = "Test configuration"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/config" -Method POST -Headers $headers -Body $configData -ContentType "application/json"
    Write-Host "✅ Config update working" -ForegroundColor Green
} catch {
    Write-Host "❌ Config update failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Request body: $configData" -ForegroundColor Gray
}

# 4. 测试公告创建
Write-Host "`n4. Testing announcement creation..." -ForegroundColor Cyan
$announcementData = @{
    title = "Test Announcement"
    content = "Test announcement content"
    type = "info"
    is_active = $true
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/announcements" -Method POST -Headers $headers -Body $announcementData -ContentType "application/json"
    Write-Host "✅ Announcement creation working" -ForegroundColor Green
} catch {
    Write-Host "❌ Announcement creation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Request body: $announcementData" -ForegroundColor Gray
}

# 5. 测试AI配置
Write-Host "`n5. Testing AI config..." -ForegroundColor Cyan
$aiConfigData = @{
    provider = "openai"
    api_key = "test_key"
    model = "gpt-3.5-turbo"
    enabled = $true
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/ai/config" -Method POST -Headers $headers -Body $aiConfigData -ContentType "application/json"
    Write-Host "✅ AI config working" -ForegroundColor Green
} catch {
    Write-Host "❌ AI config failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Request body: $aiConfigData" -ForegroundColor Gray
}

Write-Host "`n🎯 API Parameter Fix Complete!" -ForegroundColor Green
Write-Host "Check the results above to identify parameter format issues." -ForegroundColor Yellow