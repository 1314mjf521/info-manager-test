# Detailed API Permission Test
# This script tests specific API endpoints with actual data

Write-Host "=== DETAILED API PERMISSION TEST ===" -ForegroundColor Green

# Test users
$testUsers = @(
    @{Username = "admin"; Password = "admin123"},
    @{Username = "tiker"; Password = "QAZwe@01010"}
)

foreach ($testUser in $testUsers) {
    Write-Host "`n=== TESTING USER: $($testUser.Username) ===" -ForegroundColor Yellow
    
    # Login
    $loginData = @{
        username = $testUser.Username
        password = $testUser.Password
    } | ConvertTo-Json
    
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    $userId = $loginResponse.data.user.id
    $headers = @{"Authorization" = "Bearer $token"; "Content-Type" = "application/json"}
    
    Write-Host "Login: SUCCESS (ID: $userId)" -ForegroundColor Green
    
    # Get existing tickets for testing
    $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $headers
    $existingTickets = $ticketsResponse.data.items
    Write-Host "Available tickets: $($existingTickets.Count)" -ForegroundColor Cyan
    
    # Create a test ticket
    Write-Host "`n--- CREATE TICKET TEST ---" -ForegroundColor Magenta
    try {
        $createData = @{
            title = "API Test Ticket - $($testUser.Username)"
            description = "This ticket is created for API permission testing"
            type = "support"
            priority = "normal"
        } | ConvertTo-Json
        
        $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method POST -Headers $headers -Body $createData
        Write-Host "Create ticket: SUCCESS (ID: $($createResponse.data.id))" -ForegroundColor Green
        $testTicketId = $createResponse.data.id
    } catch {
        Write-Host "Create ticket: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test UPDATE ticket (only if we have a test ticket)
    if ($testTicketId) {
        Write-Host "`n--- UPDATE TICKET TEST ---" -ForegroundColor Magenta
        try {
            $updateData = @{
                title = "Updated API Test Ticket - $($testUser.Username)"
                description = "This ticket has been updated during API testing"
                type = "support"
                priority = "high"
            } | ConvertTo-Json
            
            $updateResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$testTicketId" -Method PUT -Headers $headers -Body $updateData
            Write-Host "Update ticket: SUCCESS" -ForegroundColor Green
        } catch {
            if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
                Write-Host "Update ticket: FORBIDDEN (as expected for non-own tickets)" -ForegroundColor Yellow
            } else {
                Write-Host "Update ticket: FAILED - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # Test ASSIGN ticket
        Write-Host "`n--- ASSIGN TICKET TEST ---" -ForegroundColor Magenta
        try {
            $assignData = @{
                assignee_id = 1
                comment = "API test assignment"
                auto_accept = $false
            } | ConvertTo-Json
            
            $assignResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$testTicketId/assign" -Method POST -Headers $headers -Body $assignData
            Write-Host "Assign ticket: SUCCESS" -ForegroundColor Green
        } catch {
            if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
                Write-Host "Assign ticket: FORBIDDEN" -ForegroundColor Red
            } else {
                Write-Host "Assign ticket: FAILED - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # Test ticket status operations (if user has permissions)
        if ($testUser.Username -eq "admin") {
            Write-Host "`n--- TICKET STATUS OPERATIONS TEST ---" -ForegroundColor Magenta
            
            # Test Accept
            try {
                $acceptData = @{comment = "API test accept"} | ConvertTo-Json
                $acceptResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$testTicketId/accept" -Method POST -Headers $headers -Body $acceptData
                Write-Host "Accept ticket: SUCCESS" -ForegroundColor Green
            } catch {
                Write-Host "Accept ticket: FAILED - $($_.Exception.Message)" -ForegroundColor Red
            }
            
            # Test Reject
            try {
                $rejectData = @{comment = "API test reject"} | ConvertTo-Json
                $rejectResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$testTicketId/reject" -Method POST -Headers $headers -Body $rejectData
                Write-Host "Reject ticket: SUCCESS" -ForegroundColor Green
            } catch {
                Write-Host "Reject ticket: FAILED - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # Test DELETE ticket (at the end)
        Write-Host "`n--- DELETE TICKET TEST ---" -ForegroundColor Magenta
        try {
            $deleteResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$testTicketId" -Method DELETE -Headers $headers
            Write-Host "Delete ticket: SUCCESS" -ForegroundColor Green
        } catch {
            if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
                Write-Host "Delete ticket: FORBIDDEN (as expected for non-own tickets)" -ForegroundColor Yellow
            } else {
                Write-Host "Delete ticket: FAILED - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    # Test EXPORT tickets
    Write-Host "`n--- EXPORT TICKETS TEST ---" -ForegroundColor Magenta
    try {
        $exportResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/export" -Method GET -Headers $headers
        Write-Host "Export tickets: SUCCESS" -ForegroundColor Green
    } catch {
        if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
            Write-Host "Export tickets: FORBIDDEN (as expected for tiker user)" -ForegroundColor Yellow
        } else {
            Write-Host "Export tickets: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Test IMPORT tickets
    Write-Host "`n--- IMPORT TICKETS TEST ---" -ForegroundColor Magenta
    try {
        # Create a temporary CSV file for testing
        $csvContent = @"
title,type,priority,description
Test Import Ticket,support,normal,This is a test import ticket
Another Test Ticket,bug,high,Another test ticket for import
"@
        $tempCsvFile = [System.IO.Path]::GetTempFileName() + ".csv"
        $csvContent | Out-File -FilePath $tempCsvFile -Encoding UTF8
        
        # Use curl to upload the file (PowerShell Invoke-RestMethod doesn't handle multipart well)
        $curlCommand = "curl -X POST -H `"Authorization: Bearer $token`" -F `"file=@$tempCsvFile`" http://localhost:8080/api/v1/tickets/import"
        $importResult = Invoke-Expression $curlCommand
        
        # Clean up temp file
        Remove-Item $tempCsvFile -ErrorAction SilentlyContinue
        
        Write-Host "Import tickets: SUCCESS" -ForegroundColor Green
    } catch {
        if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
            Write-Host "Import tickets: FORBIDDEN (as expected for tiker user)" -ForegroundColor Yellow
        } else {
            Write-Host "Import tickets: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Test FILE operations
    Write-Host "`n--- FILE OPERATIONS TEST ---" -ForegroundColor Magenta
    
    # Test file list
    try {
        $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files" -Method GET -Headers $headers
        Write-Host "Get files: SUCCESS ($($filesResponse.data.items.Count) files)" -ForegroundColor Green
    } catch {
        Write-Host "Get files: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test ADMIN operations
    Write-Host "`n--- ADMIN OPERATIONS TEST ---" -ForegroundColor Magenta
    
    # Test user management
    try {
        $usersResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/users" -Method GET -Headers $headers
        Write-Host "Get users: SUCCESS ($($usersResponse.data.Count) users)" -ForegroundColor Green
    } catch {
        if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
            Write-Host "Get users: FORBIDDEN (as expected for tiker user)" -ForegroundColor Yellow
        } else {
            Write-Host "Get users: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Test role management
    try {
        $rolesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles" -Method GET -Headers $headers
        Write-Host "Get roles: SUCCESS ($($rolesResponse.data.Count) roles)" -ForegroundColor Green
    } catch {
        if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
            Write-Host "Get roles: FORBIDDEN (as expected for tiker user)" -ForegroundColor Yellow
        } else {
            Write-Host "Get roles: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Test permission management
    try {
        $permissionsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions" -Method GET -Headers $headers
        Write-Host "Get permissions: SUCCESS ($($permissionsResponse.data.Count) permissions)" -ForegroundColor Green
    } catch {
        if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
            Write-Host "Get permissions: FORBIDDEN (as expected for tiker user)" -ForegroundColor Yellow
        } else {
            Write-Host "Get permissions: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n=== DETAILED API TEST COMPLETED ===" -ForegroundColor Green