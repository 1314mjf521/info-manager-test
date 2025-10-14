# Test user management batch operations
$baseUrl = "http://localhost:8080"
$apiUrl = "$baseUrl/api/v1"

Write-Host "=== User Management Batch Operations Test ===" -ForegroundColor Green

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

# 2. Create test users for batch operations
Write-Host "`n2. Creating test users..." -ForegroundColor Yellow
$testUsers = @()
$createdUserIds = @()

for ($i = 1; $i -le 3; $i++) {
    $userData = @{
        username = "batchtest$i"
        email = "batchtest$i@example.com"
        displayName = "Batch Test User $i"
        password = "test123"
        status = "active"
    } | ConvertTo-Json

    try {
        $userResponse = Invoke-RestMethod -Uri "$apiUrl/admin/users" -Method POST -Body $userData -Headers $headers
        $createdUserIds += $userResponse.id
        Write-Host "  Created user: batchtest$i (ID: $($userResponse.id))" -ForegroundColor Green
    } catch {
        Write-Host "  Failed to create user batchtest$i: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($createdUserIds.Count -eq 0) {
    Write-Host "No test users created, exiting..." -ForegroundColor Red
    exit 1
}

# 3. Test batch status update
Write-Host "`n3. Testing batch status update..." -ForegroundColor Yellow
$batchStatusData = @{
    user_ids = $createdUserIds
    status = "inactive"
} | ConvertTo-Json

try {
    $statusResponse = Invoke-RestMethod -Uri "$apiUrl/admin/users/batch-status" -Method PUT -Body $batchStatusData -Headers $headers
    Write-Host "Batch status update successful: $($statusResponse.message)" -ForegroundColor Green
} catch {
    Write-Host "Batch status update failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Test batch password reset
Write-Host "`n4. Testing batch password reset..." -ForegroundColor Yellow
$batchResetData = @{
    user_ids = $createdUserIds[0..1]  # Reset first 2 users
} | ConvertTo-Json

try {
    $resetResponse = Invoke-RestMethod -Uri "$apiUrl/admin/users/batch-reset-password" -Method POST -Body $batchResetData -Headers $headers
    Write-Host "Batch password reset successful" -ForegroundColor Green
    Write-Host "Results:" -ForegroundColor Cyan
    foreach ($result in $resetResponse.results) {
        if ($result.success) {
            Write-Host "  - $($result.username): New password = $($result.new_password)" -ForegroundColor White
        } else {
            Write-Host "  - $($result.username): Failed - $($result.error)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "Batch password reset failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Test single user password reset
Write-Host "`n5. Testing single user password reset..." -ForegroundColor Yellow
if ($createdUserIds.Count -gt 2) {
    try {
        $singleResetResponse = Invoke-RestMethod -Uri "$apiUrl/admin/users/$($createdUserIds[2])/reset-password" -Method POST -Headers $headers
        Write-Host "Single password reset successful" -ForegroundColor Green
        Write-Host "  User: $($singleResetResponse.username), New password: $($singleResetResponse.new_password)" -ForegroundColor White
    } catch {
        Write-Host "Single password reset failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 6. Test user import
Write-Host "`n6. Testing user import..." -ForegroundColor Yellow
$importData = @{
    users = @(
        @{
            username = "import1"
            email = "import1@example.com"
            displayName = "Import User 1"
            roles = "user"
            status = "active"
            password = ""
            description = "Imported user 1"
        },
        @{
            username = "import2"
            email = "import2@example.com"
            displayName = "Import User 2"
            roles = "user"
            status = "active"
            password = "custom123"
            description = "Imported user 2"
        }
    )
} | ConvertTo-Json -Depth 3

try {
    $importResponse = Invoke-RestMethod -Uri "$apiUrl/admin/users/import" -Method POST -Body $importData -Headers $headers
    Write-Host "User import completed" -ForegroundColor Green
    Write-Host "Results:" -ForegroundColor Cyan
    foreach ($result in $importResponse.results) {
        if ($result.success) {
            Write-Host "  - $($result.username): Success (ID: $($result.user_id))" -ForegroundColor Green
            $createdUserIds += $result.user_id
        } else {
            Write-Host "  - $($result.username): Failed - $($result.error)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "User import failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 7. Test batch delete
Write-Host "`n7. Testing batch delete..." -ForegroundColor Yellow
$batchDeleteData = @{
    user_ids = $createdUserIds
} | ConvertTo-Json

try {
    $deleteResponse = Invoke-RestMethod -Uri "$apiUrl/admin/users/batch" -Method DELETE -Body $batchDeleteData -Headers $headers
    Write-Host "Batch delete successful: $($deleteResponse.message)" -ForegroundColor Green
} catch {
    Write-Host "Batch delete failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 8. Verify cleanup
Write-Host "`n8. Verifying cleanup..." -ForegroundColor Yellow
try {
    $usersResponse = Invoke-RestMethod -Uri "$apiUrl/admin/users?page=1&page_size=50" -Method GET -Headers $headers
    $remainingTestUsers = $usersResponse.users | Where-Object { $_.username -like "batchtest*" -or $_.username -like "import*" }
    
    if ($remainingTestUsers.Count -eq 0) {
        Write-Host "All test users cleaned up successfully" -ForegroundColor Green
    } else {
        Write-Host "Warning: $($remainingTestUsers.Count) test users still remain" -ForegroundColor Yellow
        foreach ($user in $remainingTestUsers) {
            Write-Host "  - $($user.username) (ID: $($user.id))" -ForegroundColor White
        }
    }
} catch {
    Write-Host "Failed to verify cleanup: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
Write-Host "User management batch operations have been tested." -ForegroundColor Cyan
Write-Host "Features tested:" -ForegroundColor Yellow
Write-Host "- Batch status update" -ForegroundColor White
Write-Host "- Batch password reset" -ForegroundColor White
Write-Host "- Single user password reset" -ForegroundColor White
Write-Host "- User import" -ForegroundColor White
Write-Host "- Batch delete" -ForegroundColor White