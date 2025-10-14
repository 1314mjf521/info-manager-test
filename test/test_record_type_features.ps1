# 专门测试记录类型批量操作和导入功能的脚本
# 编码：UTF-8

Write-Host "=== 测试记录类型批量操作和导入功能 ===" -ForegroundColor Green

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

# 函数：获取记录类型列表
function Get-RecordTypes {
    param($token)
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types" -Method Get -Headers $headers
        if ($response.success) {
            Write-Host "✓ 获取记录类型列表成功，共 $($response.data.Count) 个类型" -ForegroundColor Green
            return $response.data
        } else {
            Write-Host "✗ 获取记录类型列表失败: $($response.error.message)" -ForegroundColor Red
            return @()
        }
    } catch {
        Write-Host "✗ 获取记录类型列表请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# 函数：测试记录类型导入
function Test-RecordTypeImport {
    param($token)
    
    Write-Host "`n--- 测试记录类型导入功能 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 准备导入数据
    $importData = @{
        recordTypes = @(
            @{
                name = "test_import_daily"
                displayName = "测试导入日报类型"
                schema = '{"type":"object","properties":{"title":{"type":"string","description":"标题"},"content":{"type":"string","description":"内容"},"date":{"type":"string","format":"date","description":"日期"}}}'
                isActive = "true"
            },
            @{
                name = "test_import_weekly"
                displayName = "测试导入周报类型"
                schema = '{"type":"object","properties":{"title":{"type":"string","description":"标题"},"summary":{"type":"string","description":"摘要"},"details":{"type":"string","description":"详细内容"}}}'
                isActive = "true"
            },
            @{
                name = "test_import_project"
                displayName = "测试导入项目类型"
                schema = '{"type":"object","properties":{"name":{"type":"string","description":"项目名称"},"status":{"type":"string","enum":["进行中","已完成","暂停"],"description":"项目状态"},"description":{"type":"string","description":"项目描述"}}}'
                isActive = "false"
            }
        )
    } | ConvertTo-Json -Depth 10
    
    Write-Host "准备导入 3 个测试记录类型..." -ForegroundColor Yellow
    Write-Host "请求URL: $baseUrl/api/v1/record-types/import" -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/import" -Method Post -Body $importData -Headers $headers
        
        if ($response.success) {
            Write-Host "✓ 记录类型导入请求成功" -ForegroundColor Green
            
            $results = $response.data.results
            $successCount = ($results | Where-Object { $_.success }).Count
            $failCount = $results.Count - $successCount
            
            Write-Host "导入结果: 成功 $successCount 个，失败 $failCount 个" -ForegroundColor Cyan
            
            foreach ($result in $results) {
                if ($result.success) {
                    Write-Host "  ✓ $($result.displayName) 导入成功，ID: $($result.record_type_id)" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ $($result.displayName) 导入失败: $($result.error)" -ForegroundColor Red
                }
            }
            
            return $results
        } else {
            Write-Host "✗ 记录类型导入失败: $($response.error.message)" -ForegroundColor Red
            return @()
        }
    } catch {
        Write-Host "✗ 记录类型导入请求失败" -ForegroundColor Red
        Write-Host "错误详情: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "HTTP状态码: $statusCode" -ForegroundColor Red
            
            if ($statusCode -eq 404) {
                Write-Host "可能原因: 导入接口不存在，请检查后端路由配置" -ForegroundColor Yellow
            } elseif ($statusCode -eq 403) {
                Write-Host "可能原因: 权限不足，请检查管理员权限" -ForegroundColor Yellow
            } elseif ($statusCode -eq 400 -or $statusCode -eq 422) {
                Write-Host "可能原因: 请求数据格式错误" -ForegroundColor Yellow
            }
        }
        return @()
    }
}

