# Debug File Test
Write-Host "=== Debug File Test ===" -ForegroundColor Green

# Login
$loginData = @{ username = "admin"; password = "admin123" }
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
$token = $loginResponse.data.token
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "Login successful" -ForegroundColor Green

# Test file upload with detailed response
Write-Host "`nTesting file upload with debug info..." -ForegroundColor Yellow
$testContent = "Debug test file content"
$testFilePath = "debug_test.txt"
Set-Content -Path $testFilePath -Value $testContent -Encoding UTF8

$boundary = [System.Guid]::NewGuid().ToString()
$fileBytes = [System.IO.File]::ReadAllBytes($testFilePath)
$fileName = "debug_test.txt"

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
    Write-Host "Upload Response:" -ForegroundColor Yellow
    $uploadResponse | ConvertTo-Json -Depth 5 | Write-Host
    
    if ($uploadResponse.data -and $uploadResponse.data.id) {
        $fileId = $uploadResponse.data.id
        Write-Host "File ID extracted: $fileId" -ForegroundColor Green
        
        # Test file info
        Write-Host "`nTesting file info..." -ForegroundColor Yellow
        $infoResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/$fileId/info" -Method GET -Headers $headers
        Write-Host "File Info Response:" -ForegroundColor Yellow
        $infoResponse | ConvertTo-Json -Depth 3 | Write-Host
        
        # Test file download
        Write-Host "`nTesting file download..." -ForegroundColor Yellow
        $downloadResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/files/$fileId" -Method GET -Headers $headers
        Write-Host "Download Status: $($downloadResponse.StatusCode)" -ForegroundColor Green
        Write-Host "Content Length: $($downloadResponse.Headers.'Content-Length')" -ForegroundColor Green
        
        # Test file delete
        Write-Host "`nTesting file delete..." -ForegroundColor Yellow
        $deleteResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/$fileId" -Method DELETE -Headers $headers
        Write-Host "Delete Response:" -ForegroundColor Yellow
        $deleteResponse | ConvertTo-Json -Depth 3 | Write-Host
        
    } else {
        Write-Host "Could not extract file ID from response" -ForegroundColor Red
    }
    
    Remove-Item $testFilePath -Force
    
} catch {
    Write-Host "Upload failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $responseStream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($responseStream)
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody" -ForegroundColor Gray
    }
}

Write-Host "`n=== Debug Test Completed ===" -ForegroundColor Green