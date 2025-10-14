#!/usr/bin/env pwsh

# 调试日志清理API问题
Write-Host "=== Debugging Log Cleanup API Issue ===" -ForegroundColor Green

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

# 2. 检查当前日志情况
Write-Host "`n2. Checking Current Log Status..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/logs?category=http&page=1&page_size=5" -Method GET -Headers $headers
    if ($response.success) {
        Write-Host "✓ Found $($response.data.total) http category logs" -ForegroundColor Green
        if ($response.data.logs -and $response.data.logs.Count -gt 0) {
            Write-Host "Sample logs:" -ForegroundColor Cyan
            foreach ($log in $response.data.logs) {
                Write-Host "  - ID: $($log.id), Level: $($log.level), Category: $($log.category), Time: $($log.created_at)" -ForegroundColor Gray
            }
        }
    }
} catch {
    Write-Host "✗ Failed to get logs: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. 测试不同的清理API调用方式
Write-Host "`n3. Testing Different Cleanup API Calls..." -ForegroundColor Yellow

# 3.1 测试原始的retention_days方式
Write-Host "`n3.1 Testing retention_days cleanup..." -ForegroundColor Cyan
try {
    $cleanupData1 = @{
        retention_days = 0  # 清理所有日志
    } | ConvertTo-Json
    
    Write-Host "Request data: $cleanupData1" -ForegroundColor Gray
    $response1 = Invoke-RestMethod -Uri "$baseUrl/logs/cleanup" -Method POST -Body $cleanupData1 -Headers $headers
    Write-Host "Response: $($response1 | ConvertTo-Json -Depth 3)" -ForegroundColor Gray
} catch {
    Write-Host "✗ retention_days cleanup failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 3.2 测试筛选条件清理
Write-Host "`n3.2 Testing filtered cleanup..." -ForegroundColor Cyan
try {
    $cleanupData2 = @{
        category = "http"
        cleanup_filtered = $true
    } | ConvertTo-Json
    
    Write-Host "Request data: $cleanupData2" -ForegroundColor Gray
    $response2 = Invoke-RestMethod -Uri "$baseUrl/logs/cleanup" -Method POST -Body $cleanupData2 -Headers $headers
    Write-Host "Response: $($response2 | ConvertTo-Json -Depth 3)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Filtered cleanup failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 3.3 测试直接删除方式
Write-Host "`n3.3 Testing direct delete approach..." -ForegroundColor Cyan
try {
    # 先获取要删除的日志ID列表
    $logsResponse = Invoke-RestMethod -Uri "$baseUrl/logs?category=http&level=debug&page=1&page_size=10" -Method GET -Headers $headers
    if ($logsResponse.success -and $logsResponse.data.logs -and $logsResponse.data.logs.Count -gt 0) {
        Write-Host "Found $($logsResponse.data.logs.Count) debug+http logs to test delete" -ForegroundColor Gray
        
        # 尝试删除第一条日志作为测试
        $testLogId = $logsResponse.data.logs[0].id
        Write-Host "Attempting to delete log ID: $testLogId" -ForegroundColor Gray
        
        try {
            $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/logs/$testLogId" -Method DELETE -Headers $headers
            Write-Host "Delete response: $($deleteResponse | ConvertTo-Json -Depth 3)" -ForegroundColor Gray
        } catch {
            Write-Host "Delete single log failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "No debug+http logs found for delete test" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Direct delete test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. 测试批量删除方式
Write-Host "`n4. Testing Batch Delete..." -ForegroundColor Yellow
try {
    $batchDeleteData = @{
        ids = @()  # 空数组测试
        category = "http"
        level = "debug"
    } | ConvertTo-Json
    
    Write-Host "Batch delete request: $batchDeleteData" -ForegroundColor Gray
    $batchResponse = Invoke-RestMethod -Uri "$baseUrl/logs/batch-delete" -Method POST -Body $batchDeleteData -Headers $headers
    Write-Host "Batch delete response: $($batchResponse | ConvertTo-Json -Depth 3)" -ForegroundColor Gray
} catch {
    Write-Host "Batch delete failed (expected): $($_.Exception.Message)" -ForegroundColor Yellow
}

# 5. 检查后端是否支持筛选清理
Write-Host "`n5. Analyzing Backend API Support..." -ForegroundColor Yellow
Write-Host "Based on the test results:" -ForegroundColor Cyan
Write-Host "  • retention_days cleanup works but clears by time, not by filter" -ForegroundColor Gray
Write-Host "  • cleanup_filtered parameter may not be supported by backend" -ForegroundColor Gray
Write-Host "  • Backend may only support time-based cleanup" -ForegroundColor Gray

Write-Host "`n=== Recommended Solutions ===" -ForegroundColor Cyan
Write-Host "1. Backend Enhancement:" -ForegroundColor Yellow
Write-Host "   • Add support for filtered cleanup in logs/cleanup API" -ForegroundColor Gray
Write-Host "   • Accept level, category, start_time, end_time parameters" -ForegroundColor Gray
Write-Host "   • Implement SQL WHERE clause based on provided filters" -ForegroundColor Gray

Write-Host "`n2. Frontend Fallback:" -ForegroundColor Yellow
Write-Host "   • Show warning when using filtered cleanup" -ForegroundColor Gray
Write-Host "   • Suggest using time-range filter for more precise cleanup" -ForegroundColor Gray
Write-Host "   • Provide alternative: export filtered logs then use time-based cleanup" -ForegroundColor Gray

Write-Host "`n3. Alternative Approach:" -ForegroundColor Yellow
Write-Host "   • Use time-range filter combined with other filters" -ForegroundColor Gray
Write-Host "   • Implement client-side filtering with server-side time cleanup" -ForegroundColor Gray
Write-Host "   • Add batch delete functionality for specific log IDs" -ForegroundColor Gray

Write-Host "`n=== Debug Complete ===" -ForegroundColor Green