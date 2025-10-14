# Check Permission Tree Structure
$BaseUrl = "http://localhost:8080"

Write-Host "=== Permission Tree Structure Check ===" -ForegroundColor Green

# Login
$loginData = '{"username":"admin","password":"admin123"}'
$loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
$token = $loginResponse.data.token
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Get permission tree
$treeResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/permissions/tree" -Method GET -Headers $headers
$permissions = $treeResponse.data

Write-Host "Permission Analysis:" -ForegroundColor Cyan
Write-Host "Total permissions: $($permissions.Count)" -ForegroundColor White

# Analyze data completeness
$hasDisplayName = 0
$hasDescription = 0
$hasParentId = 0
$resourceGroups = @{}

foreach ($perm in $permissions) {
    if ($perm.displayName -and $perm.displayName.Trim() -ne "") { $hasDisplayName++ }
    if ($perm.description -and $perm.description.Trim() -ne "") { $hasDescription++ }
    if ($perm.parentId) { $hasParentId++ }
    
    $resource = $perm.resource
    if (-not $resourceGroups.ContainsKey($resource)) {
        $resourceGroups[$resource] = @()
    }
    $resourceGroups[$resource] += $perm
}

Write-Host "Data completeness:" -ForegroundColor Yellow
Write-Host "- With displayName: $hasDisplayName/$($permissions.Count)" -ForegroundColor White
Write-Host "- With description: $hasDescription/$($permissions.Count)" -ForegroundColor White  
Write-Host "- With parentId: $hasParentId/$($permissions.Count)" -ForegroundColor White

Write-Host "Resource groups:" -ForegroundColor Yellow
foreach ($resource in $resourceGroups.Keys) {
    $count = $resourceGroups[$resource].Count
    Write-Host "- $resource : $count permissions" -ForegroundColor White
}

Write-Host ""
Write-Host "=== Recommended Tree Structure ===" -ForegroundColor Green
Write-Host "System Management" -ForegroundColor Yellow
Write-Host "├── System Admin (system:admin)" -ForegroundColor White
Write-Host "└── System Config (system:config)" -ForegroundColor White
Write-Host ""
Write-Host "User Management" -ForegroundColor Yellow  
Write-Host "├── View Users (users:read)" -ForegroundColor White
Write-Host "├── Edit Users (users:write)" -ForegroundColor White
Write-Host "└── Delete Users (users:delete)" -ForegroundColor White
Write-Host ""
Write-Host "Role Management" -ForegroundColor Yellow
Write-Host "├── View Roles (roles:read)" -ForegroundColor White
Write-Host "├── Edit Roles (roles:write)" -ForegroundColor White
Write-Host "├── Delete Roles (roles:delete)" -ForegroundColor White
Write-Host "└── Assign Permissions (roles:assign)" -ForegroundColor White
Write-Host ""
Write-Host "Record Management" -ForegroundColor Yellow
Write-Host "├── View Records (records:read)" -ForegroundColor White
Write-Host "├── View Own Records (records:read:own)" -ForegroundColor White
Write-Host "├── Edit Records (records:write)" -ForegroundColor White
Write-Host "├── Edit Own Records (records:write:own)" -ForegroundColor White
Write-Host "├── Delete Records (records:delete)" -ForegroundColor White
Write-Host "└── Delete Own Records (records:delete:own)" -ForegroundColor White
Write-Host ""
Write-Host "File Management" -ForegroundColor Yellow
Write-Host "├── View Files (files:read)" -ForegroundColor White
Write-Host "├── Upload Files (files:upload)" -ForegroundColor White
Write-Host "├── Edit Files (files:write)" -ForegroundColor White
Write-Host "├── Delete Files (files:delete)" -ForegroundColor White
Write-Host "└── Share Files (files:share)" -ForegroundColor White

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Green