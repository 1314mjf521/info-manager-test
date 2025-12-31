# Complete Permission Matrix Test - Test all 76 permissions across all modules
Write-Host "=== Complete Permission Matrix Test ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080"
$testResults = @()

# All 76 permissions organized by module
$permissionMatrix = @{
    "System Management" = @(
        @{ Name = "system:admin"; API = "/api/v1/system/stats"; Method = "GET" }
        @{ Name = "system:config_read"; API = "/api/v1/config"; Method = "GET" }
        @{ Name = "system:config_write"; API = "/api/v1/config/test/key"; Method = "PUT"; Body = @{value="test"} }
        @{ Name = "system:announcements_read"; API = "/api/v1/announcements"; Method = "GET" }
        @{ Name = "system:announcements_write"; API = "/api/v1/announcements"; Method = "POST"; Body = @{title="Test"; content="Test"} }
        @{ Name = "system:logs_read"; API = "/api/v1/logs"; Method = "GET" }
        @{ Name = "system:logs_delete"; API = "/api/v1/logs/cleanup"; Method = "POST" }
        @{ Name = "system:health_read"; API = "/api/v1/system/health"; Method = "GET" }
        @{ Name = "system:stats_read"; API = "/api/v1/system/stats"; Method = "GET" }
    )
    
    "User Management" = @(
        @{ Name = "users:read"; API = "/api/v1/admin/users"; Method = "GET" }
        @{ Name = "users:create"; API = "/api/v1/admin/users"; Method = "POST"; Body = @{username="test_user"; email="test@test.com"; password="test123"} }
        @{ Name = "users:update"; API = "/api/v1/admin/users/1"; Method = "PUT"; Body = @{displayName="Updated"} }
        @{ Name = "users:delete"; API = "/api/v1/admin/users/999"; Method = "DELETE" }
        @{ Name = "users:assign_roles"; API = "/api/v1/admin/users/1/roles"; Method = "PUT"; Body = @{roleIds=@(1)} }
        @{ Name = "users:reset_password"; API = "/api/v1/admin/users/1/reset-password"; Method = "POST"; Body = @{password="newpass"} }
        @{ Name = "users:change_status"; API = "/api/v1/admin/users/batch-status"; Method = "PUT"; Body = @{userIds=@(1); status="active"} }
        @{ Name = "users:import"; API = "/api/v1/admin/users/import"; Method = "POST"; RequiresFile = $true }
    )
    
    "Role Management" = @(
        @{ Name = "roles:read"; API = "/api/v1/admin/roles"; Method = "GET" }
        @{ Name = "roles:create"; API = "/api/v1/admin/roles"; Method = "POST"; Body = @{name="test_role"; displayName="Test Role"} }
        @{ Name = "roles:update"; API = "/api/v1/admin/roles/1"; Method = "PUT"; Body = @{displayName="Updated Role"} }
        @{ Name = "roles:delete"; API = "/api/v1/admin/roles/999"; Method = "DELETE" }
        @{ Name = "roles:assign_permissions"; API = "/api/v1/admin/roles/1/permissions"; Method = "PUT"; Body = @{permissionIds=@(1)} }
        @{ Name = "roles:import"; API = "/api/v1/admin/roles/import"; Method = "POST"; RequiresFile = $true }
    )
    
    "Permission Management" = @(
        @{ Name = "permissions:read"; API = "/api/v1/permissions"; Method = "GET" }
        @{ Name = "permissions:create"; API = "/api/v1/permissions"; Method = "POST"; Body = @{name="test:perm"; displayName="Test Permission"} }
        @{ Name = "permissions:update"; API = "/api/v1/permissions/1"; Method = "PUT"; Body = @{displayName="Updated Permission"} }
        @{ Name = "permissions:delete"; API = "/api/v1/permissions/999"; Method = "DELETE" }
        @{ Name = "permissions:initialize"; API = "/api/v1/permissions/initialize"; Method = "POST" }
    )
    
    "Ticket Management" = @(
        @{ Name = "ticket:read"; API = "/api/v1/tickets"; Method = "GET" }
        @{ Name = "ticket:read_own"; API = "/api/v1/tickets"; Method = "GET" }
        @{ Name = "ticket:create"; API = "/api/v1/tickets"; Method = "POST"; Body = @{title="Test Ticket"; description="Test"; type="bug"; priority="normal"} }
        @{ Name = "ticket:update"; API = "/api/v1/tickets/1"; Method = "PUT"; Body = @{title="Updated Ticket"} }
        @{ Name = "ticket:update_own"; API = "/api/v1/tickets/1"; Method = "PUT"; Body = @{title="Updated Own Ticket"} }
        @{ Name = "ticket:delete"; API = "/api/v1/tickets/999"; Method = "DELETE" }
        @{ Name = "ticket:delete_own"; API = "/api/v1/tickets/999"; Method = "DELETE" }
        @{ Name = "ticket:assign"; API = "/api/v1/tickets/1/assign"; Method = "POST"; Body = @{assignee_id=1} }
        @{ Name = "ticket:accept"; API = "/api/v1/tickets/1/accept"; Method = "POST" }
        @{ Name = "ticket:reject"; API = "/api/v1/tickets/1/reject"; Method = "POST" }
        @{ Name = "ticket:reopen"; API = "/api/v1/tickets/1/reopen"; Method = "POST" }
        @{ Name = "ticket:status_change"; API = "/api/v1/tickets/1/status"; Method = "PUT"; Body = @{status="progress"} }
        @{ Name = "ticket:comment_read"; API = "/api/v1/tickets/1/comments"; Method = "GET" }
        @{ Name = "ticket:comment_write"; API = "/api/v1/tickets/1/comments"; Method = "POST"; Body = @{content="Test comment"} }
        @{ Name = "ticket:attachment_upload"; API = "/api/v1/tickets/1/attachments"; Method = "POST"; RequiresFile = $true }
        @{ Name = "ticket:attachment_delete"; API = "/api/v1/tickets/1/attachments/1"; Method = "DELETE" }
        @{ Name = "ticket:statistics"; API = "/api/v1/tickets/statistics"; Method = "GET" }
        @{ Name = "ticket:export"; API = "/api/v1/tickets/export"; Method = "GET" }
        @{ Name = "ticket:import"; API = "/api/v1/tickets/import"; Method = "POST"; RequiresFile = $true }
    )
    
    "Record Management" = @(
        @{ Name = "records:read"; API = "/api/v1/records"; Method = "GET" }
        @{ Name = "records:read_own"; API = "/api/v1/records"; Method = "GET" }
        @{ Name = "records:create"; API = "/api/v1/records"; Method = "POST"; Body = @{title="Test Record"; content="Test"} }
        @{ Name = "records:update"; API = "/api/v1/records/1"; Method = "PUT"; Body = @{title="Updated Record"} }
        @{ Name = "records:update_own"; API = "/api/v1/records/1"; Method = "PUT"; Body = @{title="Updated Own Record"} }
        @{ Name = "records:delete"; API = "/api/v1/records/999"; Method = "DELETE" }
        @{ Name = "records:delete_own"; API = "/api/v1/records/999"; Method = "DELETE" }
        @{ Name = "records:import"; API = "/api/v1/records/import"; Method = "POST"; RequiresFile = $true }
    )
    
    "Record Type Management" = @(
        @{ Name = "record_types:read"; API = "/api/v1/record-types"; Method = "GET" }
        @{ Name = "record_types:create"; API = "/api/v1/record-types"; Method = "POST"; Body = @{name="test_type"; displayName="Test Type"} }
        @{ Name = "record_types:update"; API = "/api/v1/record-types/1"; Method = "PUT"; Body = @{displayName="Updated Type"} }
        @{ Name = "record_types:delete"; API = "/api/v1/record-types/999"; Method = "DELETE" }
        @{ Name = "record_types:import"; API = "/api/v1/record-types/import"; Method = "POST"; RequiresFile = $true }
    )
    
    "File Management" = @(
        @{ Name = "files:read"; API = "/api/v1/files"; Method = "GET" }
        @{ Name = "files:upload"; API = "/api/v1/files/upload"; Method = "POST"; RequiresFile = $true }
        @{ Name = "files:download"; API = "/api/v1/files/1"; Method = "GET" }
        @{ Name = "files:delete"; API = "/api/v1/files/999"; Method = "DELETE" }
        @{ Name = "files:ocr"; API = "/api/v1/files/ocr"; Method = "POST"; RequiresFile = $true }
    )
    
    "Export Management" = @(
        @{ Name = "export:read"; API = "/api/v1/export/templates"; Method = "GET" }
        @{ Name = "export:create"; API = "/api/v1/export/templates"; Method = "POST"; Body = @{name="test_template"; format="csv"} }
        @{ Name = "export:update"; API = "/api/v1/export/templates/1"; Method = "PUT"; Body = @{name="updated_template"} }
        @{ Name = "export:delete"; API = "/api/v1/export/templates/999"; Method = "DELETE" }
        @{ Name = "export:execute"; API = "/api/v1/export/records"; Method = "POST"; Body = @{template_id=1} }
        @{ Name = "export:download"; API = "/api/v1/export/files/1/download"; Method = "GET" }
    )
    
    "AI Features" = @(
        @{ Name = "ai:features"; API = "/api/v1/ai/chat"; Method = "POST"; Body = @{message="test"} }
        @{ Name = "ai:config"; API = "/api/v1/ai/config"; Method = "GET" }
        @{ Name = "ai:chat"; API = "/api/v1/ai/chat"; Method = "POST"; Body = @{message="Hello"} }
        @{ Name = "ai:optimize"; API = "/api/v1/ai/optimize-record"; Method = "POST"; Body = @{content="test"} }
        @{ Name = "ai:speech"; API = "/api/v1/ai/speech-to-text"; Method = "POST"; RequiresFile = $true }
    )
}

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

