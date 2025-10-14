# Simple Fixed Export Test
Write-Host "=== Fixed Export Test ===" -ForegroundColor Green

# Login
$loginData = @{ username = "admin"; password = "admin123" }
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
$token = $loginResponse.data.token
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "Login successful" -ForegroundColor Green

# Test all export formats
$formats = @("excel", "csv", "json", "pdf")

foreach ($format in $formats) {
    Write-Host "`nTesting $format export..." -ForegroundColor Yellow
    
    $exportData = @{
        task_name = "Fixed $format Export"
        format = $format
        fields = @("id", "title", "content", "created_at")
    }
    
    try {
        $exportResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/records" -Method POST -Headers $headers -Body ($exportData | ConvertTo-Json) -ContentType "application/json"
        $taskId = $exportResponse.data.task_id
        Write-Host "$format export task created - Task ID: $taskId" -ForegroundColor Green
    } catch {
        Write-Host "$format export failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Wait for completion
Write-Host "`nWaiting for exports to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check files
Write-Host "`nChecking export files..." -ForegroundColor Yellow
try {
    $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/files" -Method GET -Headers $headers
    $files = $filesResponse.data.files
    
    Write-Host "Total files: $($files.Count)" -ForegroundColor Cyan
    
    # Show latest files for each format
    $recentFiles = $files | Sort-Object created_at -Descending | Select-Object -First 4
    
    foreach ($file in $recentFiles) {
        $fileName = $file.file_name
        $format = $file.format
        $size = $file.file_size
        
        # Check file extension
        $expectedExt = switch ($format) {
            "excel" { ".xlsx" }
            "csv" { ".csv" }
            "json" { ".json" }
            "pdf" { ".pdf" }
        }
        
        $hasCorrectExt = $fileName.EndsWith($expectedExt)
        $status = if ($hasCorrectExt) { "CORRECT" } else { "WRONG" }
        $color = if ($hasCorrectExt) { "Green" } else { "Red" }
        
        Write-Host "  $format file: $fileName ($size bytes) - Extension: $status" -ForegroundColor $color
    }
    
    # Test download of first file
    if ($recentFiles.Count -gt 0) {
        $testFile = $recentFiles[0]
        Write-Host "`nTesting download of $($testFile.file_name)..." -ForegroundColor Yellow
        
        try {
            $downloadResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/export/files/$($testFile.id)/download" -Method GET -Headers $headers
            Write-Host "Download successful - Size: $($downloadResponse.Headers.'Content-Length') bytes" -ForegroundColor Green
        } catch {
            Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "Failed to get files: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Test Completed ===" -ForegroundColor Green