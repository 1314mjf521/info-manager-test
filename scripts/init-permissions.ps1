#!/usr/bin/env pwsh

Write-Host "=== 初始化优化权限树 ===" -ForegroundColor Green

# 检查数据库文件是否存在
$dbPath = "data/info_management.db"
if (-not (Test-Path $dbPath)) {
    Write-Host "错误: 数据库文件不存在 $dbPath" -ForegroundColor Red
    Write-Host "请先启动应用程序创建数据库" -ForegroundColor Yellow
    exit 1
}

# 备份数据库
$backupPath = "data/info_management_backup_permissions_$(Get-Date -Format 'yyyyMMdd_HHmmss').db"
Copy-Item $dbPath $backupPath
Write-Host "数据库已备份到: $backupPath" -ForegroundColor Blue

# 执行权限初始化SQL
Write-Host "正在初始化权限树..." -ForegroundColor Yellow

if (Get-Command sqlite3 -ErrorAction SilentlyContinue) {
    try {
        # 执行权限初始化脚本
        Get-Content "scripts/init-optimized-permissions.sql" | sqlite3 $dbPath
        Write-Host "✓ 权限树初始化完成" -ForegroundColor Green
        
        # 验证权限数量
        $permissionCount = sqlite3 $dbPath "SELECT COUNT(*) FROM permissions;"
        Write-Host "✓ 总权限数: $permissionCount" -ForegroundColor Blue
        
        # 验证根权限数量
        $rootPermissionCount = sqlite3 $dbPath "SELECT COUNT(*) FROM permissions WHERE parent_id IS NULL;"
        Write-Host "✓ 根权限数: $rootPermissionCount" -ForegroundColor Blue
        
        # 显示权限模块
        Write-Host "`n权限模块结构:" -ForegroundColor Yellow
        $modules = sqlite3 $dbPath "SELECT display_name, description FROM permissions WHERE parent_id IS NULL ORDER BY id;"
        $modules -split "`n" | ForEach-Object {
            if ($_ -match '(.+)\|(.+)') {
                Write-Host "  • $($matches[1]) - $($matches[2])" -ForegroundColor White
            }
        }
        
    } catch {
        Write-Host "✗ 权限初始化失败: $($_.Exception.Message)" -ForegroundColor Red
        
        # 恢复备份
        Write-Host "正在恢复数据库备份..." -ForegroundColor Yellow
        Copy-Item $backupPath $dbPath -Force
        Write-Host "数据库已恢复" -ForegroundColor Blue
        exit 1
    }
} else {
    Write-Host "错误: 未找到sqlite3命令" -ForegroundColor Red
    Write-Host "请安装SQLite3或手动执行SQL脚本" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=== 权限初始化完成 ===" -ForegroundColor Green
Write-Host "优化内容:" -ForegroundColor White
Write-Host "✓ 12个主要功能模块" -ForegroundColor Green
Write-Host "✓ 细化的权限粒度控制" -ForegroundColor Green
Write-Host "✓ 清晰的权限树结构" -ForegroundColor Green
Write-Host "✓ 完整的工单管理权限" -ForegroundColor Green

Write-Host "`n下一步:" -ForegroundColor Yellow
Write-Host "1. 重启应用程序以加载新权限" -ForegroundColor White
Write-Host "2. 在权限管理页面查看优化后的权限树" -ForegroundColor White
Write-Host "3. 为不同角色分配合适的权限" -ForegroundColor White
Write-Host "4. 测试各功能模块的权限控制" -ForegroundColor White