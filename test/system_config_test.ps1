# 系统配置管理测试脚本

# 配置
$baseUrl = "http://localhost:8080/api/v1"
$adminUsername = "admin"
$adminPassword = "admin123"

# 颜色输出函数
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success($message) {
    Write-ColorOutput Green "✓ $message"
}

function Write-Error($message) {
    Write-ColorOutput Red "✗ $message"
}

function Write-Info($message) {
    Write-ColorOutput Cyan "ℹ $message"
}

# 登录获取token
function Get-AuthToken {
    Write-Info "正在登录获取认证token..."
    
    $loginData = @{
        username = $adminUsername
        password = $adminPassword
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginData -ContentType "application/json"
        if ($response.success -and $response.data.access_token) {
            Write-Success "登录成功"
            return $response.data.access_token
        } else {
            Write-Error "登录失败: $($response.message)"
            return $null
        }
    } catch {
        Write-Error "登录请求失败: $($_.Exception.Message)"
        return $null
    }
}

# 创建系统配置
function Test-CreateConfig($token) {
    Write-Info "测试创建系统配置..."
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
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
        $response = Invoke-RestMethod -Uri "$baseUrl/config" -Method Post -Body $configData -Headers $headers
        if ($response.success) {
            Write-Success "系统配置创建成功: $($response.data.category).$($response.data.key)"
            return $response.data
        } else {
            Write-Error "创建系统配置失败: $($response.message)"
            return $null
        }
    } catch {
        Write-Error "创建系统配置请求失败: $($_.Exception.Message)"
        return $null
    }
}

# 获取系统配置列表
function Test-GetConfigs($token) {
    Write-Info "测试获取系统配置列表..."
    
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/config?page=1&page_size=10" -Method Get -Headers $headers
        if ($response.success) {
            Write-Success "获取系统配置列表成功，共 $($response.data.total) 条记录"
            return $response.data
        } else {
            Write-Error "获取系统配置列表失败: $($response.message)"
            return $null
        }
    } catch {
        Write-Error "获取系统配置列表请求失败: $($_.Exception.Message)"
        return $null
    }
}

# 获取单个系统配置
function Test-GetConfigByKey($token, $category, $key) {
    Write-Info "测试获取单个系统配置: ${category}.${key}"
    
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/config/$category/$key" -Method Get -Headers $headers
        if ($response.success) {
            Write-Success "获取系统配置成功: $($response.data.value)"
            return $response.data
        } else {
            Write-Error "获取系统配置失败: $($response.message)"
            return $null
        }
    } catch {
        Write-Error "获取系统配置请求失败: $($_.Exception.Message)"
        return $null
    }
}

# 更新系统配置
function Test-UpdateConfig($token, $category, $key) {
    Write-Info "测试更新系统配置: ${category}.${key}"
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $updateData = @{
        value = "true"
        reason = "测试更新配置值"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/config/$category/$key" -Method Put -Body $updateData -Headers $headers
        if ($response.success) {
            Write-Success "系统配置更新成功: $($response.data.value)"
            return $response.data
        } else {
            Write-Error "更新系统配置失败: $($response.message)"
            return $null
        }
    } catch {
        Write-Error "更新系统配置请求失败: $($_.Exception.Message)"
        return $null
    }
}

# 创建公告
function Test-CreateAnnouncement($token) {
    Write-Info "测试创建系统公告..."
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $announcementData = @{
        title = "系统维护通知"
        content = "系统将于今晚22:00-24:00进行维护，期间可能影响正常使用，请提前保存工作。"
        type = "maintenance"
        priority = 3
        is_active = $true
        is_sticky = $true
        target_users = @()
        start_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        end_time = (Get-Date).AddDays(1).ToString("yyyy-MM-ddTHH:mm:ssZ")
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/announcements" -Method Post -Body $announcementData -Headers $headers
        if ($response.success) {
            Write-Success "系统公告创建成功: $($response.data.title)"
            return $response.data
        } else {
            Write-Error "创建系统公告失败: $($response.message)"
            return $null
        }
    } catch {
        Write-Error "创建系统公告请求失败: $($_.Exception.Message)"
        return $null
    }
}

