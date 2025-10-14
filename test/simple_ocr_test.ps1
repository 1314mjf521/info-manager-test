# Simple OCR Test Script
# Test OCR recognition functionality

param(
    [string]$ServerUrl = "http://localhost:8080"
)

Write-Host "=== OCR Recognition Test ===" -ForegroundColor Green
Write-Host "Server URL: $ServerUrl" -ForegroundColor Yellow
Write-Host ""

# Global variables
$global:Token = ""

# Helper function: Send HTTP request
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
            ContentType = $ContentType
        }
        
        if ($Body -ne $null) {
            if ($ContentType -eq "application/json") {
                $params.Body = $Body | ConvertTo-Json -Depth 10
            } else {
                $params.Body = $Body
            }
        }
        
        $response = Invoke-RestMethod @params
        return @{ Success = $true; Data = $response }
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

# 1. User login
function Test-UserLogin {
    Write-Host "1. User login test..." -ForegroundColor Cyan
    
    $loginData = @{
        username = "admin"
        password = "admin123"
    }
    
    $result = Invoke-ApiRequest -Method POST -Uri "$ServerUrl/api/v1/auth/login" -Body $loginData
    
    if ($result.Success) {
        $global:Token = $result.Data.token
        Write-Host "Login successful" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Login failed: $($result.Error)" -ForegroundColor Red
        return $false
    }
}

# 2. Test OCR languages
function Test-OCRLanguages {
    Write-Host "2. Test OCR supported languages..." -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $global:Token"
    }
    
    $result = Invoke-ApiRequest -Method GET -Uri "$ServerUrl/api/v1/files/ocr/languages" -Headers $headers
    
    if ($result.Success) {
        Write-Host "Get supported languages successful" -ForegroundColor Green
        Write-Host "Supported languages:" -ForegroundColor Gray
        foreach ($lang in $result.Data.languages) {
            Write-Host "  $($lang.code): $($lang.name)" -ForegroundColor White
        }
        return $true
    } else {
        Write-Host "Get supported languages failed: $($result.Error)" -ForegroundColor Red
        return $false
    }
}

# 3. Test OCR recognition
function Test-OCRRecognition {
    param([string]$FilePath, [string]$Language = "auto")
    
    Write-Host "3. Test OCR recognition..." -ForegroundColor Cyan
    Write-Host "   File: $FilePath" -ForegroundColor Gray
    Write-Host "   Language: $Language" -ForegroundColor Gray
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "File not found: $FilePath" -ForegroundColor Red
        return $false
    }
    
    $headers = @{
        "Authorization" = "Bearer $global:Token"
    }
    
    # Create multipart/form-data content
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    
    # Read file
    $fileInfo = Get-Item $FilePath
    $fileName = $fileInfo.Name
    $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)
    
    $bodyLines = @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"image`"; filename=`"$fileName`"",
        "Content-Type: image/png",
        "",
        [System.Text.Encoding]::GetEncoding("iso-8859-1").GetString($fileBytes),
        "--$boundary",
        "Content-Disposition: form-data; name=`"language`"",
        "",
        $Language,
        "--$boundary--"
    )
    
    $body = $bodyLines -join $LF
    $bodyBytes = [System.Text.Encoding]::GetEncoding("iso-8859-1").GetBytes($body)
    
    $headers["Content-Type"] = "multipart/form-data; boundary=$boundary"
    
    try {
        $response = Invoke-RestMethod -Uri "$ServerUrl/api/v1/files/ocr" -Method POST -Headers $headers -Body $bodyBytes
        
        Write-Host "OCR recognition successful" -ForegroundColor Green
        Write-Host "   Language: $($response.language)" -ForegroundColor Gray
        Write-Host "   Confidence: $($response.confidence)" -ForegroundColor Gray
        Write-Host "   Process time: $($response.process_time)ms" -ForegroundColor Gray
        Write-Host "   Recognized text:" -ForegroundColor Gray
        Write-Host "   $($response.text)" -ForegroundColor White
        
        return $response
    }
    catch {
        Write-Host "OCR recognition failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Main test function
function Main {
    Write-Host "Starting OCR recognition test..." -ForegroundColor Green
    
    # Check if test images exist
    $testDir = "test/test_images"
    if (-not (Test-Path $testDir)) {
        Write-Host "Test images directory not found, creating test images..." -ForegroundColor Yellow
        python test/create_test_image.py
    }
    
    # 1. User login
    if (-not (Test-UserLogin)) {
        Write-Host "Login failed, cannot continue test" -ForegroundColor Red
        return
    }
    
    Write-Host ""
    
    # 2. Test OCR supported languages
    Test-OCRLanguages
    
    Write-Host ""
    
    # 3. Test OCR recognition with different images
    $testImages = @(
        @{ Path = "$testDir/ocr_test_english.png"; Language = "en"; Description = "English test image" },
        @{ Path = "$testDir/ocr_test_chinese.png"; Language = "zh-cn"; Description = "Chinese test image" },
        @{ Path = "$testDir/ocr_test_mixed.png"; Language = "auto"; Description = "Mixed language test image" }
    )
    
    $results = @()
    
    foreach ($testImage in $testImages) {
        Write-Host "--- Testing: $($testImage.Description) ---" -ForegroundColor Yellow
        
        $ocrResult = Test-OCRRecognition -FilePath $testImage.Path -Language $testImage.Language
        
        $results += @{
            Image = $testImage.Description
            Path = $testImage.Path
            Language = $testImage.Language
            Result = $ocrResult
            Success = ($ocrResult -ne $null)
        }
        
        Write-Host ""
        Start-Sleep -Seconds 1
    }
    
    # Generate summary
    Write-Host "=== Test Summary ===" -ForegroundColor Magenta
    $successCount = ($results | Where-Object { $_.Success }).Count
    $totalCount = $results.Count
    
    Write-Host "Total tests: $totalCount" -ForegroundColor White
    Write-Host "Successful: $successCount" -ForegroundColor Green
    Write-Host "Failed: $($totalCount - $successCount)" -ForegroundColor Red
    Write-Host "Success rate: $([math]::Round($successCount / $totalCount * 100, 2))%" -ForegroundColor Yellow
    
    Write-Host "`nDetailed results:" -ForegroundColor White
    foreach ($result in $results) {
        $status = if ($result.Success) { "✓" } else { "✗" }
        $color = if ($result.Success) { "Green" } else { "Red" }
        Write-Host "  $status $($result.Image)" -ForegroundColor $color
    }
    
    Write-Host "`nOCR recognition test completed!" -ForegroundColor Green
}

# Execute main function
Main