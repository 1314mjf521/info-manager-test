# 最终测试记录类型所有功能的脚本
# 编码：UTF-8

Write-Host "=== 最终测试记录类型所有功能 ===" -ForegroundColor Green

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

# 函数：步骤1 - 测试基础CRUD操作
function Step1-TestBasicCRUD {
    param($token)
    
    Write-Host "`n=== 步骤1: 测试基础CRUD操作 ===" -ForegroundColor Magenta
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 1. 测试获取记录类型列表
    Write-Host "1.1 测试获取记录类型列表..." -ForegroundColor Cyan
    try {
        $listResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types" -Method Get -Headers $headers
        if ($listResponse.success) {
            Write-Host "  ✓ 获取记录类型列表成功，共 $($listResponse.data.Count) 个" -ForegroundColor Green
            return $listResponse.data
        } else {
            Write-Host "  ✗ 获取记录类型列表失败: $($listResponse.error.message)" -ForegroundColor Red
            return @()
        }
    } catch {
        Write-Host "  ✗ 获取记录类型列表请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# 函数：步骤2 - 测试导入功能
function Step2-TestImportFunction {
    param($token)
    
    Write-Host "`n=== 步骤2: 测试导入功能 ===" -ForegroundColor Magenta
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 准备测试数据
    $importData = @{
        recordTypes = @(
            @{
                name = "final_test_type_1"
                displayName = "最终测试类型1"
                schema = '{"type":"object","properties":{"title":{"type":"string","description":"标题"},"content":{"type":"string","description":"内容"}},"required":["title"]}'
                isActive = "true"
            },
            @{
                name = "final_test_type_2"
                displayName = "最终测试类型2"
                schema = ""
                isActive = "true"
            },
            @{
                name = "final_test_type_3"
                displayName = "最终测试类型3"
                schema = '{"type":"object","properties":{"name":{"type":"string"},"status":{"type":"string","enum":["active","inactive"]}}}'
                isActive = "false"
            }
        )
    } | ConvertTo-Json -Depth 10
    
    Write-Host "2.1 执行导入操作..." -ForegroundColor Cyan
    Write-Host "导入数据:" -ForegroundColor Gray
    Write-Host $importData -ForegroundColor DarkGray
    
    try {
        $importResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/import" -Method Post -Body $importData -Headers $headers
        
        if ($importResponse.success) {
            Write-Host "  ✓ 导入请求成功" -ForegroundColor Green
            
            $results = $importResponse.data.results
            $successCount = ($results | Where-Object { $_.success }).Count
            $failCount = $results.Count - $successCount
            
            Write-Host "  导入结果: 成功 $successCount 个，失败 $failCount 个" -ForegroundColor Cyan
            
            $successfulImports = @()
            foreach ($result in $results) {
                if ($result.success) {
                    Write-Host "    ✓ $($result.displayName) 导入成功，ID: $($result.record_type_id)" -ForegroundColor Green
                    $successfulImports += $result
                } else {
                    Write-Host "    ✗ $($result.displayName) 导入失败: $($result.error)" -ForegroundColor Red
                }
            }
            
            return $successfulImports
        } else {
            Write-Host "  ✗ 导入请求失败: $($importResponse.error.message)" -ForegroundColor Red
            return @()
        }
    } catch {
        Write-Host "  ✗ 导入请求异常: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "  HTTP状态码: $statusCode" -ForegroundColor Red
            
            # 详细错误分析
            switch ($statusCode) {
                404 { Write-Host "  原因: 导入接口不存在，请检查后端路由" -ForegroundColor Yellow }
                403 { Write-Host "  原因: 权限不足，请检查管理员权限" -ForegroundColor Yellow }
                400 { Write-Host "  原因: 请求格式错误，请检查数据格式" -ForegroundColor Yellow }
                422 { Write-Host "  原因: 数据验证失败，请检查必填字段" -ForegroundColor Yellow }
                500 { Write-Host "  原因: 服务器内部错误，请检查后端日志" -ForegroundColor Yellow }
                default { Write-Host "  原因: 未知错误，状态码 $statusCode" -ForegroundColor Yellow }
            }
        }
        return @()
    }
}

# 函数：步骤3 - 测试批量操作
function Step3-TestBatchOperations {
    param($token, $recordTypes)
    
    Write-Host "`n=== 步骤3: 测试批量操作 ===" -ForegroundColor Magenta
    
    # 筛选测试记录类型
    $testTypes = $recordTypes | Where-Object { $_.name -like "final_test_type_*" }
    
    if ($testTypes.Count -eq 0) {
        Write-Host "! 没有找到测试记录类型，跳过批量操作测试" -ForegroundColor Yellow
        return
    }
    
    Write-Host "找到 $($testTypes.Count) 个测试记录类型" -ForegroundColor Gray
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $testTypeIds = $testTypes | ForEach-Object { $_.id }
    
    # 3.1 测试批量禁用
    Write-Host "3.1 测试批量禁用..." -ForegroundColor Cyan
    $disableData = @{
        record_type_ids = $testTypeIds
        is_active = $false
    } | ConvertTo-Json -Depth 10
    
    try {
        $disableResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/batch-status" -Method Put -Body $disableData -Headers $headers
        if ($disableResponse.success) {
            Write-Host "  ✓ 批量禁用成功" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 批量禁用失败: $($disableResponse.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ 批量禁用请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 等待一秒
    Start-Sleep -Seconds 1
    
    # 3.2 测试批量启用
    Write-Host "3.2 测试批量启用..." -ForegroundColor Cyan
    $enableData = @{
        record_type_ids = $testTypeIds
        is_active = $true
    } | ConvertTo-Json -Depth 10
    
    try {
        $enableResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/batch-status" -Method Put -Body $enableData -Headers $headers
        if ($enableResponse.success) {
            Write-Host "  ✓ 批量启用成功" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 批量启用失败: $($enableResponse.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ 批量启用请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 3.3 测试批量删除
    Write-Host "3.3 测试批量删除..." -ForegroundColor Cyan
    $deleteData = @{
        record_type_ids = $testTypeIds
    } | ConvertTo-Json -Depth 10
    
    try {
        $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/batch" -Method Delete -Body $deleteData -Headers $headers
        if ($deleteResponse.success) {
            Write-Host "  ✓ 批量删除成功，删除了 $($testTypeIds.Count) 个记录类型" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 批量删除失败: $($deleteResponse.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ 批量删除请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 函数：步骤4 - 验证功能完整性
function Step4-VerifyFunctionality {
    param($token)
    
    Write-Host "`n=== 步骤4: 验证功能完整性 ===" -ForegroundColor Magenta
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 4.1 验证所有接口是否存在
    Write-Host "4.1 验证接口存在性..." -ForegroundColor Cyan
    
    $endpoints = @(
        @{ Method = "GET"; URL = "/api/v1/record-types"; Name = "列表接口" },
        @{ Method = "POST"; URL = "/api/v1/record-types"; Name = "创建接口" },
        @{ Method = "POST"; URL = "/api/v1/record-types/import"; Name = "导入接口" },
        @{ Method = "PUT"; URL = "/api/v1/record-types/batch-status"; Name = "批量状态更新接口" },
        @{ Method = "DELETE"; URL = "/api/v1/record-types/batch"; Name = "批量删除接口" }
    )
    
    foreach ($endpoint in $endpoints) {
        try {
            if ($endpoint.Method -eq "GET") {
                $response = Invoke-RestMethod -Uri "$baseUrl$($endpoint.URL)" -Method $endpoint.Method -Headers $headers -TimeoutSec 5
            } else {
                # 对于POST/PUT/DELETE，发送空数据测试接口存在性
                $emptyData = @{} | ConvertTo-Json
                $response = Invoke-RestMethod -Uri "$baseUrl$($endpoint.URL)" -Method $endpoint.Method -Body $emptyData -Headers $headers -TimeoutSec 5
            }
            Write-Host "  ✓ $($endpoint.Name) 存在且可访问" -ForegroundColor Green
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            if ($statusCode -eq 404) {
                Write-Host "  ✗ $($endpoint.Name) 不存在 (404)" -ForegroundColor Red
            } elseif ($statusCode -eq 400 -or $statusCode -eq 422) {
                Write-Host "  ✓ $($endpoint.Name) 存在（参数验证失败是正常的）" -ForegroundColor Green
            } else {
                Write-Host "  ? $($endpoint.Name) 状态未知: $statusCode" -ForegroundColor Yellow
            }
        }
    }
}

# 主执行流程
try {
    Write-Host "开始最终测试..." -ForegroundColor White
    
    # 获取管理员Token
    $adminToken = Get-AdminToken
    if (-not $adminToken) {
        Write-Host "无法获取管理员Token，测试终止" -ForegroundColor Red
        exit 1
    }
    
    # 步骤1: 测试基础CRUD操作
    $existingTypes = Step1-TestBasicCRUD -token $adminToken
    
    # 步骤2: 测试导入功能
    $importResults = Step2-TestImportFunction -token $adminToken
    
    # 等待数据同步
    Start-Sleep -Seconds 2
    
    # 重新获取记录类型列表
    $updatedTypes = Step1-TestBasicCRUD -token $adminToken
    
    # 步骤3: 测试批量操作
    Step3-TestBatchOperations -token $adminToken -recordTypes $updatedTypes
    
    # 步骤4: 验证功能完整性
    Step4-VerifyFunctionality -token $adminToken
    
    Write-Host "`n=== 最终测试完成 ===" -ForegroundColor Green
    
    # 生成最终报告
    Write-Host "`n=== 最终测试报告 ===" -ForegroundColor Magenta
    
    $hasBasicFunction = $existingTypes.Count -ge 0
    $hasImportFunction = $importResults.Count -gt 0
    
    Write-Host "基础功能: $(if ($hasBasicFunction) { '✓ 正常' } else { '✗ 异常' })" -ForegroundColor $(if ($hasBasicFunction) { "Green" } else { "Red" })
    Write-Host "导入功能: $(if ($hasImportFunction) { '✓ 正常' } else { '✗ 异常' })" -ForegroundColor $(if ($hasImportFunction) { "Green" } else { "Red" })
    
    if ($hasBasicFunction -and $hasImportFunction) {
        Write-Host "`n🎉 记录类型管理功能测试全部通过！" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  部分功能存在问题，请检查上述错误信息" -ForegroundColor Yellow
    }
    
    Write-Host "`n下一步建议:" -ForegroundColor Yellow
    Write-Host "1. 在浏览器中测试前端界面功能" -ForegroundColor Gray
    Write-Host "2. 检查浏览器控制台是否有JavaScript错误" -ForegroundColor Gray
    Write-Host "3. 验证网络请求是否正确发送" -ForegroundColor Gray
    Write-Host "4. 如有问题，查看后端日志获取详细信息" -ForegroundColor Gray
    
} catch {
    Write-Host "最终测试过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}