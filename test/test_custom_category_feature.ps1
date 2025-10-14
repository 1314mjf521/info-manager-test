# Test Custom Category Feature
# Verify frontend log category selector custom category functionality

Write-Host "=== Testing Custom Category Feature ===" -ForegroundColor Green

# 配置
$baseUrl = "http://localhost:8080/api/v1"

# Login to get token
Write-Host "1. Login to get authentication token..." -ForegroundColor Yellow
try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body (@{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json) -ContentType "application/json"
    
    if ($loginResponse.success) {
        $token = $loginResponse.data.token
        $headers = @{ "Authorization" = "Bearer $token" }
        Write-Host "✓ 登录成功" -ForegroundColor Green
    } else {
        throw "登录失败: $($loginResponse.message)"
    }
} catch {
    Write-Host "✗ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 创建一些自定义分类的测试日志
Write-Host "`n2. 创建自定义分类的测试日志..." -ForegroundColor Yellow

$customCategories = @("custom_module", "third_party", "integration", "workflow", "analytics")

foreach ($category in $customCategories) {
    try {
        # 这里我们通过触发一些操作来生成日志，或者直接调用日志API（如果有的话）
        # 由于我们没有直接的日志创建API，我们可以通过其他操作来生成日志
        
        # 尝试访问一个不存在的配置来生成日志
        try {
            $testResponse = Invoke-RestMethod -Uri "$baseUrl/config/test_category/$category" -Method Get -Headers $headers
        } catch {
            # 这会生成一个错误日志，可能包含我们想要的分类
        }
        
        Write-Host "  ✓ 尝试生成 $category 分类的日志" -ForegroundColor Gray
    } catch {
        Write-Host "  - 生成 $category 分类日志时出现预期错误" -ForegroundColor Gray
    }
}

# 获取当前日志并分析分类
Write-Host "`n3. 获取日志并分析分类..." -ForegroundColor Yellow
try {
    $logsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?page=1&page_size=100" -Method Get -Headers $headers
    
    if ($logsResponse.success -and $logsResponse.data.logs) {
        $logs = $logsResponse.data.logs
        $totalLogs = $logsResponse.data.total
        
        Write-Host "✓ 获取到 $totalLogs 条日志" -ForegroundColor Green
        
        # 统计所有分类
        $categories = @{}
        foreach ($log in $logs) {
            if ($log.category) {
                if ($categories.ContainsKey($log.category)) {
                    $categories[$log.category]++
                } else {
                    $categories[$log.category] = 1
                }
            }
        }
        
        Write-Host "`n发现的日志分类:" -ForegroundColor Cyan
        $defaultCategories = @('system', 'auth', 'http', 'api', 'database', 'file', 'cache', 'email', 'job', 'security', 'network', 'storage', 'monitor', 'backup', 'config', 'user', 'permission', 'notification', 'report', 'import', 'export', 'sync', 'cron', 'external')
        
        foreach ($category in $categories.Keys | Sort-Object) {
            $count = $categories[$category]
            $isDefault = $defaultCategories -contains $category
            $categoryType = if ($isDefault) { "默认" } else { "自定义" }
            $color = if ($isDefault) { "Gray" } else { "Yellow" }
            
            Write-Host "  $category ($count 条) - $categoryType" -ForegroundColor $color
        }
        
        # 统计自定义分类数量
        $customCategoryCount = ($categories.Keys | Where-Object { $defaultCategories -notcontains $_ }).Count
        Write-Host "`n✓ 发现 $customCategoryCount 个自定义分类" -ForegroundColor Green
        
    } else {
        Write-Host "✗ 没有获取到日志数据" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 获取日志失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试按自定义分类筛选
Write-Host "`n4. 测试按自定义分类筛选..." -ForegroundColor Yellow
if ($categories -and $categories.Keys.Count -gt 0) {
    # 选择一个非默认分类进行测试
    $testCategory = $categories.Keys | Where-Object { $defaultCategories -notcontains $_ } | Select-Object -First 1
    
    if ($testCategory) {
        try {
            $filterResponse = Invoke-RestMethod -Uri "$baseUrl/logs?category=$testCategory&page=1&page_size=10" -Method Get -Headers $headers
            
            if ($filterResponse.success) {
                $filteredLogs = $filterResponse.data.logs
                $filteredTotal = $filterResponse.data.total
                
                Write-Host "✓ 按分类 '$testCategory' 筛选成功" -ForegroundColor Green
                Write-Host "  筛选结果: $filteredTotal 条日志" -ForegroundColor Gray
                
                # 验证筛选结果
                $correctFilter = $true
                foreach ($log in $filteredLogs) {
                    if ($log.category -ne $testCategory) {
                        $correctFilter = $false
                        break
                    }
                }
                
                if ($correctFilter) {
                    Write-Host "  ✓ 筛选结果正确，所有日志都属于指定分类" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ 筛选结果有误，包含其他分类的日志" -ForegroundColor Red
                }
            }
        } catch {
            Write-Host "✗ 按自定义分类筛选失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  - 没有找到自定义分类，跳过筛选测试" -ForegroundColor Gray
    }
} else {
    Write-Host "  - 没有可用的分类数据，跳过筛选测试" -ForegroundColor Gray
}

Write-Host "`n=== 前端自定义分类功能说明 ===" -ForegroundColor Green
Write-Host "前端已优化日志分类选择器，新增功能:" -ForegroundColor Cyan
Write-Host "  • 支持输入自定义分类名称" -ForegroundColor Gray
Write-Host "  • 自动提取并显示系统中存在的所有分类" -ForegroundColor Gray
Write-Host "  • 分组显示：常用分类 + 动态分类" -ForegroundColor Gray
Write-Host "  • 支持筛选和搜索分类" -ForegroundColor Gray
Write-Host "  • 可用于清理任意分类的日志" -ForegroundColor Gray

Write-Host "`n使用方法:" -ForegroundColor Cyan
Write-Host "1. 在日志管理页面的分类下拉框中" -ForegroundColor Gray
Write-Host "2. 可以选择预设的常用分类" -ForegroundColor Gray
Write-Host "3. 也可以直接输入任意分类名称" -ForegroundColor Gray
Write-Host "4. 系统会自动记住并显示曾经出现过的分类" -ForegroundColor Gray
Write-Host "5. 输入自定义分类后可以进行筛选和清理操作" -ForegroundColor Gray

Write-Host "`n=== 自定义分类功能测试完成 ===" -ForegroundColor Green