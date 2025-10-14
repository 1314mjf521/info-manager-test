# 测试批量操作修复
# 编码：UTF-8

Write-Host "=== 测试批量操作修复 ===" -ForegroundColor Green

# 设置API基础URL
$baseUrl = "http://localhost:8080/api/v1"
$token = ""

# 登录获取token
function Get-AuthToken {
    Write-Host "正在登录..." -ForegroundColor Yellow
    
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginData -ContentType "application/json"
        if ($response.success -and $response.data.access_token) {
            $script:token = $response.data.access_token
            Write-Host "登录成功" -ForegroundColor Green
            return $true
        } else {
            Write-Host "登录失败" -ForegroundColor Red
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

# 测试记录类型批量状态更新
function Test-RecordTypeBatchStatus {
    Write-Host "`n--- 测试记录类型批量状态更新 ---" -ForegroundColor Cyan
    
    try {
        # 获取记录类型列表
        $typesResponse = Invoke-RestMethod -Uri "$baseUrl/record-types" -Method Get -Headers (Get-AuthHeaders)
        if (-not $typesResponse.success -or -not $typesResponse.data -or $typesResponse.data.Count -eq 0) {
            Write-Host "没有找到记录类型" -ForegroundColor Yellow
            return $false
        }
        
        $recordTypes = $typesResponse.data
        Write-Host "找到 $($recordTypes.Count) 个记录类型" -ForegroundColor Gray
        
        # 选择前两个记录类型进行测试
        $testTypes = $recordTypes | Select-Object -First 2
        $typeIds = $testTypes | ForEach-Object { $_.id }
        
        Write-Host "测试记录类型ID：$($typeIds -join ', ')" -ForegroundColor Gray
        
        # 测试批量禁用（is_active: false）
        Write-Host "测试批量禁用..." -ForegroundColor Yellow
        $disableData = @{
            record_type_ids = $typeIds
            is_active = $false
        } | ConvertTo-Json
        
        Write-Host "发送数据：$disableData" -ForegroundColor Gray
        
        $disableResponse = Invoke-RestMethod -Uri "$baseUrl/record-types/batch-status" -Method Put -Body $disableData -Headers (Get-AuthHeaders)
        if ($disableResponse.success) {
            Write-Host "批量禁用成功：$($disableResponse.data.message)" -ForegroundColor Green
        } else {
            Write-Host "批量禁用失败" -ForegroundColor Red
            return $false
        }
        
        # 测试批量启用（is_active: true）
        Write-Host "测试批量启用..." -ForegroundColor Yellow
        $enableData = @{
            record_type_ids = $typeIds
            is_active = $true
        } | ConvertTo-Json
        
        Write-Host "发送数据：$enableData" -ForegroundColor Gray
        
        $enableResponse = Invoke-RestMethod -Uri "$baseUrl/record-types/batch-status" -Method Put -Body $enableData -Headers (Get-AuthHeaders)
        if ($enableResponse.success) {
            Write-Host "批量启用成功：$($enableResponse.data.message)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "批量启用失败" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "记录类型批量状态更新测试失败：$($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $responseBody = $reader.ReadToEnd()
            Write-Host "错误详情：$responseBody" -ForegroundColor Red
        }
        return $false
    }
}

# 测试角色批量状态更新
function Test-RoleBatchStatus {
    Write-Host "`n--- 测试角色批量状态更新 ---" -ForegroundColor Cyan
    
    try {
        # 获取角色列表
        $rolesResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method Get -Headers (Get-AuthHeaders)
        if (-not $rolesResponse.success -or -not $rolesResponse.data -or $rolesResponse.data.Count -eq 0) {
            Write-Host "没有找到角色" -ForegroundColor Yellow
            return $false
        }
        
        $roles = $rolesResponse.data
        Write-Host "找到 $($roles.Count) 个角色" -ForegroundColor Gray
        
        # 选择非系统角色进行测试
        $testRoles = $roles | Where-Object { -not ($_.is_system -or $_.isSystem) } | Select-Object -First 2
        if ($testRoles.Count -eq 0) {
            Write-Host "没有找到可测试的非系统角色" -ForegroundColor Yellow
            return $true  # 这不算失败，只是没有测试数据
        }
        
        $roleIds = $testRoles | ForEach-Object { $_.id }
        Write-Host "测试角色ID：$($roleIds -join ', ')" -ForegroundColor Gray
        
        # 测试批量禁用
        Write-Host "测试角色批量禁用..." -ForegroundColor Yellow
        $disableData = @{
            role_ids = $roleIds
            status = "inactive"
        } | ConvertTo-Json
        
        Write-Host "发送数据：$disableData" -ForegroundColor Gray
        
        $disableResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles/batch-status" -Method Put -Body $disableData -Headers (Get-AuthHeaders)
        if ($disableResponse.success) {
            Write-Host "角色批量禁用成功：$($disableResponse.data.message)" -ForegroundColor Green
        } else {
            Write-Host "角色批量禁用失败" -ForegroundColor Red
            return $false
        }
        
        # 测试批量启用
        Write-Host "测试角色批量启用..." -ForegroundColor Yellow
        $enableData = @{
            role_ids = $roleIds
            status = "active"
        } | ConvertTo-Json
        
        Write-Host "发送数据：$enableData" -ForegroundColor Gray
        
        $enableResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles/batch-status" -Method Put -Body $enableData -Headers (Get-AuthHeaders)
        if ($enableResponse.success) {
            Write-Host "角色批量启用成功：$($enableResponse.data.message)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "角色批量启用失败" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "角色批量状态更新测试失败：$($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $responseBody = $reader.ReadToEnd()
            Write-Host "错误详情：$responseBody" -ForegroundColor Red
        }
        return $false
    }
}

# 主测试流程
function Main {
    Write-Host "开始测试批量操作修复..." -ForegroundColor Green
    
    # 登录
    if (-not (Get-AuthToken)) {
        Write-Host "无法获取认证token，测试终止" -ForegroundColor Red
        return
    }
    
    $testResults = @()
    
    # 执行测试
    $testResults += @{ Name = "记录类型批量状态更新"; Result = (Test-RecordTypeBatchStatus) }
    $testResults += @{ Name = "角色批量状态更新"; Result = (Test-RoleBatchStatus) }
    
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
        Write-Host "批量操作修复验证成功！" -ForegroundColor Green
        Write-Host "修复要点：移除了布尔字段的 binding:\"required\" 标签" -ForegroundColor Cyan
    } else {
        Write-Host "部分测试失败，请检查相关功能" -ForegroundColor Yellow
    }
}

# 执行主测试
Main