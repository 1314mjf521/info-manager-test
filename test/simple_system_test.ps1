# 简化的系统配置管理测试脚本

$baseUrl = "http://localhost:8080/api/v1"
$adminUsername = "admin"
$adminPassword = "admin123"

Write-Host "开始系统配置管理功能测试..." -ForegroundColor Cyan

# 登录获取token
Write-Host "正在登录..." -ForegroundColor Yellow
$loginData = @{
    username = $adminUsername
    password = $adminPassword
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginData -ContentType "application/json"
    if ($loginResponse.success) {
        $token = $loginResponse.data.access_token
        Write-Host "登录成功" -ForegroundColor Green
    } else {
        Write-Host "登录失败: $($loginResponse.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "登录请求失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# 测试创建系统配置
Write-Host "测试创建系统配置..." -ForegroundColor Yellow
$configData = @{
    category = "system"
    key = "maintenance_mode"
    value = "false"
    description = "系统维护模式开关"
    data_type = "bool"
    is_public = $true
    is_editable = $true
    reason = "初始化系统配置"
} | ConvertTo-Json

try {
    $configResponse = Invoke-RestMethod -Uri "$baseUrl/config" -Method Post -Body $configData -Headers $headers
    if ($configResponse.success) {
        Write-Host "系统配置创建成功" -ForegroundColor Green
    } else {
        Write-Host "创建系统配置失败: $($configResponse.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "创建系统配置请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试获取系统配置列表
Write-Host "测试获取系统配置列表..." -ForegroundColor Yellow
try {
    $configListResponse = Invoke-RestMethod -Uri "$baseUrl/config?page=1&page_size=10" -Method Get -Headers $headers
    if ($configListResponse.success) {
        Write-Host "获取系统配置列表成功，共 $($configListResponse.data.total) 条记录" -ForegroundColor Green
    } else {
        Write-Host "获取系统配置列表失败: $($configListResponse.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "获取系统配置列表请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试创建公告
Write-Host "测试创建系统公告..." -ForegroundColor Yellow
$announcementData = @{
    title = "系统维护通知"
    content = "系统将于今晚进行维护"
    type = "maintenance"
    priority = 3
    is_active = $true
    is_sticky = $true
    target_users = @()
} | ConvertTo-Json

try {
    $announcementResponse = Invoke-RestMethod -Uri "$baseUrl/announcements" -Method Post -Body $announcementData -Headers $headers
    if ($announcementResponse.success) {
        Write-Host "系统公告创建成功" -ForegroundColor Green
    } else {
        Write-Host "创建系统公告失败: $($announcementResponse.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "创建系统公告请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试获取系统健康状态
Write-Host "测试获取系统健康状态..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$baseUrl/system/health" -Method Get -Headers $headers
    if ($healthResponse.success) {
        Write-Host "获取系统健康状态成功: $($healthResponse.data.overall_status)" -ForegroundColor Green
    } else {
        Write-Host "获取系统健康状态失败: $($healthResponse.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "获取系统健康状态请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "系统配置管理功能测试完成！" -ForegroundColor Cyan