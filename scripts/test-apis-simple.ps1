#!/usr/bin/env pwsh

Write-Host "Testing new ticket APIs..." -ForegroundColor Green

# Wait for service to start
Start-Sleep -Seconds 3

# Login
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    Write-Host "Login successful" -ForegroundColor Green
} catch {
    Write-Host "Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test accept API
Write-Host "Testing accept API..." -ForegroundColor Cyan
try {
    $acceptData = @{ comment = "test accept" } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/3/accept" -Method POST -Body $acceptData -Headers $headers
    Write-Host "Accept API works!" -ForegroundColor Green
} catch {
    Write-Host "Accept API failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test reject API
Write-Host "Testing reject API..." -ForegroundColor Cyan
try {
    $rejectData = @{ comment = "test reject" } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/3/reject" -Method POST -Body $rejectData -Headers $headers
    Write-Host "Reject API works!" -ForegroundColor Green
} catch {
    Write-Host "Reject API failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "API testing completed" -ForegroundColor Green