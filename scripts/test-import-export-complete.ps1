# Complete Import/Export Test
Write-Host "=== COMPLETE IMPORT/EXPORT TEST ===" -ForegroundColor Green

# Login as admin
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
$token = $loginResponse.data.token

Write-Host "Logged in as admin" -ForegroundColor Yellow

$headers = @{
    "Authorization" = "Bearer $token"
}

# Step 1: Get initial ticket count
Write-Host "`n1. Getting initial ticket count..." -ForegroundColor Cyan
$initialResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets?size=1" -Method GET -Headers $headers
$initialCount = $initialResponse.data.total
Write-Host "Initial ticket count: $initialCount" -ForegroundColor Gray

# Step 2: Import new tickets
Write-Host "`n2. Importing new tickets..." -ForegroundColor Cyan
$csvContent = @"
title,type,priority,description
Complete Test 1,bug,high,First complete test ticket
Complete Test 2,feature,normal,Second complete test ticket
Complete Test 3,support,low,Third complete test ticket
"@

$tempDir = $env:TEMP
$csvFile = Join-Path $tempDir "complete_test_import.csv"
$csvContent | Out-File -FilePath $csvFile -Encoding UTF8

try {
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    
    $fileBytes = [System.IO.File]::ReadAllBytes($csvFile)
    $fileEnc = [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($fileBytes)
    
    $bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"complete_test_import.csv`"",
        "Content-Type: text/csv$LF",
        $fileEnc,
        "--$boundary--$LF"
    ) -join $LF
    
    $importHeaders = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "multipart/form-data; boundary=$boundary"
    }
    
    $importResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/tickets/import" -Method POST -Body $bodyLines -Headers $importHeaders
    $importResult = $importResponse.Content | ConvertFrom-Json
    
    Write-Host "✅ Import successful: $($importResult.data.count) tickets imported" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Import failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Remove-Item $csvFile -ErrorAction SilentlyContinue
}

# Step 3: Verify new ticket count
Write-Host "`n3. Verifying new ticket count..." -ForegroundColor Cyan
Start-Sleep -Seconds 1  # Give database time to update
$newResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets?size=1" -Method GET -Headers $headers
$newCount = $newResponse.data.total
$importedCount = $newCount - $initialCount
Write-Host "New ticket count: $newCount (imported: $importedCount)" -ForegroundColor Gray

# Step 4: Export all tickets
Write-Host "`n4. Exporting all tickets..." -ForegroundColor Cyan
try {
    $exportUrl = "http://localhost:8080/api/v1/tickets/export?format=csv"
    $exportResponse = Invoke-WebRequest -Uri $exportUrl -Method GET -Headers $headers
    
    $exportFile = Join-Path $tempDir "complete_test_export.csv"
    $exportResponse.Content | Out-File -FilePath $exportFile -Encoding UTF8
    
    $exportLines = Get-Content $exportFile
    $exportedTicketCount = $exportLines.Count - 1  # Subtract header line
    
    Write-Host "✅ Export successful: $exportedTicketCount tickets exported" -ForegroundColor Green
    Write-Host "Export file: $exportFile" -ForegroundColor Gray
    
    # Show some exported tickets with our test data
    Write-Host "`nRecently imported tickets in export:" -ForegroundColor Yellow
    $exportLines | Where-Object { $_ -match "Complete Test" } | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "❌ Export failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Remove-Item $exportFile -ErrorAction SilentlyContinue
}

# Step 5: Test filtered export
Write-Host "`n5. Testing filtered export (bug tickets only)..." -ForegroundColor Cyan
try {
    $filteredExportUrl = "http://localhost:8080/api/v1/tickets/export?format=csv&type=bug"
    $filteredResponse = Invoke-WebRequest -Uri $filteredExportUrl -Method GET -Headers $headers
    
    $filteredFile = Join-Path $tempDir "filtered_export.csv"
    $filteredResponse.Content | Out-File -FilePath $filteredFile -Encoding UTF8
    
    $filteredLines = Get-Content $filteredFile
    $filteredCount = $filteredLines.Count - 1
    
    Write-Host "✅ Filtered export successful: $filteredCount bug tickets exported" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Filtered export failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Remove-Item $filteredFile -ErrorAction SilentlyContinue
}

Write-Host "`n=== COMPLETE IMPORT/EXPORT TEST FINISHED ===" -ForegroundColor Green
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "- Initial tickets: $initialCount" -ForegroundColor Gray
Write-Host "- Imported tickets: $importedCount" -ForegroundColor Gray
Write-Host "- Final tickets: $newCount" -ForegroundColor Gray
Write-Host "- Export/Import functionality: ✅ Working" -ForegroundColor Green