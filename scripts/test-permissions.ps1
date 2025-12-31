# 测试权限数据脚本
Write-Host "=== 权限数据测试 ===" -ForegroundColor Green

# 简单的前端测试
Write-Host "1. 检查前端是否正常启动..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5173" -Method GET -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ 前端服务正常运行" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ 前端服务未启动或有问题: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n2. 检查后端API是否可访问..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -Method GET -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ 后端API正常运行" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ 后端API未启动或有问题: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n3. 测试权限相关页面..." -ForegroundColor Yellow
Write-Host "请手动测试以下功能:" -ForegroundColor Cyan
Write-Host "  1. 访问权限管理页面 (http://localhost:5173/permissions)" -ForegroundColor White
Write-Host "  2. 检查页面是否快速加载，不卡死" -ForegroundColor White
Write-Host "  3. 检查列表模式是否清晰显示权限信息" -ForegroundColor White
Write-Host "  4. 访问角色管理页面，点击某个角色的'权限'按钮" -ForegroundColor White
Write-Host "  5. 检查权限树中是否有'工单系统'模块" -ForegroundColor White
Write-Host "  6. 尝试选择工单系统相关权限" -ForegroundColor White

Write-Host "`n=== 验证步骤 ===" -ForegroundColor Green
Write-Host "如果以上功能都正常，说明修复成功！" -ForegroundColor Yellow