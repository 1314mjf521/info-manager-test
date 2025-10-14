# 文件处理API测试脚本

Write-Host "=== 文件处理服务API测试开始 ===" -ForegroundColor Green

# 等待服务器启动
Start-Sleep -Seconds 3

# 1. 健康检查
Write-Host "`n1. 健康检查..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET
    Write-Host "✓ 健康检查成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 健康检查失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. 用户登录
Write-Host "`n2. 用户登录..." -ForegroundColor Yellow
$loginData = '{"username":"admin","password":"admin123"}'
try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -ContentType "application/json" -Body $loginData
    $token = $loginResponse.data.token
    $headers = @{ "Authorization" = "Bearer $token" }
    Write-Host "✓ 登录成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. 创建测试文件
Write-Host "`n3. 创建测试文件..." -ForegroundColor Yellow
$testContent = "This is a test file for file upload API testing.`nCreated at: $(Get-Date)"
$testFilePath = "test_upload_file.txt"
Set-Content -Path $testFilePath -Value $testContent -Encoding UTF8
Write-Host "✓ 测试文件创建成功: $testFilePath" -ForegroundColor Green

# 4. 测试文件上传
Write-Host "`n4. 测试文件上传..." -ForegroundColor Yellow
try {
    $boundary = [System.Guid]::NewGuid().ToString()
    $bodyLines = @(
        "--$boundary",
        'Content-Disposition: form-data; name="file"; filename="test_upload_file.txt"',
        'Content-Type: text/plain',
        '',
        $testContent,
        "--$boundary",
        'Content-Disposition: form-data; name="description"',
        '',
        'API test file upload',
        "--$boundary",
        'Content-Disposition: form-data; name="category"',
        '',
        'test',
        "--$boundary--"
    )
    $body = $bodyLines -join "`r`n"
    
    $uploadHeaders = $headers.Clone()
    $uploadHeaders["Content-Type"] = "multipart/form-data; boundary=$boundary"
    
    $uploadResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/upload" -Method POST -Headers $uploadHeaders -Body $body
    $fileId = $uploadResponse.data.id
    Write-Host "✓ 文件上传成功，ID: $fileId" -ForegroundColor Green
    Write-Host "  文件名: $($uploadResponse.data.original_name)" -ForegroundColor Cyan
    Write-Host "  大小: $($uploadResponse.data.size) bytes" -ForegroundColor Cyan
    Write-Host "  类型: $($uploadResponse.data.mime_type)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 文件上传失败: $($_.Exception.Message)" -ForegroundColor Red
    $fileId = $null
}

