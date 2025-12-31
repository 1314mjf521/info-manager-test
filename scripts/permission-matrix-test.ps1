# 权限矩阵测试脚本
Write-Host "=== 权限矩阵验证测试 ===" -ForegroundColor Green

$testResults = @()
$baseUrl = "http://localhost:8080"

# 获取认证令牌
function Get-AuthToken {
    param([string]$Username, [string]$Password)
    
    try {
        $loginData = @{
            username = $Username
            password = $Password
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        return $response.data.token
    } catch {
        Write-Host "❌ 登录失败 ($Username): $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 测试API端点
function Test-Permission {
    param(
        [string]$Permission,
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers,
        [string]$UserType,
        [hashtable]$Body = $null
    )
    
    try {
        $fullUrl = $baseUrl + $Url
        
        if ($Body) {
            $jsonBody = $Body | ConvertTo-Json
            $response = Invoke-WebRequest -Uri $fullUrl -Method $Method -Headers $Headers -Body $jsonBody -ContentType "application/json" -TimeoutSec 10
        } else {
            $response = Invoke-WebRequest -Uri $fullUrl -Method $Method -Headers $Headers -TimeoutSec 10
        }
        
        $success = $response.StatusCode -eq 200 -or $response.StatusCode -eq 201
        $status = if ($success) { "✅ PASS" } else { "❌ FAIL" }
        
        $testResults += @{
            Permission = $Permission
            UserType = $UserType
            Status = $status
            StatusCode = $response.StatusCode
            Method = $Method
            Url = $Url
        }
        
        Write-Host "  $status $Permission ($UserType) - HTTP $($response.StatusCode)" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
        return $success
        
    } catch {
        $statusCode = "Unknown"
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        
        # 对于权限测试，403/401可能是预期结果
        $isExpectedDenial = ($statusCode -eq 403 -or $statusCode -eq 401) -and 
                           ($UserType -eq "Tiker" -and ($Permission -like "*admin*" -or $Permission -like "*system*" -or $Permission -like "*users*" -or $Permission -like "*roles*"))
        
        $status = if ($isExpectedDenial) { "✅ PASS" } else { "❌ FAIL" }
        $details = if ($isExpectedDenial) { "Correctly denied" } else { "Access denied" }
        
        $testResults += @{
            Permission = $Permission
            UserType = $UserType
            Status = $status
            StatusCode = $statusCode
            Method = $Method
            Url = $Url
            Details = $details
        }
        
        Write-Host "  $status $Permission ($UserType) - $details (HTTP $statusCode)" -ForegroundColor $(if ($isExpectedDenial) { "Green" } else { "Red" })
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

# 2. 测试核心权限
Write-Host "`n2. 测试核心权限..." -ForegroundColor Cyan

# 系统健康检查（无需权限）
Write-Host "`n  系统健康检查:" -ForegroundColor Yellow
Test-Permission -Permission "system:health" -Method "GET" -Url "/health" -Headers @{} -UserType "Public"

# 系统管理权限
Write-Host "`n  系统管理权限:" -ForegroundColor Yellow
Test-Permission -Permission "system:stats" -Method "GET" -Url "/api/v1/system/stats" -Headers $adminHeaders -UserType "Admin"
Test-Permission -Permission "system:stats" -Method "GET" -Url "/api/v1/system/stats" -Headers $tikerHeaders -UserType "Tiker"

# 用户管理权限
Write-Host "`n  用户管理权限:" -ForegroundColor Yellow
Test-Permission -Permission "users:read" -Method "GET" -Url "/api/v1/admin/users" -Headers $adminHeaders -UserType "Admin"
Test-Permission -Permission "users:read" -Method "GET" -Url "/api/v1/admin/users" -Headers $tikerHeaders -UserType "Tiker"

# 角色管理权限
Write-Host "`n  角色管理权限:" -ForegroundColor Yellow
Test-Permission -Permission "roles:read" -Method "GET" -Url "/api/v1/admin/roles" -Headers $adminHeaders -UserType "Admin"
Test-Permission -Permission "roles:read" -Method "GET" -Url "/api/v1/admin/roles" -Headers $tikerHeaders -UserType "Tiker"

# 权限管理权限
Write-Host "`n  权限管理权限:" -ForegroundColor Yellow
Test-Permission -Permission "permissions:read" -Method "GET" -Url "/api/v1/permissions" -Headers $adminHeaders -UserType "Admin"
Test-Permission -Permission "permissions:read" -Method "GET" -Url "/api/v1/permissions" -Headers $tikerHeaders -UserType "Tiker"

# 工单管理权限
Write-Host "`n  工单管理权限:" -ForegroundColor Yellow
Test-Permission -Permission "ticket:read" -Method "GET" -Url "/api/v1/tickets" -Headers $adminHeaders -UserType "Admin"
Test-Permission -Permission "ticket:read_own" -Method "GET" -Url "/api/v1/tickets" -Headers $tikerHeaders -UserType "Tiker"
Test-Permission -Permission "ticket:statistics" -Method "GET" -Url "/api/v1/tickets/statistics" -Headers $adminHeaders -UserType "Admin"
Test-Permission -Permission "ticket:statistics" -Method "GET" -Url "/api/v1/tickets/statistics" -Headers $tikerHeaders -UserType "Tiker"
Test-Permission -Permission "ticket:export" -Method "GET" -Url "/api/v1/tickets/export?format=csv" -Headers $adminHeaders -UserType "Admin"
Test-Permission -Permission "ticket:export" -Method "GET" -Url "/api/v1/tickets/export?format=csv" -Headers $tikerHeaders -UserType "Tiker"

# 文件管理权限
Write-Host "`n  文件管理权限:" -ForegroundColor Yellow
Test-Permission -Permission "files:read" -Method "GET" -Url "/api/v1/files" -Headers $adminHeaders -UserType "Admin"
Test-Permission -Permission "files:read" -Method "GET" -Url "/api/v1/files" -Headers $tikerHeaders -UserType "Tiker"

# 3. 测试工单CRUD操作
Write-Host "`n3. 测试工单CRUD操作..." -ForegroundColor Cyan

# 创建工单
Write-Host "`n  创建工单:" -ForegroundColor Yellow
$ticketData = @{
    title = "权限测试工单"
    description = "用于权限验证的测试工单"
    type = "bug"
    priority = "normal"
}

$adminCreateResult = Test-Permission -Permission "ticket:create" -Method "POST" -Url "/api/v1/tickets" -Headers $adminHeaders -UserType "Admin" -Body $ticketData
$tikerCreateResult = Test-Permission -Permission "ticket:create" -Method "POST" -Url "/api/v1/tickets" -Headers $tikerHeaders -UserType "Tiker" -Body $ticketData

# 如果创建成功，获取工单ID进行后续测试
$testTicketId = $null
if ($adminCreateResult) {
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/tickets" -Method POST -Body ($ticketData | ConvertTo-Json) -ContentType "application/json" -Headers $adminHeaders
        $testTicketId = $response.data.id
        Write-Host "  📝 测试工单ID: $testTicketId" -ForegroundColor Gray
    } catch {
        Write-Host "  ⚠️ 无法获取测试工单ID" -ForegroundColor Yellow
    }
}

# 如果有测试工单，进行读取和更新测试
if ($testTicketId) {
    Write-Host "`n  读取工单:" -ForegroundColor Yellow
    Test-Permission -Permission "ticket:read" -Method "GET" -Url "/api/v1/tickets/$testTicketId" -Headers $adminHeaders -UserType "Admin"
    Test-Permission -Permission "ticket:read_own" -Method "GET" -Url "/api/v1/tickets/$testTicketId" -Headers $tikerHeaders -UserType "Tiker"
    
    Write-Host "`n  更新工单:" -ForegroundColor Yellow
    $updateData = @{ title = "更新后的权限测试工单" }
    Test-Permission -Permission "ticket:update" -Method "PUT" -Url "/api/v1/tickets/$testTicketId" -Headers $adminHeaders -UserType "Admin" -Body $updateData
    Test-Permission -Permission "ticket:update_own" -Method "PUT" -Url "/api/v1/tickets/$testTicketId" -Headers $tikerHeaders -UserType "Tiker" -Body $updateData
    
    # 清理测试工单
    try {
        Invoke-RestMethod -Uri "$baseUrl/api/v1/tickets/$testTicketId" -Method DELETE -Headers $adminHeaders
        Write-Host "  🧹 测试工单已清理" -ForegroundColor Gray
    } catch {
        Write-Host "  ⚠️ 无法清理测试工单" -ForegroundColor Yellow
    }
}

# 4. 生成测试报告
Write-Host "`n=== 权限矩阵测试报告 ===" -ForegroundColor Green

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
$testResults | Sort-Object Permission, UserType | ForEach-Object {
    $color = if ($_.Status -like "*PASS*") { "Green" } else { "Red" }
    $details = if ($_.Details) { " - $($_.Details)" } else { "" }
    Write-Host "  $($_.Permission) ($($_.UserType)): $($_.Status)$details" -ForegroundColor $color
}

# 按用户类型分组统计
Write-Host "`n👤 用户类型统计:" -ForegroundColor Yellow
$userStats = @{}
foreach ($result in $testResults) {
    if (-not $userStats.ContainsKey($result.UserType)) {
        $userStats[$result.UserType] = @{ Total = 0; Passed = 0 }
    }
    $userStats[$result.UserType].Total++
    if ($result.Status -like "*PASS*") {
        $userStats[$result.UserType].Passed++
    }
}

foreach ($userType in $userStats.Keys | Sort-Object) {
    $stats = $userStats[$userType]
    $successRate = if ($stats.Total -gt 0) { [math]::Round(($stats.Passed / $stats.Total) * 100, 1) } else { 0 }
    Write-Host "  $userType`: $($stats.Passed)/$($stats.Total) ($successRate%)" -ForegroundColor Cyan
}

# 保存报告
$reportPath = "docs/PERMISSION_MATRIX_TEST_REPORT.md"
$reportContent = @"
# 权限矩阵测试报告

**测试时间**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**测试总数**: $totalTests
**通过测试**: $passedTests
**失败测试**: $failedTests
**成功率**: $([math]::Round(($passedTests / $totalTests) * 100, 2))%

## 测试结果详情

| 权限 | 用户类型 | 状态 | HTTP状态码 | 方法 | URL |
|------|----------|------|------------|------|-----|
"@

foreach ($result in $testResults | Sort-Object Permission, UserType) {
    $reportContent += "| $($result.Permission) | $($result.UserType) | $($result.Status) | $($result.StatusCode) | $($result.Method) | $($result.Url) |`n"
}

$reportContent += @"

## 用户类型统计

| 用户类型 | 通过/总数 | 成功率 |
|----------|-----------|--------|
"@

foreach ($userType in $userStats.Keys | Sort-Object) {
    $stats = $userStats[$userType]
    $successRate = if ($stats.Total -gt 0) { [math]::Round(($stats.Passed / $stats.Total) * 100, 1) } else { 0 }
    $reportContent += "| $userType | $($stats.Passed)/$($stats.Total) | $successRate% |`n"
}

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "`n📄 详细报告已保存到: $reportPath" -ForegroundColor Cyan

if ($failedTests -eq 0) {
    Write-Host "`n🎉 所有权限矩阵测试通过！" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️ 有 $failedTests 个测试失败，请检查权限配置。" -ForegroundColor Yellow
    exit 1
}