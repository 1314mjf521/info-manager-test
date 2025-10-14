@echo off
chcp 65001 >nul
echo 信息管理系统编译脚本
echo ====================
echo.

REM 检查参数
set BUILD_MODE=release
set CLEAN_BUILD=false
set RUN_TESTS=false

:parse_args
if "%1"=="--debug" (
    set BUILD_MODE=debug
    shift
    goto parse_args
)
if "%1"=="--clean" (
    set CLEAN_BUILD=true
    shift
    goto parse_args
)
if "%1"=="--test" (
    set RUN_TESTS=true
    shift
    goto parse_args
)
if "%1"=="--help" (
    echo 使用方法: build.bat [选项]
    echo.
    echo 选项:
    echo   --debug    调试模式编译
    echo   --clean    清理后编译
    echo   --test     运行测试
    echo   --help     显示帮助
    echo.
    exit /b 0
)
if not "%1"=="" (
    shift
    goto parse_args
)

echo [INFO] 编译模式: %BUILD_MODE%
echo [INFO] 清理构建: %CLEAN_BUILD%
echo [INFO] 运行测试: %RUN_TESTS%
echo.

REM 检查PowerShell是否可用
powershell -Command "Get-Host" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [INFO] 使用PowerShell编译脚本...
    echo.
    
    REM 构建PowerShell命令
    set PS_CMD=powershell -ExecutionPolicy Bypass -File "scripts\build.ps1" -BuildMode "%BUILD_MODE%"
    
    if "%CLEAN_BUILD%"=="true" (
        set PS_CMD=%PS_CMD% -Clean
    )
    
    if "%RUN_TESTS%"=="true" (
        set PS_CMD=%PS_CMD% -Test
    )
    
    REM 执行PowerShell脚本
    %PS_CMD%
    set BUILD_RESULT=%ERRORLEVEL%
    
) else (
    REM 使用传统方式编译
    echo [INFO] PowerShell不可用，使用传统编译方式...
    echo.
    
    REM 检查Go环境
    go version >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Go未安装，请从 https://golang.org/dl/ 下载安装
        pause
        exit /b 1
    )
    
    echo [INFO] Go环境检查通过
    
    REM 清理构建目录
    if "%CLEAN_BUILD%"=="true" (
        if exist "build" (
            echo [INFO] 清理构建目录...
            rmdir /s /q "build"
        )
    )
    
    REM 创建构建目录
    if not exist "build" (
        mkdir "build"
        echo [INFO] 创建构建目录: build
    )
    
    REM 运行测试
    if "%RUN_TESTS%"=="true" (
        echo [INFO] 运行测试...
        go test -v ./...
        if %ERRORLEVEL% NEQ 0 (
            echo [ERROR] 测试失败
            pause
            exit /b 1
        )
        echo [SUCCESS] 所有测试通过
    )
    
    REM 编译应用
    echo [INFO] 编译应用...
    
    REM 设置环境变量
    set CGO_ENABLED=0
    set GOOS=linux
    set GOARCH=amd64
    set GOPROXY=https://mirrors.aliyun.com/goproxy/,direct
    set GOSUMDB=sum.golang.google.cn
    
    REM 获取版本信息
    for /f %%i in ('git rev-parse HEAD 2^>nul') do set GIT_COMMIT=%%i
    if "%GIT_COMMIT%"=="" set GIT_COMMIT=unknown
    
    REM 获取当前时间
    for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set BUILD_DATE=%%c-%%a-%%b
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do set BUILD_TIME=%%a:%%b
    set BUILD_TIMESTAMP=%BUILD_DATE%_%BUILD_TIME%
    
    REM 构建命令
    set LDFLAGS=-ldflags "-X main.Version=dev -X main.BuildTime=%BUILD_TIMESTAMP% -X main.GitCommit=%GIT_COMMIT%"
    
    echo [INFO] 构建目标: %GOOS%/%GOARCH%
    echo [INFO] 输出文件: build\server
    
    go build %LDFLAGS% -o "build\server" ./cmd/server
    
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] 编译失败
        pause
        exit /b 1
    )
    
    echo [SUCCESS] 编译成功
    
    REM 复制配置文件
    if exist "configs" (
        echo [INFO] 复制配置文件...
        xcopy /s /e /y "configs" "build\configs\" >nul
        echo [SUCCESS] 配置文件复制完成
    )
    
    set BUILD_RESULT=0
)

echo.
if %BUILD_RESULT% EQU 0 (
    echo [SUCCESS] 编译完成！
    echo.
    echo 构建产物位置: build\
    echo.
    echo 使用方法:
    echo   本地运行: cd build ^&^& server.exe
    echo   Docker部署: 使用 build/server 作为容器入口点
    echo   远程部署: 运行 deploy-now.bat 或 deploy-to-remote.ps1
    echo.
) else (
    echo [ERROR] 编译失败！
    echo.
    echo 故障排除建议:
    echo   1. 检查Go环境: go version
    echo   2. 检查依赖: go mod tidy
    echo   3. 清理缓存: go clean -cache
    echo   4. 重新编译: build.bat --clean
    echo.
)

pause