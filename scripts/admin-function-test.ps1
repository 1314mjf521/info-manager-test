# Admin Function Test - Test all system functions with admin user
Write-Host "=== Admin Function Test ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080"
$testResults = @()

# Get admin authentication token
function Get-AdminToken {
    try {
        $loginData = @{
            username = "admin"
            password = "admin123"
        } | ConvertTo-Json -Compress
        
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        return $response.data.token
    } catch {
        Write-Host "Admin login failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Test API endpoint
function Test-Function {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers,
        [hashtable]$Body = $null
    )
    
    try {
        $fullUrl = $baseUrl + $Url
        
        if ($Body) {
            $jsonBody = $Body | ConvertTo-Json -Compress
            $response = Invoke-WebRequest -Uri $fullUrl -Method $Method -Headers $Headers -Body $jsonBody -ContentType "application/json" -TimeoutSec 15
        } else {
            $response = Invoke-WebRequest -Uri $fullUrl -Method $Method -Headers $Headers -TimeoutSec 15
        }
        
        $success = $response.StatusCode -eq 200 -or $response.StatusCode -eq 201
        $status = if ($success) { "PASS" } else { "FAIL" }
        
        Write-Host "  $status - $Name - HTTP $($response.StatusCode)" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
        
        $script:testResults += @{
            Name = $Name
            Status = $status
            StatusCode = $response.StatusCode
            Method = $Method
            Url = $Url
        }
        
        return $success
    } catch {
        $statusCode = "Unknown"
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        
        Write-Host "  FAIL - $Name - HTTP $statusCode - $($_.Exception.Message)" -ForegroundColor Red
        
        $script:testResults += @{
            Name = $Name
            Status = "FAIL"
            StatusCode = $statusCode
            Method = $Method
            Url = $Url
            Error = $_.Exception.Message
        }
        
        return $false
    }
}

# 1. Get admin token
Write-Host "`n1. Getting admin authentication token..." -ForegroundColor Cyan

$adminToken = Get-AdminToken
if (-not $adminToken) {
    Write-Host "Failed to get admin token, exiting test" -ForegroundColor Red
    exit 1
}
Write-Host "Admin token obtained successfully" -ForegroundColor Green

$headers = @{ "Authorization" = "Bearer $adminToken" }

# 2. Test system functions
Write-Host "`n2. Testing system functions..." -ForegroundColor Cyan

Write-Host "`n  System Health and Stats:" -ForegroundColor Yellow
Test-Function -Name "System Health" -Method "GET" -Url "/health" -Headers @{}
Test-Function -Name "System Ready" -Method "GET" -Url "/ready" -Headers @{}

# 3. Test user management
Write-Host "`n3. Testing user management..." -ForegroundColor Cyan

Test-Function -Name "Get Users" -Method "GET" -Url "/api/v1/admin/users" -Headers $headers
Test-Function -Name "Get User Profile" -Method "GET" -Url "/api/v1/users/profile" -Headers $headers

# 4. Test role management
Write-Host "`n4. Testing role management..." -ForegroundColor Cyan

Test-Function -Name "Get Roles" -Method "GET" -Url "/api/v1/admin/roles" -Headers $headers

# 5. Test permission management
Write-Host "`n5. Testing permission management..." -ForegroundColor Cyan

Test-Function -Name "Get Permissions" -Method "GET" -Url "/api/v1/permissions" -Headers $headers
Test-Function -Name "Get Permission Tree" -Method "GET" -Url "/api/v1/permissions/tree" -Headers $headers

# 6. Test ticket management
Write-Host "`n6. Testing ticket management..." -ForegroundColor Cyan

Test-Function -Name "Get Tickets" -Method "GET" -Url "/api/v1/tickets" -Headers $headers
Test-Function -Name "Get Ticket Statistics" -Method "GET" -Url "/api/v1/tickets/statistics" -Headers $headers
Test-Function -Name "Get Ticket Categories" -Method "GET" -Url "/api/v1/tickets/categories" -Headers $headers
Test-Function -Name "Get Assignment Rules" -Method "GET" -Url "/api/v1/tickets/assignment-rules" -Headers $headers

# Test ticket export
Test-Function -Name "Export Tickets CSV" -Method "GET" -Url "/api/v1/tickets/export?format=csv" -Headers $headers

# 7. Test ticket CRUD operations
Write-Host "`n7. Testing ticket CRUD operations..." -ForegroundColor Cyan

# Create ticket
$ticketData = @{
    title = "Admin Function Test Ticket"
    description = "Test ticket for admin function validation"
    type = "bug"
    priority = "normal"
}

$createResult = Test-Function -Name "Create Ticket" -Method "POST" -Url "/api/v1/tickets" -Headers $headers -Body $ticketData

# Get created ticket ID for further tests
$testTicketId = $null
if ($createResult) {
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/tickets" -Method POST -Body ($ticketData | ConvertTo-Json -Compress) -ContentType "application/json" -Headers $headers
        $testTicketId = $response.data.id
        Write-Host "  Test ticket created with ID: $testTicketId" -ForegroundColor Gray
    } catch {
        Write-Host "  Warning: Could not get test ticket ID" -ForegroundColor Yellow
    }
}

