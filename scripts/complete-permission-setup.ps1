# 完整权限系统设置脚本

Write-Host "=== 完整权限系统设置 ===" -ForegroundColor Green

# API基础URL
$baseUrl = "http://localhost:8080/api/v1"

# 获取管理员token
Write-Host "1. 登录获取管理员token..." -ForegroundColor Yellow
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $adminToken = $loginResponse.data.token
    Write-Host "   登录成功" -ForegroundColor Green
} catch {
    Write-Host "   登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

# 初始化简化权限
Write-Host "2. 初始化简化权限..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/permissions/initialize-simplified" -Method POST -Headers $headers
    Write-Host "   权限初始化完成" -ForegroundColor Green
} catch {
    Write-Host "   权限初始化失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 获取所有权限
Write-Host "3. 获取权限列表..." -ForegroundColor Yellow
try {
    $permissionsResponse = Invoke-RestMethod -Uri "$baseUrl/permissions" -Method GET -Headers $headers
    $permissions = $permissionsResponse.data
    Write-Host "   获取到 $($permissions.Count) 个权限" -ForegroundColor Green
} catch {
    Write-Host "   获取权限失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 创建标准角色
Write-Host "4. 创建标准角色..." -ForegroundColor Yellow

# 工单申请人角色
$ticketUserRole = @{
    name = "工单申请人"
    display_name = "工单申请人"
    description = "可以创建和查看自己工单的普通用户"
    is_system = $false
} | ConvertTo-Json

try {
    $roleResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method POST -Headers $headers -Body $ticketUserRole
    $ticketUserRoleId = $roleResponse.data.id
    Write-Host "   创建工单申请人角色成功 (ID: $ticketUserRoleId)" -ForegroundColor Green
    
    # 为工单申请人分配权限
    $ticketUserPermissions = $permissions | Where-Object { 
        $_.name -in @(
            "ticket:read_own", "ticket:create", "ticket:update_own", "ticket:delete_own",
            "ticket:comment_read", "ticket:comment_write", "ticket:attachment_upload",
            "ticket:statistics", "files:read", "files:upload", "files:download"
        )
    } | ForEach-Object { $_.id }
    
    if ($ticketUserPermissions.Count -gt 0) {
        $assignPermissions = @{
            permission_ids = $ticketUserPermissions
        } | ConvertTo-Json
        
        try {
            Invoke-RestMethod -Uri "$baseUrl/admin/roles/$ticketUserRoleId/permissions" -Method PUT -Headers $headers -Body $assignPermissions
            Write-Host "   为工单申请人分配 $($ticketUserPermissions.Count) 个权限成功" -ForegroundColor Green
        } catch {
            Write-Host "   为工单申请人分配权限失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "   未找到工单申请人相关权限" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "   创建工单申请人角色失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 工单管理员角色
$ticketAdminRole = @{
    name = "工单管理员"
    display_name = "工单管理员"
    description = "负责工单系统管理的管理员"
    is_system = $false
} | ConvertTo-Json

try {
    $roleResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method POST -Headers $headers -Body $ticketAdminRole
    $ticketAdminRoleId = $roleResponse.data.id
    Write-Host "   创建工单管理员角色成功 (ID: $ticketAdminRoleId)" -ForegroundColor Green
    
    # 为工单管理员分配权限
    $ticketAdminPermissions = $permissions | Where-Object { 
        $_.resource -eq "ticket" -or 
        ($_.resource -eq "users" -and $_.action -eq "read") -or
        ($_.resource -eq "files" -and $_.action -in @("read", "upload", "download", "delete"))
    } | ForEach-Object { $_.id }
    
    if ($ticketAdminPermissions.Count -gt 0) {
        $assignPermissions = @{
            permission_ids = $ticketAdminPermissions
        } | ConvertTo-Json
        
        try {
            Invoke-RestMethod -Uri "$baseUrl/admin/roles/$ticketAdminRoleId/permissions" -Method PUT -Headers $headers -Body $assignPermissions
            Write-Host "   为工单管理员分配 $($ticketAdminPermissions.Count) 个权限成功" -ForegroundColor Green
        } catch {
            Write-Host "   为工单管理员分配权限失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "   创建工单管理员角色失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 记录管理员角色
$recordAdminRole = @{
    name = "记录管理员"
    display_name = "记录管理员"
    description = "负责记录管理的用户"
    is_system = $false
} | ConvertTo-Json

try {
    $roleResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method POST -Headers $headers -Body $recordAdminRole
    $recordAdminRoleId = $roleResponse.data.id
    Write-Host "   创建记录管理员角色成功 (ID: $recordAdminRoleId)" -ForegroundColor Green
    
    # 为记录管理员分配权限
    $recordAdminPermissions = $permissions | Where-Object { 
        $_.resource -in @("records", "record_types", "files", "export")
    } | ForEach-Object { $_.id }
    
    if ($recordAdminPermissions.Count -gt 0) {
        $assignPermissions = @{
            permission_ids = $recordAdminPermissions
        } | ConvertTo-Json
        
        try {
            Invoke-RestMethod -Uri "$baseUrl/admin/roles/$recordAdminRoleId/permissions" -Method PUT -Headers $headers -Body $assignPermissions
            Write-Host "   为记录管理员分配 $($recordAdminPermissions.Count) 个权限成功" -ForegroundColor Green
        } catch {
            Write-Host "   为记录管理员分配权限失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "   创建记录管理员角色失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "5. 显示权限分配结果..." -ForegroundColor Yellow

# 显示工单相关权限
$ticketPermissions = $permissions | Where-Object { $_.resource -eq "ticket" }
Write-Host "   工单相关权限 ($($ticketPermissions.Count) 个):" -ForegroundColor Cyan
foreach ($perm in $ticketPermissions) {
    Write-Host "     - $($perm.name): $($perm.display_name)" -ForegroundColor White
}

Write-Host ""
Write-Host "=== 权限系统设置完成 ===" -ForegroundColor Green
Write-Host ""
Write-Host "创建的角色:" -ForegroundColor Cyan
Write-Host "  - 工单申请人: 可以创建和管理自己的工单" -ForegroundColor White
Write-Host "  - 工单管理员: 可以管理所有工单" -ForegroundColor White
Write-Host "  - 记录管理员: 可以管理记录和文件" -ForegroundColor White