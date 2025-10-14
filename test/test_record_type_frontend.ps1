# 测试记录类型前端功能的脚本
# 编码：UTF-8

Write-Host "=== 测试记录类型前端功能 ===" -ForegroundColor Green

# 设置基础变量
$baseUrl = "http://localhost:8080"
$adminToken = ""

# 函数：获取管理员Token
function Get-AdminToken {
    Write-Host "正在获取管理员Token..." -ForegroundColor Yellow
    
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method Post -Body $loginData -ContentType "application/json"
        if ($response.success) {
            Write-Host "✓ 管理员登录成功" -ForegroundColor Green
            return $response.data.token
        } else {
            Write-Host "✗ 管理员登录失败: $($response.error.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 管理员登录请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 函数：模拟前端导入请求
function Test-FrontendImportRequest {
    param($token)
    
    Write-Host "`n--- 模拟前端导入请求 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 模拟前端发送的导入数据格式
    $frontendImportData = @{
        recordTypes = @(
            @{
                name = "frontend_test_daily"
                displayName = "前端测试日报"
                schema = ""
                isActive = "true"
            },
            @{
                name = "frontend_test_weekly"
                displayName = "前端测试周报"
                schema = '{"type":"object","properties":{"title":{"type":"string"},"content":{"type":"string"}}}'
                isActive = "true"
            }
        )
    } | ConvertTo-Json -Depth 10
    
    Write-Host "发送前端格式的导入请求..." -ForegroundColor Yellow
    Write-Host "请求数据格式:" -ForegroundColor Gray
    Write-Host $frontendImportData -ForegroundColor DarkGray
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/import" -Method Post -Body $frontendImportData -Headers $headers
        
        if ($response.success) {
            Write-Host "✓ 前端导入请求成功" -ForegroundColor Green
            
            $results = $response.data.results
            foreach ($result in $results) {
                if ($result.success) {
                    Write-Host "  ✓ $($result.displayName) 导入成功" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ $($result.displayName) 导入失败: $($result.error)" -ForegroundColor Red
                }
            }
            
            return $results
        } else {
            Write-Host "✗ 前端导入请求失败: $($response.error.message)" -ForegroundColor Red
            return @()
        }
    } catch {
        Write-Host "✗ 前端导入请求异常: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "HTTP状态码: $statusCode" -ForegroundColor Red
            
            # 尝试读取错误响应
            try {
                $errorStream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($errorStream)
                $errorBody = $reader.ReadToEnd()
                Write-Host "错误响应: $errorBody" -ForegroundColor Red
            } catch {
                Write-Host "无法读取错误响应" -ForegroundColor Yellow
            }
        }
        return @()
    }
}

