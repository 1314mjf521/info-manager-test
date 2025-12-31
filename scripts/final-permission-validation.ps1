# Final Permission System Validation
Write-Host "=== FINAL PERMISSION SYSTEM VALIDATION ===" -ForegroundColor Green

# Test both admin and tiker users
$testUsers = @(
    @{Username = "admin"; Password = "admin123"; ExpectedPermissions = "ALL"},
    @{Username = "tiker"; Password = "QAZwe@01010"; ExpectedPermissions = 12}
)

foreach ($user in $testUsers) {
    Write-Host "`n=== TESTING USER: $($user.Username) ===" -ForegroundColor Yellow
    
    # Login
    $loginData = @{
        username = $user.Username
        password = $user.Password
    } | ConvertTo-Json
    
    try {
        $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        $token = $loginResponse.data.token
        $userId = $loginResponse.data.user.id
        $headers = @{"Authorization" = "Bearer $token"; "Content-Type" = "application/json"}
        
        Write-Host "Login: SUCCESS (ID: $userId)" -ForegroundColor Green
        Write-Host "Permissions: $($loginResponse.data.user.permissions.Count)" -ForegroundColor Cyan
        
        # Test core operations
        $testResults = @{}
        
        # Test 1: Ticket List
        try {
            $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $headers
            $testResults["TicketList"] = "SUCCESS ($($ticketsResponse.data.items.Count) tickets)"
        } catch {
            $testResults["TicketList"] = "FAILED - $($_.Exception.Message)"
        }
        
        # Test 2: Create Ticket
        try {
            $createData = @{
                title = "Validation test ticket"
                description = "Test ticket for validation"
                type = "support"
                priority = "normal"
            } | ConvertTo-Json
            
            $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method POST -Headers $headers -Body $createData
            $testResults["CreateTicket"] = "SUCCESS (ID: $($createResponse.data.id))"
            $testTicketId = $createResponse.data.id
        } catch {
            $testResults["CreateTicket"] = "FAILED - $($_.Exception.Message)"
        }
        
        # Test 3: Assign Ticket (if user has permission)
        if ($loginResponse.data.user.permissions | Where-Object { $_.name -eq "ticket:assign" }) {
            try {
                $assignData = @{
                    assignee_id = 1
                    comment = "Validation test assignment"
                    auto_accept = $false
                } | ConvertTo-Json
                
                $assignResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$testTicketId/assign" -Method POST -Headers $headers -Body $assignData
                $testResults["AssignTicket"] = "SUCCESS"
            } catch {
                $testResults["AssignTicket"] = "FAILED - $($_.Exception.Message)"
            }
        } else {
            $testResults["AssignTicket"] = "SKIPPED (no permission)"
        }
        
        # Test 4: File Access
        try {
            $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files" -Method GET -Headers $headers
            $testResults["FileAccess"] = "SUCCESS ($($filesResponse.data.items.Count) files)"
        } catch {
            $testResults["FileAccess"] = "FAILED - $($_.Exception.Message)"
        }
        
        # Test 5: Admin Operations (should fail for tiker)
        try {
            $usersResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/users" -Method GET -Headers $headers
            if ($user.Username -eq "admin") {
                $testResults["AdminAccess"] = "SUCCESS (as expected for admin)"
            } else {
                $testResults["AdminAccess"] = "UNEXPECTED SUCCESS (should be forbidden)"
            }
        } catch {
            if ($user.Username -eq "admin") {
                $testResults["AdminAccess"] = "FAILED (unexpected for admin)"
            } else {
                $testResults["AdminAccess"] = "CORRECTLY FORBIDDEN"
            }
        }
        
        # Clean up test ticket
        if ($testTicketId) {
            try {
                $deleteResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$testTicketId" -Method DELETE -Headers $headers
                $testResults["CleanupTicket"] = "SUCCESS"
            } catch {
                $testResults["CleanupTicket"] = "FAILED - $($_.Exception.Message)"
            }
        }
        
        # Display results
        Write-Host "`nTest Results:" -ForegroundColor Cyan
        foreach ($test in $testResults.Keys) {
            $result = $testResults[$test]
            $color = if ($result.StartsWith("SUCCESS") -or $result.StartsWith("CORRECTLY")) { "Green" } 
                    elseif ($result.StartsWith("FAILED") -or $result.StartsWith("UNEXPECTED")) { "Red" }
                    else { "Yellow" }
            Write-Host "  $test`: $result" -ForegroundColor $color
        }
        
    } catch {
        Write-Host "Login FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== VALIDATION SUMMARY ===" -ForegroundColor Green
Write-Host "Permission system validation completed." -ForegroundColor White
Write-Host "Check results above for any issues." -ForegroundColor White
Write-Host "`nExpected behavior:" -ForegroundColor Cyan
Write-Host "- Admin: Should have access to all operations" -ForegroundColor White
Write-Host "- Tiker: Should have limited access, no admin operations" -ForegroundColor White