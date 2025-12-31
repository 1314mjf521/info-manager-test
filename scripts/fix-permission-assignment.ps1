# 修复权限分配问题脚本
Write-Host "=== 修复权限分配问题 ===" -ForegroundColor Green

Write-Host "问题分析：" -ForegroundColor Yellow
Write-Host "  - 前端使用模拟权限数据（数字ID：1101, 1103等）" -ForegroundColor White
Write-Host "  - 数据库中实际权限使用字符串ID" -ForegroundColor White
Write-Host "  - 导致权限分配时找不到对应的权限记录" -ForegroundColor White

Write-Host "`n步骤1: 初始化工单权限到数据库" -ForegroundColor Cyan

# 检查是否存在MySQL命令
$mysqlPath = Get-Command mysql -ErrorAction SilentlyContinue
if (-not $mysqlPath) {
    Write-Host "✗ 未找到MySQL命令，请确保MySQL已安装并添加到PATH" -ForegroundColor Red
    Write-Host "请手动执行以下SQL脚本：" -ForegroundColor Yellow
    Write-Host "scripts/init-ticket-permissions.sql" -ForegroundColor White
    exit 1
}

Write-Host "正在初始化工单权限..." -ForegroundColor White

# 尝试执行SQL脚本
try {
    # 使用配置文件中的数据库信息
    $result = cmd /c "mysql -u root -p123456 info_manager < scripts/init-ticket-permissions.sql 2>&1"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 工单权限初始化成功" -ForegroundColor Green
    } else {
        Write-Host "✗ 工单权限初始化失败" -ForegroundColor Red
        Write-Host "错误信息: $result" -ForegroundColor Red
        Write-Host "请检查数据库连接配置" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ 执行SQL脚本时出错: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n步骤2: 验证权限数据" -ForegroundColor Cyan
Write-Host "检查工单权限是否已创建..." -ForegroundColor White

try {
    $checkResult = cmd /c "mysql -u root -p123456 info_manager -e `"SELECT COUNT(*) as count FROM permissions WHERE resource = 'ticket';`" 2>&1"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 权限数据检查完成" -ForegroundColor Green
        Write-Host "结果: $checkResult" -ForegroundColor Gray
    } else {
        Write-Host "✗ 权限数据检查失败" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 检查权限数据时出错" -ForegroundColor Red
}

Write-Host "`n步骤3: 重启服务建议" -ForegroundColor Cyan
Write-Host "建议重启后端服务以刷新权限缓存" -ForegroundColor White
Write-Host "如果使用 rebuild-and-start.bat，请重新运行该脚本" -ForegroundColor White

Write-Host "`n步骤4: 前端修复说明" -ForegroundColor Cyan
Write-Host "前端已修改为强制使用后端真实权限数据：" -ForegroundColor White
Write-Host "  - 移除了模拟权限数据的回退逻辑" -ForegroundColor White
Write-Host "  - 权限分配将使用数据库中的真实权限ID" -ForegroundColor White
Write-Host "  - 如果权限数据为空，会显示错误提示" -ForegroundColor White

Write-Host "`n步骤5: 测试权限分配" -ForegroundColor Cyan
Write-Host "1. 刷新浏览器页面" -ForegroundColor White
Write-Host "2. 访问角色管理页面" -ForegroundColor White
Write-Host "3. 点击角色的'权限'按钮" -ForegroundColor White
Write-Host "4. 如果看不到权限，点击'重新加载权限'按钮" -ForegroundColor White
Write-Host "5. 选择工单相关权限并保存" -ForegroundColor White

Write-Host "`n=== 修复完成 ===" -ForegroundColor Green
Write-Host "如果仍有问题，请检查：" -ForegroundColor Yellow
Write-Host "1. 数据库连接是否正常" -ForegroundColor White
Write-Host "2. 后端服务是否正常运行" -ForegroundColor White
Write-Host "3. 权限API是否返回正确数据" -ForegroundColor White