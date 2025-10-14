@echo off
chcp 65001 > nul
echo Starting Debug API Tests...
echo.

REM Check if curl is available
where curl >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: curl is not available. Please install curl.
    pause
    exit /b 1
)

echo Starting server...
start /B ..\build\info-management-system.exe > debug_server.log 2>&1

echo Waiting for server to start...
timeout /t 8 /nobreak > nul

echo.
echo ========================================
echo Step 1: Admin Login
echo ========================================

echo Testing admin login...
curl -s -X POST http://localhost:8080/api/v1/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"admin\",\"password\":\"admin123\"}" -o debug_login.json

REM Extract token using PowerShell
powershell -Command "try { $json = Get-Content 'debug_login.json' | ConvertFrom-Json; if ($json.success -and $json.data.token) { $json.data.token | Out-File 'debug_token.txt' -Encoding ASCII -NoNewline; Write-Host 'Token extracted successfully' } else { Write-Host 'Login failed'; $json | ConvertTo-Json -Depth 10 | Write-Host } } catch { Write-Host 'Error parsing login response' }" 2>nul

REM Check if token was extracted
if exist "debug_token.txt" (
    set /p ADMIN_TOKEN=<debug_token.txt
    echo Token: %ADMIN_TOKEN:~0,20%...
) else (
    echo Warning: Could not extract admin token
    set ADMIN_TOKEN=
)

echo.
echo ========================================
echo Step 2: Create Record Type with Debug Info
echo ========================================

echo Creating record type 'debug_test_type'...
if defined ADMIN_TOKEN (
    curl -s -X POST http://localhost:8080/api/v1/record-types ^
      -H "Content-Type: application/json" ^
      -H "Authorization: Bearer %ADMIN_TOKEN%" ^
      -d "{\"name\":\"debug_test_type\",\"display_name\":\"Debug Test Type\",\"schema\":{\"fields\":[{\"name\":\"description\",\"type\":\"string\",\"required\":true}]}}" -o debug_create_type.json
    
    echo Response:
    type debug_create_type.json
    echo.
) else (
    echo Skipping (no admin token)
)

echo.
echo ========================================
echo Step 3: Create Record with Debug Info
echo ========================================

echo Creating a record with type 'debug_test_type'...
if defined ADMIN_TOKEN (
    curl -s -X POST http://localhost:8080/api/v1/records ^
      -H "Content-Type: application/json" ^
      -H "Authorization: Bearer %ADMIN_TOKEN%" ^
      -d "{\"type\":\"debug_test_type\",\"title\":\"Debug Test Record\",\"content\":{\"description\":\"This is a debug test record\"},\"tags\":[\"debug\",\"test\"]}" -o debug_create_record.json
    
    echo Response:
    type debug_create_record.json
    echo.
    
    echo Server log (last 20 lines):
    powershell -Command "Get-Content 'debug_server.log' | Select-Object -Last 20"
    echo.
) else (
    echo Skipping (no admin token)
)

echo.
echo ========================================
echo Step 4: List Record Types for Verification
echo ========================================

echo Getting all record types...
if defined ADMIN_TOKEN (
    curl -s http://localhost:8080/api/v1/record-types ^
      -H "Authorization: Bearer %ADMIN_TOKEN%" -o debug_list_types.json
    
    echo Response:
    type debug_list_types.json
    echo.
) else (
    echo Skipping (no admin token)
)

echo.
echo ========================================
echo Cleanup
echo ========================================

echo Stopping server...
taskkill /F /IM info-management-system.exe > nul 2>&1

echo.
echo Debug Test completed!
echo Check the following files for details:
echo - debug_server.log (server output)
echo - debug_login.json (login response)
echo - debug_create_type.json (record type creation response)
echo - debug_create_record.json (record creation response)
echo - debug_list_types.json (record types list)
echo.

REM Cleanup temporary files
if exist "debug_token.txt" del "debug_token.txt"

pause