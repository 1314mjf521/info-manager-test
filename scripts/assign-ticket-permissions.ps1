#!/usr/bin/env pwsh

Write-Host "=== Assigning Ticket Permissions to Admin ===" -ForegroundColor Green

try {
    # Login as admin
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if (-not $loginResponse.data.token) {
        Write-Host "Login failed" -ForegroundColor Red
        exit 1
    }

    $token = $loginResponse.data.token
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }

    Write-Host "Login successful" -ForegroundColor Green

    # Get admin user profile
    $userProfile = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/profile" -Method GET -Headers $headers
    $adminUserId = $userProfile.data.id
    Write-Host "Admin User ID: $adminUserId" -ForegroundColor Yellow

    # Get all permissions
    $allPermissions = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions" -Method GET -Headers $headers
    $ticketPermissions = $allPermissions.data | Where-Object { $_.name -like "ticket:*" }

    Write-Host "`nFound $($ticketPermissions.Count) ticket permissions:" -ForegroundColor Yellow
    $ticketPermissions | ForEach-Object {
        Write-Host "  - $($_.name): $($_.display_name)" -ForegroundColor White
    }

    # Get admin user's role
    $users = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users" -Method GET -Headers $headers
    $adminUser = $users.data | Where-Object { $_.id -eq $adminUserId }
    
    if ($adminUser.roles -and $adminUser.roles.Count -gt 0) {
        $adminRoleId = $adminUser.roles[0].id
        Write-Host "`nAdmin user has role ID: $adminRoleId" -ForegroundColor Yellow
        
        # Assign permissions to admin role
        Write-Host "`nAssigning ticket permissions to admin role..." -ForegroundColor Yellow
        
        $permissionIds = $ticketPermissions | ForEach-Object { $_.id }
        $assignData = @{
            permission_ids = $permissionIds
        } | ConvertTo-Json

        try {
            $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles/$adminRoleId/permissions" -Method PUT -Body $assignData -Headers $headers
            Write-Host "✓ Successfully assigned ticket permissions to admin role" -ForegroundColor Green
        } catch {
            Write-Host "✗ Failed to assign permissions to role: $($_.Exception.Message)" -ForegroundColor Red
            
            # Try individual permission assignment
            Write-Host "Trying individual permission assignment..." -ForegroundColor Yellow
            foreach ($permission in $ticketPermissions) {
                try {
                    $singleAssignData = @{
                        permission_id = $permission.id
                    } | ConvertTo-Json
                    
                    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles/$adminRoleId/permissions" -Method POST -Body $singleAssignData -Headers $headers
                    Write-Host "✓ Assigned permission: $($permission.name)" -ForegroundColor Green
                } catch {
                    Write-Host "✗ Failed to assign permission $($permission.name): $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "Admin user has no roles, cannot assign permissions" -ForegroundColor Red
    }

    Write-Host "`n=== Verification ===" -ForegroundColor Green
    
    # Verify permissions
    $userProfile = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/profile" -Method GET -Headers $headers
    $userTicketPermissions = $userProfile.data.permissions | Where-Object { $_.name -like "ticket:*" }

    if ($userTicketPermissions.Count -gt 0) {
        Write-Host "✓ Admin now has $($userTicketPermissions.Count) ticket permissions:" -ForegroundColor Green
        $userTicketPermissions | ForEach-Object {
            Write-Host "  - $($_.name): $($_.display_name)" -ForegroundColor White
        }
        Write-Host "`nPlease refresh the browser to see the changes!" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Admin still has no ticket permissions" -ForegroundColor Red
    }

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}