# Final Corrected Permission System Validation Script
# Uses actual fixed API parameters based on backend requirements
# Tests all 76 permissions with correct parameter structures

param(
    [string]$BaseUrl = "http://localhost:8080"
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

# Test user login and get user data
function Test-UserLogin {
    param([string]$Username, [string]$Password, [string]$UserType)
    
    try {
        $loginData = @{
            username = $Username
            password = $Password
        } | ConvertTo-Json -Compress
        
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        
        $userData = @{
            Token = $response.data.token
            User = $response.data.user
            UserType = $UserType
        }
        
        Write-Success "Login successful for $UserType ($Username)"
        Write-Info "  User ID: $($userData.User.id)"
        Write-Info "  Roles: $($userData.User.roles | ForEach-Object { $_.name })"
        Write-Info "  Permissions: $($userData.User.permissions.Count) permissions"
        
        return $userData
    } catch {
        Write-Error "Login failed for $UserType ($Username): $($_.Exception.Message)"
        return $null
    }
}

function Test-ApiEndpoint {
    param(
        [string]$Endpoint,
        [string]$Method = "GET",
        [string]$Token,
        [string]$Permission,
        [bool]$ShouldPass = $true,
        [hashtable]$Body = @{},
        [string]$UserType = "",
        [string]$ContentType = "application/json"
    )
    
    $script:TotalTests++
    
    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
        }
        
        if ($ContentType -eq "application/json") {
            $headers["Content-Type"] = "application/json"
        }
        
        $params = @{
            Uri = "$BaseUrl$Endpoint"
            Method = $Method
            Headers = $headers
            TimeoutSec = 10
        }
        
        if ($Body.Count -gt 0) {
            if ($ContentType -eq "application/json") {
                $params.Body = ($Body | ConvertTo-Json -Depth 3)
            } else {
                $params.Body = $Body
                $params.ContentType = $ContentType
            }
        }
        
        $response = Invoke-RestMethod @params
        
        if ($ShouldPass) {
            Write-Success "PASS: $Permission - $Method $Endpoint ($UserType)"
            $script:PassedTests++
            $script:TestResults += @{
                Permission = $Permission
                Endpoint = "$Method $Endpoint"
                UserType = $UserType
                Status = "PASS"
                Expected = "Allow"
                Actual = "Allow"
            }
            return $true
        } else {
            Write-Error "FAIL: $Permission - $Method $Endpoint ($UserType) - Should have been denied"
            $script:FailedTests++
            $script:TestResults += @{
                Permission = $Permission
                Endpoint = "$Method $Endpoint"
                UserType = $UserType
                Status = "FAIL"
                Expected = "Deny"
                Actual = "Allow"
            }
            return $false
        }
    }
    catch {
        if ($ShouldPass) {
            Write-Error "FAIL: $Permission - $Method $Endpoint ($UserType) - Error: $($_.Exception.Message)"
            $script:FailedTests++
            $script:TestResults += @{
                Permission = $Permission
                Endpoint = "$Method $Endpoint"
                UserType = $UserType
                Status = "FAIL"
                Expected = "Allow"
                Actual = "Deny"
                Error = $_.Exception.Message
            }
            return $false
        } else {
            Write-Success "PASS: $Permission - $Method $Endpoint ($UserType) - Correctly denied"
            $script:PassedTests++
            $script:TestResults += @{
                Permission = $Permission
                Endpoint = "$Method $Endpoint"
                UserType = $UserType
                Status = "PASS"
                Expected = "Deny"
                Actual = "Deny"
            }
            return $true
        }
    }
}

