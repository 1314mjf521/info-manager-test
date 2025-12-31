# 企业微信通知测试脚本
# 测试企业微信Webhook通知功能

$baseUrl = "http://localhost:8080/api/v1"
$headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== 企业微信通知测试 ===" -ForegroundColor Green

# 1. 登录获取Token
Write-Host "1. 用户登录..." -ForegroundColor Yellow
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -Headers $headers
    $token = $loginResponse.token
    $headers["Authorization"] = "Bearer $token"
    Write-Host "✓ 登录成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. 测试Zabbix Webhook格式（模拟Zabbix脚本调用）
Write-Host "2. 测试Zabbix Webhook格式..." -ForegroundColor Yellow

# 模拟Zabbix脚本传递的参数
$zabbixParams = @{
    Token = "your-wechat-webhook-token-here"  # 需要替换为实际的企业微信机器人Token
    To = "webhook"
    Subject = "Zabbix告警测试"
    Message = @"
告警主机: test-server-01
告警项目: CPU使用率过高
当前值: 95%
告警级别: High
告警时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

这是一条测试告警消息，用于验证企业微信通知功能。
"@
} | ConvertTo-Json

try {
    Write-Host "发送Zabbix格式的告警通知..." -ForegroundColor Cyan
    $zabbixResponse = Invoke-RestMethod -Uri "$baseUrl/wechat/webhook/zabbix" -Method POST -Body $zabbixParams -Headers $headers
    Write-Host "✓ Zabbix告警通知发送成功" -ForegroundColor Green
    Write-Host "  响应: $($zabbixResponse.message)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ Zabbix告警通知发送失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  这可能是因为没有配置有效的企业微信Token" -ForegroundColor Gray
}

# 3. 测试企业微信配置
Write-Host "3. 测试企业微信配置..." -ForegroundColor Yellow

# 示例配置（需要替换为实际的企业微信配置）
$wechatConfig = @{
    webhook_url = "https://qyapi.weixin.qq.com/cgi-bin/webhook/send"
    token = "your-actual-webhook-token-here"  # 需要替换为实际Token
} | ConvertTo-Json

try {
    Write-Host "保存企业微信配置..." -ForegroundColor Cyan
    $configResponse = Invoke-RestMethod -Uri "$baseUrl/wechat/config" -Method POST -Body $wechatConfig -Headers $headers
    Write-Host "✓ 企业微信配置保存成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 企业微信配置保存失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  这是正常的，因为使用的是示例Token" -ForegroundColor Gray
}

# 4. 查询企业微信配置
Write-Host "4. 查询企业微信配置..." -ForegroundColor Yellow
try {
    $getConfigResponse = Invoke-RestMethod -Uri "$baseUrl/wechat/config" -Method GET -Headers $headers
    Write-Host "✓ 企业微信配置查询成功" -ForegroundColor Green
    Write-Host "  Webhook URL: $($getConfigResponse.webhook_url)" -ForegroundColor Cyan
    Write-Host "  Token: $($getConfigResponse.token -replace '.', '*')" -ForegroundColor Cyan  # 隐藏Token
} catch {
    Write-Host "✗ 查询企业微信配置失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. 发送测试消息
Write-Host "5. 发送测试消息..." -ForegroundColor Yellow
$testMessage = @{
    webhook_url = "https://qyapi.weixin.qq.com/cgi-bin/webhook/send"
    token = "your-actual-webhook-token-here"  # 需要替换为实际Token
} | ConvertTo-Json

try {
    Write-Host "发送企业微信测试消息..." -ForegroundColor Cyan
    $testResponse = Invoke-RestMethod -Uri "$baseUrl/wechat/test" -Method POST -Body $testMessage -Headers $headers
    Write-Host "✓ 测试消息发送成功" -ForegroundColor Green
    Write-Host "  响应: $($testResponse.message)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 测试消息发送失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  这是正常的，因为使用的是示例Token" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== 企业微信通知测试完成 ===" -ForegroundColor Green
Write-Host ""
Write-Host "注意事项:" -ForegroundColor Yellow
Write-Host "1. 需要替换脚本中的 'your-actual-webhook-token-here' 为实际的企业微信机器人Token" -ForegroundColor Gray
Write-Host "2. 企业微信机器人Token可以在企业微信群聊中添加机器人时获取" -ForegroundColor Gray
Write-Host "3. Webhook URL通常是: https://qyapi.weixin.qq.com/cgi-bin/webhook/send" -ForegroundColor Gray
Write-Host ""
Write-Host "如何获取企业微信机器人Token:" -ForegroundColor Yellow
Write-Host "1. 在企业微信群聊中，点击右上角的群设置" -ForegroundColor Gray
Write-Host "2. 选择 '群机器人' -> '添加机器人'" -ForegroundColor Gray
Write-Host "3. 创建机器人后，复制Webhook地址中的key参数值" -ForegroundColor Gray
Write-Host "4. 将key值替换到脚本中的token字段" -ForegroundColor Gray