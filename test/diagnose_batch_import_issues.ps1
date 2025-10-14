# 诊断批量操作和导入功能问题的脚本
# 编码：UTF-8

Write-Host "=== 诊断批量操作和导入功能问题 ===" -ForegroundColor Green

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

# 函数：检查服务健康状态
function Check-ServiceHealth {
    Write-Host "`n--- 检查服务健康状态 ---" -ForegroundColor Cyan
    
    try {
        $healthResponse = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get -TimeoutSec 5
        Write-Host "✓ 服务健康检查通过" -ForegroundColor Green
        Write-Host "  服务状态: $($healthResponse.status)" -ForegroundColor Gray
    } catch {
        Write-Host "✗ 服务健康检查失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    try {
        $readyResponse = Invoke-RestMethod -Uri "$baseUrl/ready" -Method Get -TimeoutSec 5
        Write-Host "✓ 服务就绪检查通过" -ForegroundColor Green
    } catch {
        Write-Host "✗ 服务就绪检查失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    return $true
}

# 函数：检查API端点可用性
function Check-APIEndpoints {
    param($token)
    
    Write-Host "`n--- 检查API端点可用性 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $endpoints = @(
        @{ Method = "GET"; URL = "/admin/roles"; Name = "角色列表" },
        @{ Method = "GET"; URL = "/api/v1/record-types"; Name = "记录类型列表" },
        @{ Method = "GET"; URL = "/admin/users"; Name = "用户列表" },
        @{ Method = "GET"; URL = "/api/v1/permissions/tree"; Name = "权限树" }
    )
    
    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-RestMethod -Uri "$baseUrl$($endpoint.URL)" -Method $endpoint.Method -Headers $headers -TimeoutSec 10
            if ($response.success) {
                Write-Host "✓ $($endpoint.Name) API 可用" -ForegroundColor Green
            } else {
                Write-Host "✗ $($endpoint.Name) API 返回错误: $($response.error.message)" -ForegroundColor Red
            }
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            if ($statusCode -eq 403) {
                Write-Host "! $($endpoint.Name) API 权限不足 (403)" -ForegroundColor Yellow
            } elseif ($statusCode -eq 404) {
                Write-Host "✗ $($endpoint.Name) API 不存在 (404)" -ForegroundColor Red
            } else {
                Write-Host "✗ $($endpoint.Name) API 请求失败: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# 函数：测试批量操作端点
function Test-BatchEndpoints {
    param($token)
    
    Write-Host "`n--- 测试批量操作端点 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 测试角色批量操作端点
    Write-Host "测试角色批量操作端点..." -ForegroundColor Yellow
    
    $testData = @{
        role_ids = @(999)  # 使用不存在的ID进行测试
        status = "active"
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/admin/roles/batch-status" -Method Put -Body $testData -Headers $headers
        Write-Host "  ✓ 角色批量状态更新端点存在" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 404) {
            Write-Host "  ✗ 角色批量状态更新端点不存在 (404)" -ForegroundColor Red
        } elseif ($statusCode -eq 400 -or $statusCode -eq 422) {
            Write-Host "  ✓ 角色批量状态更新端点存在（参数验证失败是正常的）" -ForegroundColor Green
        } else {
            Write-Host "  ? 角色批量状态更新端点状态未知: $statusCode" -ForegroundColor Yellow
        }
    }
    
    # 测试记录类型批量操作端点
    Write-Host "测试记录类型批量操作端点..." -ForegroundColor Yellow
    
    $testData = @{
        record_type_ids = @(999)  # 使用不存在的ID进行测试
        is_active = $true
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/batch-status" -Method Put -Body $testData -Headers $headers
        Write-Host "  ✓ 记录类型批量状态更新端点存在" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 404) {
            Write-Host "  ✗ 记录类型批量状态更新端点不存在 (404)" -ForegroundColor Red
        } elseif ($statusCode -eq 400 -or $statusCode -eq 422) {
            Write-Host "  ✓ 记录类型批量状态更新端点存在（参数验证失败是正常的）" -ForegroundColor Green
        } else {
            Write-Host "  ? 记录类型批量状态更新端点状态未知: $statusCode" -ForegroundColor Yellow
        }
    }
}

