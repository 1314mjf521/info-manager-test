# 前端服务一键安装和启动脚本

param(
    [string]$Mode = "dev",  # dev, build, serve
    [int]$Port = 5173,
    [switch]$Force,         # 强制重新安装依赖
    [switch]$Clean          # 清理缓存和构建文件
)

Write-Host "前端服务一键安装和启动脚本" -ForegroundColor Green
Write-Host "模式: $Mode | 端口: $Port" -ForegroundColor Cyan

# 检查Node.js和npm
function Test-NodeEnvironment {
    Write-Host "`n1. 检查Node.js环境..." -ForegroundColor Yellow
    
    try {
        $nodeVersion = & node --version 2>$null
        if ($nodeVersion) {
            Write-Host "   ✓ Node.js版本: $nodeVersion" -ForegroundColor Green
        } else {
            throw "Node.js未安装"
        }
    } catch {
        Write-Host "   ✗ Node.js未安装或不在PATH中" -ForegroundColor Red
        Write-Host "   请访问 https://nodejs.org 下载安装Node.js" -ForegroundColor Yellow
        return $false
    }
    
    try {
        $npmVersion = & npm --version 2>$null
        if ($npmVersion) {
            Write-Host "   ✓ npm版本: $npmVersion" -ForegroundColor Green
        } else {
            throw "npm未安装"
        }
    } catch {
        Write-Host "   ✗ npm未安装" -ForegroundColor Red
        return $false
    }
    
    return $true
}

# 检查前端目录
function Test-FrontendDirectory {
    Write-Host "`n2. 检查前端目录..." -ForegroundColor Yellow
    
    if (-not (Test-Path "frontend")) {
        Write-Host "   ✗ frontend目录不存在" -ForegroundColor Red
        return $false
    }
    
    if (-not (Test-Path "frontend/package.json")) {
        Write-Host "   ✗ frontend/package.json不存在" -ForegroundColor Red
        return $false
    }
    
    Write-Host "   ✓ 前端目录结构正常" -ForegroundColor Green
    return $true
}

# 清理缓存和构建文件
function Clear-FrontendCache {
    Write-Host "`n3. 清理缓存和构建文件..." -ForegroundColor Yellow
    
    Push-Location frontend
    
    try {
        # 清理node_modules
        if (Test-Path "node_modules") {
            Write-Host "   清理node_modules..." -ForegroundColor Gray
            Remove-Item -Recurse -Force "node_modules" -ErrorAction SilentlyContinue
        }
        
        # 清理dist目录
        if (Test-Path "dist") {
            Write-Host "   清理dist目录..." -ForegroundColor Gray
            Remove-Item -Recurse -Force "dist" -ErrorAction SilentlyContinue
        }
        
        # 清理缓存文件
        $cacheFiles = @(".vite", ".turbo", ".next", "coverage", ".nyc_output")
        foreach ($cache in $cacheFiles) {
            if (Test-Path $cache) {
                Write-Host "   清理$cache..." -ForegroundColor Gray
                Remove-Item -Recurse -Force $cache -ErrorAction SilentlyContinue
            }
        }
        
        # 清理npm缓存
        Write-Host "   清理npm缓存..." -ForegroundColor Gray
        & npm cache clean --force 2>$null
        
        Write-Host "   ✓ 缓存清理完成" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠ 清理过程中出现警告: $($_.Exception.Message)" -ForegroundColor Yellow
    } finally {
        Pop-Location
    }
}

# 安装依赖
function Install-Dependencies {
    Write-Host "`n4. 安装前端依赖..." -ForegroundColor Yellow
    
    Push-Location frontend
    
    try {
        # 检查是否需要安装依赖
        $needInstall = $Force -or -not (Test-Path "node_modules") -or -not (Test-Path "package-lock.json")
        
        if ($needInstall) {
            Write-Host "   正在安装依赖包..." -ForegroundColor Gray
            
            # 使用npm ci进行快速安装（如果有package-lock.json）
            if (Test-Path "package-lock.json" -and -not $Force) {
                Write-Host "   使用npm ci进行快速安装..." -ForegroundColor Gray
                & npm ci
            } else {
                Write-Host "   使用npm install安装..." -ForegroundColor Gray
                & npm install
            }
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✓ 依赖安装成功" -ForegroundColor Green
            } else {
                throw "依赖安装失败"
            }
        } else {
            Write-Host "   ✓ 依赖已存在，跳过安装" -ForegroundColor Green
        }
        
        # 检查关键依赖
        Write-Host "   检查关键依赖..." -ForegroundColor Gray
        $packageJson = Get-Content "package.json" | ConvertFrom-Json
        $dependencies = @($packageJson.dependencies.PSObject.Properties.Name)
        $devDependencies = @($packageJson.devDependencies.PSObject.Properties.Name)
        
        Write-Host "   依赖包数量: $($dependencies.Count) 个生产依赖, $($devDependencies.Count) 个开发依赖" -ForegroundColor Gray
        
        return $true
    } catch {
        Write-Host "   ✗ 依赖安装失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        Pop-Location
    }
}

# 构建前端
function Build-Frontend {
    Write-Host "`n5. 构建前端..." -ForegroundColor Yellow
    
    Push-Location frontend
    
    try {
        Write-Host "   正在构建生产版本..." -ForegroundColor Gray
        & npm run build
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✓ 前端构建成功" -ForegroundColor Green
            
            # 检查构建结果
            if (Test-Path "dist") {
                $distFiles = Get-ChildItem "dist" -Recurse -File
                $totalSize = ($distFiles | Measure-Object -Property Length -Sum).Sum
                $sizeInMB = [math]::Round($totalSize / 1MB, 2)
                Write-Host "   构建文件: $($distFiles.Count) 个文件, 总大小: ${sizeInMB}MB" -ForegroundColor Gray
            }
            
            return $true
        } else {
            throw "构建失败"
        }
    } catch {
        Write-Host "   ✗ 前端构建失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        Pop-Location
    }
}

