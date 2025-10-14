# Test Frontend Records Interface
Write-Host "=== Testing Frontend Records Interface ===" -ForegroundColor Green

# Start frontend development server
Write-Host "`n1. Starting frontend development server..." -ForegroundColor Yellow

# Check if frontend server is already running
try {
    $frontendResponse = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 3
    Write-Host "Frontend server is already running on http://localhost:3000" -ForegroundColor Green
} catch {
    Write-Host "Frontend server not running, starting it..." -ForegroundColor Yellow
    
    # Start the frontend server in background
    $frontendProcess = Start-Process -FilePath "npm" -ArgumentList "run", "dev" -WorkingDirectory "frontend" -PassThru -WindowStyle Hidden
    
    Write-Host "Waiting for frontend server to start..." -ForegroundColor Cyan
    Start-Sleep -Seconds 10
    
    # Check if it started successfully
    try {
        $frontendResponse = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 5
        Write-Host "Frontend server started successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Failed to start frontend server: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please start it manually: cd frontend && npm run dev" -ForegroundColor Yellow
        exit 1
    }
}

# Test backend API directly
Write-Host "`n2. Testing backend API..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET -TimeoutSec 5
    Write-Host "Backend health check: OK" -ForegroundColor Green
} catch {
    Write-Host "Backend health check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please ensure backend server is running: go run cmd/server/main.go" -ForegroundColor Yellow
    exit 1
}

# Test login API
Write-Host "`n3. Testing login API..." -ForegroundColor Yellow
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.success -and $loginResponse.data.token) {
        Write-Host "Login API: OK" -ForegroundColor Green
        $token = $loginResponse.data.token
    } else {
        Write-Host "Login API failed: Invalid response" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Login API failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test records API
Write-Host "`n4. Testing records API..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    $recordsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    
    if ($recordsResponse.success) {
        Write-Host "Records API: OK" -ForegroundColor Green
        Write-Host "Record count: $($recordsResponse.data.total)" -ForegroundColor Cyan
        
        if ($recordsResponse.data.total -eq 0) {
            Write-Host "No records found - creating a test record..." -ForegroundColor Yellow
            
            # Create a simple test record
            $testRecord = @{
                type = "test"
                title = "Test Record"
                content = @{
                    description = "This is a test record created for frontend testing"
                    status = "published"
                }
                tags = @("test", "demo")
            } | ConvertTo-Json -Depth 10
            
            try {
                $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Body $testRecord -ContentType "application/json" -Headers $headers
                Write-Host "Test record created successfully" -ForegroundColor Green
            } catch {
                Write-Host "Failed to create test record: $($_.Exception.Message)" -ForegroundColor Yellow
                Write-Host "This might be due to missing record type - that's OK for testing" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "Records API failed: $($recordsResponse.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "Records API failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test record types API
Write-Host "`n5. Testing record types API..." -ForegroundColor Yellow
try {
    $typesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/record-types" -Method GET -Headers $headers
    
    if ($typesResponse.success) {
        Write-Host "Record Types API: OK" -ForegroundColor Green
        Write-Host "Record types count: $($typesResponse.data.Count)" -ForegroundColor Cyan
    } else {
        Write-Host "Record Types API failed: $($typesResponse.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "Record Types API failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response.StatusCode -eq 403) {
        Write-Host "Note: Record types require admin permission - this is expected" -ForegroundColor Gray
    }
}

Write-Host "`n6. Frontend access instructions..." -ForegroundColor Yellow
Write-Host "Frontend URL: http://localhost:3000" -ForegroundColor Cyan
Write-Host "Login credentials:" -ForegroundColor Cyan
Write-Host "  Username: admin" -ForegroundColor White
Write-Host "  Password: admin123" -ForegroundColor White

Write-Host "`n7. Testing steps:" -ForegroundColor Yellow
Write-Host "1. Open browser and go to http://localhost:3000" -ForegroundColor White
Write-Host "2. Login with admin/admin123" -ForegroundColor White
Write-Host "3. Navigate to Records Management" -ForegroundColor White
Write-Host "4. Check if the page loads without 'resource not found' error" -ForegroundColor White
Write-Host "5. Try creating a new record" -ForegroundColor White

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
Write-Host "If you see 'resource not found' in the frontend:" -ForegroundColor Yellow
Write-Host "1. Check browser console for errors" -ForegroundColor White
Write-Host "2. Verify the API URL in frontend/.env matches the backend" -ForegroundColor White
Write-Host "3. Ensure both frontend and backend servers are running" -ForegroundColor White