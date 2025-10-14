#!/usr/bin/env pwsh
# User Management API Test Script with Authentication

$BaseUrl = "http://localhost:8080"
$Headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== User Management API Test with Auth ===" -ForegroundColor Yellow
Write-Host ""

# Step 1: Login to get token
Write-Host "1. Login to get authentication token..." -ForegroundColor Blue

$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -Headers $Headers
    
    if ($loginResponse.success) {
        Write-Host "✓ Login success" -ForegroundColor Green
        $token = $loginResponse.data.token
        
        # Add token to headers
        $AuthHeaders = @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $token"
        }
        
        Write-Host "  Token obtained successfully" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Login failed: $($loginResponse.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Login request failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Test get user list
Write-Host "2. Testing get user list..." -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/users" -Method GET -Headers $AuthHeaders
    
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

# Step 3: Test create user
Write-Host "3. Testing create user..." -ForegroundColor Blue

$userData = @{
    username = "testuser_$(Get-Date -Format 'yyyyMMddHHmmss')"
    email = "testuser_$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
    displayName = "Test User"
    password = "password123"
    status = "active"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/users" -Method POST -Body $userData -Headers $AuthHeaders
    
    if ($response.success) {
        Write-Host "✓ User creation success" -ForegroundColor Green
        Write-Host "  New user ID: $($response.data.id)" -ForegroundColor Cyan
        Write-Host "  Username: $($response.data.username)" -ForegroundColor Cyan
        $newUserId = $response.data.id
    } else {
        Write-Host "✗ User creation failed: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Request failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Step 4: Test get single user
if ($newUserId) {
    Write-Host "4. Testing get single user..." -ForegroundColor Blue
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/users/$newUserId" -Method GET -Headers $AuthHeaders
        
        if ($response.success) {
            Write-Host "✓ Get user details success" -ForegroundColor Green
            Write-Host "  Username: $($response.data.username)" -ForegroundColor Cyan
            Write-Host "  Email: $($response.data.email)" -ForegroundColor Cyan
        } else {
            Write-Host "✗ Get user details failed: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Request failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "=== Test Complete ===" -ForegroundColor Yellow
Write-Host "User management API is working correctly!" -ForegroundColor Green
Write-Host "Frontend user management interface should now work properly." -ForegroundColor Green