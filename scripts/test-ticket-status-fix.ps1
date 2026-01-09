#!/usr/bin/env pwsh

Write-Host "=== 工单状态逻辑修复测试 ===" -ForegroundColor Green

# 检查前端是否运行
Write-Host "检查前端服务状态..." -ForegroundColor Yellow
try {
    $frontendResponse = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 5
    Write-Host "✅ 前端服务正常运行" -ForegroundColor Green
} catch {
    Write-Host "❌ 前端服务未运行，请先启动前端" -ForegroundColor Red
    Write-Host "启动命令: cd frontend && npm run dev" -ForegroundColor Yellow
    exit 1
}

# 检查后端是否运行
Write-Host "检查后端服务状态..." -ForegroundColor Yellow
try {
    $backendResponse = Invoke-WebRequest -Uri "http://localhost:8080/health" -Method GET -TimeoutSec 5
    Write-Host "✅ 后端服务正常运行" -ForegroundColor Green
} catch {
    Write-Host "❌ 后端服务未运行，请先启动后端" -ForegroundColor Red
    Write-Host "启动命令: .\rebuild-and-start.bat" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=== 工单状态逻辑测试要点 ===" -ForegroundColor Cyan
Write-Host "1. 不同状态的工单应显示不同的下一步操作按钮" -ForegroundColor White
Write-Host "   - 已提交(submitted): 显示'分配工单'" -ForegroundColor Gray
Write-Host "   - 已分配(assigned): 显示'接受工单'或'拒绝工单'" -ForegroundColor Gray
Write-Host "   - 已接受(accepted): 显示'审批通过'或'开始处理'" -ForegroundColor Gray
Write-Host "   - 处理中(progress): 显示'挂起工单'或'解决工单'" -ForegroundColor Gray
Write-Host "   - 已解决(resolved): 显示'关闭工单'" -ForegroundColor Gray
Write-Host "   - 已关闭(closed): 显示'重新打开'" -ForegroundColor Gray

Write-Host "`n2. 权限控制应正确工作" -ForegroundColor White
Write-Host "   - 只有有权限的用户才能看到相应操作按钮" -ForegroundColor Gray
Write-Host "   - 工单创建人和处理人有不同的操作权限" -ForegroundColor Gray

Write-Host "`n3. 操作按钮应根据用户身份动态显示" -ForegroundColor White
Write-Host "   - 管理员: 可以执行所有操作" -ForegroundColor Gray
Write-Host "   - 普通用户: 只能操作自己相关的工单" -ForegroundColor Gray

Write-Host "`n=== 测试步骤 ===" -ForegroundColor Cyan
Write-Host "1. 打开浏览器访问: http://localhost:3000" -ForegroundColor Yellow
Write-Host "2. 使用 admin/admin123 登录" -ForegroundColor Yellow
Write-Host "3. 进入工单管理页面" -ForegroundColor Yellow
Write-Host "4. 检查不同状态工单的操作按钮是否正确显示" -ForegroundColor Yellow
Write-Host "5. 测试点击操作按钮是否能正确执行状态变更" -ForegroundColor Yellow

Write-Host "`n=== 修复内容总结 ===" -ForegroundColor Green
Write-Host "✅ 修复了工单状态下一步操作的动态显示逻辑" -ForegroundColor Green
Write-Host "✅ 添加了基于权限系统的操作控制" -ForegroundColor Green
Write-Host "✅ 优化了权限检查，支持基础角色权限" -ForegroundColor Green
Write-Host "✅ 改进了工单操作的用户体验" -ForegroundColor Green

Write-Host "`n测试完成后，请验证以下功能是否正常:" -ForegroundColor Cyan
Write-Host "- 工单状态变更是否正确" -ForegroundColor White
Write-Host "- 权限控制是否生效" -ForegroundColor White
Write-Host "- 操作按钮显示是否符合预期" -ForegroundColor White
Write-Host "- 用户体验是否流畅" -ForegroundColor White

Write-Host "`n=== 测试脚本执行完成 ===" -ForegroundColor Green