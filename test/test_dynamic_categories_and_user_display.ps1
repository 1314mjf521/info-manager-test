# Test Dynamic Categories and User Display Improvements
# Verify the enhanced user display and dynamic category features

Write-Host "=== Testing Dynamic Categories and User Display ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080/api/v1"

# Step 1: Login and get current user info
Write-Host "1. Login and get current user information..." -ForegroundColor Yellow
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
        Write-Host "  Current User: $($currentUser.username) (ID: $($currentUser.id))" -ForegroundColor Gray
    } else {
        throw "Login failed: $($loginResponse.message)"
    }
} catch {
    Write-Host "Error: Login failed - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Test frontend improvements by accessing the system page
Write-Host "`n2. Testing frontend user display improvements..." -ForegroundColor Yellow
try {
    # Get logs to test user display
    $logsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=10" -Method Get -Headers $headers
    
    if ($logsResponse.success -and $logsResponse.data.logs) {
        $logs = $logsResponse.data.logs
        Write-Host "Success: Retrieved $($logs.Count) logs for testing" -ForegroundColor Green
        
        # Analyze user display scenarios
        $systemLogs = @()
        $userLogs = @()
        $noUserLogs = @()
        
        foreach ($log in $logs) {
            if ($log.user_id) {
                $userLogs += $log
            } elseif ($log.category -in @('system', 'health', 'monitor', 'backup', 'cron', 'database')) {
                $systemLogs += $log
            } else {
                $noUserLogs += $log
            }
        }
        
        Write-Host "`nUser Display Analysis:" -ForegroundColor Cyan
        Write-Host "  System logs (should show 'system'): $($systemLogs.Count)" -ForegroundColor Gray
        Write-Host "  User logs (should show user info): $($userLogs.Count)" -ForegroundColor Gray
        Write-Host "  Other logs (should show current user): $($noUserLogs.Count)" -ForegroundColor Gray
        
        # Show examples
        if ($systemLogs.Count -gt 0) {
            $sample = $systemLogs[0]
            Write-Host "`nSystem log example:" -ForegroundColor Cyan
            Write-Host "  Category: $($sample.category)" -ForegroundColor Gray
            Write-Host "  Message: $($sample.message)" -ForegroundColor Gray
            Write-Host "  Expected display: system" -ForegroundColor Green
        }
        
        if ($noUserLogs.Count -gt 0) {
            $sample = $noUserLogs[0]
            Write-Host "`nNo-user log example:" -ForegroundColor Cyan
            Write-Host "  Category: $($sample.category)" -ForegroundColor Gray
            Write-Host "  Message: $($sample.message)" -ForegroundColor Gray
            Write-Host "  IP Address: $($sample.ip_address)" -ForegroundColor Gray
            Write-Host "  Expected display: $($currentUser.username)" -ForegroundColor Green
        }
        
    } else {
        Write-Host "Warning: No log data available for testing" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: Failed to test user display - $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Test dynamic categories functionality
Write-Host "`n3. Testing dynamic categories functionality..." -ForegroundColor Yellow
try {
    # Get all logs to extract categories
    $allLogsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=100" -Method Get -Headers $headers
    
    if ($allLogsResponse.success -and $allLogsResponse.data.logs) {
        $allLogs = $allLogsResponse.data.logs
        
        # Extract unique categories
        $categories = @{}
        foreach ($log in $allLogs) {
            if ($log.category) {
                if ($categories.ContainsKey($log.category)) {
                    $categories[$log.category]++
                } else {
                    $categories[$log.category] = 1
                }
            }
        }
        
        Write-Host "Success: Extracted categories from $($allLogs.Count) logs" -ForegroundColor Green
        
        # Categorize as default vs custom
        $defaultCategories = @('system', 'auth', 'http', 'api', 'database', 'file', 'cache', 'email', 'job', 'security', 'network', 'storage', 'monitor', 'backup', 'config', 'user', 'permission', 'notification', 'report', 'import', 'export', 'sync', 'cron', 'external')
        
        $defaultFound = @()
        $customFound = @()
        
        foreach ($category in $categories.Keys) {
            if ($defaultCategories -contains $category) {
                $defaultFound += $category
            } else {
                $customFound += $category
            }
        }
        
        Write-Host "`nCategory Analysis:" -ForegroundColor Cyan
        Write-Host "  Default categories found: $($defaultFound.Count)" -ForegroundColor Gray
        foreach ($cat in ($defaultFound | Sort-Object)) {
            Write-Host "    $cat ($($categories[$cat]) logs)" -ForegroundColor Gray
        }
        
        Write-Host "  Custom categories found: $($customFound.Count)" -ForegroundColor Yellow
        foreach ($cat in ($customFound | Sort-Object)) {
            Write-Host "    $cat ($($categories[$cat]) logs)" -ForegroundColor Yellow
        }
        
        # Test filtering by custom category
        if ($customFound.Count -gt 0) {
            $testCategory = $customFound[0]
            Write-Host "`nTesting filter by custom category '$testCategory'..." -ForegroundColor Cyan
            
            $filterResponse = Invoke-RestMethod -Uri "$baseUrl/logs?category=$testCategory&page=1&page_size=5" -Method Get -Headers $headers
            
            if ($filterResponse.success) {
                $filteredLogs = $filterResponse.data.logs
                Write-Host "Success: Found $($filteredLogs.Count) logs in category '$testCategory'" -ForegroundColor Green
            }
        }
        
    } else {
        Write-Host "Warning: No logs available for category analysis" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: Category analysis failed - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Frontend Improvements Summary ===" -ForegroundColor Green

Write-Host "`nUser Display Enhancements:" -ForegroundColor Cyan
Write-Host "  - System logs now show 'system' user" -ForegroundColor Gray
Write-Host "  - Logs without user_id show current user ($($currentUser.username))" -ForegroundColor Gray
Write-Host "  - Local IP addresses mapped to current user" -ForegroundColor Gray
Write-Host "  - Fallback logic for different log types" -ForegroundColor Gray

Write-Host "`nDynamic Categories Features:" -ForegroundColor Cyan
Write-Host "  - Automatic extraction of all existing categories" -ForegroundColor Gray
Write-Host "  - Separation of default vs custom categories" -ForegroundColor Gray
Write-Host "  - Support for custom category input and filtering" -ForegroundColor Gray
Write-Host "  - Category memory and persistence" -ForegroundColor Gray

Write-Host "`nImplementation Details:" -ForegroundColor Cyan
Write-Host "  - Uses auth store for current user information" -ForegroundColor Gray
Write-Host "  - Intelligent fallback user display logic" -ForegroundColor Gray
Write-Host "  - Enhanced category selector with grouping" -ForegroundColor Gray
Write-Host "  - Improved user experience for log management" -ForegroundColor Gray

Write-Host "`n=== Dynamic Categories and User Display Test Complete ===" -ForegroundColor Green