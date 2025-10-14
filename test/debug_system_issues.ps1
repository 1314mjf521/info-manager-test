#!/usr/bin/env pwsh
# Debug System Management Issues

$BaseUrl = "http://localhost:8080"
$Headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== Debug System Management Issues ===" -ForegroundColor Yellow
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

# Test System Health
Write-Host "2. Testing System Health..." -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/system/health" -Method GET -Headers $AuthHeaders
    Write-Host "Response:" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 5) -ForegroundColor Gray
} catch {
    Write-Host "✗ System health failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test System Config
Write-Host "3. Testing System Config..." -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/config" -Method GET -Headers $AuthHeaders
    Write-Host "Response:" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 5) -ForegroundColor Gray
} catch {
    Write-Host "✗ System config failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Create a test config
Write-Host "4. Creating test config..." -ForegroundColor Blue
$testConfig = @{
    category = "test"
    key = "debug_test"
    value = "debug_value"
    description = "Debug test configuration"
    isPublic = $true
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/config" -Method POST -Body $testConfig -Headers $AuthHeaders
    Write-Host "Create Response:" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 5) -ForegroundColor Gray
} catch {
    Write-Host "✗ Create config failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test Announcements
Write-Host "5. Testing Announcements..." -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/announcements" -Method GET -Headers $AuthHeaders
    Write-Host "Get Announcements Response:" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 5) -ForegroundColor Gray
} catch {
    Write-Host "✗ Get announcements failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Create a test announcement
Write-Host "6. Creating test announcement..." -ForegroundColor Blue
$testAnnouncement = @{
    title = "Debug Test Announcement"
    type = "info"
    priority = 1
    content = "This is a debug test announcement."
    is_active = $true
    is_sticky = $false
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/announcements" -Method POST -Body $testAnnouncement -Headers $AuthHeaders
    Write-Host "Create Announcement Response:" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 5) -ForegroundColor Gray
    $testAnnouncementId = $response.data.id
} catch {
    Write-Host "✗ Create announcement failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test get announcements again
Write-Host "7. Testing get announcements after creation..." -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/announcements" -Method GET -Headers $AuthHeaders
    Write-Host "Get Announcements After Create Response:" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 5) -ForegroundColor Gray
} catch {
    Write-Host "✗ Get announcements after create failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test System Logs
Write-Host "8. Testing System Logs..." -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/logs" -Method GET -Headers $AuthHeaders
    Write-Host "System Logs Response:" -ForegroundColor Cyan
    Write-Host "Total logs: $($response.data.total)" -ForegroundColor Gray
    if ($response.data.items.Count -gt 0) {
        Write-Host "Latest log: $($response.data.items[0].message)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Get system logs failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Cleanup
Write-Host "9. Cleanup..." -ForegroundColor Blue
if ($testAnnouncementId) {
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/announcements/$testAnnouncementId" -Method DELETE -Headers $AuthHeaders
        Write-Host "✓ Test announcement deleted" -ForegroundColor Green
    } catch {
        Write-Host "✗ Delete announcement failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/config/test/debug_test" -Method DELETE -Headers $AuthHeaders
    Write-Host "✓ Test config deleted" -ForegroundColor Green
} catch {
    Write-Host "✗ Delete config failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Debug Complete ===" -ForegroundColor Yellow