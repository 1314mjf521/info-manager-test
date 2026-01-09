@echo off
chcp 65001 >nul
echo 重新编译并启动前后端服务...

echo.
echo 停止现有服务器...
taskkill /f /im "server.exe" >nul 2>&1
taskkill /f /im "info-management-system.exe" >nul 2>&1
taskkill /f /im "node.exe" >nul 2>&1

echo.
echo 编译后端...
go build -o info-management-system.exe ./cmd/server
if %errorlevel% neq 0 (
    echo 后端编译失败！
    pause
    exit /b 1
)

echo.
echo 检查前端依赖...
cd frontend
if not exist "node_modules" (
    echo 安装前端依赖...
    npm install
    if %errorlevel% neq 0 (
        echo 前端依赖安装失败！
        cd ..
        pause
        exit /b 1
    )
) else (
    echo 前端依赖已存在
)

echo.
echo 构建前端...
npm run build
if %errorlevel% neq 0 (
    echo 前端构建失败！
    cd ..
    pause
    exit /b 1
)

cd ..

echo.
echo 启动后端服务器...
start "后端服务" info-management-system.exe

echo.
echo 等待后端服务启动...
timeout /t 5 /nobreak >nul

echo.
echo 启动前端开发服务器...
cd frontend
start "前端服务" npm run dev

cd ..

echo.
echo ================================
echo 🎉 服务启动完成！
echo ================================
echo 前端地址: http://localhost:5173
echo 后端地址: http://localhost:8080
echo API文档: http://localhost:8080/swagger/index.html
echo 健康检查: http://localhost:8080/api/v1/health
echo ================================
echo 默认账号: admin / admin123
echo.
echo 💡 提示:
echo - 前端支持热重载，修改代码会自动刷新
echo - 后端修改需要重新运行此脚本
echo - 关闭此窗口不会停止服务
echo.
echo 按任意键关闭此窗口...
pause >nul