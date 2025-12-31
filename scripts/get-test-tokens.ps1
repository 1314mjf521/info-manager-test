# Get Test Tokens Script
# Logs in as admin and tiker users to get tokens for testing

param(
    [string]$BaseUrl = "http://localhost:8080"
)

function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }

function Get-AuthToken {
    param(
        [string]$Username,
        [string]$Password
    )
    
    try {
        $loginData = @{
            username = $Username
            password = $Password
        }
        
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
        
        if ($response.token) {
            Write-Success "Successfully logged in as $Username"
            return $response.token
        } else {
            Write-Error "Login failed for $Username - No token received"
            return $null
        }
    }
    catch {
        Write-Error "Login failed for $Username - Error: $($_.Exception.Message)"
        return $null
    }
}

Write-Info "=== Getting Test Tokens ==="
Write-Info ""

# Get admin token
Write-Info "Logging in as admin..."
$adminToken = Get-AuthToken "admin" "admin123"

if ($adminToken) {
    Write-Info "Admin Token: $adminToken"
    Write-Info ""
} else {
    Write-Error "Failed to get admin token. Please check admin credentials."
    exit 1
}

# Get tiker token
Write-Info "Logging in as tiker user..."
$tikerToken = Get-AuthToken "tiker" "tiker123"

if ($tikerToken) {
    Write-Info "Tiker Token: $tikerToken"
    Write-Info ""
} else {
    Write-Error "Failed to get tiker token. Please check tiker credentials."
    exit 1
}

Write-Success "Both tokens obtained successfully!"
Write-Info ""
Write-Info "Now run the complete permission validation:"
Write-Info ".\scripts\complete-permission-validation-en.ps1 -AdminToken '$adminToken' -TikerToken '$tikerToken'"