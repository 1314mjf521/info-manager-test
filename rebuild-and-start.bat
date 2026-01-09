@echo off
echo 重新编译并启动后端服务器...

echo 停止现有服务器...
taskkill /f /im server.exe 2>nul

echo 编译后端...
go build -o build/server.exe cmd/server/main.go

if %errorlevel% neq 0 (
    echo 编译失败！
    pause
    exit /b 1
)

echo 启动服务器...
start "Info Management Server" build\server.exe

echo 等待服务器启动...
timeout /t 3 /nobreak >nul

echo 后端服务器已启动！
echo 访问地址: http://localhost:8080
echo 前端地址: http://localhost:3000
echo 默认账号: admin / admin123
echo.
echo 按任意键关闭此窗口...
pause >nul