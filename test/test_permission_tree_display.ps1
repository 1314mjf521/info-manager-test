# 权限树显示测试脚本
$BaseUrl = "http://localhost:8080"

Write-Host "=== 权限树显示测试 ===" -ForegroundColor Green

# 登录获取token
$loginData = '{"username":"admin","password":"admin123"}'
try {
    $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.success) {
        Write-Host "✓ 登录成功" -ForegroundColor Green
        $token = $loginResponse.data.token
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
    } else {
        Write-Host "✗ 登录失败" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ 登录请求失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 获取权限树数据
Write-Host "1. 获取权限树数据..." -ForegroundColor Yellow
try {
    $treeResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions/tree" -Method GET -Headers $headers
    
    if ($treeResponse.success) {
        Write-Host "✓ 权限树获取成功" -ForegroundColor Green
        $permissions = $treeResponse.data
        
        Write-Host "权限数据分析:" -ForegroundColor Cyan
        Write-Host "- 总权限数量: $($permissions.Count)" -ForegroundColor White
        
        # 分析权限数据完整性
        $hasDisplayName = 0
        $hasDescription = 0
        $hasParentId = 0
        $resourceGroups = @{}
        
        foreach ($perm in $permissions) {
            if ($perm.displayName -and $perm.displayName.Trim() -ne "") { $hasDisplayName++ }
            if ($perm.description -and $perm.description.Trim() -ne "") { $hasDescription++ }
            if ($perm.parentId) { $hasParentId++ }
            
            $resource = $perm.resource
            if (-not $resourceGroups.ContainsKey($resource)) {
                $resourceGroups[$resource] = @()
            }
            $resourceGroups[$resource] += $perm
        }
        
        Write-Host "- 有显示名称的权限: $hasDisplayName/$($permissions.Count)" -ForegroundColor White
        Write-Host "- 有描述的权限: $hasDescription/$($permissions.Count)" -ForegroundColor White
        Write-Host "- 有父级关系的权限: $hasParentId/$($permissions.Count)" -ForegroundColor White
        
        Write-Host "资源分组:" -ForegroundColor Cyan
        foreach ($resource in $resourceGroups.Keys) {
            $count = $resourceGroups[$resource].Count
            Write-Host "- $resource : $count 个权限" -ForegroundColor White
        }
        
        # 显示权限详情
        Write-Host "权限详情:" -ForegroundColor Cyan
        foreach ($perm in $permissions) {
            $displayName = if ($perm.displayName) { $perm.displayName } else { "无显示名称" }
            $description = if ($perm.description) { $perm.description } else { "无描述" }
            $parentInfo = if ($perm.parentId) { "父级:$($perm.parentId)" } else { "根节点" }
            
            Write-Host "  [$($perm.id)] $displayName ($($perm.resource):$($perm.action):$($perm.scope)) - $parentInfo" -ForegroundColor White
        }
        
    } else {
        Write-Host "✗ 权限树获取失败: $($treeResponse.error.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 权限树请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== 建议的权限树结构 ===" -ForegroundColor Green
Write-Host "系统管理" -ForegroundColor Yellow
Write-Host "├── 系统管理员 (system:admin)" -ForegroundColor White
Write-Host "└── 系统配置 (system:config)" -ForegroundColor White
Write-Host ""
Write-Host "用户管理" -ForegroundColor Yellow  
Write-Host "├── 查看用户 (users:read)" -ForegroundColor White
Write-Host "├── 编辑用户 (users:write)" -ForegroundColor White
Write-Host "└── 删除用户 (users:delete)" -ForegroundColor White
Write-Host ""
Write-Host "角色管理" -ForegroundColor Yellow
Write-Host "├── 查看角色 (roles:read)" -ForegroundColor White
Write-Host "├── 编辑角色 (roles:write)" -ForegroundColor White
Write-Host "├── 删除角色 (roles:delete)" -ForegroundColor White
Write-Host "└── 分配权限 (roles:assign)" -ForegroundColor White
Write-Host ""
Write-Host "记录管理" -ForegroundColor Yellow
Write-Host "├── 查看记录 (records:read)" -ForegroundColor White
Write-Host "├── 查看自己的记录 (records:read:own)" -ForegroundColor White
Write-Host "├── 编辑记录 (records:write)" -ForegroundColor White
Write-Host "├── 编辑自己的记录 (records:write:own)" -ForegroundColor White
Write-Host "├── 删除记录 (records:delete)" -ForegroundColor White
Write-Host "└── 删除自己的记录 (records:delete:own)" -ForegroundColor White
Write-Host ""
Write-Host "文件管理" -ForegroundColor Yellow
Write-Host "├── 查看文件 (files:read)" -ForegroundColor White
Write-Host "├── 上传文件 (files:upload)" -ForegroundColor White
Write-Host "├── 编辑文件 (files:write)" -ForegroundColor White
Write-Host "├── 删除文件 (files:delete)" -ForegroundColor White
Write-Host "└── 分享文件 (files:share)" -ForegroundColor White

Write-Host ""
Write-Host "=== 测试完成 ===" -ForegroundColor Green