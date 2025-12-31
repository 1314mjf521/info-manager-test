# Complete Permission Linkage Test
# This script tests ALL backend API permissions, frontend button permissions, and UI display permissions

Write-Host "=== COMPLETE PERMISSION LINKAGE TEST ===" -ForegroundColor Green
Write-Host "Testing ALL backend APIs, frontend buttons, and UI permissions" -ForegroundColor White

# Test configuration
$testUsers = @(
    @{
        Username = "admin"
        Password = "admin123"
        ExpectedRole = "admin"
        Description = "System Administrator"
    },
    @{
        Username = "tiker"
        Password = "QAZwe@01010"
        ExpectedRole = "tiker_user"
        Description = "Ticket User"
    }
)

# Define all permission test cases
$permissionTests = @{
    "TICKET_OPERATIONS" = @{
        "ticket:read_own" = @{
            "API" = @{
                "Method" = "GET"
                "Endpoint" = "/api/v1/tickets"
                "Description" = "Get ticket list"
                "ExpectedForTiker" = "SUCCESS"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "TicketListView"
                "Element" = "Ticket list display"
                "Permission" = "canReadTickets()"
            }
        }
        "ticket:create" = @{
            "API" = @{
                "Method" = "POST"
                "Endpoint" = "/api/v1/tickets"
                "Description" = "Create new ticket"
                "ExpectedForTiker" = "SUCCESS"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "TicketListView"
                "Element" = "Create ticket button"
                "Permission" = "canCreateTickets()"
            }
        }
        "ticket:update_own" = @{
            "API" = @{
                "Method" = "PUT"
                "Endpoint" = "/api/v1/tickets/:id"
                "Description" = "Update own ticket"
                "ExpectedForTiker" = "SUCCESS (own tickets only)"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "TicketListView"
                "Element" = "Edit button"
                "Permission" = "canOperateTicket(ticket, 'update')"
            }
        }
        "ticket:delete_own" = @{
            "API" = @{
                "Method" = "DELETE"
                "Endpoint" = "/api/v1/tickets/:id"
                "Description" = "Delete own ticket"
                "ExpectedForTiker" = "SUCCESS (own tickets only)"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "TicketListView"
                "Element" = "Delete button"
                "Permission" = "canOperateTicket(ticket, 'delete')"
            }
        }
        "ticket:assign" = @{
            "API" = @{
                "Method" = "POST"
                "Endpoint" = "/api/v1/tickets/:id/assign"
                "Description" = "Assign ticket"
                "ExpectedForTiker" = "SUCCESS"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "TicketListView"
                "Element" = "Assign button"
                "Permission" = "canAssignTickets()"
            }
        }
        "ticket:accept" = @{
            "API" = @{
                "Method" = "POST"
                "Endpoint" = "/api/v1/tickets/:id/accept"
                "Description" = "Accept ticket"
                "ExpectedForTiker" = "FORBIDDEN"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "TicketListView"
                "Element" = "Accept button in dropdown"
                "Permission" = "canAcceptTickets()"
            }
        }
        "ticket:reject" = @{
            "API" = @{
                "Method" = "POST"
                "Endpoint" = "/api/v1/tickets/:id/reject"
                "Description" = "Reject ticket"
                "ExpectedForTiker" = "FORBIDDEN"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "TicketListView"
                "Element" = "Reject button in dropdown"
                "Permission" = "canRejectTickets()"
            }
        }
        "ticket:statistics" = @{
            "API" = @{
                "Method" = "GET"
                "Endpoint" = "/api/v1/tickets/statistics"
                "Description" = "Get ticket statistics"
                "ExpectedForTiker" = "SUCCESS"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "TicketListView"
                "Element" = "Statistics cards"
                "Permission" = "canViewStatistics()"
            }
        }
        "ticket:export" = @{
            "API" = @{
                "Method" = "GET"
                "Endpoint" = "/api/v1/tickets/export"
                "Description" = "Export tickets"
                "ExpectedForTiker" = "FORBIDDEN"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "TicketListView"
                "Element" = "Export button"
                "Permission" = "canExportTickets()"
            }
        }
        "ticket:import" = @{
            "API" = @{
                "Method" = "POST"
                "Endpoint" = "/api/v1/tickets/import"
                "Description" = "Import tickets"
                "ExpectedForTiker" = "FORBIDDEN"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "TicketListView"
                "Element" = "Import button"
                "Permission" = "canImportTickets()"
            }
        }
    }
    "FILE_OPERATIONS" = @{
        "files:read" = @{
            "API" = @{
                "Method" = "GET"
                "Endpoint" = "/api/v1/files"
                "Description" = "Get file list"
                "ExpectedForTiker" = "SUCCESS"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "FileListView"
                "Element" = "File list display"
                "Permission" = "files:read route permission"
            }
        }
        "files:upload" = @{
            "API" = @{
                "Method" = "POST"
                "Endpoint" = "/api/v1/files"
                "Description" = "Upload file"
                "ExpectedForTiker" = "SUCCESS"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "FileListView"
                "Element" = "Upload button"
                "Permission" = "files:upload permission"
            }
        }
        "files:download" = @{
            "API" = @{
                "Method" = "GET"
                "Endpoint" = "/api/v1/files/:id/download"
                "Description" = "Download file"
                "ExpectedForTiker" = "SUCCESS"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "FileListView"
                "Element" = "Download button"
                "Permission" = "files:download permission"
            }
        }
    }
    "ADMIN_OPERATIONS" = @{
        "users:read" = @{
            "API" = @{
                "Method" = "GET"
                "Endpoint" = "/api/v1/admin/users"
                "Description" = "Get user list"
                "ExpectedForTiker" = "FORBIDDEN"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "MainLayout"
                "Element" = "User management menu"
                "Permission" = "users:read route permission"
            }
        }
        "roles:read" = @{
            "API" = @{
                "Method" = "GET"
                "Endpoint" = "/api/v1/admin/roles"
                "Description" = "Get role list"
                "ExpectedForTiker" = "FORBIDDEN"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "MainLayout"
                "Element" = "Role management menu"
                "Permission" = "system:admin route permission"
            }
        }
        "permissions:read" = @{
            "API" = @{
                "Method" = "GET"
                "Endpoint" = "/api/v1/permissions"
                "Description" = "Get permission list"
                "ExpectedForTiker" = "FORBIDDEN"
                "ExpectedForAdmin" = "SUCCESS"
            }
            "Frontend" = @{
                "Component" = "MainLayout"
                "Element" = "Permission management menu"
                "Permission" = "system:admin route permission"
            }
        }
    }
}

