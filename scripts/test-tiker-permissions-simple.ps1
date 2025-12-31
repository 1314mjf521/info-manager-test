# Test tiker user permissions
Write-Host "=== Testing tiker user permissions ===" -ForegroundColor Green

# Login tiker user
$loginData = @{
    username = "tiker"
    password = "QAZwe@01010"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $tikerToken = $loginResponse.data.token
    $tikerHeaders = @{
        "Authorization" = "Bearer $tikerToken"
        "Content-Type" = "application/json"
    }
    
    Write-Host "1. User info:" -ForegroundColor Yellow
    Write-Host "   Username: $($loginResponse.data.user.username)"
    Write-Host "   User ID: $($loginResponse.data.user.id)"
    Write-Host "   Role: $($loginResponse.data.user.roles[0].name)"
    
    Write-Host "`n2. User permissions:" -ForegroundColor Yellow
    $loginResponse.data.user.permissions | ForEach-Object {
        Write-Host "   $($_.name) - $($_.display_name)"
    }
    
    Write-Host "`n3. Ticket list test:" -ForegroundColor Yellow
    $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $tikerHeaders
    Write-Host "   Visible tickets: $($ticketsResponse.data.items.Count)"
    
    $ticketsResponse.data.items | ForEach-Object {
        $creatorInfo = if ($_.creator_id -eq 2) { "(created by self)" } else { "(assigned to self)" }
        Write-Host "   - ID: $($_.id), Title: $($_.title), Status: $($_.status) $creatorInfo"
    }
    
    Write-Host "`n4. Permission check results:" -ForegroundColor Yellow
    $permissions = $loginResponse.data.user.permissions | ForEach-Object { $_.name }
    
    $checks = @(
        @{ Name = "Create tickets"; Permission = "ticket:create" },
        @{ Name = "View own tickets"; Permission = "ticket:read_own" },
        @{ Name = "Edit own tickets"; Permission = "ticket:update_own" },
        @{ Name = "Delete own tickets"; Permission = "ticket:delete_own" },
        @{ Name = "Upload attachments"; Permission = "ticket:attachment_upload" },
        @{ Name = "View comments"; Permission = "ticket:comment_read" },
        @{ Name = "Add comments"; Permission = "ticket:comment_write" },
        @{ Name = "View statistics"; Permission = "ticket:statistics" },
        @{ Name = "Return tickets"; Permission = "ticket:return" },
        @{ Name = "Accept tickets"; Permission = "ticket:accept" },
        @{ Name = "Reject tickets"; Permission = "ticket:reject" },
        @{ Name = "Approve tickets"; Permission = "ticket:approve" },
        @{ Name = "Assign tickets"; Permission = "ticket:assign" }
    )
    
    $checks | ForEach-Object {
        $hasPermission = $permissions -contains $_.Permission
        $status = if ($hasPermission) { "OK" } else { "NO" }
        $color = if ($hasPermission) { "Green" } else { "Red" }
        Write-Host "   $status $($_.Name)" -ForegroundColor $color
    }
    
    Write-Host "`n=== Test completed ===" -ForegroundColor Green
    
} catch {
    Write-Host "Test failed: $($_.Exception.Message)" -ForegroundColor Red
}