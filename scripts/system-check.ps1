# 工单管理系统状态检查脚本

Write-Host "=== 工单管理系统状态检查 ===" -ForegroundColor Green

$checkResults = @{
    passed = 0
    failed = 0
    warnings = 0
}

function Check-Item {
    param(
        [string]$Name,
        [scriptblock]$Check,
        [string]$Type = "error"
    )
    
    Write-Host "检查: $Name" -ForegroundColor Yellow
    
    try {
        $result = & $Check
        if ($result) {
            Write-Host "  ✓ $Name - 通过" -ForegroundColor Green
            $checkResults.passed++
        } else {
            if ($Type -eq "warning") {
                Write-Host "  ⚠️  $Name - 警告" -ForegroundColor Yellow
                $checkResults.warnings++
            } else {
                Write-Host "  ✗ $Name - 失败" -ForegroundColor Red
                $checkResults.failed++
            }
        }
    } catch {
        if ($Type -eq "warning") {
            Write-Host "  ⚠️  $Name - 警告: $($_.Exception.Message)" -ForegroundColor Yellow
            $checkResults.warnings++
        } else {
            Write-Host "  ✗ $Name - 失败: $($_.Exception.Message)" -ForegroundColor Red
            $checkResults.failed++
        }
    }
}

# 1. 检查项目结构
Check-Item "项目根目录结构" {
    (Test-Path "go.mod") -and 
    (Test-Path "frontend") -and 
    (Test-Path "internal") -and 
    (Test-Path "cmd")
}

Check-Item "后端代码结构" {
    (Test-Path "internal/handlers/ticket_handler.go") -and
    (Test-Path "internal/services/wechat_service.go") -and
    (Test-Path "internal/models/ticket.go")
}

Check-Item "前端代码结构" {
    (Test-Path "frontend/src/views/tickets/TicketListView.vue") -and
    (Test-Path "frontend/src/views/tickets/TicketFormView.vue") -and
    (Test-Path "frontend/src/views/tickets/TicketDetailView.vue") -and
    (Test-Path "frontend/src/api/ticket.ts")
}

# 2. 检查配置文件
Check-Item "后端配置文件" {
    Test-Path "configs/config.yaml"
}

Check-Item "前端配置文件" {
    (Test-Path "frontend/package.json") -and
    (Test-Path "frontend/vite.config.ts")
}

# 3. 检查依赖
Check-Item "Go模块依赖" {
    $goModContent = Get-Content "go.mod" -Raw
    $goModContent -match "github.com/gin-gonic/gin" -and
    $goModContent -match "gorm.io/gorm"
}

Check-Item "前端依赖文件" {
    Test-Path "frontend/package.json"
}

# 4. 检查编译
Check-Item "后端编译检查" {
    $output = go build -o build/temp_server.exe ./cmd/server 2>&1
    $success = $LASTEXITCODE -eq 0
    if (Test-Path "build/temp_server.exe") {
        Remove-Item "build/temp_server.exe" -Force
    }
    return $success
}

# 5. 检查数据库迁移文件
Check-Item "数据库迁移文件" {
    (Test-Path "internal/database/migrations.go") -and
    (Get-Content "internal/database/migrations.go" -Raw) -match "Ticket"
}

# 6. 检查测试脚本
Check-Item "测试脚本" {
    (Test-Path "test/ticket_system_test.ps1") -and
    (Test-Path "test/wechat_notification_test.ps1") -and
    (Test-Path "test/ticket_system_integration_test.ps1")
}

# 7. 检查权限初始化脚本
Check-Item "权限初始化脚本" {
    (Test-Path "scripts/init-ticket-permissions.ps1") -and
    (Test-Path "scripts/init-ticket-permissions.sql")
}

# 8. 检查文档
Check-Item "文档完整性" {
    (Test-Path "docs/TICKET_SYSTEM_GUIDE.md") -and
    (Test-Path "docs/TICKET_SYSTEM_IMPLEMENTATION_REPORT.md") -and
    (Test-Path "docs/QUICK_START.md")
}

# 9. 检查服务状态（如果正在运行）
Check-Item "后端服务状态" {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 5
        return $true
    } catch {
        return $false
    }
} "warning"

Check-Item "前端服务状态" {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
} "warning"

# 10. 检查关键文件内容
Check-Item "工单模型定义" {
    $content = Get-Content "internal/models/ticket.go" -Raw
    $content -match "type Ticket struct" -and
    $content -match "TicketStatus" -and
    $content -match "TicketPriority"
}

Check-Item "工单API处理器" {
    $content = Get-Content "internal/handlers/ticket_handler.go" -Raw
    $content -match "GetTickets" -and
    $content -match "CreateTicket" -and
    $content -match "UpdateTicket"
}

Check-Item "前端工单API" {
    $content = Get-Content "frontend/src/api/ticket.ts" -Raw
    $content -match "getTickets" -and
    $content -match "createTicket" -and
    $content -match "updateTicket"
}

# 输出检查结果
Write-Host ""
Write-Host "=== 检查结果汇总 ===" -ForegroundColor Green
Write-Host "通过: $($checkResults.passed)" -ForegroundColor Green
Write-Host "失败: $($checkResults.failed)" -ForegroundColor Red
Write-Host "警告: $($checkResults.warnings)" -ForegroundColor Yellow
Write-Host "总计: $($checkResults.passed + $checkResults.failed + $checkResults.warnings)" -ForegroundColor Cyan

$totalChecks = $checkResults.passed + $checkResults.failed + $checkResults.warnings
$successRate = [math]::Round($checkResults.passed / $totalChecks * 100, 2)
Write-Host "成功率: $successRate%" -ForegroundColor Cyan

Write-Host ""
if ($checkResults.failed -eq 0) {
    Write-Host "🎉 系统检查完成！所有关键检查都通过了！" -ForegroundColor Green
    if ($checkResults.warnings -gt 0) {
        Write-Host "⚠️  有 $($checkResults.warnings) 个警告项，这些通常是服务未启动导致的，不影响系统功能。" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  发现 $($checkResults.failed) 个问题需要解决。" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "下一步操作建议:" -ForegroundColor Yellow
if ($checkResults.failed -eq 0) {
    Write-Host "1. 运行快速启动脚本: .\scripts\quick-start.ps1" -ForegroundColor Gray
    Write-Host "2. 初始化工单权限: .\scripts\init-ticket-permissions.ps1" -ForegroundColor Gray
    Write-Host "3. 运行集成测试: .\test\ticket_system_integration_test.ps1" -ForegroundColor Gray
} else {
    Write-Host "1. 解决上述失败的检查项" -ForegroundColor Gray
    Write-Host "2. 重新运行此检查脚本" -ForegroundColor Gray
    Write-Host "3. 查看相关文档获取帮助" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== 系统检查完成 ===" -ForegroundColor Green