# Test Record Type Delete Functionality
Write-Host "=== Record Type Delete Test ===" -ForegroundColor Green

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

# Get current record types
Write-Host "1. Getting current record types..." -ForegroundColor Yellow
try {
    $typesResponse = Invoke-RestMethod -Uri "$baseUrl/record-types" -Method GET -Headers $headers
    
    if ($typesResponse.success) {
        Write-Host "Current record types:" -ForegroundColor Green
        foreach ($type in $typesResponse.data) {
            Write-Host "  - ID: $($type.id), Name: $($type.name), Display: $($type.display_name)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "Failed to get record types: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check if there are any records using 'work' type
Write-Host "2. Checking records using 'work' type..." -ForegroundColor Yellow
try {
    $recordsResponse = Invoke-RestMethod -Uri "$baseUrl/records?type=work" -Method GET -Headers $headers
    
    if ($recordsResponse.success) {
        $workRecords = $recordsResponse.data
        Write-Host "Found $($workRecords.Count) records using 'work' type" -ForegroundColor Gray
        
        if ($workRecords.Count -gt 0) {
            Write-Host "Records using 'work' type:" -ForegroundColor Yellow
            foreach ($record in $workRecords) {
                Write-Host "  - ID: $($record.id), Title: $($record.title)" -ForegroundColor Gray
            }
        }
    }
} catch {
    Write-Host "Could not check records: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Create a test record type that can be safely deleted
Write-Host "3. Creating a test record type..." -ForegroundColor Yellow
$testType = @{
    name = "test_deletable"
    display_name = "Test Deletable Type"
    schema = @{
        fields = @(
            @{ name = "title"; label = "Title"; type = "text"; required = $true }
        )
    }
} | ConvertTo-Json -Depth 3

try {
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/record-types" -Method POST -Body $testType -Headers $headers
    
    if ($createResponse.success) {
        $testTypeId = $createResponse.data.id
        Write-Host "Created test type with ID: $testTypeId" -ForegroundColor Green
        
        # Try to delete the test type (should succeed)
        Write-Host "4. Testing deletion of unused type..." -ForegroundColor Yellow
        try {
            $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/record-types/$testTypeId" -Method DELETE -Headers $headers
            
            if ($deleteResponse.success) {
                Write-Host "Successfully deleted test type" -ForegroundColor Green
            } else {
                Write-Host "Delete response indicated failure" -ForegroundColor Red
            }
        } catch {
            Write-Host "Failed to delete test type: $($_.Exception.Message)" -ForegroundColor Red
            if ($_.Exception.Response) {
                $statusCode = $_.Exception.Response.StatusCode
                Write-Host "Status Code: $statusCode" -ForegroundColor Gray
            }
        }
    }
} catch {
    Write-Host "Failed to create test type: $($_.Exception.Message)" -ForegroundColor Red
}

# Try to delete 'work' type (should fail with 409 if records exist)
Write-Host "5. Testing deletion of 'work' type (should fail if records exist)..." -ForegroundColor Yellow

# Find work type ID
$workType = $typesResponse.data | Where-Object { $_.name -eq "work" }
if ($workType) {
    try {
        $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/record-types/$($workType.id)" -Method DELETE -Headers $headers
        Write-Host "Unexpectedly succeeded in deleting 'work' type" -ForegroundColor Yellow
    } catch {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "Failed to delete 'work' type - Status: $statusCode" -ForegroundColor Green
        
        if ($statusCode -eq 409) {
            Write-Host "✓ Correctly returned 409 Conflict - type is in use" -ForegroundColor Green
        } else {
            Write-Host "✗ Unexpected status code: $statusCode" -ForegroundColor Red
        }
        
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            Write-Host "Error message: $errorBody" -ForegroundColor Gray
        } catch {
            Write-Host "Could not read error details" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "Could not find 'work' type" -ForegroundColor Red
}

Write-Host "`n=== Test Summary ===" -ForegroundColor Green
Write-Host "The 409 error when deleting 'work' type is expected behavior." -ForegroundColor White
Write-Host "This protects data integrity by preventing deletion of types that are in use." -ForegroundColor White
Write-Host "To delete a record type:" -ForegroundColor Cyan
Write-Host "1. First delete all records of that type" -ForegroundColor White
Write-Host "2. Then delete the record type" -ForegroundColor White