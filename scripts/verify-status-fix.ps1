# 验证工单状态修复脚本

Write-Host "验证工单状态转换修复..." -ForegroundColor Green

# 检查服务是否运行
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✓ 服务运行正常" -ForegroundColor Green
} catch {
    Write-Host "✗ 服务未运行，请先启动服务" -ForegroundColor Red
    Write-Host "运行: .\rebuild-and-start.bat" -ForegroundColor Yellow
    exit 1
}

# 检查前端是否可访问
try {
    $frontendResponse = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✓ 前端页面可访问" -ForegroundColor Green
} catch {
    Write-Host "⚠ 前端页面可能未配置，但后端API可用" -ForegroundColor Yellow
}

Write-Host "`n现在可以测试以下功能:" -ForegroundColor Cyan
Write-Host "1. 工单状态转换 (approved -> progress)" -ForegroundColor White
Write-Host "2. 完整的工单流程" -ForegroundColor White
Write-Host "3. 权限控制" -ForegroundColor White

Write-Host "`n测试方式:" -ForegroundColor Yellow
Write-Host "方式1: 访问测试页面" -ForegroundColor White
Write-Host "  http://localhost:8080/test/ticket-api" -ForegroundColor Gray
Write-Host "方式2: 使用API测试脚本" -ForegroundColor White
Write-Host "  .\scripts\test-ticket-workflow-fix.ps1 -Token 'your_token'" -ForegroundColor Gray
Write-Host "方式3: 手动API测试" -ForegroundColor White
Write-Host "  使用Postman或curl测试API端点" -ForegroundColor Gray

Write-Host "`n关键修复验证:" -ForegroundColor Cyan
Write-Host "- 创建工单 -> 分配 -> 接受 -> 审批 -> 开始处理" -ForegroundColor White
Write-Host "- 最后一步 '开始处理' 应该不再返回400错误" -ForegroundColor Green

Write-Host "`nAPI端点测试:" -ForegroundColor Yellow
Write-Host "PUT /api/v1/tickets/{id}/status" -ForegroundColor White
Write-Host "Body: {`"status`": `"progress`", `"comment`": `"测试`"}" -ForegroundColor Gray
Write-Host "Expected: 200 OK (之前是400 Bad Request)" -ForegroundColor Green