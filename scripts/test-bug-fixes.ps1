# Test Bug Fixes
# This script specifically tests the two issues found in the comprehensive test

Write-Host "=== TESTING BUG FIXES ===" -ForegroundColor Green

# Login as admin to test both issues
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
$token = $loginResponse.data.token
$headers = @{"Authorization" = "Bearer $token"; "Content-Type" = "application/json"}

Write-Host "Logged in as admin" -ForegroundColor Yellow

# Create a test ticket for reject testing
Write-Host "`n=== BUG FIX 1: REJECT TICKET ====" -ForegroundColor Magenta

# First create a ticket
$createData = @{
    title = "Test Reject Ticket"
    description = "This ticket will be used to test reject functionality"
    type = "support"
    priority = "normal"
} | ConvertTo-Json

$createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method POST -Headers $headers -Body $createData
$testTicketId = $createResponse.data.id
Write-Host "Created test ticket ID: $testTicketId" -ForegroundColor Cyan

# Assign the ticket to admin (so it can be rejected)
$assignData = @{
    assignee_id = 1
    comment = "Assigning for reject test"
    auto_accept = $false
} | ConvertTo-Json

$assignResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$testTicketId/assign" -Method POST -Headers $headers -Body $assignData
Write-Host "Assigned ticket to admin" -ForegroundColor Cyan

# Now test reject
try {
    $rejectData = @{comment = "Testing reject functionality"} | ConvertTo-Json
    $rejectResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$testTicketId/reject" -Method POST -Headers $headers -Body $rejectData
    Write-Host "✅ REJECT TICKET: SUCCESS - Bug fixed!" -ForegroundColor Green
    Write-Host "   Ticket status: $($rejectResponse.data.status)" -ForegroundColor Gray
} catch {
    Write-Host "❌ REJECT TICKET: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Clean up test ticket
try {
    $deleteResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$testTicketId" -Method DELETE -Headers $headers
    Write-Host "Cleaned up test ticket" -ForegroundColor Gray
} catch {
    Write-Host "Failed to clean up test ticket: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test import functionality
Write-Host "`n=== BUG FIX 2: IMPORT TICKETS ====" -ForegroundColor Magenta

# Create a temporary CSV file
$csvContent = @"
title,type,priority,description
Import Test Ticket 1,support,normal,First test ticket from import
Import Test Ticket 2,bug,high,Second test ticket from import
Import Test Ticket 3,feature,low,Third test ticket from import
"@

$tempCsvFile = [System.IO.Path]::GetTempFileName()
$csvFile = $tempCsvFile + ".csv"
$csvContent | Out-File -FilePath $csvFile -Encoding UTF8

Write-Host "Created temporary CSV file: $csvFile" -ForegroundColor Cyan

# Test import using curl (since PowerShell doesn't handle multipart well)
try {
    # Check if curl is available
    $curlPath = Get-Command curl -ErrorAction SilentlyContinue
    if ($curlPath) {
        Write-Host "Using curl for file upload..." -ForegroundColor Cyan
        $curlCommand = "curl -X POST -H `"Authorization: Bearer $token`" -F `"file=@$csvFile`" http://localhost:8080/api/v1/tickets/import"
        $importResult = Invoke-Expression $curlCommand 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ IMPORT TICKETS: SUCCESS - Bug fixed!" -ForegroundColor Green
            Write-Host "   Import result: $importResult" -ForegroundColor Gray
        } else {
            Write-Host "❌ IMPORT TICKETS: CURL FAILED" -ForegroundColor Red
        }
    } else {
        Write-Host "⚠️  IMPORT TICKETS: SKIPPED - curl not available" -ForegroundColor Yellow
        Write-Host "   Manual test required with file upload" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ IMPORT TICKETS: FAILED - $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Clean up temp file
    Remove-Item $csvFile -ErrorAction SilentlyContinue
    Remove-Item $tempCsvFile -ErrorAction SilentlyContinue
}

# Alternative test for import - test the permission check at least
Write-Host "`n--- Testing Import Permission Check ---" -ForegroundColor Cyan
try {
    # Try to access import endpoint without file (should get 400 for missing file, not 403 for permission)
    $importResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/import" -Method POST -Headers $headers
    Write-Host "Import permission check: UNEXPECTED SUCCESS" -ForegroundColor Yellow
} catch {
    if ($_.Exception.Message -like "*400*" -or $_.Exception.Message -like "*Bad Request*") {
        Write-Host "✅ Import permission check: CORRECT (400 Bad Request - missing file)" -ForegroundColor Green
    } elseif ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
        Write-Host "❌ Import permission check: FAILED (403 Forbidden - permission issue)" -ForegroundColor Red
    } else {
        Write-Host "⚠️  Import permission check: UNKNOWN - $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n=== BUG FIX TEST COMPLETED ===" -ForegroundColor Green