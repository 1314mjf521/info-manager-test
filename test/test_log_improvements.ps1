# Test Log Management Improvements
# Test custom category feature and user display enhancements

Write-Host "=== Testing Log Management Improvements ===" -ForegroundColor Green

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
        Write-Host "Success: Login completed" -ForegroundColor Green
    } else {
        throw "Login failed: $($loginResponse.message)"
    }
} catch {
    Write-Host "Error: Login failed - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Get current logs and analyze categories
Write-Host "`n2. Analyzing log categories..." -ForegroundColor Yellow
try {
    $logsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=50" -Method Get -Headers $headers
    
    if ($logsResponse.success -and $logsResponse.data.logs) {
        $logs = $logsResponse.data.logs
        $totalLogs = $logsResponse.data.total
        
        Write-Host "Success: Retrieved $totalLogs total logs" -ForegroundColor Green
        
        # Analyze categories
        $categories = @{}
        foreach ($log in $logs) {
            if ($log.category) {
                if ($categories.ContainsKey($log.category)) {
                    $categories[$log.category]++
                } else {
                    $categories[$log.category] = 1
                }
            }
        }
        
        Write-Host "`nFound log categories:" -ForegroundColor Cyan
        $defaultCategories = @('system', 'auth', 'http', 'api', 'database', 'file', 'cache', 'email', 'job', 'security', 'network', 'storage', 'monitor', 'backup', 'config', 'user', 'permission', 'notification', 'report', 'import', 'export', 'sync', 'cron', 'external')
        
        foreach ($category in ($categories.Keys | Sort-Object)) {
            $count = $categories[$category]
            $isDefault = $defaultCategories -contains $category
            $categoryType = if ($isDefault) { "Default" } else { "Custom" }
            $color = if ($isDefault) { "Gray" } else { "Yellow" }
            
            Write-Host "  $category ($count logs) - $categoryType" -ForegroundColor $color
        }
        
        $customCategoryCount = ($categories.Keys | Where-Object { $defaultCategories -notcontains $_ }).Count
        Write-Host "`nFound $customCategoryCount custom categories" -ForegroundColor Green
        
    } else {
        Write-Host "Warning: No log data retrieved" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: Failed to get logs - $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Test filtering by custom category
Write-Host "`n3. Testing custom category filtering..." -ForegroundColor Yellow
if ($categories -and $categories.Keys.Count -gt 0) {
    $testCategory = $categories.Keys | Where-Object { $defaultCategories -notcontains $_ } | Select-Object -First 1
    
    if ($testCategory) {
        try {
            $filterUrl = "$baseUrl/logs?category=$testCategory&page=1&page_size=10"
            $filterResponse = Invoke-RestMethod -Uri $filterUrl -Method Get -Headers $headers
            
            if ($filterResponse.success) {
                $filteredLogs = $filterResponse.data.logs
                $filteredTotal = $filterResponse.data.total
                
                Write-Host "Success: Filtered by category '$testCategory'" -ForegroundColor Green
                Write-Host "  Result: $filteredTotal logs found" -ForegroundColor Gray
                
                # Verify filter accuracy
                $correctFilter = $true
                foreach ($log in $filteredLogs) {
                    if ($log.category -ne $testCategory) {
                        $correctFilter = $false
                        break
                    }
                }
                
                if ($correctFilter) {
                    Write-Host "  Verification: Filter results are accurate" -ForegroundColor Green
                } else {
                    Write-Host "  Warning: Filter results contain other categories" -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Host "Error: Custom category filtering failed - $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Info: No custom categories found for testing" -ForegroundColor Gray
    }
} else {
    Write-Host "Info: No category data available for testing" -ForegroundColor Gray
}

# Step 4: Test user information display
Write-Host "`n4. Testing user information display..." -ForegroundColor Yellow
try {
    $logsWithUsers = $logs | Where-Object { $_.user_id -ne $null }
    
    if ($logsWithUsers.Count -gt 0) {
        Write-Host "Success: Found $($logsWithUsers.Count) logs with user information" -ForegroundColor Green
        
        # Show sample user info
        $sampleLog = $logsWithUsers[0]
        Write-Host "  Sample log user info:" -ForegroundColor Gray
        Write-Host "    User ID: $($sampleLog.user_id)" -ForegroundColor Gray
        if ($sampleLog.user -and $sampleLog.user.username) {
            Write-Host "    Username: $($sampleLog.user.username)" -ForegroundColor Gray
        } else {
            Write-Host "    Username: Not available" -ForegroundColor Gray
        }
    } else {
        Write-Host "Info: No logs with user information found" -ForegroundColor Gray
    }
} catch {
    Write-Host "Error: User information test failed - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Frontend Improvements Summary ===" -ForegroundColor Green
Write-Host "Custom Category Features:" -ForegroundColor Cyan
Write-Host "  - Support for custom category input" -ForegroundColor Gray
Write-Host "  - Automatic extraction of existing categories" -ForegroundColor Gray
Write-Host "  - Grouped display: Default + Dynamic categories" -ForegroundColor Gray
Write-Host "  - Filterable and searchable categories" -ForegroundColor Gray
Write-Host "  - Custom category cleanup support" -ForegroundColor Gray

Write-Host "`nUser Display Enhancements:" -ForegroundColor Cyan
Write-Host "  - Improved user information display" -ForegroundColor Gray
Write-Host "  - Username fallback for missing user data" -ForegroundColor Gray
Write-Host "  - Better user ID formatting" -ForegroundColor Gray

Write-Host "`nUsage Instructions:" -ForegroundColor Cyan
Write-Host "1. Open log management page" -ForegroundColor Gray
Write-Host "2. Use category dropdown to select or input custom categories" -ForegroundColor Gray
Write-Host "3. System automatically remembers and displays used categories" -ForegroundColor Gray
Write-Host "4. Filter and cleanup operations support custom categories" -ForegroundColor Gray

Write-Host "`n=== Log Management Improvements Test Complete ===" -ForegroundColor Green