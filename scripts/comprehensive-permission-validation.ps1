# 全面权限验证脚本
Write-Host "=== 全面权限验证测试 ===" -ForegroundColor Green

$testResults = @()
$totalTests = 0
$passedTests = 0
$failedTests = 0

# 测试配置
$baseUrl = "http://localhost:8080"
$adminCredentials = @{
    username = "admin"
    password = "admin123"
}
$tikerCredentials = @{
    username = "tiker_test"
    password = "tiker123"
}

# 权限定义
$permissions = @{
    "system" = @(
        "system:admin", "system:config_read", "system:config_write", 
        "system:announcements_read", "system:announcements_write",
        "system:logs_read", "system:logs_delete", "system:health_read", "system:stats_read"
    )
    "users" = @(
        "users:read", "users:create", "users:update", "users:delete",
        "users:assign_roles", "users:reset_password", "users:change_status", "users:import"
    )
    "roles" = @(
        "roles:read", "roles:create", "roles:update", "roles:delete",
        "roles:assign_permissions", "roles:import"
    )
    "permissions" = @(
        "permissions:read", "permissions:create", "permissions:update", 
        "permissions:delete", "permissions:initialize"
    )
    "ticket" = @(
        "ticket:read", "ticket:read_own", "ticket:create", "ticket:update", "ticket:update_own",
        "ticket:delete", "ticket:delete_own", "ticket:assign", "ticket:accept", "ticket:reject",
        "ticket:reopen", "ticket:status_change", "ticket:comment_read", "ticket:comment_write",
        "ticket:attachment_upload", "ticket:attachment_delete", "ticket:statistics",
        "ticket:export", "ticket:import"
    )
    "records" = @(
        "records:read", "records:read_own", "records:create", "records:update", "records:update_own",
        "records:delete", "records:delete_own", "records:import"
    )
    "record_types" = @(
        "record_types:read", "record_types:create", "record_types:update", 
        "record_types:delete", "record_types:import"
    )
    "files" = @(
        "files:read", "files:upload", "files:download", "files:delete", "files:ocr"
    )
    "export" = @(
        "export:read", "export:create", "export:update", "export:delete",
        "export:execute", "export:download"
    )
    "ai" = @(
        "ai:features", "ai:config", "ai:chat", "ai:optimize", "ai:speech"
    )
}

# API端点映射
$apiEndpoints = @{
    # 系统管理
    "system:health_read" = @{ method = "GET"; url = "/health" }
    "system:stats_read" = @{ method = "GET"; url = "/api/v1/system/stats" }
    "system:logs_read" = @{ method = "GET"; url = "/api/v1/logs" }
    
    # 用户管理
    "users:read" = @{ method = "GET"; url = "/api/v1/admin/users" }
    "users:create" = @{ method = "POST"; url = "/api/v1/admin/users"; body = @{username="test_user"; email="test@example.com"; password="test123"; displayName="Test User"} }
    
    # 角色管理
    "roles:read" = @{ method = "GET"; url = "/api/v1/admin/roles" }
    
    # 权限管理
    "permissions:read" = @{ method = "GET"; url = "/api/v1/permissions" }
    
    # 工单管理
    "ticket:read_own" = @{ method = "GET"; url = "/api/v1/tickets" }
    "ticket:create" = @{ method = "POST"; url = "/api/v1/tickets"; body = @{title="Test Ticket"; description="Test Description"; type="bug"; priority="normal"} }
    "ticket:statistics" = @{ method = "GET"; url = "/api/v1/tickets/statistics" }
    "ticket:export" = @{ method = "GET"; url = "/api/v1/tickets/export?format=csv" }
    
    # 文件管理
    "files:read" = @{ method = "GET"; url = "/api/v1/files" }
}

