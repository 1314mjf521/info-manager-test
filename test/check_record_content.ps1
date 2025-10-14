# Check Record Content Script
Write-Host "=== Checking Record Management Interface Issues ===" -ForegroundColor Green

# Check if backend server is running
Write-Host "`n1. Checking backend server status..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://192.168.100.15:8080/api/v1/health" -Method GET -TimeoutSec 5
    Write-Host "Backend server is running normally" -ForegroundColor Green
    Write-Host "Server status: $($response.status)" -ForegroundColor Cyan
} catch {
    Write-Host "Backend server is not accessible: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please ensure backend server is running" -ForegroundColor Yellow
    exit 1
}

# Check record list
Write-Host "`n2. Checking record list..." -ForegroundColor Yellow
try {
    # Try to login and get token
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://192.168.100.15:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    Write-Host "Login successful, token obtained" -ForegroundColor Green

    # Get record list
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    $records = Invoke-RestMethod -Uri "http://192.168.100.15:8080/api/v1/records?page=1&page_size=10" -Method GET -Headers $headers
    Write-Host "Successfully retrieved record list" -ForegroundColor Green
    Write-Host "Total records: $($records.data.total)" -ForegroundColor Cyan
    Write-Host "Current page records: $($records.data.records.Count)" -ForegroundColor Cyan

    # Check each record content
    Write-Host "`n3. Checking record content..." -ForegroundColor Yellow
    foreach ($record in $records.data.records) {
        Write-Host "`nRecord ID: $($record.id)" -ForegroundColor Cyan
        Write-Host "Title: $($record.title)" -ForegroundColor White
        Write-Host "Type: $($record.type)" -ForegroundColor White
        Write-Host "Version: $($record.version)" -ForegroundColor White
        Write-Host "Creator: $($record.creator)" -ForegroundColor White
        Write-Host "Created: $($record.created_at)" -ForegroundColor White
        Write-Host "Updated: $($record.updated_at)" -ForegroundColor White
        
        # Check if content contains Vite HMR logs
        $contentStr = $record.content | ConvertTo-Json -Depth 10
        if ($contentStr -like "*vite*hmr*" -or $contentStr -like "*[vite]*") {
            Write-Host "WARNING: Abnormal content found - contains Vite HMR logs" -ForegroundColor Red
            Write-Host "Content preview: $($contentStr.Substring(0, [Math]::Min(200, $contentStr.Length)))..." -ForegroundColor Yellow
        } else {
            Write-Host "Content is normal" -ForegroundColor Green
            Write-Host "Content preview: $($contentStr.Substring(0, [Math]::Min(100, $contentStr.Length)))..." -ForegroundColor Gray
        }
        
        if ($record.tags) {
            Write-Host "Tags: $($record.tags -join ', ')" -ForegroundColor Gray
        }
        Write-Host "---" -ForegroundColor DarkGray
    }

} catch {
    Write-Host "Error checking records: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $errorBody = $reader.ReadToEnd()
        Write-Host "Error details: $errorBody" -ForegroundColor Yellow
    }
}

# Check audit logs
Write-Host "`n4. Checking recent audit logs..." -ForegroundColor Yellow
try {
    $auditLogs = Invoke-RestMethod -Uri "http://192.168.100.15:8080/api/v1/audit/logs?page=1&page_size=5" -Method GET -Headers $headers
    Write-Host "Successfully retrieved audit logs" -ForegroundColor Green
    
    foreach ($log in $auditLogs.data.logs) {
        Write-Host "`nAudit Log ID: $($log.id)" -ForegroundColor Cyan
        Write-Host "User: $($log.username)" -ForegroundColor White
        Write-Host "Action: $($log.action)" -ForegroundColor White
        Write-Host "Resource Type: $($log.resource_type)" -ForegroundColor White
        Write-Host "Resource ID: $($log.resource_id)" -ForegroundColor White
        Write-Host "Time: $($log.created_at)" -ForegroundColor White
        
        # Check if new values contain abnormal content
        if ($log.new_values) {
            $newValuesStr = $log.new_values | ConvertTo-Json -Depth 10
            if ($newValuesStr -like "*vite*hmr*" -or $newValuesStr -like "*[vite]*") {
                Write-Host "WARNING: Abnormal audit log found - contains Vite HMR logs" -ForegroundColor Red
                Write-Host "New values preview: $($newValuesStr.Substring(0, [Math]::Min(200, $newValuesStr.Length)))..." -ForegroundColor Yellow
            }
        }
        Write-Host "---" -ForegroundColor DarkGray
    }

} catch {
    Write-Host "Error checking audit logs: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Check Complete ===" -ForegroundColor Green