# Test Export Fix
Write-Host "=== Test Export Fix ===" -ForegroundColor Green

# Login
$loginData = @{ username = "admin"; password = "admin123" }
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
$token = $loginResponse.data.token
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "Login successful" -ForegroundColor Green

# Test Excel export
Write-Host "`nTesting Excel export..." -ForegroundColor Yellow
$excelData = @{
    task_name = "Test Excel Export"
    format = "excel"
    fields = @("id", "title", "content", "created_at")
}

try {
    $excelResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/records" -Method POST -Headers $headers -Body ($excelData | ConvertTo-Json) -ContentType "application/json"
    $excelTaskId = $excelResponse.data.task_id
    Write-Host "Excel export task created - ID: $excelTaskId" -ForegroundColor Green
} catch {
    Write-Host "Excel export failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test PDF export
Write-Host "`nTesting PDF export..." -ForegroundColor Yellow
$pdfData = @{
    task_name = "Test PDF Export"
    format = "pdf"
    fields = @("id", "title", "content", "created_at")
}

try {
    $pdfResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/records" -Method POST -Headers $headers -Body ($pdfData | ConvertTo-Json) -ContentType "application/json"
    $pdfTaskId = $pdfResponse.data.task_id
    Write-Host "PDF export task created - ID: $pdfTaskId" -ForegroundColor Green
} catch {
    Write-Host "PDF export failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Wait for completion
Write-Host "`nWaiting for tasks to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check results
if ($excelTaskId) {
    Write-Host "`nChecking Excel task..." -ForegroundColor Yellow
    try {
        $taskResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/tasks/$excelTaskId" -Method GET -Headers $headers
        Write-Host "Excel task status: $($taskResponse.data.status)" -ForegroundColor Cyan
        if ($taskResponse.data.error_message) {
            Write-Host "Excel error: $($taskResponse.data.error_message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "Failed to check Excel task" -ForegroundColor Red
    }
}

if ($pdfTaskId) {
    Write-Host "`nChecking PDF task..." -ForegroundColor Yellow
    try {
        $taskResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/tasks/$pdfTaskId" -Method GET -Headers $headers
        Write-Host "PDF task status: $($taskResponse.data.status)" -ForegroundColor Cyan
        if ($taskResponse.data.error_message) {
            Write-Host "PDF error: $($taskResponse.data.error_message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "Failed to check PDF task" -ForegroundColor Red
    }
}

# List all files
Write-Host "`nListing all export files..." -ForegroundColor Yellow
try {
    $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/files" -Method GET -Headers $headers
    $files = $filesResponse.data.files
    
    Write-Host "Total files: $($files.Count)" -ForegroundColor Cyan
    
    # Show recent files
    $recentFiles = $files | Sort-Object created_at -Descending | Select-Object -First 5
    foreach ($file in $recentFiles) {
        Write-Host "  $($file.file_name) ($($file.format)) - $($file.file_size) bytes" -ForegroundColor White
    }
} catch {
    Write-Host "Failed to get files: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Test Completed ===" -ForegroundColor Green
Write-Host "Please manually check the generated files:" -ForegroundColor Yellow
Write-Host "1. Excel files should open in Microsoft Excel" -ForegroundColor Yellow
Write-Host "2. PDF files should display properly" -ForegroundColor Yellow
Write-Host "3. CSV files should show Chinese characters correctly" -ForegroundColor Yellow