# Permission Test Script (English)
Write-Host "=== Permission System Test ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080"
$testResults = @()

# Get authentication token
function Get-AuthToken {
    param([string]$Username, [string]$Password)
    
    try {
        $loginData = @{
            username = $Username
            password = $Password
        } | ConvertTo-Json -Compress
        
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        return $response.data.token
    } catch {
        Write-Host "Login failed for $Username : $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Test API endpoint
function Test-ApiEndpoint {
    param(
        [string]$Name,
        [string]$Url,
        [hashtable]$Headers,
        [string]$UserType
    )
    
    try {
        $response = Invoke-WebRequest -Uri "$baseUrl$Url" -Method GET -Headers $Headers -TimeoutSec 10
        $success = $response.StatusCode -eq 200
        $status = if ($success) { "PASS" } else { "FAIL" }
        
        Write-Host "  $status - $Name ($UserType) - HTTP $($response.StatusCode)" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
        
        $script:testResults += @{
            Name = $Name
            UserType = $UserType
            Status = $status
            StatusCode = $response.StatusCode
        }
        
        return $success
    } catch {
        $statusCode = "Unknown"
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        
        # For permission tests, 403/401 might be expected for Tiker user
        $isExpectedDenial = ($statusCode -eq 403 -or $statusCode -eq 401) -and $UserType -eq "Tiker"
        $status = if ($isExpectedDenial) { "PASS (Denied)" } else { "FAIL" }
        
        Write-Host "  $status - $Name ($UserType) - HTTP $statusCode" -ForegroundColor $(if ($isExpectedDenial) { "Green" } else { "Red" })
        
        $script:testResults += @{
            Name = $Name
            UserType = $UserType
            Status = $status
            StatusCode = $statusCode
        }
        
        return $isExpectedDenial
    }
}

# 1. Get authentication tokens
Write-Host "`n1. Getting authentication tokens..." -ForegroundColor Cyan

$adminToken = Get-AuthToken -Username "admin" -Password "admin123"
if (-not $adminToken) {
    Write-Host "Failed to get Admin token, exiting test" -ForegroundColor Red
    exit 1
}
Write-Host "Admin token obtained successfully" -ForegroundColor Green

$tikerToken = Get-AuthToken -Username "tiker" -Password "tiker123"
if (-not $tikerToken) {
    Write-Host "Failed to get Tiker token, exiting test" -ForegroundColor Red
    exit 1
}
Write-Host "Tiker token obtained successfully" -ForegroundColor Green

$adminHeaders = @{ "Authorization" = "Bearer $adminToken" }
$tikerHeaders = @{ "Authorization" = "Bearer $tikerToken" }

# 2. Test core API endpoints
Write-Host "`n2. Testing core API endpoints..." -ForegroundColor Cyan

# System health check
Write-Host "`n  System Health:" -ForegroundColor Yellow
Test-ApiEndpoint -Name "System Health" -Url "/health" -Headers @{} -UserType "Public"

# User management
Write-Host "`n  User Management:" -ForegroundColor Yellow
Test-ApiEndpoint -Name "User List" -Url "/api/v1/admin/users" -Headers $adminHeaders -UserType "Admin"
Test-ApiEndpoint -Name "User List" -Url "/api/v1/admin/users" -Headers $tikerHeaders -UserType "Tiker"

# Role management
Write-Host "`n  Role Management:" -ForegroundColor Yellow
Test-ApiEndpoint -Name "Role List" -Url "/api/v1/admin/roles" -Headers $adminHeaders -UserType "Admin"
Test-ApiEndpoint -Name "Role List" -Url "/api/v1/admin/roles" -Headers $tikerHeaders -UserType "Tiker"

# Permission management
Write-Host "`n  Permission Management:" -ForegroundColor Yellow
Test-ApiEndpoint -Name "Permission List" -Url "/api/v1/permissions" -Headers $adminHeaders -UserType "Admin"
Test-ApiEndpoint -Name "Permission List" -Url "/api/v1/permissions" -Headers $tikerHeaders -UserType "Tiker"

# Ticket management
Write-Host "`n  Ticket Management:" -ForegroundColor Yellow
Test-ApiEndpoint -Name "Ticket List" -Url "/api/v1/tickets" -Headers $adminHeaders -UserType "Admin"
Test-ApiEndpoint -Name "Ticket List" -Url "/api/v1/tickets" -Headers $tikerHeaders -UserType "Tiker"
Test-ApiEndpoint -Name "Ticket Statistics" -Url "/api/v1/tickets/statistics" -Headers $adminHeaders -UserType "Admin"
Test-ApiEndpoint -Name "Ticket Statistics" -Url "/api/v1/tickets/statistics" -Headers $tikerHeaders -UserType "Tiker"
Test-ApiEndpoint -Name "Ticket Export" -Url "/api/v1/tickets/export?format=csv" -Headers $adminHeaders -UserType "Admin"
Test-ApiEndpoint -Name "Ticket Export" -Url "/api/v1/tickets/export?format=csv" -Headers $tikerHeaders -UserType "Tiker"

# File management
Write-Host "`n  File Management:" -ForegroundColor Yellow
Test-ApiEndpoint -Name "File List" -Url "/api/v1/files" -Headers $adminHeaders -UserType "Admin"
Test-ApiEndpoint -Name "File List" -Url "/api/v1/files" -Headers $tikerHeaders -UserType "Tiker"

# System configuration
Write-Host "`n  System Configuration:" -ForegroundColor Yellow
Test-ApiEndpoint -Name "System Stats" -Url "/api/v1/system/stats" -Headers $adminHeaders -UserType "Admin"
Test-ApiEndpoint -Name "System Stats" -Url "/api/v1/system/stats" -Headers $tikerHeaders -UserType "Tiker"

# 3. Test ticket creation
Write-Host "`n3. Testing ticket creation..." -ForegroundColor Cyan

$ticketData = @{
    title = "Permission Test Ticket"
    description = "Test ticket for permission validation"
    type = "bug"
    priority = "normal"
} | ConvertTo-Json -Compress

try {
    Write-Host "`n  Admin ticket creation:" -ForegroundColor Yellow
    $adminCreateResponse = Invoke-WebRequest -Uri "$baseUrl/api/v1/tickets" -Method POST -Body $ticketData -ContentType "application/json" -Headers $adminHeaders -TimeoutSec 10
    Write-Host "  PASS - Admin ticket creation successful - HTTP $($adminCreateResponse.StatusCode)" -ForegroundColor Green
    
    # Get created ticket ID
    $responseData = $adminCreateResponse.Content | ConvertFrom-Json
    $testTicketId = $responseData.data.id
    Write-Host "  Test ticket ID: $testTicketId" -ForegroundColor Gray
    
} catch {
    Write-Host "  FAIL - Admin ticket creation failed: $($_.Exception.Message)" -ForegroundColor Red
    $testTicketId = $null
}

try {
    Write-Host "`n  Tiker ticket creation:" -ForegroundColor Yellow
    $tikerCreateResponse = Invoke-WebRequest -Uri "$baseUrl/api/v1/tickets" -Method POST -Body $ticketData -ContentType "application/json" -Headers $tikerHeaders -TimeoutSec 10
    Write-Host "  PASS - Tiker ticket creation successful - HTTP $($tikerCreateResponse.StatusCode)" -ForegroundColor Green
} catch {
    $statusCode = "Unknown"
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode
    }
    Write-Host "  FAIL - Tiker ticket creation failed - HTTP $statusCode" -ForegroundColor Red
}

# 4. Test ticket operations if test ticket exists
if ($testTicketId) {
    Write-Host "`n4. Testing ticket operations..." -ForegroundColor Cyan
    
    Write-Host "`n  Ticket reading:" -ForegroundColor Yellow
    Test-ApiEndpoint -Name "Ticket Detail" -Url "/api/v1/tickets/$testTicketId" -Headers $adminHeaders -UserType "Admin"
    Test-ApiEndpoint -Name "Ticket Detail" -Url "/api/v1/tickets/$testTicketId" -Headers $tikerHeaders -UserType "Tiker"
    
    # Clean up test ticket
    try {
        Invoke-RestMethod -Uri "$baseUrl/api/v1/tickets/$testTicketId" -Method DELETE -Headers $adminHeaders
        Write-Host "  Test ticket cleaned up" -ForegroundColor Gray
    } catch {
        Write-Host "  Warning: Could not clean up test ticket" -ForegroundColor Yellow
    }
}

# 5. Generate test report
Write-Host "`n=== Permission Test Report ===" -ForegroundColor Green

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Status -like "*PASS*" }).Count
$failedTests = $totalTests - $passedTests

