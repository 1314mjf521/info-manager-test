# 重新启动后端服务的脚本
# 编码：UTF-8

Write-Host "=== 重新启动后端服务 ===" -ForegroundColor Green

# 检查是否在项目根目录
if (-not (Test-Path "go.mod")) {
    Write-Host "✗ 请在项目根目录运行此脚本" -ForegroundColor Red
    exit 1
}

Write-Host "✓ 在项目根目录" -ForegroundColor Green

# 停止现有服务
Write-Host "`n--- 停止现有服务 ---" -ForegroundColor Cyan

try {
    # 查找并停止Go进程
    $goProcesses = Get-Process | Where-Object { $_.ProcessName -like "*go*" -or $_.ProcessName -like "*main*" -or $_.ProcessName -like "*info-management*" }
    
    if ($goProcesses) {
        Write-Host "找到以下Go相关进程:" -ForegroundColor Yellow
        foreach ($process in $goProcesses) {
            Write-Host "  PID: $($process.Id), 名称: $($process.ProcessName)" -ForegroundColor Gray
            try {
                Stop-Process -Id $process.Id -Force
                Write-Host "  ✓ 已停止进程 $($process.Id)" -ForegroundColor Green
            } catch {
                Write-Host "  ! 无法停止进程 $($process.Id): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "没有找到运行中的Go进程" -ForegroundColor Gray
    }
    
    # 检查端口8080是否被占用
    $port8080 = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
    if ($port8080) {
        Write-Host "端口8080仍被占用，尝试释放..." -ForegroundColor Yellow
        foreach ($conn in $port8080) {
            try {
                $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                if ($process) {
                    Stop-Process -Id $process.Id -Force
                    Write-Host "  ✓ 已停止占用端口8080的进程: $($process.ProcessName)" -ForegroundColor Green
                }
            } catch {
                Write-Host "  ! 无法停止占用端口的进程: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
    
} catch {
    Write-Host "停止服务时发生错误: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 等待端口释放
Write-Host "等待端口释放..." -ForegroundColor Gray
Start-Sleep -Seconds 3

# 清理和重新编译
Write-Host "`n--- 清理和重新编译 ---" -ForegroundColor Cyan

try {
    # 清理Go模块缓存
    Write-Host "清理Go模块缓存..." -ForegroundColor Yellow
    go clean -modcache 2>$null
    
    # 下载依赖
    Write-Host "下载Go依赖..." -ForegroundColor Yellow
    $goModResult = go mod download 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Go依赖下载成功" -ForegroundColor Green
    } else {
        Write-Host "! Go依赖下载警告: $goModResult" -ForegroundColor Yellow
    }
    
    # 整理依赖
    Write-Host "整理Go依赖..." -ForegroundColor Yellow
    go mod tidy 2>&1 | Out-Null
    
    # 编译项目
    Write-Host "编译项目..." -ForegroundColor Yellow
    $buildResult = go build -o bin/server.exe ./cmd/server 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 项目编译成功" -ForegroundColor Green
    } else {
        Write-Host "✗ 项目编译失败: $buildResult" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "编译过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 启动服务
Write-Host "`n--- 启动服务 ---" -ForegroundColor Cyan

try {
    # 检查配置文件
    if (Test-Path "configs/config.yaml") {
        Write-Host "✓ 找到配置文件: configs/config.yaml" -ForegroundColor Green
    } else {
        Write-Host "! 配置文件不存在，使用默认配置" -ForegroundColor Yellow
    }
    
    # 启动服务
    Write-Host "启动后端服务..." -ForegroundColor Yellow
    
    # 使用Start-Process在后台启动服务
    $processInfo = Start-Process -FilePath ".\bin\server.exe" -WorkingDirectory "." -PassThru -WindowStyle Hidden
    
    if ($processInfo) {
        Write-Host "✓ 服务已启动，PID: $($processInfo.Id)" -ForegroundColor Green
        
        # 等待服务启动
        Write-Host "等待服务启动..." -ForegroundColor Gray
        Start-Sleep -Seconds 5
        
        # 检查服务是否正常运行
        try {
            $healthCheck = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method Get -TimeoutSec 10
            Write-Host "✓ 服务健康检查通过" -ForegroundColor Green
            Write-Host "  状态: $($healthCheck.status)" -ForegroundColor Gray
        } catch {
            Write-Host "! 服务健康检查失败，但服务可能仍在启动中" -ForegroundColor Yellow
            Write-Host "  错误: $($_.Exception.Message)" -ForegroundColor Gray
        }
        
        # 检查端口是否监听
        $portCheck = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
        if ($portCheck) {
            Write-Host "✓ 端口8080正在监听" -ForegroundColor Green
        } else {
            Write-Host "! 端口8080未在监听，服务可能启动失败" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "✗ 服务启动失败" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "启动服务时发生错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== 服务重启完成 ===" -ForegroundColor Green
Write-Host "后端服务已在后台运行，PID: $($processInfo.Id)" -ForegroundColor Cyan
Write-Host "服务地址: http://localhost:8080" -ForegroundColor Cyan
Write-Host "健康检查: http://localhost:8080/health" -ForegroundColor Cyan

Write-Host "`n建议接下来的步骤:" -ForegroundColor Yellow
Write-Host "1. 运行 test/diagnose_batch_import_issues.ps1 进行诊断" -ForegroundColor Gray
Write-Host "2. 运行 test/test_simple_batch_operations.ps1 进行简单测试" -ForegroundColor Gray
Write-Host "3. 检查浏览器控制台的网络请求" -ForegroundColor Gray