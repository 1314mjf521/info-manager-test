# Quick OCR Test
Write-Host "=== Quick OCR Test ===" -ForegroundColor Green

# Wait for server to start
Start-Sleep -Seconds 3

# Test server health
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body '{"username":"admin","password":"admin123"}' -ContentType "application/json"
    $token = $healthResponse.data.token
    Write-Host "✓ Server is running and login successful" -ForegroundColor Green
} catch {
    Write-Host "✗ Server not responding or login failed" -ForegroundColor Red
    exit 1
}

# Test OCR languages endpoint
try {
    $headers = @{ "Authorization" = "Bearer $token" }
    $langResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/ocr/languages" -Method GET -Headers $headers
    Write-Host "✓ OCR languages endpoint working" -ForegroundColor Green
    Write-Host "Languages: $($langResponse.data.languages.Count) supported" -ForegroundColor Cyan
    
    foreach ($lang in $langResponse.data.languages) {
        Write-Host "  - $($lang.code): $($lang.name)" -ForegroundColor White
    }
} catch {
    Write-Host "✗ OCR languages endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test OCR recognition with a simple test
if (Test-Path "test/test_images/ocr_test_english.png") {
    Write-Host "`n=== Testing OCR Recognition ===" -ForegroundColor Yellow
    
    # Create a simple test request
    $testImagePath = "test/test_images/ocr_test_english.png"
    $boundary = [System.Guid]::NewGuid().ToString()
    $fileBytes = [System.IO.File]::ReadAllBytes($testImagePath)
    $fileName = "ocr_test_english.png"
    
    $bodyLines = @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
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
        $ocrResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/ocr" -Method POST -Headers $ocrHeaders -Body $bodyBytes
        Write-Host "✓ OCR Recognition successful!" -ForegroundColor Green
        Write-Host "Language: $($ocrResponse.data.language)" -ForegroundColor Cyan
        Write-Host "Confidence: $($ocrResponse.data.confidence)" -ForegroundColor Cyan
        Write-Host "Process Time: $($ocrResponse.data.process_time)ms" -ForegroundColor Cyan
        Write-Host "Recognized Text:" -ForegroundColor Cyan
        Write-Host "$($ocrResponse.data.text)" -ForegroundColor White
        
        if ($ocrResponse.data.regions) {
            Write-Host "`nRegions:" -ForegroundColor Cyan
            for ($i = 0; $i -lt $ocrResponse.data.regions.Count; $i++) {
                $region = $ocrResponse.data.regions[$i]
                Write-Host "  Region $($i+1): $($region.text) (Confidence: $($region.confidence))" -ForegroundColor White
            }
        }
    } catch {
        Write-Host "✗ OCR Recognition failed: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Test image not found, creating test images..." -ForegroundColor Yellow
    python test/create_test_image.py
    Write-Host "Test images created, please run the test again." -ForegroundColor Green
}

Write-Host "`n=== OCR Test Completed ===" -ForegroundColor Green