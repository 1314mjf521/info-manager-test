#!/usr/bin/env pwsh

Write-Host "=== 前端工单API测试 ===" -ForegroundColor Green

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

Write-Host "`n=== 前端工单功能测试指南 ===" -ForegroundColor Cyan

Write-Host "`n1. 打开浏览器访问: http://localhost:3000" -ForegroundColor Yellow
Write-Host "2. 使用 admin/admin123 登录" -ForegroundColor Yellow
Write-Host "3. 进入工单管理页面" -ForegroundColor Yellow

Write-Host "`n=== 需要验证的功能点 ===" -ForegroundColor Cyan

Write-Host "`n📋 基础功能验证:" -ForegroundColor White
Write-Host "  ✓ 工单列表是否正常加载" -ForegroundColor Gray
Write-Host "  ✓ 工单创建功能是否正常" -ForegroundColor Gray
Write-Host "  ✓ 工单状态显示是否正确" -ForegroundColor Gray
Write-Host "  ✓ 操作按钮是否根据状态动态显示" -ForegroundColor Gray

Write-Host "`n🔄 状态流转验证:" -ForegroundColor White
Write-Host "  ✓ 已提交 → 分配工单" -ForegroundColor Gray
Write-Host "  ✓ 已分配 → 接受工单/拒绝工单" -ForegroundColor Gray
Write-Host "  ✓ 已接受 → 开始处理/审批通过" -ForegroundColor Gray
Write-Host "  ✓ 处理中 → 解决工单/挂起工单" -ForegroundColor Gray
Write-Host "  ✓ 已解决 → 关闭工单" -ForegroundColor Gray
Write-Host "  ✓ 已关闭 → 重新打开" -ForegroundColor Gray

Write-Host "`n🔐 权限控制验证:" -ForegroundColor White
Write-Host "  ✓ 管理员可以执行所有操作" -ForegroundColor Gray
Write-Host "  ✓ 普通用户只能操作自己相关的工单" -ForegroundColor Gray
Write-Host "  ✓ 操作按钮根据权限显示/隐藏" -ForegroundColor Gray

Write-Host "`n🐛 常见问题排查:" -ForegroundColor White
Write-Host "  • 如果操作按钮不显示，检查权限配置" -ForegroundColor Gray
Write-Host "  • 如果API调用失败，检查网络请求" -ForegroundColor Gray
Write-Host "  • 如果状态不更新，检查页面刷新逻辑" -ForegroundColor Gray

Write-Host "`n💡 调试技巧:" -ForegroundColor White
Write-Host "  • 打开浏览器开发者工具 (F12)" -ForegroundColor Gray
Write-Host "  • 查看 Network 标签页的API请求" -ForegroundColor Gray
Write-Host "  • 查看 Console 标签页的错误信息" -ForegroundColor Gray
Write-Host "  • 检查 Application 标签页的 localStorage" -ForegroundColor Gray

Write-Host "`n=== 手动测试步骤 ===" -ForegroundColor Cyan

Write-Host "`n步骤1: 创建测试工单" -ForegroundColor Yellow
Write-Host "  1. 点击'创建工单'按钮" -ForegroundColor White
Write-Host "  2. 填写工单信息" -ForegroundColor White
Write-Host "  3. 提交工单" -ForegroundColor White
Write-Host "  4. 验证工单出现在列表中，状态为'已提交'" -ForegroundColor White

Write-Host "`n步骤2: 分配工单" -ForegroundColor Yellow
Write-Host "  1. 找到刚创建的工单" -ForegroundColor White
Write-Host "  2. 点击'分配工单'按钮" -ForegroundColor White
Write-Host "  3. 选择处理人员" -ForegroundColor White
Write-Host "  4. 验证状态变为'已分配'" -ForegroundColor White

Write-Host "`n步骤3: 接受工单" -ForegroundColor Yellow
Write-Host "  1. 点击'接受工单'按钮" -ForegroundColor White
Write-Host "  2. 验证状态变为'已接受'" -ForegroundColor White
Write-Host "  3. 验证操作按钮变为'开始处理'或'审批通过'" -ForegroundColor White

Write-Host "`n步骤4: 处理工单" -ForegroundColor Yellow
Write-Host "  1. 点击'开始处理'按钮" -ForegroundColor White
Write-Host "  2. 验证状态变为'处理中'" -ForegroundColor White
Write-Host "  3. 验证操作按钮变为'解决工单'或'挂起工单'" -ForegroundColor White

Write-Host "`n步骤5: 解决工单" -ForegroundColor Yellow
Write-Host "  1. 点击'解决工单'按钮" -ForegroundColor White
Write-Host "  2. 验证状态变为'已解决'" -ForegroundColor White
Write-Host "  3. 验证操作按钮变为'关闭工单'" -ForegroundColor White

Write-Host "`n步骤6: 关闭工单" -ForegroundColor Yellow
Write-Host "  1. 点击'关闭工单'按钮" -ForegroundColor White
Write-Host "  2. 验证状态变为'已关闭'" -ForegroundColor White
Write-Host "  3. 验证操作按钮变为'重新打开'" -ForegroundColor White

Write-Host "`n=== 如果发现问题 ===" -ForegroundColor Red
Write-Host "请记录以下信息:" -ForegroundColor White
Write-Host "  • 具体的操作步骤" -ForegroundColor Gray
Write-Host "  • 期望的结果 vs 实际结果" -ForegroundColor Gray
Write-Host "  • 浏览器控制台的错误信息" -ForegroundColor Gray
Write-Host "  • 网络请求的响应内容" -ForegroundColor Gray

Write-Host "`n现在请开始手动测试前端工单功能..." -ForegroundColor Green
Write-Host "测试完成后，请报告发现的问题。" -ForegroundColor Yellow