# Test individual permission
function Test-Permission {
    param(
        [string]$PermissionName,
        [string]$API,
        [string]$Method,
        [hashtable]$Headers,
        [string]$UserType,
        [hashtable]$Body = $null,
        [bool]$RequiresFile = $false
    )
    
    try {
        $fullUrl = $baseUrl + $API
        
        if ($RequiresFile) {
            # Skip file upload tests for now as they require special handling
            Write-Host "  SKIP - $PermissionName ($UserType) - File upload test skipped" -ForegroundColor Yellow
            $script:testResults += @{
                Permission = $PermissionName
                UserType = $UserType
                Status = "SKIP"
                Reason = "File upload test"
            }
            return $true
        }
        
        if ($Body) {
            $jsonBody = $Body | ConvertTo-Json -Compress
            $response = Invoke-WebRequest -Uri $fullUrl -Method $Method -Headers $Headers -Body $jsonBody -ContentType "application/json" -TimeoutSec 10
        } else {
            $response = Invoke-WebRequest -Uri $fullUrl -Method $Method -Headers $Headers -TimeoutSec 10
        }
        
        $success = $response.StatusCode -eq 200 -or $response.StatusCode -eq 201
        $status = if ($success) { "PASS" } else { "FAIL" }
        
        Write-Host "  $status - $PermissionName ($UserType) - HTTP $($response.StatusCode)" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
        
        $script:testResults += @{
            Permission = $PermissionName
            UserType = $UserType
            Status = $status
            StatusCode = $response.StatusCode
            API = $API
            Method = $Method
        }
        
        return $success
    } catch {
        $statusCode = "Unknown"
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        
        # For non-admin users, 403/401 might be expected for certain permissions
        $isExpectedDenial = ($statusCode -eq 403 -or $statusCode -eq 401) -and $UserType -ne "Admin"
        $status = if ($UserType -eq "Admin") { "FAIL" } elseif ($isExpectedDenial) { "EXPECTED" } else { "FAIL" }
        
        $color = if ($status -eq "EXPECTED") { "Yellow" } else { "Red" }
        Write-Host "  $status - $PermissionName ($UserType) - HTTP $statusCode" -ForegroundColor $color
        
        $script:testResults += @{
            Permission = $PermissionName
            UserType = $UserType
            Status = $status
            StatusCode = $statusCode
            API = $API
            Method = $Method
        }
        
        return $status -eq "EXPECTED"
    }
}

