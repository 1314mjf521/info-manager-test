# 快速启动脚本 - 一键启动前后端服务

Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║                        快速启动脚本                           ║
║                                                              ║
║  🚀 一键启动前后端服务                                        ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Green

# 检查必要文件
function Test-ProjectStructure {
    $requiredFiles = @(
        "go.mod",
        "frontend/package.json",
        "cmd/server/main.go"
    )
    
    $missing = @()
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            $missing += $file
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Host "❌ 缺少必要文件:" -ForegroundColor Red
        $missing | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
        return $false
    }
    
    Write-Host "✅ 项目结构检查通过" -ForegroundColor Green
    return $true
}

# 检查环境
function Test-Environment {
    Write-Host "`n🔍 检查开发环境..." -ForegroundColor Yellow
    
    # 检查Go
    try {
        $goVersion = & go version 2>$null
        Write-Host "✅ Go: $goVersion" -ForegroundColor Green
    } catch {
        Write-Host "❌ Go未安装" -ForegroundColor Red
        Write-Host "   请访问 https://golang.org 下载安装" -ForegroundColor Yellow
        return $false
    }
    
    # 检查Node.js
    try {
        $nodeVersion = & node --version 2>$null
        Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
    } catch {
        Write-Host "❌ Node.js未安装" -ForegroundColor Red
        Write-Host "   请访问 https://nodejs.org 下载安装" -ForegroundColor Yellow
        return $false
    }
    
    # 检查npm
    try {
        $npmVersion = & npm --version 2>$null
        Write-Host "✅ npm: $npmVersion" -ForegroundColor Green
    } catch {
        Write-Host "❌ npm未安装" -ForegroundColor Red
        return $false
    }
    
    return $true
}

# 停止现有服务
function Stop-Services {
    Write-Host "`n🛑 停止现有服务..." -ForegroundColor Yellow
    
    # 停止后端
    $backendProcesses = Get-Process -Name "info-management-system" -ErrorAction SilentlyContinue
    if ($backendProcesses) {
        $backendProcesses | Stop-Process -Force
        Write-Host "✅ 已停止后端服务" -ForegroundColor Green
    }
    
    # 停止前端 (查找运行在5173端口的Node进程)
    $nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
    if ($nodeProcesses) {
        # 这里简化处理，停止所有node进程（在实际环境中可能需要更精确的判断）
        Write-Host "⚠️  发现Node.js进程，如果有其他Node应用在运行，请手动处理" -ForegroundColor Yellow
    }
}

# 启动后端
function Start-Backend {
    Write-Host "`n🔧 启动后端服务..." -ForegroundColor Yellow
    
    # 编译后端
    Write-Host "   编译后端..." -ForegroundColor Gray
    & go build -o info-management-system.exe ./cmd/server
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ 后端编译失败" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✅ 后端编译成功" -ForegroundColor Green
    
    # 启动后端服务
    Write-Host "   启动后端服务..." -ForegroundColor Gray
    $backendJob = Start-Job -ScriptBlock {
        Set-Location $using:PWD
        & .\info-management-system.exe
    }
    
    # 等待后端启动
    Write-Host "   等待后端服务启动..." -ForegroundColor Gray
    $maxWait = 30
    $waited = 0
    
    do {
        Start-Sleep -Seconds 1
        $waited++
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 2 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ 后端服务启动成功 (http://localhost:8080)" -ForegroundColor Green
                return $true
            }
        } catch {
            # 继续等待
        }
    } while ($waited -lt $maxWait)
    
    Write-Host "❌ 后端服务启动超时" -ForegroundColor Red
    return $false
}

