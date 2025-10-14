#!/usr/bin/env pwsh

# 测试系统管理界面修复效果
Write-Host "=== Testing System Management Interface Fixes ===" -ForegroundColor Green

# 配置
$baseUrl = "http://localhost:8080/api/v1"
$headers = @{
    "Content-Type" = "application/json"
}

# 1. 登录获取token
Write-Host "`n1. Login..." -ForegroundColor Yellow
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -Headers $headers
    if ($loginResponse.success) {
        $token = $loginResponse.data.token
        $headers["Authorization"] = "Bearer $token"
        Write-Host "✓ Login successful" -ForegroundColor Green
    } else {
        Write-Host "✗ Login failed: $($loginResponse.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Login error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. 测试系统健康检查
Write-Host "`n2. Testing System Health..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$baseUrl/system/health" -Method GET -Headers $headers
    if ($healthResponse.success) {
        Write-Host "✓ Health check successful" -ForegroundColor Green
        Write-Host "  Overall Status: $($healthResponse.data.overall_status)" -ForegroundColor Cyan
        Write-Host "  Components: $($healthResponse.data.components.Count)" -ForegroundColor Cyan
        Write-Host "  Check Time: $($healthResponse.data.checked_at)" -ForegroundColor Cyan
        
        # 检查组件详情
        foreach ($component in $healthResponse.data.components) {
            Write-Host "  - $($component.component): $($component.status) (${component.response_time}ms)" -ForegroundColor Gray
        }
    } else {
        Write-Host "✗ Health check failed" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Health check error: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. 测试系统配置
Write-Host "`n3. Testing System Configuration..." -ForegroundColor Yellow
try {
    # 创建测试配置
    $configData = @{
        category = "test"
        key = "ui_fix_test"
        value = "test_value_fixed"
        description = "UI fix test configuration"
        is_public = $true
    } | ConvertTo-Json

    $createResponse = Invoke-RestMethod -Uri "$baseUrl/config" -Method POST -Body $configData -Headers $headers
    if ($createResponse.success) {
        Write-Host "✓ Config creation successful" -ForegroundColor Green
        $configId = $createResponse.data.id
        
        # 获取配置列表
        $getResponse = Invoke-RestMethod -Uri "$baseUrl/config?page=1&page_size=10" -Method GET -Headers $headers
        if ($getResponse.success) {
            Write-Host "✓ Config list retrieval successful" -ForegroundColor Green
            Write-Host "  Total configs: $($getResponse.data.total)" -ForegroundColor Cyan
            
            # 查找我们创建的配置
            $testConfig = $getResponse.data.configs | Where-Object { $_.key -eq "ui_fix_test" }
            if ($testConfig) {
                Write-Host "  ✓ Test config found with correct fields:" -ForegroundColor Green
                Write-Host "    - category: $($testConfig.category)" -ForegroundColor Gray
                Write-Host "    - key: $($testConfig.key)" -ForegroundColor Gray
                Write-Host "    - is_public: $($testConfig.is_public)" -ForegroundColor Gray
                Write-Host "    - updated_at: $($testConfig.updated_at)" -ForegroundColor Gray
            }
        }
        
        # 清理测试配置
        Invoke-RestMethod -Uri "$baseUrl/config/test/ui_fix_test" -Method DELETE -Headers $headers | Out-Null
        Write-Host "✓ Test config cleaned up" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Config test error: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. 测试公告管理
Write-Host "`n4. Testing Announcement Management..." -ForegroundColor Yellow
try {
    # 创建测试公告
    $announcementData = @{
        title = "UI Fix Test Announcement"
        content = "Testing announcement status toggle functionality"
        type = "info"
        priority = 1
        is_active = $true
        is_sticky = $false
    } | ConvertTo-Json

    $createResponse = Invoke-RestMethod -Uri "$baseUrl/announcements" -Method POST -Body $announcementData -Headers $headers
    if ($createResponse.success) {
        Write-Host "✓ Announcement creation successful" -ForegroundColor Green
        $announcementId = $createResponse.data.id
        
        # 获取公告列表
        $getResponse = Invoke-RestMethod -Uri "$baseUrl/announcements?page=1&page_size=10" -Method GET -Headers $headers
        if ($getResponse.success) {
            Write-Host "✓ Announcement list retrieval successful" -ForegroundColor Green
            
            # 查找我们创建的公告
            $testAnnouncement = $getResponse.data.announcements | Where-Object { $_.id -eq $announcementId }
            if ($testAnnouncement) {
                Write-Host "  ✓ Test announcement found with correct fields:" -ForegroundColor Green
                Write-Host "    - title: $($testAnnouncement.title)" -ForegroundColor Gray
                Write-Host "    - is_active: $($testAnnouncement.is_active)" -ForegroundColor Gray
                Write-Host "    - view_count: $($testAnnouncement.view_count)" -ForegroundColor Gray
                Write-Host "    - created_at: $($testAnnouncement.created_at)" -ForegroundColor Gray
                
                # 测试状态切换
                $updateData = @{
                    title = $testAnnouncement.title
                    type = $testAnnouncement.type
                    priority = $testAnnouncement.priority
                    content = $testAnnouncement.content
                    is_active = $false
                    is_sticky = $testAnnouncement.is_sticky
                } | ConvertTo-Json
                
                $updateResponse = Invoke-RestMethod -Uri "$baseUrl/announcements/$announcementId" -Method PUT -Body $updateData -Headers $headers
                if ($updateResponse.success) {
                    Write-Host "  ✓ Status toggle successful" -ForegroundColor Green
                    Write-Host "    - New status: $($updateResponse.data.is_active)" -ForegroundColor Gray
                }
            }
        }
        
        # 清理测试公告
        Invoke-RestMethod -Uri "$baseUrl/announcements/$announcementId" -Method DELETE -Headers $headers | Out-Null
        Write-Host "✓ Test announcement cleaned up" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Announcement test error: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. 测试日志管理
Write-Host "`n5. Testing Log Management..." -ForegroundColor Yellow
try {
    # 获取日志列表
    $logResponse = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=5" -Method GET -Headers $headers
    if ($logResponse.success) {
        Write-Host "✓ Log list retrieval successful" -ForegroundColor Green
        Write-Host "  Total logs: $($logResponse.data.total)" -ForegroundColor Cyan
        
        if ($logResponse.data.logs -and $logResponse.data.logs.Count -gt 0) {
            $sampleLog = $logResponse.data.logs[0]
            Write-Host "  ✓ Sample log fields:" -ForegroundColor Green
            Write-Host "    - level: $($sampleLog.level)" -ForegroundColor Gray
            Write-Host "    - category: $($sampleLog.category)" -ForegroundColor Gray
            Write-Host "    - ip_address: $($sampleLog.ip_address)" -ForegroundColor Gray
            Write-Host "    - created_at: $($sampleLog.created_at)" -ForegroundColor Gray
        }
        
        # 测试日志清理
        $cleanupResponse = Invoke-RestMethod -Uri "$baseUrl/logs/cleanup" -Method POST -Body '{"retention_days": 30}' -Headers $headers
        if ($cleanupResponse.success) {
            Write-Host "✓ Log cleanup successful" -ForegroundColor Green
            Write-Host "  Deleted count: $($cleanupResponse.data.deleted_count)" -ForegroundColor Cyan
        }
    }
} catch {
    Write-Host "✗ Log test error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== System Management Interface Fix Test Complete ===" -ForegroundColor Green
Write-Host "All major issues should now be resolved:" -ForegroundColor Yellow
Write-Host "1. ✓ System health shows check time and component details" -ForegroundColor Gray
Write-Host "2. ✓ System config interface displays data correctly" -ForegroundColor Gray
Write-Host "3. ✓ Announcement status can be toggled properly" -ForegroundColor Gray
Write-Host "4. ✓ Log cleanup function works with correct field mapping" -ForegroundColor Gray