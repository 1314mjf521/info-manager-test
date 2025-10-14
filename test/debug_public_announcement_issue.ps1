# Debug public announcement display issue
$baseUrl = "http://localhost:8080"
$apiUrl = "$baseUrl/api/v1"

Write-Host "=== Debug Public Announcement Issue ===" -ForegroundColor Green

# 1. Admin login
Write-Host "`n1. Admin login..." -ForegroundColor Yellow
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$apiUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.token
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    Write-Host "Admin login successful" -ForegroundColor Green
} catch {
    Write-Host "Admin login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. Check all announcements (admin view)
Write-Host "`n2. Check all announcements (admin view)..." -ForegroundColor Yellow
try {
    $allResponse = Invoke-RestMethod -Uri "$apiUrl/announcements?page=1&page_size=20" -Method GET -Headers $headers
    Write-Host "Total announcements: $($allResponse.total)" -ForegroundColor Cyan
    
    if ($allResponse.announcements -and $allResponse.announcements.Count -gt 0) {
        Write-Host "All announcements:" -ForegroundColor White
        foreach ($announcement in $allResponse.announcements) {
            Write-Host "  - ID: $($announcement.id)" -ForegroundColor White
            Write-Host "    Title: $($announcement.title)" -ForegroundColor White
            Write-Host "    Type: $($announcement.type)" -ForegroundColor White
            Write-Host "    Active: $($announcement.is_active)" -ForegroundColor White
            Write-Host "    Sticky: $($announcement.is_sticky)" -ForegroundColor White
            Write-Host "    Start: $($announcement.start_time)" -ForegroundColor White
            Write-Host "    End: $($announcement.end_time)" -ForegroundColor White
            Write-Host "    Created: $($announcement.created_at)" -ForegroundColor White
            Write-Host "" -ForegroundColor White
        }
    } else {
        Write-Host "No announcements found in admin view" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to get admin announcements: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Check public announcements (no auth)
Write-Host "`n3. Check public announcements (no auth)..." -ForegroundColor Yellow
try {
    $publicResponse = Invoke-RestMethod -Uri "$apiUrl/announcements/public?page=1&page_size=20" -Method GET
    Write-Host "Public announcements count: $($publicResponse.announcements.Count)" -ForegroundColor Cyan
    Write-Host "Public total: $($publicResponse.total)" -ForegroundColor Cyan
    
    if ($publicResponse.announcements -and $publicResponse.announcements.Count -gt 0) {
        Write-Host "Public announcements:" -ForegroundColor White
        foreach ($announcement in $publicResponse.announcements) {
            Write-Host "  - ID: $($announcement.id)" -ForegroundColor White
            Write-Host "    Title: $($announcement.title)" -ForegroundColor White
            Write-Host "    Type: $($announcement.type)" -ForegroundColor White
            Write-Host "    Active: $($announcement.is_active)" -ForegroundColor White
            Write-Host "    Sticky: $($announcement.is_sticky)" -ForegroundColor White
            Write-Host "    Start: $($announcement.start_time)" -ForegroundColor White
            Write-Host "    End: $($announcement.end_time)" -ForegroundColor White
            Write-Host "" -ForegroundColor White
        }
    } else {
        Write-Host "No public announcements found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to get public announcements: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Create a test announcement
Write-Host "`n4. Create a test announcement..." -ForegroundColor Yellow
$testAnnouncement = @{
    title = "Debug Test Announcement"
    type = "info"
    priority = 5
    content = "This is a test announcement for debugging public display"
    start_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    end_time = (Get-Date).AddDays(1).ToString("yyyy-MM-ddTHH:mm:ssZ")
    is_active = $true
    is_sticky = $true
    target_users = ""
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$apiUrl/announcements" -Method POST -Body $testAnnouncement -Headers $headers
    $testId = $createResponse.id
    Write-Host "Test announcement created with ID: $testId" -ForegroundColor Green
    Write-Host "Details:" -ForegroundColor White
    Write-Host "  Title: $($createResponse.title)" -ForegroundColor White
    Write-Host "  Active: $($createResponse.is_active)" -ForegroundColor White
    Write-Host "  Start: $($createResponse.start_time)" -ForegroundColor White
    Write-Host "  End: $($createResponse.end_time)" -ForegroundColor White
} catch {
    Write-Host "Failed to create test announcement: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
    exit 1
}

# 5. Check public announcements again
Write-Host "`n5. Check public announcements after creation..." -ForegroundColor Yellow
try {
    $publicResponse2 = Invoke-RestMethod -Uri "$apiUrl/announcements/public?page=1&page_size=20" -Method GET
    Write-Host "Public announcements count: $($publicResponse2.announcements.Count)" -ForegroundColor Cyan
    
    if ($publicResponse2.announcements -and $publicResponse2.announcements.Count -gt 0) {
        Write-Host "Public announcements after creation:" -ForegroundColor White
        foreach ($announcement in $publicResponse2.announcements) {
            Write-Host "  - ID: $($announcement.id)" -ForegroundColor White
            Write-Host "    Title: $($announcement.title)" -ForegroundColor White
            Write-Host "    Active: $($announcement.is_active)" -ForegroundColor White
            if ($announcement.id -eq $testId) {
                Write-Host "    *** THIS IS OUR TEST ANNOUNCEMENT ***" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "Still no public announcements found!" -ForegroundColor Red
    }
} catch {
    Write-Host "Failed to get public announcements: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Check the specific test announcement
Write-Host "`n6. Check the specific test announcement..." -ForegroundColor Yellow
try {
    $specificResponse = Invoke-RestMethod -Uri "$apiUrl/announcements/$testId" -Method GET -Headers $headers
    Write-Host "Specific announcement details:" -ForegroundColor White
    Write-Host "  ID: $($specificResponse.id)" -ForegroundColor White
    Write-Host "  Title: $($specificResponse.title)" -ForegroundColor White
    Write-Host "  Active: $($specificResponse.is_active)" -ForegroundColor White
    Write-Host "  Start: $($specificResponse.start_time)" -ForegroundColor White
    Write-Host "  End: $($specificResponse.end_time)" -ForegroundColor White
    Write-Host "  Created: $($specificResponse.created_at)" -ForegroundColor White
    Write-Host "  Updated: $($specificResponse.updated_at)" -ForegroundColor White
} catch {
    Write-Host "Failed to get specific announcement: $($_.Exception.Message)" -ForegroundColor Red
}

# 7. Clean up
Write-Host "`n7. Clean up test announcement..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "$apiUrl/announcements/$testId" -Method DELETE -Headers $headers
    Write-Host "Test announcement deleted" -ForegroundColor Green
} catch {
    Write-Host "Failed to delete test announcement: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Debug Complete ===" -ForegroundColor Green