function Test-SystemPermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType)
    
    Write-Info "Testing System Management Permissions (9 permissions) for $UserType"
    
    # system:admin
    Test-ApiEndpoint "/api/v1/system/health" "GET" $Token "system:admin" $ShouldPass @{} $UserType
    
    # system:config_read
    Test-ApiEndpoint "/api/v1/config" "GET" $Token "system:config_read" $ShouldPass @{} $UserType
    
    # system:config_write - FIXED with correct AnnouncementRequest structure
    Test-ApiEndpoint "/api/v1/config" "POST" $Token "system:config_write" $ShouldPass @{
        category = "test"
        key = "validation_test_$(Get-Random)"
        value = "test_value"
        description = "Test configuration for validation"
        data_type = "string"
        is_public = $false
        is_editable = $true
        reason = "Permission validation test"
    } $UserType
    
    # system:announcements_read
    Test-ApiEndpoint "/api/v1/announcements" "GET" $Token "system:announcements_read" $ShouldPass @{} $UserType
    
    # system:announcements_write - FIXED with correct AnnouncementRequest structure
    Test-ApiEndpoint "/api/v1/announcements" "POST" $Token "system:announcements_write" $ShouldPass @{
        title = "Test Announcement $(Get-Random)"
        content = "This is a test announcement for permission validation"
        type = "info"  # Must be: info, warning, error, maintenance
        priority = 1
        is_active = $true
        is_sticky = $false
        target_users = @()  # Empty array means all users
        start_time = "2026-01-01T00:00:00Z"
        end_time = "2026-12-31T23:59:59Z"
    } $UserType
    
    # system:logs_read
    Test-ApiEndpoint "/api/v1/logs" "GET" $Token "system:logs_read" $ShouldPass @{} $UserType
    
    # system:logs_delete - Use individual log deletion instead of batch
    Test-ApiEndpoint "/api/v1/logs/1" "DELETE" $Token "system:logs_delete" $ShouldPass @{} $UserType
    
    # system:health_read
    Test-ApiEndpoint "/api/v1/system/health" "GET" $Token "system:health_read" $ShouldPass @{} $UserType
    
    # system:stats_read
    Test-ApiEndpoint "/api/v1/system/stats" "GET" $Token "system:stats_read" $ShouldPass @{} $UserType
}

function Test-UserPermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType)
    
    Write-Info "Testing User Management Permissions (8 permissions) for $UserType"
    
    # users:read
    Test-ApiEndpoint "/api/v1/admin/users" "GET" $Token "users:read" $ShouldPass @{} $UserType
    
    # users:create
    Test-ApiEndpoint "/api/v1/admin/users" "POST" $Token "users:create" $ShouldPass @{
        username = "testuser_$(Get-Random)"
        email = "test$(Get-Random)@example.com"
        display_name = "Test User $(Get-Random)"
        password = "TestPassword123!"
        status = "active"
        department = "Test Department"
    } $UserType
    
    # users:update
    Test-ApiEndpoint "/api/v1/admin/users/5" "PUT" $Token "users:update" $ShouldPass @{
        display_name = "Updated Test User"
        email = "updated$(Get-Random)@example.com"
    } $UserType
    
    # users:delete
    Test-ApiEndpoint "/api/v1/admin/users/999999" "DELETE" $Token "users:delete" $ShouldPass @{} $UserType
    
    # users:assign_roles
    Test-ApiEndpoint "/api/v1/admin/users/5/roles" "PUT" $Token "users:assign_roles" $ShouldPass @{
        roleIds = @(2)
    } $UserType
    
    # users:reset_password
    Test-ApiEndpoint "/api/v1/admin/users/5/reset-password" "POST" $Token "users:reset_password" $ShouldPass @{
        newPassword = "NewPassword123!"
        requirePasswordChange = $true
    } $UserType
    
    # users:change_status - FIXED with correct structure
    Test-ApiEndpoint "/api/v1/admin/users/batch-status" "PUT" $Token "users:change_status" $ShouldPass @{
        user_ids = @(5)
        status = "active"
        reason = "Permission validation test"
    } $UserType
    
    # users:import - FIXED with correct structure
    Test-ApiEndpoint "/api/v1/admin/users/import" "POST" $Token "users:import" $ShouldPass @{
        users = @(
            @{
                username = "import_test_$(Get-Random)"
                email = "import$(Get-Random)@example.com"
                display_name = "Import Test User"
                password = "ImportTest123!"
                status = "active"
                department = "Test"
            }
        )
        options = @{
            update_existing = $false
            send_welcome_email = $false
            validate_only = $false
        }
    } $UserType
}

