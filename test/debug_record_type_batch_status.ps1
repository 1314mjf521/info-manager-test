# 调试记录类型批量状态更新问题
# 编码：UTF-8

Write-Host "=== 调试记录类型批量状态更新 ===" -ForegroundColor Green

# 设置API基础URL
$baseUrl = "http://localhost:8080/api/v1"
$token = ""

# 登录获取token
function Get-AuthToken {
    Write-Host "正在登录获取认证token..." -ForegroundColor Yellow
    
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginData -ContentType "application/json"
        if ($response.success -and $response.data.access_token) {
            $script:token = $response.data.access_token
            Write-Host "登录成功，获取到token" -ForegroundColor Green
            return $true
        } else {
            Write-Host "登录失败：$($response.error.message)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "登录请求失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 创建认证头
function Get-AuthHeaders {
    return @{
        "Authorization" = "Bearer $script:token"
        "Content-Type" = "application/json"
    }
}

# 获取记录类型列表
function Get-RecordTypes {
    Write-Host "`n--- 获取记录类型列表 ---" -ForegroundColor Cyan
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/record-types" -Method Get -Headers (Get-AuthHeaders)
        if ($response.success -and $response.data) {
            Write-Host "成功获取记录类型列表" -ForegroundColor Green
            Write-Host "记录类型数量：$($response.data.Count)" -ForegroundColor Gray
            
            # 显示前几个记录类型的信息
            $response.data | Select-Object -First 3 | ForEach-Object {
                Write-Host "ID: $($_.id), Name: $($_.name), Active: $($_.is_active)" -ForegroundColor Gray
            }
            
            return $response.data
        } else {
            Write-Host "获取记录类型列表失败" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "获取记录类型列表请求失败：$($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 测试批量状态更新 - 使用不同的参数格式
function Test-BatchStatusUpdate {
    param(
        [array]$RecordTypes
    )
    
    Write-Host "`n--- 测试批量状态更新 ---" -ForegroundColor Cyan
    
    if (-not $RecordTypes -or $RecordTypes.Count -eq 0) {
        Write-Host "没有可用的记录类型进行测试" -ForegroundColor Red
        return
    }
    
    # 选择前两个记录类型进行测试
    $testTypes = $RecordTypes | Select-Object -First 2
    $typeIds = $testTypes | ForEach-Object { $_.id }
    
    Write-Host "测试记录类型ID：$($typeIds -join ', ')" -ForegroundColor Gray
    
    # 测试格式1：使用 record_type_ids 和 is_active
    Write-Host "`n测试格式1：record_type_ids + is_active" -ForegroundColor Yellow
    $testData1 = @{
        record_type_ids = $typeIds
        is_active = $false
    } | ConvertTo-Json -Depth 10
    
    Write-Host "请求数据：$testData1" -ForegroundColor Gray
    
    try {
        $response1 = Invoke-RestMethod -Uri "$baseUrl/record-types/batch-status" -Method Put -Body $testData1 -Headers (Get-AuthHeaders)
        Write-Host "格式1测试成功：$($response1.message)" -ForegroundColor Green
    } catch {
        Write-Host "格式1测试失败：$($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "错误响应：$responseBody" -ForegroundColor Red
        }
    }
    
    # 测试格式2：使用 RecordTypeIDs 和 IsActive (Go结构体字段名)
    Write-Host "`n测试格式2：RecordTypeIDs + IsActive" -ForegroundColor Yellow
    $testData2 = @{
        RecordTypeIDs = $typeIds
        IsActive = $true
    } | ConvertTo-Json -Depth 10
    
    Write-Host "请求数据：$testData2" -ForegroundColor Gray
    
    try {
        $response2 = Invoke-RestMethod -Uri "$baseUrl/record-types/batch-status" -Method Put -Body $testData2 -Headers (Get-AuthHeaders)
        Write-Host "格式2测试成功：$($response2.message)" -ForegroundColor Green
    } catch {
        Write-Host "格式2测试失败：$($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "错误响应：$responseBody" -ForegroundColor Red
        }
    }
    
    # 测试格式3：使用字符串类型的ID
    Write-Host "`n测试格式3：字符串类型ID" -ForegroundColor Yellow
    $testData3 = @{
        record_type_ids = $typeIds | ForEach-Object { $_.ToString() }
        is_active = $true
    } | ConvertTo-Json -Depth 10
    
    Write-Host "请求数据：$testData3" -ForegroundColor Gray
    
    try {
        $response3 = Invoke-RestMethod -Uri "$baseUrl/record-types/batch-status" -Method Put -Body $testData3 -Headers (Get-AuthHeaders)
        Write-Host "格式3测试成功：$($response3.message)" -ForegroundColor Green
    } catch {
        Write-Host "格式3测试失败：$($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "错误响应：$responseBody" -ForegroundColor Red
        }
    }
}

# 测试单个记录类型状态更新
function Test-SingleStatusUpdate {
    param(
        [array]$RecordTypes
    )
    
    Write-Host "`n--- 测试单个记录类型状态更新 ---" -ForegroundColor Cyan
    
    if (-not $RecordTypes -or $RecordTypes.Count -eq 0) {
        Write-Host "没有可用的记录类型进行测试" -ForegroundColor Red
        return
    }
    
    $testType = $RecordTypes[0]
    Write-Host "测试记录类型：ID=$($testType.id), Name=$($testType.name)" -ForegroundColor Gray
    
    $updateData = @{
        is_active = -not $testType.is_active
    } | ConvertTo-Json -Depth 10
    
    Write-Host "更新数据：$updateData" -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/record-types/$($testType.id)" -Method Put -Body $updateData -Headers (Get-AuthHeaders)
        Write-Host "单个状态更新测试成功" -ForegroundColor Green
    } catch {
        Write-Host "单个状态更新测试失败：$($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "错误响应：$responseBody" -ForegroundColor Red
        }
    }
}

# 主测试流程
function Main {
    Write-Host "开始调试记录类型批量状态更新..." -ForegroundColor Green
    
    # 登录
    if (-not (Get-AuthToken)) {
        Write-Host "无法获取认证token，测试终止" -ForegroundColor Red
        return
    }
    
    # 获取记录类型列表
    $recordTypes = Get-RecordTypes
    if (-not $recordTypes) {
        Write-Host "无法获取记录类型列表，测试终止" -ForegroundColor Red
        return
    }
    
    # 测试单个状态更新（作为对照）
    Test-SingleStatusUpdate -RecordTypes $recordTypes
    
    # 测试批量状态更新
    Test-BatchStatusUpdate -RecordTypes $recordTypes
    
    Write-Host "`n=== 调试完成 ===" -ForegroundColor Green
    Write-Host "请检查上述测试结果，找出正确的参数格式" -ForegroundColor Yellow
}

# 执行主测试
Main