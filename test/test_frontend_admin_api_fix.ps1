#!/usr/bin/env pwsh
# Test Frontend Admin API Fix

$BaseUrl = "http://localhost:8080"
$Headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== Frontend Admin API Fix Test ===" -ForegroundColor Yellow
Write-Host ""

# Login first
Write-Host "1. Login to get token..." -ForegroundColor Blue
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -Headers $Headers
    if ($loginResponse.success) {
        Write-Host "✓ Login success" -ForegroundColor Green
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

# Test admin APIs that frontend will call
Write-Host "2. Testing admin APIs..." -ForegroundColor Blue

# Test user management APIs
Write-Host "  Testing user management APIs:" -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/users" -Method GET -Headers $AuthHeaders
    if ($response.success) {
        Write-Host "    ✓ GET /admin/users - Success" -ForegroundColor Green
    }
} catch {
    Write-Host "    ✗ GET /admin/users - Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test role management APIs
Write-Host "  Testing role management APIs:" -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/roles" -Method GET -Headers $AuthHeaders
    if ($response.success) {
        Write-Host "    ✓ GET /admin/roles - Success" -ForegroundColor Green
    }
} catch {
    Write-Host "    ✗ GET /admin/roles - Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test permissions API (this should still work on the old path)
Write-Host "  Testing permissions APIs:" -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions" -Method GET -Headers $AuthHeaders
    if ($response.success) {
        Write-Host "    ✓ GET /permissions - Success" -ForegroundColor Green
    }
} catch {
    Write-Host "    ✗ GET /permissions - Failed: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions/tree" -Method GET -Headers $AuthHeaders
    if ($response.success) {
        Write-Host "    ✓ GET /permissions/tree - Success" -ForegroundColor Green
    }
} catch {
    Write-Host "    ✗ GET /permissions/tree - Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Yellow
Write-Host "Frontend admin interfaces should now work with the updated API paths!" -ForegroundColor Green
Write-Host ""
Write-Host "Updated API paths:" -ForegroundColor Cyan
Write-Host "  - User Management: /api/v1/admin/users" -ForegroundColor Gray
Write-Host "  - Role Management: /api/v1/admin/roles" -ForegroundColor Gray
Write-Host "  - Permissions: /api/v1/permissions (unchanged)" -ForegroundColor Gray