# Export Service Test
Write-Host "=== Export Service Test ===" -ForegroundColor Green

# Login
$loginData = @{ username = "admin"; password = "admin123" }
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
$token = $loginResponse.data.token
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "✓ Login successful" -ForegroundColor Green

$testResults = @()

# Test 1: Create Export Template
Write-Host "`n1. Testing Create Export Template..." -ForegroundColor Yellow
try {
    $templateData = @{
        name = "Test Excel Template"
        description = "Test template for Excel export"
        format = "excel"
        config = '{"sheet_name":"Records","include_headers":true}'
        fields = '["id","title","content","created_at"]'
        is_active = $true
    }
    
    $templateResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/templates" -Method POST -Headers $headers -Body ($templateData | ConvertTo-Json) -ContentType "application/json"
    $templateId = $templateResponse.data.id
    
    Write-Host "✓ Create template successful - ID: $templateId" -ForegroundColor Green
    $testResults += @{ Test = "Create Template"; Success = $true; Details = "Template ID: $templateId" }
} catch {
    Write-Host "✗ Create template failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{ Test = "Create Template"; Success = $false; Error = $_.Exception.Message }
    $templateId = $null
}

# Test 2: Get Templates List
Write-Host "`n2. Testing Get Templates List..." -ForegroundColor Yellow
try {
    $templatesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/templates" -Method GET -Headers $headers
    $templateCount = $templatesResponse.data.templates.Count
    
    Write-Host "✓ Get templates successful - Count: $templateCount" -ForegroundColor Green
    $testResults += @{ Test = "Get Templates"; Success = $true; Details = "Template count: $templateCount" }
} catch {
    Write-Host "✗ Get templates failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{ Test = "Get Templates"; Success = $false; Error = $_.Exception.Message }
}

# Test 3: Get Template by ID
if ($templateId) {
    Write-Host "`n3. Testing Get Template by ID..." -ForegroundColor Yellow
    try {
        $templateResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/templates/$templateId" -Method GET -Headers $headers
        $templateName = $templateResponse.data.name
        
        Write-Host "✓ Get template by ID successful - Name: $templateName" -ForegroundColor Green
        $testResults += @{ Test = "Get Template by ID"; Success = $true; Details = "Template name: $templateName" }
    } catch {
        Write-Host "✗ Get template by ID failed: $($_.Exception.Message)" -ForegroundColor Red
        $testResults += @{ Test = "Get Template by ID"; Success = $false; Error = $_.Exception.Message }
    }
}

# Test 4: Update Template
if ($templateId) {
    Write-Host "`n4. Testing Update Template..." -ForegroundColor Yellow
    try {
        $updateData = @{
            name = "Updated Excel Template"
            description = "Updated test template for Excel export"
            format = "excel"
            config = '{"sheet_name":"UpdatedRecords","include_headers":true}'
            fields = '["id","title","content","created_at","updated_at"]'
            is_active = $true
        }
        
        $updateResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/templates/$templateId" -Method PUT -Headers $headers -Body ($updateData | ConvertTo-Json) -ContentType "application/json"
        $updatedName = $updateResponse.data.name
        
        Write-Host "✓ Update template successful - Name: $updatedName" -ForegroundColor Green
        $testResults += @{ Test = "Update Template"; Success = $true; Details = "Updated name: $updatedName" }
    } catch {
        Write-Host "✗ Update template failed: $($_.Exception.Message)" -ForegroundColor Red
        $testResults += @{ Test = "Update Template"; Success = $false; Error = $_.Exception.Message }
    }
}

# Test 5: Export Records (Excel)
Write-Host "`n5. Testing Export Records (Excel)..." -ForegroundColor Yellow
try {
    $exportData = @{
        task_name = "Test Excel Export"
        format = "excel"
        template_id = $templateId
        fields = @("id", "title", "content", "created_at")
        config = @{
            sheet_name = "TestRecords"
            include_headers = $true
        }
    }
    
    $exportResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/records" -Method POST -Headers $headers -Body ($exportData | ConvertTo-Json) -ContentType "application/json"
    $taskId = $exportResponse.data.task_id
    
    Write-Host "✓ Export records successful - Task ID: $taskId" -ForegroundColor Green
    $testResults += @{ Test = "Export Records (Excel)"; Success = $true; Details = "Task ID: $taskId" }
} catch {
    Write-Host "✗ Export records failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{ Test = "Export Records (Excel)"; Success = $false; Error = $_.Exception.Message }
    $taskId = $null
}

# Test 6: Export Records (CSV)
Write-Host "`n6. Testing Export Records (CSV)..." -ForegroundColor Yellow
try {
    $exportData = @{
        task_name = "Test CSV Export"
        format = "csv"
        fields = @("id", "title", "content")
        config = @{
            delimiter = ","
            include_headers = $true
        }
    }
    
    $exportResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/records" -Method POST -Headers $headers -Body ($exportData | ConvertTo-Json) -ContentType "application/json"
    $csvTaskId = $exportResponse.data.task_id
    
    Write-Host "✓ Export records (CSV) successful - Task ID: $csvTaskId" -ForegroundColor Green
    $testResults += @{ Test = "Export Records (CSV)"; Success = $true; Details = "Task ID: $csvTaskId" }
} catch {
    Write-Host "✗ Export records (CSV) failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{ Test = "Export Records (CSV)"; Success = $false; Error = $_.Exception.Message }
}

