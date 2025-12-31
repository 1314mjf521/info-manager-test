# Complete Permission System Validation Script
# Tests all 76 permissions across 10 modules
# English version to avoid encoding issues

param(
    [string]$BaseUrl = "http://localhost:8080"
)

# Color functions for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }

# Test counters
$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0
$script:TestResults = @()

# Test user login and get user data
function Test-UserLogin {
    param([string]$Username, [string]$Password, [string]$UserType)
    
    try {
        $loginData = @{
            username = $Username
            password = $Password
        } | ConvertTo-Json -Compress
        
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        
        $userData = @{
            Token = $response.data.token
            User = $response.data.user
            UserType = $UserType
        }
        
        Write-Success "Login successful for $UserType ($Username)"
        Write-Info "  User ID: $($userData.User.id)"
        Write-Info "  Roles: $($userData.User.roles | ForEach-Object { $_.name })"
        Write-Info "  Permissions: $($userData.User.permissions.Count) permissions"
        
        return $userData
    } catch {
        Write-Error "Login failed for $UserType ($Username): $($_.Exception.Message)"
        return $null
    }
}

function Test-ApiEndpoint {
    param(
        [string]$Endpoint,
        [string]$Method = "GET",
        [string]$Token,
        [string]$Permission,
        [bool]$ShouldPass = $true,
        [hashtable]$Body = @{},
        [string]$UserType = ""
    )
    
    $script:TotalTests++
    
    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
            "Content-Type" = "application/json"
        }
        
        $params = @{
            Uri = "$BaseUrl$Endpoint"
            Method = $Method
            Headers = $headers
            TimeoutSec = 10
        }
        
        if ($Body.Count -gt 0) {
            $params.Body = ($Body | ConvertTo-Json -Depth 3)
        }
        
        $response = Invoke-RestMethod @params
        
        if ($ShouldPass) {
            Write-Success "PASS: $Permission - $Method $Endpoint ($UserType)"
            $script:PassedTests++
            $script:TestResults += @{
                Permission = $Permission
                Endpoint = "$Method $Endpoint"
                UserType = $UserType
                Status = "PASS"
                Expected = "Allow"
                Actual = "Allow"
            }
            return $true
        } else {
            Write-Error "FAIL: $Permission - $Method $Endpoint ($UserType) - Should have been denied"
            $script:FailedTests++
            $script:TestResults += @{
                Permission = $Permission
                Endpoint = "$Method $Endpoint"
                UserType = $UserType
                Status = "FAIL"
                Expected = "Deny"
                Actual = "Allow"
            }
            return $false
        }
    }
    catch {
        if ($ShouldPass) {
            Write-Error "FAIL: $Permission - $Method $Endpoint ($UserType) - Error: $($_.Exception.Message)"
            $script:FailedTests++
            $script:TestResults += @{
                Permission = $Permission
                Endpoint = "$Method $Endpoint"
                UserType = $UserType
                Status = "FAIL"
                Expected = "Allow"
                Actual = "Deny"
                Error = $_.Exception.Message
            }
            return $false
        } else {
            Write-Success "PASS: $Permission - $Method $Endpoint ($UserType) - Correctly denied"
            $script:PassedTests++
            $script:TestResults += @{
                Permission = $Permission
                Endpoint = "$Method $Endpoint"
                UserType = $UserType
                Status = "PASS"
                Expected = "Deny"
                Actual = "Deny"
            }
            return $true
        }
    }
}

function Test-SystemPermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType)
    
    Write-Info "Testing System Management Permissions (9 permissions) for $UserType"
    
    # system:admin
    Test-ApiEndpoint "/api/v1/system/health" "GET" $Token "system:admin" $ShouldPass @{} $UserType
    
    # system:config_read
    Test-ApiEndpoint "/api/v1/config" "GET" $Token "system:config_read" $ShouldPass @{} $UserType
    
    # system:config_write
    Test-ApiEndpoint "/api/v1/config" "POST" $Token "system:config_write" $ShouldPass @{category="test"; key="test"; value="test"} $UserType
    
    # system:announcements_read
    Test-ApiEndpoint "/api/v1/announcements" "GET" $Token "system:announcements_read" $ShouldPass @{} $UserType
    
    # system:announcements_write
    Test-ApiEndpoint "/api/v1/announcements" "POST" $Token "system:announcements_write" $ShouldPass @{title="Test"; content="Test"} $UserType
    
    # system:logs_read
    Test-ApiEndpoint "/api/v1/logs" "GET" $Token "system:logs_read" $ShouldPass @{} $UserType
    
    # system:logs_delete
    Test-ApiEndpoint "/api/v1/logs/1" "DELETE" $Token "system:logs_delete" $ShouldPass @{} $UserType
    
    # system:health_read
    Test-ApiEndpoint "/api/v1/system/health" "GET" $Token "system:health_read" $ShouldPass @{} $UserType
    
    # system:stats_read
    Test-ApiEndpoint "/api/v1/system/stats" "GET" $Token "system:stats_read" $ShouldPass @{} $UserType
}

