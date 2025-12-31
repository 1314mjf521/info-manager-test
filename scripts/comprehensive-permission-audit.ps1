# Comprehensive Permission System Audit
# This script checks all permissions, routes, and UI elements for consistency

Write-Host "=== COMPREHENSIVE PERMISSION SYSTEM AUDIT ===" -ForegroundColor Cyan
Write-Host "This script will audit the entire permission system for consistency" -ForegroundColor White
Write-Host ""

# Test users
$testUsers = @(
    @{ Username = "admin"; Password = "admin123"; ExpectedRole = "admin" },
    @{ Username = "tiker"; Password = "QAZwe@01010"; ExpectedRole = "tiker_user" }
)

$allResults = @()

foreach ($user in $testUsers) {
    Write-Host "=== TESTING USER: $($user.Username) ===" -ForegroundColor Yellow
    
    try {
        # Login user
        $loginData = @{
            username = $user.Username
            password = $user.Password
        } | ConvertTo-Json
        
        $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        $token = $loginResponse.data.token
        $userId = $loginResponse.data.user.id
        $userRoles = $loginResponse.data.user.roles | ForEach-Object { $_.name }
        $userPermissions = $loginResponse.data.user.permissions | ForEach-Object { $_.name }
        
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        
        Write-Host "✓ Login successful - ID: $userId, Roles: $($userRoles -join ', ')" -ForegroundColor Green
        Write-Host "  Permissions count: $($userPermissions.Count)" -ForegroundColor Cyan
        
        $userResult = @{
            Username = $user.Username
            UserId = $userId
            Roles = $userRoles
            Permissions = $userPermissions
            Tests = @{}
        }
        
        # Test 1: System Permissions
        Write-Host "`n1. SYSTEM PERMISSIONS TEST:" -ForegroundColor Magenta
        $systemPermissions = @(
            "system:admin", "system:read", "system:write"
        )
        
        foreach ($perm in $systemPermissions) {
            $hasPermission = $userPermissions -contains $perm
            $status = if ($hasPermission) { "✓" } else { "✗" }
            $color = if ($hasPermission) { "Green" } else { "Red" }
            Write-Host "   $status $perm" -ForegroundColor $color
        }
        
        # Test 2: User Management Permissions
        Write-Host "`n2. USER MANAGEMENT PERMISSIONS:" -ForegroundColor Magenta
        $userMgmtPermissions = @(
            "users:read", "users:create", "users:update", "users:delete"
        )
        
        foreach ($perm in $userMgmtPermissions) {
            $hasPermission = $userPermissions -contains $perm
            $status = if ($hasPermission) { "✓" } else { "✗" }
            $color = if ($hasPermission) { "Green" } else { "Red" }
            Write-Host "   $status $perm" -ForegroundColor $color
        }
        
        # Test 3: Ticket Permissions
        Write-Host "`n3. TICKET PERMISSIONS:" -ForegroundColor Magenta
        $ticketPermissions = @(
            "ticket:read", "ticket:read_own", "ticket:create", "ticket:update", "ticket:update_own",
            "ticket:delete", "ticket:delete_own", "ticket:assign", "ticket:accept", "ticket:reject",
            "ticket:return", "ticket:approve", "ticket:statistics", "ticket:comment_read", "ticket:comment_write",
            "ticket:attachment_upload", "ticket:attachment_delete"
        )
        
        $ticketResults = @{}
        foreach ($perm in $ticketPermissions) {
            $hasPermission = $userPermissions -contains $perm
            $ticketResults[$perm] = $hasPermission
            $status = if ($hasPermission) { "✓" } else { "✗" }
            $color = if ($hasPermission) { "Green" } else { "Red" }
            Write-Host "   $status $perm" -ForegroundColor $color
        }
        $userResult.Tests["TicketPermissions"] = $ticketResults
        
        # Test 4: File Permissions
        Write-Host "`n4. FILE PERMISSIONS:" -ForegroundColor Magenta
        $filePermissions = @(
            "files:read", "files:upload", "files:download", "files:delete"
        )
        
        foreach ($perm in $filePermissions) {
            $hasPermission = $userPermissions -contains $perm
            $status = if ($hasPermission) { "✓" } else { "✗" }
            $color = if ($hasPermission) { "Green" } else { "Red" }
            Write-Host "   $status $perm" -ForegroundColor $color
        }
        
        # Test 5: API Access Tests
        Write-Host "`n5. API ACCESS TESTS:" -ForegroundColor Magenta
        
        # Test ticket list access
        try {
            $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $headers
            Write-Host "   ✓ Ticket list access: SUCCESS ($($ticketsResponse.data.items.Count) tickets)" -ForegroundColor Green
            $userResult.Tests["TicketListAccess"] = $true
            
            # Test ticket detail access for each visible ticket
            $ticketAccessResults = @{}
            foreach ($ticket in $ticketsResponse.data.items) {
                try {
                    $ticketDetail = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$($ticket.id)" -Method GET -Headers $headers
                    Write-Host "   ✓ Ticket $($ticket.id) detail access: SUCCESS" -ForegroundColor Green
                    $ticketAccessResults[$ticket.id] = $true
                } catch {
                    Write-Host "   ✗ Ticket $($ticket.id) detail access: FAILED - $($_.Exception.Message)" -ForegroundColor Red
                    $ticketAccessResults[$ticket.id] = $false
                }
            }
            $userResult.Tests["TicketDetailAccess"] = $ticketAccessResults
            
        } catch {
            Write-Host "   ✗ Ticket list access: FAILED - $($_.Exception.Message)" -ForegroundColor Red
            $userResult.Tests["TicketListAccess"] = $false
        }
        
        # Test user management access
        try {
            $usersResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/users" -Method GET -Headers $headers
            Write-Host "   ✓ User management access: SUCCESS" -ForegroundColor Green
            $userResult.Tests["UserMgmtAccess"] = $true
        } catch {
            Write-Host "   ✗ User management access: FAILED - $($_.Exception.Message)" -ForegroundColor Red
            $userResult.Tests["UserMgmtAccess"] = $false
        }
        
        # Test role management access
        try {
            $rolesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles" -Method GET -Headers $headers
            Write-Host "   ✓ Role management access: SUCCESS" -ForegroundColor Green
            $userResult.Tests["RoleMgmtAccess"] = $true
        } catch {
            Write-Host "   ✗ Role management access: FAILED - $($_.Exception.Message)" -ForegroundColor Red
            $userResult.Tests["RoleMgmtAccess"] = $false
        }
        
        # Test permission management access
        try {
            $permissionsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions" -Method GET -Headers $headers
            Write-Host "   ✓ Permission management access: SUCCESS" -ForegroundColor Green
            $userResult.Tests["PermissionMgmtAccess"] = $true
        } catch {
            Write-Host "   ✗ Permission management access: FAILED - $($_.Exception.Message)" -ForegroundColor Red
            $userResult.Tests["PermissionMgmtAccess"] = $false
        }
        
        # Test 6: Route Permission Analysis
        Write-Host "`n6. ROUTE PERMISSION ANALYSIS:" -ForegroundColor Magenta
        $routePermissions = @{
            "/dashboard" = $null  # No permission required
            "/tickets" = "ticket:read_own"
            "/tickets/:id" = "ticket:read_own"
            "/tickets/:id/edit" = "ticket:update_own"
            "/tickets/create" = "ticket:create"
            "/users" = "users:read"
            "/roles" = "system:admin"
            "/permissions" = "system:admin"
            "/files" = "files:read"
        }
        
        $routeResults = @{}
        foreach ($route in $routePermissions.Keys) {
            $requiredPerm = $routePermissions[$route]
            if ($requiredPerm -eq $null) {
                Write-Host "   ✓ $route (no permission required)" -ForegroundColor Green
                $routeResults[$route] = $true
            } else {
                $hasAccess = $userPermissions -contains $requiredPerm
                $status = if ($hasAccess) { "✓" } else { "✗" }
                $color = if ($hasAccess) { "Green" } else { "Red" }
                Write-Host "   $status $route (requires: $requiredPerm)" -ForegroundColor $color
                $routeResults[$route] = $hasAccess
            }
        }
        $userResult.Tests["RouteAccess"] = $routeResults
        
        # Test 7: UI Button Logic Test (for ticket operations)
        Write-Host "`n7. UI BUTTON LOGIC TEST:" -ForegroundColor Magenta
        if ($userResult.Tests["TicketListAccess"]) {
            $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $headers
            
            foreach ($ticket in $ticketsResponse.data.items) {
                $isOwnTicket = $ticket.creator_id -eq $userId
                $isAssignedTicket = $ticket.assignee_id -eq $userId
                
                Write-Host "   Ticket $($ticket.id) (Own: $isOwnTicket, Assigned: $isAssignedTicket):"
                
                # Edit button logic
                $shouldShowEdit = ($userPermissions -contains "ticket:update") -or (($userPermissions -contains "ticket:update_own") -and $isOwnTicket)
                $editStatus = if ($shouldShowEdit) { "✓ SHOW" } else { "✗ HIDE" }
                Write-Host "     Edit button: $editStatus" -ForegroundColor $(if ($shouldShowEdit) { "Green" } else { "Gray" })
                
                # Delete button logic
                $shouldShowDelete = ($userPermissions -contains "ticket:delete") -or (($userPermissions -contains "ticket:delete_own") -and $isOwnTicket)
                $deleteStatus = if ($shouldShowDelete) { "✓ SHOW" } else { "✗ HIDE" }
                Write-Host "     Delete button: $deleteStatus" -ForegroundColor $(if ($shouldShowDelete) { "Green" } else { "Gray" })
                
                # Assign button logic
                $shouldShowAssign = ($userPermissions -contains "ticket:assign") -and (@("submitted", "assigned") -contains $ticket.status)
                $assignStatus = if ($shouldShowAssign) { "✓ SHOW" } else { "✗ HIDE" }
                Write-Host "     Assign button: $assignStatus" -ForegroundColor $(if ($shouldShowAssign) { "Green" } else { "Gray" })
                
                # Accept/Reject buttons (only for assigned tickets)
                if ($ticket.status -eq "assigned" -and $isAssignedTicket) {
                    $shouldShowAccept = $userPermissions -contains "ticket:accept"
                    $shouldShowReject = $userPermissions -contains "ticket:reject"
                    
                    $acceptStatus = if ($shouldShowAccept) { "✓ SHOW" } else { "✗ HIDE" }
                    $rejectStatus = if ($shouldShowReject) { "✓ SHOW" } else { "✗ HIDE" }
                    
                    Write-Host "     Accept button: $acceptStatus" -ForegroundColor $(if ($shouldShowAccept) { "Green" } else { "Gray" })
                    Write-Host "     Reject button: $rejectStatus" -ForegroundColor $(if ($shouldShowReject) { "Green" } else { "Gray" })
                }
            }
        }
        
        $allResults += $userResult
        
    } catch {
        Write-Host "✗ Failed to test user $($user.Username): $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Generate Summary Report
Write-Host "=== AUDIT SUMMARY REPORT ===" -ForegroundColor Cyan

foreach ($result in $allResults) {
    Write-Host "`nUser: $($result.Username) (ID: $($result.UserId))" -ForegroundColor Yellow
    Write-Host "Roles: $($result.Roles -join ', ')"
    Write-Host "Total Permissions: $($result.Permissions.Count)"
    
    # Key permission summary
    $keyPermissions = @("ticket:read_own", "ticket:create", "ticket:update_own", "ticket:delete_own", "system:admin")
    Write-Host "Key Permissions:"
    foreach ($perm in $keyPermissions) {
        $has = $result.Permissions -contains $perm
        $status = if ($has) { "✓" } else { "✗" }
        $color = if ($has) { "Green" } else { "Red" }
        Write-Host "  $status $perm" -ForegroundColor $color
    }
    
    # Access summary
    Write-Host "API Access:"
    $accessTests = @("TicketListAccess", "UserMgmtAccess", "RoleMgmtAccess", "PermissionMgmtAccess")
    foreach ($test in $accessTests) {
        if ($result.Tests.ContainsKey($test)) {
            $has = $result.Tests[$test]
            $status = if ($has) { "✓" } else { "✗" }
            $color = if ($has) { "Green" } else { "Red" }
            Write-Host "  $status $test" -ForegroundColor $color
        }
    }
}

Write-Host "`n=== RECOMMENDATIONS ===" -ForegroundColor Cyan
Write-Host "1. Ensure all route permissions match user permissions exactly" -ForegroundColor White
Write-Host "2. Verify UI button logic matches backend permission checks" -ForegroundColor White
Write-Host "3. Test all CRUD operations for each user role" -ForegroundColor White
Write-Host "4. Check that permission names are consistent (underscore vs colon)" -ForegroundColor White

Write-Host "`n=== AUDIT COMPLETED ===" -ForegroundColor Green