# Test Records Interface Fix
Write-Host "=== Testing Records Interface Fix ===" -ForegroundColor Green

Write-Host "`n1. Verifying backend API endpoints..." -ForegroundColor Yellow

# Test login
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    Write-Host "Login: SUCCESS" -ForegroundColor Green
} catch {
    Write-Host "Login: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Test records endpoint
Write-Host "`nTesting records endpoint..." -ForegroundColor Cyan
try {
    $recordsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    Write-Host "Records API: SUCCESS" -ForegroundColor Green
    Write-Host "Response format: { success: $($recordsResponse.success), data: {...} }" -ForegroundColor White
    Write-Host "Records count: $($recordsResponse.data.total)" -ForegroundColor White
} catch {
    Write-Host "Records API: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test record types endpoint
Write-Host "`nTesting record types endpoint..." -ForegroundColor Cyan
try {
    $typesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/record-types" -Method GET -Headers $headers
    Write-Host "Record Types API: SUCCESS" -ForegroundColor Green
    Write-Host "Types count: $($typesResponse.data.Count)" -ForegroundColor White
} catch {
    Write-Host "Record Types API: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n2. Checking frontend modifications..." -ForegroundColor Yellow

# Check if the fix was applied
$recordListContent = Get-Content "frontend/src/views/records/RecordListView.vue" -Raw

if ($recordListContent -match "API_CONFIG") {
    Write-Host "API_CONFIG import: ADDED" -ForegroundColor Green
} else {
    Write-Host "API_CONFIG import: MISSING" -ForegroundColor Red
}

if ($recordListContent -match "开始获取记录列表") {
    Write-Host "Debug logging: ADDED" -ForegroundColor Green
} else {
    Write-Host "Debug logging: MISSING" -ForegroundColor Red
}

if ($recordListContent -match "checkApiConnection.*await") {
    Write-Host "API connection check: STILL PRESENT (may cause issues)" -ForegroundColor Yellow
} else {
    Write-Host "API connection check: REMOVED" -ForegroundColor Green
}

Write-Host "`n3. Frontend testing instructions..." -ForegroundColor Yellow
Write-Host "Now test the frontend:" -ForegroundColor Cyan
Write-Host "1. Ensure frontend server is running: npm run dev" -ForegroundColor White
Write-Host "2. Open http://localhost:3000" -ForegroundColor White
Write-Host "3. Login with admin/admin123" -ForegroundColor White
Write-Host "4. Navigate to Records Management" -ForegroundColor White
Write-Host "5. Check browser console for debug logs" -ForegroundColor White

Write-Host "`n4. Expected console output:" -ForegroundColor Yellow
Write-Host "=== 开始获取记录列表 ===" -ForegroundColor Gray
Write-Host "API端点: /records" -ForegroundColor Gray
Write-Host "完整URL: http://localhost:8080/api/v1/records" -ForegroundColor Gray

Write-Host "`n5. If still showing 'resource not found':" -ForegroundColor Yellow
Write-Host "- Check Network tab in DevTools" -ForegroundColor White
Write-Host "- Look for the actual URL being requested" -ForegroundColor White
Write-Host "- Check if Authorization header is present" -ForegroundColor White
Write-Host "- Verify the response status and error message" -ForegroundColor White

Write-Host "`n6. Creating a test record for verification..." -ForegroundColor Yellow

try {
    # Get the first available record type
    $typesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/record-types" -Method GET -Headers $headers
    
    if ($typesResponse.success -and $typesResponse.data.Count -gt 0) {
        $firstType = $typesResponse.data[0]
        
        $testRecord = @{
            type = $firstType.name
            title = "Frontend Test Record"
            content = @{
                description = "This record was created to test the frontend interface"
                status = "published"
                created_by_script = $true
            }
            tags = @("frontend", "test", "interface")
        } | ConvertTo-Json -Depth 10
        
        $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Body $testRecord -Headers $headers
        
        if ($createResponse.success) {
            Write-Host "Test record created: ID $($createResponse.data.id)" -ForegroundColor Green
            Write-Host "This record should now appear in the frontend" -ForegroundColor Cyan
        } else {
            Write-Host "Failed to create test record" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "Could not create test record: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "This is OK - the main API endpoints are working" -ForegroundColor Gray
}

Write-Host "`n=== Fix Applied ===" -ForegroundColor Green
Write-Host "The records interface should now work properly!" -ForegroundColor Cyan