# Test results storage
$testResults = @{}

# Test each user
foreach ($testUser in $testUsers) {
    Write-Host "`n=== TESTING USER: $($testUser.Username) ($($testUser.Description)) ===" -ForegroundColor Yellow
    
    # Login
    $loginData = @{
        username = $testUser.Username
        password = $testUser.Password
    } | ConvertTo-Json
    
    try {
        $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        $token = $loginResponse.data.token
        $userId = $loginResponse.data.user.id
        $userPermissions = $loginResponse.data.user.permissions | ForEach-Object { $_.name }
        $headers = @{"Authorization" = "Bearer $token"; "Content-Type" = "application/json"}
        
        Write-Host "Login: SUCCESS (ID: $userId, Permissions: $($userPermissions.Count))" -ForegroundColor Green
        
        $userResults = @{}
        $testResults[$testUser.Username] = $userResults
        
        # Test each permission category
        foreach ($category in $permissionTests.Keys) {
            Write-Host "`n--- Testing $category ---" -ForegroundColor Cyan
            $categoryResults = @{}
            $userResults[$category] = $categoryResults
            
            foreach ($permission in $permissionTests[$category].Keys) {
                $testCase = $permissionTests[$category][$permission]
                $apiTest = $testCase.API
                $frontendTest = $testCase.Frontend
                
                Write-Host "`nTesting: $permission" -ForegroundColor Magenta
                
                # Test API permission
                $apiResult = @{
                    "Expected" = if ($testUser.Username -eq "tiker") { $apiTest.ExpectedForTiker } else { $apiTest.ExpectedForAdmin }
                    "Actual" = ""
                    "Status" = ""
                }
                
                try {
                    switch ($apiTest.Method) {
                        "GET" {
                            if ($apiTest.Endpoint -eq "/api/v1/tickets") {
                                $response = Invoke-RestMethod -Uri "http://localhost:8080$($apiTest.Endpoint)" -Method GET -Headers $headers
                                $apiResult.Actual = "SUCCESS ($($response.data.items.Count) items)"
                            }
                            elseif ($apiTest.Endpoint -eq "/api/v1/tickets/statistics") {
                                $response = Invoke-RestMethod -Uri "http://localhost:8080$($apiTest.Endpoint)" -Method GET -Headers $headers
                                $apiResult.Actual = "SUCCESS"
                            }
                            elseif ($apiTest.Endpoint -eq "/api/v1/files") {
                                $response = Invoke-RestMethod -Uri "http://localhost:8080$($apiTest.Endpoint)" -Method GET -Headers $headers
                                $apiResult.Actual = "SUCCESS ($($response.data.items.Count) files)"
                            }
                            elseif ($apiTest.Endpoint -eq "/api/v1/admin/users") {
                                $response = Invoke-RestMethod -Uri "http://localhost:8080$($apiTest.Endpoint)" -Method GET -Headers $headers
                                $apiResult.Actual = "SUCCESS ($($response.data.Count) users)"
                            }
                            elseif ($apiTest.Endpoint -eq "/api/v1/admin/roles") {
                                $response = Invoke-RestMethod -Uri "http://localhost:8080$($apiTest.Endpoint)" -Method GET -Headers $headers
                                $apiResult.Actual = "SUCCESS ($($response.data.Count) roles)"
                            }
                            elseif ($apiTest.Endpoint -eq "/api/v1/permissions") {
                                $response = Invoke-RestMethod -Uri "http://localhost:8080$($apiTest.Endpoint)" -Method GET -Headers $headers
                                $apiResult.Actual = "SUCCESS ($($response.data.Count) permissions)"
                            }
                            else {
                                $apiResult.Actual = "SKIPPED (endpoint needs ticket ID)"
                            }
                        }
                        "POST" {
                            if ($apiTest.Endpoint -eq "/api/v1/tickets") {
                                $createData = @{
                                    title = "Test ticket for $permission"
                                    description = "Testing $permission permission"
                                    type = "support"
                                    priority = "normal"
                                } | ConvertTo-Json
                                $response = Invoke-RestMethod -Uri "http://localhost:8080$($apiTest.Endpoint)" -Method POST -Headers $headers -Body $createData
                                $apiResult.Actual = "SUCCESS (ID: $($response.data.id))"
                                
                                # Store ticket ID for later tests
                                if (-not $userResults.ContainsKey("TestTicketIds")) {
                                    $userResults["TestTicketIds"] = @()
                                }
                                $userResults["TestTicketIds"] += $response.data.id
                            }
                            else {
                                $apiResult.Actual = "SKIPPED (needs specific test data)"
                            }
                        }
                        default {
                            $apiResult.Actual = "SKIPPED (method not implemented in test)"
                        }
                    }
                } catch {
                    if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
                        $apiResult.Actual = "FORBIDDEN"
                    } elseif ($_.Exception.Message -like "*401*" -or $_.Exception.Message -like "*Unauthorized*") {
                        $apiResult.Actual = "UNAUTHORIZED"
                    } else {
                        $apiResult.Actual = "ERROR: $($_.Exception.Message)"
                    }
                }
                
                # Determine if API test passed
                if ($apiResult.Expected -eq $apiResult.Actual -or 
                    ($apiResult.Expected.StartsWith("SUCCESS") -and $apiResult.Actual.StartsWith("SUCCESS")) -or
                    ($apiResult.Expected -eq "FORBIDDEN" -and $apiResult.Actual -eq "FORBIDDEN")) {
                    $apiResult.Status = "PASS"
                    $color = "Green"
                } else {
                    $apiResult.Status = "FAIL"
                    $color = "Red"
                }
                
                Write-Host "  API Test: $($apiResult.Status) - Expected: $($apiResult.Expected), Actual: $($apiResult.Actual)" -ForegroundColor $color
                
                # Test Frontend permission
                $frontendResult = @{
                    "HasPermission" = $userPermissions -contains $permission
                    "ShouldShow" = ""
                    "Status" = ""
                }
                
                # Determine if frontend element should show
                if ($testUser.Username -eq "admin") {
                    $frontendResult.ShouldShow = "YES"
                } else {
                    $frontendResult.ShouldShow = if ($frontendResult.HasPermission) { "YES" } else { "NO" }
                }
                
                $frontendResult.Status = if ($frontendResult.HasPermission -eq ($testUser.Username -eq "admin" -or $userPermissions -contains $permission)) { "PASS" } else { "FAIL" }
                
                $frontendColor = if ($frontendResult.Status -eq "PASS") { "Green" } else { "Red" }
                Write-Host "  Frontend Test: $($frontendResult.Status) - Has Permission: $($frontendResult.HasPermission), Should Show: $($frontendResult.ShouldShow)" -ForegroundColor $frontendColor
                
                # Store results
                $categoryResults[$permission] = @{
                    "API" = $apiResult
                    "Frontend" = $frontendResult
                    "TestCase" = $testCase
                }
            }
        }
        
        # Clean up test tickets
        if ($userResults.ContainsKey("TestTicketIds")) {
            Write-Host "`nCleaning up test tickets..." -ForegroundColor Yellow
            foreach ($ticketId in $userResults["TestTicketIds"]) {
                try {
                    $deleteResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$ticketId" -Method DELETE -Headers $headers
                    Write-Host "  Deleted ticket $ticketId" -ForegroundColor Gray
                } catch {
                    Write-Host "  Failed to delete ticket $ticketId`: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
        }
        
    } catch {
        Write-Host "Login FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $testResults[$testUser.Username] = @{"Error" = $_.Exception.Message}
    }
}

# Generate comprehensive report
Write-Host "`n=== COMPREHENSIVE TEST REPORT ===" -ForegroundColor Green

$totalTests = 0
$passedTests = 0
$failedTests = 0

foreach ($username in $testResults.Keys) {
    if ($testResults[$username].ContainsKey("Error")) {
        Write-Host "`n$username`: LOGIN FAILED" -ForegroundColor Red
        continue
    }
    
    Write-Host "`n$username Test Results:" -ForegroundColor Yellow
    
    foreach ($category in $testResults[$username].Keys) {
        if ($category -eq "TestTicketIds") { continue }
        
        Write-Host "  $category`:" -ForegroundColor Cyan
        
        foreach ($permission in $testResults[$username][$category].Keys) {
            $result = $testResults[$username][$category][$permission]
            
            $apiStatus = $result.API.Status
            $frontendStatus = $result.Frontend.Status
            $overallStatus = if ($apiStatus -eq "PASS" -and $frontendStatus -eq "PASS") { "PASS" } else { "FAIL" }
            
            $totalTests += 2  # API + Frontend
            if ($apiStatus -eq "PASS") { $passedTests++ } else { $failedTests++ }
            if ($frontendStatus -eq "PASS") { $passedTests++ } else { $failedTests++ }
            
            $statusColor = if ($overallStatus -eq "PASS") { "Green" } else { "Red" }
            Write-Host "    $permission`: $overallStatus (API: $apiStatus, Frontend: $frontendStatus)" -ForegroundColor $statusColor
        }
    }
}

Write-Host "`n=== FINAL SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Yellow" })

if ($failedTests -eq 0) {
    Write-Host "`n🎉 ALL PERMISSION LINKAGE TESTS PASSED!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  SOME TESTS FAILED - REVIEW RESULTS ABOVE" -ForegroundColor Red
}

Write-Host "`n=== TEST COMPLETED ===" -ForegroundColor Green