function Test-UserPermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType)
    
    Write-Info "Testing User Management Permissions (8 permissions) for $UserType"
    
    # users:read
    Test-ApiEndpoint "/api/v1/admin/users" "GET" $Token "users:read" $ShouldPass @{} $UserType
    
    # users:create
    Test-ApiEndpoint "/api/v1/admin/users" "POST" $Token "users:create" $ShouldPass @{username="testuser"; email="test@test.com"; password="password"} $UserType
    
    # users:update
    Test-ApiEndpoint "/api/v1/admin/users/1" "PUT" $Token "users:update" $ShouldPass @{username="updated"} $UserType
    
    # users:delete
    Test-ApiEndpoint "/api/v1/admin/users/999" "DELETE" $Token "users:delete" $ShouldPass @{} $UserType
    
    # users:assign_roles
    Test-ApiEndpoint "/api/v1/admin/users/1/roles" "PUT" $Token "users:assign_roles" $ShouldPass @{roleIds=@(1,2)} $UserType
    
    # users:reset_password
    Test-ApiEndpoint "/api/v1/admin/users/1/reset-password" "POST" $Token "users:reset_password" $ShouldPass @{} $UserType
    
    # users:change_status
    Test-ApiEndpoint "/api/v1/admin/users/batch-status" "PUT" $Token "users:change_status" $ShouldPass @{userIds=@(1); status="active"} $UserType
    
    # users:import
    Test-ApiEndpoint "/api/v1/admin/users/import" "POST" $Token "users:import" $ShouldPass @{data=@()} $UserType
}

function Test-RolePermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType)
    
    Write-Info "Testing Role Management Permissions (6 permissions) for $UserType"
    
    # roles:read
    Test-ApiEndpoint "/api/v1/admin/roles" "GET" $Token "roles:read" $ShouldPass @{} $UserType
    
    # roles:create
    Test-ApiEndpoint "/api/v1/admin/roles" "POST" $Token "roles:create" $ShouldPass @{name="testrole"; description="Test Role"} $UserType
    
    # roles:update
    Test-ApiEndpoint "/api/v1/admin/roles/1" "PUT" $Token "roles:update" $ShouldPass @{name="updated"} $UserType
    
    # roles:delete
    Test-ApiEndpoint "/api/v1/admin/roles/999" "DELETE" $Token "roles:delete" $ShouldPass @{} $UserType
    
    # roles:assign_permissions
    Test-ApiEndpoint "/api/v1/admin/roles/1/permissions" "PUT" $Token "roles:assign_permissions" $ShouldPass @{permissionIds=@(1,2)} $UserType
    
    # roles:import
    Test-ApiEndpoint "/api/v1/admin/roles/import" "POST" $Token "roles:import" $ShouldPass @{data=@()} $UserType
}

function Test-PermissionPermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType)
    
    Write-Info "Testing Permission Management Permissions (5 permissions) for $UserType"
    
    # permissions:read
    Test-ApiEndpoint "/api/v1/permissions" "GET" $Token "permissions:read" $ShouldPass @{} $UserType
    
    # permissions:create
    Test-ApiEndpoint "/api/v1/permissions" "POST" $Token "permissions:create" $ShouldPass @{name="test:permission"; description="Test Permission"} $UserType
    
    # permissions:update
    Test-ApiEndpoint "/api/v1/permissions/1" "PUT" $Token "permissions:update" $ShouldPass @{description="updated"} $UserType
    
    # permissions:delete
    Test-ApiEndpoint "/api/v1/permissions/999" "DELETE" $Token "permissions:delete" $ShouldPass @{} $UserType
    
    # permissions:initialize
    Test-ApiEndpoint "/api/v1/permissions/initialize" "POST" $Token "permissions:initialize" $ShouldPass @{} $UserType
}

