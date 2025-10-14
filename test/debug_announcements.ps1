#!/usr/bin/env pwsh
# Debug Announcements API

$BaseUrl = "http://localhost:8080"
$Headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== Debug Announcements API ===" -ForegroundColor Yellow
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

# Test get announcements with detailed error handling
Write-Host "2. Testing get announcements with detailed error..." -ForegroundColor Blue
try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/api/v1/announcements" -Method GET -Headers $AuthHeaders
    Write-Host "✓ Success: $($response.StatusCode)" -ForegroundColor Green
    $responseData = $response.Content | ConvertFrom-Json
    Write-Host "Response: $($responseData | ConvertTo-Json -Depth 3)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ Failed: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $errorBody = $reader.ReadToEnd()
        Write-Host "Error response: $errorBody" -ForegroundColor Red
    }
}

Write-Host ""

# Test create announcement
Write-Host "3. Testing create announcement..." -ForegroundColor Blue
$testAnnouncement = @{
    title = "Debug Test Announcement"
    type = "info"
    priority = 1
    content = "This is a debug test announcement."
    is_active = $true
    is_sticky = $false
} | ConvertTo-Json

Write-Host "Request body:" -ForegroundColor Cyan
Write-Host $testAnnouncement -ForegroundColor Gray

try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/api/v1/announcements" -Method POST -Body $testAnnouncement -Headers $AuthHeaders
    Write-Host "✓ Success: $($response.StatusCode)" -ForegroundColor Green
    $responseData = $response.Content | ConvertFrom-Json
    Write-Host "Response: $($responseData | ConvertTo-Json -Depth 3)" -ForegroundColor Cyan
    $testAnnouncementId = $responseData.data.id
} catch {
    Write-Host "✗ Failed: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $errorBody = $reader.ReadToEnd()
        Write-Host "Error response: $errorBody" -ForegroundColor Red
    }
}

Write-Host ""

# Test get announcements again after creating one
Write-Host "4. Testing get announcements after creation..." -ForegroundColor Blue
try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/api/v1/announcements" -Method GET -Headers $AuthHeaders
    Write-Host "✓ Success: $($response.StatusCode)" -ForegroundColor Green
    $responseData = $response.Content | ConvertFrom-Json
    Write-Host "Response: $($responseData | ConvertTo-Json -Depth 3)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ Failed: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $errorBody = $reader.ReadToEnd()
        Write-Host "Error response: $errorBody" -ForegroundColor Red
    }
}

Write-Host ""

# Cleanup
if ($testAnnouncementId) {
    Write-Host "5. Cleaning up..." -ForegroundColor Blue
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/announcements/$testAnnouncementId" -Method DELETE -Headers $AuthHeaders
        Write-Host "✓ Test announcement deleted" -ForegroundColor Green
    } catch {
        Write-Host "✗ Delete failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Debug Complete ===" -ForegroundColor Yellow