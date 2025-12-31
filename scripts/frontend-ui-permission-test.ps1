# Frontend UI Permission Test
# This script analyzes frontend permission logic and UI element visibility

Write-Host "=== FRONTEND UI PERMISSION TEST ===" -ForegroundColor Green

# Test users and their expected permissions
$testUsers = @(
    @{
        Username = "admin"
        Password = "admin123"
        ExpectedPermissions = @("ALL")
        Description = "System Administrator"
    },
    @{
        Username = "tiker"
        Password = "QAZwe@01010"
        ExpectedPermissions = @(
            "ticket:assign", "ticket:attachment_upload", "ticket:comment_read", 
            "ticket:comment_write", "ticket:create", "ticket:delete_own", 
            "ticket:read_own", "ticket:statistics", "ticket:update_own",
            "files:download", "files:read", "files:upload"
        )
        Description = "Ticket User"
    }
)

# Define UI elements and their permission requirements
$uiElements = @{
    "MainLayout" = @{
        "Dashboard Menu" = @{Permission = $null; ShouldShow = @{admin = $true; tiker = $true}}
        "Tickets Menu" = @{Permission = "ticket:read_own"; ShouldShow = @{admin = $true; tiker = $true}}
        "Files Menu" = @{Permission = "files:read"; ShouldShow = @{admin = $true; tiker = $true}}
        "Users Menu" = @{Permission = "users:read"; ShouldShow = @{admin = $true; tiker = $false}}
        "Roles Menu" = @{Permission = "system:admin"; ShouldShow = @{admin = $true; tiker = $false}}
        "Permissions Menu" = @{Permission = "system:admin"; ShouldShow = @{admin = $true; tiker = $false}}
        "Records Menu" = @{Permission = "records:read"; ShouldShow = @{admin = $true; tiker = $false}}
        "Export Menu" = @{Permission = "records:read"; ShouldShow = @{admin = $true; tiker = $false}}
        "AI Menu" = @{Permission = "ai:features"; ShouldShow = @{admin = $true; tiker = $false}}
        "System Menu" = @{Permission = "system:admin"; ShouldShow = @{admin = $true; tiker = $false}}
    }
    "TicketListView" = @{
        "Create Ticket Button" = @{Permission = "ticket:create"; ShouldShow = @{admin = $true; tiker = $true}}
        "Import Tickets Button" = @{Permission = "ticket:import"; ShouldShow = @{admin = $true; tiker = $false}}
        "Export Tickets Button" = @{Permission = "ticket:export"; ShouldShow = @{admin = $true; tiker = $false}}
        "Statistics Cards" = @{Permission = "ticket:statistics"; ShouldShow = @{admin = $true; tiker = $true}}
        "Edit Button (Own Ticket)" = @{Permission = "ticket:update_own"; ShouldShow = @{admin = $true; tiker = $true}}
        "Delete Button (Own Ticket)" = @{Permission = "ticket:delete_own"; ShouldShow = @{admin = $true; tiker = $true}}
        "Assign Button" = @{Permission = "ticket:assign"; ShouldShow = @{admin = $true; tiker = $true}}
        "Accept Button (Dropdown)" = @{Permission = "ticket:accept"; ShouldShow = @{admin = $true; tiker = $false}}
        "Reject Button (Dropdown)" = @{Permission = "ticket:reject"; ShouldShow = @{admin = $true; tiker = $false}}
        "Approve Button (Dropdown)" = @{Permission = "ticket:approve"; ShouldShow = @{admin = $true; tiker = $false}}
        "Return Button (Dropdown)" = @{Permission = "ticket:return"; ShouldShow = @{admin = $true; tiker = $false}}
        "Reopen Button (Dropdown)" = @{Permission = "ticket:reopen"; ShouldShow = @{admin = $true; tiker = $false}}
    }
    "Routes" = @{
        "/dashboard" = @{Permission = $null; ShouldAccess = @{admin = $true; tiker = $true}}
        "/tickets" = @{Permission = "ticket:read_own"; ShouldAccess = @{admin = $true; tiker = $true}}
        "/tickets/:id" = @{Permission = "ticket:read_own"; ShouldAccess = @{admin = $true; tiker = $true}}
        "/tickets/:id/edit" = @{Permission = "ticket:update_own"; ShouldAccess = @{admin = $true; tiker = $true}}
        "/tickets/create" = @{Permission = "ticket:create"; ShouldAccess = @{admin = $true; tiker = $true}}
        "/tickets/:id/assign" = @{Permission = "ticket:assign"; ShouldAccess = @{admin = $true; tiker = $true}}
        "/files" = @{Permission = "files:read"; ShouldAccess = @{admin = $true; tiker = $true}}
        "/users" = @{Permission = "users:read"; ShouldAccess = @{admin = $true; tiker = $false}}
        "/roles" = @{Permission = "system:admin"; ShouldAccess = @{admin = $true; tiker = $false}}
        "/permissions" = @{Permission = "system:admin"; ShouldAccess = @{admin = $true; tiker = $false}}
    }
}

