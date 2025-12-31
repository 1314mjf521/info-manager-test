#!/usr/bin/env pwsh
# 创建测试数据脚本

Write-Host "🔧 Creating test data..." -ForegroundColor Cyan

# 获取admin token
$loginData = @{ username = "admin"; password = "admin123" } | ConvertTo-Json
$response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
$token = $response.data.token
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "✅ Got admin token" -ForegroundColor Green

# 1. 创建测试工单
Write-Host "`n📝 Creating test tickets..." -ForegroundColor Yellow
$ticketIds = @()

for ($i = 1; $i -le 3; $i++) {
    $ticketData = @{
        title = "Test Ticket $i"
        description = "This is test ticket number $i for testing purposes"
        type = "bug"
        priority = "normal"
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method POST -Headers $headers -Body $ticketData -ContentType "application/json"
        $ticketIds += $response.data.id
        Write-Host "✅ Created ticket $i (ID: $($response.data.id))" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create ticket $i`: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 2. 创建测试记录
Write-Host "`n📄 Creating test records..." -ForegroundColor Yellow
$recordIds = @()

for ($i = 1; $i -le 2; $i++) {
    $recordData = @{
        type = "general"
        title = "Test Record $i"
        content = @{
            description = "This is test record number $i"
            category = "test"
        }
    } | ConvertTo-Json -Depth 3

    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Headers $headers -Body $recordData -ContentType "application/json"
        $recordIds += $response.data.id
        Write-Host "✅ Created record $i (ID: $($response.data.id))" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create record $i`: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 3. 创建测试文件
Write-Host "`n📁 Creating test files..." -ForegroundColor Yellow
try {
    # 创建一个简单的测试文件
    $testContent = "This is a test file for testing purposes.`nCreated at: $(Get-Date)"
    $testBytes = [System.Text.Encoding]::UTF8.GetBytes($testContent)
    
    # 使用正确的multipart格式
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    $bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"test.txt`"",
        "Content-Type: text/plain$LF",
        $testContent,
        "--$boundary--$LF"
    ) -join $LF
    
    $fileHeaders = @{ 
        "Authorization" = "Bearer $token"
        "Content-Type" = "multipart/form-data; boundary=$boundary"
    }
    
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/upload" -Method POST -Headers $fileHeaders -Body $bodyLines
    Write-Host "✅ Created test file (ID: $($response.data.id))" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create test file`: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. 显示创建的测试数据
Write-Host "`n📊 Test data summary:" -ForegroundColor Cyan
Write-Host "Ticket IDs: $($ticketIds -join ', ')" -ForegroundColor Gray
Write-Host "Record IDs: $($recordIds -join ', ')" -ForegroundColor Gray

# 5. 测试工单操作
if ($ticketIds.Count -gt 0) {
    $testTicketId = $ticketIds[0]
    Write-Host "`n🧪 Testing ticket operations with ID $testTicketId..." -ForegroundColor Yellow
    
    # 测试工单更新
    $updateData = @{
        title = "Updated Test Ticket"
        description = "This ticket has been updated"
        priority = "high"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$testTicketId" -Method PUT -Headers $headers -Body $updateData -ContentType "application/json"
        Write-Host "✅ Ticket update working" -ForegroundColor Green
    } catch {
        Write-Host "❌ Ticket update failed`: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 测试工单状态变更
    $statusData = @{
        status = "in_progress"
        comment = "Starting work on this ticket"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$testTicketId/status" -Method PUT -Headers $headers -Body $statusData -ContentType "application/json"
        Write-Host "✅ Ticket status change working" -ForegroundColor Green
    } catch {
        Write-Host "❌ Ticket status change failed`: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 测试工单评论
    $commentData = @{
        content = "This is a test comment"
        type = "comment"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$testTicketId/comments" -Method POST -Headers $headers -Body $commentData -ContentType "application/json"
        Write-Host "✅ Ticket comment working" -ForegroundColor Green
    } catch {
        Write-Host "❌ Ticket comment failed`: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n🎯 Test data creation complete!" -ForegroundColor Green