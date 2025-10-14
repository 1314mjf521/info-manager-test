# Simple PDF Test
Write-Host "=== PDF Export Test ===" -ForegroundColor Green

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

    # Create PDF export task
    Write-Host "Creating PDF export task..." -ForegroundColor Yellow
    
    $exportData = @{
        task_name = "PDF Chinese Test"
        format = "pdf"
        fields = @("id", "title", "content", "created_at")
        config = @{
            include_headers = $true
        }
    }
    
    $exportResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/records" -Method POST -Headers $headers -Body ($exportData | ConvertTo-Json) -ContentType "application/json"
    $taskId = $exportResponse.data.task_id
    
    Write-Host "PDF export task created - Task ID: $taskId" -ForegroundColor Green

    # Wait for task completion
    Write-Host "Waiting for PDF export task to complete..." -ForegroundColor Yellow
    Start-Sleep -Seconds 8

    # Check task status
    $taskResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/tasks/$taskId" -Method GET -Headers $headers
    $status = $taskResponse.data.status
    $progress = $taskResponse.data.progress
    
    Write-Host "Task status: $status ($progress%)" -ForegroundColor Cyan
    
    if ($status -eq "completed") {
        Write-Host "PDF export task completed!" -ForegroundColor Green
        
        # Get generated PDF file
        $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/files" -Method GET -Headers $headers
        $pdfFiles = $filesResponse.data.files | Where-Object { $_.format -eq "pdf" } | Sort-Object created_at -Descending
        
        if ($pdfFiles.Count -gt 0) {
            $latestPdfFile = $pdfFiles[0]
            $fileName = $latestPdfFile.file_name
            $fileSize = $latestPdfFile.file_size
            
            Write-Host "Latest PDF file: $fileName ($fileSize bytes)" -ForegroundColor Green
            
            # Test download
            $downloadPath = "test\downloaded_pdf_test.pdf"
            $downloadResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/export/files/$($latestPdfFile.id)/download" -Method GET -Headers $headers -OutFile $downloadPath
            
            if (Test-Path $downloadPath) {
                $downloadedSize = (Get-Item $downloadPath).Length
                Write-Host "PDF file downloaded successfully: $downloadPath ($downloadedSize bytes)" -ForegroundColor Green
                
                # Check PDF content
                $pdfContent = Get-Content $downloadPath -Raw -Encoding UTF8
                
                if ($pdfContent -match "%PDF") {
                    Write-Host "PDF format is correct" -ForegroundColor Green
                } else {
                    Write-Host "PDF format may have issues" -ForegroundColor Red
                }
                
                if ($downloadedSize -gt 500) {
                    Write-Host "PDF file size is reasonable ($downloadedSize bytes)" -ForegroundColor Green
                } else {
                    Write-Host "PDF file may be too small ($downloadedSize bytes)" -ForegroundColor Yellow
                }
            }
        }
    } elseif ($status -eq "failed") {
        $errorMessage = $taskResponse.data.error_message
        Write-Host "PDF export task failed: $errorMessage" -ForegroundColor Red
    }

} catch {
    Write-Host "Error during test: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Stop server
    if ($serverProcess -and !$serverProcess.HasExited) {
        Write-Host "Stopping server..." -ForegroundColor Yellow
        Stop-Process -Id $serverProcess.Id -Force
    }
}

Write-Host "=== PDF Export Test Completed ===" -ForegroundColor Green