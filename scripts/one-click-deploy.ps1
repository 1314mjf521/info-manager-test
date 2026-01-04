# 信息管理系统一键部署脚本 (Windows PowerShell)

param(
    [string]$InstallPath = "C:\InfoManagement",
    [string]$ServiceName = "InfoManagementSystem",
    [switch]$SkipGo,
    [switch]$Help
)

# 显示帮助信息
if ($Help) {
    Write-Host @"
信息管理系统一键部署脚本

用法:
    .\one-click-deploy.ps1 [参数]

参数:
    -InstallPath <路径>    安装目录 (默认: C:\InfoManagement)
    -ServiceName <名称>    服务名称 (默认: InfoManagementSystem)
    -SkipGo               跳过Go安装检查
    -Help                 显示此帮助信息

示例:
    .\one-click-deploy.ps1
    .\one-click-deploy.ps1 -InstallPath "D:\Apps\InfoManagement"
    .\one-click-deploy.ps1 -SkipGo
"@
    exit 0
}

# 颜色函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $colors = @{
        "Red" = "Red"
        "Green" = "Green"
        "Yellow" = "Yellow"
        "Blue" = "Blue"
        "Magenta" = "Magenta"
        "Cyan" = "Cyan"
        "White" = "White"
    }
    
    Write-Host $Message -ForegroundColor $colors[$Color]
}

function Log-Info {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Blue"
}

function Log-Success {
    param([string]$Message)
    Write-ColorOutput "[SUCCESS] $Message" "Green"
}

function Log-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

function Log-Error {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

function Log-Step {
    param([string]$Message)
    Write-ColorOutput "[STEP] $Message" "Magenta"
}

# 检查管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 检查系统要求
function Test-SystemRequirements {
    Log-Step "检查系统要求..."
    
    # 检查Windows版本
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        Log-Warning "建议使用Windows 10或更高版本，当前版本: $($osVersion.ToString())"
    } else {
        Log-Success "操作系统版本检查通过: Windows $($osVersion.ToString())"
    }
    
    # 检查内存
    $memory = Get-CimInstance -ClassName Win32_ComputerSystem
    $memoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
    
    if ($memoryGB -lt 0.5) {
        Log-Error "内存不足 512MB，当前: ${memoryGB}GB"
        exit 1
    } else {
        Log-Success "内存检查通过: ${memoryGB}GB"
    }
    
    # 检查磁盘空间
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
    $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    
    if ($freeSpaceGB -lt 1) {
        Log-Error "C盘空间不足 1GB，当前可用: ${freeSpaceGB}GB"
        exit 1
    } else {
        Log-Success "磁盘空间检查通过: ${freeSpaceGB}GB 可用"
    }
}

# 安装Chocolatey
function Install-Chocolatey {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Log-Step "安装Chocolatey包管理器..."
        
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Log-Success "Chocolatey安装完成"
    } else {
        Log-Info "Chocolatey已安装"
    }
}

# 安装Git
function Install-Git {
    if (!(Get-Command git -ErrorAction SilentlyContinue)) {
        Log-Step "安装Git..."
        choco install git -y
        
        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Log-Success "Git安装完成"
    } else {
        Log-Info "Git已安装"
    }
}

# 安装Go
function Install-Go {
    if ($SkipGo) {
        Log-Info "跳过Go安装检查"
        return
    }
    
    Log-Step "检查Go环境..."
    
    $goInstalled = $false
    $goVersion = ""
    
    try {
        $goVersionOutput = go version 2>$null
        if ($goVersionOutput) {
            $goVersion = ($goVersionOutput -split " ")[2] -replace "go", ""
            Log-Info "检测到Go版本: $goVersion"
            
            # 简单版本比较
            $versionParts = $goVersion -split "\."
            $majorVersion = [int]$versionParts[0]
            $minorVersion = [int]$versionParts[1]
            
            if ($majorVersion -gt 1 -or ($majorVersion -eq 1 -and $minorVersion -ge 19)) {
                Log-Success "Go版本满足要求"
                $goInstalled = $true
            } else {
                Log-Warning "Go版本过低，需要升级"
            }
        }
    } catch {
        Log-Info "未检测到Go，需要安装"
    }
    
    if (!$goInstalled) {
        Log-Step "安装Go..."
        choco install golang -y
        
        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Log-Success "Go安装完成"
    }
}

# 创建安装目录
function New-InstallDirectory {
    Log-Step "创建安装目录..."
    
    $directories = @(
        $InstallPath,
        "$InstallPath\build",
        "$InstallPath\configs",
        "$InstallPath\data",
        "$InstallPath\logs",
        "$InstallPath\uploads"
    )
    
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Log-Info "创建目录: $dir"
        }
    }
    
    Log-Success "安装目录创建完成: $InstallPath"
}

