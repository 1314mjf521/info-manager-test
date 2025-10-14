# Debug Announcement System
# Analyze announcement publishing and display issues

Write-Host "=== Debugging Announcement System ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080/api/v1"

# Step 1: Login
Write-Host "1. Login to get authentication token..." -ForegroundColor Yellow
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    }
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
    
    if ($loginResponse.success) {
        $token = $loginResponse.data.token
        $headers = @{ "Authorization" = "Bearer $token" }
        Write-Host "Success: Login completed" -ForegroundColor Green
    } else {
        throw "Login failed: $($loginResponse.message)"
    }
} catch {
    Write-Host "Error: Login failed - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Check existing announcements
Write-Host "`n2. Checking existing announcements..." -ForegroundColor Yellow
try {
    $announcementsResponse = Invoke-RestMethod -Uri "$baseUrl/announcements" -Method Get -Headers $headers
    
    if ($announcementsResponse.success) {
        $announcements = $announcementsResponse.data.announcements
        Write-Host "Success: Retrieved $($announcements.Count) announcements" -ForegroundColor Green
        
        if ($announcements.Count -gt 0) {
            Write-Host "`nExisting announcements:" -ForegroundColor Cyan
            foreach ($announcement in $announcements) {
                Write-Host "  ID: $($announcement.id)" -ForegroundColor Gray
                Write-Host "  Title: $($announcement.title)" -ForegroundColor Gray
                Write-Host "  Type: $($announcement.type)" -ForegroundColor Gray
                Write-Host "  Priority: $($announcement.priority)" -ForegroundColor Gray
                Write-Host "  Active: $($announcement.is_active)" -ForegroundColor $(if ($announcement.is_active) { "Green" } else { "Red" })
                Write-Host "  Sticky: $($announcement.is_sticky)" -ForegroundColor Gray
                Write-Host "  Start Time: $($announcement.start_time)" -ForegroundColor Gray
                Write-Host "  End Time: $($announcement.end_time)" -ForegroundColor Gray
                Write-Host "  View Count: $($announcement.view_count)" -ForegroundColor Gray
                Write-Host "  Created At: $($announcement.created_at)" -ForegroundColor Gray
                Write-Host "  ---" -ForegroundColor Gray
            }
        } else {
            Write-Host "No existing announcements found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Warning: Failed to get announcements - $($announcementsResponse.message)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: Failed to get announcements - $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Create a test announcement
Write-Host "`n3. Creating a test announcement..." -ForegroundColor Yellow
try {
    $testAnnouncement = @{
        title = "Test Announcement $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        type = "info"
        priority = 5
        content = "This is a test announcement to verify the publishing system works correctly."
        is_active = $true
        is_sticky = $false
        start_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        end_time = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/announcements" -Method Post -Body ($testAnnouncement | ConvertTo-Json) -ContentType "application/json" -Headers $headers
    
    if ($createResponse.success) {
        $newAnnouncement = $createResponse.data
        Write-Host "Success: Created test announcement" -ForegroundColor Green
        Write-Host "  ID: $($newAnnouncement.id)" -ForegroundColor Gray
        Write-Host "  Title: $($newAnnouncement.title)" -ForegroundColor Gray
        Write-Host "  Active: $($newAnnouncement.is_active)" -ForegroundColor Green
    } else {
        Write-Host "Error: Failed to create announcement - $($createResponse.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: Failed to create announcement - $($_.Exception.Message)" -ForegroundColor Red
}

# Step 4: Check if announcement appears in public API
Write-Host "`n4. Checking public announcement API..." -ForegroundColor Yellow
try {
    # Try to access announcements without authentication (public endpoint)
    $publicResponse = Invoke-RestMethod -Uri "$baseUrl/announcements/public" -Method Get
    
    if ($publicResponse.success) {
        $publicAnnouncements = $publicResponse.data
        Write-Host "Success: Retrieved $($publicAnnouncements.Count) public announcements" -ForegroundColor Green
        
        if ($publicAnnouncements.Count -gt 0) {
            Write-Host "`nPublic announcements:" -ForegroundColor Cyan
            foreach ($announcement in $publicAnnouncements) {
                Write-Host "  Title: $($announcement.title)" -ForegroundColor Gray
                Write-Host "  Type: $($announcement.type)" -ForegroundColor Gray
                Write-Host "  Active: $($announcement.is_active)" -ForegroundColor $(if ($announcement.is_active) { "Green" } else { "Red" })
            }
        }
    } else {
        Write-Host "Warning: Public announcements API failed - $($publicResponse.message)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Info: Public announcements endpoint may not exist - $($_.Exception.Message)" -ForegroundColor Gray
    
    # Try alternative endpoint
    try {
        $altResponse = Invoke-RestMethod -Uri "$baseUrl/announcements?public=true" -Method Get
        Write-Host "Alternative public endpoint works" -ForegroundColor Green
    } catch {
        Write-Host "Alternative public endpoint also failed" -ForegroundColor Yellow
    }
}

# Step 5: Check announcement visibility logic
Write-Host "`n5. Analyzing announcement visibility logic..." -ForegroundColor Yellow
if ($announcements -and $announcements.Count -gt 0) {
    $activeAnnouncements = $announcements | Where-Object { $_.is_active -eq $true }
    $currentTime = Get-Date
    
    Write-Host "Visibility Analysis:" -ForegroundColor Cyan
    Write-Host "  Total announcements: $($announcements.Count)" -ForegroundColor Gray
    Write-Host "  Active announcements: $($activeAnnouncements.Count)" -ForegroundColor Gray
    
    foreach ($announcement in $announcements) {
        $isVisible = $announcement.is_active
        
        # Check time constraints
        if ($announcement.start_time) {
            $startTime = [DateTime]::Parse($announcement.start_time)
            if ($currentTime -lt $startTime) {
                $isVisible = $false
            }
        }
        
        if ($announcement.end_time) {
            $endTime = [DateTime]::Parse($announcement.end_time)
            if ($currentTime -gt $endTime) {
                $isVisible = $false
            }
        }
        
        Write-Host "  Announcement '$($announcement.title)': $(if ($isVisible) { 'VISIBLE' } else { 'HIDDEN' })" -ForegroundColor $(if ($isVisible) { "Green" } else { "Red" })
    }
}

Write-Host "`n=== Analysis Results ===" -ForegroundColor Green

Write-Host "`nIssues Identified:" -ForegroundColor Red
Write-Host "  1. Public announcement endpoint may be missing" -ForegroundColor Yellow
Write-Host "  2. Frontend may not have announcement display component" -ForegroundColor Yellow
Write-Host "  3. Announcement preview/view functionality missing" -ForegroundColor Yellow

Write-Host "`nRecommended Fixes:" -ForegroundColor Cyan
Write-Host "  Backend:" -ForegroundColor White
Write-Host "    - Add public announcement endpoint" -ForegroundColor Gray
Write-Host "    - Implement announcement visibility logic" -ForegroundColor Gray
Write-Host "    - Add announcement view tracking" -ForegroundColor Gray
Write-Host "  Frontend:" -ForegroundColor White
Write-Host "    - Add announcement display component" -ForegroundColor Gray
Write-Host "    - Add preview/view buttons to management interface" -ForegroundColor Gray
Write-Host "    - Implement user announcement notification system" -ForegroundColor Gray

Write-Host "`n=== Announcement System Debug Complete ===" -ForegroundColor Green