# Test ticket operations if we have a ticket ID
if ($testTicketId) {
    Test-Function -Name "Get Ticket Detail" -Method "GET" -Url "/api/v1/tickets/$testTicketId" -Headers $headers
    
    # Update ticket
    $updateData = @{
        title = "Updated Admin Function Test Ticket"
        priority = "high"
    }
    Test-Function -Name "Update Ticket" -Method "PUT" -Url "/api/v1/tickets/$testTicketId" -Headers $headers -Body $updateData
    
    # Test ticket comments
    Test-Function -Name "Get Ticket Comments" -Method "GET" -Url "/api/v1/tickets/$testTicketId/comments" -Headers $headers
    
    # Add comment
    $commentData = @{
        content = "Test comment for admin function validation"
    }
    Test-Function -Name "Add Ticket Comment" -Method "POST" -Url "/api/v1/tickets/$testTicketId/comments" -Headers $headers -Body $commentData
    
    # Get ticket history
    Test-Function -Name "Get Ticket History" -Method "GET" -Url "/api/v1/tickets/$testTicketId/history" -Headers $headers
    
    # Clean up test ticket
    try {
        Invoke-RestMethod -Uri "$baseUrl/api/v1/tickets/$testTicketId" -Method DELETE -Headers $headers
        Write-Host "  Test ticket cleaned up" -ForegroundColor Gray
    } catch {
        Write-Host "  Warning: Could not clean up test ticket" -ForegroundColor Yellow
    }
}

# 8. Test file management
Write-Host "`n8. Testing file management..." -ForegroundColor Cyan

Test-Function -Name "Get Files" -Method "GET" -Url "/api/v1/files" -Headers $headers

# 9. Test system configuration
Write-Host "`n9. Testing system configuration..." -ForegroundColor Cyan

Test-Function -Name "Get System Health" -Method "GET" -Url "/api/v1/system/health" -Headers $headers

# 10. Test dashboard
Write-Host "`n10. Testing dashboard..." -ForegroundColor Cyan

Test-Function -Name "Get Dashboard Stats" -Method "GET" -Url "/api/v1/dashboard/stats" -Headers $headers

# 11. Generate test report
Write-Host "`n=== Admin Function Test Report ===" -ForegroundColor Green

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failedTests = $totalTests - $passedTests

Write-Host "`nTest Statistics:" -ForegroundColor Yellow
Write-Host "Total Tests: $totalTests" -ForegroundColor Gray
Write-Host "Passed Tests: $passedTests" -ForegroundColor Green
Write-Host "Failed Tests: $failedTests" -ForegroundColor Red
if ($totalTests -gt 0) {
    Write-Host "Success Rate: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor Cyan
}

Write-Host "`nDetailed Results:" -ForegroundColor Yellow
$testResults | ForEach-Object {
    $color = if ($_.Status -eq "PASS") { "Green" } else { "Red" }
    $errorInfo = if ($_.Error) { " - $($_.Error)" } else { "" }
    Write-Host "  $($_.Name): $($_.Status) (HTTP $($_.StatusCode))$errorInfo" -ForegroundColor $color
}

# Group by function category
Write-Host "`nFunction Category Results:" -ForegroundColor Yellow
$categories = @{
    "System" = $testResults | Where-Object { $_.Name -like "*System*" -or $_.Name -like "*Health*" -or $_.Name -like "*Ready*" }
    "User Management" = $testResults | Where-Object { $_.Name -like "*User*" -or $_.Name -like "*Profile*" }
    "Role Management" = $testResults | Where-Object { $_.Name -like "*Role*" }
    "Permission Management" = $testResults | Where-Object { $_.Name -like "*Permission*" }
    "Ticket Management" = $testResults | Where-Object { $_.Name -like "*Ticket*" }
    "File Management" = $testResults | Where-Object { $_.Name -like "*File*" }
    "Dashboard" = $testResults | Where-Object { $_.Name -like "*Dashboard*" }
}

foreach ($category in $categories.Keys) {
    $categoryResults = $categories[$category]
    if ($categoryResults.Count -gt 0) {
        $categoryPassed = ($categoryResults | Where-Object { $_.Status -eq "PASS" }).Count
        $categoryRate = [math]::Round(($categoryPassed / $categoryResults.Count) * 100, 1)
        Write-Host "  $category`: $categoryPassed/$($categoryResults.Count) ($categoryRate%)" -ForegroundColor Cyan
    }
}

# Save detailed report
$reportPath = "docs/ADMIN_FUNCTION_TEST_REPORT.md"
$reportContent = @"
# Admin Function Test Report

**Test Time**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Total Tests**: $totalTests
**Passed Tests**: $passedTests
**Failed Tests**: $failedTests
**Success Rate**: $([math]::Round(($passedTests / $totalTests) * 100, 2))%

## Test Results

| Function | Status | HTTP Code | Method | URL |
|----------|--------|-----------|--------|-----|
"@

foreach ($result in $testResults) {
    $reportContent += "| $($result.Name) | $($result.Status) | $($result.StatusCode) | $($result.Method) | $($result.Url) |`n"
}

$reportContent += @"

## Category Statistics

| Category | Passed/Total | Success Rate |
|----------|--------------|--------------|
"@

foreach ($category in $categories.Keys) {
    $categoryResults = $categories[$category]
    if ($categoryResults.Count -gt 0) {
        $categoryPassed = ($categoryResults | Where-Object { $_.Status -eq "PASS" }).Count
        $categoryRate = [math]::Round(($categoryPassed / $categoryResults.Count) * 100, 1)
        $reportContent += "| $category | $categoryPassed/$($categoryResults.Count) | $categoryRate% |`n"
    }
}

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "`nDetailed report saved to: $reportPath" -ForegroundColor Cyan

if ($failedTests -eq 0) {
    Write-Host "`nAll admin functions are working correctly!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome functions failed. Please check the system." -ForegroundColor Yellow
    exit 1
}