# 下载或复制源码
function Get-SourceCode {
    Log-Step "获取源码..."
    
    $currentDir = Get-Location
    
    if ((Test-Path "go.mod") -and (Test-Path "cmd\server\main.go")) {
        Log-Info "检测到当前目录为项目目录"
        $script:ProjectDir = $currentDir.Path
    } else {
        Log-Info "下载项目源码..."
        $tempDir = "$env:TEMP\info-management-system"
        
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
        
        # 这里需要替换为实际的Git仓库地址
        git clone https://github.com/your-repo/info-management-system.git $tempDir
        $script:ProjectDir = $tempDir
    }
    
    Log-Success "源码准备完成: $ProjectDir"
}

# 编译应用
function Build-Application {
    Log-Step "编译应用..."
    
    Push-Location $ProjectDir
    
    try {
        # 下载依赖
        Log-Info "下载Go依赖..."
        go mod download
        
        if ($LASTEXITCODE -ne 0) {
            throw "依赖下载失败"
        }
        
        # 编译
        Log-Info "编译应用..."
        $env:CGO_ENABLED = "1"
        go build -ldflags "-s -w" -o "build\server.exe" "cmd\server\main.go"
        
        if ($LASTEXITCODE -ne 0) {
            throw "编译失败"
        }
        
        if (!(Test-Path "build\server.exe")) {
            throw "编译产物不存在"
        }
        
        Log-Success "编译完成"
    } catch {
        Log-Error "编译失败: $_"
        exit 1
    } finally {
        Pop-Location
    }
}

# 安装应用文件
function Install-Application {
    Log-Step "安装应用文件..."
    
    # 复制二进制文件
    Copy-Item "$ProjectDir\build\server.exe" "$InstallPath\build\" -Force
    Log-Info "复制二进制文件完成"
    
    # 复制或创建配置文件
    $configSource = ""
    if (Test-Path "$ProjectDir\configs\config.example.yaml") {
        $configSource = "$ProjectDir\configs\config.example.yaml"
    } elseif (Test-Path "$ProjectDir\configs\config.yaml") {
        $configSource = "$ProjectDir\configs\config.yaml"
    }
    
    if ($configSource) {
        Copy-Item $configSource "$InstallPath\configs\config.yaml" -Force
        Log-Info "复制配置文件完成"
    } else {
        New-DefaultConfig
    }
    
    Log-Success "应用文件安装完成"
}

# 创建默认配置文件
function New-DefaultConfig {
    Log-Info "创建默认配置文件..."
    
    $jwtSecret = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([System.Guid]::NewGuid().ToString()))
    
    $configContent = @"
# 信息管理系统配置文件

server:
  port: "8080"
  mode: "release"

database:
  driver: "sqlite"
  sqlite:
    path: "data/info_system.db"
    journal_mode: "WAL"
    busy_timeout: 30000
    cache_size: -64000
    synchronous: "NORMAL"
    temp_store: "MEMORY"
    max_open_conns: 1
    max_idle_conns: 1
    conn_max_lifetime: "1h"
    conn_max_idle_time: "30m"

jwt:
  secret: "$jwtSecret"
  expire_time: 24

log:
  level: "info"
  format: "json"
  output: "both"
  file_path: "logs/app.log"
  max_size: 100
  max_backups: 10
  max_age: 30
  compress: true
"@
    
    $configContent | Out-File -FilePath "$InstallPath\configs\config.yaml" -Encoding UTF8
    Log-Success "默认配置文件创建完成"
}

# 创建Windows服务
function New-WindowsService {
    Log-Step "创建Windows服务..."
    
    # 检查服务是否已存在
    $existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($existingService) {
        Log-Info "服务已存在，停止并删除旧服务..."
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        sc.exe delete $ServiceName
        Start-Sleep -Seconds 2
    }
    
    # 创建服务
    $servicePath = "$InstallPath\build\server.exe"
    $serviceDescription = "Info Management System - 信息管理系统"
    
    sc.exe create $ServiceName binPath= "`"$servicePath`"" start= auto DisplayName= "Info Management System" obj= "LocalSystem"
    
    if ($LASTEXITCODE -eq 0) {
        # 设置服务描述
        sc.exe description $ServiceName "$serviceDescription"
        
        # 设置服务工作目录
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
        if (Test-Path $regPath) {
            Set-ItemProperty -Path $regPath -Name "ImagePath" -Value "`"$servicePath`""
            # 注意：Windows服务的工作目录需要通过其他方式设置
        }
        
        Log-Success "Windows服务创建完成"
    } else {
        Log-Error "Windows服务创建失败"
        exit 1
    }
}

