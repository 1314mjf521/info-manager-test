# Create Test Record with Files
Write-Host "=== Creating Test Record with Files ===" -ForegroundColor Green

# Login first
Write-Host "`n1. Logging in..." -ForegroundColor Yellow
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    Write-Host "Login successful" -ForegroundColor Green
} catch {
    Write-Host "Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
}

# Create a test record with file attachments
Write-Host "`n2. Creating test record with attachments..." -ForegroundColor Yellow

$testRecord = @{
    type = "test"
    title = "测试记录 - 包含附件"
    content = @{
        description = "这是一个包含附件的测试记录，用于验证文件预览功能。"
        status = "published"
        attachments = @(
            @{
                id = 1
                name = "test-image.jpg"
                filename = "test-image.jpg"
                original_name = "测试图片.jpg"
                size = 1024000
                mimeType = "image/jpeg"
                type = "image/jpeg"
                url = "/uploads/test-image.jpg"
                path = "/uploads/test-image.jpg"
            },
            @{
                id = 2
                name = "document.pdf"
                filename = "document.pdf"
                original_name = "测试文档.pdf"
                size = 2048000
                mimeType = "application/pdf"
                type = "application/pdf"
                url = "/uploads/document.pdf"
                path = "/uploads/document.pdf"
            },
            @{
                id = 3
                name = "notes.txt"
                filename = "notes.txt"
                original_name = "笔记.txt"
                size = 5120
                mimeType = "text/plain"
                type = "text/plain"
                url = "/uploads/notes.txt"
                path = "/uploads/notes.txt"
            }
        )
        files = @(
            @{
                id = 4
                name = "screenshot.png"
                filename = "screenshot.png"
                size = 512000
                mimeType = "image/png"
                url = "/uploads/screenshot.png"
            }
        )
    }
    tags = @("测试", "附件", "预览")
} | ConvertTo-Json -Depth 10

try {
    $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Body $testRecord -ContentType "application/json" -Headers $headers
    
    if ($createResponse.success) {
        Write-Host "✅ Test record created successfully!" -ForegroundColor Green
        Write-Host "Record ID: $($createResponse.data.id)" -ForegroundColor Cyan
        Write-Host "Record Title: $($createResponse.data.title)" -ForegroundColor Cyan
        
        # Get the created record to verify structure
        Write-Host "`n3. Verifying created record..." -ForegroundColor Yellow
        $recordId = $createResponse.data.id
        $verifyResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records/$recordId" -Method GET -Headers $headers
        
        Write-Host "Created record structure:" -ForegroundColor Yellow
        Write-Host ($verifyResponse | ConvertTo-Json -Depth 10) -ForegroundColor Gray
        
    } else {
        Write-Host "❌ Failed to create test record" -ForegroundColor Red
        Write-Host "Response: $($createResponse | ConvertTo-Json)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error creating test record: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $errorStream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorStream)
        $errorBody = $reader.ReadToEnd()
        Write-Host "Error details: $errorBody" -ForegroundColor Yellow
    }
}

# Also create a simpler record with just description
Write-Host "`n4. Creating simple record with description..." -ForegroundColor Yellow

$simpleRecord = @{
    type = "test"
    title = "简单测试记录"
    content = @{
        description = "这是一个简单的测试记录，包含多行描述内容。`n`n第二段内容。`n`n第三段内容，用于测试换行显示。"
        status = "published"
        priority = "高"
        category = "测试分类"
    }
    tags = @("简单", "测试", "描述")
} | ConvertTo-Json -Depth 10

try {
    $simpleResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Body $simpleRecord -ContentType "application/json" -Headers $headers
    
    if ($simpleResponse.success) {
        Write-Host "✅ Simple test record created successfully!" -ForegroundColor Green
        Write-Host "Record ID: $($simpleResponse.data.id)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Error creating simple record: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Test Records Created ===" -ForegroundColor Green
Write-Host "Now you can test the record detail view:" -ForegroundColor Yellow
Write-Host "1. Go to Records Management" -ForegroundColor White
Write-Host "2. Click 'View' on the test records" -ForegroundColor White
Write-Host "3. Check if attachments and descriptions display correctly" -ForegroundColor White