# 函数：测试批量状态更新
function Test-BatchStatusUpdate {
    param($token, $recordTypes)
    
    Write-Host "`n--- 测试批量状态更新功能 ---" -ForegroundColor Cyan
    
    # 筛选测试导入的记录类型
    $testTypes = $recordTypes | Where-Object { $_.name -like "test_import_*" }
    
    if ($testTypes.Count -eq 0) {
        Write-Host "! 没有找到测试记录类型，跳过批量状态更新测试" -ForegroundColor Yellow
        return
    }
    
    Write-Host "找到 $($testTypes.Count) 个测试记录类型" -ForegroundColor Gray
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $testTypeIds = $testTypes | ForEach-Object { $_.id }
    
    # 测试批量禁用
    Write-Host "1. 测试批量禁用..." -ForegroundColor Yellow
    $disableData = @{
        record_type_ids = $testTypeIds
        is_active = $false
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/batch-status" -Method Put -Body $disableData -Headers $headers
        if ($response.success) {
            Write-Host "  ✓ 批量禁用成功" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 批量禁用失败: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ 批量禁用请求失败: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "  HTTP状态码: $statusCode" -ForegroundColor Red
        }
    }
    
    # 等待一秒
    Start-Sleep -Seconds 1
    
    # 测试批量启用
    Write-Host "2. 测试批量启用..." -ForegroundColor Yellow
    $enableData = @{
        record_type_ids = $testTypeIds
        is_active = $true
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/batch-status" -Method Put -Body $enableData -Headers $headers
        if ($response.success) {
            Write-Host "  ✓ 批量启用成功" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 批量启用失败: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ 批量启用请求失败: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "  HTTP状态码: $statusCode" -ForegroundColor Red
        }
    }
}

# 函数：测试批量删除
function Test-BatchDelete {
    param($token, $recordTypes)
    
    Write-Host "`n--- 测试批量删除功能 ---" -ForegroundColor Cyan
    
    # 筛选测试导入的记录类型
    $testTypes = $recordTypes | Where-Object { $_.name -like "test_import_*" }
    
    if ($testTypes.Count -eq 0) {
        Write-Host "! 没有找到测试记录类型，跳过批量删除测试" -ForegroundColor Yellow
        return
    }
    
    Write-Host "准备删除 $($testTypes.Count) 个测试记录类型" -ForegroundColor Gray
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $testTypeIds = $testTypes | ForEach-Object { $_.id }
    
    $deleteData = @{
        record_type_ids = $testTypeIds
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/batch" -Method Delete -Body $deleteData -Headers $headers
        if ($response.success) {
            Write-Host "✓ 批量删除成功，删除了 $($testTypeIds.Count) 个记录类型" -ForegroundColor Green
        } else {
            Write-Host "✗ 批量删除失败: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 批量删除请求失败: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "HTTP状态码: $statusCode" -ForegroundColor Red
            
            if ($statusCode -eq 409) {
                Write-Host "可能原因: 记录类型正在被使用，无法删除" -ForegroundColor Yellow
            }
        }
    }
}

# 函数：测试单个记录类型操作
function Test-SingleRecordTypeOperations {
    param($token)
    
    Write-Host "`n--- 测试单个记录类型操作 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 创建测试记录类型
    Write-Host "1. 创建测试记录类型..." -ForegroundColor Yellow
    $createData = @{
        name = "test_single_operation"
        display_name = "测试单个操作类型"
        schema = @{
            type = "object"
            properties = @{
                title = @{
                    type = "string"
                    description = "标题"
                }
                content = @{
                    type = "string"
                    description = "内容"
                }
            }
            required = @("title")
        }
    } | ConvertTo-Json -Depth 10
    
    try {
        $createResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types" -Method Post -Body $createData -Headers $headers
        if ($createResponse.success) {
            Write-Host "  ✓ 记录类型创建成功，ID: $($createResponse.data.id)" -ForegroundColor Green
            $createdTypeId = $createResponse.data.id
            
            # 测试更新
            Write-Host "2. 测试记录类型更新..." -ForegroundColor Yellow
            $updateData = @{
                display_name = "测试单个操作类型（已更新）"
                is_active = $false
            } | ConvertTo-Json -Depth 10
            
            $updateResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/$createdTypeId" -Method Put -Body $updateData -Headers $headers
            if ($updateResponse.success) {
                Write-Host "  ✓ 记录类型更新成功" -ForegroundColor Green
            } else {
                Write-Host "  ✗ 记录类型更新失败: $($updateResponse.error.message)" -ForegroundColor Red
            }
            
            # 测试获取单个记录类型
            Write-Host "3. 测试获取单个记录类型..." -ForegroundColor Yellow
            $getResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/$createdTypeId" -Method Get -Headers $headers
            if ($getResponse.success) {
                Write-Host "  ✓ 获取记录类型成功: $($getResponse.data.display_name)" -ForegroundColor Green
            } else {
                Write-Host "  ✗ 获取记录类型失败: $($getResponse.error.message)" -ForegroundColor Red
            }
            
            # 删除测试记录类型
            Write-Host "4. 删除测试记录类型..." -ForegroundColor Yellow
            $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/$createdTypeId" -Method Delete -Headers $headers
            if ($deleteResponse.success) {
                Write-Host "  ✓ 记录类型删除成功" -ForegroundColor Green
            } else {
                Write-Host "  ✗ 记录类型删除失败: $($deleteResponse.error.message)" -ForegroundColor Red
            }
            
        } else {
            Write-Host "  ✗ 记录类型创建失败: $($createResponse.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ 记录类型操作请求失败: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "  HTTP状态码: $statusCode" -ForegroundColor Red
        }
    }
}

