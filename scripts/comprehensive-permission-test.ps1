# Comprehensive Permission Test for tiker_user
Write-Host "=== COMPREHENSIVE PERMISSION TEST ===" -ForegroundColor Green

# Login as tiker user
$loginData = @{
    username = "tiker"
    password = "QAZwe@01010"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
$token = $loginResponse.data.token
$userId = $loginResponse.data.user.id
$headers = @{"Authorization" = "Bearer $token"; "Content-Type" = "application/json"}

Write-Host "Logged in as tiker (ID: $userId)" -ForegroundColor Yellow
Write-Host "User permissions: $($loginResponse.data.user.permissions.Count)" -ForegroundColor Cyan

# List all permissions
Write-Host "`nUser Permissions:" -ForegroundColor Yellow
$loginResponse.data.user.permissions | Sort-Object name | ForEach-Object {
    Write-Host "  $($_.name) - $($_.display_name)"
}

# Test 1: Ticket Operations
Write-Host "`n=== TICKET OPERATIONS TEST ===" -ForegroundColor Magenta

# Get tickets
try {
    $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $headers
    Write-Host "Get tickets: SUCCESS ($($ticketsResponse.data.items.Count) tickets)" -ForegroundColor Green
    
    if ($ticketsResponse.data.items.Count -gt 0) {
        $testTicket = $ticketsResponse.data.items[0]
        $isOwnTicket = $testTicket.creator_id -eq $userId
        
        Write-Host "Test ticket: ID=$($testTicket.id), Own=$isOwnTicket, Status=$($testTicket.status)"
        
        # Test view ticket detail
        try {
            $detailResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$($testTicket.id)" -Method GET -Headers $headers
            Write-Host "View ticket detail: SUCCESS" -ForegroundColor Green
        } catch {
            Write-Host "View ticket detail: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        }
        
        # Test edit ticket (only if own ticket)
        if ($isOwnTicket) {
            try {
                $updateData = @{
                    title = $testTicket.title + " (test)"
                    description = $testTicket.description
                    type = $testTicket.type
                    priority = $testTicket.priority
                } | ConvertTo-Json
                
                $updateResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$($testTicket.id)" -Method PUT -Headers $headers -Body $updateData
                Write-Host "Edit own ticket: SUCCESS" -ForegroundColor Green
            } catch {
                Write-Host "Edit own ticket: FAILED - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # Test assign ticket
        try {
            $assignData = @{
                assignee_id = 1
                comment = "Test assignment"
                auto_accept = $false
            } | ConvertTo-Json
            
            $assignResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$($testTicket.id)/assign" -Method POST -Headers $headers -Body $assignData
            Write-Host "Assign ticket: SUCCESS" -ForegroundColor Green
        } catch {
            Write-Host "Assign ticket: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "Get tickets: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Create Ticket
Write-Host "`n=== CREATE TICKET TEST ===" -ForegroundColor Magenta
try {
    $createData = @{
        title = "Test ticket from permission test"
        description = "This is a test ticket created during permission testing"
        type = "support"
        priority = "normal"
    } | ConvertTo-Json
    
    $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method POST -Headers $headers -Body $createData
    Write-Host "Create ticket: SUCCESS (ID: $($createResponse.data.id))" -ForegroundColor Green
    $newTicketId = $createResponse.data.id
    
    # Test delete own ticket
    try {
        $deleteResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$newTicketId" -Method DELETE -Headers $headers
        Write-Host "Delete own ticket: SUCCESS" -ForegroundColor Green
    } catch {
        Write-Host "Delete own ticket: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Create ticket: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: File Operations
Write-Host "`n=== FILE OPERATIONS TEST ===" -ForegroundColor Magenta
try {
    $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files" -Method GET -Headers $headers
    Write-Host "Get files: SUCCESS ($($filesResponse.data.items.Count) files)" -ForegroundColor Green
} catch {
    Write-Host "Get files: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Forbidden Operations
Write-Host "`n=== FORBIDDEN OPERATIONS TEST ===" -ForegroundColor Magenta

# Test user management (should fail)
try {
    $usersResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/users" -Method GET -Headers $headers
    Write-Host "Access user management: UNEXPECTED SUCCESS (should be forbidden)" -ForegroundColor Red
} catch {
    if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
        Write-Host "Access user management: CORRECTLY FORBIDDEN" -ForegroundColor Green
    } else {
        Write-Host "Access user management: FAILED - $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Test role management (should fail)
try {
    $rolesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles" -Method GET -Headers $headers
    Write-Host "Access role management: UNEXPECTED SUCCESS (should be forbidden)" -ForegroundColor Red
} catch {
    if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
        Write-Host "Access role management: CORRECTLY FORBIDDEN" -ForegroundColor Green
    } else {
        Write-Host "Access role management: FAILED - $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "All tests completed. Check results above for any failures." -ForegroundColor White
Write-Host "Green = Success, Red = Failure, Yellow = Unexpected behavior" -ForegroundColor White