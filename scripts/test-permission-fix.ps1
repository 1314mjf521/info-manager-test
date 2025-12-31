# 测试权限修复结果

Write-Host "=== 测试权限修复结果 ===" -ForegroundColor Green

# 获取管理员token
$loginData = @{username="admin"; password="admin123"} | ConvertTo-Json
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
$adminToken = $loginResponse.data.token

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

Write-Host "1. 检查角色权限分配..." -ForegroundColor Yellow

# 检查工单申请人角色 (ID: 4)
$rolePermissions = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles/4/permissions" -Method GET -Headers $headers
$ticketPermissions = $rolePermissions.data | Where-Object { $_.resource -eq "ticket" }
Write-Host "   工单申请人角色有 $($ticketPermissions.Count) 个工单权限" -ForegroundColor Green

# 检查工单管理员角色 (ID: 5)
$rolePermissions = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/roles/5/permissions" -Method GET -Headers $headers
$ticketPermissions = $rolePermissions.data | Where-Object { $_.resource -eq "ticket" }
Write-Host "   工单管理员角色有 $($ticketPermissions.Count) 个工单权限" -ForegroundColor Green

Write-Host "2. 测试用户权限..." -ForegroundColor Yellow

# 创建测试用户
$testUser = @{
    username = "testuser"
    email = "test@example.com"
    password = "password123"
} | ConvertTo-Json

try {
    $userResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/users" -Method POST -Headers $headers -Body $testUser
    $testUserId = $userResponse.data.id
    Write-Host "   创建测试用户成功 (ID: $testUserId)" -ForegroundColor Green
    
    # 分配工单申请人角色
    $assignRole = @{role_ids = @(4)} | ConvertTo-Json
    Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/users/$testUserId/roles" -Method PUT -Headers $headers -Body $assignRole
    Write-Host "   分配工单申请人角色成功" -ForegroundColor Green
    
    # 测试用户登录
    $testLogin = @{username="testuser"; password="password123"} | ConvertTo-Json
    $testLoginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $testLogin -ContentType "application/json"
    $testToken = $testLoginResponse.data.token
    $testUser = $testLoginResponse.data.user
    
    Write-Host "   测试用户登录成功" -ForegroundColor Green
    Write-Host "   用户有 $($testUser.permissions.Count) 个权限" -ForegroundColor Green
    
    $testHeaders = @{
        "Authorization" = "Bearer $testToken"
        "Content-Type" = "application/json"
    }
    
    # 测试工单统计API
    try {
        $stats = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/statistics" -Method GET -Headers $testHeaders
        Write-Host "   工单统计API访问成功" -ForegroundColor Green
    } catch {
        Write-Host "   工单统计API访问失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 清理测试用户
    Invoke-RestMethod -Uri "http://localhost:8080/api/v1/admin/users/$testUserId" -Method DELETE -Headers $headers
    Write-Host "   清理测试用户完成" -ForegroundColor Green
    
} catch {
    Write-Host "   测试用户创建失败: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== 权限修复测试完成 ===" -ForegroundColor Green
Write-Host "现在工单申请人角色应该可以正常使用工单功能了！" -ForegroundColor Cyan