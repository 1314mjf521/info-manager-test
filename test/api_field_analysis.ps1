# API字段分析脚本 - 检查后端返回的状态字段

Write-Host "=== API字段分析 ===" -ForegroundColor Green

$apiUrl = "http://localhost:8080/api/v1"

Write-Host "`n1. 测试记录列表API..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "$apiUrl/records" -Method GET -TimeoutSec 10 -ErrorAction Stop
    $data = $response.Content | ConvertFrom-Json
    
    Write-Host "✓ API响应成功" -ForegroundColor Green
    Write-Host "响应状态码: $($response.StatusCode)" -ForegroundColor White
    
    if ($data.success -and $data.data -and $data.data.records) {
        Write-Host "✓ 数据结构正确" -ForegroundColor Green
        
        $firstRecord = $data.data.records[0]
        Write-Host "`n第一条记录的字段:" -ForegroundColor Cyan
        
        $firstRecord.PSObject.Properties | ForEach-Object {
            Write-Host "  $($_.Name): $($_.Value)" -ForegroundColor White
        }
        
        # 检查状态字段
        if ($firstRecord.status) {
            Write-Host "`n✓ 找到status字段: $($firstRecord.status)" -ForegroundColor Green
        } elseif ($firstRecord.state) {
            Write-Host "`n⚠️ 找到state字段: $($firstRecord.state)" -ForegroundColor Yellow
        } elseif ($firstRecord.record_status) {
            Write-Host "`n⚠️ 找到record_status字段: $($firstRecord.record_status)" -ForegroundColor Yellow
        } else {
            Write-Host "`n✗ 未找到状态相关字段" -ForegroundColor Red
        }
        
        # 检查时间字段
        Write-Host "`n时间字段检查:" -ForegroundColor Cyan
        if ($firstRecord.created_at) {
            Write-Host "  created_at: $($firstRecord.created_at)" -ForegroundColor White
        }
        if ($firstRecord.updated_at) {
            Write-Host "  updated_at: $($firstRecord.updated_at)" -ForegroundColor White
        }
        if ($firstRecord.createdAt) {
            Write-Host "  createdAt: $($firstRecord.createdAt)" -ForegroundColor White
        }
        if ($firstRecord.updatedAt) {
            Write-Host "  updatedAt: $($firstRecord.updatedAt)" -ForegroundColor White
        }
        
    } else {
        Write-Host "✗ 数据结构不正确" -ForegroundColor Red
        Write-Host "完整响应: $($response.Content)" -ForegroundColor White
    }
    
} catch {
    Write-Host "✗ API请求失败: $_" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "状态码: $statusCode" -ForegroundColor Red
        
        if ($statusCode -eq 401) {
            Write-Host "需要认证 - 请先登录系统" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n2. 测试单个记录API..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "$apiUrl/records/1" -Method GET -TimeoutSec 10 -ErrorAction Stop
    $data = $response.Content | ConvertFrom-Json
    
    Write-Host "✓ 单个记录API响应成功" -ForegroundColor Green
    
    if ($data.success -and $data.data) {
        $record = $data.data
        Write-Host "`n单个记录的字段:" -ForegroundColor Cyan
        
        $record.PSObject.Properties | ForEach-Object {
            Write-Host "  $($_.Name): $($_.Value)" -ForegroundColor White
        }
    } else {
        Write-Host "完整响应: $($response.Content)" -ForegroundColor White
    }
    
} catch {
    Write-Host "✗ 单个记录API请求失败: $_" -ForegroundColor Red
}

Write-Host "`n=== 分析结果 ===" -ForegroundColor Green

Write-Host "`n可能的问题原因：" -ForegroundColor Cyan
Write-Host "1. 后端状态字段名与前端期望不一致" -ForegroundColor White
Write-Host "2. 后端更新后没有立即返回最新数据" -ForegroundColor White
Write-Host "3. 前端刷新数据时覆盖了本地更改" -ForegroundColor White
Write-Host "4. 数据库事务未提交或有延迟" -ForegroundColor White

Write-Host "`n建议的修复方案：" -ForegroundColor Cyan
Write-Host "1. 确认后端返回的确切字段名" -ForegroundColor White
Write-Host "2. 修改前端数据映射逻辑" -ForegroundColor White
Write-Host "3. 优化状态更新后的数据刷新机制" -ForegroundColor White
Write-Host "4. 添加乐观更新（先更新UI，再同步后端）" -ForegroundColor White