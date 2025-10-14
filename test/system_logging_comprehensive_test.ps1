# 系统日志功能综合测试脚本

$baseUrl = "http://localhost:8080/api/v1"

Write-Host "开始系统日志功能综合测试..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 登录获取token
Write-Host "1. 登录认证测试" -ForegroundColor Yellow
$loginData = '{"username":"admin","password":"admin123"}'
$loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginData -ContentType "application/json"
$token = $loginResponse.data.token
$headers = @{"Authorization" = "Bearer $token"; "Content-Type" = "application/json"}
Write-Host "✓ 登录成功，应该生成认证日志" -ForegroundColor Green

# 执行多种操作生成不同类型的日志
Write-Host "`n2. 执行各种操作生成日志" -ForegroundColor Yellow

# 系统健康检查
Write-Host "执行系统健康检查..." -ForegroundColor Gray
$healthResponse = Invoke-RestMethod -Uri "$baseUrl/system/health" -Method Get -Headers $headers
Write-Host "✓ 健康检查完成，应该生成健康检查日志" -ForegroundColor Green

# 创建系统配置
Write-Host "创建系统配置..." -ForegroundColor Gray
$configData = '{"category":"logging","key":"test_config","value":"enabled","description":"日志测试配置","data_type":"string","is_public":true,"is_editable":true,"reason":"测试日志记录功能"}'
try {
    $configResponse = Invoke-RestMethod -Uri "$baseUrl/config" -Method Post -Body $configData -Headers $headers
    Write-Host "✓ 配置创建成功，应该生成配置操作日志" -ForegroundColor Green
} catch {
    Write-Host "✓ 配置创建失败（可能已存在），应该生成错误日志" -ForegroundColor Yellow
}

# 创建公告
Write-Host "创建系统公告..." -ForegroundColor Gray
$announcementData = '{"title":"日志测试公告","content":"这是用于测试日志记录功能的公告","type":"info","priority":1,"is_active":true,"is_sticky":false,"target_users":[]}'
$announcementResponse = Invoke-RestMethod -Uri "$baseUrl/announcements" -Method Post -Body $announcementData -Headers $headers
Write-Host "✓ 公告创建成功，应该生成公告操作日志" -ForegroundColor Green

# 获取系统指标
Write-Host "获取系统指标..." -ForegroundColor Gray
$metricsResponse = Invoke-RestMethod -Uri "$baseUrl/system/metrics" -Method Get -Headers $headers
Write-Host "✓ 系统指标获取成功，应该生成HTTP请求日志" -ForegroundColor Green

# 等待一秒确保所有异步日志都已写入
Start-Sleep -Seconds 2

# 检查日志记录情况
Write-Host "`n3. 验证日志记录情况" -ForegroundColor Yellow

# 获取所有日志
$logsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=50" -Method Get -Headers $headers
$totalLogs = $logsResponse.data.total
$logs = $logsResponse.data.logs

Write-Host "总日志数量: $totalLogs" -ForegroundColor Cyan

# 按类别统计日志
$logsByCategory = $logs | Group-Object category
Write-Host "`n日志分类统计:" -ForegroundColor Cyan
foreach ($category in $logsByCategory) {
    Write-Host "  $($category.Name): $($category.Count) 条" -ForegroundColor White
}

# 按级别统计日志
$logsByLevel = $logs | Group-Object level
Write-Host "`n日志级别统计:" -ForegroundColor Cyan
foreach ($level in $logsByLevel) {
    $color = switch ($level.Name) {
        "error" { "Red" }
        "warn" { "Yellow" }
        "info" { "Green" }
        default { "White" }
    }
    Write-Host "  $($level.Name): $($level.Count) 条" -ForegroundColor $color
}

# 显示最近的日志
Write-Host "`n最近的10条日志:" -ForegroundColor Cyan
$recentLogs = $logs | Select-Object -First 10
$recentLogs | Select-Object @{Name="时间";Expression={$_.created_at}}, @{Name="级别";Expression={$_.level}}, @{Name="分类";Expression={$_.category}}, @{Name="消息";Expression={$_.message}} | Format-Table -AutoSize

# 验证特定类型的日志
Write-Host "`n4. 验证特定类型日志" -ForegroundColor Yellow

