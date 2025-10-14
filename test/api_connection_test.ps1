# API连接测试脚本
# 测试前端与后端API的连接状态

Write-Host "=== API连接状态测试 ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080"
$frontendUrl = "http://localhost:3000"

# 检查后端服务状态
Write-Host "`n1. 检查后端服务状态..." -ForegroundColor Yellow

try {
    $healthResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/health" -Method GET -TimeoutSec 5
    Write-Host "✓ 后端服务运行正常" -ForegroundColor Green
    Write-Host "  响应: $($healthResponse | ConvertTo-Json -Compress)" -ForegroundColor Gray
} catch {
    Write-Host "✗ 后端服务连接失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  请确保后端服务在 $baseUrl 上运行" -ForegroundColor Yellow
}

# 检查记录类型API
Write-Host "`n2. 检查记录类型API..." -ForegroundColor Yellow

try {
    $typesResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types" -Method GET -TimeoutSec 5
    Write-Host "✓ 记录类型API连接正常" -ForegroundColor Green
    Write-Host "  返回记录类型数量: $($typesResponse.data.Count)" -ForegroundColor Gray
} catch {
    Write-Host "✗ 记录类型API连接失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 检查记录列表API
Write-Host "`n3. 检查记录列表API..." -ForegroundColor Yellow

try {
    $recordsResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/records" -Method GET -TimeoutSec 5
    Write-Host "✓ 记录列表API连接正常" -ForegroundColor Green
    Write-Host "  返回记录数量: $($recordsResponse.data.records.Count)" -ForegroundColor Gray
} catch {
    Write-Host "✗ 记录列表API连接失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 检查前端服务状态
Write-Host "`n4. 检查前端服务状态..." -ForegroundColor Yellow

try {
    $frontendResponse = Invoke-WebRequest -Uri $frontendUrl -Method GET -TimeoutSec 5
    if ($frontendResponse.StatusCode -eq 200) {
        Write-Host "✓ 前端服务运行正常" -ForegroundColor Green
    } else {
        Write-Host "✗ 前端服务状态异常: $($frontendResponse.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 前端服务连接失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  请确保前端服务在 $frontendUrl 上运行" -ForegroundColor Yellow
}

# 测试数据库连接（通过API）
Write-Host "`n5. 测试数据库连接..." -ForegroundColor Yellow

try {
    # 尝试创建一个测试记录类型
    $testType = @{
        name = "api_test_type"
        display_name = "API测试类型"
        schema = @{
            fields = @(
                @{
                    name = "title"
                    label = "标题"
                    type = "text"
                    required = $true
                }
            )
        }
    }
    
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types" -Method POST -Body ($testType | ConvertTo-Json -Depth 3) -ContentType "application/json" -TimeoutSec 5
    
    if ($createResponse.success) {
        Write-Host "✓ 数据库写入测试成功" -ForegroundColor Green
        
        # 清理测试数据
        try {
            Invoke-RestMethod -Uri "$baseUrl/api/v1/record-types/$($createResponse.data.id)" -Method DELETE -TimeoutSec 5
            Write-Host "✓ 测试数据清理完成" -ForegroundColor Green
        } catch {
            Write-Host "⚠ 测试数据清理失败，请手动删除" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ 数据库写入测试失败" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 数据库连接测试失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Green

Write-Host "`n问题诊断建议：" -ForegroundColor Cyan
Write-Host "如果状态更新不生效，可能的原因：" -ForegroundColor White
Write-Host "1. 后端API服务未正常运行" -ForegroundColor White
Write-Host "2. 数据库连接配置错误" -ForegroundColor White
Write-Host "3. API请求格式不匹配后端期望" -ForegroundColor White
Write-Host "4. 前端缓存导致数据未刷新" -ForegroundColor White

Write-Host "`n解决方案：" -ForegroundColor Cyan
Write-Host "1. 确保后端服务在 http://localhost:8080 运行" -ForegroundColor White
Write-Host "2. 检查数据库连接配置" -ForegroundColor White
Write-Host "3. 在前端界面点击刷新按钮" -ForegroundColor White
Write-Host "4. 清除浏览器缓存后重试" -ForegroundColor White