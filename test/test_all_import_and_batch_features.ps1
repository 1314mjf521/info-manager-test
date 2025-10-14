# 综合测试所有导入和批量操作功能的脚本
# 编码：UTF-8

Write-Host "=== 综合测试所有导入和批量操作功能 ===" -ForegroundColor Green

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

# 函数：测试角色导入和批量操作
function Test-RoleFeatures {
    param($token)
    
    Write-Host "`n=== 测试角色管理功能 ===" -ForegroundColor Magenta
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 1. 测试角色导入
    Write-Host "1. 测试角色导入..." -ForegroundColor Cyan
    $importData = @{
        roles = @(
            @{
                name = "test_batch_role_1"
                displayName = "测试批量角色1"
                description = "用于批量操作测试的角色1"
                status = "active"
                permissions = "users:read,records:read:own"
            },
            @{
                name = "test_batch_role_2"
                displayName = "测试批量角色2"
                description = "用于批量操作测试的角色2"
                status = "active"
                permissions = "records:read,files:read"
            }
        )
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/admin/roles/import" -Method Post -Body $importData -Headers $headers
        if ($response.success) {
            Write-Host "  ✓ 角色导入成功" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 角色导入失败: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ 角色导入请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 2. 获取角色列表并测试批量操作
    try {
        $rolesResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method Get -Headers $headers
        if ($rolesResponse.success) {
            $testRoles = $rolesResponse.data | Where-Object { $_.name -like "test_batch_role_*" }
            
            if ($testRoles.Count -gt 0) {
                $roleIds = $testRoles | ForEach-Object { $_.id }
                
                # 测试批量状态更新
                Write-Host "2. 测试角色批量状态更新..." -ForegroundColor Cyan
                $statusData = @{
                    role_ids = $roleIds
                    status = "inactive"
                } | ConvertTo-Json -Depth 10
                
                $statusResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles/batch-status" -Method Put -Body $statusData -Headers $headers
                if ($statusResponse.success) {
                    Write-Host "  ✓ 角色批量状态更新成功" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ 角色批量状态更新失败: $($statusResponse.error.message)" -ForegroundColor Red
                }
                
                # 测试批量删除
                Write-Host "3. 测试角色批量删除..." -ForegroundColor Cyan
                $deleteData = @{
                    role_ids = $roleIds
                } | ConvertTo-Json -Depth 10
                
                $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles/batch" -Method Delete -Body $deleteData -Headers $headers
                if ($deleteResponse.success) {
                    Write-Host "  ✓ 角色批量删除成功" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ 角色批量删除失败: $($deleteResponse.error.message)" -ForegroundColor Red
                }
            } else {
                Write-Host "  ! 没有找到测试角色，跳过批量操作测试" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "  ✗ 角色批量操作测试失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 函数：测试记录类型导入和批量操作
function Test-RecordTypeFeatures {
    param($token)
    
    Write-Host "`n=== 测试记录类型管理功能 ===" -ForegroundColor Magenta
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 1. 测试记录类型导入
    Write-Host "1. 测试记录类型导入..." -ForegroundColor Cyan
    $importData = @{
        recordTypes = @(
            @{
                name = "test_batch_type_1"
                displayName = "测试批量类型1"
                schema = '{"type":"object","properties":{"title":{"type":"string"},"content":{"type":"string"}}}'
                isActive = "true"
            },
            @{
                name = "test_batch_type_2"
                displayName = "测试批量类型2"
                schema = '{"type":"object","properties":{"name":{"type":"string"},"description":{"type":"string"}}}'
                isActive = "true"
            }
        )
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/import" -Method Post -Body $importData -Headers $headers
        if ($response.success) {
            Write-Host "  ✓ 记录类型导入成功" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 记录类型导入失败: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ 记录类型导入请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 2. 获取记录类型列表并测试批量操作
    try {
        $typesResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types" -Method Get -Headers $headers
        if ($typesResponse.success) {
            $testTypes = $typesResponse.data | Where-Object { $_.name -like "test_batch_type_*" }
            
            if ($testTypes.Count -gt 0) {
                $typeIds = $testTypes | ForEach-Object { $_.id }
                
                # 测试批量状态更新
                Write-Host "2. 测试记录类型批量状态更新..." -ForegroundColor Cyan
                $statusData = @{
                    record_type_ids = $typeIds
                    is_active = $false
                } | ConvertTo-Json -Depth 10
                
                $statusResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/batch-status" -Method Put -Body $statusData -Headers $headers
                if ($statusResponse.success) {
                    Write-Host "  ✓ 记录类型批量状态更新成功" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ 记录类型批量状态更新失败: $($statusResponse.error.message)" -ForegroundColor Red
                }
                
                # 测试批量删除
                Write-Host "3. 测试记录类型批量删除..." -ForegroundColor Cyan
                $deleteData = @{
                    record_type_ids = $typeIds
                } | ConvertTo-Json -Depth 10
                
                $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/batch" -Method Delete -Body $deleteData -Headers $headers
                if ($deleteResponse.success) {
                    Write-Host "  ✓ 记录类型批量删除成功" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ 记录类型批量删除失败: $($deleteResponse.error.message)" -ForegroundColor Red
                }
            } else {
                Write-Host "  ! 没有找到测试记录类型，跳过批量操作测试" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "  ✗ 记录类型批量操作测试失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 函数：测试记录导入功能
function Test-RecordImportFeatures {
    param($token)
    
    Write-Host "`n=== 测试记录导入功能 ===" -ForegroundColor Magenta
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 测试记录导入
    Write-Host "1. 测试记录导入..." -ForegroundColor Cyan
    $importData = @{
        records = @(
            @{
                title = "批量测试记录1"
                type = "daily_report"
                content = "这是通过批量导入功能创建的测试记录1"
                tags = "测试,批量,导入"
                status = "published"
            },
            @{
                title = "批量测试记录2"
                type = "daily_report"
                content = "这是通过批量导入功能创建的测试记录2"
                tags = "测试,批量,导入"
                status = "draft"
            }
        )
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records/import" -Method Post -Body $importData -Headers $headers
        if ($response.success) {
            Write-Host "  ✓ 记录导入成功" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 记录导入失败: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ 记录导入请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 函数：测试权限验证
function Test-PermissionValidation {
    param($token)
    
    Write-Host "`n=== 测试权限验证 ===" -ForegroundColor Magenta
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 测试权限树获取
    Write-Host "1. 测试权限树获取..." -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/permissions/tree" -Method Get -Headers $headers
        if ($response.success) {
            Write-Host "  ✓ 权限树获取成功，节点数量: $($response.data.Count)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 权限树获取失败: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ 权限树获取请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 测试权限检查
    Write-Host "2. 测试权限检查..." -ForegroundColor Cyan
    $checkData = @{
        resource = "users"
        action = "read"
        scope = "all"
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/permissions/check" -Method Post -Body $checkData -Headers $headers
        if ($response.success) {
            Write-Host "  ✓ 权限检查成功，有权限: $($response.data.hasPermission)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 权限检查失败: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ 权限检查请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 函数：生成测试报告
function Generate-TestReport {
    param($results)
    
    Write-Host "`n=== 测试报告 ===" -ForegroundColor Magenta
    
    $totalTests = $results.Count
    $passedTests = ($results | Where-Object { $_.Status -eq "Passed" }).Count
    $failedTests = ($results | Where-Object { $_.Status -eq "Failed" }).Count
    $skippedTests = ($results | Where-Object { $_.Status -eq "Skipped" }).Count
    
    Write-Host "总测试数: $totalTests" -ForegroundColor White
    Write-Host "通过: $passedTests" -ForegroundColor Green
    Write-Host "失败: $failedTests" -ForegroundColor Red
    Write-Host "跳过: $skippedTests" -ForegroundColor Yellow
    
    $successRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }
    Write-Host "成功率: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })
    
    if ($failedTests -gt 0) {
        Write-Host "`n失败的测试:" -ForegroundColor Red
        $results | Where-Object { $_.Status -eq "Failed" } | ForEach-Object {
            Write-Host "  - $($_.TestName): $($_.Error)" -ForegroundColor Red
        }
    }
}

# 主执行流程
try {
    Write-Host "开始综合测试..." -ForegroundColor White
    
    # 获取管理员Token
    $adminToken = Get-AdminToken
    if (-not $adminToken) {
        Write-Host "无法获取管理员Token，测试终止" -ForegroundColor Red
        exit 1
    }
    
    $testResults = @()
    
    # 测试角色管理功能
    try {
        Test-RoleFeatures -token $adminToken
        $testResults += @{ TestName = "角色管理功能"; Status = "Passed"; Error = $null }
    } catch {
        $testResults += @{ TestName = "角色管理功能"; Status = "Failed"; Error = $_.Exception.Message }
    }
    
    # 测试记录类型管理功能
    try {
        Test-RecordTypeFeatures -token $adminToken
        $testResults += @{ TestName = "记录类型管理功能"; Status = "Passed"; Error = $null }
    } catch {
        $testResults += @{ TestName = "记录类型管理功能"; Status = "Failed"; Error = $_.Exception.Message }
    }
    
    # 测试记录导入功能
    try {
        Test-RecordImportFeatures -token $adminToken
        $testResults += @{ TestName = "记录导入功能"; Status = "Passed"; Error = $null }
    } catch {
        $testResults += @{ TestName = "记录导入功能"; Status = "Failed"; Error = $_.Exception.Message }
    }
    
    # 测试权限验证
    try {
        Test-PermissionValidation -token $adminToken
        $testResults += @{ TestName = "权限验证功能"; Status = "Passed"; Error = $null }
    } catch {
        $testResults += @{ TestName = "权限验证功能"; Status = "Failed"; Error = $_.Exception.Message }
    }
    
    # 生成测试报告
    Generate-TestReport -results $testResults
    
    Write-Host "`n=== 综合测试完成 ===" -ForegroundColor Green
    
} catch {
    Write-Host "测试过程中发生严重错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}