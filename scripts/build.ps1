# 编译脚本 (PowerShell版本)
# 用于Windows环境下编译Go应用

param(
    [string]$BuildMode = "release",
    [string]$OutputDir = "build",
    [switch]$Clean = $false,
    [switch]$Test = $false
)

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
    Write-ColorOutput Blue "[INFO] $message"
}

function Write-Success($message) {
    Write-ColorOutput Green "[SUCCESS] $message"
}

function Write-Warning($message) {
    Write-ColorOutput Yellow "[WARNING] $message"
}

function Write-Error($message) {
    Write-ColorOutput Red "[ERROR] $message"
}

# 检查Go环境
function Test-GoEnvironment {
    Write-Info "检查Go环境..."
    
    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        Write-Error "Go未安装，请从 https://golang.org/dl/ 下载安装"
        return $false
    }
    
    $goVersion = go version
    Write-Info "Go版本: $goVersion"
    
    return $true
}

# 清理构建目录
function Clear-BuildDirectory {
    if ($Clean -and (Test-Path $OutputDir)) {
        Write-Info "清理构建目录: $OutputDir"
        Remove-Item -Path $OutputDir -Recurse -Force
    }
    
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Info "创建构建目录: $OutputDir"
    }
}

# 运行测试
function Invoke-Tests {
    if ($Test) {
        Write-Info "运行测试..."
        
        $testResult = go test -v ./...
        if ($LASTEXITCODE -ne 0) {
            Write-Error "测试失败"
            return $false
        }
        
        Write-Success "所有测试通过"
    }
    
    return $true
}

# 编译应用
function Build-Application {
    Write-Info "编译应用..."
    
    # 设置Go代理为国内镜像
    $env:GOPROXY = "https://mirrors.aliyun.com/goproxy/,direct"
    $env:GOSUMDB = "sum.golang.google.cn"
    
    # 设置构建参数
    $env:CGO_ENABLED = "0"
    $env:GOOS = "linux"
    $env:GOARCH = "amd64"
    
    # 获取版本信息
    $version = "dev"
    $buildTime = Get-Date -Format "yyyy-MM-dd_HH:mm:ss"
    $gitCommit = "unknown"
    
    try {
        $gitCommit = git rev-parse HEAD 2>$null
        if (-not $gitCommit) { $gitCommit = "unknown" }
    } catch {
        $gitCommit = "unknown"
    }
    
    # 构建标志
    $ldflags = "-ldflags `"-X main.Version=$version -X main.BuildTime=$buildTime -X main.GitCommit=$gitCommit`""
    
    # 输出文件
    $outputFile = Join-Path $OutputDir "server"
    if ($env:GOOS -eq "windows") {
        $outputFile += ".exe"
    }
    
    Write-Info "构建目标: $env:GOOS/$env:GOARCH"
    Write-Info "输出文件: $outputFile"
    
    # 执行构建
    $buildCmd = "go build $ldflags -o `"$outputFile`" ./cmd/server"
    Write-Info "执行命令: $buildCmd"
    
    Invoke-Expression $buildCmd
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "编译失败"
        return $false
    }
    
    if (Test-Path $outputFile) {
        $fileInfo = Get-Item $outputFile
        Write-Success "编译成功: $($fileInfo.Name) ($($fileInfo.Length) bytes)"
        return $true
    } else {
        Write-Error "编译后文件不存在: $outputFile"
        return $false
    }
}

