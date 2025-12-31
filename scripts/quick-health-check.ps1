# Quick System Health Check
Write-Host "=== QUICK SYSTEM HEALTH CHECK ===" -ForegroundColor Green

$errors = @()

# 1. Check server is running
Write-Host "1. Checking server status..." -ForegroundColor Cyan
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET -TimeoutSec 5
    Write-Host "   ✅ Server is running" -ForegroundColor Green
} catch {
    $errors += "Server not responding"
    Write-Host "   ❌ Server not responding" -ForegroundColor Red
}

# 2. Check admin login
Write-Host "2. Checking admin authentication..." -ForegroundColor Cyan
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json" -TimeoutSec 5
    Write-Host "   ✅ Admin authentication working" -ForegroundColor Green
    $token = $loginResponse.data.token
} catch {
    $errors += "Admin authentication failed"
    Write-Host "   ❌ Admin authentication failed" -ForegroundColor Red
}

# 3. Check ticket system
if ($token) {
    Write-Host "3. Checking ticket system..." -ForegroundColor Cyan
    try {
        $headers = @{ "Authorization" = "Bearer $token" }
        $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets?size=1" -Method GET -Headers $headers -TimeoutSec 5
        Write-Host "   ✅ Ticket system working ($($ticketsResponse.data.total) tickets)" -ForegroundColor Green
    } catch {
        $errors += "Ticket system not working"
        Write-Host "   ❌ Ticket system not working" -ForegroundColor Red
    }

    # 4. Check permissions
    Write-Host "4. Checking permission system..." -ForegroundColor Cyan
    try {
        $usersResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/users?size=1" -Method GET -Headers $headers -TimeoutSec 5
        Write-Host "   ✅ Permission system working" -ForegroundColor Green
    } catch {
        $errors += "Permission system not working"
        Write-Host "   ❌ Permission system not working" -ForegroundColor Red
    }
}

# 5. Check tiker user
Write-Host "5. Checking tiker user..." -ForegroundColor Cyan
try {
    $tikerLoginData = @{
        username = "tiker_test"
        password = "tiker123"
    } | ConvertTo-Json

    $tikerResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $tikerLoginData -ContentType "application/json" -TimeoutSec 5
    Write-Host "   ✅ Tiker user working" -ForegroundColor Green
} catch {
    # Try original tiker user
    try {
        $tikerLoginData2 = @{
            username = "tiker"
            password = "tiker123"
        } | ConvertTo-Json

        $tikerResponse2 = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $tikerLoginData2 -ContentType "application/json" -TimeoutSec 5
        Write-Host "   ✅ Tiker user working (original user)" -ForegroundColor Green
    } catch {
        $errors += "Tiker user not working"
        Write-Host "   ❌ Tiker user not working" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n=== HEALTH CHECK SUMMARY ===" -ForegroundColor Green
if ($errors.Count -eq 0) {
    Write-Host "🎉 ALL SYSTEMS OPERATIONAL" -ForegroundColor Green
    Write-Host "System is healthy and ready for use." -ForegroundColor Gray
    exit 0
} else {
    Write-Host "⚠️ ISSUES DETECTED:" -ForegroundColor Yellow
    $errors | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    Write-Host "Please check the system and resolve these issues." -ForegroundColor Gray
    exit 1
}