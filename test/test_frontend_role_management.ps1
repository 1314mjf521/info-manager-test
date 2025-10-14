# 前端角色管理界面测试脚本
param(
    [string]$BaseUrl = "http://localhost:8080"
)

Write-Host "=== 前端角色管理界面测试 ===" -ForegroundColor Green

# 测试API接口是否正常工作
Write-Host "1. 测试后端API接口..." -ForegroundColor Yellow

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

# 测试角色列表API
Write-Host "2. 测试角色列表API..." -ForegroundColor Yellow
try {
    $rolesResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles" -Method GET -Headers $headers
    
    if ($rolesResponse.success) {
        Write-Host "✓ 角色列表API正常" -ForegroundColor Green
        Write-Host "   角色数量: $($rolesResponse.data.Count)" -ForegroundColor Cyan
        
        # 检查字段完整性
        $firstRole = $rolesResponse.data[0]
        $requiredFields = @('id', 'name', 'displayName', 'status', 'permissions', 'userCount')
        $missingFields = @()
        
        foreach ($field in $requiredFields) {
            if (-not $firstRole.PSObject.Properties.Name -contains $field) {
                $missingFields += $field
            }
        }
        
        if ($missingFields.Count -eq 0) {
            Write-Host "✓ 角色数据字段完整" -ForegroundColor Green
        } else {
            Write-Host "✗ 缺少字段: $($missingFields -join ', ')" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ 角色列表API失败" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 角色列表API请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试权限树API
Write-Host "3. 测试权限树API..." -ForegroundColor Yellow
try {
    $treeResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions/tree" -Method GET -Headers $headers
    
    if ($treeResponse.success) {
        Write-Host "✓ 权限树API正常" -ForegroundColor Green
        Write-Host "   树节点数量: $($treeResponse.data.Count)" -ForegroundColor Cyan
        
        # 检查树结构
        $hasChildren = $false
        foreach ($node in $treeResponse.data) {
            if ($node.children -and $node.children.Count -gt 0) {
                $hasChildren = $true
                break
            }
        }
        
        if ($hasChildren) {
            Write-Host "✓ 权限树结构正确" -ForegroundColor Green
        } else {
            Write-Host "⚠ 权限树无子节点，可能是平面结构" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ 权限树API失败" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 权限树API请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试角色权限获取API
Write-Host "4. 测试角色权限API..." -ForegroundColor Yellow
try {
    # 获取第一个角色的权限
    $roleId = $rolesResponse.data[0].id
    $permissionsResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$roleId/permissions" -Method GET -Headers $headers
    
    if ($permissionsResponse.success) {
        Write-Host "✓ 角色权限API正常" -ForegroundColor Green
        Write-Host "   权限数量: $($permissionsResponse.data.Count)" -ForegroundColor Cyan
    } else {
        Write-Host "✗ 角色权限API失败" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 角色权限API请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试权限分配API
Write-Host "5. 测试权限分配API..." -ForegroundColor Yellow
try {
    # 创建测试角色
    $testRoleData = @{
        name = "test_frontend_role"
        displayName = "前端测试角色"
        description = "用于测试前端界面的角色"
        status = "active"
    }
    $testRoleJson = $testRoleData | ConvertTo-Json
    
    $createResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles" -Method POST -Body $testRoleJson -Headers $headers
    
    if ($createResponse.success) {
        $testRoleId = $createResponse.data.id
        Write-Host "✓ 测试角色创建成功 (ID: $testRoleId)" -ForegroundColor Green
        
        # 分配权限
        $permissionData = @{
            permissionIds = @(1, 2, 3)  # 分配前几个权限
        }
        $permissionJson = $permissionData | ConvertTo-Json
        
        $assignResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$testRoleId/permissions" -Method PUT -Body $permissionJson -Headers $headers
        
        if ($assignResponse.success) {
            Write-Host "✓ 权限分配API正常" -ForegroundColor Green
            Write-Host "   分配的权限数量: $($assignResponse.data.permissions.Count)" -ForegroundColor Cyan
        } else {
            Write-Host "✗ 权限分配API失败" -ForegroundColor Red
        }
        
        # 清理测试角色
        try {
            Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles/$testRoleId" -Method DELETE -Headers $headers | Out-Null
            Write-Host "✓ 测试角色已清理" -ForegroundColor Green
        } catch {
            Write-Host "⚠ 测试角色清理失败" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ 测试角色创建失败" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 权限分配API测试失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== 前端界面检查清单 ===" -ForegroundColor Green
Write-Host "请在浏览器中验证以下功能:" -ForegroundColor Yellow
Write-Host "□ 角色列表正确显示 (包含displayName和status字段)" -ForegroundColor White
Write-Host "□ 权限树正确展示层次结构" -ForegroundColor White
Write-Host "□ 权限树支持展开/折叠操作" -ForegroundColor White
Write-Host "□ 权限树支持全选/全不选操作" -ForegroundColor White
Write-Host "□ 权限分配对话框正常工作" -ForegroundColor White
Write-Host "□ 权限保存功能正常" -ForegroundColor White
Write-Host "□ 角色状态切换功能正常" -ForegroundColor White
Write-Host "□ 角色创建/编辑/删除功能正常" -ForegroundColor White

Write-Host ""
Write-Host "=== 测试完成 ===" -ForegroundColor Green
Write-Host "请访问: http://localhost:3000/admin/roles 查看前端界面" -ForegroundColor Cyan