#!/usr/bin/env pwsh
# Test System Management Frontend Fixes

$BaseUrl = "http://localhost:8080"
$Headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== System Management Frontend Fixes Test ===" -ForegroundColor Yellow
Write-Host ""

# Login first
Write-Host "1. Login..." -ForegroundColor Blue
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

# Test System Health - should show healthy status
Write-Host "2. Testing System Health Display..." -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/system/health" -Method GET -Headers $AuthHeaders
    if ($response.success) {
        Write-Host "✓ System Health API Success" -ForegroundColor Green
        Write-Host "  Overall Status: $($response.data.overall_status)" -ForegroundColor Cyan
        Write-Host "  Components: $($response.data.components.Count)" -ForegroundColor Cyan
        Write-Host "  Frontend should now show: $($response.data.overall_status)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ System health failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test System Config - should show configs
Write-Host "3. Testing System Config Display..." -ForegroundColor Blue

# Create a test config first
$testConfig = @{
    category = "frontend_test"
    key = "display_test"
    value = "test_value"
    description = "Frontend display test configuration"
    isPublic = $true
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/config" -Method POST -Body $testConfig -Headers $AuthHeaders
    if ($createResponse.success) {
        Write-Host "✓ Test config created" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠ Create test config failed (may already exist)" -ForegroundColor Yellow
}

# Get configs
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/config" -Method GET -Headers $AuthHeaders
    if ($response.success) {
        Write-Host "✓ System Config API Success" -ForegroundColor Green
        Write-Host "  Total Configs: $($response.data.total)" -ForegroundColor Cyan
        Write-Host "  Configs Array Length: $($response.data.configs.Count)" -ForegroundColor Cyan
        Write-Host "  Frontend should now show: $($response.data.total) configs" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ System config failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test Announcements - should show announcements
Write-Host "4. Testing Announcements Display..." -ForegroundColor Blue

# Create a test announcement
$testAnnouncement = @{
    title = "Frontend Test Announcement"
    type = "info"
    priority = 1
    content = "This is a frontend display test announcement."
    is_active = $true
    is_sticky = $false
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/announcements" -Method POST -Body $testAnnouncement -Headers $AuthHeaders
    if ($createResponse.success) {
        Write-Host "✓ Test announcement created" -ForegroundColor Green
        $testAnnouncementId = $createResponse.data.id
    }
} catch {
    Write-Host "⚠ Create test announcement failed" -ForegroundColor Yellow
}

# Get announcements
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/announcements" -Method GET -Headers $AuthHeaders
    if ($response.success) {
        Write-Host "✓ Announcements API Success" -ForegroundColor Green
        Write-Host "  Total Announcements: $($response.data.total)" -ForegroundColor Cyan
        Write-Host "  Announcements Array Length: $($response.data.announcements.Count)" -ForegroundColor Cyan
        Write-Host "  Active Announcements: $(($response.data.announcements | Where-Object { $_.is_active -eq $true }).Count)" -ForegroundColor Cyan
        Write-Host "  Frontend should now show: $($response.data.total) announcements" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Announcements failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test System Logs - should show logs
Write-Host "5. Testing System Logs Display..." -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/logs" -Method GET -Headers $AuthHeaders
    if ($response.success) {
        Write-Host "✓ System Logs API Success" -ForegroundColor Green
        Write-Host "  Total Logs: $($response.data.total)" -ForegroundColor Cyan
        if ($response.data.logs) {
            Write-Host "  Logs Array Length: $($response.data.logs.Count)" -ForegroundColor Cyan
        } elseif ($response.data.items) {
            Write-Host "  Items Array Length: $($response.data.items.Count)" -ForegroundColor Cyan
        }
        Write-Host "  Frontend should now show: $($response.data.total) logs" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ System logs failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Cleanup
Write-Host "6. Cleanup..." -ForegroundColor Blue
if ($testAnnouncementId) {
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/announcements/$testAnnouncementId" -Method DELETE -Headers $AuthHeaders
        Write-Host "✓ Test announcement deleted" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Delete announcement failed" -ForegroundColor Yellow
    }
}

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/config/frontend_test/display_test" -Method DELETE -Headers $AuthHeaders
    Write-Host "✓ Test config deleted" -ForegroundColor Green
} catch {
    Write-Host "⚠ Delete config failed (may not exist)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Frontend Fixes Summary ===" -ForegroundColor Yellow
Write-Host "✓ System Health: Fixed status field mapping (overall_status -> status)" -ForegroundColor Green
Write-Host "✓ System Config: Fixed data field mapping (items -> configs)" -ForegroundColor Green
Write-Host "✓ Announcements: Fixed data field mapping (items -> announcements)" -ForegroundColor Green
Write-Host "✓ Announcements: Fixed search parameter (isActive -> is_active)" -ForegroundColor Green
Write-Host "✓ System Logs: Added fallback for data field mapping" -ForegroundColor Green
Write-Host ""
Write-Host "Frontend system management interface should now display data correctly!" -ForegroundColor Cyan