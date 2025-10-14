# 简单测试记录类型批量操作
# 编码：UTF-8

Write-Host "=== 简单测试记录类型批量操作 ===" -ForegroundColor Green

# 设置API基础URL
$baseUrl = "http://localhost:8080/api/v1"

# 登录获取token
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.access_token
    Write-Host "登录成功" -ForegroundColor Green
} catch {
    Write-Host "登录失败：$($_.Exception.Message)" -ForegroundColor Red
    exit
}

# 创建认证头
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# 获取记录类型列表
try {
    $typesResponse = Invoke-RestMethod -Uri "$baseUrl/record-types" -Method Get -Headers $headers
    $recordTypes = $typesResponse.data
    Write-Host "获取到 $($recordTypes.Count) 个记录类型" -ForegroundColor Green
    
    if ($recordTypes.Count -gt 0) {
        $testIds = @($recordTypes[0].id)
        if ($recordTypes.Count -gt 1) {
            $testIds += $recordTypes[1].id
        }
        
        Write-Host "测试ID：$($testIds -join ', ')" -ForegroundColor Gray
        
        # 测试批量状态更新
        $batchData = @{
            record_type_ids = $testIds
            is_active = $false
        } | ConvertTo-Json
        
        Write-Host "发送数据：$batchData" -ForegroundColor Gray
        
        try {
            $batchResponse = Invoke-RestMethod -Uri "$baseUrl/record-types/batch-status" -Method Put -Body $batchData -Headers $headers
            Write-Host "批量状态更新成功：$($batchResponse.message)" -ForegroundColor Green
        } catch {
            Write-Host "批量状态更新失败：$($_.Exception.Message)" -ForegroundColor Red
            
            # 尝试获取详细错误信息
            if ($_.Exception.Response) {
                $stream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $responseBody = $reader.ReadToEnd()
                Write-Host "错误详情：$responseBody" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "没有找到记录类型" -ForegroundColor Yellow
    }
} catch {
    Write-Host "获取记录类型失败：$($_.Exception.Message)" -ForegroundColor Red
}