# API Test Script for Info Management System
# PowerShell version with better JSON handling

Write-Host "=== Info Management System API Tests ===" -ForegroundColor Green
Write-Host ""

# Check if executable exists
if (-not (Test-Path "info-management-system.exe")) {
    Write-Host "Error: info-management-system.exe not found" -ForegroundColor Red
    Write-Host "Please make sure the executable is in the current directory"
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if config exists
if (-not (Test-Path "configs\config.yaml")) {
    Write-Host "Warning: config.yaml not found, copying from example..." -ForegroundColor Yellow
    if (-not (Test-Path "configs")) {
        New-Item -ItemType Directory -Path "configs" | Out-Null
    }
    Copy-Item "configs\config.example.yaml" "configs\config.yaml"
}

# Start server
Write-Host "Starting server..." -ForegroundColor Cyan
$serverProcess = Start-Process -FilePath "info-management-system.exe" -RedirectStandardOutput "server.log" -RedirectStandardError "server_error.log" -PassThru

# Wait for server to start
Write-Host "Waiting for server to start..." -ForegroundColor Cyan
Start-Sleep -Seconds 8

# Test results
$testResults = @()

function Test-API {
    param(
        [string]$Name,
        [string]$Method = "GET",
        [string]$Url,
        [hashtable]$Headers = @{},
        [string]$Body = $null
    )
    
    Write-Host "Testing: $Name" -ForegroundColor Yellow
    Write-Host "  URL: $Method $Url" -ForegroundColor Gray
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            Headers = $Headers
            UseBasicParsing = $true
        }
        
        if ($Body) {
            $params.Body = $Body
            $params.ContentType = "application/json"
            Write-Host "  Body: $Body" -ForegroundColor Gray
        }
        
        $response = Invoke-WebRequest @params
        $statusCode = $response.StatusCode
        $content = $response.Content
        
        Write-Host "  Status: $statusCode" -ForegroundColor Green
        
        # Try to parse JSON
        try {
            $jsonContent = $content | ConvertFrom-Json
            Write-Host "  Response: $($jsonContent | ConvertTo-Json -Compress)" -ForegroundColor Green
            
            $script:testResults += @{
                Name = $Name
                Status = $statusCode
                Success = $true
                Response = $jsonContent
            }
            
            return $jsonContent
        }
        catch {
            Write-Host "  Response: $content" -ForegroundColor Green
            
            $script:testResults += @{
                Name = $Name
                Status = $statusCode
                Success = $true
                Response = $content
            }
            
            return $content
        }
    }
    catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.Value__ } else { "Error" }
        Write-Host "  Status: $statusCode" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        
        $script:testResults += @{
            Name = $Name
            Status = $statusCode
            Success = $false
            Error = $_.Exception.Message
        }
        
        return $null
    }
    
    Write-Host ""
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Testing Health Check Endpoints" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

# Test health endpoints
Test-API -Name "Health Check" -Url "http://localhost:8080/health"
Test-API -Name "Ready Check" -Url "http://localhost:8080/ready"

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Testing Authentication APIs" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

# Test user registration
$registerResponse = Test-API -Name "User Registration" -Method "POST" -Url "http://localhost:8080/api/v1/auth/register" -Body '{"username":"testuser","email":"test@example.com","password":"password123"}'

# Test user login
$loginResponse = Test-API -Name "User Login" -Method "POST" -Url "http://localhost:8080/api/v1/auth/login" -Body '{"username":"testuser","password":"password123"}'

