#!/usr/bin/env pwsh

Write-Host "=== Creating Ticket Permissions ===" -ForegroundColor Green

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

    # Define ticket permissions
    $permissions = @(
        @{
            name = "ticket:view"
            display_name = "View Tickets"
            description = "View ticket information"
            resource = "ticket"
            action = "view"
            scope = "all"
        },
        @{
            name = "ticket:create"
            display_name = "Create Tickets"
            description = "Create new tickets"
            resource = "ticket"
            action = "create"
            scope = "all"
        },
        @{
            name = "ticket:edit"
            display_name = "Edit Tickets"
            description = "Edit ticket information"
            resource = "ticket"
            action = "edit"
            scope = "all"
        },
        @{
            name = "ticket:delete"
            display_name = "Delete Tickets"
            description = "Delete tickets"
            resource = "ticket"
            action = "delete"
            scope = "all"
        },
        @{
            name = "ticket:assign"
            display_name = "Assign Tickets"
            description = "Assign tickets to users"
            resource = "ticket"
            action = "assign"
            scope = "all"
        }
    )

    # Create permissions
    Write-Host "`nCreating permissions..." -ForegroundColor Yellow
    foreach ($permission in $permissions) {
        try {
            $permissionJson = $permission | ConvertTo-Json
            $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions" -Method POST -Body $permissionJson -Headers $headers
            Write-Host "✓ Created permission: $($permission.name)" -ForegroundColor Green
        } catch {
            if ($_.Exception.Response.StatusCode -eq 409) {
                Write-Host "- Permission already exists: $($permission.name)" -ForegroundColor Yellow
            } else {
                Write-Host "✗ Failed to create permission: $($permission.name) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    # Get admin user ID
    Write-Host "`nGetting admin user..." -ForegroundColor Yellow
    $usersResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users" -Method GET -Headers $headers
    $adminUser = $usersResponse.data | Where-Object { $_.username -eq "admin" }
    
    if (-not $adminUser) {
        Write-Host "Admin user not found" -ForegroundColor Red
        exit 1
    }

    Write-Host "Found admin user (ID: $($adminUser.id))" -ForegroundColor Green

    # Get all permissions
    $allPermissionsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions" -Method GET -Headers $headers
    $ticketPermissions = $allPermissionsResponse.data | Where-Object { $_.name -like "ticket:*" }

    # Assign permissions to admin user
    Write-Host "`nAssigning permissions to admin..." -ForegroundColor Yellow
    foreach ($permission in $ticketPermissions) {
        try {
            $assignData = @{
                user_id = $adminUser.id
                permission_id = $permission.id
            } | ConvertTo-Json

            $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/$($adminUser.id)/permissions" -Method POST -Body $assignData -Headers $headers
            Write-Host "✓ Assigned permission: $($permission.name)" -ForegroundColor Green
        } catch {
            if ($_.Exception.Response.StatusCode -eq 409) {
                Write-Host "- Permission already assigned: $($permission.name)" -ForegroundColor Yellow
            } else {
                Write-Host "✗ Failed to assign permission: $($permission.name) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    Write-Host "`n=== Success ===" -ForegroundColor Green
    Write-Host "Ticket permissions created and assigned to admin user" -ForegroundColor White
    Write-Host "Please refresh the frontend page to see the changes" -ForegroundColor Yellow

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}