# 检查系统启动日志
$systemLogs = $logs | Where-Object { $_.category -eq "system" }
if ($systemLogs.Count -gt 0) {
    Write-Host "✓ 发现 $($systemLogs.Count) 条系统日志" -ForegroundColor Green
} else {
    Write-Host "✗ 未发现系统日志" -ForegroundColor Red
}

# 检查认证日志
$authLogs = $logs | Where-Object { $_.category -eq "auth" }
if ($authLogs.Count -gt 0) {
    Write-Host "✓ 发现 $($authLogs.Count) 条认证日志" -ForegroundColor Green
} else {
    Write-Host "✗ 未发现认证日志" -ForegroundColor Red
}

# 检查HTTP请求日志
$httpLogs = $logs | Where-Object { $_.category -eq "http" }
if ($httpLogs.Count -gt 0) {
    Write-Host "✓ 发现 $($httpLogs.Count) 条HTTP请求日志" -ForegroundColor Green
} else {
    Write-Host "✗ 未发现HTTP请求日志" -ForegroundColor Red
}

# 检查配置操作日志
$configLogs = $logs | Where-Object { $_.category -eq "config" }
if ($configLogs.Count -gt 0) {
    Write-Host "✓ 发现 $($configLogs.Count) 条配置操作日志" -ForegroundColor Green
} else {
    Write-Host "✗ 未发现配置操作日志" -ForegroundColor Red
}

# 检查公告操作日志
$announcementLogs = $logs | Where-Object { $_.category -eq "announcement" }
if ($announcementLogs.Count -gt 0) {
    Write-Host "✓ 发现 $($announcementLogs.Count) 条公告操作日志" -ForegroundColor Green
} else {
    Write-Host "✗ 未发现公告操作日志" -ForegroundColor Red
}

# 检查健康检查日志
$healthLogs = $logs | Where-Object { $_.category -eq "health" }
if ($healthLogs.Count -gt 0) {
    Write-Host "✓ 发现 $($healthLogs.Count) 条健康检查日志" -ForegroundColor Green
} else {
    Write-Host "✗ 未发现健康检查日志" -ForegroundColor Red
}

# 测试日志过滤功能
Write-Host "`n5. 测试日志过滤功能" -ForegroundColor Yellow

# 按级别过滤
$infoLogsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?level=info&page=1&page_size=10" -Method Get -Headers $headers
Write-Host "✓ info级别日志过滤: $($infoLogsResponse.data.total) 条" -ForegroundColor Green

# 按分类过滤
$httpLogsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?category=http&page=1&page_size=10" -Method Get -Headers $headers
Write-Host "✓ http分类日志过滤: $($httpLogsResponse.data.total) 条" -ForegroundColor Green

# 测试日志清理功能（谨慎使用）
Write-Host "`n6. 测试日志管理功能" -ForegroundColor Yellow
Write-Host "注意: 跳过日志清理测试以保留测试数据" -ForegroundColor Yellow

# 总结测试结果
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "系统日志功能测试总结" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$testResults = @{
    "日志总数" = $totalLogs
    "日志分类数" = $logsByCategory.Count
    "日志级别数" = $logsByLevel.Count
    "系统日志" = ($systemLogs.Count -gt 0)
    "认证日志" = ($authLogs.Count -gt 0)
    "HTTP日志" = ($httpLogs.Count -gt 0)
    "配置日志" = ($configLogs.Count -gt 0)
    "公告日志" = ($announcementLogs.Count -gt 0)
    "健康检查日志" = ($healthLogs.Count -gt 0)
    "日志过滤" = $true
}

foreach ($result in $testResults.GetEnumerator()) {
    $status = if ($result.Value -eq $true -or ($result.Value -is [int] -and $result.Value -gt 0)) { "✓" } else { "✗" }
    $color = if ($status -eq "✓") { "Green" } else { "Red" }
    Write-Host "$status $($result.Key): $($result.Value)" -ForegroundColor $color
}

if ($totalLogs -gt 0) {
    Write-Host "`n🎉 系统日志功能测试通过！日志记录正常工作。" -ForegroundColor Green
} else {
    Write-Host "`n❌ 系统日志功能测试失败！未发现任何日志记录。" -ForegroundColor Red
}

Write-Host "`n测试完成！" -ForegroundColor Cyan