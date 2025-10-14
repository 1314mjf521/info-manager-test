# 测试记录类型批量操作和导入功能的脚本
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

# 函数：测试记录类型导入功能
function Test-RecordTypeImport {
    param($token)
    
    Write-Host "`n--- 测试记录类型导入功能 ---" -ForegroundColor Cyan
    
    $importData = @{
        recordTypes = @(
            @{
                name = "test_import_type_1"
                displayName = "测试导入类型1"
                schema = '{"type":"object","properties":{"title":{"type":"string"},"content":{"type":"string"}}}'
                isActive = "true"
            },
            @{
                name = "test_import_type_2"
                displayName = "测试导入类型2"
                schema = '{"type":"object","properties":{"name":{"type":"string"},"description":{"type":"string"},"status":{"type":"string"}}}'
                isActive = "true"
            },
            @{
                name = "test_import_type_3"
                displayName = "测试导入类型3"
                schema = '{"type":"object","properties":{"content":{"type":"string"}}}'
                isActive = "false"
            }
        )
    } | ConvertTo-Json -Depth 10
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/import" -Method Post -Body $importData -Headers $headers
        if ($response.success) {
            Write-Host "✓ 记录类型导入成功" -ForegroundColor Green
            $results = $response.data.results
            foreach ($result in $results) {
                if ($result.success) {
                    Write-Host "  ✓ 记录类型 '$($result.displayName)' 导入成功，ID: $($result.record_type_id)" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ 记录类型 '$($result.displayName)' 导入失败: $($result.error)" -ForegroundColor Red
                }
            }
            return $results
        } else {
            Write-Host "✗ 记录类型导入失败: $($response.error.message)" -ForegroundColor Red
            return @()
        }
    } catch {
        Write-Host "✗ 记录类型导入请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return @()
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

# 函数：测试批量状态更新
function Test-BatchStatusUpdate {
    param($token, $recordTypes)
    
    Write-Host "`n--- 测试批量状态更新功能 ---" -ForegroundColor Cyan
    
    # 筛选测试导入的记录类型
    $testTypes = $recordTypes | Where-Object { $_.name -like "test_import_type_*" }
    
    if ($testTypes.Count -eq 0) {
        Write-Host "! 没有找到测试记录类型，跳过批量状态更新测试" -ForegroundColor Yellow
        return
    }
    
    $testTypeIds = $testTypes | ForEach-Object { $_.id }
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 测试批量禁用
    Write-Host "测试批量禁用..." -ForegroundColor Yellow
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
    }
    
    # 等待一秒
    Start-Sleep -Seconds 1
    
    # 测试批量启用
    Write-Host "测试批量启用..." -ForegroundColor Yellow
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
    }
}

# 函数：测试批量删除
function Test-BatchDelete {
    param($token, $recordTypes)
    
    Write-Host "`n--- 测试批量删除功能 ---" -ForegroundColor Cyan
    
    # 筛选测试导入的记录类型
    $testTypes = $recordTypes | Where-Object { $_.name -like "test_import_type_*" }
    
    if ($testTypes.Count -eq 0) {
        Write-Host "! 没有找到测试记录类型，跳过批量删除测试" -ForegroundColor Yellow
        return
    }
    
    $testTypeIds = $testTypes | ForEach-Object { $_.id }
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
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
    }
}

# 函数：测试单个记录类型创建和删除
function Test-SingleRecordTypeOperations {
    param($token)
    
    Write-Host "`n--- 测试单个记录类型操作 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 创建测试记录类型
    Write-Host "创建测试记录类型..." -ForegroundColor Yellow
    $createData = @{
        name = "test_single_type"
        display_name = "测试单个类型"
        schema = @{
            type = "object"
            properties = @{
                title = @{
                    type = "string"
                }
                content = @{
                    type = "string"
                }
            }
        }
    } | ConvertTo-Json -Depth 10
    
    try {
        $createResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types" -Method Post -Body $createData -Headers $headers
        if ($createResponse.success) {
            Write-Host "  ✓ 记录类型创建成功，ID: $($createResponse.data.id)" -ForegroundColor Green
            $createdTypeId = $createResponse.data.id
            
            # 测试更新
            Write-Host "测试记录类型更新..." -ForegroundColor Yellow
            $updateData = @{
                display_name = "测试单个类型（已更新）"
                is_active = $false
            } | ConvertTo-Json -Depth 10
            
            $updateResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/$createdTypeId" -Method Put -Body $updateData -Headers $headers
            if ($updateResponse.success) {
                Write-Host "  ✓ 记录类型更新成功" -ForegroundColor Green
            } else {
                Write-Host "  ✗ 记录类型更新失败: $($updateResponse.error.message)" -ForegroundColor Red
            }
            
            # 测试获取单个记录类型
            Write-Host "测试获取单个记录类型..." -ForegroundColor Yellow
            $getResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/$createdTypeId" -Method Get -Headers $headers
            if ($getResponse.success) {
                Write-Host "  ✓ 获取记录类型成功: $($getResponse.data.display_name)" -ForegroundColor Green
            } else {
                Write-Host "  ✗ 获取记录类型失败: $($getResponse.error.message)" -ForegroundColor Red
            }
            
            # 删除测试记录类型
            Write-Host "删除测试记录类型..." -ForegroundColor Yellow
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
    }
}

# 函数：验证记录类型数据完整性
function Test-RecordTypeDataIntegrity {
    param($token)
    
    Write-Host "`n--- 测试记录类型数据完整性 ---" -ForegroundColor Cyan
    
    $recordTypes = Get-RecordTypes -token $token
    
    if ($recordTypes.Count -gt 0) {
        Write-Host "✓ 记录类型列表获取成功，共 $($recordTypes.Count) 个类型" -ForegroundColor Green
        
        foreach ($type in $recordTypes) {
            $issues = @()
            
            if (-not $type.name) { $issues += "缺少name字段" }
            if (-not $type.display_name -and -not $type.displayName) { $issues += "缺少display_name字段" }
            if ($null -eq $type.is_active -and $null -eq $type.isActive) { $issues += "缺少is_active字段" }
            
            if ($issues.Count -eq 0) {
                Write-Host "  ✓ 记录类型 '$($type.display_name || $type.displayName)' 数据完整" -ForegroundColor Green
            } else {
                Write-Host "  ✗ 记录类型 '$($type.display_name || $type.displayName)' 数据问题: $($issues -join ', ')" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "! 没有找到记录类型数据" -ForegroundColor Yellow
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
    
    # 测试记录类型导入功能
    $importResults = Test-RecordTypeImport -token $adminToken
    
    # 等待一秒让数据同步
    Start-Sleep -Seconds 1
    
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
    
    # 测试数据完整性
    Test-RecordTypeDataIntegrity -token $adminToken
    
    Write-Host "`n=== 记录类型批量操作和导入功能测试完成 ===" -ForegroundColor Green
    
} catch {
    Write-Host "测试过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}