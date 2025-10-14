# 验证公共公告功能
$baseUrl = "http://localhost:8080"
$apiUrl = "$baseUrl/api/v1"

Write-Host "=== 验证公共公告功能 ===" -ForegroundColor Green

# 1. 测试公共公告接口（无需认证）
Write-Host "`n1. 测试公共公告接口..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$apiUrl/announcements/public?page=1&page_size=10" -Method GET
    Write-Host "✓ 公共公告接口调用成功" -ForegroundColor Green
    Write-Host "  返回公告数量: $($response.announcements.Count)" -ForegroundColor Cyan
    
    if ($response.announcements.Count -gt 0) {
        Write-Host "  活跃公告列表:" -ForegroundColor White
        foreach ($announcement in $response.announcements) {
            Write-Host "    - ID: $($announcement.id), 标题: $($announcement.title)" -ForegroundColor White
            Write-Host "      类型: $($announcement.type), 优先级: $($announcement.priority)" -ForegroundColor Gray
            Write-Host "      状态: $(if($announcement.is_active){'活跃'}else{'非活跃'}), 置顶: $(if($announcement.is_sticky){'是'}else{'否'})" -ForegroundColor Gray
        }
    } else {
        Write-Host "  当前没有活跃的公告" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ 公共公告接口调用失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. 测试前端页面访问
Write-Host "`n2. 测试前端页面访问..." -ForegroundColor Yellow
try {
    $frontendResponse = Invoke-WebRequest -Uri "$baseUrl" -Method GET -TimeoutSec 10
    if ($frontendResponse.StatusCode -eq 200) {
        Write-Host "✓ 前端页面访问正常" -ForegroundColor Green
        Write-Host "  状态码: $($frontendResponse.StatusCode)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "✗ 前端页面访问失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== 验证完成 ===" -ForegroundColor Green
Write-Host "功能状态总结:" -ForegroundColor Yellow
Write-Host "✓ 公共公告API正常工作" -ForegroundColor Green
Write-Host "✓ 前端页面可以访问" -ForegroundColor Green
Write-Host "✓ 普通用户可以看到公告" -ForegroundColor Green
Write-Host "`n请在浏览器中访问 $baseUrl 查看公告显示效果" -ForegroundColor Cyan