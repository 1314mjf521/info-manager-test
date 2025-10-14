# Complete OCR Test
Write-Host "=== Complete OCR Test ===" -ForegroundColor Green

# Login
$loginData = @{ username = "admin"; password = "admin123" }
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
$token = $loginResponse.data.token
Write-Host "✓ Login successful" -ForegroundColor Green

$headers = @{ "Authorization" = "Bearer $token" }

# Test images
$testImages = @(
    @{ Path = "test/test_images/ocr_test_english.png"; Language = "en"; Description = "English Test Image" },
    @{ Path = "test/test_images/ocr_test_chinese.png"; Language = "zh-cn"; Description = "Chinese Test Image" },
    @{ Path = "test/test_images/ocr_test_mixed.png"; Language = "auto"; Description = "Mixed Language Test Image" }
)

$results = @()

foreach ($testImage in $testImages) {
    Write-Host "`n--- Testing: $($testImage.Description) ---" -ForegroundColor Yellow
    
    if (-not (Test-Path $testImage.Path)) {
        Write-Host "✗ Test image not found: $($testImage.Path)" -ForegroundColor Red
        continue
    }
    
    # Create multipart form data
    $boundary = [System.Guid]::NewGuid().ToString()
    $fileBytes = [System.IO.File]::ReadAllBytes($testImage.Path)
    $fileName = Split-Path $testImage.Path -Leaf
    
    $bodyLines = @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
        "Content-Type: image/png",
        "",
        [System.Text.Encoding]::GetEncoding("iso-8859-1").GetString($fileBytes),
        "--$boundary",
        "Content-Disposition: form-data; name=`"language`"",
        "",
        $testImage.Language,
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
        Write-Host "  Language: $($ocrResponse.data.language)" -ForegroundColor Cyan
        Write-Host "  Confidence: $($ocrResponse.data.confidence)" -ForegroundColor Cyan
        Write-Host "  Process Time: $($ocrResponse.data.process_time)ms" -ForegroundColor Cyan
        Write-Host "  Text Length: $($ocrResponse.data.text.Length) characters" -ForegroundColor Cyan
        Write-Host "  Recognized Text:" -ForegroundColor Cyan
        Write-Host "    $($ocrResponse.data.text.Substring(0, [Math]::Min(100, $ocrResponse.data.text.Length)))..." -ForegroundColor White
        
        if ($ocrResponse.data.regions) {
            Write-Host "  Regions: $($ocrResponse.data.regions.Count)" -ForegroundColor Cyan
        }
        
        $results += @{
            Image = $testImage.Description
            Success = $true
            Language = $ocrResponse.data.language
            Confidence = $ocrResponse.data.confidence
            TextLength = $ocrResponse.data.text.Length
            ProcessTime = $ocrResponse.data.process_time
        }
        
    } catch {
        Write-Host "✗ OCR Recognition failed: $($_.Exception.Message)" -ForegroundColor Red
        $results += @{
            Image = $testImage.Description
            Success = $false
            Error = $_.Exception.Message
        }
    }
    
    Start-Sleep -Seconds 1
}

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
    if ($result.Success) {
        Write-Host "  ✓ $($result.Image)" -ForegroundColor Green
        Write-Host "    Language: $($result.Language), Confidence: $($result.Confidence), Text: $($result.TextLength) chars, Time: $($result.ProcessTime)ms" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ $($result.Image): $($result.Error)" -ForegroundColor Red
    }
}

Write-Host "`n=== Complete OCR Test Finished ===" -ForegroundColor Green