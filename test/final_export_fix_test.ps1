# Final Export Fix Test - Test improved Excel and PDF exports
Write-Host "=== Final Export Fix Test ===" -ForegroundColor Green

# Login
$loginData = @{ username = "admin"; password = "admin123" }
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
$token = $loginResponse.data.token
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "Login successful" -ForegroundColor Green

# Test improved export formats
$formats = @("excel", "csv", "json", "pdf")
$exportTasks = @()

foreach ($format in $formats) {
    Write-Host "`nTesting improved $format export..." -ForegroundColor Yellow
    
    $exportData = @{
        task_name = "Final Fixed $format Export"
        format = $format
        fields = @("id", "title", "content", "created_at")
        config = @{
            include_headers = $true
            sheet_name = "数据导出"
        }
    }
    
    try {
        $exportResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/records" -Method POST -Headers $headers -Body ($exportData | ConvertTo-Json) -ContentType "application/json"
        $taskId = $exportResponse.data.task_id
        $exportTasks += @{ Format = $format; TaskId = $taskId; Status = "Created" }
        
        Write-Host "$format export task created - Task ID: $taskId" -ForegroundColor Green
    } catch {
        Write-Host "$format export failed: $($_.Exception.Message)" -ForegroundColor Red
        $exportTasks += @{ Format = $format; TaskId = $null; Status = "Failed" }
    }
}

# Wait for tasks to complete
Write-Host "`nWaiting for export tasks to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

# Check task status
Write-Host "`nChecking export task status..." -ForegroundColor Yellow
foreach ($task in $exportTasks) {
    if ($task.TaskId) {
        try {
            $taskResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/tasks/$($task.TaskId)" -Method GET -Headers $headers
            $status = $taskResponse.data.status
            $progress = $taskResponse.data.progress
            $errorMessage = $taskResponse.data.error_message
            
            if ($status -eq "completed") {
                Write-Host "  $($task.Format): COMPLETED ($progress%)" -ForegroundColor Green
            } elseif ($status -eq "failed") {
                Write-Host "  $($task.Format): FAILED - $errorMessage" -ForegroundColor Red
            } else {
                Write-Host "  $($task.Format): $status ($progress%)" -ForegroundColor Yellow
            }
            
            $task.Status = $status
            $task.Progress = $progress
        } catch {
            Write-Host "  $($task.Format): Error getting status" -ForegroundColor Red
            $task.Status = "Error"
        }
    }
}

# Check generated files
Write-Host "`nChecking generated files..." -ForegroundColor Yellow
try {
    $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/files" -Method GET -Headers $headers
    $files = $filesResponse.data.files
    
    # Get the latest files for each format
    $latestFiles = @{}
    foreach ($file in $files) {
        $format = $file.format
        if (-not $latestFiles.ContainsKey($format) -or $file.created_at -gt $latestFiles[$format].created_at) {
            $latestFiles[$format] = $file
        }
    }
    
    Write-Host "Latest export files:" -ForegroundColor Cyan
    foreach ($format in $formats) {
        if ($latestFiles.ContainsKey($format)) {
            $file = $latestFiles[$format]
            $fileName = $file.file_name
            $fileSize = $file.file_size
            
            Write-Host "  $format: $fileName ($fileSize bytes)" -ForegroundColor White
            
            # Test download
            try {
                $downloadResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/export/files/$($file.id)/download" -Method GET -Headers $headers
                Write-Host "    Download: SUCCESS" -ForegroundColor Green
            } catch {
                Write-Host "    Download: FAILED" -ForegroundColor Red
            }
        } else {
            Write-Host "  $format: No file found" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "Failed to get files: $($_.Exception.Message)" -ForegroundColor Red
}

# Generate final summary
Write-Host "`n=== Final Export Fix Summary ===" -ForegroundColor Magenta

$completedTasks = ($exportTasks | Where-Object { $_.Status -eq "completed" }).Count
$totalTasks = $exportTasks.Count

Write-Host "Export Task Results:" -ForegroundColor White
Write-Host "  Total formats tested: $totalTasks" -ForegroundColor Cyan
Write-Host "  Successfully completed: $completedTasks" -ForegroundColor Green
Write-Host "  Success rate: $([math]::Round($completedTasks / $totalTasks * 100, 2))%" -ForegroundColor Yellow

Write-Host "`nExpected Improvements:" -ForegroundColor White
Write-Host "  Excel files: Should now be proper .xlsx format with styling" -ForegroundColor Cyan
Write-Host "  PDF files: Should have better structure and no encoding issues" -ForegroundColor Cyan
Write-Host "  CSV files: Should maintain UTF-8 encoding" -ForegroundColor Cyan
Write-Host "  JSON files: Should remain unchanged (already working)" -ForegroundColor Cyan

if ($completedTasks -eq $totalTasks) {
    Write-Host "`n🎉 All export formats completed successfully!" -ForegroundColor Green
    Write-Host "Please manually test the downloaded files to verify:" -ForegroundColor Yellow
    Write-Host "  1. Excel files can be opened in Microsoft Excel" -ForegroundColor Yellow
    Write-Host "  2. PDF files display correctly without encoding issues" -ForegroundColor Yellow
    Write-Host "  3. CSV files show Chinese characters properly" -ForegroundColor Yellow
} else {
    Write-Host "`n⚠️ Some export tasks failed. Please check the error messages above." -ForegroundColor Yellow
}

Write-Host "`n=== Final Export Fix Test Completed ===" -ForegroundColor Green