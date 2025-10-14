# 测试导入和批量操作功能
# 编码：UTF-8

Write-Host "=== 测试导入和批量操作功能 ===" -ForegroundColor Green

# 设置API基础URL
$baseUrl = "http://localhost:8080/api/v1"
$token = ""

# 登录获取token
function Get-AuthToken {
    Write-Host "正在登录获取认证token..." -ForegroundColor Yellow
    
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginData -ContentType "application/json"
        if ($response.success -and $response.data.access_token) {
            $script:token = $response.data.access_token
            Write-Host "登录成功，获取到token" -ForegroundColor Green
            return $true
        } else {
            Write-Host "登录失败：$($response.error.message)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "登录请求失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 创建认证头
function Get-AuthHeaders {
    return @{
        "Authorization" = "Bearer $script:token"
        "Content-Type" = "application/json"
    }
}

# 测试角色导入功能
function Test-RoleImport {
    Write-Host "`n--- 测试角色导入功能 ---" -ForegroundColor Cyan
    
    $importData = @{
        roles = @(
            @{
                name = "test_role_1"
                displayName = "测试角色1"
                description = "这是一个测试角色"
                status = "active"
                permissions = "users:read,records:read"
            },
            @{
                name = "test_role_2"
                displayName = "测试角色2"
                description = "这是另一个测试角色"
                status = "active"
                permissions = "records:write,files:read"
            }
        )
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/admin/roles/import" -Method Post -Body $importData -Headers (Get-AuthHeaders)
        if ($response.success) {
            Write-Host "角色导入测试成功" -ForegroundColor Green
            Write-Host "导入结果：$($response.data.results | ConvertTo-Json -Depth 2)" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "角色导入测试失败：$($response.error.message)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "角色导入请求失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 测试角色批量操作
function Test-RoleBatchOperations {
    Write-Host "`n--- 测试角色批量操作 ---" -ForegroundColor Cyan
    
    # 首先获取角色列表
    try {
        $rolesResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method Get -Headers (Get-AuthHeaders)
        if ($rolesResponse.success -and $rolesResponse.data) {
            $testRoles = $rolesResponse.data | Where-Object { $_.name -like "test_role_*" }
            if ($testRoles.Count -gt 0) {
                $roleIds = $testRoles | ForEach-Object { $_.id }
                
                # 测试批量状态更新
                $batchStatusData = @{
                    role_ids = $roleIds
                    status = "inactive"
                } | ConvertTo-Json -Depth 10
                
                $statusResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles/batch-status" -Method Put -Body $batchStatusData -Headers (Get-AuthHeaders)
                if ($statusResponse.success) {
                    Write-Host "角色批量状态更新测试成功" -ForegroundColor Green
                } else {
                    Write-Host "角色批量状态更新测试失败" -ForegroundColor Red
                }
                
                # 测试批量删除
                $batchDeleteData = @{
                    role_ids = $roleIds
                } | ConvertTo-Json -Depth 10
                
                $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles/batch" -Method Delete -Body $batchDeleteData -Headers (Get-AuthHeaders)
                if ($deleteResponse.success) {
                    Write-Host "角色批量删除测试成功" -ForegroundColor Green
                    return $true
                } else {
                    Write-Host "角色批量删除测试失败" -ForegroundColor Red
                    return $false
                }
            } else {
                Write-Host "没有找到测试角色，跳过批量操作测试" -ForegroundColor Yellow
                return $true
            }
        } else {
            Write-Host "获取角色列表失败" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "角色批量操作测试失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 测试记录类型导入功能
function Test-RecordTypeImport {
    Write-Host "`n--- 测试记录类型导入功能 ---" -ForegroundColor Cyan
    
    $importData = @{
        recordTypes = @(
            @{
                name = "test_type_1"
                displayName = "测试类型1"
                schema = '{"type":"object","properties":{"title":{"type":"string"},"content":{"type":"string"}}}'
                isActive = "true"
            },
            @{
                name = "test_type_2"
                displayName = "测试类型2"
                schema = '{"type":"object","properties":{"name":{"type":"string"},"description":{"type":"string"}}}'
                isActive = "true"
            }
        )
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/record-types/import" -Method Post -Body $importData -Headers (Get-AuthHeaders)
        if ($response.success) {
            Write-Host "记录类型导入测试成功" -ForegroundColor Green
            Write-Host "导入结果：$($response.data.results | ConvertTo-Json -Depth 2)" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "记录类型导入测试失败：$($response.error.message)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "记录类型导入请求失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 测试记录类型批量操作
function Test-RecordTypeBatchOperations {
    Write-Host "`n--- 测试记录类型批量操作 ---" -ForegroundColor Cyan
    
    # 首先获取记录类型列表
    try {
        $typesResponse = Invoke-RestMethod -Uri "$baseUrl/record-types" -Method Get -Headers (Get-AuthHeaders)
        if ($typesResponse.success -and $typesResponse.data) {
            $testTypes = $typesResponse.data | Where-Object { $_.name -like "test_type_*" }
            if ($testTypes.Count -gt 0) {
                $typeIds = $testTypes | ForEach-Object { $_.id }
                
                # 测试批量状态更新
                $batchStatusData = @{
                    record_type_ids = $typeIds
                    is_active = $false
                } | ConvertTo-Json -Depth 10
                
                $statusResponse = Invoke-RestMethod -Uri "$baseUrl/record-types/batch-status" -Method Put -Body $batchStatusData -Headers (Get-AuthHeaders)
                if ($statusResponse.success) {
                    Write-Host "记录类型批量状态更新测试成功" -ForegroundColor Green
                } else {
                    Write-Host "记录类型批量状态更新测试失败" -ForegroundColor Red
                }
                
                # 测试批量删除
                $batchDeleteData = @{
                    record_type_ids = $typeIds
                } | ConvertTo-Json -Depth 10
                
                $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/record-types/batch" -Method Delete -Body $batchDeleteData -Headers (Get-AuthHeaders)
                if ($deleteResponse.success) {
                    Write-Host "记录类型批量删除测试成功" -ForegroundColor Green
                    return $true
                } else {
                    Write-Host "记录类型批量删除测试失败" -ForegroundColor Red
                    return $false
                }
            } else {
                Write-Host "没有找到测试记录类型，跳过批量操作测试" -ForegroundColor Yellow
                return $true
            }
        } else {
            Write-Host "获取记录类型列表失败" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "记录类型批量操作测试失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 测试记录导入功能
function Test-RecordImport {
    Write-Host "`n--- 测试记录导入功能 ---" -ForegroundColor Cyan
    
    $importData = @{
        records = @(
            @{
                title = "测试记录1"
                type = "work"
                content = "这是一个测试记录的内容"
                tags = "测试,导入"
                status = "published"
            },
            @{
                title = "测试记录2"
                type = "study"
                content = "这是另一个测试记录的内容"
                tags = "学习,笔记"
                status = "draft"
            }
        )
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/records/import" -Method Post -Body $importData -Headers (Get-AuthHeaders)
        if ($response.success) {
            Write-Host "记录导入测试成功" -ForegroundColor Green
            Write-Host "导入结果：$($response.data.results | ConvertTo-Json -Depth 2)" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "记录导入测试失败：$($response.error.message)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "记录导入请求失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 主测试流程
function Main {
    Write-Host "开始测试导入和批量操作功能..." -ForegroundColor Green
    
    # 登录
    if (-not (Get-AuthToken)) {
        Write-Host "无法获取认证token，测试终止" -ForegroundColor Red
        return
    }
    
    $testResults = @()
    
    # 测试角色功能
    $testResults += @{ Name = "角色导入"; Result = (Test-RoleImport) }
    $testResults += @{ Name = "角色批量操作"; Result = (Test-RoleBatchOperations) }
    
    # 测试记录类型功能
    $testResults += @{ Name = "记录类型导入"; Result = (Test-RecordTypeImport) }
    $testResults += @{ Name = "记录类型批量操作"; Result = (Test-RecordTypeBatchOperations) }
    
    # 测试记录功能
    $testResults += @{ Name = "记录导入"; Result = (Test-RecordImport) }
    
    # 输出测试结果汇总
    Write-Host "`n=== 测试结果汇总 ===" -ForegroundColor Green
    $successCount = 0
    $totalCount = $testResults.Count
    
    foreach ($result in $testResults) {
        $status = if ($result.Result) { "✓ 通过"; $successCount++ } else { "✗ 失败" }
        $color = if ($result.Result) { "Green" } else { "Red" }
        Write-Host "$($result.Name): $status" -ForegroundColor $color
    }
    
    Write-Host "`n总计：$successCount/$totalCount 项测试通过" -ForegroundColor $(if ($successCount -eq $totalCount) { "Green" } else { "Yellow" })
    
    if ($successCount -eq $totalCount) {
        Write-Host "所有导入和批量操作功能测试通过！" -ForegroundColor Green
    } else {
        Write-Host "部分测试失败，请检查相关功能实现" -ForegroundColor Yellow
    }
}

# 执行主测试
Main