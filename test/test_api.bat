@echo off
chcp 65001 > nul
echo Starting API Tests...
echo.

REM Check if curl is available
where curl >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: curl is not available. Please install curl or use PowerShell version.
    echo You can run: test_api.ps1
    pause
    exit /b 1
)

REM Check if exe exists
if not exist "info-management-system.exe" (
    echo Error: info-management-system.exe not found
    echo Please make sure the executable is in the current directory
    pause
    exit /b 1
)

REM Check if config exists
if not exist "configs\config.yaml" (
    echo Warning: config.yaml not found, copying from example...
    if not exist "configs" mkdir configs
    copy "configs\config.example.yaml" "configs\config.yaml" > nul
)

echo Starting server...
start /B info-management-system.exe > server.log 2>&1

echo Waiting for server to start...
timeout /t 8 /nobreak > nul

echo.
echo ========================================
echo Testing Health Check Endpoints
echo ========================================

echo Testing /health endpoint...
curl -s -w "Status: %%{http_code}\n" http://localhost:8080/health
echo.

echo Testing /ready endpoint...
curl -s -w "Status: %%{http_code}\n" http://localhost:8080/ready
echo.

echo.
echo ========================================
echo Testing Authentication APIs
echo ========================================

echo Testing user registration...
curl -s -w "Status: %%{http_code}\n" -X POST http://localhost:8080/api/v1/auth/register ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"testuser\",\"email\":\"test@example.com\",\"password\":\"password123\"}"
echo.

echo Testing user login...
curl -s -w "Status: %%{http_code}\n" -X POST http://localhost:8080/api/v1/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"testuser\",\"password\":\"password123\"}" -o login_response.json
echo.

echo Login response saved to login_response.json
echo.

echo.
echo ========================================
echo Stopping Server
echo ========================================

echo Stopping server...
taskkill /F /IM info-management-system.exe > nul 2>&1

echo.
echo API Test completed!
echo Check server.log for server output
echo Check login_response.json for login response
echo.
pause