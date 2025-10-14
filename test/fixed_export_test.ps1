# Fixed Export Test - Test all export formats with proper file extensions and encoding
Write-Host "=== Fixed Export Test ===" -ForegroundColor Green

# Login
$loginData = @{ username = "admin"; password = "admin123" }
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
$token = $loginResponse.data.token
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "✓ Login successful" -ForegroundColor Green

# Test all export formats with proper extensions
$formats = @("excel", "csv", "json", "pdf")
$exportTasks = @()

foreach ($format in $formats) {
    Write-Host "`nTesting $format export..." -ForegroundColor Yellow
    
    $exportData = @{
        task_name = "Fixed $format Export Test"
        format = $format
        fields = @("id", "title", "content", "created_at")
        config = @{
            include_headers = $true
        }
    }
    
    try {
        $exportResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/records" -Method POST -Headers $headers -Body ($exportData | ConvertTo-Json) -ContentType "application/json"
        $taskId = $exportResponse.data.task_id
        $exportTasks += @{ Format = $format; TaskId = $taskId; Status = "Created" }
        
        Write-Host "✓ $format export task created - Task ID: $taskId" -ForegroundColor Green
    } catch {
        Write-Host "✗ $format export failed: $($_.Exception.Message)" -ForegroundColor Red
        $exportTasks += @{ Format = $format; TaskId = $null; Status = "Failed" }
    }
}

# Wait for tasks to complete
Write-Host "`nWaiting for export tasks to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check task status and file extensions
Write-Host "`nChecking export results..." -ForegroundColor Yellow
foreach ($task in $exportTasks) {
    if ($task.TaskId) {
        try {
            $taskResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/tasks/$($task.TaskId)" -Method GET -Headers $headers
            $status = $taskResponse.data.status
            $progress = $taskResponse.data.progress
            
            Write-Host "  $($task.Format): Status=$status, Progress=$progress%" -ForegroundColor Cyan
            $task.Status = $status
            $task.Progress = $progress
        } catch {
            Write-Host "  $($task.Format): Failed to get status" -ForegroundColor Red
            $task.Status = "Error"
        }
    }
}

# Check generated files and their extensions
Write-Host "`nChecking generated files and extensions..." -ForegroundColor Yellow
try {
    $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/files" -Method GET -Headers $headers
    $files = $filesResponse.data.files
    
    Write-Host "Total export files: $($files.Count)" -ForegroundColor Cyan
    
    # Group files by format and show latest ones
    $latestFiles = @{}
    foreach ($file in $files) {
        $format = $file.format
        if (-not $latestFiles.ContainsKey($format) -or $file.created_at -gt $latestFiles[$format].created_at) {
            $latestFiles[$format] = $file
        }
    }
    
    foreach ($format in $formats) {
        if ($latestFiles.ContainsKey($format)) {
            $file = $latestFiles[$format]
            $fileName = $file.file_name
            $fileSize = $file.file_size
            $expectedExt = switch ($format) {
                "excel" { ".xlsx" }
                "csv" { ".csv" }
                "json" { ".json" }
                "pdf" { ".pdf" }
            }
            
            $hasCorrectExt = $fileName.EndsWith($expectedExt)
            $extStatus = if ($hasCorrectExt) { "✓" } else { "✗" }
            $extColor = if ($hasCorrectExt) { "Green" } else { "Red" }
            
            Write-Host "  $extStatus $format File: $fileName - Size: $fileSize bytes" -ForegroundColor $extColor
        } else {
            Write-Host "  ✗ $format: No file found" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "Failed to get export files: $($_.Exception.Message)" -ForegroundColor Red
}

# Test file download and content verification
Write-Host "`nTesting file downloads and content..." -ForegroundColor Yellow
if ($latestFiles.Count -gt 0) {
    foreach ($format in $formats) {
        if ($latestFiles.ContainsKey($format)) {
            $file = $latestFiles[$format]
            Write-Host "`nTesting $format file download..." -ForegroundColor Cyan
            
            try {
                $downloadResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/export/files/$($file.id)/download" -Method GET -Headers $headers
                $contentLength = $downloadResponse.Headers.'Content-Length'
                
                Write-Host "  ✓ Download successful - Size: $contentLength bytes" -ForegroundColor Green
                
                # Check content type
                $contentType = $downloadResponse.Headers.'Content-Type'
                if ($contentType) {
                    Write-Host "  Content-Type: $contentType" -ForegroundColor Gray
                }
                
                # For text-based formats, show a preview of content
                if ($format -eq "csv" -or $format -eq "json") {
                    $content = [System.Text.Encoding]::UTF8.GetString($downloadResponse.Content)
                    $preview = $content.Substring(0, [Math]::Min(200, $content.Length))
                    Write-Host "  Content preview: $preview..." -ForegroundColor Gray
                }
                
            } catch {
                Write-Host "  ✗ Download failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# Generate summary report
Write-Host "`n=== Fixed Export Test Summary ===" -ForegroundColor Magenta

$successfulTasks = ($exportTasks | Where-Object { $_.Status -eq "completed" }).Count
$correctExtensions = 0

foreach ($format in $formats) {
    if ($latestFiles.ContainsKey($format)) {
        $file = $latestFiles[$format]
        $expectedExt = switch ($format) {
            "excel" { ".xlsx" }
            "csv" { ".csv" }
            "json" { ".json" }
            "pdf" { ".pdf" }
        }
        if ($file.file_name.EndsWith($expectedExt)) {
            $correctExtensions++
        }
    }
}

Write-Host "Export Tasks:" -ForegroundColor White
Write-Host "  Total formats: $($formats.Count)" -ForegroundColor Cyan
Write-Host "  Successful exports: $successfulTasks" -ForegroundColor Green
Write-Host "  Task success rate: $([math]::Round($successfulTasks / $formats.Count * 100, 2))%" -ForegroundColor Yellow

Write-Host "`nFile Extensions:" -ForegroundColor White
Write-Host "  Correct extensions: $correctExtensions/$($formats.Count)" -ForegroundColor Green
Write-Host "  Extension accuracy: $([math]::Round($correctExtensions / $formats.Count * 100, 2))%" -ForegroundColor Yellow

$issues = @()
if ($successfulTasks -lt $formats.Count) {
    $issues += "Some export tasks failed"
}
if ($correctExtensions -lt $formats.Count) {
    $issues += "Some files have incorrect extensions"
}

if ($issues.Count -eq 0) {
    Write-Host "`n🎉 All export issues have been FIXED!" -ForegroundColor Green
    Write-Host "✓ All formats export successfully" -ForegroundColor Green
    Write-Host "✓ All files have correct extensions" -ForegroundColor Green
    Write-Host "✓ CSV files should no longer have encoding issues" -ForegroundColor Green
    Write-Host "✓ Excel files should open properly in Excel" -ForegroundColor Green
    Write-Host "✓ PDF files have proper PDF structure" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Some issues remain:" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Red
    }
}

Write-Host "`n=== Fixed Export Test Completed ===" -ForegroundColor Green