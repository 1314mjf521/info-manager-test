# 直接初始化权限数据脚本（不依赖前端）
Write-Host "=== 直接初始化权限数据 ===" -ForegroundColor Green

Write-Host "此脚本将直接通过数据库初始化权限数据，不需要前端运行" -ForegroundColor Yellow

# 检查MySQL命令
$mysqlPath = Get-Command mysql -ErrorAction SilentlyContinue
if (-not $mysqlPath) {
    Write-Host "✗ 未找到MySQL命令" -ForegroundColor Red
    Write-Host "请确保MySQL已安装并添加到系统PATH" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n步骤1: 测试数据库连接" -ForegroundColor Cyan
try {
    $testResult = cmd /c "mysql -u root -p123456 -e `"SELECT 1;`" 2>&1"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 数据库连接成功" -ForegroundColor Green
    } else {
        Write-Host "✗ 数据库连接失败" -ForegroundColor Red
        Write-Host "错误: $testResult" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ 数据库连接测试失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n步骤2: 检查数据库是否存在" -ForegroundColor Cyan
try {
    $dbCheck = cmd /c "mysql -u root -p123456 -e `"SHOW DATABASES LIKE 'info_manager';`" 2>&1"
    if ($dbCheck -match "info_manager") {
        Write-Host "✓ 数据库 info_manager 存在" -ForegroundColor Green
    } else {
        Write-Host "✗ 数据库 info_manager 不存在" -ForegroundColor Red
        Write-Host "请先创建数据库或运行完整的初始化脚本" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "✗ 检查数据库失败" -ForegroundColor Red
    exit 1
}

Write-Host "`n步骤3: 初始化工单权限" -ForegroundColor Cyan
if (Test-Path "scripts/init-ticket-permissions.sql") {
    try {
        Write-Host "正在执行工单权限初始化..." -ForegroundColor White
        $result = cmd /c "mysql -u root -p123456 info_manager < scripts/init-ticket-permissions.sql 2>&1"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ 工单权限初始化成功" -ForegroundColor Green
        } else {
            Write-Host "✗ 工单权限初始化失败" -ForegroundColor Red
            Write-Host "错误: $result" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 执行SQL脚本失败: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "✗ 找不到工单权限初始化脚本" -ForegroundColor Red
    Write-Host "请确保 scripts/init-ticket-permissions.sql 文件存在" -ForegroundColor Yellow
}

Write-Host "`n步骤4: 验证权限数据" -ForegroundColor Cyan
try {
    Write-Host "检查权限表中的数据..." -ForegroundColor White
    $permissionCount = cmd /c "mysql -u root -p123456 info_manager -e `"SELECT COUNT(*) as total FROM permissions;`" 2>&1"
    Write-Host "权限总数: $permissionCount" -ForegroundColor Gray
    
    $ticketPermissionCount = cmd /c "mysql -u root -p123456 info_manager -e `"SELECT COUNT(*) as ticket_count FROM permissions WHERE resource = 'ticket';`" 2>&1"
    Write-Host "工单权限数: $ticketPermissionCount" -ForegroundColor Gray
    
    Write-Host "✓ 权限数据验证完成" -ForegroundColor Green
} catch {
    Write-Host "✗ 验证权限数据失败" -ForegroundColor Red
}

Write-Host "`n步骤5: 显示工单权限列表" -ForegroundColor Cyan
try {
    Write-Host "工单权限列表:" -ForegroundColor White
    $ticketPermissions = cmd /c "mysql -u root -p123456 info_manager -e `"SELECT id, name, display_name FROM permissions WHERE resource = 'ticket' ORDER BY id;`" 2>&1"
    Write-Host $ticketPermissions -ForegroundColor Gray
} catch {
    Write-Host "✗ 获取工单权限列表失败" -ForegroundColor Red
}

Write-Host "`n=== 初始化完成 ===" -ForegroundColor Green
Write-Host "现在可以：" -ForegroundColor Yellow
Write-Host "1. 重启后端服务" -ForegroundColor White
Write-Host "2. 修复前端语法错误后重启前端" -ForegroundColor White
Write-Host "3. 测试权限分配功能" -ForegroundColor White

Write-Host "`n前端语法错误修复建议：" -ForegroundColor Cyan
Write-Host "检查 frontend/src/views/admin/RoleManagement.vue 文件" -ForegroundColor White
Write-Host "可能的问题：" -ForegroundColor White
Write-Host "- 缺少逗号或分号" -ForegroundColor White
Write-Host "- 括号不匹配" -ForegroundColor White
Write-Host "- 字符串引号不匹配" -ForegroundColor White