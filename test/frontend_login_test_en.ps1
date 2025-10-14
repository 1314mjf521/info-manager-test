# Frontend Login Redirect Test Script
# Test Date: 2025-01-04

Write-Host "=== Frontend Login Redirect Test ===" -ForegroundColor Green
Write-Host "Test Time: $(Get-Date)" -ForegroundColor Gray

# Test Configuration
$frontendUrl = "http://localhost:3000"
$testTimeout = 10

Write-Host "`n1. Checking frontend dev server status..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri $frontendUrl -TimeoutSec $testTimeout -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Frontend server running normally (Status: $($response.StatusCode))" -ForegroundColor Green
        Write-Host "   Response size: $($response.Content.Length) characters" -ForegroundColor Gray
    } else {
        Write-Host "❌ Frontend server response abnormal (Status: $($response.StatusCode))" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Cannot connect to frontend server: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Please ensure dev server is running: npm run dev" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n2. Testing key route access..." -ForegroundColor Yellow

$routes = @(
    @{ path = "/"; name = "Home" },
    @{ path = "/login"; name = "Login" },
    @{ path = "/register"; name = "Register" },
    @{ path = "/dashboard"; name = "Dashboard" },
    @{ path = "/records"; name = "Records" }
)

$routeResults = @()

foreach ($route in $routes) {
    try {
        $url = "$frontendUrl$($route.path)"
        $response = Invoke-WebRequest -Uri $url -TimeoutSec $testTimeout -UseBasicParsing
        $status = if ($response.StatusCode -eq 200) { "✅" } else { "❌" }
        $routeResults += @{
            Path = $route.path
            Name = $route.name
            Status = $response.StatusCode
            Size = $response.Content.Length
            Success = $response.StatusCode -eq 200
        }
        Write-Host "   $status $($route.name) ($($route.path)) - $($response.StatusCode) - $($response.Content.Length) chars" -ForegroundColor $(if ($response.StatusCode -eq 200) { "Green" } else { "Red" })
    } catch {
        $routeResults += @{
            Path = $route.path
            Name = $route.name
            Status = "Error"
            Size = 0
            Success = $false
        }
        Write-Host "   ❌ $($route.name) ($($route.path)) - Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n3. Checking frontend config files..." -ForegroundColor Yellow

$configFiles = @(
    "frontend/src/config/api.ts",
    "frontend/src/stores/auth.ts",
    "frontend/src/router/index.ts",
    "frontend/src/views/auth/LoginView.vue"
)

$configResults = @()

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw -Encoding UTF8
        $size = $content.Length
        $configResults += @{
            File = $file
            Exists = $true
            Size = $size
        }
        Write-Host "   ✅ $file - $size chars" -ForegroundColor Green
        
        # Check key configurations
        if ($file -eq "frontend/src/config/api.ts") {
            if ($content -match "BASE_URL.*localhost:8080") {
                Write-Host "      ✅ API URL configured correctly (localhost:8080)" -ForegroundColor Green
            } else {
                Write-Host "      ⚠️  API URL may need checking" -ForegroundColor Yellow
            }
        }
        
        if ($file -eq "frontend/src/views/auth/LoginView.vue") {
            if ($content -match "router\.push|router\.replace") {
                Write-Host "      ✅ Contains router redirect logic" -ForegroundColor Green
            } else {
                Write-Host "      ❌ Missing router redirect logic" -ForegroundColor Red
            }
        }
    } else {
        $configResults += @{
            File = $file
            Exists = $false
            Size = 0
        }
        Write-Host "   ❌ $file - File not found" -ForegroundColor Red
    }
}

Write-Host "`n4. Checking backend API connection..." -ForegroundColor Yellow

$backendUrl = "http://localhost:8080"
try {
    $response = Invoke-WebRequest -Uri "$backendUrl/api/v1/system/health" -TimeoutSec 5 -UseBasicParsing
    Write-Host "   ✅ Backend API service normal (Status: $($response.StatusCode))" -ForegroundColor Green
    $backendAvailable = $true
} catch {
    Write-Host "   ❌ Backend API service unavailable: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "      This may cause login functionality to fail" -ForegroundColor Yellow
    $backendAvailable = $false
}

Write-Host "`n=== Test Results Summary ===" -ForegroundColor Green

$successfulRoutes = ($routeResults | Where-Object { $_.Success }).Count
$totalRoutes = $routeResults.Count
$configFilesExist = ($configResults | Where-Object { $_.Exists }).Count
$totalConfigFiles = $configResults.Count

Write-Host "Route Access: $successfulRoutes/$totalRoutes successful" -ForegroundColor $(if ($successfulRoutes -eq $totalRoutes) { "Green" } else { "Yellow" })
Write-Host "Config Files: $configFilesExist/$totalConfigFiles exist" -ForegroundColor $(if ($configFilesExist -eq $totalConfigFiles) { "Green" } else { "Red" })
Write-Host "Backend Connection: $(if ($backendAvailable) { 'Available' } else { 'Unavailable' })" -ForegroundColor $(if ($backendAvailable) { "Green" } else { "Red" })

Write-Host "`n=== Login Redirect Issue Diagnosis ===" -ForegroundColor Cyan

if (-not $backendAvailable) {
    Write-Host "🔍 Main Issue: Backend API service unavailable" -ForegroundColor Red
    Write-Host "   Solution: Start backend server (port 8080)" -ForegroundColor Yellow
    Write-Host "   Command: go run cmd/server/main.go or ./start.bat" -ForegroundColor Gray
}

if ($successfulRoutes -lt $totalRoutes) {
    Write-Host "🔍 Route Issue: Some routes inaccessible" -ForegroundColor Yellow
    Write-Host "   This may be normal as some routes require authentication" -ForegroundColor Gray
}

Write-Host "`n=== Recommended Test Steps ===" -ForegroundColor Cyan
Write-Host "1. Ensure backend server is running on localhost:8080" -ForegroundColor White
Write-Host "2. Visit http://localhost:3000/login in browser" -ForegroundColor White
Write-Host "3. Enter test username and password to login" -ForegroundColor White
Write-Host "4. Check browser console for debug information" -ForegroundColor White
Write-Host "5. Verify successful redirect to homepage after login" -ForegroundColor White

Write-Host "`nTest completed at: $(Get-Date)" -ForegroundColor Gray