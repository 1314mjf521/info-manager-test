# 修复前端语法错误脚本
Write-Host "=== 修复前端语法错误 ===" -ForegroundColor Green

Write-Host "检测到的语法错误：" -ForegroundColor Yellow
Write-Host "  文件: frontend/src/views/admin/RoleManagement.vue" -ForegroundColor White
Write-Host "  行号: 2505" -ForegroundColor White
Write-Host "  错误: Unexpected token" -ForegroundColor White

Write-Host "`n可能的解决方案：" -ForegroundColor Cyan

Write-Host "`n1. 临时禁用语法检查" -ForegroundColor Yellow
Write-Host "在 vite.config.ts 中添加：" -ForegroundColor White
Write-Host "server: { hmr: { overlay: false } }" -ForegroundColor Gray

Write-Host "`n2. 检查常见语法问题" -ForegroundColor Yellow
Write-Host "- 检查是否有未闭合的括号 { } [ ] ( )" -ForegroundColor White
Write-Host "- 检查是否有缺失的逗号或分号" -ForegroundColor White
Write-Host "- 检查字符串引号是否匹配" -ForegroundColor White

Write-Host "`n3. 使用简化版本" -ForegroundColor Yellow
Write-Host "如果语法错误难以定位，可以：" -ForegroundColor White
Write-Host "- 备份当前文件" -ForegroundColor White
Write-Host "- 使用简化的角色管理页面" -ForegroundColor White
Write-Host "- 逐步恢复功能" -ForegroundColor White

Write-Host "`n4. 直接初始化权限数据" -ForegroundColor Yellow
Write-Host "不依赖前端，直接通过数据库初始化：" -ForegroundColor White
Write-Host ".\scripts\init-permissions-direct.ps1" -ForegroundColor Gray

Write-Host "`n建议操作顺序：" -ForegroundColor Cyan
Write-Host "1. 先运行权限初始化脚本" -ForegroundColor White
Write-Host "2. 重启后端服务" -ForegroundColor White
Write-Host "3. 修复前端语法错误" -ForegroundColor White
Write-Host "4. 测试权限分配功能" -ForegroundColor White

Write-Host "`n=== 开始权限初始化 ===" -ForegroundColor Green
Write-Host "正在运行权限初始化脚本..." -ForegroundColor White

# 运行权限初始化脚本
if (Test-Path "scripts/init-permissions-direct.ps1") {
    & "scripts/init-permissions-direct.ps1"
} else {
    Write-Host "✗ 找不到权限初始化脚本" -ForegroundColor Red
    Write-Host "请手动运行: .\scripts\init-permissions-direct.ps1" -ForegroundColor Yellow
}