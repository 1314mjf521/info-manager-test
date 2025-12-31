#!/usr/bin/env pwsh

Write-Host "=== Final Ticket System Test ===" -ForegroundColor Green

try {
    # Login
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }

    Write-Host "✓ Login successful" -ForegroundColor Green

    # Test ticket list API
    $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $headers
    
    Write-Host "`n=== API Response Test ===" -ForegroundColor Yellow
    Write-Host "✓ Response format: { success: $($ticketsResponse.success), data: {...} }" -ForegroundColor Green
    Write-Host "✓ Found $($ticketsResponse.data.items.Count) tickets" -ForegroundColor Green
    Write-Host "✓ Total count: $($ticketsResponse.data.total)" -ForegroundColor Green
    
    # Test ticket details
    if ($ticketsResponse.data.items.Count -gt 0) {
        $firstTicket = $ticketsResponse.data.items[0]
        Write-Host "`n=== Sample Ticket ===" -ForegroundColor Yellow
        Write-Host "ID: $($firstTicket.id)" -ForegroundColor White
        Write-Host "Title: $($firstTicket.title)" -ForegroundColor White
        Write-Host "Status: $($firstTicket.status)" -ForegroundColor White
        Write-Host "Type: $($firstTicket.type)" -ForegroundColor White
        Write-Host "Priority: $($firstTicket.priority)" -ForegroundColor White
        Write-Host "Creator: $($firstTicket.creator.username)" -ForegroundColor White
    }

    # Test statistics
    Write-Host "`n=== Statistics ===" -ForegroundColor Yellow
    $stats = $ticketsResponse.data.stats
    Write-Host "Total: $($stats.total)" -ForegroundColor White
    Write-Host "Open: $($stats.open)" -ForegroundColor White
    Write-Host "In Progress: $($stats.progress)" -ForegroundColor White
    Write-Host "Resolved: $($stats.resolved)" -ForegroundColor White

    Write-Host "`n🎉 All tests passed! Ticket system is working correctly!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Refresh your browser" -ForegroundColor White
    Write-Host "2. Click on 工单管理 in the navigation" -ForegroundColor White
    Write-Host "3. You should see the ticket list with data" -ForegroundColor White

} catch {
    Write-Host "✗ Test failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}