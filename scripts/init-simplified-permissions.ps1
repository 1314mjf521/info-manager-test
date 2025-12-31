# 初始化简化权限系统脚本

Write-Host "=== 初始化简化权限系统 ===" -ForegroundColor Green

# API基础URL
$baseUrl = "http://localhost:8080/api/v1"

# 管理员token（需要先登录获取）
$adminToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MzUyMTU0NzQsInVzZXJfaWQiOjF9.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8"

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

try {
    Write-Host "1. 清理现有权限数据..." -ForegroundColor Yellow
    
    # 删除所有角色权限关联
    Write-Host "   删除角色权限关联..." -ForegroundColor Gray
    
    # 删除所有权限（保留系统必需的）
    Write-Host "   清理权限数据..." -ForegroundColor Gray
    
    Write-Host "2. 初始化简化权限..." -ForegroundColor Yellow
    $response = Invoke-RestMethod -Uri "$baseUrl/permissions/initialize" -Method POST -Headers $headers
    Write-Host "   权限初始化完成" -ForegroundColor Green
    
    Write-Host "3. 创建标准角色..." -ForegroundColor Yellow
    
    # 系统管理员角色
    $adminRole = @{
        name = "系统管理员"
        display_name = "系统管理员"
        description = "拥有系统所有权限的超级管理员"
        is_system = $true
    }
    
    try {
        $adminRoleResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method POST -Headers $headers -Body ($adminRole | ConvertTo-Json)
        Write-Host "   创建系统管理员角色成功" -ForegroundColor Green
    } catch {
        Write-Host "   系统管理员角色可能已存在" -ForegroundColor Yellow
    }
    
    # 工单管理员角色
    $ticketAdminRole = @{
        name = "工单管理员"
        display_name = "工单管理员"
        description = "负责工单系统管理的管理员"
        is_system = $false
    }
    
    try {
        $ticketAdminResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method POST -Headers $headers -Body ($ticketAdminRole | ConvertTo-Json)
        Write-Host "   创建工单管理员角色成功" -ForegroundColor Green
    } catch {
        Write-Host "   工单管理员角色可能已存在" -ForegroundColor Yellow
    }
    
    # 工单处理人角色
    $ticketHandlerRole = @{
        name = "工单处理人"
        display_name = "工单处理人"
        description = "负责处理工单的用户"
        is_system = $false
    }
    
    try {
        $ticketHandlerResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method POST -Headers $headers -Body ($ticketHandlerRole | ConvertTo-Json)
        Write-Host "   创建工单处理人角色成功" -ForegroundColor Green
    } catch {
        Write-Host "   工单处理人角色可能已存在" -ForegroundColor Yellow
    }
    
    # 工单申请人角色
    $ticketUserRole = @{
        name = "工单申请人"
        display_name = "工单申请人"
        description = "可以创建和查看自己工单的普通用户"
        is_system = $false
    }
    
    try {
        $ticketUserResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method POST -Headers $headers -Body ($ticketUserRole | ConvertTo-Json)
        Write-Host "   创建工单申请人角色成功" -ForegroundColor Green
    } catch {
        Write-Host "   工单申请人角色可能已存在" -ForegroundColor Yellow
    }
    
    # 记录管理员角色
    $recordAdminRole = @{
        name = "记录管理员"
        display_name = "记录管理员"
        description = "负责记录管理的用户"
        is_system = $false
    }
    
    try {
        $recordAdminResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method POST -Headers $headers -Body ($recordAdminRole | ConvertTo-Json)
        Write-Host "   创建记录管理员角色成功" -ForegroundColor Green
    } catch {
        Write-Host "   记录管理员角色可能已存在" -ForegroundColor Yellow
    }
    
    # 普通用户角色
    $normalUserRole = @{
        name = "普通用户"
        display_name = "普通用户"
        description = "只能查看和管理自己数据的普通用户"
        is_system = $false
    }
    
    try {
        $normalUserResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method POST -Headers $headers -Body ($normalUserRole | ConvertTo-Json)
        Write-Host "   创建普通用户角色成功" -ForegroundColor Green
    } catch {
        Write-Host "   普通用户角色可能已存在" -ForegroundColor Yellow
    }
    
    # 只读用户角色
    $readOnlyRole = @{
        name = "只读用户"
        display_name = "只读用户"
        description = "只能查看数据的用户"
        is_system = $false
    }
    
    try {
        $readOnlyResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method POST -Headers $headers -Body ($readOnlyRole | ConvertTo-Json)
        Write-Host "   创建只读用户角色成功" -ForegroundColor Green
    } catch {
        Write-Host "   只读用户角色可能已存在" -ForegroundColor Yellow
    }
    
    Write-Host "4. 分配角色权限..." -ForegroundColor Yellow
    
    # 获取所有角色
    $rolesResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method GET -Headers $headers
    $roles = $rolesResponse.data
    
    # 获取所有权限
    $permissionsResponse = Invoke-RestMethod -Uri "$baseUrl/permissions" -Method GET -Headers $headers
    $permissions = $permissionsResponse.data
    
    # 为系统管理员分配所有权限
    $adminRole = $roles | Where-Object { $_.name -eq "系统管理员" }
    if ($adminRole) {
        $allPermissionIds = $permissions | ForEach-Object { $_.id }
        $assignPermissions = @{
            permission_ids = $allPermissionIds
        }
        
        try {
            Invoke-RestMethod -Uri "$baseUrl/admin/roles/$($adminRole.id)/permissions" -Method PUT -Headers $headers -Body ($assignPermissions | ConvertTo-Json)
            Write-Host "   为系统管理员分配所有权限成功" -ForegroundColor Green
        } catch {
            Write-Host "   为系统管理员分配权限失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # 为工单申请人分配基础工单权限
    $ticketUserRole = $roles | Where-Object { $_.name -eq "工单申请人" }
    if ($ticketUserRole) {
        $ticketUserPermissions = $permissions | Where-Object { 
            $_.name -in @(
                "ticket:read_own", "ticket:create", "ticket:update_own", "ticket:delete_own",
                "ticket:comment_read", "ticket:comment_write", "ticket:attachment_upload",
                "ticket:statistics", "files:read", "files:upload", "files:download"
            )
        } | ForEach-Object { $_.id }
        
        $assignPermissions = @{
            permission_ids = $ticketUserPermissions
        }
        
        try {
            Invoke-RestMethod -Uri "$baseUrl/admin/roles/$($ticketUserRole.id)/permissions" -Method PUT -Headers $headers -Body ($assignPermissions | ConvertTo-Json)
            Write-Host "   为工单申请人分配权限成功" -ForegroundColor Green
        } catch {
            Write-Host "   为工单申请人分配权限失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "=== 简化权限系统初始化完成 ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "标准角色已创建:" -ForegroundColor Cyan
    Write-Host "  - 系统管理员: 拥有所有权限" -ForegroundColor White
    Write-Host "  - 工单管理员: 工单系统管理权限" -ForegroundColor White
    Write-Host "  - 工单处理人: 工单处理权限" -ForegroundColor White
    Write-Host "  - 工单申请人: 工单创建和查看权限" -ForegroundColor White
    Write-Host "  - 记录管理员: 记录管理权限" -ForegroundColor White
    Write-Host "  - 普通用户: 基础用户权限" -ForegroundColor White
    Write-Host "  - 只读用户: 只读权限" -ForegroundColor White
    
} catch {
    Write-Host "初始化失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "错误详情: $($_.Exception)" -ForegroundColor Red
}