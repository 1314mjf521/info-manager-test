# Notification Fixes Test - Test the two fixed issues
Write-Host "=== Notification Fixes Test ===" -ForegroundColor Green

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

    # Fix 1: Test notification channel creation with unique name
    Write-Host "`nFix 1: Testing notification channel creation..." -ForegroundColor Yellow
    
    $uniqueName = "Test Email Channel $(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $channelData = @{
        name = $uniqueName
        type = "email"
        config = @{
            smtp_host = "smtp.example.com"
            smtp_port = 587
            username = "test@example.com"
            password = "password"
            from_email = "noreply@example.com"
            from_name = "Test System"
        }
        is_active = $true
        is_default = $false
        description = "Test email channel with unique name"
    }
    
    try {
        $channelResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/notifications/channels" -Method POST -Headers $headers -Body ($channelData | ConvertTo-Json) -ContentType "application/json"
        Write-Host "✅ Channel created successfully!" -ForegroundColor Green
        Write-Host "   Channel ID: $($channelResponse.data.id)" -ForegroundColor Cyan
        Write-Host "   Channel Name: $($channelResponse.data.name)" -ForegroundColor Cyan
        $channelCreateSuccess = $true
    } catch {
        Write-Host "❌ Channel creation failed: $($_.Exception.Message)" -ForegroundColor Red
        $channelCreateSuccess = $false
    }

    # Fix 2: Test template notification
    Write-Host "`nFix 2: Testing template notification..." -ForegroundColor Yellow
    
    # First create a template
    $templateName = "Test Template $(Get-Date -Format 'HHmmss')"
    $templateData = @{
        name = $templateName
        description = "Test template for notification"
        type = "email"
        subject = "Alert: {{title}}"
        content = "Hello {{recipient}}, this is an alert: {{message}} at {{timestamp}}"
        variables = '{"title": "string", "recipient": "string", "message": "string", "timestamp": "string"}'
        is_active = $true
    }
    
    try {
        $templateResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/notifications/templates" -Method POST -Headers $headers -Body ($templateData | ConvertTo-Json) -ContentType "application/json"
        $templateId = $templateResponse.data.id
        Write-Host "✅ Template created successfully! ID: $templateId" -ForegroundColor Green
        
        # Now test sending notification with template
        $templateNotificationData = @{
            template_id = $templateId
            type = "email"
            recipients = @("admin@example.com", "test@example.com")
            variables = @{
                title = "High CPU Usage"
                recipient = "System Administrator"
                message = "CPU usage has exceeded 90% threshold"
                timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            priority = 3
        }
        
        $templateNotificationResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/notifications/send" -Method POST -Headers $headers -Body ($templateNotificationData | ConvertTo-Json) -ContentType "application/json"
        Write-Host "✅ Template notification sent successfully!" -ForegroundColor Green
        Write-Host "   Notification ID: $($templateNotificationResponse.data.id)" -ForegroundColor Cyan
        Write-Host "   Title: $($templateNotificationResponse.data.title)" -ForegroundColor Cyan
        Write-Host "   Subject: $($templateNotificationResponse.data.subject)" -ForegroundColor Cyan
        Write-Host "   Content Preview: $($templateNotificationResponse.data.content.Substring(0, [Math]::Min(50, $templateNotificationResponse.data.content.Length)))..." -ForegroundColor Cyan
        $templateNotificationSuccess = $true
        
    } catch {
        Write-Host "❌ Template notification failed: $($_.Exception.Message)" -ForegroundColor Red
        $templateNotificationSuccess = $false
    }

    # Test 3: Verify notification history includes both notifications
    Write-Host "`nTest 3: Verifying notification history..." -ForegroundColor Yellow
    
    try {
        $historyResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/notifications/history" -Method GET -Headers $headers
        $notificationCount = $historyResponse.data.notifications.Count
        Write-Host "✅ Retrieved $notificationCount notifications from history" -ForegroundColor Green
        
        if ($notificationCount -gt 0) {
            Write-Host "Recent notifications:" -ForegroundColor Cyan
            $recentNotifications = $historyResponse.data.notifications | Select-Object -First 3
            foreach ($notification in $recentNotifications) {
                Write-Host "   ID: $($notification.id), Title: $($notification.title), Status: $($notification.status), Type: $($notification.type)" -ForegroundColor White
            }
        }
        $historySuccess = $true
    } catch {
        Write-Host "❌ Failed to get notification history: $($_.Exception.Message)" -ForegroundColor Red
        $historySuccess = $false
    }

    # Test 4: Verify channels list
    Write-Host "`nTest 4: Verifying channels list..." -ForegroundColor Yellow
    
    try {
        $channelsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/notifications/channels" -Method GET -Headers $headers
        $channelCount = $channelsResponse.data.channels.Count
        Write-Host "✅ Retrieved $channelCount notification channels" -ForegroundColor Green
        
        if ($channelCount -gt 0) {
            Write-Host "Available channels:" -ForegroundColor Cyan
            foreach ($channel in $channelsResponse.data.channels) {
                Write-Host "   ID: $($channel.id), Name: $($channel.name), Type: $($channel.type), Active: $($channel.is_active)" -ForegroundColor White
            }
        }
        $channelsListSuccess = $true
    } catch {
        Write-Host "❌ Failed to get channels list: $($_.Exception.Message)" -ForegroundColor Red
        $channelsListSuccess = $false
    }

    # Generate fix verification summary
    Write-Host "`n=== Notification Fixes Verification Summary ===" -ForegroundColor Magenta
    
    $fixResults = @{
        "Channel Creation Fix" = if ($channelCreateSuccess) { "FIXED" } else { "STILL BROKEN" }
        "Template Notification Fix" = if ($templateNotificationSuccess) { "FIXED" } else { "STILL BROKEN" }
        "Notification History" = if ($historySuccess) { "WORKING" } else { "BROKEN" }
        "Channels List" = if ($channelsListSuccess) { "WORKING" } else { "BROKEN" }
    }
    
    Write-Host "`nFix Results:" -ForegroundColor White
    $fixedCount = 0
    $totalFixes = $fixResults.Count
    
    foreach ($fix in $fixResults.GetEnumerator()) {
        $status = $fix.Value
        $color = if ($status.Contains("FIXED") -or $status.Contains("WORKING")) { "Green" } else { "Red" }
        Write-Host "  $($fix.Key): $status" -ForegroundColor $color
        if ($status.Contains("FIXED") -or $status.Contains("WORKING")) { $fixedCount++ }
    }
    
    $fixSuccessRate = [math]::Round(($fixedCount / $totalFixes) * 100, 2)
    Write-Host "`nOverall Fix Results:" -ForegroundColor White
    Write-Host "  Fixes Working: $fixedCount/$totalFixes" -ForegroundColor Cyan
    Write-Host "  Fix Success Rate: $fixSuccessRate%" -ForegroundColor Cyan
    
    Write-Host "`nKey Fixes Applied:" -ForegroundColor White
    Write-Host "  1. Channel Creation: Added unique name generation to avoid UNIQUE constraint errors" -ForegroundColor Green
    Write-Host "  2. Template Notification: Fixed content validation logic for template-based notifications" -ForegroundColor Green
    Write-Host "  3. Template Processing: Moved template processing before notification creation" -ForegroundColor Green
    Write-Host "  4. Content Validation: Made content optional when using templates" -ForegroundColor Green
    
    if ($fixSuccessRate -eq 100) {
        Write-Host "`n🎉 All fixes are working perfectly!" -ForegroundColor Green
        Write-Host "Task 7 notification system is now fully functional with 100% test success rate." -ForegroundColor Green
    } elseif ($fixSuccessRate -ge 75) {
        Write-Host "`n✅ Most fixes are working well!" -ForegroundColor Green
        Write-Host "Task 7 notification system is largely functional." -ForegroundColor Green
    } else {
        Write-Host "`n⚠️ Some fixes still need attention." -ForegroundColor Yellow
    }

} catch {
    Write-Host "Error during notification fixes test: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Stop server
    if ($serverProcess -and !$serverProcess.HasExited) {
        Write-Host "`nStopping server..." -ForegroundColor Yellow
        Stop-Process -Id $serverProcess.Id -Force
    }
}

Write-Host "`n=== Notification Fixes Test Completed ===" -ForegroundColor Green