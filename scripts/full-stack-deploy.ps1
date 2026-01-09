# 全栈应用一键部署脚本

param(
    [string]$Mode = "dev",           # dev, prod, test
    [int]$BackendPort = 8080,
    [int]$FrontendPort = 5173,
    [switch]$SkipBackend,            # 跳过后端部署
    [switch]$SkipFrontend,           # 跳过前端部署
    [switch]$Clean,                  # 清理所有缓存和构建文件
    [switch]$Force,                  # 强制重新安装/编译
    [switch]$Background              # 后台运行服务
)

Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║                    全栈应用一键部署脚本                        ║
║                                                              ║
║  模式: $Mode | 后端端口: $BackendPort | 前端端口: $FrontendPort                    ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# 全局变量
$script:BackendProcess = $null
$script:FrontendProcess = $null
$script:DeploymentLog = @()

# 日志函数
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    $script:DeploymentLog += $logEntry
    
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN"  { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry -ForegroundColor White }
    }
}

# 检查系统环境
function Test-SystemEnvironment {
    Write-Log "检查系统环境..." "INFO"
    
    # 检查PowerShell版本
    $psVersion = $PSVersionTable.PSVersion
    Write-Log "PowerShell版本: $psVersion" "INFO"
    
    # 检查操作系统
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    Write-Log "操作系统: $($os.Caption)" "INFO"
    
    # 检查可用内存
    $memory = Get-CimInstance -ClassName Win32_ComputerSystem
    $totalMemoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
    Write-Log "总内存: ${totalMemoryGB}GB" "INFO"
    
    # 检查磁盘空间
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 -and $_.DeviceID -eq "C:" }
    $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    Write-Log "C盘可用空间: ${freeSpaceGB}GB" "INFO"
    
    if ($freeSpaceGB -lt 2) {
        Write-Log "磁盘空间不足，建议至少保留2GB空间" "WARN"
    }
    
    return $true
}

# 检查端口可用性
function Test-PortAvailability {
    param([int]$Port, [string]$ServiceName)
    
    try {
        $connection = Test-NetConnection -ComputerName "localhost" -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($connection) {
            Write-Log "端口 $Port ($ServiceName) 已被占用" "WARN"
            return $false
        } else {
            Write-Log "端口 $Port ($ServiceName) 可用" "SUCCESS"
            return $true
        }
    } catch {
        Write-Log "端口 $Port ($ServiceName) 可用" "SUCCESS"
        return $true
    }
}

# 停止现有服务
function Stop-ExistingServices {
    Write-Log "停止现有服务..." "INFO"
    
    # 停止后端服务
    $backendProcesses = Get-Process -Name "info-management-system" -ErrorAction SilentlyContinue
    if ($backendProcesses) {
        Write-Log "停止 $($backendProcesses.Count) 个后端进程..." "INFO"
        $backendProcesses | Stop-Process -Force
        Start-Sleep -Seconds 2
        Write-Log "后端服务已停止" "SUCCESS"
    }
    
    # 停止可能的Node.js进程（前端）
    $nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*vite*" -or $_.CommandLine -like "*dev*" -or $_.CommandLine -like "*serve*"
    }
    if ($nodeProcesses) {
        Write-Log "停止 $($nodeProcesses.Count) 个前端进程..." "INFO"
        $nodeProcesses | Stop-Process -Force
        Start-Sleep -Seconds 2
        Write-Log "前端服务已停止" "SUCCESS"
    }
}

# 清理环境
function Clear-Environment {
    if (-not $Clean) { return }
    
    Write-Log "清理环境..." "INFO"
    
    # 清理后端构建文件
    if (Test-Path "info-management-system.exe") {
        Write-Log "清理后端可执行文件..." "INFO"
        Remove-Item "info-management-system.exe" -Force -ErrorAction SilentlyContinue
    }
    
    # 清理前端
    if (Test-Path "frontend") {
        Push-Location "frontend"
        
        if (Test-Path "dist") {
            Write-Log "清理前端构建文件..." "INFO"
            Remove-Item -Recurse -Force "dist" -ErrorAction SilentlyContinue
        }
        
        if (Test-Path "node_modules" -and $Force) {
            Write-Log "清理前端依赖..." "INFO"
            Remove-Item -Recurse -Force "node_modules" -ErrorAction SilentlyContinue
        }
        
        Pop-Location
    }
    
    Write-Log "环境清理完成" "SUCCESS"
}

