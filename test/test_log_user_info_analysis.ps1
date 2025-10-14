# Test Log User Information Analysis
# Check if backend logs contain user information and analyze the data structure

Write-Host "=== Analyzing Log User Information ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080/api/v1"

# Step 1: Login
Write-Host "1. Login to get authentication token..." -ForegroundColor Yellow
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    }
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
    
    if ($loginResponse.success) {
        $token = $loginResponse.data.token
        $headers = @{ "Authorization" = "Bearer $token" }
        $currentUserId = $loginResponse.data.user.id
        $currentUsername = $loginResponse.data.user.username
        Write-Host "Success: Login completed" -ForegroundColor Green
        Write-Host "  Current User ID: $currentUserId" -ForegroundColor Gray
        Write-Host "  Current Username: $currentUsername" -ForegroundColor Gray
    } else {
        throw "Login failed: $($loginResponse.message)"
    }
} catch {
    Write-Host "Error: Login failed - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Get detailed log data
Write-Host "`n2. Analyzing log data structure..." -ForegroundColor Yellow
try {
    $logsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=20" -Method Get -Headers $headers
    
    if ($logsResponse.success -and $logsResponse.data.logs) {
        $logs = $logsResponse.data.logs
        $totalLogs = $logsResponse.data.total
        
        Write-Host "Success: Retrieved $($logs.Count) logs from total $totalLogs" -ForegroundColor Green
        
        # Analyze user information in logs
        $logsWithUserId = @()
        $logsWithUserObject = @()
        $logsWithoutUser = @()
        
        foreach ($log in $logs) {
            if ($log.user_id -ne $null -and $log.user_id -ne 0) {
                $logsWithUserId += $log
                if ($log.user -ne $null) {
                    $logsWithUserObject += $log
                }
            } else {
                $logsWithoutUser += $log
            }
        }
        
        Write-Host "`nUser Information Analysis:" -ForegroundColor Cyan
        Write-Host "  Total logs analyzed: $($logs.Count)" -ForegroundColor Gray
        Write-Host "  Logs with user_id: $($logsWithUserId.Count)" -ForegroundColor Gray
        Write-Host "  Logs with user object: $($logsWithUserObject.Count)" -ForegroundColor Gray
        Write-Host "  Logs without user info: $($logsWithoutUser.Count)" -ForegroundColor Gray
        
        # Show sample log structures
        if ($logsWithUserId.Count -gt 0) {
            Write-Host "`nSample log with user_id:" -ForegroundColor Cyan
            $sampleLog = $logsWithUserId[0]
            Write-Host "  ID: $($sampleLog.id)" -ForegroundColor Gray
            Write-Host "  Level: $($sampleLog.level)" -ForegroundColor Gray
            Write-Host "  Category: $($sampleLog.category)" -ForegroundColor Gray
            Write-Host "  Message: $($sampleLog.message)" -ForegroundColor Gray
            Write-Host "  User ID: $($sampleLog.user_id)" -ForegroundColor Gray
            if ($sampleLog.user) {
                Write-Host "  User Object: $($sampleLog.user | ConvertTo-Json -Compress)" -ForegroundColor Gray
            } else {
                Write-Host "  User Object: null" -ForegroundColor Gray
            }
            Write-Host "  IP Address: $($sampleLog.ip_address)" -ForegroundColor Gray
            Write-Host "  Created At: $($sampleLog.created_at)" -ForegroundColor Gray
        }
        
        if ($logsWithoutUser.Count -gt 0) {
            Write-Host "`nSample log without user info:" -ForegroundColor Cyan
            $sampleLog = $logsWithoutUser[0]
            Write-Host "  ID: $($sampleLog.id)" -ForegroundColor Gray
            Write-Host "  Level: $($sampleLog.level)" -ForegroundColor Gray
            Write-Host "  Category: $($sampleLog.category)" -ForegroundColor Gray
            Write-Host "  Message: $($sampleLog.message)" -ForegroundColor Gray
            Write-Host "  User ID: $($sampleLog.user_id)" -ForegroundColor Gray
            Write-Host "  IP Address: $($sampleLog.ip_address)" -ForegroundColor Gray
            Write-Host "  Created At: $($sampleLog.created_at)" -ForegroundColor Gray
        }
        
    } else {
        Write-Host "Warning: No log data retrieved" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: Failed to get logs - $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Test creating a log entry to see current user behavior
Write-Host "`n3. Testing current user log creation..." -ForegroundColor Yellow
try {
    # Try to trigger a log by accessing user profile (this should create a log with current user)
    $profileResponse = Invoke-RestMethod -Uri "$baseUrl/users/profile" -Method Get -Headers $headers
    
    if ($profileResponse.success) {
        Write-Host "Success: Profile access completed" -ForegroundColor Green
        
        # Get recent logs to see if new log was created with user info
        Start-Sleep -Seconds 1
        $recentLogsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=5" -Method Get -Headers $headers
        
        if ($recentLogsResponse.success -and $recentLogsResponse.data.logs) {
            $recentLogs = $recentLogsResponse.data.logs
            Write-Host "`nRecent logs after profile access:" -ForegroundColor Cyan
            
            foreach ($log in $recentLogs) {
                $userInfo = if ($log.user_id) { "User ID: $($log.user_id)" } else { "No User" }
                $userObj = if ($log.user) { "User: $($log.user.username)" } else { "No User Object" }
                Write-Host "  [$($log.level)] $($log.category) - $userInfo, $userObj" -ForegroundColor Gray
            }
        }
    }
} catch {
    Write-Host "Info: Profile access test completed with expected behavior" -ForegroundColor Gray
}

# Step 4: Analyze IP addresses and request patterns
Write-Host "`n4. Analyzing request patterns..." -ForegroundColor Yellow
try {
    if ($logs) {
        $ipAddresses = @{}
        $categories = @{}
        
        foreach ($log in $logs) {
            # Count IP addresses
            if ($log.ip_address) {
                if ($ipAddresses.ContainsKey($log.ip_address)) {
                    $ipAddresses[$log.ip_address]++
                } else {
                    $ipAddresses[$log.ip_address] = 1
                }
            }
            
            # Count categories
            if ($log.category) {
                if ($categories.ContainsKey($log.category)) {
                    $categories[$log.category]++
                } else {
                    $categories[$log.category] = 1
                }
            }
        }
        
        Write-Host "IP Address Analysis:" -ForegroundColor Cyan
        foreach ($ip in ($ipAddresses.Keys | Sort-Object)) {
            Write-Host "  $ip : $($ipAddresses[$ip]) requests" -ForegroundColor Gray
        }
        
        Write-Host "`nCategory Analysis:" -ForegroundColor Cyan
        foreach ($cat in ($categories.Keys | Sort-Object)) {
            Write-Host "  $cat : $($categories[$cat]) logs" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "Error: Pattern analysis failed - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Analysis Results ===" -ForegroundColor Green
Write-Host "Backend User Information Status:" -ForegroundColor Cyan
if ($logsWithUserId.Count -gt 0) {
    Write-Host "  - Backend DOES contain user information in logs" -ForegroundColor Green
    Write-Host "  - User IDs are present in $($logsWithUserId.Count) out of $($logs.Count) logs" -ForegroundColor Gray
    if ($logsWithUserObject.Count -gt 0) {
        Write-Host "  - User objects are populated in $($logsWithUserObject.Count) logs" -ForegroundColor Green
    } else {
        Write-Host "  - User objects are NOT populated (need backend fix)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  - Backend does NOT contain user information in logs" -ForegroundColor Red
    Write-Host "  - Frontend should implement fallback user display" -ForegroundColor Yellow
}

Write-Host "`nRecommended Frontend Actions:" -ForegroundColor Cyan
if ($logsWithUserId.Count -eq 0) {
    Write-Host "  1. Implement current user fallback display" -ForegroundColor Gray
    Write-Host "  2. Show 'system' for system-generated logs" -ForegroundColor Gray
    Write-Host "  3. Use IP address as user identifier when available" -ForegroundColor Gray
} elseif ($logsWithUserObject.Count -eq 0) {
    Write-Host "  1. Fix backend to populate user objects" -ForegroundColor Gray
    Write-Host "  2. Implement frontend fallback for missing user objects" -ForegroundColor Gray
} else {
    Write-Host "  1. User information is properly available" -ForegroundColor Green
    Write-Host "  2. Frontend display should work correctly" -ForegroundColor Green
}

Write-Host "`n=== Log User Information Analysis Complete ===" -ForegroundColor Green