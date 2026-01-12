# 信息管理系统 - Windows部署脚本
# PowerShell 版本

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "prod", "docker")]
    [string]$Mode = "dev",
    
    [Parameter(Mandatory=$false)]
    [string]$Domain = "localhost",
    
    [Parameter(Mandatory=$false)]
    [switch]$SSL,
    
    [Parameter(Mandatory=$false)]
    [string]$DbPassword,
    
    [Parameter(Mandatory=$false)]
    [string]$RedisPassword,
    
    [Parameter(Mandatory=$false)]
    [string]$JwtSecret,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

# 项目配置
$ProjectName = "info-management-system"
$Version = "1.0.0"
$BackendPort = 8080
$FrontendPort = 3000
$DbPort = 5432
$RedisPort = 6379

# 颜色函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Blue"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[SUCCESS] $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

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
信息管理系统 Windows 部署脚本

用法: .\deploy.ps1 [参数]

参数:
    -Mode MODE              部署模式 (dev|prod|docker) 默认: dev
    -Domain DOMAIN          域名 (默认: localhost)
    -SSL                    启用SSL证书
    -DbPassword PWD         数据库密码
    -RedisPassword PWD      Redis密码
    -JwtSecret SECRET       JWT密钥
    -Help                   显示帮助信息

部署模式:
    dev         开发模式部署
    prod        生产模式部署
    docker      使用Docker部署

示例:
    .\deploy.ps1 -Mode dev
    .\deploy.ps1 -Mode prod -Domain example.com -SSL
    .\deploy.ps1 -Mode docker -DbPassword mypass123

"@
}

# 检查系统要求
function Test-Requirements {
    Write-Header "检查系统要求"
    
    switch ($Mode) {
        "dev" { Test-DevRequirements }
        "prod" { Test-ProdRequirements }
        "docker" { Test-DockerRequirements }
    }
}

# 检查开发环境要求
function Test-DevRequirements {
    $missingDeps = @()
    
    # 检查Node.js
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        $missingDeps += "Node.js"
    }
    
    # 检查npm
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        $missingDeps += "npm"
    }
    
    # 检查Go
    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        $missingDeps += "Go"
    }
    
    if ($missingDeps.Count -gt 0) {
        Write-Error "缺少以下依赖: $($missingDeps -join ', ')"
        Write-Info "请先安装缺少的依赖，然后重新运行脚本"
        exit 1
    }
    
    Write-Success "开发环境要求检查通过"
}

# 检查生产环境要求
function Test-ProdRequirements {
    Test-DevRequirements
    
    # 检查IIS或其他Web服务器
    if (-not (Get-WindowsFeature -Name IIS-WebServerRole -ErrorAction SilentlyContinue)) {
        Write-Warning "建议安装IIS作为Web服务器"
    }
    
    Write-Success "生产环境要求检查通过"
}

# 检查Docker要求
function Test-DockerRequirements {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker 未安装"
        exit 1
    }
    
    if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        Write-Error "Docker Compose 未安装"
        exit 1
    }
    
    # 检查Docker服务状态
    try {
        docker info | Out-Null
    }
    catch {
        Write-Error "Docker 服务未运行"
        exit 1
    }
    
    Write-Success "Docker要求检查通过"
}

