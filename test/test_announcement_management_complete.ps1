# 公告管理完整功能测试脚本
# 测试公告的创建、查看、预览、编辑、删除功能

$baseUrl = "http://localhost:8080"
$apiUrl = "$baseUrl/api/v1"

Write-Host "=== 公告管理完整功能测试 ===" -ForegroundColor Green

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
    Write-Host "✓ 登录成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. 创建测试公告
Write-Host "`n2. 创建测试公告..." -ForegroundColor Yellow
$announcementData = @{
    title = "系统维护通知 - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    type = "maintenance"
    priority = 5
    content = "系统将于今晚22:00-24:00进行维护升级，期间可能影响部分功能使用。请提前保存工作内容。如有紧急问题，请联系技术支持。"
    start_time = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
    end_time = (Get-Date).AddDays(7).ToString('yyyy-MM-ddTHH:mm:ssZ')
    is_active = $true
    is_sticky = $true
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$apiUrl/announcements" -Method POST -Body $announcementData -Headers $headers
    $announcementId = $createResponse.id
    Write-Host "✓ 公告创建成功，ID: $announcementId" -ForegroundColor Green
    Write-Host "  标题: $($createResponse.title)" -ForegroundColor Cyan
    Write-Host "  类型: $($createResponse.type)" -ForegroundColor Cyan
    Write-Host "  优先级: $($createResponse.priority)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 创建公告失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. 获取公告列表
Write-Host "`n3. 获取公告列表..." -ForegroundColor Yellow
try {
    $listResponse = Invoke-RestMethod -Uri "$apiUrl/announcements?page=1`&page_size=10" -Method GET -Headers $headers
    Write-Host "✓ 获取公告列表成功" -ForegroundColor Green
    Write-Host "  总数: $($listResponse.total)" -ForegroundColor Cyan
    Write-Host "  当前页数据: $($listResponse.announcements.Count)" -ForegroundColor Cyan
    
    # 显示公告信息
    foreach ($announcement in $listResponse.announcements) {
        Write-Host "  - ID: $($announcement.id), 标题: $($announcement.title), 状态: $(if($announcement.is_active){'启用'}else{'停用'})" -ForegroundColor White
    }
} catch {
    Write-Host "✗ 获取公告列表失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. 获取单个公告详情
Write-Host "`n4. 获取公告详情..." -ForegroundColor Yellow
try {
    $detailResponse = Invoke-RestMethod -Uri "$apiUrl/announcements/$announcementId" -Method GET -Headers $headers
    Write-Host "✓ 获取公告详情成功" -ForegroundColor Green
    Write-Host "  标题: $($detailResponse.title)" -ForegroundColor Cyan
    Write-Host "  内容: $($detailResponse.content.Substring(0, [Math]::Min(50, $detailResponse.content.Length)))..." -ForegroundColor Cyan
    Write-Host "  查看次数: $($detailResponse.view_count)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 获取公告详情失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. 更新公告
Write-Host "`n5. 更新公告..." -ForegroundColor Yellow
$updateData = @{
    title = "系统维护通知 - 已更新 - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    type = "warning"
    priority = 8
    content = "【更新】系统维护时间调整为今晚23:00-01:00，维护期间系统将完全不可用。请务必提前保存工作内容并及时退出系统。"
    start_time = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
    end_time = (Get-Date).AddDays(3).ToString('yyyy-MM-ddTHH:mm:ssZ')
    is_active = $true
    is_sticky = $true
} | ConvertTo-Json

try {
    $updateResponse = Invoke-RestMethod -Uri "$apiUrl/announcements/$announcementId" -Method PUT -Body $updateData -Headers $headers
    Write-Host "✓ 公告更新成功" -ForegroundColor Green
    Write-Host "  新标题: $($updateResponse.title)" -ForegroundColor Cyan
    Write-Host "  新类型: $($updateResponse.type)" -ForegroundColor Cyan
    Write-Host "  新优先级: $($updateResponse.priority)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 更新公告失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. 测试公告筛选
Write-Host "`n6. 测试公告筛选..." -ForegroundColor Yellow
try {
    # 按类型筛选
    $filterResponse = Invoke-RestMethod -Uri "$apiUrl/announcements?type=warning`&is_active=true" -Method GET -Headers $headers
    Write-Host "✓ 公告筛选成功" -ForegroundColor Green
    Write-Host "  警告类型活跃公告数: $($filterResponse.announcements.Count)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 公告筛选失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 7. 创建不同类型的公告进行测试
Write-Host "`n7. 创建不同类型公告..." -ForegroundColor Yellow
$testAnnouncements = @(
    @{
        title = "系统升级通知"
        type = "info"
        priority = 3
        content = "系统将在下周进行功能升级，新增多项实用功能。"
        is_active = $true
        is_sticky = $false
    },
    @{
        title = "安全警告"
        type = "error"
        priority = 9
        content = "检测到异常登录行为，请立即检查账户安全。"
        is_active = $true
        is_sticky = $true
    }
)

$createdIds = @()
foreach ($testData in $testAnnouncements) {
    $testData.start_time = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $testData.end_time = (Get-Date).AddDays(5).ToString('yyyy-MM-ddTHH:mm:ssZ')
    
    try {
        $testJson = $testData | ConvertTo-Json
        $testResponse = Invoke-RestMethod -Uri "$apiUrl/announcements" -Method POST -Body $testJson -Headers $headers
        $createdIds += $testResponse.id
        Write-Host "  ✓ 创建 $($testData.type) 类型公告: $($testData.title)" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ 创建公告失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 8. 测试前端页面访问
Write-Host "`n8. 测试前端页面访问..." -ForegroundColor Yellow
try {
    $frontendResponse = Invoke-WebRequest -Uri "$baseUrl" -Method GET -TimeoutSec 10
    if ($frontendResponse.StatusCode -eq 200) {
        Write-Host "✓ 前端页面访问正常" -ForegroundColor Green
        Write-Host "  状态码: $($frontendResponse.StatusCode)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "✗ 前端页面访问失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 9. 清理测试数据
Write-Host "`n9. 清理测试数据..." -ForegroundColor Yellow
$allTestIds = @($announcementId) + $createdIds

foreach ($id in $allTestIds) {
    if ($id) {
        try {
            Invoke-RestMethod -Uri "$apiUrl/announcements/$id" -Method DELETE -Headers $headers
            Write-Host "  ✓ 删除公告 ID: $id" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ 删除公告失败 ID: $id - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 10. 验证删除结果
Write-Host "`n10. 验证删除结果..." -ForegroundColor Yellow
try {
    $finalListResponse = Invoke-RestMethod -Uri "$apiUrl/announcements?page=1`&page_size=50" -Method GET -Headers $headers
    $remainingTestAnnouncements = $finalListResponse.announcements | Where-Object { $_.title -like "*测试*" -or $_.title -like "*维护通知*" -or $_.title -like "*升级通知*" -or $_.title -like "*安全警告*" }
    
    if ($remainingTestAnnouncements.Count -eq 0) {
        Write-Host "✓ 测试数据清理完成" -ForegroundColor Green
    } else {
        Write-Host "⚠ 仍有 $($remainingTestAnnouncements.Count) 条测试数据未清理" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ 验证删除结果失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== 公告管理功能测试完成 ===" -ForegroundColor Green
Write-Host "请在浏览器中访问 $baseUrl 查看前端界面效果" -ForegroundColor Cyan
Write-Host "测试要点:" -ForegroundColor Yellow
Write-Host "1. 公告列表显示和筛选功能" -ForegroundColor White
Write-Host "2. 公告创建和编辑对话框" -ForegroundColor White
Write-Host "3. 公告查看详情对话框" -ForegroundColor White
Write-Host "4. 公告预览对话框效果" -ForegroundColor White
Write-Host "5. 操作按钮布局（确认不换行）" -ForegroundColor White
Write-Host "6. 响应式设计和移动端适配" -ForegroundColor White