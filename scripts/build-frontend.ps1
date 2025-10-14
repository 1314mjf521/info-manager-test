# 前端构建脚本
# 编译前端项目并将文件复制到build文件夹

param(
    [switch]$Clean = $false,
    [switch]$Dev = $false
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 颜色输出函数
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Info($message) {
    Write-ColorOutput Green "[INFO] $message"
}

function Write-Warning($message) {
    Write-ColorOutput Yellow "[WARN] $message"
}

function Write-Error($message) {
    Write-ColorOutput Red "[ERROR] $message"
}

# 获取项目根目录
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$FrontendDir = Join-Path $ProjectRoot "frontend"
$BuildDir = Join-Path $ProjectRoot "build"

Write-Info "项目根目录: $ProjectRoot"
Write-Info "前端目录: $FrontendDir"
Write-Info "构建目录: $BuildDir"

# 检查前端目录是否存在
if (-not (Test-Path $FrontendDir)) {
    Write-Error "前端目录不存在: $FrontendDir"
    exit 1
}

# 检查package.json是否存在
$PackageJsonPath = Join-Path $FrontendDir "package.json"
if (-not (Test-Path $PackageJsonPath)) {
    Write-Error "package.json不存在: $PackageJsonPath"
    exit 1
}

# 清理构建目录
if ($Clean -and (Test-Path $BuildDir)) {
    Write-Info "清理构建目录..."
    Remove-Item -Path $BuildDir -Recurse -Force
}

# 创建构建目录
if (-not (Test-Path $BuildDir)) {
    Write-Info "创建构建目录..."
    New-Item -Path $BuildDir -ItemType Directory -Force | Out-Null
}

# 进入前端目录
Push-Location $FrontendDir

try {
    # 检查Node.js和npm是否可用
    Write-Info "检查Node.js环境..."
    
    try {
        $nodeVersion = node --version
        Write-Info "Node.js版本: $nodeVersion"
    } catch {
        Write-Error "Node.js未安装或不在PATH中"
        exit 1
    }
    
    try {
        $npmVersion = npm --version
        Write-Info "npm版本: $npmVersion"
    } catch {
        Write-Error "npm未安装或不在PATH中"
        exit 1
    }
    
    # 检查依赖是否已安装
    $NodeModulesPath = Join-Path $FrontendDir "node_modules"
    if (-not (Test-Path $NodeModulesPath)) {
        Write-Info "安装依赖..."
        npm install
        if ($LASTEXITCODE -ne 0) {
            Write-Error "依赖安装失败"
            exit 1
        }
    } else {
        Write-Info "依赖已存在，跳过安装"
    }
    
    # 构建项目
    if ($Dev) {
        Write-Info "启动开发服务器..."
        npm run dev
    } else {
        Write-Info "构建生产版本..."
        npm run build
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "构建失败"
            exit 1
        }
        
        # 检查dist目录是否存在
        $DistPath = Join-Path $FrontendDir "dist"
        if (-not (Test-Path $DistPath)) {
            Write-Error "构建输出目录不存在: $DistPath"
            exit 1
        }
        
        # 复制构建文件到build目录
        Write-Info "复制构建文件到build目录..."
        $FrontendBuildDir = Join-Path $BuildDir "frontend"
        
        if (Test-Path $FrontendBuildDir) {
            Remove-Item -Path $FrontendBuildDir -Recurse -Force
        }
        
        # 使用正确的复制方法保持目录结构
        Copy-Item -Path $DistPath -Destination $FrontendBuildDir -Recurse -Force
        
        Write-Info "构建完成！"
        Write-Info "前端文件已复制到: $FrontendBuildDir"
        
        # 显示构建文件大小
        $BuildFiles = Get-ChildItem -Path $FrontendBuildDir -Recurse -File
        $TotalSize = ($BuildFiles | Measure-Object -Property Length -Sum).Sum
        $TotalSizeMB = [math]::Round($TotalSize / 1MB, 2)
        
        Write-Info "构建文件总大小: $TotalSizeMB MB"
        Write-Info "文件数量: $($BuildFiles.Count)"
    }
    
} catch {
    Write-Error "构建过程中发生错误: $($_.Exception.Message)"
    exit 1
} finally {
    # 返回原目录
    Pop-Location
}

Write-Info "前端构建脚本执行完成"