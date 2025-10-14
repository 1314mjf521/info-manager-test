# Test Records API
Write-Host "=== Records API Test ===" -ForegroundColor Green

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

# Test different records API calls
Write-Host "1. Testing GET /records (no params)..." -ForegroundColor Yellow
try {
    $response1 = Invoke-RestMethod -Uri "$baseUrl/records" -Method GET -Headers $headers
    Write-Host "Success: $($response1.success)" -ForegroundColor Green
    Write-Host "Data type: $($response1.data.GetType().Name)" -ForegroundColor Gray
    Write-Host "Data count: $($response1.data.Count)" -ForegroundColor Gray
    Write-Host "Response structure: $($response1 | ConvertTo-Json -Depth 1)" -ForegroundColor Gray
} catch {
    Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "Status: $statusCode" -ForegroundColor Gray
    }
}

Write-Host "2. Testing GET /records with params..." -ForegroundColor Yellow
try {
    $response2 = Invoke-RestMethod -Uri "$baseUrl/records?page=1&page_size=20" -Method GET -Headers $headers
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

Write-Host "3. Testing what frontend sends..." -ForegroundColor Yellow
try {
    # Simulate frontend parameters
    $params = "search=&type=&page=1&page_size=20"
    $url = "$baseUrl/records?$params"
    Write-Host "URL: $url" -ForegroundColor Gray
    
    $response3 = Invoke-RestMethod -Uri $url -Method GET -Headers $headers
    Write-Host "Success: $($response3.success)" -ForegroundColor Green
    Write-Host "Data: $($response3.data | ConvertTo-Json -Depth 2)" -ForegroundColor Gray
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

Write-Host "Test completed" -ForegroundColor Green