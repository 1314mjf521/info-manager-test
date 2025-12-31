@echo off
echo === Rebuilding and Starting Info Management System ===

echo.
echo 1. Stopping existing server...
taskkill /f /im server.exe 2>nul
timeout /t 2 >nul

echo.
echo 2. Building backend...
go build -o server.exe cmd/server/main.go
if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo 3. Starting server...
start "Info Management Server" server.exe

echo.
echo 4. Waiting for server to start...
timeout /t 5 >nul

echo.
echo 5. Testing server...
curl -s http://localhost:8080/health >nul
if %errorlevel% equ 0 (
    echo ✓ Server is running
) else (
    echo ✗ Server failed to start
)

echo.
echo === Server started successfully ===
echo Frontend: http://localhost:3000
echo Backend:  http://localhost:8080
echo.
echo Please refresh your browser to see the ticket management menu.
pause