# 部署后端
function Deploy-Backend {
    if ($SkipBackend) {
        Write-Log "跳过后端部署" "INFO"
        return $true
    }
    
    Write-Log "开始部署后端..." "INFO"
    
    # 检查Go环境
    try {
        $goVersion = & go version 2>$null
        Write-Log "Go版本: $goVersion" "INFO"
    } catch {
        Write-Log "Go未安装或不在PATH中" "ERROR"
        return $false
    }
    
    # 编译后端
    Write-Log "编译后端服务..." "INFO"
    try {
        & go build -o info-management-system.exe ./cmd/server
        if ($LASTEXITCODE -eq 0) {
            Write-Log "后端编译成功" "SUCCESS"
        } else {
            throw "编译失败，退出代码: $LASTEXITCODE"
        }
    } catch {
        Write-Log "后端编译失败: $($_.Exception.Message)" "ERROR"
        return $false
    }
    
    # 启动后端服务
    Write-Log "启动后端服务..." "INFO"
    try {
        if ($Background) {
            $script:BackendProcess = Start-Process -FilePath ".\info-management-system.exe" -PassThru -WindowStyle Hidden
            Write-Log "后端服务已在后台启动 (PID: $($script:BackendProcess.Id))" "SUCCESS"
        } else {
            Write-Log "后端服务将在前台运行，请在新终端窗口中运行前端部署" "INFO"
            & .\info-management-system.exe
        }
        
        # 等待服务启动
        Write-Log "等待后端服务启动..." "INFO"
        $maxRetries = 30
        $retryCount = 0
        
        do {
            Start-Sleep -Seconds 1
            $retryCount++
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:$BackendPort/api/v1/health" -TimeoutSec 2 -ErrorAction Stop
                if ($response.StatusCode -eq 200) {
                    Write-Log "后端服务启动成功" "SUCCESS"
                    return $true
                }
            } catch {
                # 继续等待
            }
        } while ($retryCount -lt $maxRetries)
        
        Write-Log "后端服务启动超时" "ERROR"
        return $false
        
    } catch {
        Write-Log "后端服务启动失败: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# 部署前端
function Deploy-Frontend {
    if ($SkipFrontend) {
        Write-Log "跳过前端部署" "INFO"
        return $true
    }
    
    Write-Log "开始部署前端..." "INFO"
    
    # 检查Node.js环境
    try {
        $nodeVersion = & node --version 2>$null
        $npmVersion = & npm --version 2>$null
        Write-Log "Node.js版本: $nodeVersion" "INFO"
        Write-Log "npm版本: $npmVersion" "INFO"
    } catch {
        Write-Log "Node.js或npm未安装" "ERROR"
        return $false
    }
    
    # 检查前端目录
    if (-not (Test-Path "frontend/package.json")) {
        Write-Log "前端项目不存在" "ERROR"
        return $false
    }
    
    Push-Location "frontend"
    
    try {
        # 安装依赖
        if ($Force -or -not (Test-Path "node_modules")) {
            Write-Log "安装前端依赖..." "INFO"
            & npm install
            if ($LASTEXITCODE -ne 0) {
                throw "依赖安装失败"
            }
            Write-Log "前端依赖安装成功" "SUCCESS"
        } else {
            Write-Log "前端依赖已存在，跳过安装" "INFO"
        }
        
        # 根据模式执行不同操作
        switch ($Mode.ToLower()) {
            "dev" {
                Write-Log "启动前端开发服务器..." "INFO"
                if ($Background) {
                    $script:FrontendProcess = Start-Process -FilePath "npm" -ArgumentList "run", "dev", "--", "--port", $FrontendPort, "--host", "0.0.0.0" -PassThru -WindowStyle Hidden
                    Write-Log "前端开发服务器已在后台启动 (PID: $($script:FrontendProcess.Id))" "SUCCESS"
                } else {
                    Write-Log "前端开发服务器将在前台运行" "INFO"
                    & npm run dev -- --port $FrontendPort --host 0.0.0.0
                }
            }
            "prod" {
                Write-Log "构建前端生产版本..." "INFO"
                & npm run build
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "前端构建成功" "SUCCESS"
                    
                    # 启动预览服务器
                    Write-Log "启动前端预览服务器..." "INFO"
                    if ($Background) {
                        $script:FrontendProcess = Start-Process -FilePath "npm" -ArgumentList "run", "preview", "--", "--port", $FrontendPort, "--host", "0.0.0.0" -PassThru -WindowStyle Hidden
                        Write-Log "前端预览服务器已在后台启动 (PID: $($script:FrontendProcess.Id))" "SUCCESS"
                    } else {
                        & npm run preview -- --port $FrontendPort --host 0.0.0.0
                    }
                } else {
                    throw "前端构建失败"
                }
            }
            "test" {
                Write-Log "运行前端测试..." "INFO"
                & npm run test
            }
        }
        
        return $true
        
    } catch {
        Write-Log "前端部署失败: $($_.Exception.Message)" "ERROR"
        return $false
    } finally {
        Pop-Location
    }
}

