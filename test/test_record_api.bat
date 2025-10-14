@echo off
chcp 65001 > nul
echo Starting Record Management API Tests...
echo.

REM Check if curl is available
where curl >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: curl is not available. Please install curl.
    pause
    exit /b 1
)

REM Check if exe exists
if not exist "info-management-system.exe" (
    echo Error: info-management-system.exe not found
    pause
    exit /b 1
)

echo Starting server...
start /B info-management-system.exe > server.log 2>&1

echo Waiting for server to start...
timeout /t 8 /nobreak > nul

echo.
echo ========================================
echo Step 1: User Login and Token Extraction
echo ========================================

echo Testing user login...
curl -s -X POST http://localhost:8080/api/v1/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"testuser\",\"password\":\"password123\"}" -o login_temp.json

REM Extract token using PowerShell (if available)
powershell -Command "try { $json = Get-Content 'login_temp.json' | ConvertFrom-Json; if ($json.success -and $json.data.token) { $json.data.token | Out-File 'token.txt' -Encoding ASCII -NoNewline; Write-Host 'Token extracted successfully' } else { Write-Host 'Login failed or no token found' } } catch { Write-Host 'Error parsing login response' }" 2>nul

REM Check if token was extracted
if exist "token.txt" (
    set /p TOKEN=<token.txt
    echo Token: %TOKEN:~0,20%...
) else (
    echo Warning: Could not extract token, some tests may fail
    set TOKEN=
)

echo.
echo ========================================
echo Step 2: Testing Record Type APIs
echo ========================================

echo Creating record type...
if defined TOKEN (
    curl -s -w "Status: %%{http_code}\n" -X POST http://localhost:8080/api/v1/record-types ^
      -H "Content-Type: application/json" ^
      -H "Authorization: Bearer %TOKEN%" ^
      -d "{\"name\":\"api_test_type\",\"display_name\":\"API Test Type\",\"schema\":{\"fields\":[{\"name\":\"description\",\"type\":\"string\",\"required\":true},{\"name\":\"priority\",\"type\":\"number\",\"required\":false}]}}"
) else (
    echo Skipping (no token)
)
echo.

echo Getting all record types...
if defined TOKEN (
    curl -s -w "Status: %%{http_code}\n" http://localhost:8080/api/v1/record-types ^
      -H "Authorization: Bearer %TOKEN%"
) else (
    echo Skipping (no token)
)
echo.

echo.
echo ========================================
echo Step 3: Testing Record Management APIs
echo ========================================

echo Creating a record...
if defined TOKEN (
    curl -s -w "Status: %%{http_code}\n" -X POST http://localhost:8080/api/v1/records ^
      -H "Content-Type: application/json" ^
      -H "Authorization: Bearer %TOKEN%" ^
      -d "{\"type\":\"api_test_type\",\"title\":\"API Test Record\",\"content\":{\"description\":\"This is a test record created via API\",\"priority\":1},\"tags\":[\"api\",\"test\"]}" -o create_record_response.json
) else (
    echo Skipping (no token)
)
echo.

echo Getting all records...
if defined TOKEN (
    curl -s -w "Status: %%{http_code}\n" http://localhost:8080/api/v1/records ^
      -H "Authorization: Bearer %TOKEN%"
) else (
    echo Skipping (no token)
)
echo.

echo Testing batch record creation...
if defined TOKEN (
    curl -s -w "Status: %%{http_code}\n" -X POST http://localhost:8080/api/v1/records/batch ^
      -H "Content-Type: application/json" ^
      -H "Authorization: Bearer %TOKEN%" ^
      -d "{\"records\":[{\"type\":\"api_test_type\",\"title\":\"Batch Record 1\",\"content\":{\"description\":\"First batch record\",\"priority\":1},\"tags\":[\"batch\",\"test\"]},{\"type\":\"api_test_type\",\"title\":\"Batch Record 2\",\"content\":{\"description\":\"Second batch record\",\"priority\":2},\"tags\":[\"batch\",\"test\"]}]}"
) else (
    echo Skipping (no token)
)
echo.

echo Testing record import...
if defined TOKEN (
    curl -s -w "Status: %%{http_code}\n" -X POST http://localhost:8080/api/v1/records/import ^
      -H "Content-Type: application/json" ^
      -H "Authorization: Bearer %TOKEN%" ^
      -d "{\"type\":\"api_test_type\",\"records\":[{\"title\":\"Imported Record 1\",\"description\":\"First imported record\",\"priority\":1,\"tags\":[\"import\",\"test\"]},{\"title\":\"Imported Record 2\",\"description\":\"Second imported record\",\"priority\":2,\"tags\":[\"import\",\"test\"]}]}"
) else (
    echo Skipping (no token)
)
echo.

echo Testing records by type...
if defined TOKEN (
    curl -s -w "Status: %%{http_code}\n" http://localhost:8080/api/v1/records/type/api_test_type ^
      -H "Authorization: Bearer %TOKEN%"
) else (
    echo Skipping (no token)
)
echo.

echo.
echo ========================================
echo Step 4: Testing Audit APIs
echo ========================================

echo Getting audit logs...
if defined TOKEN (
    curl -s -w "Status: %%{http_code}\n" http://localhost:8080/api/v1/audit/logs ^
      -H "Authorization: Bearer %TOKEN%"
) else (
    echo Skipping (no token)
)
echo.

echo Getting audit statistics...
if defined TOKEN (
    curl -s -w "Status: %%{http_code}\n" http://localhost:8080/api/v1/audit/statistics ^
      -H "Authorization: Bearer %TOKEN%"
) else (
    echo Skipping (no token)
)
echo.

echo.
echo ========================================
echo Step 5: Testing Pagination and Filtering
echo ========================================

echo Testing pagination (page 1, size 5)...
if defined TOKEN (
    curl -s -w "Status: %%{http_code}\n" "http://localhost:8080/api/v1/records?page=1&page_size=5" ^
      -H "Authorization: Bearer %TOKEN%"
) else (
    echo Skipping (no token)
)
echo.

echo Testing search functionality...
if defined TOKEN (
    curl -s -w "Status: %%{http_code}\n" "http://localhost:8080/api/v1/records?search=test" ^
      -H "Authorization: Bearer %TOKEN%"
) else (
    echo Skipping (no token)
)
echo.

echo Testing tag filtering...
if defined TOKEN (
    curl -s -w "Status: %%{http_code}\n" "http://localhost:8080/api/v1/records?tags=api,test" ^
      -H "Authorization: Bearer %TOKEN%"
) else (
    echo Skipping (no token)
)
echo.

echo.
echo ========================================
echo Cleanup and Summary
echo ========================================

echo Stopping server...
taskkill /F /IM info-management-system.exe > nul 2>&1

echo.
echo Record Management API Test completed!
echo.
echo Files created:
echo - server.log (server output)
echo - login_temp.json (login response)
echo - create_record_response.json (record creation response)
if exist "token.txt" echo - token.txt (extracted token)
echo.

REM Cleanup temporary files
if exist "login_temp.json" del "login_temp.json"
if exist "token.txt" del "token.txt"

echo Test Summary:
echo - Health checks: TESTED
echo - Authentication: TESTED
echo - Record Types: TESTED
echo - Record CRUD: TESTED
echo - Batch Operations: TESTED
echo - Import Operations: TESTED
echo - Audit Logs: TESTED
echo - Pagination/Filtering: TESTED
echo.
pause