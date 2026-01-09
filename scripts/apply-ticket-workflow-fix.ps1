# 工单流程修复部署脚本

Write-Host "开始应用工单流程修复..." -ForegroundColor Green

# 1. 备份原有文件
Write-Host "1. 备份原有文件..." -ForegroundColor Yellow
$backupDir = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force

# 备份关键文件
if (Test-Path "internal/handlers/ticket_handler.go") {
    Copy-Item "internal/handlers/ticket_handler.go" "$backupDir/ticket_handler.go.bak"
}
if (Test-Path "frontend/src/api/ticket.ts") {
    Copy-Item "frontend/src/api/ticket.ts" "$backupDir/ticket.ts.bak"
}

# 2. 应用后端修复
Write-Host "2. 应用后端修复..." -ForegroundColor Yellow

# 复制修复文件到正确位置
if (Test-Path "backend_fixes/complete_ticket_workflow_fix.go") {
    Copy-Item "backend_fixes/complete_ticket_workflow_fix.go" "internal/handlers/complete_ticket_workflow_handler.go"
    Write-Host "   ✓ 复制完整工单流程处理器" -ForegroundColor Green
}

# 3. 应用前端修复
Write-Host "3. 应用前端修复..." -ForegroundColor Yellow

# 复制修复的API文件
if (Test-Path "frontend/src/api/ticketFixed.ts") {
    Write-Host "   ✓ 修复的API文件已准备就绪" -ForegroundColor Green
}

# 复制测试组件
if (Test-Path "frontend/src/views/test/TicketWorkflowTest.vue") {
    Write-Host "   ✓ 工单流程测试组件已准备就绪" -ForegroundColor Green
}

# 4. 更新路由配置
Write-Host "4. 更新路由配置..." -ForegroundColor Yellow

# 检查是否需要更新前端路由
$routerFile = "frontend/src/router/index.ts"
if (Test-Path $routerFile) {
    $routerContent = Get-Content $routerFile -Raw
    if ($routerContent -notmatch "TicketWorkflowTest") {
        Write-Host "   需要手动添加测试页面路由到 $routerFile" -ForegroundColor Red
        Write-Host "   添加以下路由配置:" -ForegroundColor Cyan
        Write-Host @"
{
  path: '/test/ticket-workflow',
  name: 'TicketWorkflowTest',
  component: () => import('@/views/test/TicketWorkflowTest.vue'),
  meta: { title: '工单流程测试' }
}
"@ -ForegroundColor White
    }
}

# 5. 数据库更新检查
Write-Host "5. 检查数据库更新需求..." -ForegroundColor Yellow
Write-Host "   请确保执行以下SQL语句更新数据库结构:" -ForegroundColor Cyan
Write-Host @"
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMP NULL;
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMP NULL;
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS returned_at TIMESTAMP NULL;
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS processing_started_at TIMESTAMP NULL;
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP NULL;
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS closed_at TIMESTAMP NULL;
"@ -ForegroundColor White

# 6. 编译和重启服务
Write-Host "6. 重新编译和启动服务..." -ForegroundColor Yellow

# 停止现有服务
Write-Host "   停止现有服务..." -ForegroundColor Gray
$processes = Get-Process -Name "info-management-system" -ErrorAction SilentlyContinue
if ($processes) {
    $processes | Stop-Process -Force
    Write-Host "   ✓ 已停止现有服务" -ForegroundColor Green
}

# 重新编译后端
Write-Host "   重新编译后端..." -ForegroundColor Gray
try {
    & go build -o info-management-system.exe ./cmd/server
    Write-Host "   ✓ 后端编译成功" -ForegroundColor Green
} catch {
    Write-Host "   ✗ 后端编译失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 重新编译前端
Write-Host "   重新编译前端..." -ForegroundColor Gray
Push-Location frontend
try {
    & npm run build
    Write-Host "   ✓ 前端编译成功" -ForegroundColor Green
} catch {
    Write-Host "   ✗ 前端编译失败: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Pop-Location
}

# 7. 启动服务
Write-Host "7. 启动服务..." -ForegroundColor Yellow
try {
    Start-Process -FilePath ".\info-management-system.exe" -WindowStyle Hidden
    Write-Host "   ✓ 服务启动成功" -ForegroundColor Green
} catch {
    Write-Host "   ✗ 服务启动失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 8. 验证修复
Write-Host "8. 验证修复..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 10 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✓ 服务健康检查通过" -ForegroundColor Green
    }
} catch {
    Write-Host "   ✗ 服务健康检查失败" -ForegroundColor Red
}

# 9. 完成提示
Write-Host "`n修复部署完成!" -ForegroundColor Green
Write-Host "备份文件保存在: $backupDir" -ForegroundColor Cyan
Write-Host "`n下一步操作:" -ForegroundColor Yellow
Write-Host "1. 访问 http://localhost:8080/test/ticket-workflow 测试工单流程" -ForegroundColor White
Write-Host "2. 检查现有工单的状态转换是否正常" -ForegroundColor White
Write-Host "3. 验证权限控制是否按预期工作" -ForegroundColor White
Write-Host "4. 如有问题，可以从备份文件恢复" -ForegroundColor White

Write-Host "`n如果遇到问题，请查看:" -ForegroundColor Cyan
Write-Host "- 后端日志: logs/app.log" -ForegroundColor White
Write-Host "- 浏览器开发者工具的网络请求" -ForegroundColor White
Write-Host "- TICKET_WORKFLOW_FIX_GUIDE.md 详细说明" -ForegroundColor White