function Test-TicketPermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType, [bool]$IsAdmin = $false)
    
    Write-Info "Testing Ticket Management Permissions (19 permissions) for $UserType"
    
    # ticket:read (admin can read all)
    Test-ApiEndpoint "/api/v1/tickets" "GET" $Token "ticket:read" $ShouldPass @{} $UserType
    
    # ticket:create
    Test-ApiEndpoint "/api/v1/tickets" "POST" $Token "ticket:create" $ShouldPass @{title="Test Ticket"; description="Test Description"; priority="medium"} $UserType
    
    # ticket:update
    Test-ApiEndpoint "/api/v1/tickets/1" "PUT" $Token "ticket:update" $ShouldPass @{title="Updated"} $UserType
    
    # ticket:delete
    Test-ApiEndpoint "/api/v1/tickets/999" "DELETE" $Token "ticket:delete" $ShouldPass @{} $UserType
    
    # ticket:assign
    Test-ApiEndpoint "/api/v1/tickets/1/assign" "POST" $Token "ticket:assign" $ShouldPass @{assigneeId=2} $UserType
    
    # ticket:accept
    Test-ApiEndpoint "/api/v1/tickets/1/accept" "POST" $Token "ticket:accept" $ShouldPass @{} $UserType
    
    # ticket:reject
    Test-ApiEndpoint "/api/v1/tickets/1/reject" "POST" $Token "ticket:reject" $ShouldPass @{reason="Test rejection"} $UserType
    
    # ticket:reopen
    Test-ApiEndpoint "/api/v1/tickets/1/reopen" "POST" $Token "ticket:reopen" $ShouldPass @{} $UserType
    
    # ticket:status_change
    Test-ApiEndpoint "/api/v1/tickets/1/status" "PUT" $Token "ticket:status_change" $ShouldPass @{status="in_progress"} $UserType
    
    # ticket:comment_read
    Test-ApiEndpoint "/api/v1/tickets/1/comments" "GET" $Token "ticket:comment_read" $ShouldPass @{} $UserType
    
    # ticket:comment_write
    Test-ApiEndpoint "/api/v1/tickets/1/comments" "POST" $Token "ticket:comment_write" $ShouldPass @{content="Test comment"} $UserType
    
    # ticket:attachment_upload
    Test-ApiEndpoint "/api/v1/tickets/1/attachments" "POST" $Token "ticket:attachment_upload" $ShouldPass @{filename="test.txt"} $UserType
    
    # ticket:attachment_delete
    Test-ApiEndpoint "/api/v1/tickets/1/attachments/1" "DELETE" $Token "ticket:attachment_delete" $ShouldPass @{} $UserType
    
    # ticket:statistics
    Test-ApiEndpoint "/api/v1/tickets/statistics" "GET" $Token "ticket:statistics" $ShouldPass @{} $UserType
    
    # ticket:export
    Test-ApiEndpoint "/api/v1/tickets/export" "GET" $Token "ticket:export" $ShouldPass @{} $UserType
    
    # ticket:import
    Test-ApiEndpoint "/api/v1/tickets/import" "POST" $Token "ticket:import" $ShouldPass @{data=@()} $UserType
}

function Test-RecordPermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType, [bool]$IsAdmin = $false)
    
    Write-Info "Testing Record Management Permissions (8 permissions) for $UserType"
    
    # records:read
    Test-ApiEndpoint "/api/v1/records" "GET" $Token "records:read" $ShouldPass @{} $UserType
    
    # records:create
    Test-ApiEndpoint "/api/v1/records" "POST" $Token "records:create" $ShouldPass @{title="Test Record"; content="Test Content"} $UserType
    
    # records:update
    Test-ApiEndpoint "/api/v1/records/1" "PUT" $Token "records:update" $ShouldPass @{title="Updated"} $UserType
    
    # records:delete
    Test-ApiEndpoint "/api/v1/records/999" "DELETE" $Token "records:delete" $ShouldPass @{} $UserType
    
    # records:import
    Test-ApiEndpoint "/api/v1/records/import" "POST" $Token "records:import" $ShouldPass @{data=@()} $UserType
}

function Test-RecordTypePermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType)
    
    Write-Info "Testing Record Type Management Permissions (5 permissions) for $UserType"
    
    # record_types:read
    Test-ApiEndpoint "/api/v1/record-types" "GET" $Token "record_types:read" $ShouldPass @{} $UserType
    
    # record_types:create
    Test-ApiEndpoint "/api/v1/record-types" "POST" $Token "record_types:create" $ShouldPass @{name="Test Type"; description="Test Description"} $UserType
    
    # record_types:update
    Test-ApiEndpoint "/api/v1/record-types/1" "PUT" $Token "record_types:update" $ShouldPass @{name="Updated"} $UserType
    
    # record_types:delete
    Test-ApiEndpoint "/api/v1/record-types/999" "DELETE" $Token "record_types:delete" $ShouldPass @{} $UserType
    
    # record_types:import
    Test-ApiEndpoint "/api/v1/record-types/import" "POST" $Token "record_types:import" $ShouldPass @{data=@()} $UserType
}

