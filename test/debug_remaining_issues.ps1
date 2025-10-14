#!/usr/bin/env pwsh
# Debug Remaining System Management Issues

$BaseUrl = "http://localhost:8080"
$Headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== Debug Remaining System Management Issues ===" -ForegroundColor Yellow
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

# Issue 1: System Health - missing check time and details
Write-Host "2. Analyzing System Health Response..." -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/system/health" -Method GET -Headers $AuthHeaders
    Write-Host "System Health Response Structure:" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 6) -ForegroundColor Gray
} catch {
    Write-Host "✗ System health failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Issue 2: System Config - still empty
Write-Host "3. Analyzing System Config Response..." -ForegroundColor Blue

# Create a test config first
$testConfig = @{
    category = "debug"
    key = "test_config"
    value = "test_value"
    description = "Debug test configuration"
    is_public = $true
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/config" -Method POST -Body $testConfig -Headers $AuthHeaders
    Write-Host "Create Config Response:" -ForegroundColor Cyan
    Write-Host ($createResponse | ConvertTo-Json -Depth 3) -ForegroundColor Gray
} catch {
    Write-Host "Create config error: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/config" -Method GET -Headers $AuthHeaders
    Write-Host "Get Config Response Structure:" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 4) -ForegroundColor Gray
} catch {
    Write-Host "✗ System config failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Issue 3: Announcements - status always inactive
Write-Host "4. Analyzing Announcements Status Issue..." -ForegroundColor Blue

$testAnnouncement = @{
    title = "Status Test Announcement"
    type = "info"
    priority = 1
    content = "Testing announcement status display."
    is_active = $true
    is_sticky = $false
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/announcements" -Method POST -Body $testAnnouncement -Headers $AuthHeaders
    Write-Host "Create Announcement Response:" -ForegroundColor Cyan
    Write-Host ($createResponse | ConvertTo-Json -Depth 3) -ForegroundColor Gray
    $testAnnouncementId = $createResponse.data.id
} catch {
    Write-Host "Create announcement error: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/announcements" -Method GET -Headers $AuthHeaders
    Write-Host "Get Announcements Response Structure:" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 4) -ForegroundColor Gray
} catch {
    Write-Host "✗ Get announcements failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Issue 4: Log cleanup not working
Write-Host "5. Testing Log Cleanup..." -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/logs/cleanup" -Method POST -Body '{"retentionDays": 30}' -Headers $AuthHeaders
    Write-Host "Log Cleanup Response:" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 3) -ForegroundColor Gray
} catch {
    Write-Host "Log cleanup error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $errorBody = $reader.ReadToEnd()
        Write-Host "Error details: $errorBody" -ForegroundColor Red
    }
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
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/config/debug/test_config" -Method DELETE -Headers $AuthHeaders
    Write-Host "✓ Test config deleted" -ForegroundColor Green
} catch {
    Write-Host "⚠ Delete config failed" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Analysis Complete ===" -ForegroundColor Yellow