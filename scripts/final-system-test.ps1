# Final System Test - Complete Functionality Verification
Write-Host "=== FINAL SYSTEM TEST ===" -ForegroundColor Green
Write-Host "Testing all major system functionalities..." -ForegroundColor Yellow

$testResults = @()

# Test 1: User Authentication
Write-Host "`n1. Testing User Authentication..." -ForegroundColor Cyan
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    
    $testResults += @{Test="User Authentication"; Status="✅ PASS"; Details="Admin login successful"}
    Write-Host "✅ Authentication: PASS" -ForegroundColor Green
} catch {
    $testResults += @{Test="User Authentication"; Status="❌ FAIL"; Details=$_.Exception.Message}
    Write-Host "❌ Authentication: FAIL" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
}

# Test 2: Ticket CRUD Operations
Write-Host "`n2. Testing Ticket CRUD Operations..." -ForegroundColor Cyan

# Create ticket
try {
    $ticketData = @{
        title = "Final Test Ticket"
        description = "This is a final system test ticket"
        type = "bug"
        priority = "high"
    } | ConvertTo-Json

    $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method POST -Body $ticketData -ContentType "application/json" -Headers $headers
    $ticketId = $createResponse.data.id
    
    $testResults += @{Test="Ticket Creation"; Status="✅ PASS"; Details="Ticket ID: $ticketId"}
    Write-Host "✅ Ticket Creation: PASS (ID: $ticketId)" -ForegroundColor Green
} catch {
    $testResults += @{Test="Ticket Creation"; Status="❌ FAIL"; Details=$_.Exception.Message}
    Write-Host "❌ Ticket Creation: FAIL" -ForegroundColor Red
}

# Read ticket
try {
    $readResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId" -Method GET -Headers $headers
    $testResults += @{Test="Ticket Reading"; Status="✅ PASS"; Details="Retrieved ticket: $($readResponse.data.title)"}
    Write-Host "✅ Ticket Reading: PASS" -ForegroundColor Green
} catch {
    $testResults += @{Test="Ticket Reading"; Status="❌ FAIL"; Details=$_.Exception.Message}
    Write-Host "❌ Ticket Reading: FAIL" -ForegroundColor Red
}

# Update ticket
try {
    $updateData = @{
        title = "Updated Final Test Ticket"
        priority = "critical"
    } | ConvertTo-Json

    $updateResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId" -Method PUT -Body $updateData -ContentType "application/json" -Headers $headers
    $testResults += @{Test="Ticket Update"; Status="✅ PASS"; Details="Updated ticket title"}
    Write-Host "✅ Ticket Update: PASS" -ForegroundColor Green
} catch {
    $testResults += @{Test="Ticket Update"; Status="❌ FAIL"; Details=$_.Exception.Message}
    Write-Host "❌ Ticket Update: FAIL" -ForegroundColor Red
}

# Test 3: Import/Export Functionality
Write-Host "`n3. Testing Import/Export Functionality..." -ForegroundColor Cyan

