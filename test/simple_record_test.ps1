# Simple Record Test
Write-Host "=== Record Management Test ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080/api/v1"

# Get auth token
Write-Host "1. Getting auth token..." -ForegroundColor Yellow
$loginData = '{"username":"admin","password":"admin123"}'

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.success -and $loginResponse.data.token) {
        $token = $loginResponse.data.token
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        Write-Host "Auth successful" -ForegroundColor Green
    } else {
        Write-Host "Auth failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Auth request failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test record types API
Write-Host "2. Testing record types..." -ForegroundColor Yellow

# Create a simple record type
$simpleType = @{
    name = "work"
    display_name = "Work record type"
    schema = @{
        fields = @(
            @{ name = "title"; label = "Title"; type = "text"; required = $true }
        )
    }
} | ConvertTo-Json -Depth 3

Write-Host "Sending data: $simpleType" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/record-types" -Method POST -Body $simpleType -Headers $headers
    
    if ($response.success) {
        Write-Host "Record type created successfully" -ForegroundColor Green
    } else {
        Write-Host "Record type creation failed: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "Record type request failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "Status Code: $statusCode" -ForegroundColor Gray
        
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            Write-Host "Error details: $errorBody" -ForegroundColor Gray
        } catch {
            Write-Host "Could not read error details" -ForegroundColor Gray
        }
    }
}

# Create more default types
Write-Host "3. Creating more default types..." -ForegroundColor Yellow

$defaultTypes = @(
    @{
        name = "study"
        display_name = "Study Notes"
        schema = @{
            fields = @(
                @{ name = "title"; label = "Title"; type = "text"; required = $true },
                @{ name = "content"; label = "Content"; type = "textarea"; required = $true }
            )
        }
    },
    @{
        name = "project"
        display_name = "Project Document"
        schema = @{
            fields = @(
                @{ name = "title"; label = "Title"; type = "text"; required = $true },
                @{ name = "description"; label = "Description"; type = "textarea"; required = $true }
            )
        }
    },
    @{
        name = "other"
        display_name = "Other Type"
        schema = @{
            fields = @(
                @{ name = "title"; label = "Title"; type = "text"; required = $true },
                @{ name = "content"; label = "Content"; type = "textarea"; required = $true }
            )
        }
    }
)

foreach ($type in $defaultTypes) {
    try {
        $typeJson = $type | ConvertTo-Json -Depth 3
        $response = Invoke-RestMethod -Uri "$baseUrl/record-types" -Method POST -Body $typeJson -Headers $headers
        
        if ($response.success) {
            Write-Host "Created type: $($type.name)" -ForegroundColor Green
        }
    } catch {
        Write-Host "Type may already exist: $($type.name)" -ForegroundColor Yellow
    }
}

# Test getting record types
Write-Host "4. Getting all record types..." -ForegroundColor Yellow
try {
    $typesResponse = Invoke-RestMethod -Uri "$baseUrl/record-types" -Method GET -Headers $headers
    
    if ($typesResponse.success) {
        Write-Host "Got record types successfully" -ForegroundColor Green
        foreach ($type in $typesResponse.data) {
            Write-Host "  - $($type.name): $($type.display_name)" -ForegroundColor Gray
        }
    } else {
        Write-Host "Failed to get record types" -ForegroundColor Red
    }
} catch {
    Write-Host "Get record types failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test creating a record
Write-Host "5. Testing record creation..." -ForegroundColor Yellow
$testRecord = @{
    title = "Test Record"
    type = "work"
    status = "draft"
    content = @{
        description = "This is a test record"
    }
    tags = @("test")
} | ConvertTo-Json -Depth 3

try {
    $recordResponse = Invoke-RestMethod -Uri "$baseUrl/records" -Method POST -Body $testRecord -Headers $headers
    
    if ($recordResponse.success) {
        Write-Host "Record created successfully!" -ForegroundColor Green
        Write-Host "Record ID: $($recordResponse.data.id)" -ForegroundColor Gray
    } else {
        Write-Host "Record creation failed: $($recordResponse.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "Record creation request failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            Write-Host "Error details: $errorBody" -ForegroundColor Gray
        } catch {
            Write-Host "Could not read error details" -ForegroundColor Gray
        }
    }
}

Write-Host "Test completed" -ForegroundColor Green