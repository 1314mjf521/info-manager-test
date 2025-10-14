# Simple Role Management Test
$BaseUrl = "http://localhost:8080"
$Username = "admin"
$Password = "admin123"

Write-Host "=== Role Management Test ===" -ForegroundColor Green

# Login
Write-Host "1. Login..." -ForegroundColor Yellow
$loginData = @{
    username = $Username
    password = $Password
} | ConvertTo-Json

$headers = @{
    "Content-Type" = "application/json"
}

try {
    $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -Headers $headers
    
    if ($loginResponse.success) {
        Write-Host "Success: Login successful" -ForegroundColor Green
        $token = $loginResponse.data.token
        $headers["Authorization"] = "Bearer $token"
    } else {
        Write-Host "Error: Login failed - $($loginResponse.error.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error: Login request failed - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get roles list
Write-Host "2. Get roles list..." -ForegroundColor Yellow
try {
    $rolesResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/roles" -Method GET -Headers $headers
    
    if ($rolesResponse.success) {
        Write-Host "Success: Roles list retrieved" -ForegroundColor Green
        Write-Host "Roles count: $($rolesResponse.data.Count)" -ForegroundColor Cyan
        
        foreach ($role in $rolesResponse.data) {
            Write-Host "- ID: $($role.id), Name: $($role.name), DisplayName: $($role.displayName), Status: $($role.status)" -ForegroundColor White
        }
    } else {
        Write-Host "Error: Failed to get roles - $($rolesResponse.error.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: Roles request failed - $($_.Exception.Message)" -ForegroundColor Red
}

# Get permissions list
Write-Host "3. Get permissions list..." -ForegroundColor Yellow
try {
    $permissionsResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions" -Method GET -Headers $headers
    
    if ($permissionsResponse.success) {
        Write-Host "Success: Permissions list retrieved" -ForegroundColor Green
        Write-Host "Permissions count: $($permissionsResponse.data.Count)" -ForegroundColor Cyan
    } else {
        Write-Host "Error: Failed to get permissions - $($permissionsResponse.error.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: Permissions request failed - $($_.Exception.Message)" -ForegroundColor Red
}

# Get permissions tree
Write-Host "4. Get permissions tree..." -ForegroundColor Yellow
try {
    $treeResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions/tree" -Method GET -Headers $headers
    
    if ($treeResponse.success) {
        Write-Host "Success: Permissions tree retrieved" -ForegroundColor Green
        Write-Host "Tree nodes count: $($treeResponse.data.Count)" -ForegroundColor Cyan
    } else {
        Write-Host "Error: Failed to get permissions tree - $($treeResponse.error.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: Permissions tree request failed - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=== Test Complete ===" -ForegroundColor Green