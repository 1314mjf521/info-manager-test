#!/usr/bin/env pwsh

Write-Host "=== 前端API调试 ===" -ForegroundColor Green

# 检查前端是否运行
try {
    $frontendCheck = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 5
    Write-Host "✅ 前端服务正常" -ForegroundColor Green
} catch {
    Write-Host "❌ 前端服务异常" -ForegroundColor Red
    exit 1
}

Write-Host "`n请按以下步骤进行调试:" -ForegroundColor Cyan

Write-Host "`n1. 打开浏览器访问: http://localhost:3000/tickets/test" -ForegroundColor Yellow
Write-Host "2. 打开浏览器开发者工具 (F12)" -ForegroundColor Yellow
Write-Host "3. 切换到 Network 标签页" -ForegroundColor Yellow
Write-Host "4. 使用 admin/admin123 登录" -ForegroundColor Yellow
Write-Host "5. 在测试页面创建工单" -ForegroundColor Yellow
Write-Host "6. 尝试分配和接受工单" -ForegroundColor Yellow
Write-Host "7. 观察 Network 标签页中的请求详情" -ForegroundColor Yellow

Write-Host "`n需要检查的关键信息:" -ForegroundColor Cyan
Write-Host "• 请求URL是否正确 (应该是 http://localhost:8080/api/v1/tickets/ID/accept)" -ForegroundColor White
Write-Host "• 请求方法是否为 POST" -ForegroundColor White
Write-Host "• Authorization 头是否包含正确的 Bearer token" -ForegroundColor White
Write-Host "• Content-Type 是否为 application/json" -ForegroundColor White
Write-Host "• 请求体是否为有效的 JSON" -ForegroundColor White

Write-Host "`n常见问题排查:" -ForegroundColor Cyan
Write-Host "• 如果是 404 错误，检查请求URL路径" -ForegroundColor White
Write-Host "• 如果是 401 错误，检查认证token" -ForegroundColor White
Write-Host "• 如果是 400 错误，检查请求参数格式" -ForegroundColor White
Write-Host "• 如果是 CORS 错误，检查跨域配置" -ForegroundColor White

Write-Host "`n调试完成后，请报告以下信息:" -ForegroundColor Red
Write-Host "1. 具体的错误状态码" -ForegroundColor White
Write-Host "2. 完整的请求URL" -ForegroundColor White
Write-Host "3. 请求头信息" -ForegroundColor White
Write-Host "4. 请求体内容" -ForegroundColor White
Write-Host "5. 服务器响应内容" -ForegroundColor White

Write-Host "`n现在请开始调试..." -ForegroundColor Green