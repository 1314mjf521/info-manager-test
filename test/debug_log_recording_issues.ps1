# Debug Log Recording Issues
# Analyze why logs lack user information and IP addresses

Write-Host "=== Debugging Log Recording Issues ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080/api/v1"

# Step 1: Login and capture request details
Write-Host "1. Login and analyze request/response..." -ForegroundColor Yellow
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    }
    
    # Capture the login request details
    Write-Host "  Making login request..." -ForegroundColor Gray
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body ($loginData | ConvertTo-Json) -ContentType "application/json" -Verbose
    
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

# Step 2: Make several API calls to generate logs with user context
Write-Host "`n2. Making API calls to generate logs..." -ForegroundColor Yellow
try {
    Write-Host "  Making profile request..." -ForegroundColor Gray
    $profileResponse = Invoke-RestMethod -Uri "$baseUrl/users/profile" -Method Get -Headers $headers
    
    Write-Host "  Making health check request..." -ForegroundColor Gray
    $healthResponse = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get -Headers $headers
    
    Write-Host "  Making config request..." -ForegroundColor Gray
    try {
        $configResponse = Invoke-RestMethod -Uri "$baseUrl/config" -Method Get -Headers $headers
    } catch {
        Write-Host "    Config request failed (expected)" -ForegroundColor Gray
    }
    
    Write-Host "  Waiting for logs to be written..." -ForegroundColor Gray
    Start-Sleep -Seconds 2
    
} catch {
    Write-Host "Warning: Some API calls failed (this is expected for testing)" -ForegroundColor Yellow
}

