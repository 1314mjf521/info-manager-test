# 简单测试批量操作功能的脚本
# 编码：UTF-8

Write-Host "=== 简单测试批量操作功能 ===" -ForegroundColor Green

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

# 函数：测试角色导入
function Test-RoleImport {
    param($token)
    
    Write-Host "`n--- 测试角色导入 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $importData = @{
        roles = @(
            @{
                name = "simple_test_role"
                displayName = "简单测试角色"
                description = "用于测试的简单角色"
                status = "active"
                permissions = ""
            }
        )
    } | ConvertTo-Json -Depth 10
    
    Write-Host "发送请求到: $baseUrl/admin/roles/import" -ForegroundColor Gray
    Write-Host "请求数据: $importData" -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/admin/roles/import" -Method Post -Body $importData -Headers $headers
        Write-Host "✓ 角色导入请求成功" -ForegroundColor Green
        Write-Host "响应: $($response | ConvertTo-Json -Depth 10)" -ForegroundColor Gray
        return $response
    } catch {
        Write-Host "✗ 角色导入请求失败" -ForegroundColor Red
        Write-Host "错误详情: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "HTTP状态码: $statusCode" -ForegroundColor Red
            
            try {
                $errorStream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($errorStream)
                $errorBody = $reader.ReadToEnd()
                Write-Host "错误响应体: $errorBody" -ForegroundColor Red
            } catch {
                Write-Host "无法读取错误响应体" -ForegroundColor Red
            }
        }
        return $null
    }
}

# 函数：测试记录类型导入
function Test-RecordTypeImport {
    param($token)
    
    Write-Host "`n--- 测试记录类型导入 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $importData = @{
        recordTypes = @(
            @{
                name = "simple_test_type"
                displayName = "简单测试类型"
                schema = ""
                isActive = "true"
            }
        )
    } | ConvertTo-Json -Depth 10
    
    Write-Host "发送请求到: $baseUrl/api/v1/record-types/import" -ForegroundColor Gray
    Write-Host "请求数据: $importData" -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/import" -Method Post -Body $importData -Headers $headers
        Write-Host "✓ 记录类型导入请求成功" -ForegroundColor Green
        Write-Host "响应: $($response | ConvertTo-Json -Depth 10)" -ForegroundColor Gray
        return $response
    } catch {
        Write-Host "✗ 记录类型导入请求失败" -ForegroundColor Red
        Write-Host "错误详情: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "HTTP状态码: $statusCode" -ForegroundColor Red
            
            try {
                $errorStream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($errorStream)
                $errorBody = $reader.ReadToEnd()
                Write-Host "错误响应体: $errorBody" -ForegroundColor Red
            } catch {
                Write-Host "无法读取错误响应体" -ForegroundColor Red
            }
        }
        return $null
    }
}

# 函数：测试批量状态更新
function Test-BatchStatusUpdate {
    param($token)
    
    Write-Host "`n--- 测试批量状态更新 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 先获取角色列表
    try {
        $rolesResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method Get -Headers $headers
        if ($rolesResponse.success -and $rolesResponse.data.Count -gt 0) {
            # 找到测试角色
            $testRole = $rolesResponse.data | Where-Object { $_.name -eq "simple_test_role" }
            
            if ($testRole) {
                Write-Host "找到测试角色，ID: $($testRole.id)" -ForegroundColor Gray
                
                # 测试批量状态更新
                $statusData = @{
                    role_ids = @($testRole.id)
                    status = "inactive"
                } | ConvertTo-Json -Depth 10
                
                Write-Host "发送批量状态更新请求..." -ForegroundColor Gray
                Write-Host "请求数据: $statusData" -ForegroundColor Gray
                
                $statusResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles/batch-status" -Method Put -Body $statusData -Headers $headers
                Write-Host "✓ 批量状态更新成功" -ForegroundColor Green
                Write-Host "响应: $($statusResponse | ConvertTo-Json -Depth 10)" -ForegroundColor Gray
            } else {
                Write-Host "! 没有找到测试角色，跳过批量状态更新测试" -ForegroundColor Yellow
            }
        } else {
            Write-Host "! 没有获取到角色列表" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ 批量状态更新失败" -ForegroundColor Red
        Write-Host "错误详情: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "HTTP状态码: $statusCode" -ForegroundColor Red
        }
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
            $testRole = $rolesResponse.data | Where-Object { $_.name -eq "simple_test_role" }
            if ($testRole) {
                $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles/$($testRole.id)" -Method Delete -Headers $headers
                Write-Host "✓ 清理测试角色成功" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "! 清理测试角色失败（可能已不存在）" -ForegroundColor Yellow
    }
    
    # 清理测试记录类型
    try {
        $typesResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types" -Method Get -Headers $headers
        if ($typesResponse.success) {
            $testType = $typesResponse.data | Where-Object { $_.name -eq "simple_test_type" }
            if ($testType) {
                $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/$($testType.id)" -Method Delete -Headers $headers
                Write-Host "✓ 清理测试记录类型成功" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "! 清理测试记录类型失败（可能已不存在）" -ForegroundColor Yellow
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
    
    # 测试角色导入
    $roleImportResult = Test-RoleImport -token $adminToken
    
    # 测试记录类型导入
    $recordTypeImportResult = Test-RecordTypeImport -token $adminToken
    
    # 测试批量状态更新
    Test-BatchStatusUpdate -token $adminToken
    
    # 清理测试数据
    Cleanup-TestData -token $adminToken
    
    Write-Host "`n=== 简单测试完成 ===" -ForegroundColor Green
    
    # 总结测试结果
    Write-Host "`n=== 测试结果总结 ===" -ForegroundColor Magenta
    if ($roleImportResult) {
        Write-Host "✓ 角色导入功能正常" -ForegroundColor Green
    } else {
        Write-Host "✗ 角色导入功能异常" -ForegroundColor Red
    }
    
    if ($recordTypeImportResult) {
        Write-Host "✓ 记录类型导入功能正常" -ForegroundColor Green
    } else {
        Write-Host "✗ 记录类型导入功能异常" -ForegroundColor Red
    }
    
} catch {
    Write-Host "测试过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}