# Debug Record Structure
Write-Host "=== Debugging Record Data Structure ===" -ForegroundColor Green

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

# Get records list to see structure
Write-Host "`n2. Getting records list..." -ForegroundColor Yellow
try {
    $recordsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    
    if ($recordsResponse.success -and $recordsResponse.data.records) {
        Write-Host "Found $($recordsResponse.data.records.Count) records" -ForegroundColor Green
        
        foreach ($record in $recordsResponse.data.records) {
            Write-Host "`n--- Record ID: $($record.id) ---" -ForegroundColor Cyan
            Write-Host "Title: $($record.title)" -ForegroundColor White
            Write-Host "Type: $($record.type)" -ForegroundColor White
            
            Write-Host "Content structure:" -ForegroundColor Yellow
            if ($record.content) {
                $contentJson = $record.content | ConvertTo-Json -Depth 5
                Write-Host $contentJson -ForegroundColor Gray
            } else {
                Write-Host "No content" -ForegroundColor Gray
            }
            
            Write-Host "Tags:" -ForegroundColor Yellow
            if ($record.tags) {
                Write-Host ($record.tags | ConvertTo-Json) -ForegroundColor Gray
            } else {
                Write-Host "No tags" -ForegroundColor Gray
            }
            
            Write-Host "Full record structure:" -ForegroundColor Yellow
            Write-Host ($record | ConvertTo-Json -Depth 5) -ForegroundColor DarkGray
            Write-Host "---" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "No records found or invalid response format" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to get records: $($_.Exception.Message)" -ForegroundColor Red
}

# Get a specific record if available
Write-Host "`n3. Getting specific record details..." -ForegroundColor Yellow
try {
    $recordsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    
    if ($recordsResponse.success -and $recordsResponse.data.records -and $recordsResponse.data.records.Count -gt 0) {
        $firstRecord = $recordsResponse.data.records[0]
        $recordId = $firstRecord.id
        
        Write-Host "Getting details for record ID: $recordId" -ForegroundColor Cyan
        
        $detailResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records/$recordId" -Method GET -Headers $headers
        
        Write-Host "Record detail response:" -ForegroundColor Yellow
        Write-Host ($detailResponse | ConvertTo-Json -Depth 10) -ForegroundColor Gray
        
        # Check for file-related fields
        Write-Host "`nChecking for file-related fields..." -ForegroundColor Yellow
        if ($detailResponse.success) {
            $recordData = $detailResponse.data
        } else {
            $recordData = $detailResponse
        }
        
        $possibleFileFields = @('attachments', 'files', 'images', '附件', '文件', 'uploads')
        foreach ($field in $possibleFileFields) {
            if ($recordData.content -and $recordData.content.$field) {
                Write-Host "Found file field '$field':" -ForegroundColor Green
                Write-Host ($recordData.content.$field | ConvertTo-Json -Depth 3) -ForegroundColor Cyan
            } elseif ($recordData.$field) {
                Write-Host "Found file field '$field' at root level:" -ForegroundColor Green
                Write-Host ($recordData.$field | ConvertTo-Json -Depth 3) -ForegroundColor Cyan
            }
        }
        
        # Check for description fields
        Write-Host "`nChecking for description fields..." -ForegroundColor Yellow
        $possibleDescFields = @('description', '备注', 'remark', 'note', 'comment', 'content')
        foreach ($field in $possibleDescFields) {
            if ($recordData.content -and $recordData.content.$field) {
                Write-Host "Found description field '$field':" -ForegroundColor Green
                Write-Host $recordData.content.$field -ForegroundColor Cyan
            }
        }
        
    } else {
        Write-Host "No records available for detailed inspection" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to get record details: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Debug Complete ===" -ForegroundColor Green
Write-Host "Please check the output above to understand the actual data structure" -ForegroundColor Yellow