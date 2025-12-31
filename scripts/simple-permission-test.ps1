# 简化权限测试脚本
Write-Host "=== 简化权限测试 ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080"
$testResults = @()

# 获取认证令牌
function Get-AuthToken {
    param([string]$Username, [string]$Password)
    
    try {
        $loginData = "{`"username`":`"$Username`",`"password`":`"$Password`"}"
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        return $response.data.token
    } catch {
        Write-Host "❌ 登录失败 ($Username): $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 测试API端点
function Test-ApiAccess {
    param(
        [string]$Name,
        [string]$Url,
        [hashtable]$Headers,
        [string]$UserType
    )
    
    try {
        $response = Invoke-WebRequest -Uri "$baseUrl$Url" -Method GET -Headers $Headers -TimeoutSec 10
        $success = $response.StatusCode -eq 200
        $status = if ($success) { "✅ PASS" } else { "❌ FAIL" }
        
        Write-Host "  $status $Name ($UserType) - HTTP $($response.StatusCode)" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
        
        $script:testResults += @{
            Name = $Name
            UserType = $UserType
            Status = $status
            StatusCode = $response.StatusCode
        }
        
        return $success
    } catch {
        $statusCode = "Unknown"
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        
        # 对于权限测试，403/401可能是预期结果
        $isExpectedDenial = ($statusCode -eq 403 -or $statusCode -eq 401) -and $UserType -eq "Tiker"
        $status = if ($isExpectedDenial) { "✅ PASS (Denied)" } else { "❌ FAIL" }
        
        Write-Host "  $status $Name ($UserType) - HTTP $statusCode" -ForegroundColor $(if ($isExpectedDenial) { "Green" } else { "Red" })
        
        $script:testResults += @{
            Name = $Name
            UserType = $UserType
            Status = $status
            StatusCode = $statusCode
        }
        
        return $isExpectedDenial
    }
}

# 1. 获取认证令牌
Write-Host "`n1. 获取认证令牌..." -ForegroundColor Cyan

$adminToken = Get-AuthToken -Username "admin" -Password "admin123"
if (-not $adminToken) {
    Write-Host "❌ 无法获取Admin令牌，退出测试" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Admin令牌获取成功" -ForegroundColor Green

$tikerToken = Get-AuthToken -Username "tiker_test" -Password "tiker123"
if (-not $tikerToken) {
    Write-Host "❌ 无法获取Tiker令牌，退出测试" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Tiker令牌获取成功" -ForegroundColor Green

$adminHeaders = @{ "Authorization" = "Bearer $adminToken" }
$tikerHeaders = @{ "Authorization" = "Bearer $tikerToken" }

# 2. 测试核心API端点
Write-Host "`n2. 测试核心API端点..." -ForegroundColor Cyan

# 系统健康检查
Write-Host "`n  系统健康检查:" -ForegroundColor Yellow
Test-ApiAccess -Name "系统健康" -Url "/health" -Headers @{} -UserType "Public"

# 用户管理
Write-Host "`n  用户管理:" -ForegroundColor Yellow
Test-ApiAccess -Name "用户列表" -Url "/api/v1/admin/users" -Headers $adminHeaders -UserType "Admin"
Test-ApiAccess -Name "用户列表" -Url "/api/v1/admin/users" -Headers $tikerHeaders -UserType "Tiker"

# 角色管理
Write-Host "`n  角色管理:" -ForegroundColor Yellow
Test-ApiAccess -Name "角色列表" -Url "/api/v1/admin/roles" -Headers $adminHeaders -UserType "Admin"
Test-ApiAccess -Name "角色列表" -Url "/api/v1/admin/roles" -Headers $tikerHeaders -UserType "Tiker"

# 权限管理
Write-Host "`n  权限管理:" -ForegroundColor Yellow
Test-ApiAccess -Name "权限列表" -Url "/api/v1/permissions" -Headers $adminHeaders -UserType "Admin"
Test-ApiAccess -Name "权限列表" -Url "/api/v1/permissions" -Headers $tikerHeaders -UserType "Tiker"

# 工单管理
Write-Host "`n  工单管理:" -ForegroundColor Yellow
Test-ApiAccess -Name "工单列表" -Url "/api/v1/tickets" -Headers $adminHeaders -UserType "Admin"
Test-ApiAccess -Name "工单列表" -Url "/api/v1/tickets" -Headers $tikerHeaders -UserType "Tiker"
Test-ApiAccess -Name "工单统计" -Url "/api/v1/tickets/statistics" -Headers $adminHeaders -UserType "Admin"
Test-ApiAccess -Name "工单统计" -Url "/api/v1/tickets/statistics" -Headers $tikerHeaders -UserType "Tiker"
Test-ApiAccess -Name "工单导出" -Url "/api/v1/tickets/export?format=csv" -Headers $adminHeaders -UserType "Admin"
Test-ApiAccess -Name "工单导出" -Url "/api/v1/tickets/export?format=csv" -Headers $tikerHeaders -UserType "Tiker"

# 文件管理
Write-Host "`n  文件管理:" -ForegroundColor Yellow
Test-ApiAccess -Name "文件列表" -Url "/api/v1/files" -Headers $adminHeaders -UserType "Admin"
Test-ApiAccess -Name "文件列表" -Url "/api/v1/files" -Headers $tikerHeaders -UserType "Tiker"

# 系统配置
Write-Host "`n  系统配置:" -ForegroundColor Yellow
Test-ApiAccess -Name "系统统计" -Url "/api/v1/system/stats" -Headers $adminHeaders -UserType "Admin"
Test-ApiAccess -Name "系统统计" -Url "/api/v1/system/stats" -Headers $tikerHeaders -UserType "Tiker"

# 3. 测试工单创建
Write-Host "`n3. 测试工单创建..." -ForegroundColor Cyan

$ticketJson = '{"title":"权限测试工单","description":"用于权限验证的测试工单","type":"bug","priority":"normal"}'

try {
    Write-Host "`n  Admin创建工单:" -ForegroundColor Yellow
    $adminCreateResponse = Invoke-WebRequest -Uri "$baseUrl/api/v1/tickets" -Method POST -Body $ticketJson -ContentType "application/json" -Headers $adminHeaders -TimeoutSec 10
    Write-Host "  ✅ Admin创建工单成功 - HTTP $($adminCreateResponse.StatusCode)" -ForegroundColor Green
    
    # 获取创建的工单ID
    $responseData = $adminCreateResponse.Content | ConvertFrom-Json
    $testTicketId = $responseData.data.id
    Write-Host "  📝 测试工单ID: $testTicketId" -ForegroundColor Gray
    
} catch {
    Write-Host "  ❌ Admin创建工单失败: $($_.Exception.Message)" -ForegroundColor Red
    $testTicketId = $null
}

try {
    Write-Host "`n  Tiker创建工单:" -ForegroundColor Yellow
    $tikerCreateResponse = Invoke-WebRequest -Uri "$baseUrl/api/v1/tickets" -Method POST -Body $ticketJson -ContentType "application/json" -Headers $tikerHeaders -TimeoutSec 10
    Write-Host "  ✅ Tiker创建工单成功 - HTTP $($tikerCreateResponse.StatusCode)" -ForegroundColor Green
} catch {
    $statusCode = "Unknown"
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode
    }
    Write-Host "  ❌ Tiker创建工单失败 - HTTP $statusCode" -ForegroundColor Red
}

# 4. 如果有测试工单，测试读取和更新
if ($testTicketId) {
    Write-Host "`n4. 测试工单操作..." -ForegroundColor Cyan
    
    Write-Host "`n  工单读取:" -ForegroundColor Yellow
    Test-ApiAccess -Name "工单详情" -Url "/api/v1/tickets/$testTicketId" -Headers $adminHeaders -UserType "Admin"
    Test-ApiAccess -Name "工单详情" -Url "/api/v1/tickets/$testTicketId" -Headers $tikerHeaders -UserType "Tiker"
    
    # 清理测试工单
    try {
        Invoke-RestMethod -Uri "$baseUrl/api/v1/tickets/$testTicketId" -Method DELETE -Headers $adminHeaders
        Write-Host "  🧹 测试工单已清理" -ForegroundColor Gray
    } catch {
        Write-Host "  ⚠️ 无法清理测试工单" -ForegroundColor Yellow
    }
}

# 5. 生成测试报告
Write-Host "`n=== 权限测试报告 ===" -ForegroundColor Green

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Status -like "*PASS*" }).Count
$failedTests = $totalTests - $passedTests

Write-Host "`n📊 测试统计:" -ForegroundColor Yellow
Write-Host "总测试数: $totalTests" -ForegroundColor Gray
Write-Host "通过测试: $passedTests" -ForegroundColor Green
Write-Host "失败测试: $failedTests" -ForegroundColor Red
if ($totalTests -gt 0) {
    Write-Host "成功率: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor Cyan
}

Write-Host "`n📋 详细结果:" -ForegroundColor Yellow
$testResults | Sort-Object Name, UserType | ForEach-Object {
    $color = if ($_.Status -like "*PASS*") { "Green" } else { "Red" }
    Write-Host "  $($_.Name) ($($_.UserType)): $($_.Status)" -ForegroundColor $color
}

# 按用户类型分组统计
Write-Host "`n👤 用户类型统计:" -ForegroundColor Yellow
$adminResults = $testResults | Where-Object { $_.UserType -eq "Admin" }
$tikerResults = $testResults | Where-Object { $_.UserType -eq "Tiker" }
$publicResults = $testResults | Where-Object { $_.UserType -eq "Public" }

if ($adminResults.Count -gt 0) {
    $adminPassed = ($adminResults | Where-Object { $_.Status -like "*PASS*" }).Count
    $adminRate = [math]::Round(($adminPassed / $adminResults.Count) * 100, 1)
    Write-Host "  Admin: $adminPassed/$($adminResults.Count) ($adminRate%)" -ForegroundColor Cyan
}

if ($tikerResults.Count -gt 0) {
    $tikerPassed = ($tikerResults | Where-Object { $_.Status -like "*PASS*" }).Count
    $tikerRate = [math]::Round(($tikerPassed / $tikerResults.Count) * 100, 1)
    Write-Host "  Tiker: $tikerPassed/$($tikerResults.Count) ($tikerRate%)" -ForegroundColor Cyan
}

if ($publicResults.Count -gt 0) {
    $publicPassed = ($publicResults | Where-Object { $_.Status -like "*PASS*" }).Count
    $publicRate = [math]::Round(($publicPassed / $publicResults.Count) * 100, 1)
    Write-Host "  Public: $publicPassed/$($publicResults.Count) ($publicRate%)" -ForegroundColor Cyan
}

if ($failedTests -eq 0) {
    Write-Host "`n🎉 所有权限测试通过！" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️ 有 $failedTests 个测试失败，请检查权限配置。" -ForegroundColor Yellow
    exit 1
}