# Extract token if login successful
$token = $null
if ($loginResponse -and $loginResponse.success -and $loginResponse.data.access_token) {
    $token = $loginResponse.data.access_token
    Write-Host "Token extracted successfully: $($token.Substring(0, 20))..." -ForegroundColor Green
}
elseif ($loginResponse -and $loginResponse.data -and $loginResponse.data.token) {
    $token = $loginResponse.data.token
    Write-Host "Token extracted successfully: $($token.Substring(0, 20))..." -ForegroundColor Green
}
else {
    Write-Host "Warning: Could not extract token from login response" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Testing Record Type APIs" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

$authHeaders = @{}
if ($token) {
    $authHeaders["Authorization"] = "Bearer $token"
}

# Test record type creation
$recordTypeBody = @{
    name = "test_type"
    display_name = "Test Record Type"
    schema = @{
        fields = @(
            @{
                name = "description"
                type = "string"
                required = $true
            },
            @{
                name = "priority"
                type = "number"
                required = $false
            }
        )
    }
} | ConvertTo-Json -Depth 10

$createRecordTypeResponse = Test-API -Name "Create Record Type" -Method "POST" -Url "http://localhost:8080/api/v1/record-types" -Headers $authHeaders -Body $recordTypeBody

# Test get all record types
Test-API -Name "Get All Record Types" -Url "http://localhost:8080/api/v1/record-types" -Headers $authHeaders

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Testing Record Management APIs" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

# Test record creation
$recordBody = @{
    type = "test_type"
    title = "Test Record"
    content = @{
        description = "This is a test record"
        priority = 1
    }
    tags = @("test", "api")
} | ConvertTo-Json -Depth 10

$createRecordResponse = Test-API -Name "Create Record" -Method "POST" -Url "http://localhost:8080/api/v1/records" -Headers $authHeaders -Body $recordBody

# Extract record ID if creation successful
$recordId = $null
if ($createRecordResponse -and $createRecordResponse.success -and $createRecordResponse.data.id) {
    $recordId = $createRecordResponse.data.id
    Write-Host "Record ID extracted: $recordId" -ForegroundColor Green
}

# Test get all records
Test-API -Name "Get All Records" -Url "http://localhost:8080/api/v1/records" -Headers $authHeaders

# Test get record by ID (if we have one)
if ($recordId) {
    Test-API -Name "Get Record by ID" -Url "http://localhost:8080/api/v1/records/$recordId" -Headers $authHeaders
    
    # Test update record
    $updateBody = @{
        title = "Updated Test Record"
        content = @{
            description = "This is an updated test record"
            priority = 2
        }
    } | ConvertTo-Json -Depth 10
    
    Test-API -Name "Update Record" -Method "PUT" -Url "http://localhost:8080/api/v1/records/$recordId" -Headers $authHeaders -Body $updateBody
}

# Test batch record creation
$batchBody = @{
    records = @(
        @{
            type = "test_type"
            title = "Batch Record 1"
            content = @{
                description = "First batch record"
                priority = 1
            }
            tags = @("batch", "test")
        },
        @{
            type = "test_type"
            title = "Batch Record 2"
            content = @{
                description = "Second batch record"
                priority = 2
            }
            tags = @("batch", "test")
        }
    )
} | ConvertTo-Json -Depth 10

Test-API -Name "Batch Create Records" -Method "POST" -Url "http://localhost:8080/api/v1/records/batch" -Headers $authHeaders -Body $batchBody

# Test record import
$importBody = @{
    type = "test_type"
    records = @(
        @{
            title = "Imported Record 1"
            description = "First imported record"
            priority = 1
            tags = @("import", "test")
        },
        @{
            title = "Imported Record 2"
            description = "Second imported record"
            priority = 2
            tags = @("import", "test")
        }
    )
} | ConvertTo-Json -Depth 10

Test-API -Name "Import Records" -Method "POST" -Url "http://localhost:8080/api/v1/records/import" -Headers $authHeaders -Body $importBody

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Testing Audit APIs" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

# Test audit logs (admin permission required)
Test-API -Name "Get Audit Logs" -Url "http://localhost:8080/api/v1/audit/logs" -Headers $authHeaders
Test-API -Name "Get Audit Statistics" -Url "http://localhost:8080/api/v1/audit/statistics" -Headers $authHeaders

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Stopping Server" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

# Stop server
Write-Host "Stopping server..." -ForegroundColor Cyan
if ($serverProcess -and !$serverProcess.HasExited) {
    $serverProcess.Kill()
    $serverProcess.WaitForExit(5000)
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Test Results Summary" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

$successCount = ($testResults | Where-Object { $_.Success }).Count
$totalCount = $testResults.Count

Write-Host "Total Tests: $totalCount" -ForegroundColor White
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $($totalCount - $successCount)" -ForegroundColor Red
Write-Host ""

# Show detailed results
foreach ($result in $testResults) {
    $color = if ($result.Success) { "Green" } else { "Red" }
    $status = if ($result.Success) { "PASS" } else { "FAIL" }
    Write-Host "[$status] $($result.Name) - Status: $($result.Status)" -ForegroundColor $color
}

Write-Host ""
Write-Host "Check server.log for server output" -ForegroundColor Cyan
Write-Host "Check server_error.log for server errors" -ForegroundColor Cyan

# Save test results to JSON
$testResults | ConvertTo-Json -Depth 10 | Out-File "test_results.json" -Encoding UTF8
Write-Host "Test results saved to test_results.json" -ForegroundColor Cyan

Write-Host ""
Read-Host "Press Enter to exit"