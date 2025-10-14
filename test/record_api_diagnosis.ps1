# Record API Diagnosis Script
Write-Host "=== Record Management API Diagnosis ===" -ForegroundColor Green

# Test different possible backend URLs
$possibleUrls = @(
    "http://localhost:8080",
    "http://127.0.0.1:8080", 
    "http://192.168.100.15:8080"
)

$workingUrl = $null

Write-Host "`n1. Testing backend server connectivity..." -ForegroundColor Yellow

foreach ($url in $possibleUrls) {
    Write-Host "Testing: $url" -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri "$url/health" -Method GET -TimeoutSec 5
        Write-Host "SUCCESS: $url is accessible" -ForegroundColor Green
        Write-Host "Response: $($response | ConvertTo-Json -Depth 2)" -ForegroundColor Gray
        $workingUrl = $url
        break
    } catch {
        Write-Host "FAILED: $url - $($_.Exception.Message)" -ForegroundColor Red
    }
}

if (-not $workingUrl) {
    Write-Host "`nNo backend server found. Please start the backend server first." -ForegroundColor Red
    Write-Host "Run: go run cmd/server/main.go" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n2. Testing API endpoints..." -ForegroundColor Yellow

# Test login
Write-Host "Testing login endpoint..." -ForegroundColor Cyan
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "$workingUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.success -and $loginResponse.data.token) {
        Write-Host "LOGIN SUCCESS: Token obtained" -ForegroundColor Green
        $token = $loginResponse.data.token
        
        # Test records endpoint
        Write-Host "Testing records endpoint..." -ForegroundColor Cyan
        $headers = @{
            "Authorization" = "Bearer $token"
        }
        
        try {
            $recordsResponse = Invoke-RestMethod -Uri "$workingUrl/api/v1/records" -Method GET -Headers $headers
            Write-Host "RECORDS SUCCESS: API is working" -ForegroundColor Green
            Write-Host "Records data structure:" -ForegroundColor Gray
            Write-Host ($recordsResponse | ConvertTo-Json -Depth 3) -ForegroundColor Gray
            
            # Test record types endpoint
            Write-Host "Testing record types endpoint..." -ForegroundColor Cyan
            try {
                $typesResponse = Invoke-RestMethod -Uri "$workingUrl/api/v1/record-types" -Method GET -Headers $headers
                Write-Host "RECORD TYPES SUCCESS" -ForegroundColor Green
                Write-Host "Types data:" -ForegroundColor Gray
                Write-Host ($typesResponse | ConvertTo-Json -Depth 2) -ForegroundColor Gray
            } catch {
                Write-Host "RECORD TYPES FAILED: $($_.Exception.Message)" -ForegroundColor Red
                if ($_.Exception.Response.StatusCode -eq 403) {
                    Write-Host "Note: Record types require admin permission" -ForegroundColor Yellow
                }
            }
            
        } catch {
            Write-Host "RECORDS FAILED: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
            
            if ($_.Exception.Response) {
                $errorStream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($errorStream)
                $errorBody = $reader.ReadToEnd()
                Write-Host "Error Body: $errorBody" -ForegroundColor Yellow
            }
        }
        
    } else {
        Write-Host "LOGIN FAILED: Invalid response format" -ForegroundColor Red
        Write-Host "Response: $($loginResponse | ConvertTo-Json)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "LOGIN FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
}

Write-Host "`n3. Frontend configuration check..." -ForegroundColor Yellow

# Check frontend API configuration
$frontendApiConfig = Get-Content "frontend/src/config/api.ts" -Raw
if ($frontendApiConfig -match "BASE_URL.*?'([^']+)'") {
    $frontendBaseUrl = $matches[1]
    Write-Host "Frontend BASE_URL: $frontendBaseUrl" -ForegroundColor Cyan
    
    if ($frontendBaseUrl -ne $workingUrl) {
        Write-Host "MISMATCH: Frontend is configured for $frontendBaseUrl but backend is at $workingUrl" -ForegroundColor Red
        Write-Host "Recommendation: Update frontend/src/config/api.ts" -ForegroundColor Yellow
    } else {
        Write-Host "MATCH: Frontend and backend URLs are aligned" -ForegroundColor Green
    }
}

Write-Host "`n4. Database check..." -ForegroundColor Yellow

# Check if database file exists
if (Test-Path "data/info_system.db") {
    Write-Host "Database file exists: data/info_system.db" -ForegroundColor Green
    
    # Get file size
    $dbSize = (Get-Item "data/info_system.db").Length
    Write-Host "Database size: $([math]::Round($dbSize/1KB, 2)) KB" -ForegroundColor Cyan
} else {
    Write-Host "Database file not found: data/info_system.db" -ForegroundColor Red
    Write-Host "The backend may need to be started to create the database" -ForegroundColor Yellow
}

Write-Host "`n=== Diagnosis Summary ===" -ForegroundColor Green

if ($workingUrl) {
    Write-Host "Working backend URL: $workingUrl" -ForegroundColor Green
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Update frontend API configuration if needed" -ForegroundColor White
    Write-Host "2. Ensure frontend is using the correct backend URL" -ForegroundColor White
    Write-Host "3. Check browser console for any CORS or network errors" -ForegroundColor White
} else {
    Write-Host "No working backend found. Please:" -ForegroundColor Red
    Write-Host "1. Start the backend server: go run cmd/server/main.go" -ForegroundColor White
    Write-Host "2. Check if the server is binding to the correct address" -ForegroundColor White
    Write-Host "3. Verify firewall settings" -ForegroundColor White
}

Write-Host "`n=== End Diagnosis ===" -ForegroundColor Green