# 验证部署
function Test-Deployment {
    Write-Log "验证部署状态..." "INFO"
    
    $allGood = $true
    
    # 检查后端
    if (-not $SkipBackend) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$BackendPort/api/v1/health" -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Log "✓ 后端服务正常 (http://localhost:$BackendPort)" "SUCCESS"
            } else {
                throw "HTTP $($response.StatusCode)"
            }
        } catch {
            Write-Log "✗ 后端服务异常: $($_.Exception.Message)" "ERROR"
            $allGood = $false
        }
    }
    
    # 检查前端
    if (-not $SkipFrontend) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$FrontendPort" -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Log "✓ 前端服务正常 (http://localhost:$FrontendPort)" "SUCCESS"
            } else {
                throw "HTTP $($response.StatusCode)"
            }
        } catch {
            Write-Log "✗ 前端服务异常: $($_.Exception.Message)" "ERROR"
            $allGood = $false
        }
    }
    
    return $allGood
}

# 显示部署信息
function Show-DeploymentInfo {
    Write-Host "`n" + "="*60 -ForegroundColor Cyan
    Write-Host "部署完成信息" -ForegroundColor Green
    Write-Host "="*60 -ForegroundColor Cyan
    
    if (-not $SkipBackend) {
        Write-Host "🔧 后端服务:" -ForegroundColor Yellow
        Write-Host "   地址: http://localhost:$BackendPort" -ForegroundColor White
        Write-Host "   API文档: http://localhost:$BackendPort/swagger/index.html" -ForegroundColor White
        Write-Host "   健康检查: http://localhost:$BackendPort/api/v1/health" -ForegroundColor White
        if ($script:BackendProcess) {
            Write-Host "   进程ID: $($script:BackendProcess.Id)" -ForegroundColor Gray
        }
    }
    
    if (-not $SkipFrontend) {
        Write-Host "`n🎨 前端服务:" -ForegroundColor Yellow
        Write-Host "   地址: http://localhost:$FrontendPort" -ForegroundColor White
        Write-Host "   模式: $Mode" -ForegroundColor White
        if ($script:FrontendProcess) {
            Write-Host "   进程ID: $($script:FrontendProcess.Id)" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n📋 快速链接:" -ForegroundColor Yellow
    Write-Host "   主页: http://localhost:$FrontendPort" -ForegroundColor White
    Write-Host "   登录: http://localhost:$FrontendPort/login" -ForegroundColor White
    Write-Host "   文件管理: http://localhost:$FrontendPort/files" -ForegroundColor White
    Write-Host "   工单管理: http://localhost:$FrontendPort/tickets" -ForegroundColor White
    Write-Host "   测试页面: http://localhost:$FrontendPort/test-file-download.html" -ForegroundColor White
    
    Write-Host "`n🛠️ 管理命令:" -ForegroundColor Yellow
    Write-Host "   停止所有服务: Get-Process -Name 'info-management-system','node' | Stop-Process" -ForegroundColor White
    Write-Host "   查看后端日志: Get-Content logs/app.log -Wait" -ForegroundColor White
    Write-Host "   重新部署: .\scripts\full-stack-deploy.ps1 -Force" -ForegroundColor White
    
    if ($Background) {
        Write-Host "`n⚠️  服务运行在后台，关闭此窗口不会停止服务" -ForegroundColor Yellow
        Write-Host "   要停止服务，请运行上面的停止命令" -ForegroundColor Yellow
    }
}

# 清理函数
function Cleanup {
    if ($script:BackendProcess -and -not $script:BackendProcess.HasExited) {
        Write-Log "清理后端进程..." "INFO"
        $script:BackendProcess.Kill()
    }
    
    if ($script:FrontendProcess -and -not $script:FrontendProcess.HasExited) {
        Write-Log "清理前端进程..." "INFO"
        $script:FrontendProcess.Kill()
    }
}

# 信号处理
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Cleanup
}

# 主执行流程
function Main {
    try {
        # 系统检查
        Test-SystemEnvironment
        
        # 端口检查
        if (-not $SkipBackend) {
            Test-PortAvailability -Port $BackendPort -ServiceName "后端"
        }
        if (-not $SkipFrontend) {
            Test-PortAvailability -Port $FrontendPort -ServiceName "前端"
        }
        
        # 停止现有服务
        Stop-ExistingServices
        
        # 清理环境
        Clear-Environment
        
        # 部署后端
        if (-not (Deploy-Backend)) {
            Write-Log "后端部署失败，停止部署" "ERROR"
            return $false
        }
        
        # 部署前端
        if (-not (Deploy-Frontend)) {
            Write-Log "前端部署失败" "ERROR"
            if (-not $SkipBackend) {
                Write-Log "但后端服务仍在运行" "INFO"
            }
            return $false
        }
        
        # 验证部署
        Start-Sleep -Seconds 3
        if (Test-Deployment) {
            Write-Log "全栈部署成功！" "SUCCESS"
            Show-DeploymentInfo
            return $true
        } else {
            Write-Log "部署验证失败" "ERROR"
            return $false
        }
        
    } catch {
        Write-Log "部署过程中发生错误: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# 显示帮助
function Show-Help {
    Write-Host @"
全栈应用一键部署脚本

用法:
    .\scripts\full-stack-deploy.ps1 [参数]

参数:
    -Mode <模式>          部署模式 (dev|prod|test)，默认: dev
    -BackendPort <端口>   后端端口，默认: 8080
    -FrontendPort <端口>  前端端口，默认: 5173
    -SkipBackend         跳过后端部署
    -SkipFrontend        跳过前端部署
    -Clean               清理所有缓存和构建文件
    -Force               强制重新安装/编译
    -Background          后台运行服务

模式说明:
    dev                  开发模式 (前端热重载)
    prod                 生产模式 (构建优化版本)
    test                 测试模式

示例:
    .\scripts\full-stack-deploy.ps1                                    # 开发模式
    .\scripts\full-stack-deploy.ps1 -Mode prod                         # 生产模式
    .\scripts\full-stack-deploy.ps1 -SkipBackend                       # 只部署前端
    .\scripts\full-stack-deploy.ps1 -Clean -Force                      # 清理重建
    .\scripts\full-stack-deploy.ps1 -Background                        # 后台运行

"@ -ForegroundColor White
}

# 参数处理
if ($args -contains "-Help" -or $args -contains "--help" -or $args -contains "-h") {
    Show-Help
    exit 0
}

# 执行部署
if (Main) {
    Write-Log "部署脚本执行完成" "SUCCESS"
    exit 0
} else {
    Write-Log "部署脚本执行失败" "ERROR"
    exit 1
}