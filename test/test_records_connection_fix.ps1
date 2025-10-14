# Test Records Connection Fix
Write-Host "=== Testing Records Connection Fix ===" -ForegroundColor Green

# Step 1: Verify backend is running
Write-Host "`n1. Verifying backend server..." -ForegroundColor Yellow

try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET -TimeoutSec 5
    Write-Host "✅ Backend health check: OK" -ForegroundColor Green
    Write-Host "Response: $($healthResponse | ConvertTo-Json -Compress)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Backend health check: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Please ensure backend server is running: go run cmd/server/main.go" -ForegroundColor Yellow
    exit 1
}

# Step 2: Test login API
Write-Host "`n2. Testing login API..." -ForegroundColor Yellow

try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.success -and $loginResponse.data.token) {
        Write-Host "✅ Login API: OK" -ForegroundColor Green
        $token = $loginResponse.data.token
    } else {
        Write-Host "❌ Login API: Invalid response" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Login API: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    exit 1
}

# Step 3: Test records API
Write-Host "`n3. Testing records API..." -ForegroundColor Yellow

try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    $recordsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    
    if ($recordsResponse.success) {
        Write-Host "✅ Records API: OK" -ForegroundColor Green
        Write-Host "Record count: $($recordsResponse.data.total)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Records API: Invalid response" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Records API: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 4: Check frontend configuration
Write-Host "`n4. Checking frontend configuration..." -ForegroundColor Yellow

$envContent = Get-Content "frontend/.env" -Raw
if ($envContent -match "VITE_API_BASE_URL=(.+)") {
    $frontendApiUrl = $matches[1].Trim()
    Write-Host "Frontend API URL: $frontendApiUrl" -ForegroundColor Cyan
    
    if ($frontendApiUrl -eq "http://localhost:8080") {
        Write-Host "✅ Frontend API URL: Correct" -ForegroundColor Green
    } else {
        Write-Host "❌ Frontend API URL: Incorrect" -ForegroundColor Red
        Write-Host "Expected: http://localhost:8080" -ForegroundColor Yellow
        Write-Host "Actual: $frontendApiUrl" -ForegroundColor Yellow
    }
}

# Step 5: Check frontend server
Write-Host "`n5. Checking frontend server..." -ForegroundColor Yellow

try {
    $frontendResponse = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 3
    Write-Host "✅ Frontend server: Running" -ForegroundColor Green
} catch {
    Write-Host "❌ Frontend server: Not running" -ForegroundColor Red
    Write-Host "Please start frontend server: cd frontend && npm run dev" -ForegroundColor Yellow
}

# Step 6: Create a simple test record for demonstration
Write-Host "`n6. Creating test record for demonstration..." -ForegroundColor Yellow

try {
    # First, get available record types
    $typesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/record-types" -Method GET -Headers $headers
    
    if ($typesResponse.success -and $typesResponse.data.Count -gt 0) {
        $firstType = $typesResponse.data[0]
        Write-Host "Using record type: $($firstType.name)" -ForegroundColor Cyan
        
        # Create a test record
        $testRecord = @{
            type = $firstType.name
            title = "Frontend Connection Test Record"
            content = @{
                description = "This record was created to test frontend-backend connectivity"
                status = "published"
                created_by_script = $true
                timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            tags = @("test", "connectivity", "frontend")
        } | ConvertTo-Json -Depth 10
        
        $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Body $testRecord -ContentType "application/json" -Headers $headers
        
        if ($createResponse.success) {
            Write-Host "✅ Test record created successfully" -ForegroundColor Green
            Write-Host "Record ID: $($createResponse.data.id)" -ForegroundColor Cyan
            Write-Host "Record Title: $($createResponse.data.title)" -ForegroundColor Cyan
        } else {
            Write-Host "⚠️ Failed to create test record" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️ No record types available" -ForegroundColor Yellow
        Write-Host "Records interface may show empty list" -ForegroundColor Gray
    }
} catch {
    Write-Host "⚠️ Could not create test record: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 7: Final verification
Write-Host "`n7. Final verification..." -ForegroundColor Yellow

try {
    $finalRecordsCheck = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    
    if ($finalRecordsCheck.success) {
        Write-Host "✅ Final records check: OK" -ForegroundColor Green
        Write-Host "Total records: $($finalRecordsCheck.data.total)" -ForegroundColor Cyan
        
        if ($finalRecordsCheck.data.total -gt 0) {
            Write-Host "Records available for frontend display:" -ForegroundColor Cyan
            foreach ($record in $finalRecordsCheck.data.records) {
                Write-Host "  - $($record.title) (Type: $($record.type), ID: $($record.id))" -ForegroundColor White
            }
        }
    }
} catch {
    Write-Host "❌ Final verification failed" -ForegroundColor Red
}

# Step 8: Instructions for user
Write-Host "`n=== Instructions ===" -ForegroundColor Green

Write-Host "The backend connection issue should now be fixed. Please:" -ForegroundColor White
Write-Host "1. Refresh your browser (Ctrl+F5 or Cmd+R)" -ForegroundColor Cyan
Write-Host "2. Go to http://localhost:3000" -ForegroundColor Cyan
Write-Host "3. Login with admin/admin123" -ForegroundColor Cyan
Write-Host "4. Navigate to Records Management" -ForegroundColor Cyan
Write-Host "5. The page should now load without connection errors" -ForegroundColor Cyan

Write-Host "`nIf you still see connection errors:" -ForegroundColor Yellow
Write-Host "- Check browser console (F12) for detailed error messages" -ForegroundColor White
Write-Host "- Ensure both frontend (3000) and backend (8080) servers are running" -ForegroundColor White
Write-Host "- Clear browser cache and localStorage" -ForegroundColor White

Write-Host "`n=== Fix Complete ===" -ForegroundColor Green