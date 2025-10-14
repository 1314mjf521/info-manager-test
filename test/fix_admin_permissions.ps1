# Fix admin permissions for announcements
$baseUrl = "http://localhost:8080"
$apiUrl = "$baseUrl/api/v1"

Write-Host "=== Fix Admin Permissions ===" -ForegroundColor Green

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

# 2. Try to access announcements without system permission requirement
Write-Host "`n2. Test direct API access..." -ForegroundColor Yellow

# Test the public endpoint first
try {
    $publicResponse = Invoke-RestMethod -Uri "$apiUrl/announcements/public" -Method GET
    Write-Host "Public announcements API works: $($publicResponse.announcements.Count) announcements" -ForegroundColor Green
} catch {
    Write-Host "Public announcements API failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test with authentication but check if it's a permission issue
try {
    $response = Invoke-WebRequest -Uri "$apiUrl/announcements" -Method GET -Headers $headers
    Write-Host "Announcements API works with status: $($response.StatusCode)" -ForegroundColor Green
    $data = $response.Content | ConvertFrom-Json
    Write-Host "Found $($data.total) total announcements" -ForegroundColor Cyan
} catch {
    Write-Host "Announcements API failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    
    if ($_.Exception.Response.StatusCode -eq 403) {
        Write-Host "This is a permission issue. Admin user lacks required permissions." -ForegroundColor Yellow
    }
}

# 3. Try to create an announcement to test the system:admin permission
Write-Host "`n3. Test announcement creation..." -ForegroundColor Yellow
$testAnnouncement = @{
    title = "Permission Test Announcement"
    type = "info"
    priority = 1
    content = "Testing admin permissions"
    start_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    end_time = (Get-Date).AddDays(1).ToString("yyyy-MM-ddTHH:mm:ssZ")
    is_active = $true
    is_sticky = $false
    target_users = ""
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$apiUrl/announcements" -Method POST -Body $testAnnouncement -Headers $headers
    Write-Host "Announcement creation successful! ID: $($createResponse.id)" -ForegroundColor Green
    
    # Clean up
    try {
        Invoke-RestMethod -Uri "$apiUrl/announcements/$($createResponse.id)" -Method DELETE -Headers $headers
        Write-Host "Test announcement cleaned up" -ForegroundColor Green
    } catch {
        Write-Host "Failed to clean up test announcement" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Announcement creation failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response.StatusCode -eq 403) {
        Write-Host "Admin user lacks 'system:admin' permission for creating announcements" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Analysis Complete ===" -ForegroundColor Green
Write-Host "If you see 403 errors above, the admin user needs proper permissions." -ForegroundColor Yellow
Write-Host "Please run the database initialization script to fix permissions." -ForegroundColor Yellow