# Create Simple Record for Testing
Write-Host "=== Creating Simple Record for Testing ===" -ForegroundColor Green

# Login
Write-Host "`n1. Logging in..." -ForegroundColor Yellow
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    Write-Host "Login successful" -ForegroundColor Green
} catch {
    Write-Host "Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
}

# Get existing record types
Write-Host "`n2. Getting existing record types..." -ForegroundColor Yellow
try {
    $typesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/record-types" -Method GET -Headers $headers
    
    if ($typesResponse.success -and $typesResponse.data.Count -gt 0) {
        $firstType = $typesResponse.data[0]
        Write-Host "Using existing record type: $($firstType.name)" -ForegroundColor Green
        
        # Create a simple record using the first available type
        $simpleRecord = @{
            type = $firstType.name
            title = "Simple Test Record"
            content = @{
                description = "This is a simple test record for frontend testing"
                status = "published"
                created_for = "frontend_testing"
            }
            tags = @("test", "frontend", "demo")
        } | ConvertTo-Json -Depth 10
        
        Write-Host "`n3. Creating test record..." -ForegroundColor Yellow
        try {
            $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Body $simpleRecord -ContentType "application/json" -Headers $headers
            
            if ($createResponse.success) {
                Write-Host "Test record created successfully!" -ForegroundColor Green
                Write-Host "Record ID: $($createResponse.data.id)" -ForegroundColor Cyan
                Write-Host "Record Title: $($createResponse.data.title)" -ForegroundColor Cyan
            } else {
                Write-Host "Failed to create record: $($createResponse.message)" -ForegroundColor Red
            }
        } catch {
            Write-Host "Error creating record: $($_.Exception.Message)" -ForegroundColor Red
        }
        
    } else {
        Write-Host "No record types found, creating a basic type first..." -ForegroundColor Yellow
        
        # Create a basic record type
        $basicType = @{
            name = "basic"
            display_name = "Basic Record"
            schema = @{
                fields = @(
                    @{ name = "description"; type = "text"; required = $true },
                    @{ name = "status"; type = "select"; options = @("draft", "published", "archived") }
                )
            }
        } | ConvertTo-Json -Depth 10
        
        try {
            $typeResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/record-types" -Method POST -Body $basicType -ContentType "application/json" -Headers $headers
            Write-Host "Basic record type created" -ForegroundColor Green
            
            # Now create the record
            $simpleRecord = @{
                type = "basic"
                title = "Simple Test Record"
                content = @{
                    description = "This is a simple test record for frontend testing"
                    status = "published"
                }
                tags = @("test", "frontend")
            } | ConvertTo-Json -Depth 10
            
            $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Body $simpleRecord -ContentType "application/json" -Headers $headers
            Write-Host "Test record created successfully!" -ForegroundColor Green
            
        } catch {
            Write-Host "Failed to create record type or record: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "Failed to get record types: $($_.Exception.Message)" -ForegroundColor Red
}

# Verify the record was created
Write-Host "`n4. Verifying record creation..." -ForegroundColor Yellow
try {
    $recordsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    
    if ($recordsResponse.success) {
        Write-Host "Current record count: $($recordsResponse.data.total)" -ForegroundColor Green
        
        foreach ($record in $recordsResponse.data.records) {
            Write-Host "Record: $($record.title) (ID: $($record.id), Type: $($record.type))" -ForegroundColor Cyan
        }
    }
} catch {
    Write-Host "Failed to verify records: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Record Creation Complete ===" -ForegroundColor Green
Write-Host "Now you can test the frontend at http://localhost:3000" -ForegroundColor Yellow