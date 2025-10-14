# 测试记录管理导入和批量操作修复后的功能
# 编码：UTF-8

Write-Host "=== 测试记录管理导入和批量操作修复功能 ===" -ForegroundColor Green

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

# 函数：测试记录导入功能
function Test-RecordImport {
    param($token)
    
    Write-Host "`n--- 测试记录导入功能 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 测试数据
    $importData = @{
        type = "work"
        records = @(
            @{
                title = "测试导入记录1"
                content = @{
                    description = "这是一个测试导入的记录"
                }
                tags = @("测试", "导入")
            },
            @{
                title = "测试导入记录2"
                content = @{
                    description = "这是另一个测试导入的记录"
                }
                tags = @("测试", "批量")
            }
        )
    } | ConvertTo-Json -Depth 10
    
    try {
        Write-Host "正在测试记录导入..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records/import" -Method Post -Body $importData -Headers $headers
        
        if ($response.success) {
            Write-Host "✓ 记录导入测试成功" -ForegroundColor Green
            Write-Host "  导入记录数: $($response.data.Count)" -ForegroundColor Gray
            return $response.data
        } else {
            Write-Host "✗ 记录导入测试失败: $($response.message)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ 记录导入请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 函数：测试批量状态更新
function Test-BatchStatusUpdate {
    param($token, $recordIds)
    
    Write-Host "`n--- 测试批量状态更新 ---" -ForegroundColor Cyan
    
    if (-not $recordIds -or $recordIds.Count -eq 0) {
        Write-Host "✗ 没有可用的记录ID进行测试" -ForegroundColor Red
        return $false
    }
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $updateData = @{
        record_ids = $recordIds
        status = "published"
    } | ConvertTo-Json -Depth 10
    
    try {
        Write-Host "正在测试批量状态更新..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records/batch-status" -Method Put -Body $updateData -Headers $headers
        
        if ($response.success) {
            Write-Host "✓ 批量状态更新测试成功" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ 批量状态更新测试失败: $($response.message)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "✗ 批量状态更新请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 函数：测试批量删除
function Test-BatchDelete {
    param($token, $recordIds)
    
    Write-Host "`n--- 测试批量删除 ---" -ForegroundColor Cyan
    
    if (-not $recordIds -or $recordIds.Count -eq 0) {
        Write-Host "✗ 没有可用的记录ID进行测试" -ForegroundColor Red
        return $false
    }
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $deleteData = @{
        record_ids = $recordIds
    } | ConvertTo-Json -Depth 10
    
    try {
        Write-Host "正在测试批量删除..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records/batch" -Method Delete -Body $deleteData -Headers $headers
        
        if ($response.success) {
            Write-Host "✓ 批量删除测试成功" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ 批量删除测试失败: $($response.message)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "✗ 批量删除请求失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
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
    
    # 测试记录导入功能
    $importedRecords = Test-RecordImport -token $adminToken
    
    if ($importedRecords) {
        $recordIds = $importedRecords | ForEach-Object { $_.id }
        
        # 测试批量状态更新
        $statusUpdateResult = Test-BatchStatusUpdate -token $adminToken -recordIds $recordIds
        
        # 测试批量删除
        $deleteResult = Test-BatchDelete -token $adminToken -recordIds $recordIds
        
        # 显示测试结果
        Write-Host "`n=== 测试结果汇总 ===" -ForegroundColor Green
        Write-Host "记录导入: $(if ($importedRecords) { '✓ 成功' } else { '✗ 失败' })" -ForegroundColor $(if ($importedRecords) { 'Green' } else { 'Red' })
        Write-Host "批量状态更新: $(if ($statusUpdateResult) { '✓ 成功' } else { '✗ 失败' })" -ForegroundColor $(if ($statusUpdateResult) { 'Green' } else { 'Red' })
        Write-Host "批量删除: $(if ($deleteResult) { '✓ 成功' } else { '✗ 失败' })" -ForegroundColor $(if ($deleteResult) { 'Green' } else { 'Red' })
        
        if ($importedRecords -and $statusUpdateResult -and $deleteResult) {
            Write-Host "`n🎉 所有测试通过！记录管理导入和批量操作功能已修复" -ForegroundColor Green
        } else {
            Write-Host "`n⚠️ 部分测试失败，请检查相关功能" -ForegroundColor Yellow
        }
    } else {
        Write-Host "`n❌ 导入功能测试失败，无法继续后续测试" -ForegroundColor Red
    }
    
} catch {
    Write-Host "测试过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}