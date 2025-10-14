# 公告管理系统测试脚本
# 测试公告的基本CRUD功能

$baseUrl = "http://localhost:8080"
$apiUrl = "$baseUrl/api/v1"

Write-Host "=== 公告管理系统测试 ===" -ForegroundColor Green

# 1. 登录获取token
Write-Host "`n1. 用户登录..." -ForegroundColor Yellow
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$apiUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.token
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    Write-Host "登录成功" -ForegroundColor Green
} catch {
    Write-Host "登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. 创建测试公告
Write-Host "`n2. 创建测试公告..." -ForegroundColor Yellow
$announcementData = @{
    title = "系统维护通知"
    type = "maintenance"
    priority = 5
    content = "系统将于今晚进行维护升级"
    start_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    end_time = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ssZ")
    is_active = $true
    is_sticky = $true
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$apiUrl/announcements" -Method POST -Body $announcementData -Headers $headers
    $announcementId = $createResponse.id
    Write-Host "公告创建成功，ID: $announcementId" -ForegroundColor Green
} catch {
    Write-Host "创建公告失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. 获取公告列表
Write-Host "`n3. 获取公告列表..." -ForegroundColor Yellow
try {
    $listResponse = Invoke-RestMethod -Uri "$apiUrl/announcements?page=1&page_size=10" -Method GET -Headers $headers
    Write-Host "获取公告列表成功，总数: $($listResponse.total)" -ForegroundColor Green
} catch {
    Write-Host "获取公告列表失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. 更新公告
Write-Host "`n4. 更新公告..." -ForegroundColor Yellow
$updateData = @{
    title = "系统维护通知 - 已更新"
    type = "warning"
    priority = 8
    content = "维护时间调整为今晚23:00-01:00"
    start_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    end_time = (Get-Date).AddDays(3).ToString("yyyy-MM-ddTHH:mm:ssZ")
    is_active = $true
    is_sticky = $true
} | ConvertTo-Json

try {
    $updateResponse = Invoke-RestMethod -Uri "$apiUrl/announcements/$announcementId" -Method PUT -Body $updateData -Headers $headers
    Write-Host "公告更新成功" -ForegroundColor Green
} catch {
    Write-Host "更新公告失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. 删除公告
Write-Host "`n5. 删除测试公告..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "$apiUrl/announcements/$announcementId" -Method DELETE -Headers $headers
    Write-Host "公告删除成功" -ForegroundColor Green
} catch {
    Write-Host "删除公告失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. 测试前端页面
Write-Host "`n6. 测试前端页面..." -ForegroundColor Yellow
try {
    $frontendResponse = Invoke-WebRequest -Uri "$baseUrl" -Method GET -TimeoutSec 10
    if ($frontendResponse.StatusCode -eq 200) {
        Write-Host "前端页面访问正常" -ForegroundColor Green
    }
} catch {
    Write-Host "前端页面访问失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
Write-Host "请访问 $baseUrl 查看前端界面" -ForegroundColor Cyan