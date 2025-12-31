#!/usr/bin/env pwsh

Write-Host "=== Verifying Ticket Permissions ===" -ForegroundColor Green

try {
    # Login as admin
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if (-not $loginResponse.data.token) {
        Write-Host "✗ Login failed" -ForegroundColor Red
        exit 1
    }

    $token = $loginResponse.data.token
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }

    Write-Host "✓ Login successful" -ForegroundColor Green

    # Check all permissions
    Write-Host "`nChecking system permissions..." -ForegroundColor Yellow
    $allPermissions = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions" -Method GET -Headers $headers
    $ticketPermissions = $allPermissions.data | Where-Object { $_.name -like "ticket:*" }

    if ($ticketPermissions.Count -gt 0) {
        Write-Host "✓ Found $($ticketPermissions.Count) ticket permissions:" -ForegroundColor Green
        $ticketPermissions | ForEach-Object {
            Write-Host "  - $($_.name): $($_.display_name)" -ForegroundColor White
        }
    } else {
        Write-Host "✗ No ticket permissions found" -ForegroundColor Red
    }

    # Check user permissions
    Write-Host "`nChecking admin user permissions..." -ForegroundColor Yellow
    $userProfile = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/profile" -Method GET -Headers $headers
    $userTicketPermissions = $userProfile.data.permissions | Where-Object { $_.name -like "ticket:*" }

    if ($userTicketPermissions.Count -gt 0) {
        Write-Host "✓ Admin has $($userTicketPermissions.Count) ticket permissions:" -ForegroundColor Green
        $userTicketPermissions | ForEach-Object {
            Write-Host "  - $($_.name): $($_.display_name)" -ForegroundColor White
        }
    } else {
        Write-Host "✗ Admin user has no ticket permissions" -ForegroundColor Red
    }

    # Test ticket API
    Write-Host "`nTesting ticket API..." -ForegroundColor Yellow
    try {
        $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $headers
        Write-Host "✓ Ticket API accessible" -ForegroundColor Green
    } catch {
        Write-Host "✗ Ticket API failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "`n=== Verification Complete ===" -ForegroundColor Green
    
    if ($userTicketPermissions.Count -gt 0) {
        Write-Host "✓ All checks passed! Ticket management should now work." -ForegroundColor Green
        Write-Host "Please refresh your browser to see the changes." -ForegroundColor Yellow
    } else {
        Write-Host "✗ Permissions not properly assigned. Please check the server logs." -ForegroundColor Red
    }

} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}