# Test Import
try {
    $csvContent = @"
title,type,priority,description
Final Test Import 1,support,normal,First final test import
Final Test Import 2,feature,low,Second final test import
"@

    $tempDir = $env:TEMP
    $csvFile = Join-Path $tempDir "final_test_import.csv"
    $csvContent | Out-File -FilePath $csvFile -Encoding UTF8

    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    
    $fileBytes = [System.IO.File]::ReadAllBytes($csvFile)
    $fileEnc = [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($fileBytes)
    
    $bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"final_test_import.csv`"",
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
    
    $testResults += @{Test="Ticket Import"; Status="✅ PASS"; Details="Imported $($importResult.data.count) tickets"}
    Write-Host "✅ Ticket Import: PASS ($($importResult.data.count) tickets)" -ForegroundColor Green
    
    Remove-Item $csvFile -ErrorAction SilentlyContinue
} catch {
    $testResults += @{Test="Ticket Import"; Status="❌ FAIL"; Details=$_.Exception.Message}
    Write-Host "❌ Ticket Import: FAIL" -ForegroundColor Red
}

# Test Export
try {
    $exportResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/tickets/export?format=csv" -Method GET -Headers $headers
    
    $exportFile = Join-Path $tempDir "final_test_export.csv"
    $exportResponse.Content | Out-File -FilePath $exportFile -Encoding UTF8
    
    $exportLines = Get-Content $exportFile
    $exportCount = $exportLines.Count - 1
    
    $testResults += @{Test="Ticket Export"; Status="✅ PASS"; Details="Exported $exportCount tickets"}
    Write-Host "✅ Ticket Export: PASS ($exportCount tickets)" -ForegroundColor Green
    
    Remove-Item $exportFile -ErrorAction SilentlyContinue
} catch {
    $testResults += @{Test="Ticket Export"; Status="❌ FAIL"; Details=$_.Exception.Message}
    Write-Host "❌ Ticket Export: FAIL" -ForegroundColor Red
}

# Test 4: Permission System
Write-Host "`n4. Testing Permission System..." -ForegroundColor Cyan

# Test admin permissions
try {
    $usersResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/users" -Method GET -Headers $headers
    $testResults += @{Test="Admin Permissions"; Status="✅ PASS"; Details="Admin can access user management"}
    Write-Host "✅ Admin Permissions: PASS" -ForegroundColor Green
} catch {
    $testResults += @{Test="Admin Permissions"; Status="❌ FAIL"; Details=$_.Exception.Message}
    Write-Host "❌ Admin Permissions: FAIL" -ForegroundColor Red
}

# Test tiker user permissions
try {
    $tikerLoginData = @{
        username = "tiker_test"
        password = "tiker123"
    } | ConvertTo-Json

    $tikerLoginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $tikerLoginData -ContentType "application/json"
    $tikerToken = $tikerLoginResponse.data.token
    
    $tikerHeaders = @{
        "Authorization" = "Bearer $tikerToken"
    }
    
    # Tiker should be able to access tickets
    $tikerTicketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $tikerHeaders
    
    # Tiker should NOT be able to access admin functions
    try {
        $tikerAdminResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/users" -Method GET -Headers $tikerHeaders
        $testResults += @{Test="Tiker Permissions"; Status="❌ FAIL"; Details="Tiker can access admin functions (security issue)"}
        Write-Host "❌ Tiker Permissions: FAIL (Security Issue)" -ForegroundColor Red
    } catch {
        $testResults += @{Test="Tiker Permissions"; Status="✅ PASS"; Details="Tiker correctly denied admin access"}
        Write-Host "✅ Tiker Permissions: PASS" -ForegroundColor Green
    }
} catch {
    $testResults += @{Test="Tiker Permissions"; Status="❌ FAIL"; Details=$_.Exception.Message}
    Write-Host "❌ Tiker Permissions: FAIL" -ForegroundColor Red
}

# Test 5: System Health
Write-Host "`n5. Testing System Health..." -ForegroundColor Cyan
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET
    $testResults += @{Test="System Health"; Status="✅ PASS"; Details="System is healthy"}
    Write-Host "✅ System Health: PASS" -ForegroundColor Green
} catch {
    $testResults += @{Test="System Health"; Status="❌ FAIL"; Details=$_.Exception.Message}
    Write-Host "❌ System Health: FAIL" -ForegroundColor Red
}

# Clean up test ticket
if ($ticketId) {
    try {
        Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId" -Method DELETE -Headers $headers
        Write-Host "🧹 Cleaned up test ticket" -ForegroundColor Gray
    } catch {
        Write-Host "⚠️ Could not clean up test ticket" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Green
$passCount = ($testResults | Where-Object { $_.Status -like "*PASS*" }).Count
$failCount = ($testResults | Where-Object { $_.Status -like "*FAIL*" }).Count
$totalTests = $testResults.Count

Write-Host "Total Tests: $totalTests" -ForegroundColor Yellow
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red

Write-Host "`nDetailed Results:" -ForegroundColor Yellow
$testResults | ForEach-Object {
    Write-Host "- $($_.Test): $($_.Status)" -ForegroundColor Gray
    if ($_.Details) {
        Write-Host "  $($_.Details)" -ForegroundColor DarkGray
    }
}

if ($failCount -eq 0) {
    Write-Host "`n🎉 ALL TESTS PASSED! System is fully functional." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️ Some tests failed. Please review the results above." -ForegroundColor Yellow
    exit 1
}