# 配置防火墙
function Set-FirewallRule {
    Log-Step "配置防火墙..."
    
    try {
        # 检查防火墙规则是否已存在
        $existingRule = Get-NetFirewallRule -DisplayName "Info Management System" -ErrorAction SilentlyContinue
        if ($existingRule) {
            Log-Info "防火墙规则已存在"
        } else {
            # 创建防火墙规则
            New-NetFirewallRule -DisplayName "Info Management System" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow
            Log-Success "防火墙规则创建完成"
        }
    } catch {
        Log-Warning "防火墙配置失败，请手动开放8080端口: $_"
    }
}

# 启动服务
function Start-ApplicationService {
    Log-Step "启动服务..."
    
    try {
        Start-Service -Name $ServiceName
        Start-Sleep -Seconds 3
        
        $service = Get-Service -Name $ServiceName
        if ($service.Status -eq "Running") {
            Log-Success "服务启动成功"
        } else {
            Log-Error "服务启动失败，状态: $($service.Status)"
            exit 1
        }
    } catch {
        Log-Error "服务启动失败: $_"
        exit 1
    }
}

# 健康检查
function Test-ApplicationHealth {
    Log-Step "执行健康检查..."
    
    $maxAttempts = 30
    $attempt = 1
    
    while ($attempt -le $maxAttempts) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 5 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Log-Success "健康检查通过"
                return $true
            }
        } catch {
            # 忽略错误，继续尝试
        }
        
        Log-Info "等待服务启动... ($attempt/$maxAttempts)"
        Start-Sleep -Seconds 2
        $attempt++
    }
    
    Log-Error "健康检查失败，服务可能未正常启动"
    return $false
}

# 显示部署结果
function Show-DeploymentResult {
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Green
    Log-Success "🎉 部署完成！"
    Write-Host "==================================" -ForegroundColor Green
    Write-Host ""
    
    Log-Info "服务信息:"
    Write-Host "  - 安装目录: $InstallPath"
    Write-Host "  - 配置文件: $InstallPath\configs\config.yaml"
    Write-Host "  - 日志文件: $InstallPath\logs\app.log"
    Write-Host "  - 数据目录: $InstallPath\data"
    Write-Host ""
    
    Log-Info "访问地址:"
    Write-Host "  - 本地访问: http://localhost:8080"
    Write-Host "  - 健康检查: http://localhost:8080/health"
    Write-Host ""
    
    Log-Info "默认账号:"
    Write-Host "  - 用户名: admin"
    Write-Host "  - 密码: admin123"
    Write-Host ""
    
    Log-Info "服务管理命令:"
    Write-Host "  - 启动服务: Start-Service -Name $ServiceName"
    Write-Host "  - 停止服务: Stop-Service -Name $ServiceName"
    Write-Host "  - 重启服务: Restart-Service -Name $ServiceName"
    Write-Host "  - 查看状态: Get-Service -Name $ServiceName"
    Write-Host "  - 查看日志: Get-Content $InstallPath\logs\app.log -Tail 50 -Wait"
    Write-Host ""
    
    Log-Info "配置文件位置: $InstallPath\configs\config.yaml"
    Log-Info "如需修改配置，请编辑配置文件后重启服务"
    Write-Host ""
    
    Log-Warning "重要提示:"
    Write-Host "  1. 请及时修改默认密码"
    Write-Host "  2. 生产环境请配置HTTPS"
    Write-Host "  3. 定期备份数据目录"
    Write-Host "  4. 监控日志文件大小"
    Write-Host ""
}

# 主函数
function Main {
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "🚀 信息管理系统一键部署脚本 (Windows)" -ForegroundColor Cyan
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host ""
    
    # 检查管理员权限
    if (!(Test-Administrator)) {
        Log-Error "请以管理员身份运行此脚本"
        Log-Info "右键点击PowerShell，选择'以管理员身份运行'"
        exit 1
    }
    
    try {
        # 检查系统要求
        Test-SystemRequirements
        
        # 安装Chocolatey
        Install-Chocolatey
        
        # 安装Git
        Install-Git
        
        # 安装Go
        Install-Go
        
        # 创建安装目录
        New-InstallDirectory
        
        # 获取源码
        Get-SourceCode
        
        # 编译应用
        Build-Application
        
        # 安装应用
        Install-Application
        
        # 创建Windows服务
        New-WindowsService
        
        # 配置防火墙
        Set-FirewallRule
        
        # 启动服务
        Start-ApplicationService
        
        # 健康检查
        if (Test-ApplicationHealth) {
            Show-DeploymentResult
        } else {
            Log-Error "部署可能存在问题，请检查日志"
            Log-Info "日志位置: $InstallPath\logs\app.log"
            exit 1
        }
        
    } catch {
        Log-Error "部署失败: $_"
        exit 1
    }
}

# 错误处理
$ErrorActionPreference = "Stop"

# 运行主函数
Main