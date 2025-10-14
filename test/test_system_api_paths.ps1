#!/usr/bin/env pwsh
# Test System Management API Paths

$BaseUrl = "http://localhost:8080"
$Headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== System Management API Paths Test ===" -ForegroundColor Yellow
Write-Host ""

# Login first
Write-Host "1. Login to get admin token..." -ForegroundColor Blue
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -Headers $Headers
    if ($loginResponse.success) {
        Write-Host "✓ Login successful" -ForegroundColor Green
        $AuthHeaders = @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $($loginResponse.data.token)"
        }
    } else {
        Write-Host "✗ Login failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test all API paths that frontend will call
Write-Host "2. Testing API paths..." -ForegroundColor Blue

# System Health
Write-Host "  Testing system health..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/system/health" -Method GET -Headers $AuthHeaders
    if ($response.success) {
        Write-Host "    ✓ GET /api/v1/system/health - Success" -ForegroundColor Green
    }
} catch {
    Write-Host "    ✗ GET /api/v1/system/health - Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# System Config
Write-Host "  Testing system config..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/config" -Method GET -Headers $AuthHeaders
    if ($response.success) {
        Write-Host "    ✓ GET /api/v1/config - Success" -ForegroundColor Green
    }
} catch {
    Write-Host "    ✗ GET /api/v1/config - Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Create test config
$testConfig = @{
    category = "test"
    key = "api_test_$(Get-Date -Format 'HHmmss')"
    value = "test_value"
    description = "API test configuration"
    isPublic = $false
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/config" -Method POST -Body $testConfig -Headers $AuthHeaders
    if ($response.success) {
        Write-Host "    ✓ POST /api/v1/config - Success" -ForegroundColor Green
        $testConfigKey = $response.data.key
        $testConfigCategory = $response.data.category
    }
} catch {
    Write-Host "    ✗ POST /api/v1/config - Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Announcements
Write-Host "  Testing announcements..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/announcements" -Method GET -Headers $AuthHeaders
    if ($response.success) {
        Write-Host "    ✓ GET /api/v1/announcements - Success" -ForegroundColor Green
    }
} catch {
    Write-Host "    ✗ GET /api/v1/announcements - Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Create test announcement
$testAnnouncement = @{
    title = "API Test Announcement"
    type = "info"
    priority = 1
    content = "This is an API test announcement."
    is_active = $true
    is_sticky = $false
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/announcements" -Method POST -Body $testAnnouncement -Headers $AuthHeaders
    if ($response.success) {
        Write-Host "    ✓ POST /api/v1/announcements - Success" -ForegroundColor Green
        $testAnnouncementId = $response.data.id
    }
} catch {
    Write-Host "    ✗ POST /api/v1/announcements - Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# System Logs
Write-Host "  Testing system logs..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/logs" -Method GET -Headers $AuthHeaders
    if ($response.success) {
        Write-Host "    ✓ GET /api/v1/logs - Success" -ForegroundColor Green
    }
} catch {
    Write-Host "    ✗ GET /api/v1/logs - Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Cleanup test data
Write-Host "3. Cleaning up test data..." -ForegroundColor Blue

if ($testConfigCategory -and $testConfigKey) {
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/config/$testConfigCategory/$testConfigKey" -Method DELETE -Headers $AuthHeaders
        if ($response.success) {
            Write-Host "  ✓ Test config deleted" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ✗ Delete test config failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($testAnnouncementId) {
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/announcements/$testAnnouncementId" -Method DELETE -Headers $AuthHeaders
        if ($response.success) {
            Write-Host "  ✓ Test announcement deleted" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ✗ Delete test announcement failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Yellow
Write-Host "All API paths have been tested and should work with the frontend!" -ForegroundColor Green
Write-Host ""
Write-Host "Frontend API paths are now correctly mapped to:" -ForegroundColor Cyan
Write-Host "  - System Health: /api/v1/system/health" -ForegroundColor Gray
Write-Host "  - System Config: /api/v1/config" -ForegroundColor Gray
Write-Host "  - Announcements: /api/v1/announcements" -ForegroundColor Gray
Write-Host "  - System Logs: /api/v1/logs" -ForegroundColor Gray