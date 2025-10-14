# Test Record Management Functions
Write-Host "=== Record Management Functions Test ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080/api/v1"
$frontendUrl = "http://localhost:3000"

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

# Test 1: Create a new record
Write-Host "1. Testing record creation..." -ForegroundColor Yellow
$newRecord = @{
    title = "Test Record for Functions"
    type = "work"
    status = "draft"
    content = @{
        description = "This is a test record to verify all functions work correctly"
    }
    tags = @("test", "functions", "verification")
} | ConvertTo-Json -Depth 3

try {
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/records" -Method POST -Body $newRecord -Headers $headers
    
    if ($createResponse.success) {
        $recordId = $createResponse.data.id
        Write-Host "✓ Record created successfully - ID: $recordId" -ForegroundColor Green
        
        # Test 2: Get record details
        Write-Host "2. Testing record detail retrieval..." -ForegroundColor Yellow
        try {
            $detailResponse = Invoke-RestMethod -Uri "$baseUrl/records/$recordId" -Method GET -Headers $headers
            
            if ($detailResponse.success) {
                Write-Host "✓ Record details retrieved successfully" -ForegroundColor Green
                Write-Host "  Title: $($detailResponse.data.title)" -ForegroundColor Gray
                Write-Host "  Type: $($detailResponse.data.type)" -ForegroundColor Gray
                Write-Host "  Status: $($detailResponse.data.status)" -ForegroundColor Gray
            } else {
                Write-Host "✗ Failed to get record details" -ForegroundColor Red
            }
        } catch {
            Write-Host "✗ Record detail request failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        # Test 3: Update record
        Write-Host "3. Testing record update..." -ForegroundColor Yellow
        $updateRecord = @{
            title = "Updated Test Record"
            type = "work"
            status = "published"
            content = @{
                description = "This record has been updated to test the edit functionality"
            }
            tags = @("test", "updated", "edit")
        } | ConvertTo-Json -Depth 3
        
        try {
            $updateResponse = Invoke-RestMethod -Uri "$baseUrl/records/$recordId" -Method PUT -Body $updateRecord -Headers $headers
            
            if ($updateResponse.success) {
                Write-Host "✓ Record updated successfully" -ForegroundColor Green
            } else {
                Write-Host "✗ Failed to update record" -ForegroundColor Red
            }
        } catch {
            Write-Host "✗ Record update request failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        # Test 4: Search/Filter records
        Write-Host "4. Testing record search/filter..." -ForegroundColor Yellow
        try {
            $searchResponse = Invoke-RestMethod -Uri "$baseUrl/records?search=Updated&type=work" -Method GET -Headers $headers
            
            if ($searchResponse.success) {
                Write-Host "✓ Record search works - Found $($searchResponse.data.records.Count) records" -ForegroundColor Green
            } else {
                Write-Host "✗ Record search failed" -ForegroundColor Red
            }
        } catch {
            Write-Host "✗ Record search request failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        # Test 5: Delete record
        Write-Host "5. Testing record deletion..." -ForegroundColor Yellow
        try {
            $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/records/$recordId" -Method DELETE -Headers $headers
            
            if ($deleteResponse.success) {
                Write-Host "✓ Record deleted successfully" -ForegroundColor Green
            } else {
                Write-Host "✗ Failed to delete record" -ForegroundColor Red
            }
        } catch {
            Write-Host "✗ Record deletion request failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
    } else {
        Write-Host "✗ Failed to create record" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Record creation request failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test frontend pages
Write-Host "6. Testing frontend pages..." -ForegroundColor Yellow
$pages = @(
    @{ path = "/records"; name = "Records List" },
    @{ path = "/records/create"; name = "Create Record" }
)

foreach ($page in $pages) {
    try {
        $response = Invoke-WebRequest -Uri "$frontendUrl$($page.path)" -TimeoutSec 5 -UseBasicParsing
        Write-Host "✓ $($page.name) page accessible - Status: $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "✗ $($page.name) page failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Test Summary ===" -ForegroundColor Green
Write-Host "Record management functions test completed." -ForegroundColor White
Write-Host "All CRUD operations and frontend pages have been tested." -ForegroundColor White
Write-Host "`nYou can now test in the browser:" -ForegroundColor Cyan
Write-Host "1. Visit http://localhost:3000/records to view records" -ForegroundColor White
Write-Host "2. Click 'New Record' to create records" -ForegroundColor White
Write-Host "3. Click 'View' to see record details" -ForegroundColor White
Write-Host "4. Click 'Edit' to modify records" -ForegroundColor White
Write-Host "5. Use search and filters to find records" -ForegroundColor White