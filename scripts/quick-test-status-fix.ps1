# 快速测试工单状态修复

Write-Host "快速测试工单状态修复..." -ForegroundColor Green

# 重新启动服务
Write-Host "1. 重新启动服务..." -ForegroundColor Yellow

# 停止现有服务
$processes = Get-Process -Name "info-management-system" -ErrorAction SilentlyContinue
if ($processes) {
    $processes | Stop-Process -Force
    Write-Host "   ✓ 已停止现有服务" -ForegroundColor Green
    Start-Sleep -Seconds 2
}

# 重新编译
Write-Host "2. 重新编译..." -ForegroundColor Yellow
try {
    & go build -o info-management-system.exe ./cmd/server
    Write-Host "   ✓ 编译成功" -ForegroundColor Green
} catch {
    Write-Host "   ✗ 编译失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 启动服务
Write-Host "3. 启动服务..." -ForegroundColor Yellow
try {
    $process = Start-Process -FilePath ".\info-management-system.exe" -PassThru
    Write-Host "   ✓ 服务启动成功 (PID: $($process.Id))" -ForegroundColor Green
    Start-Sleep -Seconds 5
} catch {
    Write-Host "   ✗ 服务启动失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 测试服务是否可用
Write-Host "4. 测试服务可用性..." -ForegroundColor Yellow
$maxRetries = 10
$retryCount = 0

do {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "   ✓ 服务可用" -ForegroundColor Green
            break
        }
    } catch {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "   等待服务启动... ($retryCount/$maxRetries)" -ForegroundColor Gray
            Start-Sleep -Seconds 2
        } else {
            Write-Host "   ✗ 服务启动超时" -ForegroundColor Red
            exit 1
        }
    }
} while ($retryCount -lt $maxRetries)

Write-Host "`n服务已重新启动并可用!" -ForegroundColor Green
Write-Host "现在可以测试工单状态转换了。" -ForegroundColor Cyan

# 提供测试建议
Write-Host "`n建议测试步骤:" -ForegroundColor Yellow
Write-Host "1. 访问前端测试页面: http://localhost:8080/test/ticket-workflow" -ForegroundColor White
Write-Host "2. 或者使用API测试脚本: .\scripts\test-ticket-workflow-fix.ps1" -ForegroundColor White
Write-Host "3. 重点测试 approved -> progress 状态转换" -ForegroundColor White

# 显示服务信息
Write-Host "`n服务信息:" -ForegroundColor Cyan
Write-Host "- 后端服务: http://localhost:8080" -ForegroundColor White
Write-Host "- 前端页面: http://localhost:8080 (如果已配置)" -ForegroundColor White
Write-Host "- API文档: http://localhost:8080/swagger/index.html (如果已配置)" -ForegroundColor White

Write-Host "`n如需停止服务，运行: Get-Process -Name 'info-management-system' | Stop-Process" -ForegroundColor Gray