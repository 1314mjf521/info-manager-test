# Debug OCR Test
Write-Host "=== Debug OCR Test ===" -ForegroundColor Green

# Test login
Write-Host "1. Testing login..." -ForegroundColor Yellow
try {
    $loginData = @{ username = "admin"; password = "admin123" }
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
    $token = $loginResponse.data.token
    $userId = $loginResponse.data.user.id
    Write-Host "✓ Login successful, User ID: $userId" -ForegroundColor Green
} catch {
    Write-Host "✗ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test user permissions
Write-Host "`n2. Testing user permissions..." -ForegroundColor Yellow
$headers = @{ "Authorization" = "Bearer $token" }
try {
    $permResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions/user/$userId" -Method GET -Headers $headers
    Write-Host "✓ User permissions retrieved successfully" -ForegroundColor Green
    Write-Host "Permissions count: $($permResponse.data.permissions.Count)" -ForegroundColor Cyan
    
    foreach ($perm in $permResponse.data.permissions) {
        Write-Host "  - $($perm.resource):$($perm.action):$($perm.scope)" -ForegroundColor White
    }
} catch {
    Write-Host "✗ Failed to get user permissions: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Gray
}

# Test permission check for files
Write-Host "`n3. Testing permission check for files..." -ForegroundColor Yellow
try {
    $checkData = @{
        user_id = $userId
        resource = "files"
        action = "read"
        scope = "all"
    }
    $checkResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions/check" -Method POST -Headers $headers -Body ($checkData | ConvertTo-Json) -ContentType "application/json"
    Write-Host "✓ Permission check successful" -ForegroundColor Green
    Write-Host "Has permission: $($checkResponse.data.has_permission)" -ForegroundColor Cyan
    Write-Host "Message: $($checkResponse.data.message)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ Permission check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test OCR languages endpoint with detailed error info
Write-Host "`n4. Testing OCR languages endpoint..." -ForegroundColor Yellow
try {
    $langResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/ocr/languages" -Method GET -Headers $headers
    Write-Host "✓ OCR languages endpoint successful" -ForegroundColor Green
    Write-Host "Languages: $($langResponse.data.languages.Count)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ OCR languages endpoint failed" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Gray
    Write-Host "Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Gray
    
    # Try to get response body
    try {
        $responseStream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($responseStream)
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody" -ForegroundColor Gray
    } catch {
        Write-Host "Could not read response body" -ForegroundColor Gray
    }
}

Write-Host "`n=== Debug Test Completed ===" -ForegroundColor Green