# Step 3: Analyze recent logs in detail
Write-Host "`n3. Analyzing recent logs in detail..." -ForegroundColor Yellow
try {
    $logsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=10" -Method Get -Headers $headers
    
    if ($logsResponse.success -and $logsResponse.data.logs) {
        $logs = $logsResponse.data.logs
        Write-Host "Success: Retrieved $($logs.Count) recent logs" -ForegroundColor Green
        
        Write-Host "`nDetailed Log Analysis:" -ForegroundColor Cyan
        for ($i = 0; $i -lt [Math]::Min(5, $logs.Count); $i++) {
            $log = $logs[$i]
            Write-Host "  --- Log $($i + 1) ---" -ForegroundColor White
            Write-Host "    ID: $($log.id)" -ForegroundColor Gray
            Write-Host "    Level: $($log.level)" -ForegroundColor Gray
            Write-Host "    Category: $($log.category)" -ForegroundColor Gray
            Write-Host "    Message: $($log.message)" -ForegroundColor Gray
            Write-Host "    User ID: $($log.user_id)" -ForegroundColor $(if ($log.user_id) { "Green" } else { "Red" })
            Write-Host "    User Object: $($log.user)" -ForegroundColor $(if ($log.user) { "Green" } else { "Red" })
            Write-Host "    IP Address: $($log.ip_address)" -ForegroundColor $(if ($log.ip_address) { "Green" } else { "Red" })
            Write-Host "    User Agent: $($log.user_agent)" -ForegroundColor $(if ($log.user_agent) { "Green" } else { "Red" })
            Write-Host "    Request ID: $($log.request_id)" -ForegroundColor $(if ($log.request_id) { "Green" } else { "Red" })
            Write-Host "    Created At: $($log.created_at)" -ForegroundColor Gray
            
            if ($log.context) {
                Write-Host "    Context: $($log.context | ConvertTo-Json -Compress)" -ForegroundColor Gray
            }
            Write-Host ""
        }
        
        # Statistics
        $logsWithUserId = ($logs | Where-Object { $_.user_id -ne $null -and $_.user_id -ne 0 }).Count
        $logsWithIP = ($logs | Where-Object { $_.ip_address -ne $null -and $_.ip_address -ne "" }).Count
        $logsWithUserAgent = ($logs | Where-Object { $_.user_agent -ne $null -and $_.user_agent -ne "" }).Count
        
        Write-Host "Statistics:" -ForegroundColor Cyan
        Write-Host "  Total logs: $($logs.Count)" -ForegroundColor Gray
        Write-Host "  Logs with User ID: $logsWithUserId" -ForegroundColor $(if ($logsWithUserId -gt 0) { "Green" } else { "Red" })
        Write-Host "  Logs with IP Address: $logsWithIP" -ForegroundColor $(if ($logsWithIP -gt 0) { "Green" } else { "Red" })
        Write-Host "  Logs with User Agent: $logsWithUserAgent" -ForegroundColor $(if ($logsWithUserAgent -gt 0) { "Green" } else { "Red" })
        
    } else {
        Write-Host "Warning: No log data retrieved" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: Failed to analyze logs - $($_.Exception.Message)" -ForegroundColor Red
}

# Step 4: Check if middleware is capturing request context
Write-Host "`n4. Testing request context capture..." -ForegroundColor Yellow
try {
    # Make a request with custom headers to see if they're logged
    $customHeaders = $headers.Clone()
    $customHeaders["X-Test-Header"] = "LoggingTest"
    $customHeaders["User-Agent"] = "PowerShell-LogTest/1.0"
    
    Write-Host "  Making request with custom headers..." -ForegroundColor Gray
    try {
        $testResponse = Invoke-RestMethod -Uri "$baseUrl/users/profile" -Method Get -Headers $customHeaders
        Write-Host "  Custom header request completed" -ForegroundColor Green
    } catch {
        Write-Host "  Custom header request failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    Start-Sleep -Seconds 1
    
    # Check if the custom headers appeared in logs
    $recentLogsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=3" -Method Get -Headers $headers
    if ($recentLogsResponse.success -and $recentLogsResponse.data.logs) {
        $recentLogs = $recentLogsResponse.data.logs
        Write-Host "`nMost recent logs after custom request:" -ForegroundColor Cyan
        foreach ($log in $recentLogs) {
            Write-Host "  [$($log.level)] $($log.category): $($log.message)" -ForegroundColor Gray
            if ($log.user_agent -and $log.user_agent -like "*PowerShell-LogTest*") {
                Write-Host "    ✓ Custom User-Agent captured: $($log.user_agent)" -ForegroundColor Green
            }
            if ($log.context) {
                Write-Host "    Context: $($log.context)" -ForegroundColor Gray
            }
        }
    }
    
} catch {
    Write-Host "Error: Request context test failed - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Analysis Results ===" -ForegroundColor Green

Write-Host "`nIssues Identified:" -ForegroundColor Red
if ($logsWithUserId -eq 0) {
    Write-Host "  ❌ No logs contain user_id information" -ForegroundColor Red
    Write-Host "     - Backend middleware not capturing authenticated user" -ForegroundColor Yellow
    Write-Host "     - JWT token not being parsed for user context" -ForegroundColor Yellow
}

if ($logsWithIP -eq 0) {
    Write-Host "  ❌ No logs contain IP address information" -ForegroundColor Red
    Write-Host "     - Request IP not being extracted from headers" -ForegroundColor Yellow
    Write-Host "     - Middleware not capturing client IP" -ForegroundColor Yellow
}

if ($logsWithUserAgent -eq 0) {
    Write-Host "  ❌ No logs contain User-Agent information" -ForegroundColor Red
    Write-Host "     - Request headers not being logged" -ForegroundColor Yellow
}

Write-Host "`nFrontend Issues:" -ForegroundColor Red
Write-Host "  ❌ User ID filter in frontend is inappropriate" -ForegroundColor Red
Write-Host "     - Since no logs have user_id, this filter is useless" -ForegroundColor Yellow
Write-Host "     - Should be replaced with more useful filters" -ForegroundColor Yellow

Write-Host "`nRecommended Fixes:" -ForegroundColor Cyan
Write-Host "  1. Backend: Fix logging middleware to capture user context" -ForegroundColor Gray
Write-Host "  2. Backend: Extract and log client IP addresses" -ForegroundColor Gray
Write-Host "  3. Backend: Log request headers (User-Agent, etc.)" -ForegroundColor Gray
Write-Host "  4. Frontend: Remove or replace user_id filter" -ForegroundColor Gray
Write-Host "  5. Frontend: Add more useful filters (IP, User-Agent, etc.)" -ForegroundColor Gray

Write-Host "`n=== Log Recording Issues Debug Complete ===" -ForegroundColor Green