# 获取公告列表
function Test-GetAnnouncements($token) {
    Write-Info "测试获取公告列表..."
    
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/announcements?page=1&page_size=10" -Method Get -Headers $headers
        if ($response.success) {
            Write-Success "获取公告列表成功，共 $($response.data.total) 条记录"
            return $response.data
        } else {
            Write-Error "获取公告列表失败: $($response.message)"
            return $null
        }
    } catch {
        Write-Error "获取公告列表请求失败: $($_.Exception.Message)"
        return $null
    }
}

# 标记公告为已查看
function Test-MarkAnnouncementViewed($token, $announcementId) {
    Write-Info "测试标记公告为已查看: ID $announcementId"
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/announcements/$announcementId/view" -Method Post -Headers $headers
        if ($response.success) {
            Write-Success "标记公告查看成功"
            return $response.data
        } else {
            Write-Error "标记公告查看失败: $($response.message)"
            return $null
        }
    } catch {
        Write-Error "标记公告查看请求失败: $($_.Exception.Message)"
        return $null
    }
}

# 获取系统健康状态
function Test-GetSystemHealth($token) {
    Write-Info "测试获取系统健康状态..."
    
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/system/health" -Method Get -Headers $headers
        if ($response.success) {
            Write-Success "获取系统健康状态成功: $($response.data.overall_status)"
            Write-Info "健康组件: $($response.data.summary.healthy_components)/$($response.data.summary.total_components)"
            return $response.data
        } else {
            Write-Error "获取系统健康状态失败: $($response.message)"
            return $null
        }
    } catch {
        Write-Error "获取系统健康状态请求失败: $($_.Exception.Message)"
        return $null
    }
}

# 获取系统指标
function Test-GetSystemMetrics($token) {
    Write-Info "测试获取系统指标..."
    
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/system/metrics" -Method Get -Headers $headers
        if ($response.success) {
            Write-Success "获取系统指标成功"
            Write-Info "CPU使用率: $($response.data.summary.cpu_usage)%"
            Write-Info "内存使用: $($response.data.summary.memory_usage)MB"
            return $response.data
        } else {
            Write-Error "获取系统指标失败: $($response.message)"
            return $null
        }
    } catch {
        Write-Error "获取系统指标请求失败: $($_.Exception.Message)"
        return $null
    }
}

# 获取系统日志
function Test-GetSystemLogs($token) {
    Write-Info "测试获取系统日志..."
    
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=10" -Method Get -Headers $headers
        if ($response.success) {
            Write-Success "获取系统日志成功，共 $($response.data.total) 条记录"
            return $response.data
        } else {
            Write-Error "获取系统日志失败: $($response.message)"
            return $null
        }
    } catch {
        Write-Error "获取系统日志请求失败: $($_.Exception.Message)"
        return $null
    }
}

# 主测试流程
function Main {
    Write-Info "开始系统配置管理功能测试..."
    Write-Info "=========================================="
    
    # 获取认证token
    $token = Get-AuthToken
    if (-not $token) {
        Write-Error "无法获取认证token，测试终止"
        return
    }
    
    Write-Info ""
    Write-Info "1. 测试系统配置管理"
    Write-Info "----------------------------------------"
    
    # 创建系统配置
    $config = Test-CreateConfig $token
    if ($config) {
        # 获取配置列表
        Test-GetConfigs $token
        
        # 获取单个配置
        Test-GetConfigByKey $token $config.category $config.key
        
        # 更新配置
        Test-UpdateConfig $token $config.category $config.key
    }
    
    Write-Info ""
    Write-Info "2. 测试公告管理"
    Write-Info "----------------------------------------"
    
    # 创建公告
    $announcement = Test-CreateAnnouncement $token
    if ($announcement) {
        # 获取公告列表
        Test-GetAnnouncements $token
        
        # 标记公告为已查看
        Test-MarkAnnouncementViewed $token $announcement.id
    }
    
    Write-Info ""
    Write-Info "3. 测试系统监控"
    Write-Info "----------------------------------------"
    
    # 获取系统健康状态
    Test-GetSystemHealth $token
    
    # 获取系统指标
    Test-GetSystemMetrics $token
    
    # 获取系统日志
    Test-GetSystemLogs $token
    
    Write-Info ""
    Write-Success "系统配置管理功能测试完成！"
}

# 运行主测试
Main