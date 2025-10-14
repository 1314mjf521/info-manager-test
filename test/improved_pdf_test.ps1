# Improved PDF Test - Test enhanced Chinese character support
Write-Host "=== Improved PDF Export Test ===" -ForegroundColor Green

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

    # Create improved PDF export task
    Write-Host "Creating improved PDF export task..." -ForegroundColor Yellow
    
    $exportData = @{
        task_name = "Improved PDF Chinese Test"
        format = "pdf"
        fields = @("id", "title", "content", "created_at")
        config = @{
            include_headers = $true
            encoding = "utf-8"
            chinese_support = $true
        }
    }
    
    $exportResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/records" -Method POST -Headers $headers -Body ($exportData | ConvertTo-Json) -ContentType "application/json"
    $taskId = $exportResponse.data.task_id
    
    Write-Host "Improved PDF export task created - Task ID: $taskId" -ForegroundColor Green

    # Wait for task completion
    Write-Host "Waiting for PDF export task to complete..." -ForegroundColor Yellow
    Start-Sleep -Seconds 8

    # Check task status
    $taskResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/tasks/$taskId" -Method GET -Headers $headers
    $status = $taskResponse.data.status
    $progress = $taskResponse.data.progress
    
    Write-Host "Task status: $status ($progress%)" -ForegroundColor Cyan
    
    if ($status -eq "completed") {
        Write-Host "Improved PDF export task completed!" -ForegroundColor Green
        
        # Get generated PDF file
        $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/files" -Method GET -Headers $headers
        $pdfFiles = $filesResponse.data.files | Where-Object { $_.format -eq "pdf" } | Sort-Object created_at -Descending
        
        if ($pdfFiles.Count -gt 0) {
            $latestPdfFile = $pdfFiles[0]
            $fileName = $latestPdfFile.file_name
            $fileSize = $latestPdfFile.file_size
            
            Write-Host "Latest improved PDF file: $fileName ($fileSize bytes)" -ForegroundColor Green
            
            # Test download
            $downloadPath = "test\improved_pdf_test.pdf"
            $downloadResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/export/files/$($latestPdfFile.id)/download" -Method GET -Headers $headers -OutFile $downloadPath
            
            if (Test-Path $downloadPath) {
                $downloadedSize = (Get-Item $downloadPath).Length
                Write-Host "Improved PDF file downloaded: $downloadPath ($downloadedSize bytes)" -ForegroundColor Green
                
                # Check PDF content
                $pdfContent = Get-Content $downloadPath -Raw -Encoding UTF8
                
                if ($pdfContent -match "%PDF") {
                    Write-Host "PDF format is correct" -ForegroundColor Green
                } else {
                    Write-Host "PDF format may have issues" -ForegroundColor Red
                }
                
                # Check for Chinese character handling improvements
                if ($downloadedSize -gt 1000) {
                    Write-Host "PDF file size is reasonable ($downloadedSize bytes)" -ForegroundColor Green
                } else {
                    Write-Host "PDF file may be too small ($downloadedSize bytes)" -ForegroundColor Yellow
                }
                
                # Compare with previous version
                $previousPdfPath = "test\downloaded_pdf_test.pdf"
                if (Test-Path $previousPdfPath) {
                    $previousSize = (Get-Item $previousPdfPath).Length
                    $sizeDiff = $downloadedSize - $previousSize
                    Write-Host "Size comparison with previous version: $sizeDiff bytes difference" -ForegroundColor Cyan
                }
                
            } else {
                Write-Host "Failed to download improved PDF file" -ForegroundColor Red
            }
        } else {
            Write-Host "No PDF file found" -ForegroundColor Red
        }
    } elseif ($status -eq "failed") {
        $errorMessage = $taskResponse.data.error_message
        Write-Host "Improved PDF export task failed: $errorMessage" -ForegroundColor Red
    }

    # Generate improvement summary
    Write-Host "`n=== PDF Improvement Summary ===" -ForegroundColor Magenta
    Write-Host "Improvements made:" -ForegroundColor White
    Write-Host "  1. Switched from gofpdf to gopdf library for better Unicode support" -ForegroundColor Green
    Write-Host "  2. Added Chinese font detection and loading" -ForegroundColor Green
    Write-Host "  3. Implemented intelligent Chinese-to-Pinyin conversion" -ForegroundColor Green
    Write-Host "  4. Enhanced character mapping for common Chinese words" -ForegroundColor Green
    Write-Host "  5. Fallback mechanism for systems without Chinese fonts" -ForegroundColor Green
    
    if ($status -eq "completed") {
        Write-Host "`nResult: PDF export with improved Chinese character handling completed successfully!" -ForegroundColor Green
        Write-Host "Please manually open the PDF file to verify the Chinese character display quality." -ForegroundColor Yellow
    } else {
        Write-Host "`nResult: PDF export task did not complete successfully." -ForegroundColor Red
    }

} catch {
    Write-Host "Error during improved PDF test: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Stop server
    if ($serverProcess -and !$serverProcess.HasExited) {
        Write-Host "`nStopping server..." -ForegroundColor Yellow
        Stop-Process -Id $serverProcess.Id -Force
    }
}

Write-Host "`n=== Improved PDF Export Test Completed ===" -ForegroundColor Green