# 生成随机密码
function New-RandomPassword {
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    $password = ""
    for ($i = 0; $i -lt 25; $i++) {
        $password += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $password
}

# 设置默认密码
function Set-DefaultPasswords {
    if (-not $DbPassword) {
        $script:DbPassword = New-RandomPassword
        Write-Info "生成数据库密码: $DbPassword"
    }
    
    if (-not $RedisPassword) {
        $script:RedisPassword = New-RandomPassword
        Write-Info "生成Redis密码: $RedisPassword"
    }
    
    if (-not $JwtSecret) {
        $script:JwtSecret = New-RandomPassword
        Write-Info "生成JWT密钥: $JwtSecret"
    }
}

# 构建前端
function Build-Frontend {
    Write-Header "构建前端应用"
    
    Push-Location frontend
    
    try {
        # 安装依赖
        Write-Info "安装前端依赖..."
        npm ci --production=false
        
        # 构建
        Write-Info "构建前端应用..."
        npm run build
        
        Write-Success "前端构建完成"
    }
    catch {
        Write-Error "前端构建失败: $_"
        exit 1
    }
    finally {
        Pop-Location
    }
}

# 构建后端
function Build-Backend {
    Write-Header "构建后端应用"
    
    try {
        # 设置Go环境
        $env:CGO_ENABLED = "0"
        $env:GOOS = "windows"
        $env:GOARCH = "amd64"
        
        # 构建
        Write-Info "构建后端应用..."
        go mod tidy
        
        if (-not (Test-Path "bin")) {
            New-Item -ItemType Directory -Path "bin" | Out-Null
        }
        
        go build -o bin/server.exe ./cmd/server
        
        Write-Success "后端构建完成"
    }
    catch {
        Write-Error "后端构建失败: $_"
        exit 1
    }
}

# 开发模式部署
function Deploy-Dev {
    Write-Header "开发模式部署"
    
    # 构建应用
    Build-Frontend
    Build-Backend
    
    # 创建配置文件
    New-DevConfig
    
    # 启动服务
    Start-DevServices
    
    Write-Success "开发环境部署完成"
    Show-DevInfo
}

# 生产模式部署
function Deploy-Prod {
    Write-Header "生产模式部署"
    
    # 构建应用
    Build-Frontend
    Build-Backend
    
    # 创建配置文件
    New-ProdConfig
    
    # 配置服务
    Install-WindowsService
    
    Write-Success "生产环境部署完成"
    Show-ProdInfo
}

# Docker部署
function Deploy-Docker {
    Write-Header "Docker部署"
    
    # 创建环境变量文件
    New-DockerEnv
    
    try {
        # 构建和启动服务
        Write-Info "构建Docker镜像..."
        docker-compose build
        
        Write-Info "启动服务..."
        docker-compose up -d
        
        # 等待服务启动
        Write-Info "等待服务启动..."
        Start-Sleep -Seconds 10
        
        # 检查服务状态
        Test-DockerServices
        
        Write-Success "Docker部署完成"
        Show-DockerInfo
    }
    catch {
        Write-Error "Docker部署失败: $_"
        exit 1
    }
}

# 创建开发配置
function New-DevConfig {
    $config = @{
        server = @{
            port = $BackendPort
            mode = "debug"
        }
        database = @{
            host = "localhost"
            port = $DbPort
            name = $ProjectName
            user = "postgres"
            password = $DbPassword
        }
        redis = @{
            host = "localhost"
            port = $RedisPort
            password = $RedisPassword
        }
        jwt = @{
            secret = $JwtSecret
        }
    }
    
    $config | ConvertTo-Json -Depth 3 | Out-File -FilePath "config/config.dev.json" -Encoding UTF8
    Write-Success "开发配置文件创建完成"
}

# 创建生产配置
function New-ProdConfig {
    $config = @{
        server = @{
            port = $BackendPort
            mode = "release"
        }
        database = @{
            host = "localhost"
            port = $DbPort
            name = $ProjectName
            user = "postgres"
            password = $DbPassword
        }
        redis = @{
            host = "localhost"
            port = $RedisPort
            password = $RedisPassword
        }
        jwt = @{
            secret = $JwtSecret
        }
        ssl = @{
            enabled = $SSL.IsPresent
            domain = $Domain
        }
    }
    
    $config | ConvertTo-Json -Depth 3 | Out-File -FilePath "config/config.prod.json" -Encoding UTF8
    Write-Success "生产配置文件创建完成"
}

# 创建Docker环境变量文件
function New-DockerEnv {
    $envContent = @"
# 应用配置
PROJECT_NAME=$ProjectName
VERSION=$Version
DOMAIN=$Domain

# 端口配置
BACKEND_PORT=$BackendPort
FRONTEND_PORT=$FrontendPort
DB_PORT=$DbPort
REDIS_PORT=$RedisPort

# 数据库配置
POSTGRES_DB=$ProjectName
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$DbPassword

# Redis配置
REDIS_PASSWORD=$RedisPassword

# JWT配置
JWT_SECRET=$JwtSecret

# SSL配置
SSL_ENABLED=$($SSL.IsPresent)
"@
    
    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-Success "环境变量文件创建完成"
}

# 启动开发服务
function Start-DevServices {
    Write-Info "启动开发服务..."
    
    # 启动后端服务（后台）
    Start-Process -FilePath "bin/server.exe" -ArgumentList "--config=config/config.dev.json" -WindowStyle Hidden
    
    # 启动前端开发服务
    Push-Location frontend
    Start-Process -FilePath "npm" -ArgumentList "run", "dev" -WindowStyle Hidden
    Pop-Location
    
    Write-Success "开发服务启动完成"
}

# 安装Windows服务
function Install-WindowsService {
    Write-Info "配置Windows服务..."
    
    # 这里可以使用NSSM或其他工具将应用安装为Windows服务
    # 简化版本，直接提示用户手动配置
    Write-Warning "请手动配置Windows服务或使用任务计划程序"
    Write-Info "可执行文件路径: $(Get-Location)\bin\server.exe"
    Write-Info "配置文件路径: $(Get-Location)\config\config.prod.json"
}

# 检查Docker服务状态
function Test-DockerServices {
    $services = @("app", "postgres", "redis", "nginx")
    
    foreach ($service in $services) {
        $status = docker-compose ps $service
        if ($status -match "Up") {
            Write-Success "$service 服务运行正常"
        } else {
            Write-Error "$service 服务启动失败"
            docker-compose logs $service
        }
    }
}

# 显示开发环境信息
function Show-DevInfo {
    Write-Header "开发环境信息"
    Write-Host "前端地址: http://localhost:$FrontendPort"
    Write-Host "后端地址: http://localhost:$BackendPort"
    Write-Host "API地址: http://localhost:$BackendPort/api"
    Write-Host ""
    Write-Host "数据库密码: $DbPassword"
    Write-Host "Redis密码: $RedisPassword"
}

# 显示生产环境信息
function Show-ProdInfo {
    Write-Header "生产环境信息"
    Write-Host "应用地址: http://$Domain"
    Write-Host "API地址: http://$Domain/api"
    Write-Host ""
    Write-Host "数据库密码: $DbPassword"
    Write-Host "Redis密码: $RedisPassword"
    Write-Host ""
    Write-Host "请配置Web服务器（IIS/Nginx）代理到后端服务"
}

# 显示Docker信息
function Show-DockerInfo {
    Write-Header "Docker部署信息"
    Write-Host "应用地址: http://$Domain"
    Write-Host "API地址: http://$Domain/api"
    Write-Host ""
    Write-Host "数据库密码: $DbPassword"
    Write-Host "Redis密码: $RedisPassword"
    Write-Host ""
    Write-Host "管理命令:"
    Write-Host "  查看日志: docker-compose logs -f"
    Write-Host "  重启服务: docker-compose restart"
    Write-Host "  停止服务: docker-compose down"
}

# 主函数
function Main {
    Write-Header "信息管理系统 Windows 部署脚本"
    
    # 显示帮助
    if ($Help) {
        Show-Help
        return
    }
    
    # 检查要求
    Test-Requirements
    
    # 设置密码
    Set-DefaultPasswords
    
    # 根据模式部署
    switch ($Mode) {
        "dev" { Deploy-Dev }
        "prod" { Deploy-Prod }
        "docker" { Deploy-Docker }
    }
    
    Write-Success "部署完成！"
}

# 运行主函数
Main