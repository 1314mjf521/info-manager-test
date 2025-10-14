# Login Diagnosis Script
Write-Host "=== Login Problem Diagnosis ===" -ForegroundColor Green

# Test different backend URLs and credentials
$possibleUrls = @(
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://192.168.100.15:8080"
)

$credentialSets = @(
    @{ username = "admin"; password = "admin123" },
    @{ username = "admin"; password = "admin" },
    @{ username = "administrator"; password = "admin123" },
    @{ username = "root"; password = "admin123" }
)

Write-Host "`n1. Testing backend connectivity..." -ForegroundColor Yellow

$workingUrl = $null
foreach ($url in $possibleUrls) {
    Write-Host "Testing: $url" -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri "$url/health" -Method GET -TimeoutSec 5
        Write-Host "SUCCESS: $url is accessible" -ForegroundColor Green
        $workingUrl = $url
        break
    } catch {
        Write-Host "FAILED: $url - $($_.Exception.Message)" -ForegroundColor Red
    }
}

if (-not $workingUrl) {
    Write-Host "`nNo backend server found!" -ForegroundColor Red
    exit 1
}

Write-Host "`n2. Testing login credentials..." -ForegroundColor Yellow

$validCredentials = $null
foreach ($creds in $credentialSets) {
    Write-Host "Testing: $($creds.username)/$($creds.password)" -ForegroundColor Cyan
    
    try {
        $loginData = $creds | ConvertTo-Json
        $loginResponse = Invoke-RestMethod -Uri "$workingUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        
        if ($loginResponse.success -and $loginResponse.data.token) {
            Write-Host "SUCCESS: Valid credentials found!" -ForegroundColor Green
            $validCredentials = $creds
            $token = $loginResponse.data.token
            Write-Host "Token: $($token.Substring(0, 20))..." -ForegroundColor Gray
            break
        } else {
            Write-Host "FAILED: Invalid response format" -ForegroundColor Red
        }
    } catch {
        Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode
            Write-Host "Status Code: $statusCode" -ForegroundColor Yellow
            
            if ($statusCode -eq 401) {
                Write-Host "  -> Invalid credentials" -ForegroundColor Gray
            } elseif ($statusCode -eq 400) {
                Write-Host "  -> Bad request format" -ForegroundColor Gray
            }
        }
    }
}

if (-not $validCredentials) {
    Write-Host "`nNo valid credentials found! Checking database..." -ForegroundColor Red
    
    # Check if database exists and has users
    if (Test-Path "data/info_system.db") {
        Write-Host "Database file exists" -ForegroundColor Green
        
        # Try to check if there are any users in the database
        Write-Host "`n3. Checking database users..." -ForegroundColor Yellow
        Write-Host "Database file size: $([math]::Round((Get-Item 'data/info_system.db').Length/1KB, 2)) KB" -ForegroundColor Cyan
        
        # Suggest database reset
        Write-Host "`nSuggested solutions:" -ForegroundColor Yellow
        Write-Host "1. Reset the database and recreate admin user" -ForegroundColor White
        Write-Host "2. Check if backend server initialized properly" -ForegroundColor White
        Write-Host "3. Restart backend server to trigger user creation" -ForegroundColor White
        
    } else {
        Write-Host "Database file not found!" -ForegroundColor Red
        Write-Host "Backend server may not have started properly" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n3. Testing with valid credentials..." -ForegroundColor Yellow
    Write-Host "Working URL: $workingUrl" -ForegroundColor Green
    Write-Host "Valid credentials: $($validCredentials.username)/$($validCredentials.password)" -ForegroundColor Green
    
    # Test a protected endpoint
    try {
        $headers = @{ "Authorization" = "Bearer $token" }
        $profileResponse = Invoke-RestMethod -Uri "$workingUrl/api/v1/users/profile" -Method GET -Headers $headers
        Write-Host "Profile API test: SUCCESS" -ForegroundColor Green
    } catch {
        Write-Host "Profile API test: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n4. Frontend configuration check..." -ForegroundColor Yellow

# Check if frontend is using the correct URL
$frontendEnv = Get-Content "frontend/.env" -Raw
if ($frontendEnv -match "VITE_API_BASE_URL=(.+)") {
    $frontendUrl = $matches[1].Trim()
    Write-Host "Frontend configured URL: $frontendUrl" -ForegroundColor Cyan
    
    if ($frontendUrl -eq $workingUrl) {
        Write-Host "Frontend URL matches working backend URL" -ForegroundColor Green
    } else {
        Write-Host "MISMATCH: Frontend URL ($frontendUrl) != Working URL ($workingUrl)" -ForegroundColor Red
        Write-Host "Recommendation: Update frontend/.env to use $workingUrl" -ForegroundColor Yellow
    }
} else {
    Write-Host "Could not parse frontend URL from .env file" -ForegroundColor Red
}

Write-Host "`n5. Browser testing instructions..." -ForegroundColor Yellow
if ($validCredentials) {
    Write-Host "Use these credentials in the browser:" -ForegroundColor Green
    Write-Host "URL: http://localhost:3000" -ForegroundColor Cyan
    Write-Host "Username: $($validCredentials.username)" -ForegroundColor Cyan
    Write-Host "Password: $($validCredentials.password)" -ForegroundColor Cyan
} else {
    Write-Host "No valid credentials found. Try these steps:" -ForegroundColor Red
    Write-Host "1. Restart the backend server" -ForegroundColor White
    Write-Host "2. Check backend logs for user creation" -ForegroundColor White
    Write-Host "3. Try default credentials: admin/admin123" -ForegroundColor White
}

Write-Host "`n=== Diagnosis Complete ===" -ForegroundColor Green