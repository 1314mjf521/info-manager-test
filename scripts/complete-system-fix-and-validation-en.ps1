# Complete System Fix and Validation Script - English Version
# Fixes user initialization, permissions, and validates the entire system
# Avoids encoding issues by using English throughout

param(
    [string]$BaseUrl = "http://localhost:8080",
    [switch]$SkipUserInit,
    [switch]$SkipPermissionInit,
    [switch]$SkipValidation
)

# Color functions for output
function Write-Success { param($Message) Write-Host "[PASS] $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }

# Test counters
$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0
$script:TestResults = @()

Write-Info "=== Complete System Fix and Validation Script ==="
Write-Info "Starting comprehensive system repair and testing..."
Write-Info ""

# 1. Check backend server
Write-Info "1. Checking backend server status..."
try {
    $healthResponse = Invoke-WebRequest -Uri "$BaseUrl/health" -TimeoutSec 5
    Write-Success "Backend server is running - HTTP $($healthResponse.StatusCode)"
} catch {
    Write-Error "Backend server is not running. Please start the server first."
    exit 1
}

# 2. Test admin login
Write-Info "2. Testing admin user login..."
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json -Compress
    
    $adminResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $adminToken = $adminResponse.data.token
    $adminUser = $adminResponse.data.user
    
    Write-Success "Admin login successful"
    Write-Info "  User ID: $($adminUser.id)"
    Write-Info "  Username: $($adminUser.username)"
    Write-Info "  Roles: $($adminUser.roles.Count) roles"
    Write-Info "  Permissions: $($adminUser.permissions.Count) permissions"
} catch {
    Write-Error "Admin login failed: $($_.Exception.Message)"
    Write-Info "Attempting to initialize admin user..."
    
    # Try to create admin user if login fails
    try {
        $createAdminData = @{
            username = "admin"
            email = "admin@system.com"
            password = "admin123"
            displayName = "System Administrator"
            status = "active"
        } | ConvertTo-Json -Compress
        
        $createResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/register" -Method POST -Body $createAdminData -ContentType "application/json"
        Write-Success "Admin user created successfully"
        
        # Try login again
        $adminResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        $adminToken = $adminResponse.data.token
        $adminUser = $adminResponse.data.user
        Write-Success "Admin login successful after creation"
    } catch {
        Write-Error "Failed to create or login admin user: $($_.Exception.Message)"
        exit 1
    }
}# 
3. Initialize permissions if needed
if (-not $SkipPermissionInit) {
    Write-Info "3. Initializing permission system..."
    try {
        $headers = @{
            "Authorization" = "Bearer $adminToken"
            "Content-Type" = "application/json"
        }
        
        $permResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions/initialize" -Method POST -Headers $headers
        Write-Success "Permission system initialized successfully"
    } catch {
        Write-Warning "Permission initialization failed or already done: $($_.Exception.Message)"
    }
} else {
    Write-Info "3. Skipping permission initialization (SkipPermissionInit flag set)"
}

# 4. Initialize or fix tiker user
if (-not $SkipUserInit) {
    Write-Info "4. Checking and fixing tiker user..."
    
    # First try to login with existing tiker user
    try {
        $tikerLoginData = @{
            username = "tiker"
            password = "tiker123"
        } | ConvertTo-Json -Compress
        
        $tikerResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $tikerLoginData -ContentType "application/json"
        $tikerToken = $tikerResponse.data.token
        $tikerUser = $tikerResponse.data.user
        
        Write-Success "Tiker user login successful"
        Write-Info "  User ID: $($tikerUser.id)"
        Write-Info "  Username: $($tikerUser.username)"
        Write-Info "  Roles: $($tikerUser.roles.Count) roles"
        Write-Info "  Permissions: $($tikerUser.permissions.Count) permissions"
    } catch {
        Write-Warning "Tiker user login failed, attempting to create/fix..."
        
        # Try to create tiker user
        try {
            $headers = @{
                "Authorization" = "Bearer $adminToken"
                "Content-Type" = "application/json"
            }
            
            $createTikerData = @{
                username = "tiker"
                email = "tiker@system.com"
                password = "tiker123"
                displayName = "Ticket Manager"
                status = "active"
            } | ConvertTo-Json -Compress
            
            $createTikerResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/users" -Method POST -Body $createTikerData -Headers $headers
            Write-Success "Tiker user created successfully"
            
            # Get tiker role ID
            $rolesResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/roles" -Method GET -Headers $headers
            $tikerRole = $rolesResponse.data | Where-Object { $_.name -eq "tiker" }
            
            if ($tikerRole) {
                # Assign tiker role to user
                $assignRoleData = @{
                    roleIds = @($tikerRole.id)
                } | ConvertTo-Json -Compress
                
                $assignResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/users/$($createTikerResponse.data.id)/roles" -Method PUT -Body $assignRoleData -Headers $headers
                Write-Success "Tiker role assigned to user"
            } else {
                Write-Warning "Tiker role not found, user created without specific role"
            }
            
            # Try login again
            $tikerResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $tikerLoginData -ContentType "application/json"
            $tikerToken = $tikerResponse.data.token
            $tikerUser = $tikerResponse.data.user
            Write-Success "Tiker l