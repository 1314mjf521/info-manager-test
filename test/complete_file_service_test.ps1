# Complete File Service Test
Write-Host "=== Complete File Service Test ===" -ForegroundColor Green

# Global variables
$global:Token = ""
$global:UploadedFileId = ""

# Helper function: API request
function Invoke-ApiRequest {
    param(
        [string]$Method,
        [string]$Uri,
        [hashtable]$Headers = @{},
        [object]$Body = $null,
        [string]$ContentType = "application/json"
    )
    
    try {
        $params = @{
            Method = $Method
            Uri = $Uri
            Headers = $Headers
        }
        
        if ($ContentType -eq "application/json" -and $Body) {
            $params.Body = $Body | ConvertTo-Json -Depth 10
            $params.ContentType = $ContentType
        } elseif ($Body) {
            $params.Body = $Body
            $params.ContentType = $ContentType
        }
        
        $response = Invoke-RestMethod @params
        return @{ Success = $true; Data = $response }
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

# 1. Login
function Test-Login {
    Write-Host "1. Testing login..." -ForegroundColor Yellow
    
    $loginData = @{
        username = "admin"
        password = "admin123"
    }
    
    $result = Invoke-ApiRequest -Method POST -Uri "http://localhost:8080/api/v1/auth/login" -Body $loginData
    
    if ($result.Success) {
        $global:Token = $result.Data.data.token
        Write-Host "✓ Login successful" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Login failed: $($result.Error)" -ForegroundColor Red
        return $false
    }
}

# 2. Test file upload
function Test-FileUpload {
    Write-Host "`n2. Testing file upload..." -ForegroundColor Yellow
    
    # Create test file
    $testContent = "This is a test file for upload testing.`nCreated at: $(Get-Date)"
    $testFilePath = "test_upload.txt"
    Set-Content -Path $testFilePath -Value $testContent -Encoding UTF8
    
    # Upload file
    $boundary = [System.Guid]::NewGuid().ToString()
    $fileBytes = [System.IO.File]::ReadAllBytes($testFilePath)
    $fileName = "test_upload.txt"
    
    $bodyLines = @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
        "Content-Type: text/plain",
        "",
        [System.Text.Encoding]::UTF8.GetString($fileBytes),
        "--$boundary--"
    )
    
    $body = $bodyLines -join "`r`n"
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    
    $headers = @{
        "Authorization" = "Bearer $global:Token"
        "Content-Type" = "multipart/form-data; boundary=$boundary"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/upload" -Method POST -Headers $headers -Body $bodyBytes
        $global:UploadedFileId = $response.data.file.id
        Write-Host "✓ File upload successful, File ID: $global:UploadedFileId" -ForegroundColor Green
        
        # Clean up test file
        Remove-Item $testFilePath -Force
        return $true
    }
    catch {
        Write-Host "✗ File upload failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 3. Test file list
function Test-FileList {
    Write-Host "`n3. Testing file list..." -ForegroundColor Yellow
    
    $headers = @{ "Authorization" = "Bearer $global:Token" }
    $result = Invoke-ApiRequest -Method GET -Uri "http://localhost:8080/api/v1/files" -Headers $headers
    
    if ($result.Success) {
        $fileCount = $result.Data.data.files.Count
        Write-Host "✓ File list retrieved successfully, Total files: $fileCount" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ File list failed: $($result.Error)" -ForegroundColor Red
        return $false
    }
}

# 4. Test file info
function Test-FileInfo {
    Write-Host "`n4. Testing file info..." -ForegroundColor Yellow
    
    if (-not $global:UploadedFileId) {
        Write-Host "✗ No uploaded file ID available" -ForegroundColor Red
        return $false
    }
    
    $headers = @{ "Authorization" = "Bearer $global:Token" }
    $result = Invoke-ApiRequest -Method GET -Uri "http://localhost:8080/api/v1/files/$global:UploadedFileId/info" -Headers $headers
    
    if ($result.Success) {
        $fileName = $result.Data.data.file.filename
        $fileSize = $result.Data.data.file.size
        Write-Host "✓ File info retrieved successfully" -ForegroundColor Green
        Write-Host "  File name: $fileName" -ForegroundColor Cyan
        Write-Host "  File size: $fileSize bytes" -ForegroundColor Cyan
        return $true
    } else {
        Write-Host "✗ File info failed: $($result.Error)" -ForegroundColor Red
        return $false
    }
}

# 5. Test file download
function Test-FileDownload {
    Write-Host "`n5. Testing file download..." -ForegroundColor Yellow
    
    if (-not $global:UploadedFileId) {
        Write-Host "✗ No uploaded file ID available" -ForegroundColor Red
        return $false
    }
    
    $headers = @{ "Authorization" = "Bearer $global:Token" }
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/files/$global:UploadedFileId" -Method GET -Headers $headers
        $contentLength = $response.Headers.'Content-Length'
        Write-Host "✓ File download successful" -ForegroundColor Green
        Write-Host "  Content length: $contentLength bytes" -ForegroundColor Cyan
        return $true
    }
    catch {
        Write-Host "✗ File download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 6. Test file deletion
function Test-FileDelete {
    Write-Host "`n6. Testing file deletion..." -ForegroundColor Yellow
    
    if (-not $global:UploadedFileId) {
        Write-Host "✗ No uploaded file ID available" -ForegroundColor Red
        return $false
    }
    
    $headers = @{ "Authorization" = "Bearer $global:Token" }
    $result = Invoke-ApiRequest -Method DELETE -Uri "http://localhost:8080/api/v1/files/$global:UploadedFileId" -Headers $headers
    
    if ($result.Success) {
        Write-Host "✓ File deletion successful" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ File deletion failed: $($result.Error)" -ForegroundColor Red
        return $false
    }
}

# 7. Test OCR languages
function Test-OCRLanguages {
    Write-Host "`n7. Testing OCR languages..." -ForegroundColor Yellow
    
    $headers = @{ "Authorization" = "Bearer $global:Token" }
    $result = Invoke-ApiRequest -Method GET -Uri "http://localhost:8080/api/v1/files/ocr/languages" -Headers $headers
    
    if ($result.Success) {
        $languageCount = $result.Data.data.languages.Count
        Write-Host "✓ OCR languages retrieved successfully, Supported languages: $languageCount" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ OCR languages failed: $($result.Error)" -ForegroundColor Red
        return $false
    }
}

# Main test execution
function Main {
    Write-Host "Starting complete file service test..." -ForegroundColor Green
    
    $results = @()
    
    # Run all tests
    $results += @{ Test = "Login"; Success = (Test-Login) }
    $results += @{ Test = "File Upload"; Success = (Test-FileUpload) }
    $results += @{ Test = "File List"; Success = (Test-FileList) }
    $results += @{ Test = "File Info"; Success = (Test-FileInfo) }
    $results += @{ Test = "File Download"; Success = (Test-FileDownload) }
    $results += @{ Test = "File Delete"; Success = (Test-FileDelete) }
    $results += @{ Test = "OCR Languages"; Success = (Test-OCRLanguages) }
    
    # Generate summary
    Write-Host "`n=== Test Summary ===" -ForegroundColor Magenta
    $successCount = ($results | Where-Object { $_.Success }).Count
    $totalCount = $results.Count
    
    Write-Host "Total Tests: $totalCount" -ForegroundColor White
    Write-Host "Successful: $successCount" -ForegroundColor Green
    Write-Host "Failed: $($totalCount - $successCount)" -ForegroundColor Red
    Write-Host "Success Rate: $([math]::Round($successCount / $totalCount * 100, 2))%" -ForegroundColor Yellow
    
    Write-Host "`nDetailed Results:" -ForegroundColor White
    foreach ($result in $results) {
        $status = if ($result.Success) { "✓" } else { "✗" }
        $color = if ($result.Success) { "Green" } else { "Red" }
        Write-Host "  $status $($result.Test)" -ForegroundColor $color
    }
    
    Write-Host "`n=== Complete File Service Test Finished ===" -ForegroundColor Green
    
    return $successCount -eq $totalCount
}

# Execute main function
Main