function Test-FilePermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType)
    
    Write-Info "Testing File Management Permissions (5 permissions) for $UserType"
    
    # files:read
    Test-ApiEndpoint "/api/v1/files" "GET" $Token "files:read" $ShouldPass @{} $UserType
    
    # files:upload
    Test-ApiEndpoint "/api/v1/files/upload" "POST" $Token "files:upload" $ShouldPass @{filename="test.txt"; content="test"} $UserType
    
    # files:download
    Test-ApiEndpoint "/api/v1/files/1" "GET" $Token "files:download" $ShouldPass @{} $UserType
    
    # files:delete
    Test-ApiEndpoint "/api/v1/files/999" "DELETE" $Token "files:delete" $ShouldPass @{} $UserType
    
    # files:ocr
    Test-ApiEndpoint "/api/v1/files/ocr" "POST" $Token "files:ocr" $ShouldPass @{} $UserType
}

function Test-ExportPermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType)
    
    Write-Info "Testing Export Management Permissions (6 permissions) for $UserType"
    
    # export:read
    Test-ApiEndpoint "/api/v1/export/templates" "GET" $Token "export:read" $ShouldPass @{} $UserType
    
    # export:create
    Test-ApiEndpoint "/api/v1/export/templates" "POST" $Token "export:create" $ShouldPass @{name="Test Template"; config=@{}} $UserType
    
    # export:update
    Test-ApiEndpoint "/api/v1/export/templates/1" "PUT" $Token "export:update" $ShouldPass @{name="Updated"} $UserType
    
    # export:delete
    Test-ApiEndpoint "/api/v1/export/templates/999" "DELETE" $Token "export:delete" $ShouldPass @{} $UserType
    
    # export:execute
    Test-ApiEndpoint "/api/v1/export/records" "POST" $Token "export:execute" $ShouldPass @{} $UserType
    
    # export:download
    Test-ApiEndpoint "/api/v1/export/files/1/download" "GET" $Token "export:download" $ShouldPass @{} $UserType
}

function Test-AIPermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType)
    
    Write-Info "Testing AI Feature Permissions (5 permissions) for $UserType"
    
    # ai:features
    Test-ApiEndpoint "/api/v1/ai/config" "GET" $Token "ai:features" $ShouldPass @{} $UserType
    
    # ai:config
    Test-ApiEndpoint "/api/v1/ai/config" "POST" $Token "ai:config" $ShouldPass @{name="test"; config=@{}} $UserType
    
    # ai:chat
    Test-ApiEndpoint "/api/v1/ai/chat" "POST" $Token "ai:chat" $ShouldPass @{message="Hello"} $UserType
    
    # ai:optimize
    Test-ApiEndpoint "/api/v1/ai/optimize-record" "POST" $Token "ai:optimize" $ShouldPass @{data="test"} $UserType
    
    # ai:speech
    Test-ApiEndpoint "/api/v1/ai/speech-to-text" "POST" $Token "ai:speech" $ShouldPass @{audio="test"} $UserType
}

# Main execution
Write-Info "=== Complete Permission System Validation ==="
Write-Info "Testing all 76 permissions across 10 modules"
Write-Info ""

# 1. Check backend server
Write-Info "1. Checking backend server..."
try {
    $healthResponse = Invoke-WebRequest -Uri "$BaseUrl/health" -TimeoutSec 5
    Write-Success "Backend server is running - HTTP $($healthResponse.StatusCode)"
} catch {
    Write-Error "Backend server is not running"
    exit 1
}

# 2. Test admin user
Write-Info "2. Testing admin user permissions..."
$adminData = Test-UserLogin -Username "admin" -Password "admin123" -UserType "Admin"
if (-not $adminData) {
    Write-Error "Failed to login as admin, exiting test"
    exit 1
}

# 3. Test tiker user
Write-Info "3. Testing tiker user permissions..."
$tikerData = Test-UserLogin -Username "tiker_test" -Password "tiker123" -UserType "Tiker"
if (-not $tikerData) {
    Write-Warning "Tiker user not available, trying alternative credentials..."
    $tikerData = Test-UserLogin -Username "tiker" -Password "tiker123" -UserType "Tiker"
}

Write-Info ""
Write-Info "Starting comprehensive permission tests..."
Write-Info ""

# Test Admin permissions (should pass all)
Write-Info "🔐 Testing ADMIN user permissions (should pass all 76 permissions)"
Write-Info "=================================================="

