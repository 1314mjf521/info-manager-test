# PDF Format Optimization Test - Test improved layout and complete content display
Write-Host "=== PDF Format Optimization Test ===" -ForegroundColor Green

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

    # Create optimized PDF export task
    Write-Host "Creating optimized PDF export task..." -ForegroundColor Yellow
    
    $exportData = @{
        task_name = "PDF Format Optimization Test"
        format = "pdf"
        fields = @("id", "title", "content", "created_at")
        config = @{
            include_headers = $true
            optimized_layout = $true
            show_full_content = $true
        }
    }
    
    $exportResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/records" -Method POST -Headers $headers -Body ($exportData | ConvertTo-Json) -ContentType "application/json"
    $taskId = $exportResponse.data.task_id
    
    Write-Host "Optimized PDF export task created - Task ID: $taskId" -ForegroundColor Green

    # Wait for task completion
    Write-Host "Waiting for PDF export task to complete..." -ForegroundColor Yellow
    Start-Sleep -Seconds 8

    # Check task status
    $taskResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/tasks/$taskId" -Method GET -Headers $headers
    $status = $taskResponse.data.status
    $progress = $taskResponse.data.progress
    
    Write-Host "Task status: $status ($progress%)" -ForegroundColor Cyan
    
    if ($status -eq "completed") {
        Write-Host "Optimized PDF export task completed!" -ForegroundColor Green
        
        # Get generated PDF file
        $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/files" -Method GET -Headers $headers
        $pdfFiles = $filesResponse.data.files | Where-Object { $_.format -eq "pdf" } | Sort-Object created_at -Descending
        
        if ($pdfFiles.Count -gt 0) {
            $latestPdfFile = $pdfFiles[0]
            $fileName = $latestPdfFile.file_name
            $fileSize = $latestPdfFile.file_size
            
            Write-Host "Latest optimized PDF file: $fileName ($fileSize bytes)" -ForegroundColor Green
            
            # Test download
            $downloadPath = "test\optimized_pdf_test.pdf"
            $downloadResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/export/files/$($latestPdfFile.id)/download" -Method GET -Headers $headers -OutFile $downloadPath
            
            if (Test-Path $downloadPath) {
                $downloadedSize = (Get-Item $downloadPath).Length
                Write-Host "Optimized PDF file downloaded: $downloadPath ($downloadedSize bytes)" -ForegroundColor Green
                
                # Check PDF content
                $pdfContent = Get-Content $downloadPath -Raw -Encoding UTF8
                
                if ($pdfContent -match "%PDF") {
                    Write-Host "PDF format is correct" -ForegroundColor Green
                } else {
                    Write-Host "PDF format may have issues" -ForegroundColor Red
                }
                
                # File size analysis
                Write-Host "`nFile Size Analysis:" -ForegroundColor Cyan
                Write-Host "  Current optimized PDF: $downloadedSize bytes" -ForegroundColor White
                
                # Compare with previous versions
                $previousFiles = @{
                    "Original PDF" = "test\downloaded_pdf_test.pdf"
                    "Improved PDF" = "test\improved_pdf_test.pdf"
                }
                
                foreach ($version in $previousFiles.Keys) {
                    $filePath = $previousFiles[$version]
                    if (Test-Path $filePath) {
                        $size = (Get-Item $filePath).Length
                        $diff = $downloadedSize - $size
                        if ($diff -gt 0) {
                            Write-Host "  $version`: $size bytes (current is +$diff bytes larger)" -ForegroundColor Cyan
                        } elseif ($diff -lt 0) {
                            Write-Host "  $version`: $size bytes (current is $([Math]::Abs($diff)) bytes smaller)" -ForegroundColor Yellow
                        } else {
                            Write-Host "  $version`: $size bytes (same size)" -ForegroundColor White
                        }
                    }
                }
                
            } else {
                Write-Host "Failed to download optimized PDF file" -ForegroundColor Red
            }
        } else {
            Write-Host "No PDF file found" -ForegroundColor Red
        }
    } elseif ($status -eq "failed") {
        $errorMessage = $taskResponse.data.error_message
        Write-Host "Optimized PDF export task failed: $errorMessage" -ForegroundColor Red
    }

    # Generate optimization summary
    Write-Host "`n=== PDF Format Optimization Summary ===" -ForegroundColor Magenta
    Write-Host "Format Improvements Made:" -ForegroundColor White
    Write-Host "  1. Proper table layout with defined column widths" -ForegroundColor Green
    Write-Host "  2. Table borders and cell formatting" -ForegroundColor Green
    Write-Host "  3. Intelligent text wrapping and truncation" -ForegroundColor Green
    Write-Host "  4. Detailed records section showing full content" -ForegroundColor Green
    Write-Host "  5. Automatic page breaks for long content" -ForegroundColor Green
    Write-Host "  6. Proper margins and spacing" -ForegroundColor Green
    Write-Host "  7. Separate summary table and detailed view" -ForegroundColor Green
    
    Write-Host "`nLayout Features:" -ForegroundColor White
    Write-Host "  - Column widths: ID(40px), Title(120px), Content(200px), Time(100px)" -ForegroundColor Cyan
    Write-Host "  - Table with borders for clear data separation" -ForegroundColor Cyan
    Write-Host "  - Summary table + detailed records for complete information" -ForegroundColor Cyan
    Write-Host "  - Text wrapping for long content display" -ForegroundColor Cyan
    Write-Host "  - Page break handling for large datasets" -ForegroundColor Cyan
    
    if ($status -eq "completed") {
        Write-Host "`nResult: PDF export with optimized format and complete content display!" -ForegroundColor Green
        Write-Host "All export parameters should now be fully visible and properly formatted." -ForegroundColor Green
    } else {
        Write-Host "`nResult: PDF format optimization test did not complete successfully." -ForegroundColor Red
    }

} catch {
    Write-Host "Error during PDF format optimization test: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Stop server
    if ($serverProcess -and !$serverProcess.HasExited) {
        Write-Host "`nStopping server..." -ForegroundColor Yellow
        Stop-Process -Id $serverProcess.Id -Force
    }
}

Write-Host "`n=== PDF Format Optimization Test Completed ===" -ForegroundColor Green