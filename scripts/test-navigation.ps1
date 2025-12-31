#!/usr/bin/env pwsh

Write-Host "=== Testing Ticket Navigation Fix ===" -ForegroundColor Green

# 1. Test API
Write-Host "`n1. Testing API connection..." -ForegroundColor Yellow

try {
    # Test login
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.token) {
        Write-Host "✓ Login successful" -ForegroundColor Green
        $token = $loginResponse.token
        
        # Test ticket API
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        
        $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $headers
        Write-Host "✓ Ticket API working" -ForegroundColor Green
        
        # Test user permissions
        $userResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/profile" -Method GET -Headers $headers
        Write-Host "✓ User API working" -ForegroundColor Green
        
    } else {
        Write-Host "✗ Login failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ API connection failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please make sure server is running (run .\start.bat)" -ForegroundColor Yellow
    exit 1
}

# 2. Check frontend navigation
Write-Host "`n2. Checking frontend navigation..." -ForegroundColor Yellow

$layoutFile = "frontend/src/layout/MainLayout.vue"
if (Test-Path $layoutFile) {
    $content = Get-Content $layoutFile -Raw
    if ($content -match "tickets") {
        Write-Host "✓ Navigation menu includes tickets" -ForegroundColor Green
    } else {
        Write-Host "✗ Navigation menu missing tickets" -ForegroundColor Red
    }
    
    if ($content -match "ticket:view") {
        Write-Host "✓ Ticket permission configured" -ForegroundColor Green
    } else {
        Write-Host "✗ Ticket permission not configured" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Layout file not found" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
Write-Host "If all checks pass, please:" -ForegroundColor Yellow
Write-Host "1. Restart frontend dev server (npm run dev)" -ForegroundColor White
Write-Host "2. Refresh browser page" -ForegroundColor White
Write-Host "3. Check if ticket management appears in navigation" -ForegroundColor White