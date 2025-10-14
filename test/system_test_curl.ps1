# 使用curl的系统配置管理测试脚本

$baseUrl = "http://localhost:8080/api/v1"

Write-Host "开始系统配置管理功能测试..." -ForegroundColor Cyan

# 登录获取token
Write-Host "正在登录..." -ForegroundColor Yellow
$loginResult = curl -s -X POST "$baseUrl/auth/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}'
$loginJson = $loginResult | ConvertFrom-Json

if ($loginJson.success) {
    $token = $loginJson.data.access_token
    Write-Host "登录成功" -ForegroundColor Green
} else {
    Write-Host "登录失败" -ForegroundColor Red
    exit 1
}

# 测试创建系统配置
Write-Host "测试创建系统配置..." -ForegroundColor Yellow
$configResult = curl -s -X POST "$baseUrl/config" -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d '{"category":"system","key":"maintenance_mode","value":"false","description":"系统维护模式开关","data_type":"bool","is_public":true,"is_editable":true,"reason":"初始化系统配置"}'
$configJson = $configResult | ConvertFrom-Json

if ($configJson.success) {
    Write-Host "系统配置创建成功" -ForegroundColor Green
} else {
    Write-Host "创建系统配置失败: $($configJson.message)" -ForegroundColor Red
}

# 测试获取系统配置列表
Write-Host "测试获取系统配置列表..." -ForegroundColor Yellow
$configListResult = curl -s -X GET "$baseUrl/config?page=1&page_size=10" -H "Authorization: Bearer $token"
$configListJson = $configListResult | ConvertFrom-Json

if ($configListJson.success) {
    Write-Host "获取系统配置列表成功，共 $($configListJson.data.total) 条记录" -ForegroundColor Green
} else {
    Write-Host "获取系统配置列表失败: $($configListJson.message)" -ForegroundColor Red
}

# 测试创建公告
Write-Host "测试创建系统公告..." -ForegroundColor Yellow
$announcementResult = curl -s -X POST "$baseUrl/announcements" -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d '{"title":"系统维护通知","content":"系统将于今晚进行维护","type":"maintenance","priority":3,"is_active":true,"is_sticky":true,"target_users":[]}'
$announcementJson = $announcementResult | ConvertFrom-Json

if ($announcementJson.success) {
    Write-Host "系统公告创建成功" -ForegroundColor Green
} else {
    Write-Host "创建系统公告失败: $($announcementJson.message)" -ForegroundColor Red
}

# 测试获取系统健康状态
Write-Host "测试获取系统健康状态..." -ForegroundColor Yellow
$healthResult = curl -s -X GET "$baseUrl/system/health" -H "Authorization: Bearer $token"
$healthJson = $healthResult | ConvertFrom-Json

if ($healthJson.success) {
    Write-Host "获取系统健康状态成功: $($healthJson.data.overall_status)" -ForegroundColor Green
} else {
    Write-Host "获取系统健康状态失败: $($healthJson.message)" -ForegroundColor Red
}

Write-Host "系统配置管理功能测试完成！" -ForegroundColor Cyan