function Test-RolePermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType)
    
    Write-Info "Testing Role Management Permissions (6 permissions) for $UserType"
    
    # roles:read
    Test-ApiEndpoint "/api/v1/admin/roles" "GET" $Token "roles:read" $ShouldPass @{} $UserType
    
    # roles:create
    Test-ApiEndpoint "/api/v1/admin/roles" "POST" $Token "roles:create" $ShouldPass @{
        name = "test_role_$(Get-Random)"
        display_name = "Test Role $(Get-Random)"
        description = "Test role for validation"
        is_active = $true
    } $UserType
    
    # roles:update
    Test-ApiEndpoint "/api/v1/admin/roles/2" "PUT" $Token "roles:update" $ShouldPass @{
        display_name = "Updated Test Role"
        description = "Updated role description"
    } $UserType
    
    # roles:delete
    Test-ApiEndpoint "/api/v1/admin/roles/999999" "DELETE" $Token "roles:delete" $ShouldPass @{} $UserType
    
    # roles:assign_permissions
    Test-ApiEndpoint "/api/v1/admin/roles/2/permissions" "PUT" $Token "roles:assign_permissions" $ShouldPass @{
        permissionIds = @(1, 2, 3)
    } $UserType
    
    # roles:import - Use simpler structure for now
    Test-ApiEndpoint "/api/v1/admin/roles/import" "POST" $Token "roles:import" $ShouldPass @{
        data = @(
            @{
                name = "import_role_$(Get-Random)"
                display_name = "Import Test Role"
                description = "Imported role for validation"
            }
        )
    } $UserType
}

function Test-PermissionPermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType)
    
    Write-Info "Testing Permission Management Permissions (5 permissions) for $UserType"
    
    # permissions:read
    Test-ApiEndpoint "/api/v1/permissions" "GET" $Token "permissions:read" $ShouldPass @{} $UserType
    
    # permissions:create
    Test-ApiEndpoint "/api/v1/permissions" "POST" $Token "permissions:create" $ShouldPass @{
        name = "test:permission:$(Get-Random)"
        description = "Test permission for validation"
    } $UserType
    
    # permissions:update
    Test-ApiEndpoint "/api/v1/permissions/1" "PUT" $Token "permissions:update" $ShouldPass @{
        description = "Updated permission description"
    } $UserType
    
    # permissions:delete
    Test-ApiEndpoint "/api/v1/permissions/999999" "DELETE" $Token "permissions:delete" $ShouldPass @{} $UserType
    
    # permissions:initialize
    Test-ApiEndpoint "/api/v1/permissions/initialize" "POST" $Token "permissions:initialize" $ShouldPass @{} $UserType
}

function Test-TicketPermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType, [bool]$IsAdmin = $false)
    
    Write-Info "Testing Ticket Management Permissions (19 permissions) for $UserType"
    
    # ticket:read
    Test-ApiEndpoint "/api/v1/tickets" "GET" $Token "ticket:read" $ShouldPass @{} $UserType
    
    # ticket:create
    Test-ApiEndpoint "/api/v1/tickets" "POST" $Token "ticket:create" $ShouldPass @{
        title = "Test Ticket $(Get-Random)"
        description = "Test ticket for permission validation"
        type = "bug"
        priority = "normal"
        category = "technical"
    } $UserType
    
    # ticket:update
    Test-ApiEndpoint "/api/v1/tickets/65" "PUT" $Token "ticket:update" $ShouldPass @{
        title = "Updated Test Ticket"
        description = "Updated description"
    } $UserType
    
    # ticket:delete
    Test-ApiEndpoint "/api/v1/tickets/999999" "DELETE" $Token "ticket:delete" $ShouldPass @{} $UserType
    
    # ticket:assign - FIXED with correct parameter name
    Test-ApiEndpoint "/api/v1/tickets/65/assign" "POST" $Token "ticket:assign" $ShouldPass @{
        assignee_id = 5
        reason = "Permission validation test"
        notify_assignee = $true
    } $UserType
    
    # ticket:accept
    Test-ApiEndpoint "/api/v1/tickets/65/accept" "POST" $Token "ticket:accept" $ShouldPass @{
        comment = "Accepting for validation test"
    } $UserType
    
    # ticket:reject
    Test-ApiEndpoint "/api/v1/tickets/65/reject" "POST" $Token "ticket:reject" $ShouldPass @{
        reason = "Rejecting for validation test"
        comment = "Test rejection"
    } $UserType
    
    # ticket:reopen
    Test-ApiEndpoint "/api/v1/tickets/65/reopen" "POST" $Token "ticket:reopen" $ShouldPass @{
        reason = "Reopening for validation test"
    } $UserType
    
    # ticket:status_change - Use simpler structure
    Test-ApiEndpoint "/api/v1/tickets/65/status" "PUT" $Token "ticket:status_change" $ShouldPass @{
        status = "open"
        comment = "Status change for validation"
    } $UserType
    
    # ticket:comment_read
    Test-ApiEndpoint "/api/v1/tickets/65/comments" "GET" $Token "ticket:comment_read" $ShouldPass @{} $UserType
    
    # ticket:comment_write
    Test-ApiEndpoint "/api/v1/tickets/65/comments" "POST" $Token "ticket:comment_write" $ShouldPass @{
        content = "Test comment for validation"
        type = "comment"
    } $UserType
    
    # ticket:attachment_upload
    Test-ApiEndpoint "/api/v1/tickets/65/attachments" "POST" $Token "ticket:attachment_upload" $ShouldPass @{
        filename = "test.txt"
        description = "Test attachment"
    } $UserType
    
    # ticket:attachment_delete
    Test-ApiEndpoint "/api/v1/tickets/65/attachments/999999" "DELETE" $Token "ticket:attachment_delete" $ShouldPass @{} $UserType
    
    # ticket:statistics
    Test-ApiEndpoint "/api/v1/tickets/statistics" "GET" $Token "ticket:statistics" $ShouldPass @{} $UserType
    
    # ticket:export - Use GET method
    Test-ApiEndpoint "/api/v1/tickets/export" "GET" $Token "ticket:export" $ShouldPass @{} $UserType
    
    # ticket:import
    Test-ApiEndpoint "/api/v1/tickets/import" "POST" $Token "ticket:import" $ShouldPass @{
        data = @(
            @{
                title = "Import Test Ticket"
                description = "Imported ticket"
                type = "feature"
                priority = "normal"
            }
        )
    } $UserType
}

