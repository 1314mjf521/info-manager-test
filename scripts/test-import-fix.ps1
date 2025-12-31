# Test Import Fix with proper PowerShell method
Write-Host "=== TESTING IMPORT FIX ===" -ForegroundColor Green

# Login as admin
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
$token = $loginResponse.data.token

Write-Host "Logged in as admin" -ForegroundColor Yellow

# Create CSV content
$csvContent = @"
title,type,priority,description
Import Test 1,support,normal,First import test
Import Test 2,bug,high,Second import test
Import Test 3,feature,low,Third import test
"@

$tempDir = $env:TEMP
$csvFile = Join-Path $tempDir "test_import.csv"
$csvContent | Out-File -FilePath $csvFile -Encoding UTF8

Write-Host "Created CSV file: $csvFile" -ForegroundColor Cyan

# Test import using Invoke-WebRequest
try {
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    
    $fileBytes = [System.IO.File]::ReadAllBytes($csvFile)
    $fileEnc = [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($fileBytes)
    
    $bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"test_import.csv`"",
        "Content-Type: text/csv$LF",
        $fileEnc,
        "--$boundary--$LF"
    ) -join $LF
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "multipart/form-data; boundary=$boundary"
    }
    
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/tickets/import" -Method POST -Body $bodyLines -Headers $headers
    
    Write-Host "✅ IMPORT SUCCESS!" -ForegroundColor Green
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Gray
    
    # Parse JSON response to get import count
    try {
        $jsonResponse = $response.Content | ConvertFrom-Json
        if ($jsonResponse.success) {
            Write-Host "Imported $($jsonResponse.data.count) tickets successfully" -ForegroundColor Green
        }
    } catch {
        Write-Host "Response received but couldn't parse JSON" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ IMPORT FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody" -ForegroundColor Red
    }
} finally {
    # Clean up
    Remove-Item $csvFile -ErrorAction SilentlyContinue
}

Write-Host "`n=== IMPORT TEST COMPLETED ===" -ForegroundColor Green