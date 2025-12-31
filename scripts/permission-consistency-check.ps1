# Permission Consistency Check
# This script checks for inconsistencies between different parts of the permission system

Write-Host "=== PERMISSION CONSISTENCY CHECK ===" -ForegroundColor Cyan

# Get all permissions from database
try {
    $adminHeaders = @{
        "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJ1c2VybmFtZSI6ImFkbWluIiwicm9sZXMiOlsiYWRtaW4iXSwiaXNzIjoiaW5mby1tYW5hZ2VtZW50LXN5c3RlbSIsInN1YiI6IjEiLCJleHAiOjE3NjY4MzI0MjYsIm5iZiI6MTc2Njc0NjAyNiwiaWF0IjoxNzY2NzQ2MDI2fQ.quE5hkIgg_2GdcImQD3cMbLMpUuic7AcwYLTYw_Bax8"
        "Content-Type" = "application/json"
    }
    
    $permissionsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions" -Method GET -Headers $adminHeaders
    $allPermissions = $permissionsResponse.data | ForEach-Object { $_.name }
    
    Write-Host "✓ Retrieved $($allPermissions.Count) permissions from database" -ForegroundColor Green
    
} catch {
    Write-Host "✗ Failed to retrieve permissions: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Define expected permissions by module
$expectedPermissions = @{
    "system" = @("system:admin", "system:read", "system:write")
    "users" = @("users:read", "users:create", "users:update", "users:delete")
    "roles" = @("roles:read", "roles:create", "roles:update", "roles:delete")
    "permissions" = @("permissions:read", "permissions:create", "permissions:update", "permissions:delete")
    "ticket" = @(
        "ticket:read", "ticket:read_own", "ticket:create", "ticket:update", "ticket:update_own",
        "ticket:delete", "ticket:delete_own", "ticket:assign", "ticket:accept", "ticket:reject",
        "ticket:return", "ticket:approve", "ticket:statistics", "ticket:comment_read", 
        "ticket:comment_write", "ticket:attachment_upload", "ticket:attachment_delete"
    )
    "records" = @("records:read", "records:create", "records:update", "records:delete")
    "record_types" = @("record_types:read", "record_types:create", "record_types:update", "record_types:delete")
    "files" = @("files:read", "files:upload", "files:download", "files:delete")
    "export" = @("export:records", "export:tickets", "export:users")
    "ai" = @("ai:features", "ai:chat", "ai:analysis")
}

# Check 1: Missing permissions
Write-Host "`n1. CHECKING FOR MISSING PERMISSIONS:" -ForegroundColor Yellow
$missingPermissions = @()
foreach ($module in $expectedPermissions.Keys) {
    foreach ($perm in $expectedPermissions[$module]) {
        if ($allPermissions -notcontains $perm) {
            Write-Host "   ✗ Missing: $perm" -ForegroundColor Red
            $missingPermissions += $perm
        }
    }
}

if ($missingPermissions.Count -eq 0) {
    Write-Host "   ✓ No missing permissions found" -ForegroundColor Green
} else {
    Write-Host "   Found $($missingPermissions.Count) missing permissions" -ForegroundColor Red
}

# Check 2: Extra permissions (not in expected list)
Write-Host "`n2. CHECKING FOR UNEXPECTED PERMISSIONS:" -ForegroundColor Yellow
$allExpectedPermissions = $expectedPermissions.Values | ForEach-Object { $_ } | ForEach-Object { $_ }
$extraPermissions = $allPermissions | Where-Object { $allExpectedPermissions -notcontains $_ }

if ($extraPermissions.Count -eq 0) {
    Write-Host "   ✓ No unexpected permissions found" -ForegroundColor Green
} else {
    Write-Host "   Found $($extraPermissions.Count) unexpected permissions:" -ForegroundColor Yellow
    foreach ($perm in $extraPermissions) {
        Write-Host "     - $perm" -ForegroundColor Cyan
    }
}

# Check 3: Permission naming consistency
Write-Host "`n3. CHECKING PERMISSION NAMING CONSISTENCY:" -ForegroundColor Yellow
$namingIssues = @()

foreach ($perm in $allPermissions) {
    # Check for mixed separators (should be consistent)
    if ($perm -match ":" -and $perm -match "_") {
        $parts = $perm -split ":"
        if ($parts.Count -gt 2 -and $parts[2] -match "_") {
            # This might be intentional (e.g., ticket:read_own)
            continue
        }
        $namingIssues += "Mixed separators in: $perm"
    }
    
    # Check for proper format (resource:action or resource:action:scope)
    if (-not ($perm -match "^[a-z_]+:[a-z_]+(:own|:all|:department)?$")) {
        $namingIssues += "Invalid format: $perm"
    }
}

if ($namingIssues.Count -eq 0) {
    Write-Host "   ✓ No naming consistency issues found" -ForegroundColor Green
} else {
    Write-Host "   Found $($namingIssues.Count) naming issues:" -ForegroundColor Red
    foreach ($issue in $namingIssues) {
        Write-Host "     - $issue" -ForegroundColor Red
    }
}

# Check 4: Route permission consistency
Write-Host "`n4. CHECKING ROUTE PERMISSION CONSISTENCY:" -ForegroundColor Yellow

# Define route permissions (what we expect vs what might be configured)
$routePermissionMap = @{
    "tickets" = "ticket:read_own"
    "tickets/:id" = "ticket:read_own"
    "tickets/:id/edit" = "ticket:update_own"
    "tickets/create" = "ticket:create"
    "users" = "users:read"
    "roles" = "system:admin"
    "permissions" = "system:admin"
    "files" = "files:read"
}

$routeIssues = @()
foreach ($route in $routePermissionMap.Keys) {
    $expectedPerm = $routePermissionMap[$route]
    if ($allPermissions -notcontains $expectedPerm) {
        $routeIssues += "Route '$route' requires '$expectedPerm' but permission doesn't exist"
    }
}

if ($routeIssues.Count -eq 0) {
    Write-Host "   ✓ All route permissions exist in database" -ForegroundColor Green
} else {
    Write-Host "   Found $($routeIssues.Count) route permission issues:" -ForegroundColor Red
    foreach ($issue in $routeIssues) {
        Write-Host "     - $issue" -ForegroundColor Red
    }
}

# Check 5: Role permission assignments
Write-Host "`n5. CHECKING ROLE PERMISSION ASSIGNMENTS:" -ForegroundColor Yellow

try {
    $rolesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles" -Method GET -Headers $adminHeaders
    $roles = $rolesResponse.data
    
    foreach ($role in $roles) {
        $roleDetailResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles/$($role.id)" -Method GET -Headers $adminHeaders
        $roleDetail = $roleDetailResponse.data
        
        Write-Host "   Role: $($roleDetail.name) ($($roleDetail.permissions.Count) permissions)"
        
        # Check for common permission patterns
        $rolePermissions = $roleDetail.permissions | ForEach-Object { $_.name }
        
        # For tiker_user role, check essential permissions
        if ($roleDetail.name -eq "tiker_user") {
            $essentialPerms = @("ticket:read_own", "ticket:create", "ticket:update_own", "ticket:delete_own")
            foreach ($perm in $essentialPerms) {
                $has = $rolePermissions -contains $perm
                $status = if ($has) { "✓" } else { "✗" }
                $color = if ($has) { "Green" } else { "Red" }
                Write-Host "     $status $perm" -ForegroundColor $color
            }
        }
        
        # Check for orphaned permissions (permissions that don't exist)
        foreach ($perm in $rolePermissions) {
            if ($allPermissions -notcontains $perm) {
                Write-Host "     ✗ Orphaned permission: $perm" -ForegroundColor Red
            }
        }
    }
    
} catch {
    Write-Host "   ✗ Failed to check role assignments: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n=== CONSISTENCY CHECK SUMMARY ===" -ForegroundColor Cyan
Write-Host "Missing permissions: $($missingPermissions.Count)" -ForegroundColor $(if ($missingPermissions.Count -eq 0) { "Green" } else { "Red" })
Write-Host "Extra permissions: $($extraPermissions.Count)" -ForegroundColor $(if ($extraPermissions.Count -eq 0) { "Green" } else { "Yellow" })
Write-Host "Naming issues: $($namingIssues.Count)" -ForegroundColor $(if ($namingIssues.Count -eq 0) { "Green" } else { "Red" })
Write-Host "Route issues: $($routeIssues.Count)" -ForegroundColor $(if ($routeIssues.Count -eq 0) { "Green" } else { "Red" })

$totalIssues = $missingPermissions.Count + $namingIssues.Count + $routeIssues.Count
if ($totalIssues -eq 0) {
    Write-Host "`n✓ PERMISSION SYSTEM IS CONSISTENT" -ForegroundColor Green
} else {
    Write-Host "`n✗ FOUND $totalIssues CONSISTENCY ISSUES" -ForegroundColor Red
}

Write-Host "`n=== CHECK COMPLETED ===" -ForegroundColor Cyan