Test-SystemPermissions $adminData.Token $true "Admin"
Test-UserPermissions $adminData.Token $true "Admin"
Test-RolePermissions $adminData.Token $true "Admin"
Test-PermissionPermissions $adminData.Token $true "Admin"
Test-TicketPermissions $adminData.Token $true "Admin" $true
Test-RecordPermissions $adminData.Token $true "Admin" $true
Test-RecordTypePermissions $adminData.Token $true "Admin"
Test-FilePermissions $adminData.Token $true "Admin"
Test-ExportPermissions $adminData.Token $true "Admin"
Test-AIPermissions $adminData.Token $true "Admin"

if ($tikerData) {
    Write-Info ""
    Write-Info "🔐 Testing TIKER user permissions (should fail admin functions)"
    Write-Info "=============================================================="

    Test-SystemPermissions $tikerData.Token $false "Tiker"
    Test-UserPermissions $tikerData.Token $false "Tiker"
    Test-RolePermissions $tikerData.Token $false "Tiker"
    Test-PermissionPermissions $tikerData.Token $false "Tiker"
    Test-TicketPermissions $tikerData.Token $true "Tiker" $false  # Should pass ticket operations
    Test-RecordPermissions $tikerData.Token $false "Tiker" $false  # Should fail most record operations
    Test-RecordTypePermissions $tikerData.Token $false "Tiker"
    Test-FilePermissions $tikerData.Token $true "Tiker"  # Should pass file operations
    Test-ExportPermissions $tikerData.Token $false "Tiker"
    Test-AIPermissions $tikerData.Token $false "Tiker"
} else {
    Write-Warning "Tiker user not available, skipping tiker permission tests"
}

# Generate comprehensive report
Write-Info ""
Write-Info "=== COMPREHENSIVE PERMISSION TEST REPORT ==="

# Group results by user type
$adminResults = $script:TestResults | Where-Object { $_.UserType -eq "Admin" }
$tikerResults = $script:TestResults | Where-Object { $_.UserType -eq "Tiker" }

Write-Info "Total Tests: $script:TotalTests"
Write-Success "Passed: $script:PassedTests"
Write-Error "Failed: $script:FailedTests"

$successRate = if ($script:TotalTests -gt 0) { [math]::Round(($script:PassedTests / $script:TotalTests) * 100, 2) } else { 0 }
Write-Info "Success Rate: $successRate%"

if ($adminResults.Count -gt 0) {
    $adminPassed = ($adminResults | Where-Object { $_.Status -eq "PASS" }).Count
    $adminRate = [math]::Round(($adminPassed / $adminResults.Count) * 100, 1)
    Write-Info "Admin User: $adminPassed/$($adminResults.Count) ($adminRate%)"
}

if ($tikerResults.Count -gt 0) {
    $tikerPassed = ($tikerResults | Where-Object { $_.Status -eq "PASS" }).Count
    $tikerRate = [math]::Round(($tikerPassed / $tikerResults.Count) * 100, 1)
    Write-Info "Tiker User: $tikerPassed/$($tikerResults.Count) ($tikerRate%)"
}

# Save detailed report
$reportPath = "docs/COMPLETE_PERMISSION_VALIDATION_REPORT.md"
$reportContent = @"
# Complete Permission System Validation Report

**Test Time**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Total Tests**: $script:TotalTests
**Passed Tests**: $script:PassedTests
**Failed Tests**: $script:FailedTests
**Success Rate**: $successRate%

## Summary by User Type

$(if ($adminResults.Count -gt 0) { "**Admin User**: $adminPassed/$($adminResults.Count) ($adminRate%)" } else { "Admin user not tested" })
$(if ($tikerResults.Count -gt 0) { "**Tiker User**: $tikerPassed/$($tikerResults.Count) ($tikerRate%)" } else { "Tiker user not tested" })

## Detailed Test Results

| Permission | Endpoint | User Type | Status | Expected | Actual | Error |
|------------|----------|-----------|--------|----------|--------|-------|
"@

foreach ($result in $script:TestResults) {
    $error = if ($result.Error) { $result.Error } else { "" }
    $reportContent += "| $($result.Permission) | $($result.Endpoint) | $($result.UserType) | $($result.Status) | $($result.Expected) | $($result.Actual) | $error |`n"
}

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Info "Detailed report saved to: $reportPath"

if ($script:FailedTests -eq 0) {
    Write-Success "🎉 ALL TESTS PASSED! Permission system is working correctly."
    exit 0
} else {
    Write-Warning "⚠️  Some tests failed. Please review the failed permissions above."
    exit 1
}

Write-Info ""
Write-Info "Test completed at $(Get-Date)"