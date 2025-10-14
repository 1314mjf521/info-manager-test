# Simple File Service Test
Write-Host "=== File Service Test ===" -ForegroundColor Green

# Login
$loginData = @{ username = "admin"; password = "admin123" }
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
$token = $loginResponse.data.token
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "Login successful" -ForegroundColor Green

# Test 1: File Upload
Write-Host "`n1. Testing file upload..." -ForegroundColor Yellow
$testContent = "Test file content for upload"
$testFilePath = "temp_test.txt"
Set-Content -Path $testFilePath -Value $testContent -Encoding UTF8

$boundary = [System.Guid]::NewGuid().ToString()
$fileBytes = [System.IO.File]::ReadAllBytes($testFilePath)
$fileName = "temp_test.txt"

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

$uploadHeaders = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "multipart/form-data; boundary=$boundary"
}

try {
    $uploadResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/upload" -Method POST -Headers $uploadHeaders -Body $bodyBytes
    $fileId = $uploadResponse.data.file.id
    Write-Host "File upload successful, ID: $fileId" -ForegroundColor Green
    Remove-Item $testFilePath -Force
} catch {
    Write-Host "File upload failed: $($_.Exception.Message)" -ForegroundColor Red
    $fileId = $null
}

# Test 2: File List
Write-Host "`n2. Testing file list..." -ForegroundColor Yellow
try {
    $listResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files" -Method GET -Headers $headers
    $fileCount = $listResponse.data.files.Count
    Write-Host "File list successful, Count: $fileCount" -ForegroundColor Green
} catch {
    Write-Host "File list failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: File Info (if we have a file ID)
if ($fileId) {
    Write-Host "`n3. Testing file info..." -ForegroundColor Yellow
    try {
        $infoResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/$fileId/info" -Method GET -Headers $headers
        $fileName = $infoResponse.data.file.filename
        Write-Host "File info successful, Name: $fileName" -ForegroundColor Green
    } catch {
        Write-Host "File info failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test 4: File Download
    Write-Host "`n4. Testing file download..." -ForegroundColor Yellow
    try {
        $downloadResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/files/$fileId" -Method GET -Headers $headers
        $contentLength = $downloadResponse.Headers.'Content-Length'
        Write-Host "File download successful, Size: $contentLength bytes" -ForegroundColor Green
    } catch {
        Write-Host "File download failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test 5: File Delete
    Write-Host "`n5. Testing file delete..." -ForegroundColor Yellow
    try {
        $deleteResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/$fileId" -Method DELETE -Headers $headers
        Write-Host "File delete successful" -ForegroundColor Green
    } catch {
        Write-Host "File delete failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 6: OCR Languages
Write-Host "`n6. Testing OCR languages..." -ForegroundColor Yellow
try {
    $langResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/ocr/languages" -Method GET -Headers $headers
    $langCount = $langResponse.data.languages.Count
    Write-Host "OCR languages successful, Count: $langCount" -ForegroundColor Green
} catch {
    Write-Host "OCR languages failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== File Service Test Completed ===" -ForegroundColor Green