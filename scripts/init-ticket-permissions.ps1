# 工单权限初始化脚本
# 初始化工单管理相关权限

$baseUrl = "http://localhost:8080/api/v1"
$headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== 工单权限初始化 ===" -ForegroundColor Green

# 1. 登录获取管理员Token
Write-Host "1. 管理员登录..." -ForegroundColor Yellow
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -Headers $headers
    $token = $loginResponse.token
    $headers["Authorization"] = "Bearer $token"
    Write-Host "✓ 管理员登录成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 管理员登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. 创建工单权限
Write-Host "2. 创建工单权限..." -ForegroundColor Yellow

$ticketPermissions = @(
    @{
        name = "ticket:view"
        display_name = "查看工单"
        description = "查看工单列表和详情"
        resource = "ticket"
        action = "view"
        scope = "all"
    },
    @{
        name = "ticket:create"
        display_name = "创建工单"
        description = "创建新工单"
        resource = "ticket"
        action = "create"
        scope = "all"
    },
    @{
        name = "ticket:edit"
        display_name = "编辑工单"
        description = "编辑工单信息"
        resource = "ticket"
        action = "edit"
        scope = "own"
    },
    @{
        name = "ticket:delete"
        display_name = "删除工单"
        description = "删除工单"
        resource = "ticket"
        action = "delete"
        scope = "own"
    },
    @{
        name = "ticket:view_all"
        display_name = "查看所有工单"
        description = "查看所有用户的工单"
        resource = "ticket"
        action = "view"
        scope = "all"
    },
    @{
        name = "ticket:edit_all"
        display_name = "编辑所有工单"
        description = "编辑所有用户的工单"
        resource = "ticket"
        action = "edit"
        scope = "all"
    },
    @{
        name = "ticket:assign"
        display_name = "分配工单"
        description = "分配工单给其他用户"
        resource = "ticket"
        action = "assign"
        scope = "all"
    },
    @{
        name = "ticket:status_all"
        display_name = "更新所有工单状态"
        description = "更新任何工单的状态"
        resource = "ticket"
        action = "status"
        scope = "all"
    },
    @{
        name = "ticket:comment"
        display_name = "添加工单评论"
        description = "在工单中添加评论"
        resource = "ticket"
        action = "comment"
        scope = "all"
    },
    @{
        name = "ticket:attachment_upload"
        display_name = "上传工单附件"
        description = "上传工单附件"
        resource = "ticket"
        action = "attachment_upload"
        scope = "all"
    },
    @{
        name = "ticket:delete_attachment"
        display_name = "删除工单附件"
        description = "删除工单附件"
        resource = "ticket"
        action = "delete_attachment"
        scope = "all"
    },
    @{
        name = "ticket:statistics"
        display_name = "查看工单统计"
        description = "查看工单统计数据"
        resource = "ticket"
        action = "statistics"
        scope = "all"
    }
)

$createdCount = 0
$skippedCount = 0

foreach ($permission in $ticketPermissions) {
    try {
        $permissionData = $permission | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "$baseUrl/permissions" -Method POST -Body $permissionData -Headers $headers
        Write-Host "  ✓ 创建权限: $($permission.name)" -ForegroundColor Green
        $createdCount++
    } catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-Host "  - 权限已存在: $($permission.name)" -ForegroundColor Yellow
            $skippedCount++
        } else {
            Write-Host "  ✗ 创建权限失败: $($permission.name) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "权限创建完成: 新建 $createdCount 个，跳过 $skippedCount 个" -ForegroundColor Cyan

# 3. 获取角色列表
Write-Host "3. 获取角色列表..." -ForegroundColor Yellow
try {
    $rolesResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method GET -Headers $headers
    $roles = $rolesResponse.roles
    Write-Host "✓ 获取到 $($roles.Count) 个角色" -ForegroundColor Green
} catch {
    Write-Host "✗ 获取角色列表失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 4. 为管理员角色分配所有工单权限
Write-Host "4. 为管理员角色分配工单权限..." -ForegroundColor Yellow
$adminRole = $roles | Where-Object { $_.name -eq "admin" }
if ($adminRole) {
    try {
        # 获取所有工单权限
        $permissionsResponse = Invoke-RestMethod -Uri "$baseUrl/permissions" -Method GET -Headers $headers
        $allPermissions = $permissionsResponse.permissions
        $ticketPermissionIds = ($allPermissions | Where-Object { $_.name -like "ticket:*" }).id
        
        $assignData = @{
            permission_ids = $ticketPermissionIds
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$baseUrl/admin/roles/$($adminRole.id)/permissions" -Method PUT -Body $assignData -Headers $headers
        Write-Host "✓ 管理员角色权限分配成功" -ForegroundColor Green
    } catch {
        Write-Host "✗ 管理员角色权限分配失败: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "✗ 未找到管理员角色" -ForegroundColor Red
}

# 5. 为普通用户角色分配基础工单权限
Write-Host "5. 为普通用户角色分配基础工单权限..." -ForegroundColor Yellow
$userRole = $roles | Where-Object { $_.name -eq "user" }
if ($userRole) {
    try {
        # 获取基础工单权限
        $permissionsResponse = Invoke-RestMethod -Uri "$baseUrl/permissions" -Method GET -Headers $headers
        $allPermissions = $permissionsResponse.permissions
        $basicPermissions = @(
            "ticket:view",
            "ticket:create", 
            "ticket:edit",
            "ticket:comment",
            "ticket:attachment_upload"
        )
        $basicPermissionIds = ($allPermissions | Where-Object { $basicPermissions -contains $_.name }).id
        
        $assignData = @{
            permission_ids = $basicPermissionIds
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$baseUrl/admin/roles/$($userRole.id)/permissions" -Method POST -Body $assignData -Headers $headers
        Write-Host "✓ 普通用户角色权限分配成功" -ForegroundColor Green
    } catch {
        Write-Host "✗ 普通用户角色权限分配失败: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "✗ 未找到普通用户角色" -ForegroundColor Red
}

# 6. 验证权限创建
Write-Host "6. 验证权限创建..." -ForegroundColor Yellow
try {
    $permissionsResponse = Invoke-RestMethod -Uri "$baseUrl/permissions" -Method GET -Headers $headers
    $allPermissions = $permissionsResponse.permissions
    $ticketPermissions = $allPermissions | Where-Object { $_.name -like "ticket:*" }
    
    Write-Host "✓ 工单权限验证完成" -ForegroundColor Green
    Write-Host "  总权限数: $($allPermissions.Count)" -ForegroundColor Cyan
    Write-Host "  工单权限数: $($ticketPermissions.Count)" -ForegroundColor Cyan
    
    Write-Host "  工单权限列表:" -ForegroundColor Cyan
    foreach ($perm in $ticketPermissions) {
        Write-Host "    - $($perm.name): $($perm.display_name)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ 权限验证失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== 工单权限初始化完成 ===" -ForegroundColor Green
Write-Host "现在可以使用工单管理功能了！" -ForegroundColor Yellow