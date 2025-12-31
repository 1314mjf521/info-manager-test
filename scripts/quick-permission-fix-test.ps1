# Quick Permission Fix Test
# Tests key fixed endpoints to verify improvements

param(
    [string]$BaseUrl = "http://localhost:8080"
)

function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }

function Test-UserLogin {
    param([string]$Username, [string]$Password, [string]$UserType)
    
    try {
        $loginData = @{
            username = $Username
            password = $Password
        } | ConvertTo-Json -Compress
        
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        
        return @{
            Token = $response.data.token
            User = $response.data.user
            UserType = $UserType
        }
    } catch {
        Write-Error "Login failed for $UserType ($Username): $($_.Exception.Message)"
        return $null
    }
}

function Test-Endpoint {
    param([string]$Name, [string]$Url, [string]$Token, [bool]$ShouldPass)
    
    try {
        $headers = @{ "Authorization" = "Bearer $Token" }
        $response = Invoke-RestMethod -Uri "$BaseUrl$Url" -Method GET -Headers $headers -TimeoutSec 5
        
        if ($ShouldPass) {
            Write-Success "PASS: $Name - Access granted as expected"
        } else {
            Write-Error "FAIL: $Name - Should have been denied but was granted"
        }
        return $true
    } catch {
        if ($ShouldPass) {
            Write-Error "FAIL: $Name - Should have been granted but was denied: $($_.Exception.Message)"
        } else {
            Write-Success "PASS: $Name - Correctly denied access"
        }
        return $false
    }
}

Write-Info "=== Quick Permission Fix Test ==="
Write-Info ""

# Login as admin and tiker
$adminData = Test-UserLogin "admin" "admin123" "Admin"
$tikerData = Test-UserLogin "tiker_test" "tiker123" "Tiker"

if (-not $adminData -or -not $tikerData) {
    Write-Error "Failed to login users, exiting"
    exit 1
}

Write-Info ""
Write-Info "Testing key fixed endpoints..."
Write-Info ""

# Test previously problematic endpoints
Write-Info "Admin user tests (should pass):"
Test-Endpoint "System Stats" "/api/v1/system/stats" $adminData.Token $true
Test-Endpoint "Permissions CRUD" "/api/v1/permissions" $adminData.Token $true
Test-Endpoint "AI Config" "/api/v1/ai/config" $tikerData.Token $false

Write-Info ""
Write-Info "Tiker user tests (should be denied):"
Test-Endpoint "System Health" "/api/v1/system/health" $tikerData.Token $false
Test-Endpoint "Announcements" "/api/v1/announcements" $tikerData.Token $false
Test-Endpoint "Export Templates" "/api/v1/export/templates" $tikerData.Token $false
Test-Endpoint "AI Config" "/api/v1/ai/config" $tikerData.Token $false

Write-Info ""
Write-Info "Permission fix test completed!"