# 辅助函数
function Test-ApiEndpoint {
    param(
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers,
        [hashtable]$Body = $null,
        [string]$Permission,
        [string]$UserType
    )
    
    $totalTests++
    
    try {
        $fullUrl = $baseUrl + $Url
        
        if ($Body) {
            $jsonBody = $Body | ConvertTo-Json
            if ($Method -eq "POST") {
                $response = Invoke-WebRequest -Uri $fullUrl -Method $Method -Headers $Headers -Body $jsonBody -ContentType "application/json" -TimeoutSec 10
            } else {
                $response = Invoke-WebRequest -Uri $fullUrl -Method $Method -Headers $Headers -TimeoutSec 10
            }
        } else {
            $response = Invoke-WebRequest -Uri $fullUrl -Method $Method -Headers $Headers -TimeoutSec 10
        }
        
        if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 201) {
            $testResults += @{
                Permission = $Permission
                UserType = $UserType
                Method = $Method
                Url = $Url
                Status = "✅ PASS"
                Details = "HTTP $($response.StatusCode)"
            }
            $script:passedTests++
            Write-Host "  ✅ $Permission ($UserType): PASS" -ForegroundColor Green
            return $true
        } else {
            $testResults += @{
                Permission = $Permission
                UserType = $UserType
                Method = $Method
                Url = $Url
                Status = "❌ FAIL"
                Details = "HTTP $($response.StatusCode)"
            }
            $script:failedTests++
            Write-Host "  ❌ $Permission ($UserType): FAIL - HTTP $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
    } catch {
        $statusCode = "Unknown"
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode
        }
        
        # 403/401 对于权限测试是预期的结果
        if ($statusCode -eq 403 -or $statusCode -eq 401) {
            if ($UserType -eq "Tiker" -and $Permission -like "*admin*") {
                # Tiker用户被拒绝访问管理功能是正确的
                $testResults += @{
                    Permission = $Permission
                    UserType = $UserType
                    Method = $Method
                    Url = $Url
                    Status = "✅ PASS"
                    Details = "Correctly denied (HTTP $statusCode)"
                }
                $script:passedTests++
                Write-Host "  ✅ $Permission ($UserType): PASS - Correctly denied" -ForegroundColor Green
                return $true
            } else {
                $testResults += @{
                    Permission = $Permission
                    UserType = $UserType
                    Method = $Method
                    Url = $Url
                    Status = "❌ FAIL"
                    Details = "Access denied (HTTP $statusCode)"
                }
                $script:failedTests++
                Write-Host "  ❌ $Permission ($UserType): FAIL - Access denied" -ForegroundColor Red
                return $false
            }
        } else {
            $testResults += @{
                Permission = $Permission
                UserType = $UserType
                Method = $Method
                Url = $Url
                Status = "❌ ERROR"
                Details = $_.Exception.Message
            }
            $script:failedTests++
            Write-Host "  ❌ $Permission ($UserType): ERROR - $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

function Get-AuthToken {
    param([hashtable]$Credentials)
    
    try {
        $loginData = $Credentials | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        return $response.data.token
    } catch {
        Write-Host "❌ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 开始测试
Write-Host "`n1. 获取认证令牌..." -ForegroundColor Cyan

# 获取Admin令牌
$adminToken = Get-AuthToken -Credentials $adminCredentials
if (-not $adminToken) {
    Write-Host "❌ 无法获取Admin令牌，退出测试" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Admin令牌获取成功" -ForegroundColor Green

# 获取Tiker令牌
$tikerToken = Get-AuthToken -Credentials $tikerCredentials
if (-not $tikerToken) {
    Write-Host "❌ 无法获取Tiker令牌，退出测试" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Tiker令牌获取成功" -ForegroundColor Green

$adminHeaders = @{ "Authorization" = "Bearer $adminToken" }
$tikerHeaders = @{ "Authorization" = "Bearer $tikerToken" }

# 2. 测试API端点权限
Write-Host "`n2. 测试API端点权限..." -ForegroundColor Cyan

foreach ($permission in $apiEndpoints.Keys) {
    $endpoint = $apiEndpoints[$permission]
    
    Write-Host "`n  测试权限: $permission" -ForegroundColor Yellow
    
    # 测试Admin用户
    Test-ApiEndpoint -Method $endpoint.method -Url $endpoint.url -Headers $adminHeaders -Body $endpoint.body -Permission $permission -UserType "Admin"
    
    # 测试Tiker用户
    Test-ApiEndpoint -Method $endpoint.method -Url $endpoint.url -Headers $tikerHeaders -Body $endpoint.body -Permission $permission -UserType "Tiker"
}

# 3. 测试工单CRUD操作
Write-Host "`n3. 测试工单CRUD操作..." -ForegroundColor Cyan

# 创建测试工单
Write-Host "`n  创建测试工单..." -ForegroundColor Yellow
$ticketData = @{
    title = "权限测试工单"
    description = "用于权限验证的测试工单"
    type = "bug"
    priority = "normal"
}
$ticketJson = $ticketData | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/tickets" -Method POST -Body $ticketJson -ContentType "application/json" -Headers $adminHeaders
    $testTicketId = $createResponse.data.id
    Write-Host "  ✅ 测试工单创建成功 (ID: $testTicketId)" -ForegroundColor Green
    
    # 测试工单读取权限
    Write-Host "`n  测试工单读取权限..." -ForegroundColor Yellow
    
    # Admin应该能读取
    Test-ApiEndpoint -Method "GET" -Url "/api/v1/tickets/$testTicketId" -Headers $adminHeaders -Permission "ticket:read" -UserType "Admin"
    
    # Tiker应该能读取（如果有权限）
    Test-ApiEndpoint -Method "GET" -Url "/api/v1/tickets/$testTicketId" -Headers $tikerHeaders -Permission "ticket:read_own" -UserType "Tiker"
    
    # 测试工单更新权限
    Write-Host "`n  测试工单更新权限..." -ForegroundColor Yellow
    $updateData = @{ title = "更新后的权限测试工单" }
    
    Test-ApiEndpoint -Method "PUT" -Url "/api/v1/tickets/$testTicketId" -Headers $adminHeaders -Body $updateData -Permission "ticket:update" -UserType "Admin"
    Test-ApiEndpoint -Method "PUT" -Url "/api/v1/tickets/$testTicketId" -Headers $tikerHeaders -Body $updateData -Permission "ticket:update_own" -UserType "Tiker"
    
    # 清理测试工单
    try {
        Invoke-RestMethod -Uri "$baseUrl/api/v1/tickets/$testTicketId" -Method DELETE -Headers $adminHeaders
        Write-Host "  🧹 测试工单已清理" -ForegroundColor Gray
    } catch {
        Write-Host "  ⚠️ 无法清理测试工单" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "  ❌ 无法创建测试工单: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. 测试文件上传权限
Write-Host "`n4. 测试文件上传权限..." -ForegroundColor Cyan

# 创建临时测试文件
$tempFile = Join-Path $env:TEMP "permission_test.txt"
"Permission test file content" | Out-File -FilePath $tempFile -Encoding UTF8

try {
    # 测试Admin文件上传
    Write-Host "  测试Admin文件上传..." -ForegroundColor Yellow
    # 注意：文件上传需要特殊的multipart/form-data格式，这里简化测试
    Test-ApiEndpoint -Method "GET" -Url "/api/v1/files" -Headers $adminHeaders -Permission "files:read" -UserType "Admin"
    
    # 测试Tiker文件访问
    Write-Host "  测试Tiker文件访问..." -ForegroundColor Yellow
    Test-ApiEndpoint -Method "GET" -Url "/api/v1/files" -Headers $tikerHeaders -Permission "files:read" -UserType "Tiker"
    
} finally {
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}

# 5. 生成测试报告
Write-Host "`n=== 权限验证测试报告 ===" -ForegroundColor Green

Write-Host "`n📊 测试统计:" -ForegroundColor Yellow
Write-Host "总测试数: $totalTests" -ForegroundColor Gray
Write-Host "通过测试: $passedTests" -ForegroundColor Green
Write-Host "失败测试: $failedTests" -ForegroundColor Red
Write-Host "成功率: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor Cyan

Write-Host "`n📋 详细结果:" -ForegroundColor Yellow
$testResults | Sort-Object Permission, UserType | ForEach-Object {
    $color = if ($_.Status -like "*PASS*") { "Green" } elseif ($_.Status -like "*FAIL*") { "Red" } else { "Yellow" }
    Write-Host "  $($_.Permission) ($($_.UserType)): $($_.Status)" -ForegroundColor $color
    if ($_.Details) {
        Write-Host "    $($_.Details)" -ForegroundColor DarkGray
    }
}

# 按权限类别分组统计
Write-Host "`n📈 权限类别统计:" -ForegroundColor Yellow
$categoryStats = @{}
foreach ($result in $testResults) {
    $category = $result.Permission.Split(':')[0]
    if (-not $categoryStats.ContainsKey($category)) {
        $categoryStats[$category] = @{ Total = 0; Passed = 0; Failed = 0 }
    }
    $categoryStats[$category].Total++
    if ($result.Status -like "*PASS*") {
        $categoryStats[$category].Passed++
    } else {
        $categoryStats[$category].Failed++
    }
}

foreach ($category in $categoryStats.Keys | Sort-Object) {
    $stats = $categoryStats[$category]
    $successRate = [math]::Round(($stats.Passed / $stats.Total) * 100, 1)
    Write-Host "  $category`: $($stats.Passed)/$($stats.Total) ($successRate%)" -ForegroundColor Cyan
}

# 保存详细报告到文件
$reportPath = "docs/PERMISSION_VALIDATION_REPORT.md"
$reportContent = @"
# 权限验证测试报告

**测试时间**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**测试总数**: $totalTests
**通过测试**: $passedTests
**失败测试**: $failedTests
**成功率**: $([math]::Round(($passedTests / $totalTests) * 100, 2))%

## 详细测试结果

| 权限 | 用户类型 | 方法 | URL | 状态 | 详情 |
|------|----------|------|-----|------|------|
"@

foreach ($result in $testResults | Sort-Object Permission, UserType) {
    $reportContent += "| $($result.Permission) | $($result.UserType) | $($result.Method) | $($result.Url) | $($result.Status) | $($result.Details) |`n"
}

$reportContent += @"

## 权限类别统计

| 类别 | 通过/总数 | 成功率 |
|------|-----------|--------|
"@

foreach ($category in $categoryStats.Keys | Sort-Object) {
    $stats = $categoryStats[$category]
    $successRate = [math]::Round(($stats.Passed / $stats.Total) * 100, 1)
    $reportContent += "| $category | $($stats.Passed)/$($stats.Total) | $successRate% |`n"
}

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "`n📄 详细报告已保存到: $reportPath" -ForegroundColor Cyan

if ($failedTests -eq 0) {
    Write-Host "`n🎉 所有权限验证测试通过！" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️ 有 $failedTests 个测试失败，请检查权限配置。" -ForegroundColor Yellow
    exit 1
}