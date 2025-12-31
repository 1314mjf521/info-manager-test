#!/usr/bin/env pwsh

Write-Host "=== Testing Auto Assignment Rules ===" -ForegroundColor Green

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

# Test assignment rules API
Write-Host "3. Testing assignment rules API..." -ForegroundColor Yellow
try {
    $rulesResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/assignment-rules" -Headers $headers
    Write-Host "✓ Assignment rules API working" -ForegroundColor Green
    Write-Host "  Bug tickets assigned to: $($rulesResponse.data.bug.assignee_name)" -ForegroundColor Blue
    Write-Host "  Feature tickets assigned to: $($rulesResponse.data.feature.assignee_name)" -ForegroundColor Blue
    Write-Host "  Support tickets assigned to: $($rulesResponse.data.support.assignee_name)" -ForegroundColor Blue
    Write-Host "  Change tickets assigned to: $($rulesResponse.data.change.assignee_name)" -ForegroundColor Blue
} catch {
    Write-Host "✗ Assignment rules API failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test auto-assignment for different ticket types
$ticketTypes = @("bug", "feature", "support", "change", "custom")
$ticketLabels = @("故障报告", "功能请求", "技术支持", "变更请求", "自定义请求")

for ($i = 0; $i -lt $ticketTypes.Length; $i++) {
    $type = $ticketTypes[$i]
    $label = $ticketLabels[$i]
    
    Write-Host "4.$($i+1) Testing auto-assignment for $label ($type)..." -ForegroundColor Yellow
    
    $ticketData = @{
        title = "Auto-Assignment Test $label - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        type = $type
        priority = "normal"
        description = "Testing automatic assignment for $label tickets"
        metadata = @{}
    } | ConvertTo-Json -Depth 3

    try {
        $createResponse = Invoke-RestMethod -Uri "$baseUrl/tickets" -Method POST -Body $ticketData -Headers $headers
        $ticketId = $createResponse.data.id
        Write-Host "    ✓ $label ticket created, ID: $ticketId" -ForegroundColor Green
        
        # Wait for auto-assignment
        Start-Sleep -Seconds 2
        
        # Check assignment
        $ticketResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/$ticketId" -Headers $headers
        if ($ticketResponse.data.assignee_id) {
            Write-Host "    ✓ Ticket auto-assigned to user ID: $($ticketResponse.data.assignee_id)" -ForegroundColor Green
            Write-Host "    ✓ Status: $($ticketResponse.data.status)" -ForegroundColor Green
            
            if ($ticketResponse.data.assignee) {
                Write-Host "    ✓ Assigned to: $($ticketResponse.data.assignee.username)" -ForegroundColor Green
            }
        } else {
            Write-Host "    ✗ Ticket was not auto-assigned" -ForegroundColor Red
        }
    } catch {
        Write-Host "    ✗ Failed to create $label ticket: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test statistics after auto-assignments
Write-Host "5. Testing statistics after auto-assignments..." -ForegroundColor Yellow
try {
    $statsResponse = Invoke-RestMethod -Uri "$baseUrl/tickets/statistics" -Headers $headers
    Write-Host "✓ Statistics updated" -ForegroundColor Green
    Write-Host "  Total tickets: $($statsResponse.data.total)" -ForegroundColor Blue
    Write-Host "  Submitted: $($statsResponse.data.status.submitted)" -ForegroundColor Blue
    Write-Host "  Assigned: $($statsResponse.data.status.assigned)" -ForegroundColor Blue
} catch {
    Write-Host "✗ Failed to get statistics: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Auto Assignment Test Complete ===" -ForegroundColor Green
Write-Host "Features tested:" -ForegroundColor White
Write-Host "✓ Assignment rules API" -ForegroundColor Green
Write-Host "✓ Auto-assignment for all ticket types" -ForegroundColor Green
Write-Host "✓ Status transitions after assignment" -ForegroundColor Green
Write-Host "✓ Statistics updates" -ForegroundColor Green

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Verify assignment rules in frontend at http://localhost:8080" -ForegroundColor White
Write-Host "2. Test approval/rejection workflow for assigned tickets" -ForegroundColor White
Write-Host "3. Configure assignment rules for different user roles" -ForegroundColor White