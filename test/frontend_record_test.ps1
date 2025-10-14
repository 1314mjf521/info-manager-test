# Frontend Record Management Test
Write-Host "=== Frontend Record Management Test ===" -ForegroundColor Green

# Test frontend server
Write-Host "1. Testing frontend server..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -UseBasicParsing
    Write-Host "Frontend server OK - Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Frontend server ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please ensure frontend is running: cd frontend && npm run dev" -ForegroundColor Yellow
    exit 1
}

# Test record type pages
Write-Host "2. Testing record type pages..." -ForegroundColor Yellow
$pages = @(
    @{ path = "/record-types"; name = "Record Types Management" },
    @{ path = "/records"; name = "Records List" },
    @{ path = "/records/create"; name = "Create Record" }
)

foreach ($page in $pages) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000$($page.path)" -TimeoutSec 5 -UseBasicParsing
        Write-Host "✓ $($page.name) - Status: $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "✗ $($page.name) - ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test backend API
Write-Host "3. Testing backend record types API..." -ForegroundColor Yellow

# Get auth token
$loginData = '{"username":"admin","password":"admin123"}'
try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.success -and $loginResponse.data.token) {
        $token = $loginResponse.data.token
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        Write-Host "✓ Backend auth successful" -ForegroundColor Green
        
        # Test record types API
        try {
            $typesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/record-types" -Method GET -Headers $headers
            
            if ($typesResponse.success) {
                Write-Host "✓ Record types API working" -ForegroundColor Green
                Write-Host "Available types:" -ForegroundColor Gray
                foreach ($type in $typesResponse.data) {
                    Write-Host "  - $($type.name): $($type.display_name)" -ForegroundColor Gray
                }
            } else {
                Write-Host "✗ Record types API failed" -ForegroundColor Red
            }
        } catch {
            Write-Host "✗ Record types API error: $($_.Exception.Message)" -ForegroundColor Red
        }
        
    } else {
        Write-Host "✗ Backend auth failed" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Backend connection failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Test Summary ===" -ForegroundColor Green
Write-Host "Frontend compilation and record management test completed." -ForegroundColor White
Write-Host "If all tests passed, you can now:" -ForegroundColor Cyan
Write-Host "1. Visit http://localhost:3000/record-types to manage record types" -ForegroundColor White
Write-Host "2. Visit http://localhost:3000/records to view records" -ForegroundColor White
Write-Host "3. Visit http://localhost:3000/records/create to create new records" -ForegroundColor White