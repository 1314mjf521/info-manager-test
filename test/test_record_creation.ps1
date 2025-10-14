# Test Record Creation Fix
Write-Host "=== Testing Record Creation Fix ===" -ForegroundColor Green

# Step 1: Login to get token
Write-Host "`n1. Logging in..." -ForegroundColor Yellow
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.success -and $loginResponse.data.token) {
        Write-Host "✅ Login successful" -ForegroundColor Green
        $token = $loginResponse.data.token
    } else {
        Write-Host "❌ Login failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Login error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Step 2: Get available record types
Write-Host "`n2. Getting record types..." -ForegroundColor Yellow
try {
    $typesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/record-types" -Method GET -Headers $headers
    
    if ($typesResponse.success -and $typesResponse.data.Count -gt 0) {
        Write-Host "✅ Found $($typesResponse.data.Count) record types" -ForegroundColor Green
        $firstType = $typesResponse.data[0]
        Write-Host "Using type: $($firstType.name) ($($firstType.display_name))" -ForegroundColor Cyan
    } else {
        Write-Host "❌ No record types found" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error getting record types: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Test record creation with correct format
Write-Host "`n3. Testing record creation..." -ForegroundColor Yellow

$testRecord = @{
    type = $firstType.name
    title = "Test Record - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    content = @{
        description = "This is a test record created to verify the fix"
        status = "published"
        test_field = "test_value"
    }
    tags = @("test", "fix-verification")
}

$recordJson = $testRecord | ConvertTo-Json -Depth 10
Write-Host "Request data:" -ForegroundColor Gray
Write-Host $recordJson -ForegroundColor Gray
Write-Host "Request size: $($recordJson.Length) bytes" -ForegroundColor Gray

try {
    $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Body $recordJson -Headers $headers
    
    if ($createResponse.success) {
        Write-Host "✅ Record created successfully!" -ForegroundColor Green
        Write-Host "Record ID: $($createResponse.data.id)" -ForegroundColor Cyan
        Write-Host "Record Title: $($createResponse.data.title)" -ForegroundColor Cyan
        Write-Host "Record Type: $($createResponse.data.type)" -ForegroundColor Cyan
        Write-Host "Record Version: $($createResponse.data.version)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Record creation failed: $($createResponse.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Record creation error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $errorStream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorStream)
        $errorBody = $reader.ReadToEnd()
        Write-Host "Error details: $errorBody" -ForegroundColor Yellow
    }
}

# Step 4: Test with minimal data
Write-Host "`n4. Testing with minimal data..." -ForegroundColor Yellow

$minimalRecord = @{
    type = $firstType.name
    title = "Minimal Test Record"
    content = @{
        description = "Minimal test"
    }
    tags = @()
}

$minimalJson = $minimalRecord | ConvertTo-Json -Depth 10
Write-Host "Minimal request size: $($minimalJson.Length) bytes" -ForegroundColor Gray

try {
    $minimalResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Body $minimalJson -Headers $headers
    
    if ($minimalResponse.success) {
        Write-Host "✅ Minimal record created successfully!" -ForegroundColor Green
        Write-Host "Record ID: $($minimalResponse.data.id)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Minimal record creation failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Minimal record creation error: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 5: Verify records were created
Write-Host "`n5. Verifying created records..." -ForegroundColor Yellow
try {
    $recordsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    
    if ($recordsResponse.success) {
        Write-Host "✅ Current record count: $($recordsResponse.data.total)" -ForegroundColor Green
        
        # Show recent records
        foreach ($record in $recordsResponse.data.records | Select-Object -First 3) {
            Write-Host "  - $($record.title) (ID: $($record.id), Type: $($record.type))" -ForegroundColor White
        }
    }
} catch {
    Write-Host "❌ Error verifying records: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
Write-Host "Frontend record creation should now work properly." -ForegroundColor Yellow
Write-Host "Try creating a record in the browser interface." -ForegroundColor Yellow