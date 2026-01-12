# Windows 依赖安装脚本
# 使用 Chocolatey 包管理器

param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipChocolatey,
    
    [Parameter(Mandatory=$false)]
    [switch]$DevOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

# 颜色函数
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Info { param([string]$Message); Write-ColorOutput "[INFO] $Message" "Blue" }
function Write-Success { param([string]$Message); Write-ColorOutput "[SUCCESS] $Message" "Green" }
function Write-Warning { param([string]$Message); Write-ColorOutput "[WARNING] $Message" "Yellow" }
function Write-Error { param([string]$Message); Write-ColorOutput "[ERROR] $Message" "Red" }
function Write-Header { 
    param([string]$Message)
    Write-Host ""
    Write-ColorOutput "================================" "Blue"
    Write-ColorOutput $Message "Blue"
    Write-ColorOutput "================================" "Blue"
}

# 显示帮助信息
function Show-Help {
    @"
Windows 依赖安装脚本

用法: .\install-dependencies.ps1 [参数]

参数:
    -SkipChocolatey     跳过 Chocolatey 安装
    -DevOnly           仅安装开发环境依赖
    -Help              显示帮助信息

说明:
    此脚本会自动安装项目所需的所有依赖，包括：
    - Chocolatey 包管理器
    - Node.js 和 npm
    - Go 语言
    - Git
    - Docker Desktop (可选)
    - PostgreSQL (可选)
    - Redis (可选)

示例:
    .\install-dependencies.ps1
    .\install-dependencies.ps1 -DevOnly
    .\install-dependencies.ps1 -SkipChocolatey

"@
}

# 检查管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 安装 Chocolatey
function Install-Chocolatey {
    if ($SkipChocolatey) {
        Write-Info "跳过 Chocolatey 安装"
        return
    }
    
    Write-Header "安装 Chocolatey 包管理器"
    
    # 检查是否已安装
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Info "Chocolatey 已安装"
        return
    }
    
    try {
        # 设置执行策略
        Set-ExecutionPolicy Bypass -Scope Process -Force
        
        # 下载并安装 Chocolatey
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Write-Success "Chocolatey 安装完成"
    }
    catch {
        Write-Error "Chocolatey 安装失败: $_"
        Write-Info "请手动安装 Chocolatey: https://chocolatey.org/install"
        exit 1
    }
}

# 安装包
function Install-Package {
    param(
        [string]$PackageName,
        [string]$DisplayName = $PackageName,
        [string]$CheckCommand = $PackageName
    )
    
    Write-Info "检查 $DisplayName..."
    
    # 检查是否已安装
    if (Get-Command $CheckCommand -ErrorAction SilentlyContinue) {
        Write-Info "$DisplayName 已安装"
        return $true
    }
    
    Write-Info "安装 $DisplayName..."
    
    try {
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            choco install $PackageName -y
        } else {
            Write-Warning "Chocolatey 未安装，请手动安装 $DisplayName"
            return $false
        }
        
        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # 验证安装
        if (Get-Command $CheckCommand -ErrorAction SilentlyContinue) {
            Write-Success "$DisplayName 安装完成"
            return $true
        } else {
            Write-Error "$DisplayName 安装失败"
            return $false
        }
    }
    catch {
        Write-Error "$DisplayName 安装失败: $_"
        return $false
    }
}

# 安装开发工具
function Install-DevTools {
    Write-Header "安装开发工具"
    
    $tools = @(
        @{ Package = "git"; Display = "Git"; Check = "git" },
        @{ Package = "nodejs"; Display = "Node.js"; Check = "node" },
        @{ Package = "go"; Display = "Go"; Check = "go" }
    )
    
    foreach ($tool in $tools) {
        Install-Package -PackageName $tool.Package -DisplayName $tool.Display -CheckCommand $tool.Check
    }
}

# 安装数据库和缓存
function Install-Databases {
    if ($DevOnly) {
        Write-Info "开发模式，跳过数据库安装"
        return
    }
    
    Write-Header "安装数据库和缓存"
    
    # PostgreSQL
    Write-Info "检查 PostgreSQL..."
    if (-not (Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue)) {
        Write-Info "安装 PostgreSQL..."
        try {
            choco install postgresql -y
            Write-Success "PostgreSQL 安装完成"
        }
        catch {
            Write-Warning "PostgreSQL 安装失败，请手动安装"
        }
    } else {
        Write-Info "PostgreSQL 已安装"
    }
    
    # Redis
    Write-Info "检查 Redis..."
    if (-not (Get-Command redis-server -ErrorAction SilentlyContinue)) {
        Write-Info "安装 Redis..."
        try {
            # Windows 版本的 Redis
            choco install redis-64 -y
            Write-Success "Redis 安装完成"
        }
        catch {
            Write-Warning "Redis 安装失败，请手动安装"
        }
    } else {
        Write-Info "Redis 已安装"
    }
}