# Test each user
foreach ($testUser in $testUsers) {
    Write-Host "`n=== TESTING USER: $($testUser.Username) ($($testUser.Description)) ===" -ForegroundColor Yellow
    
    # Login to get actual permissions
    $loginData = @{
        username = $testUser.Username
        password = $testUser.Password
    } | ConvertTo-Json
    
    try {
        $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        $actualPermissions = $loginResponse.data.user.permissions | ForEach-Object { $_.name }
        
        Write-Host "Login: SUCCESS" -ForegroundColor Green
        Write-Host "Actual Permissions: $($actualPermissions.Count)" -ForegroundColor Cyan
        
        # Compare expected vs actual permissions
        if ($testUser.ExpectedPermissions[0] -eq "ALL") {
            Write-Host "Expected: ALL permissions (admin user)" -ForegroundColor Cyan
        } else {
            Write-Host "Expected Permissions: $($testUser.ExpectedPermissions.Count)" -ForegroundColor Cyan
            
            # Check for missing permissions
            $missingPermissions = $testUser.ExpectedPermissions | Where-Object { $actualPermissions -notcontains $_ }
            if ($missingPermissions.Count -gt 0) {
                Write-Host "Missing Permissions:" -ForegroundColor Red
                $missingPermissions | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
            }
            
            # Check for extra permissions
            $extraPermissions = $actualPermissions | Where-Object { $testUser.ExpectedPermissions -notcontains $_ }
            if ($extraPermissions.Count -gt 0) {
                Write-Host "Extra Permissions:" -ForegroundColor Yellow
                $extraPermissions | ForEach-Object { Write-Host "  + $_" -ForegroundColor Yellow }
            }
        }
        
        # Test UI elements
        foreach ($component in $uiElements.Keys) {
            Write-Host "`n--- Testing $component ---" -ForegroundColor Magenta
            
            foreach ($element in $uiElements[$component].Keys) {
                $elementConfig = $uiElements[$component][$element]
                $requiredPermission = $elementConfig.Permission
                $shouldShow = $elementConfig.ShouldShow[$testUser.Username.ToLower()]
                $shouldAccess = $elementConfig.ShouldAccess[$testUser.Username.ToLower()]
                
                # Determine if user has required permission
                $hasPermission = $false
                if ($requiredPermission -eq $null) {
                    $hasPermission = $true  # No permission required
                } elseif ($testUser.Username -eq "admin") {
                    $hasPermission = $true  # Admin has all permissions
                } else {
                    $hasPermission = $actualPermissions -contains $requiredPermission
                }
                
                # Check if expectation matches reality
                $expectedResult = if ($component -eq "Routes") { $shouldAccess } else { $shouldShow }
                $testResult = if ($hasPermission -eq $expectedResult) { "PASS" } else { "FAIL" }
                $resultColor = if ($testResult -eq "PASS") { "Green" } else { "Red" }
                
                # Display result
                $permissionText = if ($requiredPermission) { $requiredPermission } else { "No permission required" }
                $expectedText = if ($component -eq "Routes") { 
                    if ($shouldAccess) { "Should Access" } else { "Should Block" }
                } else { 
                    if ($shouldShow) { "Should Show" } else { "Should Hide" }
                }
                
                Write-Host "  $element`: $testResult" -ForegroundColor $resultColor
                Write-Host "    Permission: $permissionText" -ForegroundColor Gray
                Write-Host "    Has Permission: $hasPermission, $expectedText`: $expectedResult" -ForegroundColor Gray
                
                if ($testResult -eq "FAIL") {
                    Write-Host "    ⚠️  MISMATCH: User permission status doesn't match expected UI behavior" -ForegroundColor Red
                }
            }
        }
        
    } catch {
        Write-Host "Login FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== FRONTEND UI PERMISSION ANALYSIS ===" -ForegroundColor Green

Write-Host "`nKey Findings:" -ForegroundColor Cyan
Write-Host "1. Menu Items: Should be controlled by route permissions" -ForegroundColor White
Write-Host "2. Action Buttons: Should be controlled by specific operation permissions" -ForegroundColor White
Write-Host "3. Dropdown Actions: Should check both permission and context (e.g., ticket status, ownership)" -ForegroundColor White
Write-Host "4. Route Access: Should be enforced by router guards" -ForegroundColor White

Write-Host "`nRecommendations:" -ForegroundColor Cyan
Write-Host "1. Ensure all UI elements check permissions before rendering" -ForegroundColor White
Write-Host "2. Implement consistent permission checking across components" -ForegroundColor White
Write-Host "3. Add permission-based CSS classes for better UX" -ForegroundColor White
Write-Host "4. Consider caching permission checks for performance" -ForegroundColor White

Write-Host "`n=== FRONTEND UI TEST COMPLETED ===" -ForegroundColor Green