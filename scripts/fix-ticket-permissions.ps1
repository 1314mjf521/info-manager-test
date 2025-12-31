# 修复工单权限脚本
# 确保工单权限被正确创建和分配

$baseUrl = "http://localhost:8080/api/v1"
$headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== 修复工单权限 ===" -ForegroundColor Green

# 1. 登录获取管理员Token
Write-Host "1. 管理员登录..." -ForegroundColor Yellow
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -Headers $headers
    $token = $loginResponse.data.token
    $adminHeaders = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $token"
    }
    Write-Host "✓ 管理员登录成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 管理员登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. 检查现有权限
Write-Host "2. 检查现有权限..." -ForegroundColor Yellow
try {
    $permissionsResponse = Invoke-RestMethod -Uri "$baseUrl/permissions" -Method GET -Headers $adminHeaders
    $existingPermissions = $permissionsResponse.permissions
    Write-Host "✓ 获取到 $($existingPermissions.Count) 个权限" -ForegroundColor Green
    
    $ticketPermissions = $existingPermissions | Where-Object { $_.name -like "ticket*" }
    Write-Host "  现有工单权限: $($ticketPermissions.Count) 个" -ForegroundColor Cyan
    foreach ($perm in $ticketPermissions) {
        Write-Host "    - $($perm.name): $($perm.display_name)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ 获取权限失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. 创建缺失的工单权限
Write-Host "3. 创建缺失的工单权限..." -ForegroundColor Yellow

$requiredPermissions = @(
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
        name = "ticket:assign"
        display_name = "分配工单"
        description = "分配工单给其他用户"
        resource = "ticket"
        action = "assign"
        scope = "all"
    }
)

$createdCount = 0
foreach ($perm in $requiredPermissions) {
    $exists = $existingPermissions | Where-Object { $_.name -eq $perm.name }
    if (-not $exists) {
        try {
            $permData = $perm | ConvertTo-Json
            $response = Invoke-RestMethod -Uri "$baseUrl/permissions" -Method POST -Body $permData -Headers $adminHeaders
            Write-Host "  ✓ 创建权限: $($perm.name)" -ForegroundColor Green
            $createdCount++
        } catch {
            Write-Host "  ✗ 创建权限失败: $($perm.name) - $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  - 权限已存在: $($perm.name)" -ForegroundColor Gray
    }
}

Write-Host "权限创建完成: 新建 $createdCount 个" -ForegroundColor Cyan

# 4. 为管理员角色分配工单权限
Write-Host "4. 为管理员角色分配工单权限..." -ForegroundColor Yellow
try {
    $rolesResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles" -Method GET -Headers $adminHeaders
    $adminRole = $rolesResponse.roles | Where-Object { $_.name -eq "admin" }
    
    if ($adminRole) {
        # 获取所有权限
        $allPermissionsResponse = Invoke-RestMethod -Uri "$baseUrl/permissions" -Method GET -Headers $adminHeaders
        $allPermissions = $allPermissionsResponse.permissions
        $allPermissionIds = $allPermissions.id
        
        $assignData = @{
            permission_ids = $allPermissionIds
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$baseUrl/admin/roles/$($adminRole.id)/permissions" -Method PUT -Body $assignData -Headers $adminHeaders
        Write-Host "✓ 管理员角色权限分配成功" -ForegroundColor Green
    } else {
        Write-Host "✗ 未找到管理员角色" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 管理员角色权限分配失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. 测试工单API
Write-Host "5. 测试工单API..." -ForegroundColor Yellow
try {
    $ticketsResponse = Invoke-RestMethod -Uri "$baseUrl/tickets?page=1&size=5" -Method GET -Headers $adminHeaders
    Write-Host "✓ 工单API测试成功" -ForegroundColor Green
    Write-Host "  工单总数: $($ticketsResponse.total)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 工单API测试失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== 工单权限修复完成 ===" -ForegroundColor Green
Write-Host "请刷新前端页面查看工单管理菜单" -ForegroundColor Yellow