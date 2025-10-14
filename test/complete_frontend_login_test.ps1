# Complete Frontend Login Test
Write-Host "=== Complete Frontend Login Test ===" -ForegroundColor Green

# Step 1: Test backend API directly
Write-Host "`n1. Testing backend API directly..." -ForegroundColor Yellow

try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $backendResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    Write-Host "Backend API Response:" -ForegroundColor Cyan
    Write-Host "Success: $($backendResponse.success)" -ForegroundColor White
    Write-Host "Has Data: $($backendResponse.data -ne $null)" -ForegroundColor White
    
    if ($backendResponse.success -and $backendResponse.data) {
        Write-Host "Token exists: $($backendResponse.data.token -ne $null)" -ForegroundColor White
        Write-Host "User exists: $($backendResponse.data.user -ne $null)" -ForegroundColor White
        Write-Host "User info: $($backendResponse.data.user.username) (ID: $($backendResponse.data.user.id))" -ForegroundColor White
        Write-Host "User roles: $($backendResponse.data.user.roles -join ', ')" -ForegroundColor White
        
        $testToken = $backendResponse.data.token
        Write-Host "Backend login: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "Backend login: FAILED - Invalid response format" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Backend login: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Check frontend configuration
Write-Host "`n2. Checking frontend configuration..." -ForegroundColor Yellow

$envContent = Get-Content "frontend/.env" -Raw
if ($envContent -match "VITE_API_BASE_URL=(.+)") {
    $frontendApiUrl = $matches[1].Trim()
    Write-Host "Frontend API URL: $frontendApiUrl" -ForegroundColor Cyan
    
    if ($frontendApiUrl -eq "http://localhost:8080") {
        Write-Host "API URL: CORRECT" -ForegroundColor Green
    } else {
        Write-Host "API URL: INCORRECT (should be http://localhost:8080)" -ForegroundColor Red
        Write-Host "Fixing API URL..." -ForegroundColor Yellow
        
        $newEnvContent = $envContent -replace "VITE_API_BASE_URL=.+", "VITE_API_BASE_URL=http://localhost:8080"
        Set-Content "frontend/.env" -Value $newEnvContent -Encoding UTF8
        Write-Host "API URL fixed. Please restart frontend server." -ForegroundColor Green
    }
}

# Step 3: Check if frontend server is running
Write-Host "`n3. Checking frontend server..." -ForegroundColor Yellow

try {
    $frontendCheck = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 3
    Write-Host "Frontend server: RUNNING" -ForegroundColor Green
} catch {
    Write-Host "Frontend server: NOT RUNNING" -ForegroundColor Red
    Write-Host "Please start frontend server:" -ForegroundColor Yellow
    Write-Host "  cd frontend" -ForegroundColor White
    Write-Host "  npm run dev" -ForegroundColor White
    exit 1
}

# Step 4: Test frontend API call simulation
Write-Host "`n4. Simulating frontend API call..." -ForegroundColor Yellow

try {
    # Simulate the exact call that frontend would make
    $frontendHeaders = @{
        "Content-Type" = "application/json"
        "Accept" = "application/json"
    }
    
    $frontendResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -Headers $frontendHeaders
    
    Write-Host "Frontend simulation response:" -ForegroundColor Cyan
    Write-Host ($frontendResponse | ConvertTo-Json -Depth 3) -ForegroundColor Gray
    
    # Test the exact logic that frontend uses
    if ($frontendResponse.success -and $frontendResponse.data) {
        $authData = $frontendResponse.data
        Write-Host "Frontend logic test: SUCCESS" -ForegroundColor Green
        Write-Host "Extracted token: $($authData.token.Substring(0, 20))..." -ForegroundColor White
        Write-Host "Extracted user: $($authData.user.username)" -ForegroundColor White
    } else {
        Write-Host "Frontend logic test: FAILED" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Frontend simulation: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Step 5: Check for common issues
Write-Host "`n5. Checking for common issues..." -ForegroundColor Yellow

# Check if there are any TypeScript compilation errors
if (Test-Path "frontend/src/stores/auth.ts") {
    $authContent = Get-Content "frontend/src/stores/auth.ts" -Raw
    
    # Check for variable name conflicts
    if ($authContent -match "loginData.*LoginRequest" -and $authContent -match "let loginData.*LoginResponse") {
        Write-Host "ISSUE FOUND: Variable name conflict in auth.ts" -ForegroundColor Red
        Write-Host "The parameter and local variable both use 'loginData'" -ForegroundColor Yellow
    } else {
        Write-Host "Variable naming: OK" -ForegroundColor Green
    }
    
    # Check for proper error handling
    if ($authContent -match "console\.log.*登录响应") {
        Write-Host "Debug logging: ENABLED" -ForegroundColor Green
    } else {
        Write-Host "Debug logging: MISSING" -ForegroundColor Yellow
    }
}

# Step 6: Browser testing instructions
Write-Host "`n6. Browser testing instructions..." -ForegroundColor Yellow
Write-Host "Now test in browser:" -ForegroundColor Cyan
Write-Host "1. Open http://localhost:3000" -ForegroundColor White
Write-Host "2. Open browser DevTools (F12)" -ForegroundColor White
Write-Host "3. Go to Console tab" -ForegroundColor White
Write-Host "4. Try logging in with admin/admin123" -ForegroundColor White
Write-Host "5. Check console for detailed debug logs" -ForegroundColor White

Write-Host "`n7. Expected console output:" -ForegroundColor Yellow
Write-Host "=== 开始登录流程 ===" -ForegroundColor Gray
Write-Host "发送登录请求到: /auth/login" -ForegroundColor Gray
Write-Host "=== 登录响应 ===" -ForegroundColor Gray
Write-Host "完整响应: {success: true, data: {...}}" -ForegroundColor Gray
Write-Host "=== 提取的认证数据 ===" -ForegroundColor Gray
Write-Host "token存在: true" -ForegroundColor Gray
Write-Host "user存在: true" -ForegroundColor Gray
Write-Host "=== 登录状态保存完成 ===" -ForegroundColor Gray

Write-Host "`n8. If login still fails:" -ForegroundColor Yellow
Write-Host "- Check browser console for JavaScript errors" -ForegroundColor White
Write-Host "- Check Network tab for API request details" -ForegroundColor White
Write-Host "- Clear browser cache and localStorage" -ForegroundColor White
Write-Host "- Restart frontend server after any changes" -ForegroundColor White

Write-Host "`n=== Test Complete ===" -ForegroundColor Green