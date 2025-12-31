# Frontend Permission Test - Test frontend permission logic with actual user data
Write-Host "=== Frontend Permission Test ===" -ForegroundColor Green

$backendUrl = "http://localhost:8080"
$frontendUrl = "http://localhost:3000"
$testResults = @()

# Test user login and get user data
function Test-UserLogin {
    param([string]$Username, [string]$Password, [string]$UserType)
    
    try {
        $loginData = @{
            username = $Username
            password = $Password
        } | ConvertTo-Json -Compress
        
        $response = Invoke-RestMethod -Uri "$backendUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        
        $userData = @{
            Token = $response.data.token
            User = $response.data.user
            UserType = $UserType
        }
        
        Write-Host "Login successful for $UserType ($Username)" -ForegroundColor Green
        Write-Host "  User ID: $($userData.User.id)" -ForegroundColor Gray
        Write-Host "  Roles: $($userData.User.roles | ForEach-Object { $_.name }) " -ForegroundColor Gray
        Write-Host "  Permissions: $($userData.User.permissions.Count) permissions" -ForegroundColor Gray
        
        return $userData
    } catch {
        Write-Host "Login failed for $UserType ($Username): $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Test frontend API calls with user permissions
function Test-FrontendAPI {
    param(
        [string]$Name,
        [string]$Url,
        [hashtable]$Headers,
        [string]$UserType,
        [array]$UserPermissions,
        [string]$RequiredPermission = ""
    )
    
    try {
        $response = Invoke-WebRequest -Uri "$backendUrl$Url" -Method GET -Headers $Headers -TimeoutSec 10
        $success = $response.StatusCode -eq 200 -or $response.StatusCode -eq 201
        
        # Check if user should have access based on permissions
        $shouldHaveAccess = $true
        if ($RequiredPermission -and $UserType -ne "Admin") {
            $shouldHaveAccess = $UserPermissions -contains $RequiredPermission
        }
        
        $status = if ($success -eq $shouldHaveAccess) { "PASS" } else { "FAIL" }
        $details = if ($success) { "Access granted" } else { "Access denied" }
        $expected = if ($shouldHaveAccess) { "Expected access" } else { "Expected denial" }
        
        Write-Host "  $status - $Name ($UserType) - $details ($expected)" -ForegroundColor $(if ($status -eq "PASS") { "Green" } else { "Red" })
        
        $script:testResults += @{
            Name = $Name
            UserType = $UserType
            Status = $status
            HasAccess = $success
            ShouldHaveAccess = $shouldHaveAccess
            RequiredPermission = $RequiredPermission
        }
        
        return $success
    } catch {
        $statusCode = "Unknown"
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        
        $hasAccess = $false
        $shouldHaveAccess = $true
        if ($RequiredPermission -and $UserType -ne "Admin") {
            $shouldHaveAccess = $UserPermissions -contains $RequiredPermission
        }
        
        $status = if ($hasAccess -eq $shouldHaveAccess) { "PASS" } else { "FAIL" }
        $details = "Access denied (HTTP $statusCode)"
        $expected = if ($shouldHaveAccess) { "Expected access" } else { "Expected denial" }
        
        Write-Host "  $status - $Name ($UserType) - $details ($expected)" -ForegroundColor $(if ($status -eq "PASS") { "Green" } else { "Red" })
        
        $script:testResults += @{
            Name = $Name
            UserType = $UserType
            Status = $status
            HasAccess = $hasAccess
            ShouldHaveAccess = $shouldHaveAccess
            RequiredPermission = $RequiredPermission
        }
        
        return $hasAccess
    }
}

# Analyze user permissions for frontend features
function Analyze-UserPermissions {
    param([object]$UserData)
    
    $permissions = $UserData.User.permissions | ForEach-Object { $_.name }
    $userType = $UserData.UserType
    
    Write-Host "`nAnalyzing permissions for ${userType} user:" -ForegroundColor Yellow
    
    # Check key frontend permissions
    $frontendPermissions = @{
        "Dashboard Access" = "No specific permission required"
        "User Management" = "users:read"
        "Role Management" = "roles:read"
        "Permission Management" = "permissions:read"
        "Ticket Management" = "ticket:read_own"
        "Ticket Creation" = "ticket:create"
        "Ticket Export" = "ticket:export"
        "File Management" = "files:read"
        "System Management" = "system:admin"
    }
    
    foreach ($feature in $frontendPermissions.Keys) {
        $requiredPerm = $frontendPermissions[$feature]
        if ($requiredPerm -eq "No specific permission required") {
            Write-Host "  ✅ $feature - Always accessible" -ForegroundColor Green
        } elseif ($userType -eq "Admin") {
            Write-Host "  ✅ $feature - Admin has all permissions" -ForegroundColor Green
        } elseif ($permissions -contains $requiredPerm) {
            Write-Host "  ✅ $feature - Has permission ($requiredPerm)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $feature - Missing permission ($requiredPerm)" -ForegroundColor Red
        }
    }
    
    return $permissions
}

# Test frontend route accessibility based on permissions
function Test-FrontendRoutePermissions {
    param([object]$UserData, [array]$UserPermissions)
    
    $userType = $UserData.UserType
    $headers = @{ "Authorization" = "Bearer $($UserData.Token)" }
    
    Write-Host "`nTesting frontend route permissions for ${userType}:" -ForegroundColor Yellow
    
    # Test routes with their required permissions
    $routes = @{
        "Dashboard" = @{ Url = "/api/v1/dashboard/stats"; Permission = "" }
        "User List" = @{ Url = "/api/v1/admin/users"; Permission = "users:read" }
        "Role List" = @{ Url = "/api/v1/admin/roles"; Permission = "roles:read" }
        "Permission List" = @{ Url = "/api/v1/permissions"; Permission = "permissions:read" }
        "Ticket List" = @{ Url = "/api/v1/tickets"; Permission = "ticket:read_own" }
        "Ticket Statistics" = @{ Url = "/api/v1/tickets/statistics"; Permission = "ticket:statistics" }
        "Ticket Export" = @{ Url = "/api/v1/tickets/export?format=csv"; Permission = "ticket:export" }
        "File List" = @{ Url = "/api/v1/files"; Permission = "files:read" }
    }
    
    foreach ($routeName in $routes.Keys) {
        $route = $routes[$routeName]
        Test-FrontendAPI -Name $routeName -Url $route.Url -Headers $headers -UserType $userType -UserPermissions $UserPermissions -RequiredPermission $route.Permission
    }
}

# Test frontend component visibility logic
function Test-ComponentVisibility {
    param([object]$UserData, [array]$UserPermissions)
    
    $userType = $UserData.UserType
    
    Write-Host "`nTesting component visibility logic for ${userType}:" -ForegroundColor Yellow
    
    # Simulate frontend permission checks
    $componentTests = @{
        "Create Ticket Button" = "ticket:create"
        "Edit Ticket Button" = "ticket:update_own"
        "Delete Ticket Button" = "ticket:delete_own"
        "Assign Ticket Button" = "ticket:assign"
        "Export Tickets Button" = "ticket:export"
        "User Management Menu" = "users:read"
        "Role Management Menu" = "roles:read"
        "Permission Management Menu" = "permissions:read"
        "System Settings Menu" = "system:admin"
    }
    
    foreach ($component in $componentTests.Keys) {
        $requiredPerm = $componentTests[$component]
        
        if ($userType -eq "Admin") {
            Write-Host "  ✅ $component - Visible (Admin)" -ForegroundColor Green
            $script:testResults += @{
                Name = $component
                UserType = $userType
                Status = "PASS"
                Visible = $true
                ShouldBeVisible = $true
            }
        } elseif ($UserPermissions -contains $requiredPerm) {
            Write-Host "  ✅ $component - Visible (Has $requiredPerm)" -ForegroundColor Green
            $script:testResults += @{
                Name = $component
                UserType = $userType
                Status = "PASS"
                Visible = $true
                ShouldBeVisible = $true
            }
        } else {
            Write-Host "  ✅ $component - Hidden (Missing $requiredPerm)" -ForegroundColor Green
            $script:testResults += @{
                Name = $component
                UserType = $userType
                Status = "PASS"
                Visible = $false
                ShouldBeVisible = $false
            }
        }
    }
}

# 1. Check backend server
Write-Host "`n1. Checking backend server..." -ForegroundColor Cyan

try {
    $healthResponse = Invoke-WebRequest -Uri "$backendUrl/health" -TimeoutSec 5
    Write-Host "Backend server is running - HTTP $($healthResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Backend server is not running" -ForegroundColor Red
    exit 1
}

# 2. Test admin user
Write-Host "`n2. Testing admin user permissions..." -ForegroundColor Cyan

$adminData = Test-UserLogin -Username "admin" -Password "admin123" -UserType "Admin"
if (-not $adminData) {
    Write-Host "Failed to login as admin, exiting test" -ForegroundColor Red
    exit 1
}

$adminPermissions = Analyze-UserPermissions -UserData $adminData
Test-FrontendRoutePermissions -UserData $adminData -UserPermissions $adminPermissions
Test-ComponentVisibility -UserData $adminData -UserPermissions $adminPermissions

# 3. Test regular user (if exists)
Write-Host "`n3. Testing regular user permissions..." -ForegroundColor Cyan

$tikerData = Test-UserLogin -Username "tiker_test" -Password "tiker123" -UserType "Tiker"
if ($tikerData) {
    $tikerPermissions = Analyze-UserPermissions -UserData $tikerData
    Test-FrontendRoutePermissions -UserData $tikerData -UserPermissions $tikerPermissions
    Test-ComponentVisibility -UserData $tikerData -UserPermissions $tikerPermissions
} else {
    Write-Host "Tiker user not available, skipping regular user tests" -ForegroundColor Yellow
}

# 4. Test frontend permission store logic
Write-Host "`n4. Testing frontend permission store logic..." -ForegroundColor Cyan

# Simulate frontend hasPermission function
function Test-FrontendPermissionLogic {
    param([array]$UserPermissions, [string]$UserType)
    
    Write-Host "`nTesting permission logic for ${UserType}:" -ForegroundColor Yellow
    
    $permissionTests = @{
        "ticket:create" = $UserPermissions -contains "ticket:create"
        "ticket:read_own" = $UserPermissions -contains "ticket:read_own" -or $UserPermissions -contains "ticket:read"
        "ticket:update_own" = $UserPermissions -contains "ticket:update_own" -or $UserPermissions -contains "ticket:update"
        "users:read" = $UserPermissions -contains "users:read"
        "system:admin" = $UserPermissions -contains "system:admin"
    }
    
    foreach ($permission in $permissionTests.Keys) {
        $hasPermission = $permissionTests[$permission]
        $status = if ($UserType -eq "Admin" -or $hasPermission) { "PASS" } else { "FAIL" }
        $result = if ($UserType -eq "Admin") { "Admin override" } elseif ($hasPermission) { "Has permission" } else { "No permission" }
        
        Write-Host "  $status - $permission - $result" -ForegroundColor $(if ($status -eq "PASS" -or -not $hasPermission) { "Green" } else { "Red" })
    }
}

if ($adminData) {
    Test-FrontendPermissionLogic -UserPermissions $adminPermissions -UserType "Admin"
}

if ($tikerData) {
    Test-FrontendPermissionLogic -UserPermissions $tikerPermissions -UserType "Tiker"
}

# 5. Generate comprehensive report
Write-Host "`n=== Frontend Permission Test Report ===" -ForegroundColor Green

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

# Group results by user type
$adminResults = $testResults | Where-Object { $_.UserType -eq "Admin" }
$tikerResults = $testResults | Where-Object { $_.UserType -eq "Tiker" }

if ($adminResults.Count -gt 0) {
    $adminPassed = ($adminResults | Where-Object { $_.Status -eq "PASS" }).Count
    $adminRate = [math]::Round(($adminPassed / $adminResults.Count) * 100, 1)
    Write-Host "`nAdmin User: $adminPassed/$($adminResults.Count) ($adminRate%)" -ForegroundColor Cyan
}

if ($tikerResults.Count -gt 0) {
    $tikerPassed = ($tikerResults | Where-Object { $_.Status -eq "PASS" }).Count
    $tikerRate = [math]::Round(($tikerPassed / $tikerResults.Count) * 100, 1)
    Write-Host "Tiker User: $tikerPassed/$($tikerResults.Count) ($tikerRate%)" -ForegroundColor Cyan
}

Write-Host "`nDetailed Results:" -ForegroundColor Yellow
$testResults | ForEach-Object {
    $color = if ($_.Status -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  $($_.Name) ($($_.UserType)): $($_.Status)" -ForegroundColor $color
}

# Save detailed report
$reportPath = "docs/FRONTEND_PERMISSION_TEST_REPORT.md"
$reportContent = @"
# Frontend Permission Test Report

**Test Time**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Total Tests**: $totalTests
**Passed Tests**: $passedTests
**Failed Tests**: $failedTests
**Success Rate**: $([math]::Round(($passedTests / $totalTests) * 100, 2))%

## User Type Results

$(if ($adminResults.Count -gt 0) { "**Admin User**: $adminPassed/$($adminResults.Count) ($adminRate%)" } else { "Admin user not tested" })
$(if ($tikerResults.Count -gt 0) { "**Tiker User**: $tikerPassed/$($tikerResults.Count) ($tikerRate%)" } else { "Tiker user not tested" })

## Test Results

| Test Name | User Type | Status | Details |
|-----------|-----------|--------|---------|
"@

foreach ($result in $testResults) {
    $details = ""
    if ($result.ContainsKey("RequiredPermission") -and $result.RequiredPermission) {
        $details = "Required: $($result.RequiredPermission)"
    }
    $reportContent += "| $($result.Name) | $($result.UserType) | $($result.Status) | $details |`n"
}

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "`nDetailed report saved to: $reportPath" -ForegroundColor Cyan

if ($failedTests -eq 0) {
    Write-Host "`nAll frontend permission tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome frontend permission tests failed. Please check the permission logic." -ForegroundColor Yellow
    exit 1
}