# 复制配置文件
function Copy-ConfigFiles {
    Write-Info "复制配置文件..."
    
    $configSource = "configs"
    $configDest = Join-Path $OutputDir "configs"
    
    if (Test-Path $configSource) {
        Copy-Item -Path $configSource -Destination $configDest -Recurse -Force
        
        # 创建本地测试配置
        $localConfig = @"
server:
  port: "8080"
  mode: "debug"

database:
  type: "sqlite"
  database: "info_system.db"

redis:
  host: "localhost"
  port: "6379"
  password: ""
  db: 0

jwt:
  secret: "local-development-secret-key"
  expire_time: 24

log:
  level: "debug"
  format: "text"
"@
        
        $localConfigPath = Join-Path $configDest "config.local.yaml"
        $localConfig | Out-File -FilePath $localConfigPath -Encoding UTF8
        Write-Info "创建本地测试配置: $localConfigPath"
        
        Write-Success "配置文件复制完成"
    } else {
        Write-Warning "配置文件目录不存在: $configSource"
    }
}

# 创建启动脚本
function New-StartupScript {
    Write-Info "创建启动脚本..."
    
    # Linux启动脚本
    $linuxScript = @"
#!/bin/bash
# 应用启动脚本

# 设置工作目录
cd `$(dirname `$0)

# 设置环境变量
export IMS_SERVER_MODE=$BuildMode

# 启动应用
./server
"@
    
    $linuxScriptPath = Join-Path $OutputDir "start.sh"
    $linuxScript | Out-File -FilePath $linuxScriptPath -Encoding UTF8
    Write-Info "Linux启动脚本: $linuxScriptPath"
    
    # Windows启动脚本
    $windowsScript = @"
@echo off
REM 应用启动脚本

REM 设置工作目录
cd /d %~dp0

REM 设置环境变量
set IMS_SERVER_MODE=$BuildMode

REM 启动应用
server.exe
"@
    
    $windowsScriptPath = Join-Path $OutputDir "start.bat"
    $windowsScript | Out-File -FilePath $windowsScriptPath -Encoding UTF8
    Write-Info "Windows启动脚本: $windowsScriptPath"
}

# 显示构建信息
function Show-BuildInfo {
    Write-Success "构建完成！"
    Write-Host ""
    Write-Info "构建信息:"
    Write-Info "  构建模式: $BuildMode"
    Write-Info "  输出目录: $OutputDir"
    Write-Info "  目标平台: $env:GOOS/$env:GOARCH"
    Write-Host ""
    
    if (Test-Path $OutputDir) {
        Write-Info "构建产物:"
        Get-ChildItem -Path $OutputDir | ForEach-Object {
            $size = if ($_.PSIsContainer) { "目录" } else { "$($_.Length) bytes" }
            Write-Info "  $($_.Name) - $size"
        }
    }
    
    Write-Host ""
    Write-Info "使用方法:"
    Write-Info "  Linux: cd $OutputDir; chmod +x server start.sh; ./start.sh"
    Write-Info "  Windows: cd $OutputDir; start.bat"
    Write-Info "  Docker: 使用 $OutputDir/server 作为容器入口点"
}

# 主函数
function Main {
    Write-Info "开始编译信息管理系统..."
    Write-Info "构建模式: $BuildMode"
    Write-Host ""
    
    try {
        # 检查Go环境
        if (-not (Test-GoEnvironment)) {
            throw "Go环境检查失败"
        }
        
        # 清理构建目录
        Clear-BuildDirectory
        
        # 运行测试
        if (-not (Invoke-Tests)) {
            throw "测试失败"
        }
        
        # 编译应用
        if (-not (Build-Application)) {
            throw "编译失败"
        }
        
        # 复制配置文件
        Copy-ConfigFiles
        
        # 创建启动脚本
        New-StartupScript
        
        # 显示构建信息
        Show-BuildInfo
        
        Write-Success "编译流程完成！"
        
    } catch {
        Write-Error "编译过程中发生错误: $($_.Exception.Message)"
        Write-Info ""
        Write-Info "故障排除建议："
        Write-Info "1. 检查Go环境: go version"
        Write-Info "2. 检查依赖: go mod tidy"
        Write-Info "3. 清理缓存: go clean -cache"
        Write-Info "4. 重新下载依赖: go mod download"
        
        exit 1
    }
}

# 执行主函数
Main