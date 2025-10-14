@echo off
echo 启动信息记录管理系统...
echo.

REM 检查配置文件是否存在
if not exist "configs\config.yaml" (
    echo 错误：找不到配置文件 configs\config.yaml
    echo 请先复制 configs\config.example.yaml 为 configs\config.yaml 并修改配置
    pause
    exit /b 1
)

REM 检查可执行文件是否存在
if not exist "build\back.exe" (
    echo 错误：找不到可执行文件 build\back.exe
    echo 请先编译项目：go build -o build\back.exe .\cmd\server
    pause
    exit /b 1
)

REM 启动应用程序
build\back.exe

pause