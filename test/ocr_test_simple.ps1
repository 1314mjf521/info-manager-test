# OCR Test Script
param([string]$ServerUrl = "http://localhost:8080")

Write-Host "=== OCR Test ===" -ForegroundColor Green

# Login
$loginData = @{ username = "admin"; password = "admin123" }
$loginResponse = Invoke-RestMethod -Uri "$ServerUrl/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
$token = $loginResponse.token
Write-Host "Login successful" -ForegroundColor Green

# Test OCR languages
$headers = @{ "Authorization" = "Bearer $token" }
$langResponse = Invoke-RestMethod -Uri "$ServerUrl/api/v1/files/ocr/languages" -Method GET -Headers $headers
Write-Host "Supported languages:" -ForegroundColor Yellow
foreach ($lang in $langResponse.languages) {
    Write-Host "  $($lang.code): $($lang.name)"
}

# Test OCR with image
$testImagePath = "test/test_images/ocr_test_english.png"
if (Test-Path $testImagePath) {
    Write-Host "`nTesting OCR with: $testImagePath" -ForegroundColor Yellow
    
    # Create multipart form data
    $boundary = [System.Guid]::NewGuid().ToString()
    $fileBytes = [System.IO.File]::ReadAllBytes($testImagePath)
    $fileName = Split-Path $testImagePath -Leaf
    
    $bodyLines = @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"image`"; filename=`"$fileName`"",
        "Content-Type: image/png",
        "",
        [System.Text.Encoding]::GetEncoding("iso-8859-1").GetString($fileBytes),
        "--$boundary",
        "Content-Disposition: form-data; name=`"language`"",
        "",
        "en",
        "--$boundary--"
    )
    
    $body = $bodyLines -join "`r`n"
    $bodyBytes = [System.Text.Encoding]::GetEncoding("iso-8859-1").GetBytes($body)
    
    $ocrHeaders = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "multipart/form-data; boundary=$boundary"
    }
    
    try {
        $ocrResponse = Invoke-RestMethod -Uri "$ServerUrl/api/v1/files/ocr" -Method POST -Headers $ocrHeaders -Body $bodyBytes
        Write-Host "OCR Success!" -ForegroundColor Green
        Write-Host "Language: $($ocrResponse.language)"
        Write-Host "Confidence: $($ocrResponse.confidence)"
        Write-Host "Text: $($ocrResponse.text)"
    }
    catch {
        Write-Host "OCR failed: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Test image not found: $testImagePath" -ForegroundColor Red
}

Write-Host "`nOCR test completed!" -ForegroundColor Green