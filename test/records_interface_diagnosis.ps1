# Records Interface Diagnosis
Write-Host "=== Records Management Interface Diagnosis ===" -ForegroundColor Green

# Step 1: Test login and get token
Write-Host "`n1. Getting authentication token..." -ForegroundColor Yellow

try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.success -and $loginResponse.data.token) {
        $token = $loginResponse.data.token
        Write-Host "Authentication: SUCCESS" -ForegroundColor Green
        Write-Host "Token: $($token.Substring(0, 20))..." -ForegroundColor Cyan
    } else {
        Write-Host "Authentication: FAILED" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Authentication: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Step 2: Test all records-related endpoints
Write-Host "`n2. Testing records API endpoints..." -ForegroundColor Yellow

$endpoints = @(
    @{ name = "Records List"; url = "/api/v1/records"; method = "GET" },
    @{ name = "Record Types"; url = "/api/v1/record-types"; method = "GET" },
    @{ name = "Health Check"; url = "/health"; method = "GET"; noAuth = $true }
)

foreach ($endpoint in $endpoints) {
    Write-Host "`nTesting: $($endpoint.name)" -ForegroundColor Cyan
    Write-Host "URL: http://localhost:8080$($endpoint.url)" -ForegroundColor Gray
    
    try {
        $testHeaders = if ($endpoint.noAuth) { @{} } else { $headers }
        $response = Invoke-RestMethod -Uri "http://localhost:8080$($endpoint.url)" -Method $endpoint.method -Headers $testHeaders
        
        Write-Host "Status: SUCCESS" -ForegroundColor Green
        Write-Host "Response type: $($response.GetType().Name)" -ForegroundColor White
        
        if ($response.success -ne $null) {
            Write-Host "Success field: $($response.success)" -ForegroundColor White
            if ($response.data -ne $null) {
                Write-Host "Data field exists: True" -ForegroundColor White
                if ($response.data.GetType().Name -eq "Object[]") {
                    Write-Host "Data is array with $($response.data.Count) items" -ForegroundColor White
                } elseif ($response.data.records -ne $null) {
                    Write-Host "Records array with $($response.data.records.Count) items" -ForegroundColor White
                    Write-Host "Total records: $($response.data.total)" -ForegroundColor White
                }
            }
        }
        
        # Show first few lines of response
        $responseJson = $response | ConvertTo-Json -Depth 2 -Compress
        $preview = if ($responseJson.Length -gt 200) { $responseJson.Substring(0, 200) + "..." } else { $responseJson }
        Write-Host "Response preview: $preview" -ForegroundColor Gray
        
    } catch {
        Write-Host "Status: FAILED" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            Write-Host "HTTP Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
            
            try {
                $errorStream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($errorStream)
                $errorBody = $reader.ReadToEnd()
                Write-Host "Error Body: $errorBody" -ForegroundColor Yellow
            } catch {
                Write-Host "Could not read error body" -ForegroundColor Gray
            }
        }
    }
}

# Step 3: Test specific record operations
Write-Host "`n3. Testing record operations..." -ForegroundColor Yellow

# Try to create a simple record first
Write-Host "`nTesting record creation..." -ForegroundColor Cyan

try {
    # Get available record types first
    $typesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/record-types" -Method GET -Headers $headers
    
    if ($typesResponse.success -and $typesResponse.data -and $typesResponse.data.Count -gt 0) {
        $firstType = $typesResponse.data[0]
        Write-Host "Using record type: $($firstType.name)" -ForegroundColor White
        
        $newRecord = @{
            type = $firstType.name
            title = "Test Record for Interface"
            content = @{
                description = "This is a test record created for interface testing"
                status = "published"
                test_field = "test_value"
            }
            tags = @("test", "interface", "diagnosis")
        } | ConvertTo-Json -Depth 10
        
        $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Body $newRecord -Headers $headers
        
        if ($createResponse.success) {
            Write-Host "Record creation: SUCCESS" -ForegroundColor Green
            Write-Host "Created record ID: $($createResponse.data.id)" -ForegroundColor White
            
            # Test getting the specific record
            $recordId = $createResponse.data.id
            $getResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records/$recordId" -Method GET -Headers $headers
            
            if ($getResponse.success) {
                Write-Host "Record retrieval: SUCCESS" -ForegroundColor Green
            } else {
                Write-Host "Record retrieval: FAILED" -ForegroundColor Red
            }
        } else {
            Write-Host "Record creation: FAILED" -ForegroundColor Red
        }
        
    } else {
        Write-Host "No record types available for testing" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Record operations: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Step 4: Check frontend API configuration
Write-Host "`n4. Checking frontend configuration..." -ForegroundColor Yellow

$frontendFiles = @(
    "frontend/src/config/api.ts",
    "frontend/src/utils/request.ts",
    "frontend/src/views/records/RecordListView.vue"
)

foreach ($file in $frontendFiles) {
    if (Test-Path $file) {
        Write-Host "Checking: $file" -ForegroundColor Cyan
        
        $content = Get-Content $file -Raw
        
        # Check API endpoints
        if ($content -match "RECORDS.*LIST.*['\`"]([^'\`"]+)['\`"]") {
            Write-Host "Records endpoint: $($matches[1])" -ForegroundColor White
        }
        
        # Check base URL
        if ($content -match "BASE_URL.*['\`"]([^'\`"]+)['\`"]") {
            Write-Host "Base URL: $($matches[1])" -ForegroundColor White
        }
        
        # Check for localhost references
        if ($content -match "localhost:8080") {
            Write-Host "Uses localhost:8080: YES" -ForegroundColor Green
        } elseif ($content -match "192\.168\.100\.15") {
            Write-Host "Uses 192.168.100.15: YES (should be localhost)" -ForegroundColor Red
        }
        
    } else {
        Write-Host "File not found: $file" -ForegroundColor Red
    }
}

# Step 5: Browser testing instructions
Write-Host "`n5. Browser debugging instructions..." -ForegroundColor Yellow
Write-Host "To debug the frontend issue:" -ForegroundColor Cyan
Write-Host "1. Open http://localhost:3000 and login" -ForegroundColor White
Write-Host "2. Open DevTools (F12) -> Network tab" -ForegroundColor White
Write-Host "3. Navigate to Records Management" -ForegroundColor White
Write-Host "4. Look for failed API requests (red entries)" -ForegroundColor White
Write-Host "5. Click on failed requests to see details" -ForegroundColor White
Write-Host "6. Check Console tab for JavaScript errors" -ForegroundColor White

Write-Host "`n6. Expected API calls:" -ForegroundColor Yellow
Write-Host "- GET http://localhost:8080/api/v1/records" -ForegroundColor White
Write-Host "- GET http://localhost:8080/api/v1/record-types" -ForegroundColor White
Write-Host "- Both should return 200 status with JSON data" -ForegroundColor White

Write-Host "`n7. Common issues to check:" -ForegroundColor Yellow
Write-Host "- Wrong API URL in frontend config" -ForegroundColor White
Write-Host "- Missing Authorization header" -ForegroundColor White
Write-Host "- CORS issues" -ForegroundColor White
Write-Host "- Network connectivity problems" -ForegroundColor White
Write-Host "- Backend server not running" -ForegroundColor White

Write-Host "`n=== Diagnosis Complete ===" -ForegroundColor Green