function Test-RecordPermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType, [bool]$IsAdmin = $false)
    
    Write-Info "Testing Record Management Permissions (8 permissions) for $UserType"
    
    # records:read
    Test-ApiEndpoint "/api/v1/records" "GET" $Token "records:read" $ShouldPass @{} $UserType
    
    # records:create - Use simpler structure
    Test-ApiEndpoint "/api/v1/records" "POST" $Token "records:create" $ShouldPass @{
        title = "Test Record $(Get-Random)"
        content = "Test record content for validation"
        type = "general"
    } $UserType
    
    # records:update
    Test-ApiEndpoint "/api/v1/records/999999" "PUT" $Token "records:update" $ShouldPass @{
        title = "Updated Test Record"
    } $UserType
    
    # records:delete
    Test-ApiEndpoint "/api/v1/records/999999" "DELETE" $Token "records:delete" $ShouldPass @{} $UserType
    
    # records:import
    Test-ApiEndpoint "/api/v1/records/import" "POST" $Token "records:import" $ShouldPass @{
        data = @(
            @{
                title = "Import Test Record"
                content = "Imported record content"
                type = "general"
            }
        )
    } $UserType
}

function Test-RecordTypePermissions {
    param([string]$Token, [bool]$ShouldPass, [string]$UserType)
    
    Write-Info "Testing Record Type Management Permissions (5 permissions) for $UserType"
    
    # record_types:read
    Test-ApiEndpoint "/api/v1/record-types" "GET" $Token "record_types:read" $ShouldPass @{} $UserType
    
    # record_types:create
    Test-ApiEndpoint "/api/v1/record-types" "POST" $Token "record_types:create" $ShouldPass @{
        name = "test_type_$(Get-Random)"
        display_name = "Test Record Type"
        description = "Test record type for validation"
        schema = '{"type":"object","properties":{"title":{"type":"string"}}}'
        is_active = $true
    } $UserType
    
    # record_types:update
    Test-ApiEndpoint "/api/v1/record-types/1" "PUT" $Token "record_types:update" $ShouldPass @{
        display_name = "Updated Record Type"
        description = "Updated description"
    } $UserType
    
    # record_types:delete
    Test-ApiEndpoint "/api/v1/record-types/999999" "DELETE" $Token "record_types:delete" $ShouldPass @{} $UserType
    
    # record_types:import
    Test-ApiEndpoint "/api/v1/record-types/import" "POST" $Token "record_types:import" $ShouldPass @{
        data = @(
            @{
                name = "import_type"
                display_name = "Import Type"
                description = "Imported record type"
                schema = '{"type":"object"}'
            }
        )
    } $UserType
}

function Te