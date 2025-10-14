# 记录管理修复测试脚本
Write-Host "=== 记录管理修复测试 ===" -ForegroundColor Green

# 测试配置
$baseUrl = "http://localhost:8080/api/v1"
$frontendUrl = "http://localhost:3000"

# 获取认证token
Write-Host "`n1. 获取认证token..." -ForegroundColor Yellow
$loginData = '{"username":"admin","password":"admin123"}'

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.success -and $loginResponse.data.token) {
        $token = $loginResponse.data.token
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        Write-Host "✓ 认证成功" -ForegroundColor Green
    } else {
        Write-Host "✗ 认证失败" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ 认证请求失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 测试记录类型API
Write-Host "`n2. 测试记录类型管理..." -ForegroundColor Yellow

# 创建默认记录类型
$defaultTypes = @(
    @{
        name = "work"
        description = "工作记录类型"
        isActive = $true
        fields = @(
            @{ name = "title"; label = "标题"; type = "text"; required = $true },
            @{ name = "description"; label = "描述"; type = "textarea"; required = $true }
        )
    },
    @{
        name = "study"
        description = "学习笔记类型"
        isActive = $true
        fields = @(
            @{ name = "title"; label = "标题"; type = "text"; required = $true },
            @{ name = "content"; label = "内容"; type = "textarea"; required = $true }
        )
    },
    @{
        name = "project"
        description = "项目文档类型"
        isActive = $true
        fields = @(
            @{ name = "title"; label = "标题"; type = "text"; required = $true },
            @{ name = "description"; label = "描述"; type = "textarea"; required = $true }
        )
    },
    @{
        name = "other"
        description = "其他类型"
        isActive = $true
        fields = @(
            @{ name = "title"; label = "标题"; type = "text"; required = $true },
            @{ name = "content"; label = "内容"; type = "textarea"; required = $true }
        )
    }
)

foreach ($type in $defaultTypes) {
    try {
        $typeJson = $type | ConvertTo-Json -Depth 3
        $response = Invoke-RestMethod -Uri "$baseUrl/record-types" -Method POST -Body $typeJson -Headers $headers
        
        if ($response.success) {
            Write-Host "✓ 创建记录类型成功: $($type.name)" -ForegroundColor Green
        } else {
            Write-Host "⚠ 记录类型可能已存在: $($type.name)" -ForegroundColor Yellow
        }
    } catch {
        if ($_.Exception.Response.StatusCode -eq 400) {
            Write-Host "⚠ 记录类型已存在: $($type.name)" -ForegroundColor Yellow
        } else {
            Write-Host "✗ 创建记录类型失败: $($type.name) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 获取记录类型列表
Write-Host "`n3. 获取记录类型列表..." -ForegroundColor Yellow
try {
    $typesResponse = Invoke-RestMethod -Uri "$baseUrl/record-types" -Method GET -Headers $headers
    
    if ($typesResponse.success -and $typesResponse.data) {
        $types = $typesResponse.data
        Write-Host "✓ 获取记录类型成功，共 $($types.Count) 个类型" -ForegroundColor Green
        
        foreach ($type in $types) {
            Write-Host "  - $($type.name): $($type.description)" -ForegroundColor Gray
        }
    } else {
        Write-Host "✗ 获取记录类型失败" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 获取记录类型请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试创建记录
Write-Host "`n4. 测试创建记录..." -ForegroundColor Yellow

$testRecord = @{
    title = "测试记录"
    type = "work"
    status = "draft"
    content = @{
        description = "这是一个测试记录，用于验证记录管理功能"
    }
    tags = @("测试", "记录管理")
} | ConvertTo-Json -Depth 3

try {
    $recordResponse = Invoke-RestMethod -Uri "$baseUrl/records" -Method POST -Body $testRecord -Headers $headers
    
    if ($recordResponse.success) {
        Write-Host "✓ 创建记录成功" -ForegroundColor Green
        $recordId = $recordResponse.data.id
        Write-Host "  记录ID: $recordId" -ForegroundColor Gray
        
        # 测试获取记录详情
        Write-Host "`n5. 测试获取记录详情..." -ForegroundColor Yellow
        try {
            $detailResponse = Invoke-RestMethod -Uri "$baseUrl/records/$recordId" -Method GET -Headers $headers
            
            if ($detailResponse.success) {
                Write-Host "✓ 获取记录详情成功" -ForegroundColor Green
                Write-Host "  标题: $($detailResponse.data.title)" -ForegroundColor Gray
                Write-Host "  类型: $($detailResponse.data.type)" -ForegroundColor Gray
            } else {
                Write-Host "✗ 获取记录详情失败" -ForegroundColor Red
            }
        } catch {
            Write-Host "✗ 获取记录详情请求失败: $($_.Exception.Message)" -ForegroundColor Red
        }
        
    } else {
        Write-Host "✗ 创建记录失败: $($recordResponse.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 创建记录请求失败: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            Write-Host "错误详情: $errorBody" -ForegroundColor Gray
        } catch {
            Write-Host "无法读取错误详情" -ForegroundColor Gray
        }
    }
}

# 测试前端页面
Write-Host "`n6. 测试前端页面访问..." -ForegroundColor Yellow

$frontendPages = @(
    @{ path = "/records"; name = "记录管理" },
    @{ path = "/records/create"; name = "创建记录" },
    @{ path = "/record-types"; name = "记录类型管理" }
)

foreach ($page in $frontendPages) {
    try {
        $response = Invoke-WebRequest -Uri "$frontendUrl$($page.path)" -TimeoutSec 5 -UseBasicParsing
        Write-Host "✓ $($page.name) 页面可访问 - 状态: $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "✗ $($page.name) 页面访问失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
Write-Host "现在可以在浏览器中测试记录管理功能:" -ForegroundColor Cyan
Write-Host "1. 访问 http://localhost:3000/record-types 管理记录类型" -ForegroundColor White
Write-Host "2. 访问 http://localhost:3000/records 查看记录列表" -ForegroundColor White
Write-Host "3. 访问 http://localhost:3000/records/create 创建新记录" -ForegroundColor White
Write-Host "4. 选择正确的记录类型进行创建" -ForegroundColor White