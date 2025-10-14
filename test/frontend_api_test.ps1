# 前端API测试脚本
Write-Host "=== 前端API调用测试 ===" -ForegroundColor Green

# 检查后端服务器状态
Write-Host "`n1. 检查后端服务器..." -ForegroundColor Yellow
$backendUrl = "http://localhost:8080"

try {
    $healthResponse = Invoke-RestMethod -Uri "$backendUrl/api/v1/health" -Method GET -TimeoutSec 5
    Write-Host "✅ 后端服务器运行正常" -ForegroundColor Green
    Write-Host "健康状态: $($healthResponse | ConvertTo-Json -Depth 2)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ 后端服务器无法访问: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "请确保后端服务器在 $backendUrl 运行" -ForegroundColor Yellow
    exit 1
}

# 测试登录
Write-Host "`n2. 测试用户登录..." -ForegroundColor Yellow
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "$backendUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.success) {
        $token = $loginResponse.data.token
        Write-Host "✅ 登录成功" -ForegroundColor Green
        Write-Host "Token: $($token.Substring(0, 20))..." -ForegroundColor Cyan
    } else {
        Write-Host "❌ 登录失败: $($loginResponse.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ 登录请求失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 设置认证头
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# 测试记录类型API
Write-Host "`n3. 测试记录类型API..." -ForegroundColor Yellow
try {
    $recordTypesResponse = Invoke-RestMethod -Uri "$backendUrl/api/v1/record-types" -Method GET -Headers $headers
    Write-Host "✅ 记录类型API正常" -ForegroundColor Green
    
    if ($recordTypesResponse.success -and $recordTypesResponse.data) {
        Write-Host "记录类型数量: $($recordTypesResponse.data.Count)" -ForegroundColor Cyan
        foreach ($type in $recordTypesResponse.data) {
            Write-Host "  - $($type.name): $($type.display_name)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "⚠️  记录类型API失败: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 测试记录列表API
Write-Host "`n4. 测试记录列表API..." -ForegroundColor Yellow
try {
    $recordsResponse = Invoke-RestMethod -Uri "$backendUrl/api/v1/records?page=1&page_size=10" -Method GET -Headers $headers
    Write-Host "✅ 记录列表API正常" -ForegroundColor Green
    
    if ($recordsResponse.success -and $recordsResponse.data) {
        if ($recordsResponse.data.records) {
            Write-Host "记录总数: $($recordsResponse.data.total)" -ForegroundColor Cyan
            Write-Host "当前页记录数: $($recordsResponse.data.records.Count)" -ForegroundColor Cyan
            
            Write-Host "`n记录列表:" -ForegroundColor White
            foreach ($record in $recordsResponse.data.records) {
                Write-Host "  ID: $($record.id) | 标题: $($record.title) | 类型: $($record.type) | 创建者: $($record.creator)" -ForegroundColor Gray
            }
        } else {
            Write-Host "记录数据格式: $($recordsResponse.data | ConvertTo-Json -Depth 2)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "❌ 记录列表API失败: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $errorStream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorStream)
        $errorBody = $reader.ReadToEnd()
        Write-Host "错误详情: $errorBody" -ForegroundColor Yellow
    }
}

# 测试创建记录API
Write-Host "`n5. 测试创建记录API..." -ForegroundColor Yellow
try {
    $newRecord = @{
        type = "work"
        title = "前端API测试记录"
        content = @{
            description = "这是一个通过前端API测试创建的记录"
            testTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        tags = @("测试", "前端", "API")
    } | ConvertTo-Json -Depth 3

    $createResponse = Invoke-RestMethod -Uri "$backendUrl/api/v1/records" -Method POST -Body $newRecord -Headers $headers
    
    if ($createResponse.success) {
        Write-Host "✅ 创建记录成功" -ForegroundColor Green
        Write-Host "新记录ID: $($createResponse.data.id)" -ForegroundColor Cyan
        $testRecordId = $createResponse.data.id
    } else {
        Write-Host "❌ 创建记录失败: $($createResponse.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ 创建记录API失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试更新记录API
if ($testRecordId) {
    Write-Host "`n6. 测试更新记录API..." -ForegroundColor Yellow
    try {
        $updateRecord = @{
            title = "前端API测试记录 (已更新)"
            content = @{
                description = "这是一个通过前端API测试更新的记录"
                testTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                status = "published"
            }
            tags = @("测试", "前端", "API", "已更新")
        } | ConvertTo-Json -Depth 3

        $updateResponse = Invoke-RestMethod -Uri "$backendUrl/api/v1/records/$testRecordId" -Method PUT -Body $updateRecord -Headers $headers
        
        if ($updateResponse.success) {
            Write-Host "✅ 更新记录成功" -ForegroundColor Green
            Write-Host "更新后版本: $($updateResponse.data.version)" -ForegroundColor Cyan
        } else {
            Write-Host "❌ 更新记录失败: $($updateResponse.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ 更新记录API失败: $($_.Exception.Message)" -ForegroundColor Red
    }

    # 测试删除记录API
    Write-Host "`n7. 测试删除记录API..." -ForegroundColor Yellow
    try {
        $deleteResponse = Invoke-RestMethod -Uri "$backendUrl/api/v1/records/$testRecordId" -Method DELETE -Headers $headers
        
        if ($deleteResponse.success) {
            Write-Host "✅ 删除记录成功" -ForegroundColor Green
        } else {
            Write-Host "❌ 删除记录失败: $($deleteResponse.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ 删除记录API失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== API测试完成 ===" -ForegroundColor Green
Write-Host "如果所有测试都通过，前端应该能够正常工作" -ForegroundColor Cyan