# 5. 测试获取文件列表
Write-Host "`n5. 测试获取文件列表..." -ForegroundColor Yellow
try {
    $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files" -Method GET -Headers $headers
    Write-Host "✓ 获取文件列表成功" -ForegroundColor Green
    Write-Host "  总文件数: $($filesResponse.data.total)" -ForegroundColor Cyan
    Write-Host "  当前页文件数: $($filesResponse.data.files.Count)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 获取文件列表失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. 测试获取文件信息
if ($fileId) {
    Write-Host "`n6. 测试获取文件信息..." -ForegroundColor Yellow
    try {
        $fileInfoResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/$fileId/info" -Method GET -Headers $headers
        Write-Host "✓ 获取文件信息成功" -ForegroundColor Green
        Write-Host "  文件ID: $($fileInfoResponse.data.id)" -ForegroundColor Cyan
        Write-Host "  原始名称: $($fileInfoResponse.data.original_name)" -ForegroundColor Cyan
        Write-Host "  上传者: $($fileInfoResponse.data.uploader)" -ForegroundColor Cyan
    } catch {
        Write-Host "✗ 获取文件信息失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 7. 测试文件下载
if ($fileId) {
    Write-Host "`n7. 测试文件下载..." -ForegroundColor Yellow
    try {
        $downloadResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/files/$fileId" -Method GET -Headers $headers
        if ($downloadResponse.StatusCode -eq 200) {
            Write-Host "✓ 文件下载成功" -ForegroundColor Green
            Write-Host "  响应大小: $($downloadResponse.Content.Length) bytes" -ForegroundColor Cyan
            Write-Host "  Content-Type: $($downloadResponse.Headers['Content-Type'])" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "✗ 文件下载失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 8. 创建测试图片文件用于OCR
Write-Host "`n8. 创建测试图片文件..." -ForegroundColor Yellow
$imageContent = @"
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAI9jU77yQAAAABJRU5ErkJggg==
"@
$imageBytes = [Convert]::FromBase64String($imageContent)
$imageFilePath = "test_image.png"
[System.IO.File]::WriteAllBytes($imageFilePath, $imageBytes)
Write-Host "✓ 测试图片文件创建成功: $imageFilePath" -ForegroundColor Green

# 9. 测试OCR支持的语言
Write-Host "`n9. 测试OCR支持的语言..." -ForegroundColor Yellow
try {
    $languagesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/ocr/languages" -Method GET -Headers $headers
    Write-Host "✓ 获取OCR支持语言成功" -ForegroundColor Green
    Write-Host "  支持的语言: $($languagesResponse.data.languages -join ', ')" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 获取OCR支持语言失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 10. 测试OCR文字识别
Write-Host "`n10. 测试OCR文字识别..." -ForegroundColor Yellow
try {
    $ocrBoundary = [System.Guid]::NewGuid().ToString()
    $ocrBodyLines = @(
        "--$ocrBoundary",
        'Content-Disposition: form-data; name="file"; filename="test_image.png"',
        'Content-Type: image/png',
        '',
        [System.Text.Encoding]::UTF8.GetString($imageBytes),
        "--$ocrBoundary",
        'Content-Disposition: form-data; name="language"',
        '',
        'zh-cn',
        "--$ocrBoundary--"
    )
    $ocrBody = $ocrBodyLines -join "`r`n"
    
    $ocrHeaders = $headers.Clone()
    $ocrHeaders["Content-Type"] = "multipart/form-data; boundary=$ocrBoundary"
    
    $ocrResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/ocr" -Method POST -Headers $ocrHeaders -Body $ocrBody
    Write-Host "✓ OCR识别成功" -ForegroundColor Green
    Write-Host "  识别语言: $($ocrResponse.data.language)" -ForegroundColor Cyan
    Write-Host "  置信度: $($ocrResponse.data.confidence)" -ForegroundColor Cyan
    Write-Host "  处理时间: $($ocrResponse.data.process_time)ms" -ForegroundColor Cyan
    Write-Host "  识别文本: $($ocrResponse.data.text)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ OCR识别失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 11. 测试文件搜索
Write-Host "`n11. 测试文件搜索..." -ForegroundColor Yellow
try {
    $searchResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files?search=test" -Method GET -Headers $headers
    Write-Host "✓ 文件搜索成功" -ForegroundColor Green
    Write-Host "  搜索结果数: $($searchResponse.data.total)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 文件搜索失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 12. 测试按类型过滤文件
Write-Host "`n12. 测试按类型过滤文件..." -ForegroundColor Yellow
try {
    $filterResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files?mime_type=text/plain" -Method GET -Headers $headers
    Write-Host "✓ 文件类型过滤成功" -ForegroundColor Green
    Write-Host "  过滤结果数: $($filterResponse.data.total)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 文件类型过滤失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 13. 测试删除文件
if ($fileId) {
    Write-Host "`n13. 测试删除文件..." -ForegroundColor Yellow
    try {
        $deleteResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/$fileId" -Method DELETE -Headers $headers
        Write-Host "✓ 文件删除成功" -ForegroundColor Green
        Write-Host "  删除消息: $($deleteResponse.data.message)" -ForegroundColor Cyan
    } catch {
        Write-Host "✗ 文件删除失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 清理测试文件
Write-Host "`n清理测试文件..." -ForegroundColor Yellow
Remove-Item -Path $testFilePath -ErrorAction SilentlyContinue
Remove-Item -Path $imageFilePath -ErrorAction SilentlyContinue
Write-Host "✓ 测试文件清理完成" -ForegroundColor Green

Write-Host "`n=== 文件处理服务API测试完成 ===" -ForegroundColor Green