# Test Log Recording Fixes
# Verify that user information is now properly captured in logs

Write-Host "=== Testing Log Recording Fixes ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080/api/v1"

# Step 1: Restart backend to apply middleware changes
Write-Host "1. Please restart the backend server to apply middleware changes" -ForegroundColor Yellow
Write-Host "   Press Enter when backend is restarted..." -ForegroundColor Gray
Read-Host

# Step 2: Login and make authenticated requests
Write-Host "2. Login and make authenticated requests..." -ForegroundColor Yellow
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    }
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
    
    if ($loginResponse.success) {
        $token = $loginResponse.data.token
        $headers = @{ "Authorization" = "Bearer $token" }
        $currentUser = $loginResponse.data.user
        Write-Host "Success: Login completed" -ForegroundColor Green
        Write-Host "  User ID: $($currentUser.id)" -ForegroundColor Gray
        Write-Host "  Username: $($currentUser.username)" -ForegroundColor Gray
    } else {
        throw "Login failed: $($loginResponse.message)"
    }
} catch {
    Write-Host "Error: Login failed - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Make several authenticated API calls
Write-Host "`n3. Making authenticated API calls..." -ForegroundColor Yellow
try {
    Write-Host "  Making profile request..." -ForegroundColor Gray
    $profileResponse = Invoke-RestMethod -Uri "$baseUrl/users/profile" -Method Get -Headers $headers
    
    Write-Host "  Making admin users request..." -ForegroundColor Gray
    try {
        $usersResponse = Invoke-RestMethod -Uri "$baseUrl/admin/users" -Method Get -Headers $headers
    } catch {
        Write-Host "    Admin users request failed (may be expected)" -ForegroundColor Gray
    }
    
    Write-Host "  Making logs request..." -ForegroundColor Gray
    $logsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=5" -Method Get -Headers $headers
    
    Write-Host "  Waiting for logs to be written..." -ForegroundColor Gray
    Start-Sleep -Seconds 2
    
} catch {
    Write-Host "Warning: Some API calls failed (this may be expected)" -ForegroundColor Yellow
}

# Step 4: Check if user information is now captured
Write-Host "`n4. Checking if user information is now captured..." -ForegroundColor Yellow
try {
    $recentLogsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=10" -Method Get -Headers $headers
    
    if ($recentLogsResponse.success -and $recentLogsResponse.data.logs) {
        $logs = $recentLogsResponse.data.logs
        Write-Host "Success: Retrieved $($logs.Count) recent logs" -ForegroundColor Green
        
        # Analyze user information capture
        $logsWithUserId = @()
        $logsWithUserObject = @()
        $logsWithIP = @()
        $logsWithUserAgent = @()
        
        foreach ($log in $logs) {
            if ($log.user_id -ne $null -and $log.user_id -ne 0) {
                $logsWithUserId += $log
            }
            if ($log.user -ne $null -and $log.user.id -ne 0) {
                $logsWithUserObject += $log
            }
            if ($log.ip_address -ne $null -and $log.ip_address -ne "") {
                $logsWithIP += $log
            }
            if ($log.user_agent -ne $null -and $log.user_agent -ne "") {
                $logsWithUserAgent += $log
            }
        }
        
        Write-Host "`nUser Information Analysis:" -ForegroundColor Cyan
        Write-Host "  Total logs: $($logs.Count)" -ForegroundColor Gray
        Write-Host "  Logs with User ID: $($logsWithUserId.Count)" -ForegroundColor $(if ($logsWithUserId.Count -gt 0) { "Green" } else { "Red" })
        Write-Host "  Logs with User Object: $($logsWithUserObject.Count)" -ForegroundColor $(if ($logsWithUserObject.Count -gt 0) { "Green" } else { "Red" })
        Write-Host "  Logs with IP Address: $($logsWithIP.Count)" -ForegroundColor $(if ($logsWithIP.Count -gt 0) { "Green" } else { "Red" })
        Write-Host "  Logs with User Agent: $($logsWithUserAgent.Count)" -ForegroundColor $(if ($logsWithUserAgent.Count -gt 0) { "Green" } else { "Red" })
        
        # Show sample logs with user information
        if ($logsWithUserId.Count -gt 0) {
            Write-Host "`nSample log with user information:" -ForegroundColor Cyan
            $sampleLog = $logsWithUserId[0]
            Write-Host "  ID: $($sampleLog.id)" -ForegroundColor Gray
            Write-Host "  Level: $($sampleLog.level)" -ForegroundColor Gray
            Write-Host "  Category: $($sampleLog.category)" -ForegroundColor Gray
            Write-Host "  Message: $($sampleLog.message)" -ForegroundColor Gray
            Write-Host "  User ID: $($sampleLog.user_id)" -ForegroundColor Green
            Write-Host "  IP Address: $($sampleLog.ip_address)" -ForegroundColor Green
            Write-Host "  User Agent: $($sampleLog.user_agent)" -ForegroundColor Green
            Write-Host "  Created At: $($sampleLog.created_at)" -ForegroundColor Gray
        }
        
    } else {
        Write-Host "Warning: No log data retrieved" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: Failed to check user information - $($_.Exception.Message)" -ForegroundColor Red
}

# Step 5: Test IP address filtering
Write-Host "`n5. Testing IP address filtering..." -ForegroundColor Yellow
try {
    if ($logsWithIP.Count -gt 0) {
        $testIP = $logsWithIP[0].ip_address
        Write-Host "  Testing filter by IP: $testIP" -ForegroundColor Gray
        
        $filterResponse = Invoke-RestMethod -Uri "$baseUrl/logs?ip_address=$testIP&page=1&page_size=5" -Method Get -Headers $headers
        
        if ($filterResponse.success) {
            $filteredLogs = $filterResponse.data.logs
            Write-Host "  Success: Found $($filteredLogs.Count) logs with IP $testIP" -ForegroundColor Green
            
            # Verify all logs have the correct IP
            $correctFilter = $true
            foreach ($log in $filteredLogs) {
                if ($log.ip_address -ne $testIP) {
                    $correctFilter = $false
                    break
                }
            }
            
            if ($correctFilter) {
                Write-Host "  ✓ IP filtering works correctly" -ForegroundColor Green
            } else {
                Write-Host "  ✗ IP filtering has issues" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  No logs with IP addresses to test filtering" -ForegroundColor Gray
    }
} catch {
    Write-Host "Error: IP filtering test failed - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Fix Results Summary ===" -ForegroundColor Green

if ($logsWithUserId.Count -gt 0) {
    Write-Host "✅ SUCCESS: User information is now being captured!" -ForegroundColor Green
    Write-Host "   - User IDs are present in logs" -ForegroundColor Gray
    Write-Host "   - Authentication middleware is working" -ForegroundColor Gray
} else {
    Write-Host "❌ ISSUE: User information still not captured" -ForegroundColor Red
    Write-Host "   - Check if OptionalAuthMiddleware is working" -ForegroundColor Yellow
    Write-Host "   - Verify middleware execution order" -ForegroundColor Yellow
}

Write-Host "`nFrontend Improvements:" -ForegroundColor Cyan
Write-Host "✅ Replaced user_id filter with ip_address filter" -ForegroundColor Green
Write-Host "✅ Updated search parameters and validation" -ForegroundColor Green
Write-Host "✅ Improved filter descriptions and messages" -ForegroundColor Green

Write-Host "`nNext Steps:" -ForegroundColor Cyan
if ($logsWithUserId.Count -eq 0) {
    Write-Host "1. Debug OptionalAuthMiddleware implementation" -ForegroundColor Gray
    Write-Host "2. Check JWT token validation in middleware" -ForegroundColor Gray
    Write-Host "3. Verify user context is properly set" -ForegroundColor Gray
} else {
    Write-Host "1. Test frontend IP address filtering functionality" -ForegroundColor Gray
    Write-Host "2. Verify user display improvements work correctly" -ForegroundColor Gray
    Write-Host "3. Test log deletion with proper user context" -ForegroundColor Gray
}

Write-Host "`n=== Log Recording Fixes Test Complete ===" -ForegroundColor Green