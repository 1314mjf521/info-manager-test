# 角色权限分配测试脚本
Write-Host "=== 角色权限分配测试 ===" -ForegroundColor Green

Write-Host "修复内容：" -ForegroundColor Yellow
Write-Host "  - 设置 check-strictly='true' 允许独立选择权限" -ForegroundColor White
Write-Host "  - 修复权限检查处理逻辑" -ForegroundColor White
Write-Host "  - 保留'全选子项'和'取消全选'功能" -ForegroundColor White

Write-Host "`n请按以下步骤测试：" -ForegroundColor Cyan

Write-Host "`n1. 访问角色管理页面" -ForegroundColor Yellow
Write-Host "   URL: http://localhost:5173/admin/roles" -ForegroundColor White

Write-Host "`n2. 选择一个角色进行权限分配" -ForegroundColor Yellow
Write-Host "   - 点击任意角色行的'权限'按钮" -ForegroundColor White
Write-Host "   - 权限分配对话框应该打开" -ForegroundColor White

Write-Host "`n3. 测试单个权限选择" -ForegroundColor Yellow
Write-Host "   - 找到工单系统模块" -ForegroundColor White
Write-Host "   - 点击单个子权限（如'查看工单'）" -ForegroundColor White
Write-Host "   - ✅ 应该只选中该权限，不会自动选中其他权限" -ForegroundColor Green
Write-Host "   - ❌ 之前会自动选中所有工单权限" -ForegroundColor Red

Write-Host "`n4. 测试父权限选择" -ForegroundColor Yellow
Write-Host "   - 点击父权限（如'工单系统'）" -ForegroundColor White
Write-Host "   - ✅ 应该只选中父权限本身" -ForegroundColor Green
Write-Host "   - ❌ 之前会自动选中所有子权限" -ForegroundColor Red

Write-Host "`n5. 测试批量选择功能" -ForegroundColor Yellow
Write-Host "   - 点击权限节点右侧的'全选子项'按钮" -ForegroundColor White
Write-Host "   - ✅ 应该选中该节点及其所有子权限" -ForegroundColor Green
Write-Host "   - 再次点击应该变成'取消全选'并取消所有选择" -ForegroundColor White

Write-Host "`n6. 测试权限保存" -ForegroundColor Yellow
Write-Host "   - 选择一些权限后点击'保存权限'按钮" -ForegroundColor White
Write-Host "   - 应该成功保存并显示成功消息" -ForegroundColor White

Write-Host "`n7. 验证权限生效" -ForegroundColor Yellow
Write-Host "   - 重新打开该角色的权限分配" -ForegroundColor White
Write-Host "   - 之前选择的权限应该正确显示为已选中状态" -ForegroundColor White

Write-Host "`n=== 预期行为 ===" -ForegroundColor Green
Write-Host "✅ 可以独立选择单个权限" -ForegroundColor Green
Write-Host "✅ 选择父权限不会自动选择子权限" -ForegroundColor Green
Write-Host "✅ 选择子权限不会自动选择父权限" -ForegroundColor Green
Write-Host "✅ '全选子项'按钮可以批量选择" -ForegroundColor Green
Write-Host "✅ 权限保存和加载正常" -ForegroundColor Green

Write-Host "`n=== 测试完成 ===" -ForegroundColor Blue