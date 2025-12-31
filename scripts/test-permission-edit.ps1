# 权限编辑功能测试脚本
Write-Host "=== 权限编辑功能测试 ===" -ForegroundColor Green

Write-Host "请按以下步骤测试权限编辑功能：" -ForegroundColor Yellow

Write-Host "`n1. 访问权限管理页面" -ForegroundColor Cyan
Write-Host "   URL: http://localhost:5173/permissions" -ForegroundColor White

Write-Host "`n2. 检查页面加载" -ForegroundColor Cyan
Write-Host "   - 页面应该快速加载，不卡死" -ForegroundColor White
Write-Host "   - 应该显示权限列表" -ForegroundColor White

Write-Host "`n3. 测试单个权限编辑" -ForegroundColor Cyan
Write-Host "   - 在权限列表中找到任意一个权限" -ForegroundColor White
Write-Host "   - 点击该权限行右侧的'编辑'按钮" -ForegroundColor White
Write-Host "   - 应该弹出权限编辑对话框" -ForegroundColor White

Write-Host "`n4. 测试编辑对话框功能" -ForegroundColor Cyan
Write-Host "   - 对话框应该预填充当前权限的信息" -ForegroundColor White
Write-Host "   - 可以修改权限名称、描述等信息" -ForegroundColor White
Write-Host "   - 点击'更新'按钮应该保存修改" -ForegroundColor White

Write-Host "`n5. 测试新增权限" -ForegroundColor Cyan
Write-Host "   - 点击页面顶部的'新增权限'按钮" -ForegroundColor White
Write-Host "   - 应该弹出空的权限创建对话框" -ForegroundColor White
Write-Host "   - 填写信息后点击'创建'应该添加新权限" -ForegroundColor White

Write-Host "`n6. 检查角色赋权功能" -ForegroundColor Cyan
Write-Host "   - 访问角色管理页面" -ForegroundColor White
Write-Host "   - 点击任意角色的'权限'按钮" -ForegroundColor White
Write-Host "   - 检查权限树中是否有'工单系统'模块" -ForegroundColor White
Write-Host "   - 尝试选择工单相关权限" -ForegroundColor White

Write-Host "`n=== 常见问题排查 ===" -ForegroundColor Red

Write-Host "`n如果编辑按钮不可见：" -ForegroundColor Yellow
Write-Host "   - 检查浏览器控制台是否有JavaScript错误" -ForegroundColor White
Write-Host "   - 刷新页面重试" -ForegroundColor White

Write-Host "`n如果点击编辑没有反应：" -ForegroundColor Yellow
Write-Host "   - 检查浏览器控制台的错误信息" -ForegroundColor White
Write-Host "   - 检查网络请求是否正常" -ForegroundColor White

Write-Host "`n如果ElTag类型错误：" -ForegroundColor Yellow
Write-Host "   - 这个错误已经修复，刷新页面即可" -ForegroundColor White

Write-Host "`n=== 测试完成 ===" -ForegroundColor Green