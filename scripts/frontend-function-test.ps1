# Frontend Function Test - Test frontend routes and components
Write-Host "=== Frontend Function Test ===" -ForegroundColor Green

$frontendUrl = "http://localhost:3000"
$testResults = @()

# Test frontend route
function Test-FrontendRoute {
    param(
        [string]$Name,
        [string]$Path
    )
    
    try {
        $response = Invoke-WebRequest -Uri "$frontendUrl$Path" -TimeoutSec 10
        $success = $response.StatusCode -eq 200
        $status = if ($success) { "PASS" } else { "FAIL" }
        
        Write-Host "  $status - $Name - HTTP $($response.StatusCode)" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
        
        $script:testResults += @{
            Name = $Name
            Status = $status
            StatusCode = $response.StatusCode
            Path = $Path
        }
        
        return $success
    } catch {
        $statusCode = "Unknown"
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        
        Write-Host "  FAIL - $Name - HTTP $statusCode" -ForegroundColor Red
        
        $script:testResults += @{
            Name = $Name
            Status = "FAIL"
            StatusCode = $statusCode
            Path = $Path
        }
        
        return $false
    }
}

# 1. Check if frontend is running
Write-Host "`n1. Checking frontend server..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri $frontendUrl -TimeoutSec 5
    Write-Host "Frontend server is running - HTTP $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Frontend server is not running or not accessible" -ForegroundColor Red
    Write-Host "Please start the frontend server with: npm run dev" -ForegroundColor Yellow
    exit 1
}

# 2. Test main routes
Write-Host "`n2. Testing main routes..." -ForegroundColor Cyan

Test-FrontendRoute -Name "Home Page" -Path "/"
Test-FrontendRoute -Name "Login Page" -Path "/login"
Test-FrontendRoute -Name "Dashboard" -Path "/dashboard"

# 3. Test management routes
Write-Host "`n3. Testing management routes..." -ForegroundColor Cyan

Test-FrontendRoute -Name "User Management" -Path "/users"
Test-FrontendRoute -Name "Role Management" -Path "/roles"
Test-FrontendRoute -Name "Permission Management" -Path "/permissions"

# 4. Test ticket routes
Write-Host "`n4. Testing ticket routes..." -ForegroundColor Cyan

Test-FrontendRoute -Name "Ticket List" -Path "/tickets"
Test-FrontendRoute -Name "Ticket Create" -Path "/tickets/create"

# 5. Test other functional routes
Write-Host "`n5. Testing other functional routes..." -ForegroundColor Cyan

Test-FrontendRoute -Name "Records" -Path "/records"
Test-FrontendRoute -Name "Files" -Path "/files"
Test-FrontendRoute -Name "Export" -Path "/export"
Test-FrontendRoute -Name "System" -Path "/system"
Test-FrontendRoute -Name "Profile" -Path "/profile"

# 6. Generate test report
Write-Host "`n=== Frontend Function Test Report ===" -ForegroundColor Green

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failedTests = $totalTests - $passedTests

Write-Host "`nTest Statistics:" -ForegroundColor Yellow
Write-Host "Total Tests: $totalTests" -ForegroundColor Gray
Write-Host "Passed Tests: $passedTests" -ForegroundColor Green
Write-Host "Failed Tests: $failedTests" -ForegroundColor Red
if ($totalTests -gt 0) {
    Write-Host "Success Rate: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor Cyan
}

Write-Host "`nDetailed Results:" -ForegroundColor Yellow
$testResults | ForEach-Object {
    $color = if ($_.Status -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  $($_.Name): $($_.Status) (HTTP $($_.StatusCode))" -ForegroundColor $color
}

# Group by route category
Write-Host "`nRoute Category Results:" -ForegroundColor Yellow
$categories = @{
    "Main Routes" = $testResults | Where-Object { $_.Name -like "*Home*" -or $_.Name -like "*Login*" -or $_.Name -like "*Dashboard*" }
    "Management Routes" = $testResults | Where-Object { $_.Name -like "*Management*" }
    "Ticket Routes" = $testResults | Where-Object { $_.Name -like "*Ticket*" }
    "Other Routes" = $testResults | Where-Object { $_.Name -like "*Records*" -or $_.Name -like "*Files*" -or $_.Name -like "*Export*" -or $_.Name -like "*System*" -or $_.Name -like "*Profile*" }
}

foreach ($category in $categories.Keys) {
    $categoryResults = $categories[$category]
    if ($categoryResults.Count -gt 0) {
        $categoryPassed = ($categoryResults | Where-Object { $_.Status -eq "PASS" }).Count
        $categoryRate = [math]::Round(($categoryPassed / $categoryResults.Count) * 100, 1)
        Write-Host "  $category`: $categoryPassed/$($categoryResults.Count) ($categoryRate%)" -ForegroundColor Cyan
    }
}

if ($failedTests -eq 0) {
    Write-Host "`nAll frontend routes are accessible!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome frontend routes failed. Please check the frontend application." -ForegroundColor Yellow
    exit 1
}