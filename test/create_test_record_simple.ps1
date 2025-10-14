# Create Test Record Simple
Write-Host "=== Creating Test Record with Files ===" -ForegroundColor Green

# Login first
Write-Host "1. Logging in..." -ForegroundColor Yellow
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    Write-Host "Login successful" -ForegroundColor Green
} catch {
    Write-Host "Login failed" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
}

# Create a test record with file attachments
Write-Host "2. Creating test record..." -ForegroundColor Yellow

$testRecord = @{
    type = "test"
    title = "Test Record with Attachments"
    content = @{
        description = "This is a test record with file attachments for testing preview functionality."
        status = "published"
        attachments = @(
            @{
                id = 1
                name = "test-image.jpg"
                filename = "test-image.jpg"
                size = 1024000
                mimeType = "image/jpeg"
                url = "/uploads/test-image.jpg"
            },
            @{
                id = 2
                name = "document.pdf"
                filename = "document.pdf"
                size = 2048000
                mimeType = "application/pdf"
                url = "/uploads/document.pdf"
            }
        )
    }
    tags = @("test", "attachments", "preview")
} | ConvertTo-Json -Depth 10

try {
    $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Body $testRecord -ContentType "application/json" -Headers $headers
    
    if ($createResponse.success) {
        Write-Host "Test record created successfully!" -ForegroundColor Green
        Write-Host "Record ID: $($createResponse.data.id)" -ForegroundColor Cyan
    } else {
        Write-Host "Failed to create test record" -ForegroundColor Red
    }
} catch {
    Write-Host "Error creating test record: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=== Test Complete ===" -ForegroundColor Green