# Complete Permission System Fix
# This script will systematically fix all permission issues

Write-Host "=== COMPLETE PERMISSION SYSTEM FIX ===" -ForegroundColor Green

# Step 1: Get current permission structure
Write-Host "`n1. Analyzing current permission structure..." -ForegroundColor Yellow

$adminHeaders = @{
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJ1c2VybmFtZSI6ImFkbWluIiwicm9sZXMiOlsiYWRtaW4iXSwiaXNzIjoiaW5mby1tYW5hZ2VtZW50LXN5c3RlbSIsInN1YiI6IjEiLCJleHAiOjE3NjY4MzI0MjYsIm5iZiI6MTc2Njc0NjAyNiwiaWF0IjoxNzY2NzQ2MDI2fQ.quE5hkIgg_2GdcImQD3cMbLMpUuic7AcwYLTYw_Bax8"
    "Content-Type" = "application/json"
}

try {
    $permissionsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions" -Method GET -Headers $adminHeaders
    $allPermissions = $permissionsResponse.data
    
    Write-Host "Total permissions in system: $($allPermissions.Count)"
    
    # Group by module
    $modules = $allPermissions | Group-Object resource | Sort-Object Name
    foreach ($module in $modules) {
        Write-Host "  $($module.Name): $($module.Count) permissions"
    }
    
} catch {
    Write-Host "Failed to get permissions: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Check tiker_user role permissions
Write-Host "`n2. Checking tiker_user role permissions..." -ForegroundColor Yellow

try {
    $roleResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles/4" -Method GET -Headers $adminHeaders
    $tikerRole = $roleResponse.data
    
    Write-Host "Role: $($tikerRole.name)"
    Write-Host "Current permissions: $($tikerRole.permissions.Count)"
    
    $currentPermissions = $tikerRole.permissions | ForEach-Object { $_.name }
    Write-Host "Permissions list:"
    $currentPermissions | Sort-Object | ForEach-Object {
        Write-Host "  $_"
    }
    
} catch {
    Write-Host "Failed to get role permissions: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Test permission functionality
Write-Host "`n3. Testing permission functionality..." -ForegroundColor Yellow

# Login as tiker user
$loginData = @{
    username = "tiker"
    password = "QAZwe@01010"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $tikerToken = $loginResponse.data.token
    $tikerUserId = $loginResponse.data.user.id
    $tikerHeaders = @{
        "Authorization" = "Bearer $tikerToken"
        "Content-Type" = "application/json"
    }
    
    Write-Host "Tiker user logged in successfully (ID: $tikerUserId)"
    
    # Test ticket operations
    Write-Host "`nTesting ticket operations:"
    
    # Get tickets
    try {
        $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $tikerHeaders
        Write-Host "  Get tickets: SUCCESS ($($ticketsResponse.data.items.Count) tickets)"
        
        # Test assign operation on first ticket
        if ($ticketsResponse.data.items.Count -gt 0) {
            $firstTicket = $ticketsResponse.data.items[0]
            Write-Host "  Testing assign on ticket $($firstTicket.id)..."
            
            # Try to assign ticket to admin (user ID 1)
            $assignData = @{
                assignee_id = 1
                comment = "Test assignment"
                auto_accept = $false
            } | ConvertTo-Json
            
            try {
                $assignResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$($firstTicket.id)/assign" -Method POST -Headers $tikerHeaders -Body $assignData
                Write-Host "    Assign ticket: SUCCESS" -ForegroundColor Green
            } catch {
                Write-Host "    Assign ticket: FAILED - $($_.Exception.Message)" -ForegroundColor Red
                
                # Check if it's a permission error
                if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
                    Write-Host "    This is a permission error - need to fix backend" -ForegroundColor Red
                }
            }
        }
        
    } catch {
        Write-Host "  Get tickets: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Failed to login as tiker: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== ANALYSIS COMPLETE ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Fix backend hasPermission function to include all tiker_user permissions" -ForegroundColor White
Write-Host "2. Fix frontend permission checker to match backend permissions" -ForegroundColor White
Write-Host "3. Ensure UI buttons match actual permissions" -ForegroundColor White
Write-Host "4. Test all CRUD operations for each permission" -ForegroundColor White