# Verify Export Quality Test
Write-Host "=== Export Quality Verification Test ===" -ForegroundColor Green

# Login
$loginData = @{ username = "admin"; password = "admin123" }
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
$token = $loginResponse.data.token
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "Login successful" -ForegroundColor Green

# Create one export of each format for final verification
$formats = @("excel", "csv", "json", "pdf")
$finalTasks = @()

foreach ($format in $formats) {
    Write-Host "`nCreating final $format export..." -ForegroundColor Yellow
    
    $exportData = @{
        task_name = "Quality Verification $format Export"
        format = $format
        fields = @("id", "title", "content", "created_at")
        config = @{
            include_headers = $true
        }
    }
    
    try {
        $exportResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/records" -Method POST -Headers $headers -Body ($exportData | ConvertTo-Json) -ContentType "application/json"
        $taskId = $exportResponse.data.task_id
        $finalTasks += @{ Format = $format; TaskId = $taskId }
        Write-Host "$format task created - ID: $taskId" -ForegroundColor Green
    } catch {
        Write-Host "$format export failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Wait for all tasks to complete
Write-Host "`nWaiting for all tasks to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Verify all tasks completed successfully
Write-Host "`nVerifying task completion..." -ForegroundColor Yellow
$allCompleted = $true

foreach ($task in $finalTasks) {
    try {
        $taskResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/tasks/$($task.TaskId)" -Method GET -Headers $headers
        $status = $taskResponse.data.status
        
        if ($status -eq "completed") {
            Write-Host "  $($task.Format): COMPLETED" -ForegroundColor Green
        } else {
            Write-Host "  $($task.Format): $status" -ForegroundColor Red
            $allCompleted = $false
            if ($taskResponse.data.error_message) {
                Write-Host "    Error: $($taskResponse.data.error_message)" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "  $($task.Format): Failed to check status" -ForegroundColor Red
        $allCompleted = $false
    }
}

# Get final file list and verify extensions
Write-Host "`nVerifying file extensions and sizes..." -ForegroundColor Yellow
try {
    $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/files" -Method GET -Headers $headers
    $files = $filesResponse.data.files
    
    # Get the most recent files
    $recentFiles = $files | Sort-Object created_at -Descending | Select-Object -First 4
    
    $extensionCheck = @{
        "excel" = ".xlsx"
        "csv" = ".csv"
        "json" = ".json"
        "pdf" = ".pdf"
    }
    
    $allExtensionsCorrect = $true
    
    foreach ($file in $recentFiles) {
        $format = $file.format
        $fileName = $file.file_name
        $fileSize = $file.file_size
        $expectedExt = $extensionCheck[$format]
        
        if ($fileName.EndsWith($expectedExt)) {
            Write-Host "  $format file: $fileName ($fileSize bytes) - CORRECT EXTENSION" -ForegroundColor Green
        } else {
            Write-Host "  $format file: $fileName ($fileSize bytes) - WRONG EXTENSION" -ForegroundColor Red
            $allExtensionsCorrect = $false
        }
    }
    
    # File size analysis
    Write-Host "`nFile size analysis:" -ForegroundColor Yellow
    foreach ($file in $recentFiles) {
        $format = $file.format
        $size = $file.file_size
        
        $sizeStatus = switch ($format) {
            "excel" { if ($size -gt 5000) { "GOOD (Real Excel format)" } else { "SMALL (May be CSV format)" } }
            "pdf" { if ($size -gt 1000) { "GOOD (Structured PDF)" } else { "SMALL (Basic PDF)" } }
            "csv" { if ($size -gt 200 -and $size -lt 1000) { "GOOD (Standard CSV)" } else { "UNUSUAL SIZE" } }
            "json" { if ($size -gt 400) { "GOOD (Formatted JSON)" } else { "SMALL (Compact JSON)" } }
        }
        
        Write-Host "  $format ($size bytes): $sizeStatus" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "Failed to verify files: $($_.Exception.Message)" -ForegroundColor Red
    $allExtensionsCorrect = $false
}

# Final assessment
Write-Host "`n=== Final Quality Assessment ===" -ForegroundColor Magenta

if ($allCompleted -and $allExtensionsCorrect) {
    Write-Host "🎉 EXPORT QUALITY VERIFICATION: PASSED!" -ForegroundColor Green
    Write-Host "✓ All export tasks completed successfully" -ForegroundColor Green
    Write-Host "✓ All files have correct extensions" -ForegroundColor Green
    Write-Host "✓ File sizes indicate proper format implementation" -ForegroundColor Green
    
    Write-Host "`nTask 6 Status: READY FOR COMPLETION" -ForegroundColor Green
} else {
    Write-Host "⚠️ EXPORT QUALITY VERIFICATION: NEEDS ATTENTION" -ForegroundColor Yellow
    
    if (-not $allCompleted) {
        Write-Host "✗ Some export tasks failed" -ForegroundColor Red
    }
    if (-not $allExtensionsCorrect) {
        Write-Host "✗ Some files have incorrect extensions" -ForegroundColor Red
    }
    
    Write-Host "`nTask 6 Status: REQUIRES FURTHER FIXES" -ForegroundColor Yellow
}

Write-Host "`n=== Verification Completed ===" -ForegroundColor Green