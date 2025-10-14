#!/usr/bin/env pwsh
# Debug User Creation API

$BaseUrl = "http://localhost:8080"
$Headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== Debug User Creation ===" -ForegroundColor Yellow
Write-Host ""

# Step 1: Login
Write-Host "1. Login..." -ForegroundColor Blue

$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -Headers $Headers
    
    if ($loginResponse.success) {
        Write-Host "✓ Login success" -ForegroundColor Green
        $token = $loginResponse.data.token
        
        $AuthHeaders = @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $token"
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

# Step 2: Test different user creation requests
Write-Host "2. Testing user creation with minimal data..." -ForegroundColor Blue

$userData1 = @{
    username = "testuser1"
    email = "testuser1@example.com"
    displayName = "Test User 1"
    password = "password123"
} | ConvertTo-Json

Write-Host "Request body:" -ForegroundColor Cyan
Write-Host $userData1 -ForegroundColor Gray

try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/api/v1/admin/users" -Method POST -Body $userData1 -Headers $AuthHeaders
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

# Step 3: Test with all fields
Write-Host "3. Testing user creation with all fields..." -ForegroundColor Blue

$userData2 = @{
    username = "testuser2"
    email = "testuser2@example.com"
    displayName = "Test User 2"
    password = "password123"
    status = "active"
    description = "Test user description"
} | ConvertTo-Json

Write-Host "Request body:" -ForegroundColor Cyan
Write-Host $userData2 -ForegroundColor Gray

try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/api/v1/admin/users" -Method POST -Body $userData2 -Headers $AuthHeaders
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
Write-Host "=== Debug Complete ===" -ForegroundColor Yellow