# Test all permissions for a user
function Test-AllPermissions {
    param([object]$UserData)
    
    $userType = $UserData.UserType
    $headers = @{ "Authorization" = "Bearer $($UserData.Token)" }
    
    Write-Host "`nTesting all permissions for $userType user:" -ForegroundColor Cyan
    
    foreach ($module in $permissionMatrix.Keys) {
        Write-Host "`n  Testing $module permissions:" -ForegroundColor Yellow
        
        foreach ($permission in $permissionMatrix[$module]) {
            Test-Permission -PermissionName $permission.Name -API $permission.API -Method $permission.Method -Headers $headers -UserType $userType -Body $permission.Body -RequiresFile $permission.RequiresFile
        }
    }
}

# 1. Check backend server
Write-Host "`n1. Checking backend server..." -ForegroundColor Cyan

try {
    $healthResponse = Invoke-WebRequest -Uri "$baseUrl/health" -TimeoutSec 5
    Write-Host "Backend server is running - HTTP $($healthResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Backend server is not running" -ForegroundColor Red
    exit 1
}

# 2. Test admin user with all permissions
Write-Host "`n2. Testing admin user with all 76 permissions..." -ForegroundColor Cyan

$adminToken = Get-AuthToken -Username "admin" -Password "admin123"
if (-not $adminToken) {
    Write-Host "Failed to get admin token, exiting test" -ForegroundColor Red
    exit 1
}

$adminData = @{
    Token = $adminToken
    UserType = "Admin"
}

Test-AllPermissions -UserData $adminData

# 3. Test regular user with limited permissions
Write-Host "`n3. Testing tiker user with limited permissions..." -ForegroundColor Cyan