# 函数：模拟前端批量操作请求
function Test-FrontendBatchOperations {
    param($token)
    
    Write-Host "`n--- 模拟前端批量操作请求 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 先获取记录类型列表
    try {
        $typesResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types" -Method Get -Headers $headers
        
        if ($typesResponse.success) {
            $testTypes = $typesResponse.data | Where-Object { $_.name -like "frontend_test_*" }
            
            if ($testTypes.Count -gt 0) {
                Write-Host "找到 $($testTypes.Count) 个前端测试记录类型" -ForegroundColor Gray
                
                $testTypeIds = $testTypes | ForEach-Object { $_.id }
                
                # 测试批量状态更新（前端格式）
                Write-Host "1. 测试前端批量状态更新..." -ForegroundColor Yellow
                $batchStatusData = @{
                    record_type_ids = $testTypeIds
                    is_active = $false
                } | ConvertTo-Json -Depth 10
                
                Write-Host "请求数据: $batchStatusData" -ForegroundColor DarkGray
                
                try {
                    $statusResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/batch-status" -Method Put -Body $batchStatusData -Headers $headers
                    if ($statusResponse.success) {
                        Write-Host "  ✓ 前端批量状态更新成功" -ForegroundColor Green
                    } else {
                        Write-Host "  ✗ 前端批量状态更新失败: $($statusResponse.error.message)" -ForegroundColor Red
                    }
                } catch {
                    Write-Host "  ✗ 前端批量状态更新请求失败: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                # 测试批量删除（前端格式）
                Write-Host "2. 测试前端批量删除..." -ForegroundColor Yellow
                $batchDeleteData = @{
                    record_type_ids = $testTypeIds
                } | ConvertTo-Json -Depth 10
                
                Write-Host "请求数据: $batchDeleteData" -ForegroundColor DarkGray
                
                try {
                    $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/batch" -Method Delete -Body $batchDeleteData -Headers $headers
                    if ($deleteResponse.success) {
                        Write-Host "  ✓ 前端批量删除成功" -ForegroundColor Green
                    } else {
                        Write-Host "  ✗ 前端批量删除失败: $($deleteResponse.error.message)" -ForegroundColor Red
                    }
                } catch {
                    Write-Host "  ✗ 前端批量删除请求失败: $($_.Exception.Message)" -ForegroundColor Red
                }
                
            } else {
                Write-Host "! 没有找到前端测试记录类型" -ForegroundColor Yellow
            }
        } else {
            Write-Host "✗ 获取记录类型列表失败: $($typesResponse.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 获取记录类型列表请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 函数：检查前端请求格式兼容性
function Test-RequestFormatCompatibility {
    param($token)
    
    Write-Host "`n--- 检查前端请求格式兼容性 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 测试不同的请求格式
    $testCases = @(
        @{
            Name = "标准格式"
            Data = @{
                recordTypes = @(
                    @{
                        name = "format_test_1"
                        displayName = "格式测试1"
                        schema = '{"type":"object"}'
                        isActive = "true"
                    }
                )
            }
        },
        @{
            Name = "布尔值格式"
            Data = @{
                recordTypes = @(
                    @{
                        name = "format_test_2"
                        displayName = "格式测试2"
                        schema = ""
                        isActive = $true
                    }
                )
            }
        },
        @{
            Name = "数字格式"
            Data = @{
                recordTypes = @(
                    @{
                        name = "format_test_3"
                        displayName = "格式测试3"
                        schema = ""
                        isActive = 1
                    }
                )
            }
        }
    )
    
    foreach ($testCase in $testCases) {
        Write-Host "测试 $($testCase.Name)..." -ForegroundColor Yellow
        
        $testData = $testCase.Data | ConvertTo-Json -Depth 10
        
        try {
            $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/import" -Method Post -Body $testData -Headers $headers
            
            if ($response.success) {
                Write-Host "  ✓ $($testCase.Name) 格式兼容" -ForegroundColor Green
                
                # 清理测试数据
                $results = $response.data.results
                foreach ($result in $results) {
                    if ($result.success -and $result.record_type_id) {
                        try {
                            Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/$($result.record_type_id)" -Method Delete -Headers $headers | Out-Null
                        } catch {
                            # 忽略清理错误
                        }
                    }
                }
            } else {
                Write-Host "  ✗ $($testCase.Name) 格式不兼容: $($response.error.message)" -ForegroundColor Red
            }
        } catch {
            Write-Host "  ✗ $($testCase.Name) 格式请求失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 函数：生成前端调试信息
function Generate-FrontendDebugInfo {
    param($token)
    
    Write-Host "`n--- 生成前端调试信息 ---" -ForegroundColor Cyan
    
    Write-Host "前端开发者调试指南:" -ForegroundColor Yellow
    Write-Host "1. 检查网络请求" -ForegroundColor Gray
    Write-Host "   - 打开浏览器开发者工具 (F12)" -ForegroundColor Gray
    Write-Host "   - 切换到 Network 标签页" -ForegroundColor Gray
    Write-Host "   - 执行导入或批量操作" -ForegroundColor Gray
    Write-Host "   - 查看请求的状态码和响应内容" -ForegroundColor Gray
    
    Write-Host "`n2. 检查请求格式" -ForegroundColor Gray
    Write-Host "   导入请求应该发送到: POST $baseUrl/api/v1/record-types/import" -ForegroundColor Gray
    Write-Host "   批量状态更新: PUT $baseUrl/api/v1/record-types/batch-status" -ForegroundColor Gray
    Write-Host "   批量删除: DELETE $baseUrl/api/v1/record-types/batch" -ForegroundColor Gray
    
    Write-Host "`n3. 检查请求头" -ForegroundColor Gray
    Write-Host "   Content-Type: application/json" -ForegroundColor Gray
    Write-Host "   Authorization: Bearer [token]" -ForegroundColor Gray
    
    Write-Host "`n4. 检查请求体格式" -ForegroundColor Gray
    Write-Host "   导入格式示例:" -ForegroundColor Gray
    $importExample = @{
        recordTypes = @(
            @{
                name = "example_type"
                displayName = "示例类型"
                schema = '{"type":"object","properties":{"title":{"type":"string"}}}'
                isActive = "true"
            }
        )
    } | ConvertTo-Json -Depth 10
    Write-Host $importExample -ForegroundColor DarkGray
    
    Write-Host "`n5. 常见错误排查" -ForegroundColor Gray
    Write-Host "   - 404: 接口不存在，检查URL路径" -ForegroundColor Gray
    Write-Host "   - 403: 权限不足，检查用户权限" -ForegroundColor Gray
    Write-Host "   - 400/422: 请求格式错误，检查请求体" -ForegroundColor Gray
    Write-Host "   - 500: 服务器错误，检查后端日志" -ForegroundColor Gray
}

# 主执行流程
try {
    # 获取管理员Token
    $adminToken = Get-AdminToken
    if (-not $adminToken) {
        Write-Host "无法获取管理员Token，测试终止" -ForegroundColor Red
        exit 1
    }
    
    # 测试前端导入请求
    $importResults = Test-FrontendImportRequest -token $adminToken
    
    # 等待数据同步
    Start-Sleep -Seconds 2
    
    # 测试前端批量操作
    Test-FrontendBatchOperations -token $adminToken
    
    # 测试请求格式兼容性
    Test-RequestFormatCompatibility -token $adminToken
    
    # 生成前端调试信息
    Generate-FrontendDebugInfo -token $adminToken
    
    Write-Host "`n=== 前端功能测试完成 ===" -ForegroundColor Green
    
    # 测试结果总结
    Write-Host "`n=== 测试结果总结 ===" -ForegroundColor Magenta
    if ($importResults.Count -gt 0) {
        Write-Host "✓ 前端导入功能基本正常" -ForegroundColor Green
    } else {
        Write-Host "✗ 前端导入功能存在问题" -ForegroundColor Red
        Write-Host "建议检查:" -ForegroundColor Yellow
        Write-Host "1. 后端服务是否正常运行" -ForegroundColor Gray
        Write-Host "2. 接口路由是否正确配置" -ForegroundColor Gray
        Write-Host "3. 权限验证是否通过" -ForegroundColor Gray
        Write-Host "4. 请求数据格式是否正确" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "测试过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}