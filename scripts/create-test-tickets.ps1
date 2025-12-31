#!/usr/bin/env pwsh

Write-Host "=== Creating Test Tickets ===" -ForegroundColor Green

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

    # Create test tickets
    $testTickets = @(
        @{
            title = "Test Ticket 1"
            description = "This is a test ticket for bug fixing"
            type = "bug"
            priority = "high"
            status = "open"
        },
        @{
            title = "Test Ticket 2"
            description = "This is a test ticket for feature request"
            type = "feature"
            priority = "normal"
            status = "open"
        },
        @{
            title = "Test Ticket 3"
            description = "This is a test ticket for support"
            type = "support"
            priority = "low"
            status = "progress"
        }
    )

    Write-Host "`nCreating test tickets..." -ForegroundColor Yellow
    
    foreach ($ticket in $testTickets) {
        try {
            $ticketJson = $ticket | ConvertTo-Json
            $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method POST -Body $ticketJson -Headers $headers
            Write-Host "✓ Created ticket: $($ticket.title)" -ForegroundColor Green
        } catch {
            Write-Host "✗ Failed to create ticket: $($ticket.title)" -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Verify tickets were created
    Write-Host "`nVerifying tickets..." -ForegroundColor Yellow
    try {
        $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $headers
        Write-Host "✓ Found $($ticketsResponse.data.tickets.Count) tickets" -ForegroundColor Green
        
        if ($ticketsResponse.data.tickets.Count -gt 0) {
            Write-Host "Tickets:" -ForegroundColor White
            $ticketsResponse.data.tickets | ForEach-Object {
                Write-Host "  - ID: $($_.id), Title: $($_.title), Status: $($_.status)" -ForegroundColor White
            }
        }
    } catch {
        Write-Host "✗ Failed to get tickets: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "`n=== Test tickets created successfully ===" -ForegroundColor Green

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}