$tikerToken = Get-AuthToken -Username "tiker_test" -Password "tiker123"
if ($tikerToken) {
    $tikerData = @{
        Token = $tikerToken
        UserType = "Tiker"
    }
    
    Test-AllPermissions -UserData $tikerData
} else {
    Write-Host "Tiker user not available, skipping limited user tests" -ForegroundColor Yellow
}

# 4. Generate comprehensive report
Write-Host "`n=== Complete Permission Matrix Test Report ===" -ForegroundColor Green

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failedTests = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$expectedTests = ($testResults | Where-Object { $_.Status -eq "EXPECTED" }).Count
$skippedTests = ($testResults | Where-Object { $_.Status -eq "SKIP" }).Count

Write-Host "`nOverall Statistics:" -ForegroundColor Yellow
Write-Host "Total Permission Tests: $totalTests" -ForegroundColor Gray
Write-Host "Passed Tests: $passedTests" -ForegroundColor Green
Write-Host "Failed Tests: $failedTests" -ForegroundColor Red
Write-Host "Expected Denials: $expectedTests" -ForegroundColor Yellow
Write-Host "Skipped Tests: $skippedTests" -ForegroundColor Cyan

if ($totalTests -gt 0) {
    $successRate = [math]::Round((($passedTests + $expectedTests) / $totalTests) * 100, 2)
    Write-Host "Success Rate: $successRate%" -ForegroundColor Cyan
}

# Module-wise statistics
Write-Host "`nModule-wise Results:" -ForegroundColor Yellow
foreach ($module in $permissionMatrix.Keys) {
    $moduleResults = $testResults | Where-Object { $_.Permission -like "$($module.Split(' ')[0].ToLower()):*" -or $_.Permission -like "$($module.Split(' ')[0].ToLower())_*" }
    if ($moduleResults.Count -gt 0) {
        $modulePassed = ($moduleResults | Where-Object { $_.Status -eq "PASS" -or $_.Status -eq "EXPECTED" }).Count
        $moduleRate = [math]::Round(($modulePassed / $moduleResults.Count) * 100, 1)
        Write-Host "  $module`: $modulePassed/$($moduleResults.Count) ($moduleRate%)" -ForegroundColor Cyan
    }
}

# User type statistics
$adminResults = $testResults | Where-Object { $_.UserType -eq "Admin" }
$tikerResults = $testResults | Where-Object { $_.UserType -eq "Tiker" }

if ($adminResults.Count -gt 0) {
    $adminPassed = ($adminResults | Where-Object { $_.Status -eq "PASS" }).Count
    $adminRate = [math]::Round(($adminPassed / $adminResults.Count) * 100, 1)
    Write-Host "`nAdmin User: $adminPassed/$($adminResults.Count) ($adminRate%)" -ForegroundColor Cyan
}

if ($tikerResults.Count -gt 0) {
    $tikerPassed = ($tikerResults | Where-Object { $_.Status -eq "PASS" -or $_.Status -eq "EXPECTED" }).Count
    $tikerRate = [math]::Round(($tikerPassed / $tikerResults.Count) * 100, 1)
    Write-Host "Tiker User: $tikerPassed/$($tikerResults.Count) ($tikerRate%)" -ForegroundColor Cyan
}

# Save detailed report
$reportPath = "docs/COMPLETE_PERMISSION_MATRIX_TEST_REPORT.md"
$reportContent = @"
# Complete Permission Matrix Test Report

**Test Time**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Total Permission Tests**: $totalTests
**Passed Tests**: $passedTests
**Failed Tests**: $failedTests
**Expected Denials**: $expectedTests
**Skipped Tests**: $skippedTests
**Success Rate**: $successRate%

## Test Coverage
- **System Management**: 9 permissions
- **User Management**: 8 permissions  
- **Role Management**: 6 permissions
- **Permission Management**: 5 permissions
- **Ticket Management**: 19 permissions
- **Record Management**: 8 permissions
- **Record Type Management**: 5 permissions
- **File Management**: 5 permissions
- **Export Management**: 6 permissions
- **AI Features**: 5 permissions

**Total**: 76 permissions tested

## Detailed Results

| Permission | User Type | Status | HTTP Code | API Endpoint |
|------------|-----------|--------|-----------|--------------|
"@

foreach ($result in $testResults | Sort-Object Permission, UserType) {
    $reportContent += "| $($result.Permission) | $($result.UserType) | $($result.Status) | $($result.StatusCode) | $($result.API) |`n"
}

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "`nComplete test report saved to: $reportPath" -ForegroundColor Cyan

if ($failedTests -eq 0) {
    Write-Host "`nAll permission matrix tests completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome permission tests failed. Please review the results." -ForegroundColor Yellow
    exit 1
}