# Test 7: Export Records (JSON)
Write-Host "`n7. Testing Export Records (JSON)..." -ForegroundColor Yellow
try {
    $exportData = @{
        task_name = "Test JSON Export"
        format = "json"
        fields = @("id", "title", "content", "created_at")
        config = @{
            pretty_print = $true
        }
    }
    
    $exportResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/records" -Method POST -Headers $headers -Body ($exportData | ConvertTo-Json) -ContentType "application/json"
    $jsonTaskId = $exportResponse.data.task_id
    
    Write-Host "✓ Export records (JSON) successful - Task ID: $jsonTaskId" -ForegroundColor Green
    $testResults += @{ Test = "Export Records (JSON)"; Success = $true; Details = "Task ID: $jsonTaskId" }
} catch {
    Write-Host "✗ Export records (JSON) failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{ Test = "Export Records (JSON)"; Success = $false; Error = $_.Exception.Message }
}

# Wait for export tasks to complete
Write-Host "`nWaiting for export tasks to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Test 8: Get Export Tasks
Write-Host "`n8. Testing Get Export Tasks..." -ForegroundColor Yellow
try {
    $tasksResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/tasks" -Method GET -Headers $headers
    $taskCount = $tasksResponse.data.tasks.Count
    
    Write-Host "✓ Get export tasks successful - Count: $taskCount" -ForegroundColor Green
    $testResults += @{ Test = "Get Export Tasks"; Success = $true; Details = "Task count: $taskCount" }
} catch {
    Write-Host "✗ Get export tasks failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{ Test = "Get Export Tasks"; Success = $false; Error = $_.Exception.Message }
}

# Test 9: Get Task by ID
if ($taskId) {
    Write-Host "`n9. Testing Get Task by ID..." -ForegroundColor Yellow
    try {
        $taskResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/tasks/$taskId" -Method GET -Headers $headers
        $taskStatus = $taskResponse.data.status
        $taskProgress = $taskResponse.data.progress
        
        Write-Host "✓ Get task by ID successful - Status: $taskStatus, Progress: $taskProgress%" -ForegroundColor Green
        $testResults += @{ Test = "Get Task by ID"; Success = $true; Details = "Status: $taskStatus, Progress: $taskProgress%" }
    } catch {
        Write-Host "✗ Get task by ID failed: $($_.Exception.Message)" -ForegroundColor Red
        $testResults += @{ Test = "Get Task by ID"; Success = $false; Error = $_.Exception.Message }
    }
}

# Test 10: Get Export Files
Write-Host "`n10. Testing Get Export Files..." -ForegroundColor Yellow
try {
    $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/files" -Method GET -Headers $headers
    $fileCount = $filesResponse.data.files.Count
    
    Write-Host "✓ Get export files successful - Count: $fileCount" -ForegroundColor Green
    $testResults += @{ Test = "Get Export Files"; Success = $true; Details = "File count: $fileCount" }
    
    # Try to download first file if available
    if ($fileCount -gt 0) {
        $firstFileId = $filesResponse.data.files[0].id
        Write-Host "`n10.1 Testing Download Export File..." -ForegroundColor Yellow
        try {
            $downloadResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/export/files/$firstFileId/download" -Method GET -Headers $headers
            $contentLength = $downloadResponse.Headers.'Content-Length'
            
            Write-Host "✓ Download export file successful - Size: $contentLength bytes" -ForegroundColor Green
            $testResults += @{ Test = "Download Export File"; Success = $true; Details = "Downloaded size: $contentLength bytes" }
        } catch {
            Write-Host "✗ Download export file failed: $($_.Exception.Message)" -ForegroundColor Red
            $testResults += @{ Test = "Download Export File"; Success = $false; Error = $_.Exception.Message }
        }
    }
} catch {
    Write-Host "✗ Get export files failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{ Test = "Get Export Files"; Success = $false; Error = $_.Exception.Message }
}

# Test 11: Delete Template (cleanup)
if ($templateId) {
    Write-Host "`n11. Testing Delete Template..." -ForegroundColor Yellow
    try {
        $deleteResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/templates/$templateId" -Method DELETE -Headers $headers
        
        Write-Host "✓ Delete template successful" -ForegroundColor Green
        $testResults += @{ Test = "Delete Template"; Success = $true; Details = "Template deleted successfully" }
    } catch {
        Write-Host "✗ Delete template failed: $($_.Exception.Message)" -ForegroundColor Red
        $testResults += @{ Test = "Delete Template"; Success = $false; Error = $_.Exception.Message }
    }
}

# Generate Test Report
Write-Host "`n=== Export Service Test Report ===" -ForegroundColor Magenta
$successCount = ($testResults | Where-Object { $_.Success }).Count
$totalCount = $testResults.Count

Write-Host "Total Tests: $totalCount" -ForegroundColor White
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $($totalCount - $successCount)" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round($successCount / $totalCount * 100, 2))%" -ForegroundColor Yellow

Write-Host "`nDetailed Results:" -ForegroundColor White
foreach ($result in $testResults) {
    if ($result.Success) {
        Write-Host "  ✓ $($result.Test): $($result.Details)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $($result.Test): $($result.Error)" -ForegroundColor Red
    }
}

if ($successCount -eq $totalCount) {
    Write-Host "`n🎉 Export Service: ALL TESTS PASSED!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Export Service: SOME TESTS FAILED" -ForegroundColor Yellow
}

Write-Host "`n=== Export Service Test Completed ===" -ForegroundColor Green