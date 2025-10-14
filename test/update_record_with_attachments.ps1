# Update Existing Record with Attachments
Write-Host "=== Updating Record with Attachments ===" -ForegroundColor Green

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

# Get existing records
Write-Host "2. Getting existing records..." -ForegroundColor Yellow
try {
    $recordsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    
    if ($recordsResponse.success -and $recordsResponse.data.records -and $recordsResponse.data.records.Count -gt 0) {
        $firstRecord = $recordsResponse.data.records[0]
        $recordId = $firstRecord.id
        
        Write-Host "Updating record ID: $recordId" -ForegroundColor Cyan
        
        # Update the record with attachment information
        $updateData = @{
            title = $firstRecord.title + " (Updated with Attachments)"
            content = @{
                description = "This record has been updated to include test attachments for preview functionality testing."
                status = "published"
                attachments = @(
                    @{
                        id = 1
                        name = "sample-image.jpg"
                        filename = "sample-image.jpg"
                        size = 1024000
                        mimeType = "image/jpeg"
                        url = "https://via.placeholder.com/400x300.jpg"
                    },
                    @{
                        id = 2
                        name = "test-document.pdf"
                        filename = "test-document.pdf"
                        size = 2048000
                        mimeType = "application/pdf"
                        url = "/uploads/test-document.pdf"
                    },
                    @{
                        id = 3
                        name = "notes.txt"
                        filename = "notes.txt"
                        size = 5120
                        mimeType = "text/plain"
                        url = "/uploads/notes.txt"
                    }
                )
                priority = "High"
                category = "Test Category"
            }
            tags = @("updated", "attachments", "test")
        } | ConvertTo-Json -Depth 10
        
        $updateResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records/$recordId" -Method PUT -Body $updateData -ContentType "application/json" -Headers $headers
        
        if ($updateResponse.success) {
            Write-Host "Record updated successfully!" -ForegroundColor Green
            
            # Verify the update
            Write-Host "3. Verifying update..." -ForegroundColor Yellow
            $verifyResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records/$recordId" -Method GET -Headers $headers
            
            Write-Host "Updated record content:" -ForegroundColor Yellow
            Write-Host ($verifyResponse.data.content | ConvertTo-Json -Depth 5) -ForegroundColor Gray
            
        } else {
            Write-Host "Failed to update record" -ForegroundColor Red
        }
        
    } else {
        Write-Host "No records found to update" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=== Update Complete ===" -ForegroundColor Green
Write-Host "Now test the record detail view to see attachments" -ForegroundColor Yellow