# 安装 Docker
function Install-Docker {
    if ($DevOnly) {
        Write-Info "开发模式，跳过 Docker 安装"
        return
    }
    
    Write-Header "安装 Docker Desktop"
    
    # 检查是否已安装
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Write-Info "Docker 已安装"
        return
    }
    
    Write-Info "安装 Docker Desktop..."
    try {
        choco install docker-desktop -y
        Write-Success "Docker Desktop 安装完成"
        Write-Warning "请重启计算机以完成 Docker 安装"
    }
    catch {
        Write-Warning "Docker Desktop 安装失败，请手动安装"
        Write-Info "下载地址: https://www.docker.com/products/docker-desktop"
    }
}

# 安装编辑器和工具
function Install-Editors {
    Write-Header "安装编辑器和工具"
    
    $choice = Read-Host "是否安装 Visual Studio Code? (y/N)"
    if ($choice -eq 'y' -or $choice -eq 'Y') {
        Install-Package -PackageName "vscode" -DisplayName "Visual Studio Code" -CheckCommand "code"
    }
    
    $choice = Read-Host "是否安装 Postman? (y/N)"
    if ($choice -eq 'y' -or $choice -eq 'Y') {
        Install-Package -PackageName "postman" -DisplayName "Postman" -CheckCommand "postman"
    }
}

# 配置开发环境
function Set-DevEnvironment {
    Write-Header "配置开发环境"
    
    # 设置 Go 环境变量
    if (Get-Command go -ErrorAction SilentlyContinue) {
        $goPath = "$env:USERPROFILE\go"
        if (-not (Test-Path $goPath)) {
            New-Item -ItemType Directory -Path $goPath -Force | Out-Null
        }
        
        [Environment]::SetEnvironmentVariable("GOPATH", $goPath, "User")
        [Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$goPath\bin", "User")
        
        Write-Success "Go 环境变量配置完成"
    }
    
    # 配置 npm 全局包目录
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $npmGlobal = "$env:APPDATA\npm"
        npm config set prefix $npmGlobal
        Write-Success "npm 全局包目录配置完成"
    }
}

# 验证安装
function Test-Installation {
    Write-Header "验证安装"
    
    $results = @()
    
    # 检查各个工具
    $tools = @(
        @{ Name = "Git"; Command = "git"; Version = "git --version" },
        @{ Name = "Node.js"; Command = "node"; Version = "node --version" },
        @{ Name = "npm"; Command = "npm"; Version = "npm --version" },
        @{ Name = "Go"; Command = "go"; Version = "go version" }
    )
    
    if (-not $DevOnly) {
        $tools += @(
            @{ Name = "Docker"; Command = "docker"; Version = "docker --version" }
        )
    }
    
    foreach ($tool in $tools) {
        if (Get-Command $tool.Command -ErrorAction SilentlyContinue) {
            try {
                $version = Invoke-Expression $tool.Version 2>$null
                $results += "✓ $($tool.Name): $version"
            }
            catch {
                $results += "✓ $($tool.Name): 已安装"
            }
        } else {
            $results += "✗ $($tool.Name): 未安装"
        }
    }
    
    Write-Host ""
    Write-Host "安装结果:" -ForegroundColor Green
    foreach ($result in $results) {
        if ($result.StartsWith("✓")) {
            Write-Host $result -ForegroundColor Green
        } else {
            Write-Host $result -ForegroundColor Red
        }
    }
}

# 显示后续步骤
function Show-NextSteps {
    Write-Header "后续步骤"
    
    @"
1. 重启 PowerShell 或命令提示符以刷新环境变量

2. 如果安装了数据库，请配置：
   - PostgreSQL: 设置密码并创建数据库
   - Redis: 启动 Redis 服务

3. 运行项目部署脚本：
   .\scripts\deploy.ps1 -Mode dev

4. 开发环境配置：
   - 配置 IDE/编辑器
   - 安装项目依赖: npm install (在 frontend 目录)
   - 安装 Go 模块: go mod tidy

5. 可选工具：
   - Postman: API 测试
   - pgAdmin: PostgreSQL 管理
   - Redis Desktop Manager: Redis 管理

"@
}

# 主函数
function Main {
    Write-Header "Windows 依赖安装脚本"
    
    # 显示帮助
    if ($Help) {
        Show-Help
        return
    }
    
    # 检查管理员权限
    if (-not (Test-Administrator)) {
        Write-Warning "建议以管理员身份运行此脚本以获得最佳体验"
        $choice = Read-Host "是否继续? (y/N)"
        if ($choice -ne 'y' -and $choice -ne 'Y') {
            Write-Info "请以管理员身份重新运行脚本"
            return
        }
    }
    
    try {
        Install-Chocolatey
        Install-DevTools
        Install-Databases
        Install-Docker
        Install-Editors
        Set-DevEnvironment
        Test-Installation
        Show-NextSteps
        
        Write-Success "依赖安装完成！"
    }
    catch {
        Write-Error "安装过程中出现错误: $_"
        exit 1
    }
}

# 运行主函数
Main