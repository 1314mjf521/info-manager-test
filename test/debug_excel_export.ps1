# Debug Excel Export Test
Write-Host "=== Debug Excel Export Test ===" -ForegroundColor Green

# Login
$loginData = @{ username = "admin"; password = "admin123" }
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
$token = $loginResponse.data.token
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "✓ Login successful" -ForegroundColor Green

# Test Excel export with detailed error handling
Write-Host "`nTesting Excel export with debug info..." -ForegroundColor Yellow

$exportData = @{
    task_name = "Debug Excel Export"
    format = "excel"
    fields = @("id", "title")  # Simplified fields
    config = @{
        sheet_name = "TestData"
        include_headers = $true
    }
}

try {
    $exportResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/records" -Method POST -Headers $headers -Body ($exportData | ConvertTo-Json) -ContentType "application/json"
    $taskId = $exportResponse.data.task_id
    
    Write-Host "✓ Excel export task created - Task ID: $taskId" -ForegroundColor Green
    
    # Wait and check status multiple times
    for ($i = 1; $i -le 5; $i++) {
        Start-Sleep -Seconds 2
        
        try {
            $taskResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/tasks/$taskId" -Method GET -Headers $headers
            $status = $taskResponse.data.status
            $progress = $taskResponse.data.progress
            $errorMessage = $taskResponse.data.error_message
            
            Write-Host "Check $i - Status: $status, Progress: $progress%" -ForegroundColor Cyan
            
            if ($errorMessage) {
                Write-Host "Error Message: $errorMessage" -ForegroundColor Red
            }
            
            if ($status -eq "completed" -or $status -eq "failed") {
                break
            }
        } catch {
            Write-Host "Check $i - Failed to get task status: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "✗ Excel export failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try to get more error details
    if ($_.Exception.Response) {
        try {
            $responseStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($responseStream)
            $responseBody = $reader.ReadToEnd()
            Write-Host "Response Body: $responseBody" -ForegroundColor Gray
        } catch {
            Write-Host "Could not read error response" -ForegroundColor Gray
        }
    }
}

Write-Host "`n=== Debug Excel Export Test Completed ===" -ForegroundColor Green