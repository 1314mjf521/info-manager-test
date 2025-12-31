# Complete System Test - Test all system functions (Backend + Frontend)
Write-Host "=== Complete System Function Test ===" -ForegroundColor Green

$backendUrl = "http://localhost:8080"
$frontendUrl = "http://localhost:3000"
$testResults = @()

# Get admin authentication token
function Get-AdminToken {
    try {
        $loginData = @{
            username = "admin"
            password = "admin123"
        } | ConvertTo-Json -Compress
        
        $response = Invoke-RestMethod -Uri "$backendUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        return $response.data.token
    } catch {
        Write-Host "Admin login failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Test backend API
function Test-BackendAPI {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers,
        [hashtable]$Body = $null
    )
    
    try {
        $fullUrl = $backendUrl + $Url
        
        if ($Body) {
            $jsonBody = $Body | ConvertTo-Json -Compress
            $response = Invoke-WebRequest -Uri $fullUrl -Method $Method -Headers $Headers -Body $jsonBody -ContentType "application/json" -TimeoutSec 10
        } else {
            $response = Invoke-WebRequest -Uri $fullUrl -Method $Method -Headers $Headers -TimeoutSec 10
        }
        
        $success = $response.StatusCode -eq 200 -or $response.StatusCode -eq 201
        $status = if ($success) { "PASS" } else { "FAIL" }
        
        Write-Host "  $status - Backend $Name" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
        
        $script:testResults += @{
            Type = "Backend"
            Name = $Name
            Status = $status
            StatusCode = $response.StatusCode
        }
        
        return $success
    } catch {
        Write-Host "  FAIL - Backend $Name - $($_.Exception.Message)" -ForegroundColor Red
        
        $script:testResults += @{
            Type = "Backend"
            Name = $Name
            Status = "FAIL"
            Error = $_.Exception.Message
        }
        
        return $false
    }
}

# Test frontend route
function Test-FrontendRoute {
    param(
        [string]$Name,
        [string]$Path
    )
    
    try {
        $response = Invoke-WebRequest -Uri "$frontendUrl$Path" -TimeoutSec 10
        $success = $response.StatusCode -eq 200
        $status = if ($success) { "PASS" } else { "FAIL" }
        
        Write-Host "  $status - Frontend $Name" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
        
        $script:testResults += @{
            Type = "Frontend"
            Name = $Name
            Status = $status
            StatusCode = $response.StatusCode
        }
        
        return $success
    } catch {
        Write-Host "  FAIL - Frontend $Name" -ForegroundColor Red
        
        $script:testResults += @{
            Type = "Frontend"
            Name = $Name
            Status = "FAIL"
        }
        
        return $false
    }
}

# 1. Check servers
Write-Host "`n1. Checking servers..." -ForegroundColor Cyan

# Check backend
try {
    $backendResponse = Invoke-WebRequest -Uri "$backendUrl/health" -TimeoutSec 5
    Write-Host "Backend server is running - HTTP $($backendResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Backend server is not running" -ForegroundColor Red
    exit 1
}

# Check frontend
try {
    $frontendResponse = Invoke-WebRequest -Uri $frontendUrl -TimeoutSec 5
    Write-Host "Frontend server is running - HTTP $($frontendResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Frontend server is not running (this is optional)" -ForegroundColor Yellow
}

# 2. Get admin token
Write-Host "`n2. Getting admin authentication..." -ForegroundColor Cyan

$adminToken = Get-AdminToken
if (-not $adminToken) {
    Write-Host "Failed to get admin token, exiting test" -ForegroundColor Red
    exit 1
}
Write-Host "Admin authentication successful" -ForegroundColor Green

$headers = @{ "Authorization" = "Bearer $adminToken" }

# 3. Test core backend functions
Write-Host "`n3. Testing core backend functions..." -ForegroundColor Cyan

Test-BackendAPI -Name "System Health" -Method "GET" -Url "/health" -Headers @{}
Test-BackendAPI -Name "User Management" -Method "GET" -Url "/api/v1/admin/users" -Headers $headers
Test-BackendAPI -Name "Role Management" -Method "GET" -Url "/api/v1/admin/roles" -Headers $headers
Test-BackendAPI -Name "Permission Management" -Method "GET" -Url "/api/v1/permissions" -Headers $headers
Test-BackendAPI -Name "Ticket Management" -Method "GET" -Url "/api/v1/tickets" -Headers $headers
Test-BackendAPI -Name "Ticket Statistics" -Method "GET" -Url "/api/v1/tickets/statistics" -Headers $headers
Test-BackendAPI -Name "File Management" -Method "GET" -Url "/api/v1/files" -Headers $headers

# 4. Test ticket CRUD
Write-Host "`n4. Testing ticket CRUD operations..." -ForegroundColor Cyan

$ticketData = @{
    title = "Complete System Test Ticket"
    description = "Test ticket for complete system validation"
    type = "bug"
    priority = "normal"
}

$createResult = Test-BackendAPI -Name "Create Ticket" -Method "POST" -Url "/api/v1/tickets" -Headers $headers -Body $ticketData

# Get ticket ID for further operations
$testTicketId = $null
if ($createResult) {
    try {
        $response = Invoke-RestMethod -Uri "$backendUrl/api/v1/tickets" -Method POST -Body ($ticketData | ConvertTo-Json -Compress) -ContentType "application/json" -Headers $headers
        $testTicketId = $response.data.id
        Write-Host "  Test ticket created with ID: $testTicketId" -ForegroundColor Gray
        
        # Test read and update
        Test-BackendAPI -Name "Read Ticket" -Method "GET" -Url "/api/v1/tickets/$testTicketId" -Headers $headers
        
        $updateData = @{ title = "Updated Complete System Test Ticket" }
        Test-BackendAPI -Name "Update Ticket" -Method "PUT" -Url "/api/v1/tickets/$testTicketId" -Headers $headers -Body $updateData
        
        # Clean up
        Invoke-RestMethod -Uri "$backendUrl/api/v1/tickets/$testTicketId" -Method DELETE -Headers $headers
        Write-Host "  Test ticket cleaned up" -ForegroundColor Gray
    } catch {
        Write-Host "  Warning: Could not complete ticket operations" -ForegroundColor Yellow
    }
}

# 5. Test import/export functions
Write-Host "`n5. Testing import/export functions..." -ForegroundColor Cyan

Test-BackendAPI -Name "Export Tickets" -Method "GET" -Url "/api/v1/tickets/export?format=csv" -Headers $headers

# 6. Test frontend routes (if frontend is running)
if ($frontendResponse) {
    Write-Host "`n6. Testing frontend routes..." -ForegroundColor Cyan
    
    Test-FrontendRoute -Name "Home Page" -Path "/"
    Test-FrontendRoute -Name "Login Page" -Path "/login"
    Test-FrontendRoute -Name "Dashboard" -Path "/dashboard"
    Test-FrontendRoute -Name "Tickets" -Path "/tickets"
    Test-FrontendRoute -Name "Users" -Path "/users"
    Test-FrontendRoute -Name "Roles" -Path "/roles"
    Test-FrontendRoute -Name "Permissions" -Path "/permissions"
}

# 7. Generate comprehensive report
Write-Host "`n=== Complete System Test Report ===" -ForegroundColor Green

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failedTests = $totalTests - $passedTests

Write-Host "`nOverall Statistics:" -ForegroundColor Yellow
Write-Host "Total Tests: $totalTests" -ForegroundColor Gray
Write-Host "Passed Tests: $passedTests" -ForegroundColor Green
Write-Host "Failed Tests: $failedTests" -ForegroundColor Red
if ($totalTests -gt 0) {
    Write-Host "Success Rate: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor Cyan
}

# Backend vs Frontend statistics
$backendResults = $testResults | Where-Object { $_.Type -eq "Backend" }
$frontendResults = $testResults | Where-Object { $_.Type -eq "Frontend" }

if ($backendResults.Count -gt 0) {
    $backendPassed = ($backendResults | Where-Object { $_.Status -eq "PASS" }).Count
    $backendRate = [math]::Round(($backendPassed / $backendResults.Count) * 100, 1)
    Write-Host "`nBackend: $backendPassed/$($backendResults.Count) ($backendRate%)" -ForegroundColor Cyan
}

if ($frontendResults.Count -gt 0) {
    $frontendPassed = ($frontendResults | Where-Object { $_.Status -eq "PASS" }).Count
    $frontendRate = [math]::Round(($frontendPassed / $frontendResults.Count) * 100, 1)
    Write-Host "Frontend: $frontendPassed/$($frontendResults.Count) ($frontendRate%)" -ForegroundColor Cyan
}

Write-Host "`nDetailed Results:" -ForegroundColor Yellow
$testResults | ForEach-Object {
    $color = if ($_.Status -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  $($_.Type) - $($_.Name): $($_.Status)" -ForegroundColor $color
}

# Save comprehensive report
$reportPath = "docs/COMPLETE_SYSTEM_TEST_REPORT.md"
$reportContent = @"
# Complete System Test Report

**Test Time**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Total Tests**: $totalTests
**Passed Tests**: $passedTests
**Failed Tests**: $failedTests
**Success Rate**: $([math]::Round(($passedTests / $totalTests) * 100, 2))%

## Backend Tests: $($backendResults.Count)
$(if ($backendResults.Count -gt 0) { "**Success Rate**: $backendRate%" } else { "No backend tests" })

## Frontend Tests: $($frontendResults.Count)
$(if ($frontendResults.Count -gt 0) { "**Success Rate**: $frontendRate%" } else { "No frontend tests" })

## Detailed Results

| Type | Function | Status |
|------|----------|--------|
"@

foreach ($result in $testResults) {
    $reportContent += "| $($result.Type) | $($result.Name) | $($result.Status) |`n"
}

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "`nComprehensive report saved to: $reportPath" -ForegroundColor Cyan

if ($failedTests -eq 0) {
    Write-Host "`nAll system functions are working correctly!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome functions failed. Please check the system." -ForegroundColor Yellow
    exit 1
}