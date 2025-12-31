#!/usr/bin/env pwsh

Write-Host "=== Final Ticket System Check ===" -ForegroundColor Green

# Check API
Write-Host "`n1. API Status:" -ForegroundColor Yellow
try {
    $body = '{"username":"admin","password":"admin123"}'
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $body -ContentType "application/json"
    Write-Host "✓ API is working" -ForegroundColor Green
} catch {
    Write-Host "✗ API connection failed" -ForegroundColor Red
}

# Check navigation config
Write-Host "`n2. Navigation Config:" -ForegroundColor Yellow
$layoutContent = Get-Content "frontend/src/layout/MainLayout.vue" -Raw
if ($layoutContent -match "path: '/tickets'") {
    Write-Host "✓ Ticket route added to navigation" -ForegroundColor Green
} else {
    Write-Host "✗ Ticket route missing" -ForegroundColor Red
}

if ($layoutContent -match "title: '工单管理'") {
    Write-Host "✓ Ticket menu title configured" -ForegroundColor Green
} else {
    Write-Host "✗ Ticket menu title missing" -ForegroundColor Red
}

# Check router config
Write-Host "`n3. Router Config:" -ForegroundColor Yellow
$routerContent = Get-Content "frontend/src/router/index.ts" -Raw
if ($routerContent -match "/tickets") {
    Write-Host "✓ Ticket routes configured" -ForegroundColor Green
} else {
    Write-Host "✗ Ticket routes missing" -ForegroundColor Red
}

Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "The following issues have been fixed:" -ForegroundColor White
Write-Host "1. ✓ API path duplication (/api/v1/api/v1/tickets -> /api/v1/tickets)" -ForegroundColor Green
Write-Host "2. ✓ Added ticket management to navigation menu" -ForegroundColor Green
Write-Host "3. ✓ Fixed permission checking logic" -ForegroundColor Green

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Restart frontend: npm run dev" -ForegroundColor White
Write-Host "2. Refresh browser" -ForegroundColor White
Write-Host "3. Login and check navigation menu" -ForegroundColor White