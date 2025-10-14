# 测试公告公共显示功能
$baseUrl = "http://localhost:8080"
$apiUrl = "$baseUrl/api/v1"

Write-Host "=== 公告公共显示功能测试 ===" -ForegroundColor Green

# 1. 管理员登录
Write-Host "`n1. 管理员登录..." -ForegroundColor Yellow
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
    Write-Host "管理员登录成功" -ForegroundColor Green
} catch {
    Write-Host "管理员登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. 创建测试公告
Write-Host "`n2. 创建测试公告..." -ForegroundColor Yellow
$announcementData = @{
    title = "公共显示测试公告"
    type = "info"
    priority = 5
    content = "这是一条用于测试公共显示功能的公告。普通用户应该能够看到此公告。"
    start_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    end_time = (Get-Date).AddDays(1).ToString("yyyy-MM-ddTHH:mm:ssZ")
    is_active = $true
    is_sticky = $true
    target_users = ""
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$apiUrl/announcements" -Method POST -Body $announcementData -Headers $headers
    $announcementId = $createResponse.id
    Write-Host "测试公告创建成功，ID: $announcementId" -ForegroundColor Green
} catch {
    Write-Host "创建测试公告失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. 测试公共公告接口（无需认证）
Write-Host "`n3. 测试公共公告接口..." -ForegroundColor Yellow
try {
    $publicResponse = Invoke-RestMethod -Uri "$apiUrl/announcements/public?page=1&page_size=10" -Method GET
    Write-Host "公共公告接口调用成功" -ForegroundColor Green
    Write-Host "  返回公告数量: $($publicResponse.announcements.Count)" -ForegroundColor Cyan
    
    # 检查是否包含我们创建的测试公告
    $testAnnouncement = $publicResponse.announcements | Where-Object { $_.id -eq $announcementId }
    if ($testAnnouncement) {
        Write-Host "  ✓ 测试公告在公共接口中可见" -ForegroundColor Green
        Write-Host "    标题: $($testAnnouncement.title)" -ForegroundColor White
        Write-Host "    状态: $(if($testAnnouncement.is_active){'活跃'}else{'非活跃'})" -ForegroundColor White
    } else {
        Write-Host "  ✗ 测试公告在公共接口中不可见" -ForegroundColor Red
    }
} catch {
    Write-Host "公共公告接口调用失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. 创建普通用户进行测试
Write-Host "`n4. 创建普通用户..." -ForegroundColor Yellow
$userData = @{
    username = "testuser"
    password = "test123"
    email = "testuser@example.com"
    display_name = "测试用户"
} | ConvertTo-Json

try {
    $userResponse = Invoke-RestMethod -Uri "$apiUrl/users" -Method POST -Body $userData -Headers $headers
    Write-Host "普通用户创建成功" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*already exists*" -or $_.Exception.Message -like "*已存在*") {
        Write-Host "普通用户已存在，继续测试" -ForegroundColor Yellow
    } else {
        Write-Host "创建普通用户失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 5. 普通用户登录
Write-Host "`n5. 普通用户登录..." -ForegroundColor Yellow
$userLoginData = @{
    username = "testuser"
    password = "test123"
} | ConvertTo-Json

try {
    $userLoginResponse = Invoke-RestMethod -Uri "$apiUrl/auth/login" -Method POST -Body $userLoginData -ContentType "application/json"
    $userToken = $userLoginResponse.token
    $userHeaders = @{
        "Authorization" = "Bearer $userToken"
        "Content-Type" = "application/json"
    }
    Write-Host "普通用户登录成功" -ForegroundColor Green
} catch {
    Write-Host "普通用户登录失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. 普通用户访问公共公告
Write-Host "`n6. 普通用户访问公共公告..." -ForegroundColor Yellow
try {
    $userPublicResponse = Invoke-RestMethod -Uri "$apiUrl/announcements/public?page=1&page_size=10" -Method GET
    Write-Host "普通用户访问公共公告成功" -ForegroundColor Green
    Write-Host "  返回公告数量: $($userPublicResponse.announcements.Count)" -ForegroundColor Cyan
    
    # 检查是否包含测试公告
    $userTestAnnouncement = $userPublicResponse.announcements | Where-Object { $_.id -eq $announcementId }
    if ($userTestAnnouncement) {
        Write-Host "  ✓ 普通用户可以看到测试公告" -ForegroundColor Green
        Write-Host "    标题: $($userTestAnnouncement.title)" -ForegroundColor White
        Write-Host "    内容: $($userTestAnnouncement.content.Substring(0, [Math]::Min(30, $userTestAnnouncement.content.Length)))..." -ForegroundColor White
    } else {
        Write-Host "  ✗ 普通用户无法看到测试公告" -ForegroundColor Red
    }
} catch {
    Write-Host "普通用户访问公共公告失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 7. 测试公告查看次数记录
Write-Host "`n7. 测试公告查看次数记录..." -ForegroundColor Yellow
try {
    $viewResponse = Invoke-RestMethod -Uri "$apiUrl/announcements/$announcementId/view" -Method POST -Headers $userHeaders
    Write-Host "公告查看次数记录成功" -ForegroundColor Green
} catch {
    Write-Host "公告查看次数记录失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 8. 验证查看次数是否增加
Write-Host "`n8. 验证查看次数..." -ForegroundColor Yellow
try {
    $detailResponse = Invoke-RestMethod -Uri "$apiUrl/announcements/$announcementId" -Method GET -Headers $headers
    Write-Host "查看次数: $($detailResponse.view_count)" -ForegroundColor Cyan
} catch {
    Write-Host "获取公告详情失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 9. 测试前端页面访问
Write-Host "`n9. 测试前端页面访问..." -ForegroundColor Yellow
try {
    $frontendResponse = Invoke-WebRequest -Uri "$baseUrl" -Method GET -TimeoutSec 10
    if ($frontendResponse.StatusCode -eq 200) {
        Write-Host "前端页面访问正常" -ForegroundColor Green
        Write-Host "  状态码: $($frontendResponse.StatusCode)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "前端页面访问失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 10. 清理测试数据
Write-Host "`n10. 清理测试数据..." -ForegroundColor Yellow
try {
    # 删除测试公告
    Invoke-RestMethod -Uri "$apiUrl/announcements/$announcementId" -Method DELETE -Headers $headers
    Write-Host "测试公告删除成功" -ForegroundColor Green
    
    # 删除测试用户
    try {
        $usersResponse = Invoke-RestMethod -Uri "$apiUrl/users?username=testuser" -Method GET -Headers $headers
        if ($usersResponse.users -and $usersResponse.users.Count -gt 0) {
            $testUserId = $usersResponse.users[0].id
            Invoke-RestMethod -Uri "$apiUrl/users/$testUserId" -Method DELETE -Headers $headers
            Write-Host "测试用户删除成功" -ForegroundColor Green
        }
    } catch {
        Write-Host "删除测试用户失败: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "清理测试数据失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
Write-Host "请访问 $baseUrl 查看前端公告显示效果" -ForegroundColor Cyan
Write-Host "测试要点:" -ForegroundColor Yellow
Write-Host "1. 公共公告API无需认证即可访问" -ForegroundColor White
Write-Host "2. 普通用户可以看到活跃的公告" -ForegroundColor White
Write-Host "3. 公告查看次数正确记录" -ForegroundColor White
Write-Host "4. 前端公告组件正常显示" -ForegroundColor White