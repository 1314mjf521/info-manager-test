# Final Comprehensive Export Test - Test all export formats after fixes
Write-Host "=== Final Comprehensive Export Test ===" -ForegroundColor Green

# Start server
Write-Host "Starting server..." -ForegroundColor Yellow
$serverProcess = Start-Process -FilePath ".\build\server.exe" -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 3

try {
    # Login
    $loginData = @{ username = "admin"; password = "admin123" }
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
    $token = $loginResponse.data.token
    $headers = @{ "Authorization" = "Bearer $token" }

    Write-Host "Login successful" -ForegroundColor Green

    # Test all export formats
    $formats = @("excel", "csv", "json", "pdf")
    $exportResults = @()

    foreach ($format in $formats) {
        Write-Host "`nTesting $format export..." -ForegroundColor Yellow
        
        $exportData = @{
            task_name = "Final Test $format Export"
            format = $format
            fields = @("id", "title", "content", "created_at")
            config = @{
                include_headers = $true
                sheet_name = "Export Data"
            }
        }
        
        try {
            $exportResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/records" -Method POST -Headers $headers -Body ($exportData | ConvertTo-Json) -ContentType "application/json"
            $taskId = $exportResponse.data.task_id
            
            Write-Host "$format export task created - Task ID: $taskId" -ForegroundColor Green
            $exportResults += @{ Format = $format; TaskId = $taskId; Status = "Created" }
        } catch {
            Write-Host "$format export failed: $($_.Exception.Message)" -ForegroundColor Red
            $exportResults += @{ Format = $format; TaskId = $null; Status = "Failed" }
        }
    }

    # Wait for all tasks to complete
    Write-Host "`nWaiting for all export tasks to complete..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10

    # Check all task statuses
    Write-Host "`nChecking export task statuses..." -ForegroundColor Yellow
    $completedTasks = 0
    $totalTasks = $exportResults.Count

    foreach ($result in $exportResults) {
        if ($result.TaskId) {
            try {
                $taskResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/tasks/$($result.TaskId)" -Method GET -Headers $headers
                $status = $taskResponse.data.status
                $progress = $taskResponse.data.progress
                
                if ($status -eq "completed") {
                    Write-Host "  $($result.Format): COMPLETED ($progress%)" -ForegroundColor Green
                    $result.Status = "Completed"
                    $completedTasks++
                } elseif ($status -eq "failed") {
                    $errorMessage = $taskResponse.data.error_message
                    Write-Host "  $($result.Format): FAILED - $errorMessage" -ForegroundColor Red
                    $result.Status = "Failed"
                } else {
                    Write-Host "  $($result.Format): $status ($progress%)" -ForegroundColor Yellow
                    $result.Status = $status
                }
            } catch {
                Write-Host "  $($result.Format): Error getting status" -ForegroundColor Red
                $result.Status = "Error"
            }
        } else {
            Write-Host "  $($result.Format): Not created" -ForegroundColor Red
        }
    }

    # Test file downloads
    Write-Host "`nTesting file downloads..." -ForegroundColor Yellow
    try {
        $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/files" -Method GET -Headers $headers
        $files = $filesResponse.data.files
        
        # Group files by format and get the latest for each
        $latestFiles = @{}
        foreach ($file in $files) {
            $format = $file.format
            if (-not $latestFiles.ContainsKey($format) -or $file.created_at -gt $latestFiles[$format].created_at) {
                $latestFiles[$format] = $file
            }
        }
        
        $downloadResults = @{}
        foreach ($format in $formats) {
            if ($latestFiles.ContainsKey($format)) {
                $file = $latestFiles[$format]
                $fileName = $file.file_name
                $fileSize = $file.file_size
                
                Write-Host "  $format file: $fileName ($fileSize bytes)" -ForegroundColor Cyan
                
                # Test download
                try {
                    $downloadPath = "test\final_test_$format.$format"
                    if ($format -eq "excel") { $downloadPath = "test\final_test_excel.xlsx" }
                    
                    $downloadResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/export/files/$($file.id)/download" -Method GET -Headers $headers -OutFile $downloadPath
                    
                    if (Test-Path $downloadPath) {
                        $downloadedSize = (Get-Item $downloadPath).Length
                        Write-Host "    Download: SUCCESS ($downloadedSize bytes)" -ForegroundColor Green
                        $downloadResults[$format] = "Success"
                    } else {
                        Write-Host "    Download: FAILED - File not found" -ForegroundColor Red
                        $downloadResults[$format] = "Failed"
                    }
                } catch {
                    Write-Host "    Download: FAILED - $($_.Exception.Message)" -ForegroundColor Red
                    $downloadResults[$format] = "Failed"
                }
            } else {
                Write-Host "  ${format}: No file found" -ForegroundColor Red
                $downloadResults[$format] = "No File"
            }
        }
    } catch {
        Write-Host "Failed to get files: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Generate comprehensive summary
    Write-Host "`n=== Final Comprehensive Test Summary ===" -ForegroundColor Magenta
    
    Write-Host "`nExport Task Results:" -ForegroundColor White
    Write-Host "  Total formats tested: $totalTasks" -ForegroundColor Cyan
    Write-Host "  Successfully completed: $completedTasks" -ForegroundColor Green
    Write-Host "  Success rate: $([math]::Round($completedTasks / $totalTasks * 100, 2))%" -ForegroundColor Yellow
    
    Write-Host "`nDetailed Results:" -ForegroundColor White
    foreach ($result in $exportResults) {
        $downloadStatus = if ($downloadResults.ContainsKey($result.Format)) { $downloadResults[$result.Format] } else { "Unknown" }
        Write-Host "  $($result.Format): Export=$($result.Status), Download=$downloadStatus" -ForegroundColor Cyan
    }
    
    Write-Host "`nKey Improvements Made:" -ForegroundColor White
    Write-Host "  1. PDF Export: Fixed encoding issues using gofpdf library" -ForegroundColor Green
    Write-Host "  2. Excel Export: Maintained proper .xlsx format with styling" -ForegroundColor Green
    Write-Host "  3. CSV Export: Preserved UTF-8 BOM for Chinese character support" -ForegroundColor Green
    Write-Host "  4. JSON Export: Already working correctly" -ForegroundColor Green
    
    if ($completedTasks -eq $totalTasks) {
        Write-Host "`n🎉 All export formats completed successfully!" -ForegroundColor Green
        Write-Host "Task 6 (Data Export Service) is now fully functional." -ForegroundColor Green
    } else {
        Write-Host "`n⚠️ Some export tasks failed. Please check the error messages above." -ForegroundColor Yellow
    }

} catch {
    Write-Host "Error during comprehensive test: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Stop server
    if ($serverProcess -and !$serverProcess.HasExited) {
        Write-Host "`nStopping server..." -ForegroundColor Yellow
        Stop-Process -Id $serverProcess.Id -Force
    }
}

Write-Host "`n=== Final Comprehensive Export Test Completed ===" -ForegroundColor Green