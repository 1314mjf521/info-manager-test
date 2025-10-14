# Debug Record Types API
Write-Host "=== Debug Record Types API ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080/api/v1"

# Get auth token
$loginData = '{"username":"admin","password":"admin123"}'
try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    Write-Host "Auth successful" -ForegroundColor Green
} catch {
    Write-Host "Auth failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test different API calls
Write-Host "1. Testing GET /record-types (no params)..." -ForegroundColor Yellow
try {
    $response1 = Invoke-RestMethod -Uri "$baseUrl/record-types" -Method GET -Headers $headers
    Write-Host "Success: $($response1.success)" -ForegroundColor Green
    Write-Host "Data count: $($response1.data.Count)" -ForegroundColor Gray
} catch {
    Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "Status: $statusCode" -ForegroundColor Gray
    }
}

Write-Host "2. Testing GET /record-types with page params..." -ForegroundColor Yellow
try {
    $response2 = Invoke-RestMethod -Uri "$baseUrl/record-types?page=1&size=20" -Method GET -Headers $headers
    Write-Host "Success: $($response2.success)" -ForegroundColor Green
    Write-Host "Data count: $($response2.data.Count)" -ForegroundColor Gray
} catch {
    Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "Status: $statusCode" -ForegroundColor Gray
        
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            Write-Host "Error body: $errorBody" -ForegroundColor Gray
        } catch {
            Write-Host "Could not read error body" -ForegroundColor Gray
        }
    }
}

Write-Host "3. Testing what frontend might send..." -ForegroundColor Yellow
try {
    # Simulate what frontend might send
    $frontendParams = @{
        page = 1
        size = 20
    }
    $queryString = ($frontendParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
    $url = "$baseUrl/record-types?$queryString"
    Write-Host "URL: $url" -ForegroundColor Gray
    
    $response3 = Invoke-RestMethod -Uri $url -Method GET -Headers $headers
    Write-Host "Success: $($response3.success)" -ForegroundColor Green
} catch {
    Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "Status: $statusCode" -ForegroundColor Gray
        
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            Write-Host "Error body: $errorBody" -ForegroundColor Gray
        } catch {
            Write-Host "Could not read error body" -ForegroundColor Gray
        }
    }
}

Write-Host "Debug completed" -ForegroundColor Green