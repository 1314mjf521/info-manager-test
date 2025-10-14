# Backend Service Diagnosis and Fix
Write-Host "=== Backend Service Diagnosis and Fix ===" -ForegroundColor Green

# Step 1: Check if backend process is running
Write-Host "`n1. Checking if backend process is running..." -ForegroundColor Yellow

$backendProcess = Get-Process | Where-Object { $_.ProcessName -like "*main*" -or $_.ProcessName -like "*server*" -or $_.ProcessName -like "*go*" }
if ($backendProcess) {
    Write-Host "Found potential backend processes:" -ForegroundColor Cyan
    $backendProcess | ForEach-Object {
        Write-Host "  Process: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor White
    }
} else {
    Write-Host "No backend processes found" -ForegroundColor Red
}

# Step 2: Test port 8080 connectivity
Write-Host "`n2. Testing port 8080 connectivity..." -ForegroundColor Yellow

$portTest = Test-NetConnection -ComputerName "localhost" -Port 8080 -WarningAction SilentlyContinue
if ($portTest.TcpTestSucceeded) {
    Write-Host "Port 8080: OPEN" -ForegroundColor Green
} else {
    Write-Host "Port 8080: CLOSED" -ForegroundColor Red
    Write-Host "Backend server is not running on port 8080" -ForegroundColor Yellow
}

# Step 3: Try different backend URLs
Write-Host "`n3. Testing different backend URLs..." -ForegroundColor Yellow

$testUrls = @(
    "http://localhost:8080/health",
    "http://127.0.0.1:8080/health",
    "http://localhost:8080/api/v1/health",
    "http://localhost:8080/ready"
)

