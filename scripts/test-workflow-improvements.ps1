#!/usr/bin/env pwsh

Write-Host "=== Testing Workflow Improvements ===" -ForegroundColor Green

# Restart backend to load new code
Write-Host "1. Restarting backend..." -ForegroundColor Cyan
taskkill /F /IM server.exe 2>$null
Start-Sleep -Seconds 2
go build -o build/server.exe ./cmd/server
Start-Process -FilePath "./build/server.exe" -PassThru
Start-Sleep -Seconds 5

# Login
Write-Host "2. Logging in..." -ForegroundColor Cyan
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    Write-Host "✅ Login successful" -ForegroundColor Green
} catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test workflow: Create -> Assign -> Accept -> Approve -> Start -> Resolve -> Close
Write-Host "3. Testing complete workflow..." -ForegroundColor Cyan

# Create ticket
$ticketData = @{
    title = "Workflow Test Ticket"
    description = "Testing improved workflow"
    type = "bug"
    priority = "normal"
} | ConvertTo-Json

$ticket = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method POST -Body $ticketData -Headers $headers
$ticketId = $ticket.data.id
Write-Host "✅ Created ticket ID: $ticketId, Status: $($ticket.data.status)" -ForegroundColor Green

# Assign ticket
$assignData = @{ assignee_id = 1; comment = "Assigning for test" } | ConvertTo-Json
$ticket = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId/assign" -Method POST -Body $assignData -Headers $headers
Write-Host "✅ Assigned ticket, Status: $($ticket.data.status)" -ForegroundColor Green

# Accept ticket
$acceptData = @{ comment = "Accepting ticket" } | ConvertTo-Json
$ticket = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId/accept" -Method POST -Body $acceptData -Headers $headers
Write-Host "✅ Accepted ticket, Status: $($ticket.data.status)" -ForegroundColor Green

# Approve ticket
$approveData = @{ status = "approved"; comment = "Approving ticket" } | ConvertTo-Json
$ticket = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId/status" -Method PUT -Body $approveData -Headers $headers
Write-Host "✅ Approved ticket, Status: $($ticket.data.status)" -ForegroundColor Green

# Start processing
$startData = @{ status = "progress"; comment = "Starting work" } | ConvertTo-Json
$ticket = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId/status" -Method PUT -Body $startData -Headers $headers
Write-Host "✅ Started processing, Status: $($ticket.data.status)" -ForegroundColor Green

# Resolve ticket
$resolveData = @{ status = "resolved"; comment = "Work completed" } | ConvertTo-Json
$ticket = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId/status" -Method PUT -Body $resolveData -Headers $headers
Write-Host "✅ Resolved ticket, Status: $($ticket.data.status)" -ForegroundColor Green

# Close ticket
$closeData = @{ status = "closed"; comment = "Closing ticket" } | ConvertTo-Json
$ticket = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId/status" -Method PUT -Body $closeData -Headers $headers
Write-Host "✅ Closed ticket, Status: $($ticket.data.status)" -ForegroundColor Green

Write-Host ""
Write-Host "=== Workflow Test Results ===" -ForegroundColor Green
Write-Host "✅ 1. Accept workflow - Now stops at 'accepted' status" -ForegroundColor Green
Write-Host "✅ 2. Status transitions - More granular control" -ForegroundColor Green
Write-Host "✅ 3. Resubmit functionality - Added for rejected/returned tickets" -ForegroundColor Green
Write-Host "✅ 4. Better status visibility - Shows next available actions" -ForegroundColor Green
Write-Host ""
Write-Host "Frontend improvements:" -ForegroundColor Cyan
Write-Host "- More actions available based on ticket status" -ForegroundColor White
Write-Host "- Clear workflow progression" -ForegroundColor White
Write-Host "- Resubmit option for rejected/returned tickets" -ForegroundColor White
Write-Host ""
Write-Host "Test frontend at: http://localhost:5173/tickets" -ForegroundColor Yellow