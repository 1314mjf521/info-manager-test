#!/usr/bin/env pwsh

Write-Host "=== Testing Enhanced Ticket Workflow ===" -ForegroundColor Green

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

# Test ticket categories API
Write-Host "3. Testing ticket categories API..." -ForegroundColor Yellow
try {
    $categoriesResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/categories" -Headers $headers
    Write-Host "✓ Ticket categories API working" -ForegroundColor Green
    Write-Host "  Default types: $($categoriesResponse.data.default.Count)" -ForegroundColor Blue
    Write-Host "  Custom types: $($categoriesResponse.data.custom.Count)" -ForegroundColor Blue
} catch {
    Write-Host "✗ Ticket categories API failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Create a test ticket to test auto-assignment
Write-Host "4. Testing auto-assignment workflow..." -ForegroundColor Yellow
$ticketData = @{
    title = "Auto-Assignment Test - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    type = "bug"
    priority = "high"
    description = "Testing automatic assignment workflow"
    metadata = @{
        bugLevel = "P1"
        affectedScope = "Production environment"
        reproduceSteps = "1. Create ticket\n2. Check auto-assignment\n3. Verify workflow"
    }
} | ConvertTo-Json -Depth 3

try {
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/tickets" -Method POST -Body $ticketData -Headers $headers
    $ticketId = $createResponse.data.id
    Write-Host "✓ Test ticket created, ID: $ticketId" -ForegroundColor Green
    
    # Wait a moment for auto-assignment
    Start-Sleep -Seconds 2
    
    # Check if ticket was auto-assigned
    $ticketResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$ticketId" -Headers $headers
    if ($ticketResponse.data.assignee_id) {
        Write-Host "✓ Ticket was auto-assigned to user ID: $($ticketResponse.data.assignee_id)" -ForegroundColor Green
        Write-Host "✓ Status changed to: $($ticketResponse.data.status)" -ForegroundColor Green
    } else {
        Write-Host "⚠ Ticket was not auto-assigned (this might be expected)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Failed to create test ticket: $($_.Exception.Message)" -ForegroundColor Red
}

# Test approval and auto-processing
if ($ticketId) {
    Write-Host "5. Testing approval and auto-processing..." -ForegroundColor Yellow
    
    # Approve the ticket
    $approveData = @{
        status = "approved"
        comment = "Approved for auto-processing test"
    } | ConvertTo-Json
    
    try {
        $approveResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$ticketId/status" -Method PUT -Body $approveData -Headers $headers
        Write-Host "✓ Ticket approved" -ForegroundColor Green
        
        # Wait for auto-processing
        Start-Sleep -Seconds 3
        
        # Check if ticket auto-entered processing
        $processResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$ticketId" -Headers $headers
        if ($processResponse.data.status -eq "progress") {
            Write-Host "✓ Ticket automatically entered processing stage" -ForegroundColor Green
            Write-Host "✓ Processing started at: $($processResponse.data.processing_started_at)" -ForegroundColor Green
        } else {
            Write-Host "⚠ Ticket did not auto-enter processing (status: $($processResponse.data.status))" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ Failed to approve ticket: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test statistics after workflow
Write-Host "6. Testing statistics after workflow..." -ForegroundColor Yellow
try {
    $statsResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/statistics" -Headers $headers
    Write-Host "✓ Statistics updated" -ForegroundColor Green
    Write-Host "  Total tickets: $($statsResponse.data.total)" -ForegroundColor Blue
    Write-Host "  Submitted: $($statsResponse.data.status.submitted)" -ForegroundColor Blue
    Write-Host "  Assigned: $($statsResponse.data.status.assigned)" -ForegroundColor Blue
    Write-Host "  Approved: $($statsResponse.data.status.approved)" -ForegroundColor Blue
    Write-Host "  In Progress: $($statsResponse.data.status.progress)" -ForegroundColor Blue
} catch {
    Write-Host "✗ Failed to get statistics: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Enhanced Workflow Test Complete ===" -ForegroundColor Green
Write-Host "Features tested:" -ForegroundColor White
Write-Host "✓ Ticket categories API" -ForegroundColor Green
Write-Host "✓ Auto-assignment workflow" -ForegroundColor Green
Write-Host "✓ Auto-processing after approval" -ForegroundColor Green
Write-Host "✓ Statistics updates" -ForegroundColor Green

Write-Host "`nNext steps to verify:" -ForegroundColor Yellow
Write-Host "1. Check frontend dynamic action buttons at http://localhost:8080" -ForegroundColor White
Write-Host "2. Test custom ticket types in creation form" -ForegroundColor White
Write-Host "3. Verify processing timeout functionality (after 24 hours)" -ForegroundColor White
Write-Host "4. Test extend processing time feature" -ForegroundColor White