$workingUrl = $null
foreach ($url in $testUrls) {
    Write-Host "Testing: $url" -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri $url -Method GET -TimeoutSec 3
        Write-Host "SUCCESS: $url is accessible" -ForegroundColor Green
        Write-Host "Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
        $workingUrl = $url
        break
    } catch {
        Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if (-not $workingUrl) {
    Write-Host "`n❌ Backend server is not accessible" -ForegroundColor Red
    Write-Host "`n4. Starting backend server..." -ForegroundColor Yellow
    
    # Check if Go is installed
    try {
        $goVersion = go version
        Write-Host "Go version: $goVersion" -ForegroundColor Green
        
        # Check if main.go exists
        if (Test-Path "cmd/server/main.go") {
            Write-Host "Found main.go file" -ForegroundColor Green
            
            Write-Host "Starting backend server..." -ForegroundColor Cyan
            Write-Host "Command: go run cmd/server/main.go" -ForegroundColor Gray
            
            # Start backend server in background
            $backendJob = Start-Job -ScriptBlock {
                Set-Location $using:PWD
                go run cmd/server/main.go
            }
            
            Write-Host "Backend server job started (Job ID: $($backendJob.Id))" -ForegroundColor Green
            Write-Host "Waiting for server to start..." -ForegroundColor Cyan
            
            # Wait and test
            for ($i = 1; $i -le 10; $i++) {
                Start-Sleep -Seconds 2
                Write-Host "Attempt $i/10..." -ForegroundColor Gray
                
                try {
                    $testResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET -TimeoutSec 3
                    Write-Host "✅ Backend server started successfully!" -ForegroundColor Green
                    Write-Host "Health check response: $($testResponse | ConvertTo-Json -Compress)" -ForegroundColor Gray
                    $workingUrl = "http://localhost:8080"
                    break
                } catch {
                    Write-Host "Still starting..." -ForegroundColor Yellow
                }
            }
            
            if (-not $workingUrl) {
                Write-Host "❌ Backend server failed to start within 20 seconds" -ForegroundColor Red
                Write-Host "Checking job output..." -ForegroundColor Yellow
                
                $jobOutput = Receive-Job -Job $backendJob
                if ($jobOutput) {
                    Write-Host "Backend output:" -ForegroundColor Cyan
                    Write-Host $jobOutput -ForegroundColor Gray
                }
                
                Write-Host "`nManual start instructions:" -ForegroundColor Yellow
                Write-Host "1. Open a new terminal/command prompt" -ForegroundColor White
                Write-Host "2. Navigate to project directory" -ForegroundColor White
                Write-Host "3. Run: go run cmd/server/main.go" -ForegroundColor White
                Write-Host "4. Wait for 'Starting server on port 8080' message" -ForegroundColor White
            }
            
        } else {
            Write-Host "❌ main.go file not found at cmd/server/main.go" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "❌ Go is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Please install Go from https://golang.org/dl/" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n✅ Backend server is accessible at: $workingUrl" -ForegroundColor Green
}

# Step 4: Test API endpoints if backend is running
if ($workingUrl) {
    Write-Host "`n5. Testing API endpoints..." -ForegroundColor Yellow
    
    # Test login endpoint
    try {
        $loginData = @{
            username = "admin"
            password = "admin123"
        } | ConvertTo-Json
        
        $baseUrl = $workingUrl -replace "/health", "" -replace "/ready", ""
        $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        
        if ($loginResponse.success) {
            Write-Host "✅ Login API: Working" -ForegroundColor Green
            $token = $loginResponse.data.token
            
            # Test records endpoint
            $headers = @{ "Authorization" = "Bearer $token" }
            $recordsResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/records" -Method GET -Headers $headers
            
            if ($recordsResponse.success) {
                Write-Host "✅ Records API: Working" -ForegroundColor Green
                Write-Host "Record count: $($recordsResponse.data.total)" -ForegroundColor Cyan
            } else {
                Write-Host "⚠️ Records API: Failed" -ForegroundColor Yellow
            }
        } else {
            Write-Host "⚠️ Login API: Failed" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ API test failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Step 5: Fix frontend configuration
Write-Host "`n6. Checking and fixing frontend configuration..." -ForegroundColor Yellow

if ($workingUrl) {
    $baseUrl = $workingUrl -replace "/health", "" -replace "/ready", ""
    
    # Update frontend .env file
    if (Test-Path "frontend/.env") {
        $envContent = Get-Content "frontend/.env" -Raw
        $newEnvContent = $envContent -replace "VITE_API_BASE_URL=.*", "VITE_API_BASE_URL=$baseUrl"
        
        if ($envContent -ne $newEnvContent) {
            Set-Content "frontend/.env" -Value $newEnvContent -Encoding UTF8
            Write-Host "✅ Updated frontend/.env with correct API URL: $baseUrl" -ForegroundColor Green
        } else {
            Write-Host "✅ Frontend/.env already has correct API URL" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠️ Frontend/.env file not found" -ForegroundColor Yellow
    }
}

# Step 6: Test frontend server
Write-Host "`n7. Checking frontend server..." -ForegroundColor Yellow

try {
    $frontendResponse = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 3
    Write-Host "✅ Frontend server: Running" -ForegroundColor Green
} catch {
    Write-Host "❌ Frontend server: Not running" -ForegroundColor Red
    Write-Host "Please start frontend server:" -ForegroundColor Yellow
    Write-Host "  cd frontend" -ForegroundColor White
    Write-Host "  npm run dev" -ForegroundColor White
}

# Step 7: Summary and next steps
Write-Host "`n=== Summary ===" -ForegroundColor Green

if ($workingUrl) {
    Write-Host "✅ Backend Status: RUNNING" -ForegroundColor Green
    Write-Host "✅ Backend URL: $workingUrl" -ForegroundColor Cyan
    Write-Host "✅ Frontend should now be able to connect" -ForegroundColor Green
    
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Refresh your browser page (Ctrl+F5)" -ForegroundColor White
    Write-Host "2. Try logging in with admin/admin123" -ForegroundColor White
    Write-Host "3. Check that record management page loads properly" -ForegroundColor White
} else {
    Write-Host "❌ Backend Status: NOT RUNNING" -ForegroundColor Red
    Write-Host "`nTo fix this:" -ForegroundColor Yellow
    Write-Host "1. Open a new terminal" -ForegroundColor White
    Write-Host "2. Navigate to your project directory" -ForegroundColor White
    Write-Host "3. Run: go run cmd/server/main.go" -ForegroundColor White
    Write-Host "4. Wait for server to start" -ForegroundColor White
    Write-Host "5. Run this script again to verify" -ForegroundColor White
}

Write-Host "`n=== Diagnosis Complete ===" -ForegroundColor Green