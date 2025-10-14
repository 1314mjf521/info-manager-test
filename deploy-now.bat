@echo off
chcp 65001 >nul
echo 信息管理系统一键部署
echo =====================
echo.

echo [INFO] 检测部署环境...

REM 检查PowerShell是否可用
powershell -Command "Get-Host" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [INFO] 使用PowerShell部署脚本...
    echo.
    powershell -ExecutionPolicy Bypass -File "scripts/deploy-remote.ps1"
    set DEPLOY_RESULT=%ERRORLEVEL%
) else (
    REM 检查是否有Git Bash
    if exist "%ProgramFiles%\Git\bin\bash.exe" (
        echo [INFO] 使用Git Bash部署脚本...
        echo.
        "%ProgramFiles%\Git\bin\bash.exe" scripts/remote-deploy.sh
        set DEPLOY_RESULT=%ERRORLEVEL%
    ) else if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" (
        echo [INFO] 使用Git Bash部署脚本...
        echo.
        "%ProgramFiles(x86)%\Git\bin\bash.exe" scripts/remote-deploy.sh
        set DEPLOY_RESULT=%ERRORLEVEL%
    ) else (
        echo [ERROR] 未找到PowerShell或Git Bash
        echo [INFO] 请安装以下之一：
        echo   1. Windows PowerShell (通常已预装)
        echo   2. Git for Windows: https://git-scm.com/download/win
        echo.
        pause
        exit /b 1
    )
)

echo.
if %DEPLOY_RESULT% EQU 0 (
    echo [SUCCESS] 部署成功！
    echo.
    echo 服务访问地址:
    echo   应用服务: http://192.168.100.15:8080
    echo   健康检查: http://192.168.100.15:8080/health
    echo   API文档: http://192.168.100.15:8080/api/v1
    echo   Grafana监控: http://192.168.100.15:3000 (admin/admin123)
    echo   Prometheus: http://192.168.100.15:9090
    echo.
    echo 管理命令:
    echo   查看状态: ssh root@192.168.100.15 'cd /opt/info-management-system && ./scripts/deploy.sh prod status'
    echo   查看日志: ssh root@192.168.100.15 'cd /opt/info-management-system && ./scripts/deploy.sh prod logs'
    echo.
) else (
    echo [ERROR] 部署失败！
    echo.
    echo 故障排除建议:
    echo   1. 检查网络连接: ping 192.168.100.15
    echo   2. 检查SSH连接: ssh root@192.168.100.15
    echo   3. 查看详细错误信息
    echo.
    echo 重新部署选项:
    echo   PowerShell: .\scripts\deploy-remote.ps1
    echo   Git Bash: bash scripts/remote-deploy.sh
    echo.
)

pause