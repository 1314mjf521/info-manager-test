# Simple Notification Test - Test the title field fix
Write-Host "=== Simple Notification Test ===" -ForegroundColor Green

# Start server
Write-Host "Starting server..." -ForegroundColor Yellow
$serverProcess = Start-Process -FilePath ".\build\server.exe" -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 3

try {
    # Login
    $loginData = @{ username = "admin"; password = "admin123" }
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
    $token = $loginResponse.data.token
    $headers = @{ "Authorization" = "Bearer $token" }

    Write-Host "Login successful" -ForegroundColor Green

    # Test simple notification
    Write-Host "`nTesting simple notification..." -ForegroundColor Yellow
    
    $notificationData = @{
        type = "email"
        recipients = @("test@example.com")
        subject = "Simple Test"
        content = "This is a simple test notification"
        priority = 1
    }
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/notifications/send" -Method POST -Headers $headers -Body ($notificationData | ConvertTo-Json) -ContentType "application/json"
        Write-Host "Notification sent successfully!" -ForegroundColor Green
        Write-Host "Notification ID: $($response.data.id)" -ForegroundColor Cyan
        Write-Host "Status: $($response.data.status)" -ForegroundColor Cyan
        Write-Host "Title: $($response.data.title)" -ForegroundColor Cyan
    } catch {
        Write-Host "Failed to send notification: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test notification history
    Write-Host "`nTesting notification history..." -ForegroundColor Yellow
    
    try {
        $historyResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/notifications/history" -Method GET -Headers $headers
        $count = $historyResponse.data.notifications.Count
        Write-Host "Retrieved $count notifications from history" -ForegroundColor Green
        
        if ($count -gt 0) {
            $latest = $historyResponse.data.notifications[0]
            Write-Host "Latest notification:" -ForegroundColor Cyan
            Write-Host "  ID: $($latest.id)" -ForegroundColor White
            Write-Host "  Title: $($latest.title)" -ForegroundColor White
            Write-Host "  Subject: $($latest.subject)" -ForegroundColor White
            Write-Host "  Status: $($latest.status)" -ForegroundColor White
            Write-Host "  Type: $($latest.type)" -ForegroundColor White
        }
    } catch {
        Write-Host "Failed to get notification history: $($_.Exception.Message)" -ForegroundColor Red
    }

} catch {
    Write-Host "Error during test: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Stop server
    if ($serverProcess -and !$serverProcess.HasExited) {
        Write-Host "`nStopping server..." -ForegroundColor Yellow
        Stop-Process -Id $serverProcess.Id -Force
    }
}

Write-Host "`n=== Simple Notification Test Completed ===" -ForegroundColor Green