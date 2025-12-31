# Test ticket system fixes
Write-Host "=== Testing Ticket System Fixes ===" -ForegroundColor Green

# Login tiker user
$loginData = @{
    username = "tiker"
    password = "QAZwe@01010"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $tikerToken = $loginResponse.data.token
    $tikerHeaders = @{
        "Authorization" = "Bearer $tikerToken"
        "Content-Type" = "application/json"
    }
    
    Write-Host "`n1. Testing ticket list API:" -ForegroundColor Yellow
    $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $tikerHeaders
    Write-Host "   Visible tickets: $($ticketsResponse.data.items.Count)"
    
    $ticketsResponse.data.items | ForEach-Object {
        $creatorName = if ($_.creator) { $_.creator.username } else { "N/A" }
        $assigneeName = if ($_.assignee) { $_.assignee.username } else { "N/A" }
        Write-Host "   - ID: $($_.id), Title: $($_.title), Creator: $creatorName, Assignee: $assigneeName"
    }
    
    Write-Host "`n2. Testing ticket detail access:" -ForegroundColor Yellow
    $ticketsResponse.data.items | ForEach-Object {
        try {
            $ticketDetail = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$($_.id)" -Method GET -Headers $tikerHeaders
            Write-Host "   ✓ Can access ticket $($_.id): $($ticketDetail.data.title)" -ForegroundColor Green
        } catch {
            Write-Host "   ✗ Cannot access ticket $($_.id): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "`n3. Testing data structure:" -ForegroundColor Yellow
    $firstTicket = $ticketsResponse.data.items[0]
    Write-Host "   First ticket data:"
    Write-Host "     ID: $($firstTicket.id)"
    Write-Host "     Title: $($firstTicket.title)"
    Write-Host "     Creator ID: $($firstTicket.creator_id)"
    Write-Host "     Creator Username: $($firstTicket.creator.username)"
    Write-Host "     Assignee ID: $($firstTicket.assignee_id)"
    Write-Host "     Assignee Username: $($firstTicket.assignee.username)"
    Write-Host "     Status: $($firstTicket.status)"
    
    Write-Host "`n=== All tests completed ===" -ForegroundColor Green
    
} catch {
    Write-Host "Test failed: $($_.Exception.Message)" -ForegroundColor Red
}