# Simple MySQL API Test

Write-Host "Starting MySQL API Test..." -ForegroundColor Green

# Start server in background
Start-Process -FilePath "./build/info-management-system.exe" -WindowStyle Hidden
Start-Sleep -Seconds 10

# Test health check
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET
    Write-Host "Health check: OK" -ForegroundColor Green
} catch {
    Write-Host "Health check failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Login
try {
    $loginData = '{"username":"admin","password":"admin123"}'
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -ContentType "application/json" -Body $loginData
    $token = $loginResponse.data.token
    $headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }
    Write-Host "Login: OK" -ForegroundColor Green
} catch {
    Write-Host "Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get record types
try {
    $typesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/record-types" -Method GET -Headers $headers
    Write-Host "Record types: $($typesResponse.data.Count) found" -ForegroundColor Green
} catch {
    Write-Host "Get record types failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Get all records
try {
    $recordsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    Write-Host "Records: $($recordsResponse.data.total) found" -ForegroundColor Green
} catch {
    Write-Host "Get records failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "MySQL API Test Complete!" -ForegroundColor Green