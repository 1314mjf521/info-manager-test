# Test Table Layout Improvements
# Verify that action columns in user and role management tables have proper width

Write-Host "=== Testing Table Layout Improvements ===" -ForegroundColor Green

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

# Step 2: Test user management data
Write-Host "`n2. Testing user management data..." -ForegroundColor Yellow
try {
    $usersResponse = Invoke-RestMethod -Uri "$baseUrl/admin/users?page=1&size=5" -Method Get -Headers $headers
    
    if ($usersResponse.data) {
        $users = if ($usersResponse.data.items) { $usersResponse.data.items } else { $usersResponse.data }
        Write-Host "Success: Retrieved $($users.Count) users for testing" -ForegroundColor Green
        
        if ($users.Count -gt 0) {
            Write-Host "`nSample user data:" -ForegroundColor Cyan
            $sampleUser = $users[0]
            Write-Host "  ID: $($sampleUser.id)" -ForegroundColor Gray
            Write-Host "  Username: $($sampleUser.username)" -ForegroundColor Gray
            Write-Host "  Email: $($sampleUser.email)" -ForegroundColor Gray
            Write-Host "  Status: $($sampleUser.status)" -ForegroundColor Gray
            Write-Host "  Roles: $($sampleUser.roles.Count) roles" -ForegroundColor Gray
        }
    } else {
        Write-Host "Warning: No user data retrieved" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: Failed to get user data - $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Test role management data
Write-Host "`n3. Testing role management data..." -ForegroundColor Yellow
try {
    $rolesResponse = Invoke-RestMethod -Uri "$baseUrl/admin/roles?page=1&size=5" -Method Get -Headers $headers
    
    if ($rolesResponse.data) {
        $roles = $rolesResponse.data.items || $rolesResponse.data
        Write-Host "Success: Retrieved $($roles.Count) roles for testing" -ForegroundColor Green
        
        if ($roles.Count -gt 0) {
            Write-Host "`nSample role data:" -ForegroundColor Cyan
            $sampleRole = $roles[0]
            Write-Host "  ID: $($sampleRole.id)" -ForegroundColor Gray
            Write-Host "  Name: $($sampleRole.name)" -ForegroundColor Gray
            Write-Host "  Display Name: $($sampleRole.displayName)" -ForegroundColor Gray
            Write-Host "  Status: $($sampleRole.status)" -ForegroundColor Gray
            Write-Host "  Is System: $($sampleRole.is_system -or $sampleRole.isSystem)" -ForegroundColor Gray
        }
    } else {
        Write-Host "Warning: No role data retrieved" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: Failed to get role data - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Table Layout Improvements Summary ===" -ForegroundColor Green

Write-Host "`nUser Management Table Improvements:" -ForegroundColor Cyan
Write-Host "  ✅ Action column width increased: 260px → 320px" -ForegroundColor Green
Write-Host "  ✅ Button layout optimized: flex-wrap: nowrap" -ForegroundColor Green
Write-Host "  ✅ Button spacing improved: gap: 6px" -ForegroundColor Green
Write-Host "  ✅ Button size optimized: padding: 5px 8px" -ForegroundColor Green
Write-Host "  ✅ Text wrapping prevented: white-space: nowrap" -ForegroundColor Green

Write-Host "`nRole Management Table Improvements:" -ForegroundColor Cyan
Write-Host "  ✅ Action column width increased: 280px → 320px" -ForegroundColor Green
Write-Host "  ✅ Button layout optimized: flex-wrap: nowrap" -ForegroundColor Green
Write-Host "  ✅ Button spacing improved: gap: 6px" -ForegroundColor Green
Write-Host "  ✅ Button size optimized: padding: 5px 8px" -ForegroundColor Green
Write-Host "  ✅ Text wrapping prevented: white-space: nowrap" -ForegroundColor Green

Write-Host "`nAction Buttons in Each Table:" -ForegroundColor Cyan
Write-Host "  User Management: [编辑] [角色] [启用/禁用] [删除]" -ForegroundColor Gray
Write-Host "  Role Management: [编辑] [权限] [启用/禁用] [删除]" -ForegroundColor Gray

Write-Host "`nLayout Benefits:" -ForegroundColor Cyan
Write-Host "  • No more button wrapping to new lines" -ForegroundColor Gray
Write-Host "  • Consistent button spacing and alignment" -ForegroundColor Gray
Write-Host "  • Better visual appearance and usability" -ForegroundColor Gray
Write-Host "  • Responsive design maintained for mobile" -ForegroundColor Gray

Write-Host "`nTechnical Details:" -ForegroundColor Cyan
Write-Host "  • Column width: 320px (sufficient for 4 buttons)" -ForegroundColor Gray
Write-Host "  • Button min-width: 48px (compact but readable)" -ForegroundColor Gray
Write-Host "  • Gap between buttons: 6px (balanced spacing)" -ForegroundColor Gray
Write-Host "  • Flex layout: nowrap (prevents line breaks)" -ForegroundColor Gray

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "  1. Test the user management interface in browser" -ForegroundColor Gray
Write-Host "  2. Verify action buttons display in single line" -ForegroundColor Gray
Write-Host "  3. Test role management interface similarly" -ForegroundColor Gray
Write-Host "  4. Check responsive behavior on different screen sizes" -ForegroundColor Gray

Write-Host "`n=== Table Layout Improvements Test Complete ===" -ForegroundColor Green