Write-Host "`nTest Statistics:" -ForegroundColor Yellow
Write-Host "Total Tests: $totalTests" -ForegroundColor Gray
Write-Host "Passed Tests: $passedTests" -ForegroundColor Green
Write-Host "Failed Tests: $failedTests" -ForegroundColor Red
if ($totalTests -gt 0) {
    Write-Host "Success Rate: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor Cyan
}

Write-Host "`nDetailed Results:" -ForegroundColor Yellow
$testResults | Sort-Object Name, UserType | ForEach-Object {
    $color = if ($_.Status -like "*PASS*") { "Green" } else { "Red" }
    Write-Host "  $($_.Name) ($($_.UserType)): $($_.Status)" -ForegroundColor $color
}

# User type statistics
Write-Host "`nUser Type Statistics:" -ForegroundColor Yellow
$adminResults = $testResults | Where-Object { $_.UserType -eq "Admin" }
$tikerResults = $testResults | Where-Object { $_.UserType -eq "Tiker" }
$publicResults = $testResults | Where-Object { $_.UserType -eq "Public" }

if ($adminResults.Count -gt 0) {
    $adminPassed = ($adminResults | Where-Object { $_.Status -like "*PASS*" }).Count
    $adminRate = [math]::Round(($adminPassed / $adminResults.Count) * 100, 1)
    Write-Host "  Admin: $adminPassed/$($adminResults.Count) ($adminRate%)" -ForegroundColor Cyan
}

if ($tikerResults.Count -gt 0) {
    $tikerPassed = ($tikerResults | Where-Object { $_.Status -like "*PASS*" }).Count
    $tikerRate = [math]::Round(($tikerPassed / $tikerResults.Count) * 100, 1)
    Write-Host "  Tiker: $tikerPassed/$($tikerResults.Count) ($tikerRate%)" -ForegroundColor Cyan
}

if ($publicResults.Count -gt 0) {
    $publicPassed = ($publicResults | Where-Object { $_.Status -like "*PASS*" }).Count
    $publicRate = [math]::Round(($publicPassed / $publicResults.Count) * 100, 1)
    Write-Host "  Public: $publicPassed/$($publicResults.Count) ($publicRate%)" -ForegroundColor Cyan
}

if ($failedTests -eq 0) {
    Write-Host "`nAll permission tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome tests failed. Please check permission configuration." -ForegroundColor Yellow
    exit 1
}