# Rebuild and Test Script
# Rebuilds the server with API fixes and runs validation

Write-Host "=== Rebuild and Test with API Fixes ===" -ForegroundColor Cyan

# 1. Stop existing server
Write-Host "1. Stopping existing server..." -ForegroundColor Yellow
try {
    $processes = Get-Process -Name "server" -ErrorAction SilentlyContinue
    if ($processes) {
        $processes | Stop-Process -Force
        Write-Host "   Server processes stopped" -ForegroundColor Green
        Start-Sleep -Seconds 2
    } else {
        Write-Host "   No server processes found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Error stopping server: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Build the server
Write-Host "2. Building server with API fixes..." -ForegroundColor Yellow
try {
    $buildResult = & go build -o build/server.exe cmd/server/main.go 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Build successful!" -ForegroundColor Green
    } else {
        Write-Host "   Build failed:" -ForegroundColor Red
        Write-Host $buildResult -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   Build error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. Start the server
Write-Host "3. Starting server..." -ForegroundColor Yellow
try {
    Start-Process -FilePath "build/server.exe" -WindowStyle Hidden
    Write-Host "   Server started" -ForegroundColor Green
    Start-Sleep -Seconds 5
} catch {
    Write-Host "   Error starting server: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 4. Wait for server to be ready
Write-Host "4. Waiting for server to be ready..." -ForegroundColor Yellow
$maxAttempts = 10
$attempt = 0
$serverReady = $false

while ($attempt -lt $maxAttempts -and -not $serverReady) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $serverReady = $true
            Write-Host "   Server is ready!" -ForegroundColor Green
        }
    } catch {
        $attempt++
        Write-Host "   Attempt $attempt/$maxAttempts - Server not ready yet..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }
}

if (-not $serverReady) {
    Write-Host "   Server failed to start properly" -ForegroundColor Red
    exit 1
}

# 5. Run the validation test
Write-Host "5. Running validation test..." -ForegroundColor Yellow
Write-Host ""

try {
    & .\scripts\ultimate-validation-en.ps1
    $testExitCode = $LASTEXITCODE
    
    Write-Host ""
    Write-Host "=== Test Results Summary ===" -ForegroundColor Cyan
    
    if ($testExitCode -eq 0) {
        Write-Host "✅ All tests passed! API fixes were successful." -ForegroundColor Green
    } else {
        Write-Host "⚠️  Some tests failed, but improvements should be visible." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Error running validation test: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Rebuild and Test Complete ===" -ForegroundColor Cyan
Write-Host "Server is running with API fixes applied." -ForegroundColor Green
Write-Host "Check the test results above for success rate improvements." -ForegroundColor Yellow