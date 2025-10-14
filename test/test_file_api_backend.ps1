# Test File API Backend
Write-Host "=== 测试后端文件API ===" -ForegroundColor Green

# Login first
Write-Host "`n1. 登录获取token..." -ForegroundColor Yellow
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    Write-Host "✅ 登录成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
}

# Test file list API
Write-Host "`n2. 测试文件列表API..." -ForegroundColor Yellow
try {
    $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files" -Method GET -Headers $headers
    Write-Host "✅ 文件列表API调用成功" -ForegroundColor Green
    Write-Host "响应格式:" -ForegroundColor Cyan
    Write-Host ($filesResponse | ConvertTo-Json -Depth 3) -ForegroundColor Gray
    
    # 分析响应格式
    if ($filesResponse.success -and $filesResponse.data) {
        Write-Host "`n📋 响应格式分析:" -ForegroundColor Yellow
        Write-Host "- 标准成功响应格式: response.success = true, response.data = {...}" -ForegroundColor White
        
        if ($filesResponse.data.items) {
            Write-Host "- 文件列表位置: response.data.items" -ForegroundColor White
            Write-Host "- 文件数量: $($filesResponse.data.items.Count)" -ForegroundColor White
        } elseif ($filesResponse.data.files) {
            Write-Host "- 文件列表位置: response.data.files" -ForegroundColor White
            Write-Host "- 文件数量: $($filesResponse.data.files.Count)" -ForegroundColor White
        } elseif ($filesResponse.data -is [array]) {
            Write-Host "- 文件列表位置: response.data (直接数组)" -ForegroundColor White
            Write-Host "- 文件数量: $($filesResponse.data.Count)" -ForegroundColor White
        } else {
            Write-Host "- 未识别的数据格式" -ForegroundColor Red
        }
        
        if ($filesResponse.data.total) {
            Write-Host "- 总数字段: response.data.total = $($filesResponse.data.total)" -ForegroundColor White
        }
        
    } elseif ($filesResponse.items) {
        Write-Host "`n📋 响应格式分析:" -ForegroundColor Yellow
        Write-Host "- 直接items格式: response.items" -ForegroundColor White
        Write-Host "- 文件数量: $($filesResponse.items.Count)" -ForegroundColor White
        
        if ($filesResponse.total) {
            Write-Host "- 总数字段: response.total = $($filesResponse.total)" -ForegroundColor White
        }
        
    } elseif ($filesResponse -is [array]) {
        Write-Host "`n📋 响应格式分析:" -ForegroundColor Yellow
        Write-Host "- 直接数组格式: response = [...]" -ForegroundColor White
        Write-Host "- 文件数量: $($filesResponse.Count)" -ForegroundColor White
    } else {
        Write-Host "`n❌ 未识别的响应格式" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ 文件列表API调用失败: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "HTTP状态码: $statusCode" -ForegroundColor Yellow
        
        if ($statusCode -eq 404) {
            Write-Host "可能的原因: 文件API端点不存在或路径错误" -ForegroundColor Yellow
        } elseif ($statusCode -eq 403) {
            Write-Host "可能的原因: 用户没有文件管理权限" -ForegroundColor Yellow
        } elseif ($statusCode -eq 401) {
            Write-Host "可能的原因: token无效或已过期" -ForegroundColor Yellow
        }
    }
}

# Test file upload (if we have a test file)
Write-Host "`n3. 测试文件上传API..." -ForegroundColor Yellow
$testFilePath = "test_upload.txt"

# Create a simple test file
"This is a test file for upload testing.`nCreated at: $(Get-Date)" | Out-File -FilePath $testFilePath -Encoding UTF8

if (Test-Path $testFilePath) {
    try {
        # PowerShell file upload is complex, let's just test if the endpoint exists
        Write-Host "测试文件已创建: $testFilePath" -ForegroundColor White
        Write-Host "文件上传需要在浏览器中测试，这里只验证端点可达性" -ForegroundColor Yellow
        
        # Test if upload endpoint is reachable (will fail but we can see the error)
        try {
            Invoke-RestMethod -Uri "http://localhost:8080/api/v1/files/upload" -Method POST -Headers $headers
        } catch {
            if ($_.Exception.Response.StatusCode -eq 400) {
                Write-Host "✅ 上传端点可达（返回400是因为没有文件数据，这是正常的）" -ForegroundColor Green
            } else {
                Write-Host "上传端点状态: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
            }
        }
        
    } catch {
        Write-Host "❌ 文件上传测试失败: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        # Clean up test file
        if (Test-Path $testFilePath) {
            Remove-Item $testFilePath -Force
        }
    }
} else {
    Write-Host "❌ 无法创建测试文件" -ForegroundColor Red
}

Write-Host "`n=== 后端API测试完成 ===" -ForegroundColor Green
Write-Host "`n💡 前端集成建议:" -ForegroundColor Blue
Write-Host "根据上面的响应格式分析，前端应该相应调整数据处理逻辑" -ForegroundColor White
Write-Host "确保 fetchFiles() 函数能正确解析后端返回的数据格式" -ForegroundColor White