# 启动开发服务器
function Start-DevServer {
    Write-Host "`n6. 启动开发服务器..." -ForegroundColor Yellow
    
    Push-Location frontend
    
    try {
        Write-Host "   正在启动Vite开发服务器..." -ForegroundColor Gray
        Write-Host "   端口: $Port" -ForegroundColor Gray
        Write-Host "   访问地址: http://localhost:$Port" -ForegroundColor Cyan
        Write-Host "   按 Ctrl+C 停止服务器" -ForegroundColor Yellow
        
        # 设置环境变量
        $env:VITE_PORT = $Port
        
        # 启动开发服务器
        & npm run dev -- --port $Port --host 0.0.0.0
        
    } catch {
        Write-Host "   ✗ 开发服务器启动失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        Pop-Location
    }
}

# 启动预览服务器
function Start-PreviewServer {
    Write-Host "`n6. 启动预览服务器..." -ForegroundColor Yellow
    
    Push-Location frontend
    
    try {
        Write-Host "   正在启动预览服务器..." -ForegroundColor Gray
        Write-Host "   端口: $Port" -ForegroundColor Gray
        Write-Host "   访问地址: http://localhost:$Port" -ForegroundColor Cyan
        Write-Host "   按 Ctrl+C 停止服务器" -ForegroundColor Yellow
        
        # 启动预览服务器
        & npm run preview -- --port $Port --host 0.0.0.0
        
    } catch {
        Write-Host "   ✗ 预览服务器启动失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        Pop-Location
    }
}

# 检查端口是否被占用
function Test-Port {
    param([int]$TestPort)
    
    try {
        $connection = Test-NetConnection -ComputerName "localhost" -Port $TestPort -InformationLevel Quiet -WarningAction SilentlyContinue
        return $connection
    } catch {
        return $false
    }
}

# 主执行流程
function Main {
    Write-Host "="*60 -ForegroundColor Cyan
    
    # 检查环境
    if (-not (Test-NodeEnvironment)) {
        exit 1
    }
    
    if (-not (Test-FrontendDirectory)) {
        exit 1
    }
    
    # 清理缓存（如果指定）
    if ($Clean) {
        Clear-FrontendCache
    }
    
    # 安装依赖
    if (-not (Install-Dependencies)) {
        exit 1
    }
    
    # 检查端口
    if (Test-Port -TestPort $Port) {
        Write-Host "`n⚠ 端口 $Port 已被占用" -ForegroundColor Yellow
        $newPort = $Port + 1
        while (Test-Port -TestPort $newPort -and $newPort -lt ($Port + 10)) {
            $newPort++
        }
        if ($newPort -lt ($Port + 10)) {
            Write-Host "   将使用端口 $newPort" -ForegroundColor Yellow
            $Port = $newPort
        } else {
            Write-Host "   无法找到可用端口，请手动指定" -ForegroundColor Red
            exit 1
        }
    }
    
    # 根据模式执行不同操作
    switch ($Mode.ToLower()) {
        "dev" {
            Write-Host "`n🚀 启动开发模式..." -ForegroundColor Green
            Start-DevServer
        }
        "build" {
            Write-Host "`n🔨 构建生产版本..." -ForegroundColor Green
            if (Build-Frontend) {
                Write-Host "`n✅ 构建完成！构建文件位于 frontend/dist 目录" -ForegroundColor Green
            }
        }
        "serve" {
            Write-Host "`n📦 构建并启动预览服务器..." -ForegroundColor Green
            if (Build-Frontend) {
                Start-PreviewServer
            }
        }
        default {
            Write-Host "`n❌ 无效的模式: $Mode" -ForegroundColor Red
            Write-Host "可用模式: dev, build, serve" -ForegroundColor Yellow
            exit 1
        }
    }
}

# 显示帮助信息
function Show-Help {
    Write-Host @"
前端服务一键安装和启动脚本

用法:
    .\scripts\install-and-start-frontend.ps1 [参数]

参数:
    -Mode <模式>     指定运行模式 (dev|build|serve)，默认: dev
    -Port <端口>     指定端口号，默认: 5173
    -Force          强制重新安装依赖
    -Clean          清理缓存和构建文件
    -Help           显示此帮助信息

模式说明:
    dev             启动开发服务器 (热重载)
    build           构建生产版本
    serve           构建并启动预览服务器

示例:
    .\scripts\install-and-start-frontend.ps1                    # 开发模式
    .\scripts\install-and-start-frontend.ps1 -Mode build        # 构建模式
    .\scripts\install-and-start-frontend.ps1 -Mode serve        # 预览模式
    .\scripts\install-and-start-frontend.ps1 -Port 3000         # 指定端口
    .\scripts\install-and-start-frontend.ps1 -Clean -Force      # 清理并重装

"@ -ForegroundColor White
}

# 参数验证和执行
if ($args -contains "-Help" -or $args -contains "--help" -or $args -contains "-h") {
    Show-Help
    exit 0
}

# 执行主流程
try {
    Main
} catch {
    Write-Host "`n💥 执行过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "请检查错误信息并重试" -ForegroundColor Yellow
    exit 1
}