#!/usr/bin/env pwsh
# User Management API Test Script

$BaseUrl = "http://localhost:8080"
$Headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== User Management API Test ===" -ForegroundColor Yellow
Write-Host ""

# 1. Test get user list
Write-Host "1. Testing get user list..." -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/users" -Method GET -Headers $Headers
    
    if ($response.success) {
        Write-Host "✓ Get user list success" -ForegroundColor Green
        Write-Host "  Total users: $($response.data.total)" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Get user list failed: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Request failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 2. Test create user
Write-Host "2. Testing create user..." -ForegroundColor Blue

$userData = @{
    username = "testuser_$(Get-Date -Format 'yyyyMMddHHmmss')"
    email = "testuser_$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
    displayName = "Test User"
    password = "password123"
    status = "active"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/users" -Method POST -Body $userData -Headers $Headers
    
    if ($response.success) {
        Write-Host "✓ User creation success" -ForegroundColor Green
        Write-Host "  New user ID: $($response.data.id)" -ForegroundColor Cyan
        $newUserId = $response.data.id
    } else {
        Write-Host "✗ User creation failed: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Request failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 3. Test get single user
if ($newUserId) {
    Write-Host "3. Testing get single user..." -ForegroundColor Blue
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/users/$newUserId" -Method GET -Headers $Headers
        
        if ($response.success) {
            Write-Host "✓ Get user details success" -ForegroundColor Green
            Write-Host "  Username: $($response.data.username)" -ForegroundColor Cyan
        } else {
            Write-Host "✗ Get user details failed: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Request failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "=== Test Complete ===" -ForegroundColor Yellow
Write-Host "User management interface should work now" -ForegroundColor Green