# 启动前端
function Start-Frontend {
    Write-Host "`n🎨 启动前端服务..." -ForegroundColor Yellow
    
    Push-Location frontend
    
    try {
        # 检查依赖
        if (-not (Test-Path "node_modules")) {
            Write-Host "   安装前端依赖..." -ForegroundColor Gray
            & npm install
            if ($LASTEXITCODE -ne 0) {
                Write-Host "❌ 前端依赖安装失败" -ForegroundColor Red
                return $false
            }
            Write-Host "✅ 前端依赖安装成功" -ForegroundColor Green
        } else {
            Write-Host "✅ 前端依赖已存在" -ForegroundColor Green
        }
        
        # 启动开发服务器
        Write-Host "   启动前端开发服务器..." -ForegroundColor Gray
        $frontendJob = Start-Job -ScriptBlock {
            Set-Location $using:PWD/frontend
            & npm run dev -- --port 5173 --host 0.0.0.0
        }
        
        # 等待前端启动
        Write-Host "   等待前端服务启动..." -ForegroundColor Gray
        Start-Sleep -Seconds 5
        
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:5173" -TimeoutSec 5 -ErrorAction Stop
            Write-Host "✅ 前端服务启动成功 (http://localhost:5173)" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "⚠️  前端服务可能仍在启动中..." -ForegroundColor Yellow
            return $true
        }
        
    } finally {
        Pop-Location
    }
}

# 显示启动信息
function Show-StartupInfo {
    Write-Host "`n" + "="*60 -ForegroundColor Cyan
    Write-Host "🎉 服务启动完成！" -ForegroundColor Green
    Write-Host "="*60 -ForegroundColor Cyan
    
    Write-Host "`n📱 访问地址:" -ForegroundColor Yellow
    Write-Host "   前端应用: http://localhost:5173" -ForegroundColor White
    Write-Host "   后端API: http://localhost:8080" -ForegroundColor White
    Write-Host "   API文档: http://localhost:8080/swagger/index.html" -ForegroundColor White
    Write-Host "   健康检查: http://localhost:8080/api/v1/health" -ForegroundColor White
    
    Write-Host "`n🔗 快速链接:" -ForegroundColor Yellow
    Write-Host "   登录页面: http://localhost:5173/login" -ForegroundColor White
    Write-Host "   文件管理: http://localhost:5173/files" -ForegroundColor White
    Write-Host "   工单管理: http://localhost:5173/tickets" -ForegroundColor White
    Write-Host "   测试页面: http://localhost:5173/test-file-download.html" -ForegroundColor White
    
    Write-Host "`n🛠️  管理命令:" -ForegroundColor Yellow
    Write-Host "   查看后端日志: Get-Job | Receive-Job" -ForegroundColor White
    Write-Host "   停止所有服务: Get-Job | Stop-Job; Get-Process -Name 'info-management-system' | Stop-Process" -ForegroundColor White
    Write-Host "   重新启动: .\scripts\quick-start.ps1" -ForegroundColor White
    
    Write-Host "`n💡 提示:" -ForegroundColor Yellow
    Write-Host "   - 前端支持热重载，修改代码会自动刷新" -ForegroundColor White
    Write-Host "   - 后端修改需要重新编译和启动" -ForegroundColor White
    Write-Host "   - 关闭此窗口不会停止服务" -ForegroundColor White
    Write-Host "   - 使用上面的停止命令来停止服务" -ForegroundColor White
    
    Write-Host "`n按任意键退出..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# 主执行流程
function Main {
    # 检查项目结构
    if (-not (Test-ProjectStructure)) {
        Write-Host "`n❌ 项目结构检查失败，请确保在项目根目录运行此脚本" -ForegroundColor Red
        return $false
    }
    
    # 检查环境
    if (-not (Test-Environment)) {
        Write-Host "`n❌ 环境检查失败，请安装必要的开发工具" -ForegroundColor Red
        return $false
    }
    
    # 停止现有服务
    Stop-Services
    
    # 启动后端
    if (-not (Start-Backend)) {
        Write-Host "`n❌ 后端启动失败" -ForegroundColor Red
        return $false
    }
    
    # 启动前端
    if (-not (Start-Frontend)) {
        Write-Host "`n❌ 前端启动失败" -ForegroundColor Red
        return $false
    }
    
    # 显示启动信息
    Show-StartupInfo
    
    return $true
}

# 错误处理
try {
    if (Main) {
        Write-Host "`n✅ 快速启动完成" -ForegroundColor Green
    } else {
        Write-Host "`n❌ 快速启动失败" -ForegroundColor Red
        Write-Host "请检查错误信息并重试，或使用详细的部署脚本:" -ForegroundColor Yellow
        Write-Host ".\scripts\full-stack-deploy.ps1 -Mode dev" -ForegroundColor White
    }
} catch {
    Write-Host "`n💥 执行过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "请检查错误信息并重试" -ForegroundColor Yellow
}