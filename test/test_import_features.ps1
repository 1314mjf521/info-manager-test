# 测试导入功能的综合脚本
# 编码：UTF-8

Write-Host "=== 测试角色管理、记录类型管理和记录管理的导入功能 ===" -ForegroundColor Green

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

# 函数：测试角色导入功能
function Test-RoleImport {
    param($token)
    
    Write-Host "`n--- 测试角色导入功能 ---" -ForegroundColor Cyan
    
    $importData = @{
        roles = @(
            @{
                name = "test_role_1"
                displayName = "测试角色1"
                description = "通过导入创建的测试角色1"
                status = "active"
                permissions = "users:read,records:read:own"
            },
            @{
                name = "test_role_2"
                displayName = "测试角色2"
                description = "通过导入创建的测试角色2"
                status = "active"
                permissions = "records:read,files:read"
            }
        )
    } | ConvertTo-Json -Depth 10
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/admin/roles/import" -Method Post -Body $importData -Headers $headers
        if ($response.success) {
            Write-Host "✓ 角色导入成功" -ForegroundColor Green
            $results = $response.data.results
            foreach ($result in $results) {
                if ($result.success) {
                    Write-Host "  ✓ 角色 '$($result.displayName)' 导入成功，ID: $($result.role_id)" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ 角色 '$($result.displayName)' 导入失败: $($result.error)" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "✗ 角色导入失败: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 角色导入请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 函数：测试记录类型导入功能
function Test-RecordTypeImport {
    param($token)
    
    Write-Host "`n--- 测试记录类型导入功能 ---" -ForegroundColor Cyan
    
    $importData = @{
        recordTypes = @(
            @{
                name = "test_type_1"
                displayName = "测试类型1"
                schema = '{"type":"object","properties":{"content":{"type":"string"}}}'
                isActive = "true"
            },
            @{
                name = "test_type_2"
                displayName = "测试类型2"
                schema = '{"type":"object","properties":{"title":{"type":"string"},"content":{"type":"string"}}}'
                isActive = "true"
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
        } else {
            Write-Host "✗ 记录类型导入失败: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 记录类型导入请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 函数：测试记录导入功能
function Test-RecordImport {
    param($token)
    
    Write-Host "`n--- 测试记录导入功能 ---" -ForegroundColor Cyan
    
    $importData = @{
        records = @(
            @{
                title = "导入测试记录1"
                type = "daily_report"
                content = "这是通过导入功能创建的测试记录1"
                tags = "测试,导入"
                status = "published"
            },
            @{
                title = "导入测试记录2"
                type = "daily_report"
                content = "这是通过导入功能创建的测试记录2"
                tags = "测试,导入,记录"
                status = "draft"
            }
        )
    } | ConvertTo-Json -Depth 10
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records/import" -Method Post -Body $importData -Headers $headers
        if ($response.success) {
            Write-Host "✓ 记录导入成功" -ForegroundColor Green
            $results = $response.data.results
            foreach ($result in $results) {
                if ($result.success) {
                    Write-Host "  ✓ 记录 '$($result.title)' 导入成功，ID: $($result.record_id)" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ 记录 '$($result.title)' 导入失败: $($result.error)" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "✗ 记录导入失败: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 记录导入请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 函数：测试批量操作功能
function Test-BatchOperations {
    param($token)
    
    Write-Host "`n--- 测试批量操作功能 ---" -ForegroundColor Cyan
    
    # 测试批量更新角色状态
    Write-Host "测试批量更新角色状态..." -ForegroundColor Yellow
    
    # 首先获取角色列表
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    try {
        $rolesResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method Get -Headers $headers
        if ($rolesResponse.success -and $rolesResponse.data.Count -gt 0) {
            $testRoleIds = @()
            foreach ($role in $rolesResponse.data) {
                if ($role.name -like "test_role_*") {
                    $testRoleIds += $role.id
                }
            }
            
            if ($testRoleIds.Count -gt 0) {
                $batchUpdateData = @{
                    role_ids = $testRoleIds
                    status = "inactive"
                } | ConvertTo-Json -Depth 10
                
                $batchResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles/batch-status" -Method Put -Body $batchUpdateData -Headers $headers
                if ($batchResponse.success) {
                    Write-Host "  ✓ 批量更新角色状态成功" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ 批量更新角色状态失败: $($batchResponse.error.message)" -ForegroundColor Red
                }
            } else {
                Write-Host "  ! 没有找到测试角色，跳过批量操作测试" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "  ✗ 批量操作测试失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 函数：清理测试数据
function Cleanup-TestData {
    param($token)
    
    Write-Host "`n--- 清理测试数据 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 清理测试角色
    try {
        $rolesResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method Get -Headers $headers
        if ($rolesResponse.success) {
            foreach ($role in $rolesResponse.data) {
                if ($role.name -like "test_role_*") {
                    try {
                        $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles/$($role.id)" -Method Delete -Headers $headers
                        if ($deleteResponse.success) {
                            Write-Host "  ✓ 删除测试角色: $($role.displayName)" -ForegroundColor Green
                        }
                    } catch {
                        Write-Host "  ✗ 删除测试角色失败: $($role.displayName)" -ForegroundColor Red
                    }
                }
            }
        }
    } catch {
        Write-Host "  ✗ 清理测试角色失败" -ForegroundColor Red
    }
    
    # 清理测试记录类型
    try {
        $typesResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types" -Method Get -Headers $headers
        if ($typesResponse.success) {
            foreach ($type in $typesResponse.data) {
                if ($type.name -like "test_type_*") {
                    try {
                        $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/$($type.id)" -Method Delete -Headers $headers
                        if ($deleteResponse.success) {
                            Write-Host "  ✓ 删除测试记录类型: $($type.display_name)" -ForegroundColor Green
                        }
                    } catch {
                        Write-Host "  ✗ 删除测试记录类型失败: $($type.display_name)" -ForegroundColor Red
                    }
                }
            }
        }
    } catch {
        Write-Host "  ✗ 清理测试记录类型失败" -ForegroundColor Red
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
    
    # 测试角色导入功能
    Test-RoleImport -token $adminToken
    
    # 测试记录类型导入功能
    Test-RecordTypeImport -token $adminToken
    
    # 测试记录导入功能
    Test-RecordImport -token $adminToken
    
    # 测试批量操作功能
    Test-BatchOperations -token $adminToken
    
    # 清理测试数据
    Cleanup-TestData -token $adminToken
    
    Write-Host "`n=== 导入功能测试完成 ===" -ForegroundColor Green
    
} catch {
    Write-Host "测试过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}