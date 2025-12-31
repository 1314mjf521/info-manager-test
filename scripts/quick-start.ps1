# 工单管理系统快速启动脚本

Write-Host "=== 工单管理系统快速启动 ===" -ForegroundColor Green

# 检查是否在正确的目录
if (-not (Test-Path "go.mod")) {
    Write-Host "错误: 请在项目根目录运行此脚本" -ForegroundColor Red
    exit 1
}

# 1. 编译后端
Write-Host "1. 编译后端服务..." -ForegroundColor Yellow
try {
    go build -o build/server.exe ./cmd/server
    if ($LASTEXITCODE -ne 0) {
        throw "后端编译失败"
    }
    Write-Host "✓ 后端编译成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 后端编译失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. 启动后端服务
Write-Host "2. 启动后端服务..." -ForegroundColor Yellow
$backendProcess = Start-Process -FilePath ".\build\server.exe" -PassThru -WindowStyle Minimized
Write-Host "✓ 后端服务已启动 (PID: $($backendProcess.Id))" -ForegroundColor Green

# 等待后端启动
Write-Host "等待后端服务启动..." -ForegroundColor Gray
Start-Sleep -Seconds 3

# 3. 检查后端健康状态
Write-Host "3. 检查后端健康状态..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 10
    Write-Host "✓ 后端服务健康检查通过" -ForegroundColor Green
} catch {
    Write-Host "⚠️  后端健康检查失败，但继续启动前端" -ForegroundColor Yellow
}

# 4. 启动前端开发服务器
Write-Host "4. 启动前端开发服务器..." -ForegroundColor Yellow
Set-Location frontend

# 检查是否需要安装依赖
if (-not (Test-Path "node_modules")) {
    Write-Host "安装前端依赖..." -ForegroundColor Gray
    npm install
}

# 启动前端
Write-Host "启动前端开发服务器..." -ForegroundColor Gray
$frontendProcess = Start-Process -FilePath "npm" -ArgumentList "run", "dev" -PassThru
Write-Host "✓ 前端开发服务器已启动 (PID: $($frontendProcess.Id))" -ForegroundColor Green

# 返回根目录
Set-Location ..

Write-Host ""
Write-Host "=== 启动完成 ===" -ForegroundColor Green
Write-Host "后端服务: http://localhost:8080" -ForegroundColor Cyan
Write-Host "前端服务: http://localhost:3000" -ForegroundColor Cyan
Write-Host "工单测试页面: http://localhost:3000/tickets/test" -ForegroundColor Cyan
Write-Host ""
Write-Host "默认管理员账号:" -ForegroundColor Yellow
Write-Host "  用户名: admin" -ForegroundColor Gray
Write-Host "  密码: admin123" -ForegroundColor Gray
Write-Host ""
Write-Host "按任意键停止所有服务..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# 停止服务
Write-Host ""
Write-Host "正在停止服务..." -ForegroundColor Yellow
try {
    Stop-Process -Id $backendProcess.Id -Force
    Write-Host "✓ 后端服务已停止" -ForegroundColor Green
} catch {
    Write-Host "⚠️  停止后端服务失败" -ForegroundColor Yellow
}

try {
    Stop-Process -Id $frontendProcess.Id -Force
    Write-Host "✓ 前端服务已停止" -ForegroundColor Green
} catch {
    Write-Host "⚠️  停止前端服务失败" -ForegroundColor Yellow
}

Write-Host "所有服务已停止" -ForegroundColor Green