# 函数：验证后端接口可用性
function Test-BackendEndpoints {
    param($token)
    
    Write-Host "`n--- 验证后端接口可用性 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $endpoints = @(
        @{ Method = "GET"; URL = "/api/v1/record-types"; Name = "获取记录类型列表" },
        @{ Method = "POST"; URL = "/api/v1/record-types/import"; Name = "导入记录类型"; TestData = @{ recordTypes = @() } },
        @{ Method = "PUT"; URL = "/api/v1/record-types/batch-status"; Name = "批量更新状态"; TestData = @{ record_type_ids = @(); is_active = $true } },
        @{ Method = "DELETE"; URL = "/api/v1/record-types/batch"; Name = "批量删除"; TestData = @{ record_type_ids = @() } }
    )
    
    foreach ($endpoint in $endpoints) {
        Write-Host "测试: $($endpoint.Name)" -ForegroundColor Yellow
        
        try {
            if ($endpoint.TestData) {
                $testData = $endpoint.TestData | ConvertTo-Json -Depth 10
                $response = Invoke-RestMethod -Uri "$baseUrl$($endpoint.URL)" -Method $endpoint.Method -Body $testData -Headers $headers -TimeoutSec 10
            } else {
                $response = Invoke-RestMethod -Uri "$baseUrl$($endpoint.URL)" -Method $endpoint.Method -Headers $headers -TimeoutSec 10
            }
            
            Write-Host "  ✓ $($endpoint.Name) 接口可用" -ForegroundColor Green
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            if ($statusCode -eq 404) {
                Write-Host "  ✗ $($endpoint.Name) 接口不存在 (404)" -ForegroundColor Red
            } elseif ($statusCode -eq 400 -or $statusCode -eq 422) {
                Write-Host "  ✓ $($endpoint.Name) 接口存在（参数验证失败是正常的）" -ForegroundColor Green
            } elseif ($statusCode -eq 403) {
                Write-Host "  ! $($endpoint.Name) 权限不足 (403)" -ForegroundColor Yellow
            } else {
                Write-Host "  ? $($endpoint.Name) 状态未知: $statusCode" -ForegroundColor Yellow
            }
        }
    }
}

# 主执行流程
try {
    # 获取管理员Token
    $adminToken = Get-AdminToken
    if (-not $adminToken) {
        Write-Host "无法获取管理员Token，测试终止" -ForegroundColor Red
        exit 1
    }
    
    # 验证后端接口可用性
    Test-BackendEndpoints -token $adminToken
    
    # 测试记录类型导入功能
    $importResults = Test-RecordTypeImport -token $adminToken
    
    # 等待一秒让数据同步
    Start-Sleep -Seconds 2
    
    # 获取最新的记录类型列表
    $recordTypes = Get-RecordTypes -token $adminToken
    
    # 测试批量状态更新
    Test-BatchStatusUpdate -token $adminToken -recordTypes $recordTypes
    
    # 等待一秒
    Start-Sleep -Seconds 1
    
    # 重新获取记录类型列表
    $recordTypes = Get-RecordTypes -token $adminToken
    
    # 测试批量删除
    Test-BatchDelete -token $adminToken -recordTypes $recordTypes
    
    # 测试单个记录类型操作
    Test-SingleRecordTypeOperations -token $adminToken
    
    Write-Host "`n=== 记录类型功能测试完成 ===" -ForegroundColor Green
    
    # 生成测试总结
    Write-Host "`n=== 测试总结 ===" -ForegroundColor Magenta
    if ($importResults.Count -gt 0) {
        Write-Host "✓ 导入功能测试完成" -ForegroundColor Green
    } else {
        Write-Host "✗ 导入功能测试失败" -ForegroundColor Red
    }
    
    Write-Host "`n如果测试失败，请检查:" -ForegroundColor Yellow
    Write-Host "1. 后端服务是否正常运行在 localhost:8080" -ForegroundColor Gray
    Write-Host "2. 管理员账号是否有正确的权限" -ForegroundColor Gray
    Write-Host "3. 后端是否包含最新的批量操作接口" -ForegroundColor Gray
    Write-Host "4. 数据库连接是否正常" -ForegroundColor Gray
    
} catch {
    Write-Host "测试过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}