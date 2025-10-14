# Simple announcement system test
$baseUrl = "http://localhost:8080"
$apiUrl = "$baseUrl/api/v1"

Write-Host "=== Announcement System Test ===" -ForegroundColor Green

# 1. Login
Write-Host "`n1. Login..." -ForegroundColor Yellow
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
    Write-Host "Login successful" -ForegroundColor Green
} catch {
    Write-Host "Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. Create announcement
Write-Host "`n2. Create announcement..." -ForegroundColor Yellow
$announcementData = @{
    title = "System Maintenance Notice"
    type = "maintenance"
    priority = 5
    content = "System will be under maintenance tonight"
    start_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    end_time = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ssZ")
    is_active = $true
    is_sticky = $true
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$apiUrl/announcements" -Method POST -Body $announcementData -Headers $headers
    $announcementId = $createResponse.id
    Write-Host "Announcement created successfully, ID: $announcementId" -ForegroundColor Green
} catch {
    Write-Host "Failed to create announcement: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. Get announcements list
Write-Host "`n3. Get announcements list..." -ForegroundColor Yellow
try {
    $listResponse = Invoke-RestMethod -Uri "$apiUrl/announcements?page=1&page_size=10" -Method GET -Headers $headers
    Write-Host "Got announcements list successfully, total: $($listResponse.total)" -ForegroundColor Green
} catch {
    Write-Host "Failed to get announcements list: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Update announcement
Write-Host "`n4. Update announcement..." -ForegroundColor Yellow
$updateData = @{
    title = "System Maintenance Notice - Updated"
    type = "warning"
    priority = 8
    content = "Maintenance time changed to 23:00-01:00 tonight"
    start_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    end_time = (Get-Date).AddDays(3).ToString("yyyy-MM-ddTHH:mm:ssZ")
    is_active = $true
    is_sticky = $true
} | ConvertTo-Json

try {
    $updateResponse = Invoke-RestMethod -Uri "$apiUrl/announcements/$announcementId" -Method PUT -Body $updateData -Headers $headers
    Write-Host "Announcement updated successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to update announcement: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Delete announcement
Write-Host "`n5. Delete test announcement..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "$apiUrl/announcements/$announcementId" -Method DELETE -Headers $headers
    Write-Host "Announcement deleted successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to delete announcement: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Test frontend
Write-Host "`n6. Test frontend page..." -ForegroundColor Yellow
try {
    $frontendResponse = Invoke-WebRequest -Uri "$baseUrl" -Method GET -TimeoutSec 10
    if ($frontendResponse.StatusCode -eq 200) {
        Write-Host "Frontend page accessible" -ForegroundColor Green
    }
} catch {
    Write-Host "Frontend page not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
Write-Host "Please visit $baseUrl to check the frontend interface" -ForegroundColor Cyan