# 函数：测试导入端点
function Test-ImportEndpoints {
    param($token)
    
    Write-Host "`n--- 测试导入端点 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # 测试角色导入端点
    Write-Host "测试角色导入端点..." -ForegroundColor Yellow
    
    $testData = @{
        roles = @()  # 空数据进行测试
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/admin/roles/import" -Method Post -Body $testData -Headers $headers
        Write-Host "  ✓ 角色导入端点存在" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 404) {
            Write-Host "  ✗ 角色导入端点不存在 (404)" -ForegroundColor Red
        } elseif ($statusCode -eq 400 -or $statusCode -eq 422) {
            Write-Host "  ✓ 角色导入端点存在（参数验证失败是正常的）" -ForegroundColor Green
        } else {
            Write-Host "  ? 角色导入端点状态未知: $statusCode" -ForegroundColor Yellow
        }
    }
    
    # 测试记录类型导入端点
    Write-Host "测试记录类型导入端点..." -ForegroundColor Yellow
    
    $testData = @{
        recordTypes = @()  # 空数据进行测试
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/import" -Method Post -Body $testData -Headers $headers
        Write-Host "  ✓ 记录类型导入端点存在" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 404) {
            Write-Host "  ✗ 记录类型导入端点不存在 (404)" -ForegroundColor Red
        } elseif ($statusCode -eq 400 -or $statusCode -eq 422) {
            Write-Host "  ✓ 记录类型导入端点存在（参数验证失败是正常的）" -ForegroundColor Green
        } else {
            Write-Host "  ? 记录类型导入端点状态未知: $statusCode" -ForegroundColor Yellow
        }
    }
    
    # 测试记录导入端点
    Write-Host "测试记录导入端点..." -ForegroundColor Yellow
    
    $testData = @{
        records = @()  # 空数据进行测试
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records/import" -Method Post -Body $testData -Headers $headers
        Write-Host "  ✓ 记录导入端点存在" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 404) {
            Write-Host "  ✗ 记录导入端点不存在 (404)" -ForegroundColor Red
        } elseif ($statusCode -eq 400 -or $statusCode -eq 422) {
            Write-Host "  ✓ 记录导入端点存在（参数验证失败是正常的）" -ForegroundColor Green
        } else {
            Write-Host "  ? 记录导入端点状态未知: $statusCode" -ForegroundColor Yellow
        }
    }
}

# 函数：检查权限配置
function Check-PermissionConfiguration {
    param($token)
    
    Write-Host "`n--- 检查权限配置 ---" -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    try {
        # 检查当前用户权限
        $userResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/users/profile" -Method Get -Headers $headers
        if ($userResponse.success) {
            Write-Host "✓ 当前用户信息获取成功" -ForegroundColor Green
            Write-Host "  用户名: $($userResponse.data.username)" -ForegroundColor Gray
            Write-Host "  角色: $($userResponse.data.roles -join ', ')" -ForegroundColor Gray
        }
        
        # 检查权限验证
        $permissionCheck = @{
            resource = "system"
            action = "admin"
            scope = "all"
        } | ConvertTo-Json -Depth 10
        
        $permResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/permissions/check" -Method Post -Body $permissionCheck -Headers $headers
        if ($permResponse.success) {
            Write-Host "✓ 权限检查功能正常" -ForegroundColor Green
            Write-Host "  管理员权限: $($permResponse.data.hasPermission)" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "✗ 权限检查失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 函数：生成诊断报告
function Generate-DiagnosticReport {
    param($issues)
    
    Write-Host "`n=== 诊断报告 ===" -ForegroundColor Magenta
    
    if ($issues.Count -eq 0) {
        Write-Host "✓ 未发现明显问题，所有检查都通过了" -ForegroundColor Green
        Write-Host "`n可能的问题原因:" -ForegroundColor Yellow
        Write-Host "1. 前端请求格式与后端期望不匹配" -ForegroundColor Gray
        Write-Host "2. 数据验证失败（如必填字段缺失）" -ForegroundColor Gray
        Write-Host "3. 业务逻辑限制（如系统角色保护）" -ForegroundColor Gray
        Write-Host "4. 网络连接问题或超时" -ForegroundColor Gray
    } else {
        Write-Host "发现以下问题:" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
    }
    
    Write-Host "`n建议的解决步骤:" -ForegroundColor Yellow
    Write-Host "1. 检查后端服务是否正常运行" -ForegroundColor Gray
    Write-Host "2. 验证管理员账号权限是否正确" -ForegroundColor Gray
    Write-Host "3. 检查前端请求的数据格式" -ForegroundColor Gray
    Write-Host "4. 查看后端日志获取详细错误信息" -ForegroundColor Gray
    Write-Host "5. 使用浏览器开发者工具检查网络请求" -ForegroundColor Gray
}

# 主执行流程
try {
    $issues = @()
    
    # 检查服务健康状态
    if (-not (Check-ServiceHealth)) {
        $issues += "服务健康检查失败"
    }
    
    # 获取管理员Token
    $adminToken = Get-AdminToken
    if (-not $adminToken) {
        $issues += "无法获取管理员Token"
        Write-Host "无法继续后续检查，请确保管理员账号正确" -ForegroundColor Red
        exit 1
    }
    
    # 检查API端点可用性
    Check-APIEndpoints -token $adminToken
    
    # 测试批量操作端点
    Test-BatchEndpoints -token $adminToken
    
    # 测试导入端点
    Test-ImportEndpoints -token $adminToken
    
    # 检查权限配置
    Check-PermissionConfiguration -token $adminToken
    
    # 生成诊断报告
    Generate-DiagnosticReport -issues $issues
    
    Write-Host "`n=== 诊断完成 ===" -ForegroundColor Green
    
} catch {
    Write-Host "诊断过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}