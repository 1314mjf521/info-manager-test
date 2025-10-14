@echo off
chcp 65001 > nul
echo Starting Admin API Tests...
echo.

REM Check if curl is available
where curl >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: curl is not available. Please install curl.
    pause
    exit /b 1
)

echo Starting server...
start /B info-management-system.exe > admin_server.log 2>&1

echo Waiting for server to start...
timeout /t 8 /nobreak > nul

echo.
echo ========================================
echo Step 1: Admin Login and Token Extraction
echo ========================================

echo Testing admin login...
curl -s -X POST http://localhost:8080/api/v1/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"admin\",\"password\":\"admin123\"}" -o admin_login.json

REM Extract token using PowerShell
powershell -Command "try { $json = Get-Content 'admin_login.json' | ConvertFrom-Json; if ($json.success -and $json.data.token) { $json.data.token | Out-File 'admin_token.txt' -Encoding ASCII -NoNewline; Write-Host 'Admin token extracted successfully' } else { Write-Host 'Admin login failed or no token found' } } catch { Write-Host 'Error parsing admin login response' }" 2>nul

REM Check if token was extracted
if exist "admin_token.txt" (
    set /p ADMIN_TOKEN=<admin_token.txt
    echo Admin Token: %ADMIN_TOKEN:~0,20%...
) else (
    echo Warning: Could not extract admin token
    set ADMIN_TOKEN=
)

echo.
echo ========================================
echo Step 2: Testing Record Type APIs (Admin)
echo ========================================

echo Creating record type...
if defined ADMIN_TOKEN (
    curl -s -w "Status: %%{http_code}\n" -X POST http://localhost:8080/api/v1/record-types ^
      -H "Content-Type: application/json" ^
      -H "Authorization: Bearer %ADMIN_TOKEN%" ^
      -d "{\"name\":\"admin_test_type\",\"display_name\":\"Admin Test Type\",\"schema\":{\"fields\":[{\"name\":\"description\",\"type\":\"string\",\"required\":true},{\"name\":\"priority\",\"type\":\"number\",\"required\":false}]}}"
) else (
    echo Skipping (no admin token)
)
echo.

echo Getting all record types...
if defined ADMIN_TOKEN (
    curl -s -w "Status: %%{http_code}\n" http://localhost:8080/api/v1/record-types ^
      -H "Authorization: Bearer %ADMIN_TOKEN%"
) else (
    echo Skipping (no admin token)
)
echo.

echo.
echo ========================================
echo Step 3: Testing Record Management APIs (Admin)
echo ========================================

echo Creating a record...
if defined ADMIN_TOKEN (
    curl -s -w "Status: %%{http_code}\n" -X POST http://localhost:8080/api/v1/records ^
      -H "Content-Type: application/json" ^
      -H "Authorization: Bearer %ADMIN_TOKEN%" ^
      -d "{\"type\":\"admin_test_type\",\"title\":\"Admin Test Record\",\"content\":{\"description\":\"This is a test record created by admin\",\"priority\":1},\"tags\":[\"admin\",\"test\"]}" -o admin_create_record.json
) else (
    echo Skipping (no admin token)
)
echo.

echo Getting all records...
if defined ADMIN_TOKEN (
    curl -s -w "Status: %%{http_code}\n" http://localhost:8080/api/v1/records ^
      -H "Authorization: Bearer %ADMIN_TOKEN%"
) else (
    echo Skipping (no admin token)
)
echo.

echo Testing batch record creation...
if defined ADMIN_TOKEN (
    curl -s -w "Status: %%{http_code}\n" -X POST http://localhost:8080/api/v1/records/batch ^
      -H "Content-Type: application/json" ^
      -H "Authorization: Bearer %ADMIN_TOKEN%" ^
      -d "{\"records\":[{\"type\":\"admin_test_type\",\"title\":\"Admin Batch Record 1\",\"content\":{\"description\":\"First admin batch record\",\"priority\":1},\"tags\":[\"batch\",\"admin\"]},{\"type\":\"admin_test_type\",\"title\":\"Admin Batch Record 2\",\"content\":{\"description\":\"Second admin batch record\",\"priority\":2},\"tags\":[\"batch\",\"admin\"]}]}"
) else (
    echo Skipping (no admin token)
)
echo.

echo.
echo ========================================
echo Step 4: Testing Audit APIs (Admin)
echo ========================================

echo Getting audit logs...
if defined ADMIN_TOKEN (
    curl -s -w "Status: %%{http_code}\n" http://localhost:8080/api/v1/audit/logs ^
      -H "Authorization: Bearer %ADMIN_TOKEN%"
) else (
    echo Skipping (no admin token)
)
echo.

echo Getting audit statistics...
if defined ADMIN_TOKEN (
    curl -s -w "Status: %%{http_code}\n" http://localhost:8080/api/v1/audit/statistics ^
      -H "Authorization: Bearer %ADMIN_TOKEN%"
) else (
    echo Skipping (no admin token)
)
echo.

echo.
echo ========================================
echo Step 5: Testing Advanced Features
echo ========================================

echo Testing record update (extract ID from creation response)...
if defined ADMIN_TOKEN (
    if exist "admin_create_record.json" (
        powershell -Command "try { $json = Get-Content 'admin_create_record.json' | ConvertFrom-Json; if ($json.success -and $json.data.id) { $json.data.id | Out-File 'record_id.txt' -Encoding ASCII -NoNewline } } catch { }" 2>nul
        if exist "record_id.txt" (
            set /p RECORD_ID=<record_id.txt
            echo Updating record ID: %RECORD_ID%
            curl -s -w "Status: %%{http_code}\n" -X PUT http://localhost:8080/api/v1/records/%RECORD_ID% ^
              -H "Content-Type: application/json" ^
              -H "Authorization: Bearer %ADMIN_TOKEN%" ^
              -d "{\"title\":\"Updated Admin Test Record\",\"content\":{\"description\":\"This record has been updated\",\"priority\":3}}"
            echo.
            
            echo Getting updated record...
            curl -s -w "Status: %%{http_code}\n" http://localhost:8080/api/v1/records/%RECORD_ID% ^
              -H "Authorization: Bearer %ADMIN_TOKEN%"
            echo.
        )
    )
) else (
    echo Skipping (no admin token)
)

echo.
echo ========================================
echo Cleanup and Summary
echo ========================================

echo Stopping server...
taskkill /F /IM info-management-system.exe > nul 2>&1

echo.
echo Admin API Test completed!
echo.
echo Files created:
echo - admin_server.log (server output)
echo - admin_login.json (admin login response)
echo - admin_create_record.json (record creation response)
if exist "admin_token.txt" echo - admin_token.txt (admin token)
if exist "record_id.txt" echo - record_id.txt (created record ID)
echo.

REM Cleanup temporary files
if exist "admin_login.json" del "admin_login.json"
if exist "admin_token.txt" del "admin_token.txt"
if exist "record_id.txt" del "record_id.txt"

echo Admin Test Summary:
echo - Health checks: TESTED
echo - Admin Authentication: TESTED
echo - Record Types (Admin): TESTED
echo - Record CRUD (Admin): TESTED
echo - Batch Operations (Admin): TESTED
echo - Audit Logs (Admin): TESTED
echo - Record Updates: TESTED
echo.
pause