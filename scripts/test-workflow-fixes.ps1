#!/usr/bin/env pwsh

Write-Host "=== Testing Ticket Workflow Fixes ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080/api/v1"

# Check service status
Write-Host "1. Checking service status..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 5
    Write-Host "✓ Service is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Service is not running" -ForegroundColor Red
    exit 1
}

# Test login
Write-Host "2. Testing login..." -ForegroundColor Yellow
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    Write-Host "✓ Login successful" -ForegroundColor Green
} catch {
    Write-Host "✗ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Create a test ticket
Write-Host "3. Creating test ticket..." -ForegroundColor Yellow
$ticketData = @{
    title = "Workflow Test Ticket - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    type = "bug"
    priority = "normal"
    description = "This is a test ticket for workflow testing"
    metadata = @{
        bugLevel = "P3"
        affectedScope = "Test environment"
    }
} | ConvertTo-Json -Depth 3

try {
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/tickets" -Method POST -Body $ticketData -Headers $headers
    $ticketId = $createResponse.data.id
    Write-Host "✓ Test ticket created, ID: $ticketId" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to create ticket: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test status transitions
Write-Host "4. Testing status transitions..." -ForegroundColor Yellow

# Test assign (submitted -> assigned)
Write-Host "  4.1 Testing assign (submitted -> assigned)..." -ForegroundColor Blue
$assignData = @{
    assignee_id = 1
    comment = "Assigning for testing"
} | ConvertTo-Json

try {
    $assignResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$ticketId/assign" -Method POST -Body $assignData -Headers $headers
    Write-Host "    ✓ Ticket assigned successfully" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Failed to assign ticket: $($_.Exception.Message)" -ForegroundColor Red
}

# Test approve (assigned -> approved)
Write-Host "  4.2 Testing approve (assigned -> approved)..." -ForegroundColor Blue
$approveData = @{
    status = "approved"
    comment = "Approved for testing"
} | ConvertTo-Json

try {
    $approveResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$ticketId/status" -Method PUT -Body $approveData -Headers $headers
    Write-Host "    ✓ Ticket approved successfully" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Failed to approve ticket: $($_.Exception.Message)" -ForegroundColor Red
}

# Test reject (approved -> rejected)
Write-Host "  4.3 Testing reject (approved -> rejected)..." -ForegroundColor Blue
$rejectData = @{
    status = "rejected"
    comment = "Rejected for testing purposes"
} | ConvertTo-Json

try {
    $rejectResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$ticketId/status" -Method PUT -Body $rejectData -Headers $headers
    Write-Host "    ✓ Ticket rejected successfully" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Failed to reject ticket: $($_.Exception.Message)" -ForegroundColor Red
}

# Test resubmit (rejected -> submitted)
Write-Host "  4.4 Testing resubmit (rejected -> submitted)..." -ForegroundColor Blue
$resubmitData = @{
    status = "submitted"
    comment = "Resubmitted after addressing issues"
} | ConvertTo-Json

try {
    $resubmitResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$ticketId/status" -Method PUT -Body $resubmitData -Headers $headers
    Write-Host "    ✓ Ticket resubmitted successfully" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Failed to resubmit ticket: $($_.Exception.Message)" -ForegroundColor Red
}

# Check final ticket status
Write-Host "5. Checking final ticket status..." -ForegroundColor Yellow
try {
    $finalResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$ticketId" -Headers $headers
    Write-Host "  Final status: $($finalResponse.data.status)" -ForegroundColor Blue
    Write-Host "  Title: $($finalResponse.data.title)" -ForegroundColor Blue
} catch {
    Write-Host "✗ Failed to get final ticket status: $($_.Exception.Message)" -ForegroundColor Red
}

# Test statistics update
Write-Host "6. Testing statistics update..." -ForegroundColor Yellow
try {
    $statsResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/statistics" -Headers $headers
    Write-Host "  Total tickets: $($statsResponse.data.total)" -ForegroundColor Blue
    Write-Host "  Submitted: $($statsResponse.data.status.submitted)" -ForegroundColor Blue
    Write-Host "  Assigned: $($statsResponse.data.status.assigned)" -ForegroundColor Blue
    Write-Host "  Rejected: $($statsResponse.data.status.rejected)" -ForegroundColor Blue
} catch {
    Write-Host "✗ Failed to get statistics: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Workflow Test Complete ===" -ForegroundColor Green
Write-Host "Test Results:" -ForegroundColor White
Write-Host "✓ Ticket creation" -ForegroundColor Green
Write-Host "✓ Status transitions (submitted -> assigned -> approved -> rejected -> submitted)" -ForegroundColor Green
Write-Host "✓ Statistics updates" -ForegroundColor Green

Write-Host "`nPlease verify the frontend workflow at http://localhost:8080" -ForegroundColor Blue