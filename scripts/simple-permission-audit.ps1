# Simple Permission Audit
Write-Host "=== PERMISSION AUDIT ===" -ForegroundColor Green

# Test tiker user
$loginData = @{
    username = "tiker"
    password = "QAZwe@01010"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    $userId = $loginResponse.data.user.id
    $userPermissions = $loginResponse.data.user.permissions | ForEach-Object { $_.name }
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    Write-Host "User: tiker (ID: $userId)" -ForegroundColor Yellow
    Write-Host "Permissions: $($userPermissions.Count)" -ForegroundColor Cyan
    
    # Check key permissions
    Write-Host "`nKey Permissions:" -ForegroundColor Yellow
    $keyPerms = @("ticket:read_own", "ticket:create", "ticket:update_own", "ticket:delete_own")
    foreach ($perm in $keyPerms) {
        $has = $userPermissions -contains $perm
        $status = if ($has) { "YES" } else { "NO" }
        $color = if ($has) { "Green" } else { "Red" }
        Write-Host "  $perm: $status" -ForegroundColor $color
    }
    
    # Test API access
    Write-Host "`nAPI Tests:" -ForegroundColor Yellow
    
    # Ticket list
    try {
        $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $headers
        Write-Host "  Ticket list: SUCCESS ($($ticketsResponse.data.items.Count) tickets)" -ForegroundColor Green
        
        # Test editing first own ticket
        $ownTickets = $ticketsResponse.data.items | Where-Object { $_.creator_id -eq $userId }
        if ($ownTickets.Count -gt 0) {
            $firstOwnTicket = $ownTickets[0]
            Write-Host "  Testing edit access for ticket $($firstOwnTicket.id)..." -ForegroundColor Cyan
            
            # Try to get ticket for editing
            try {
                $editTicketResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$($firstOwnTicket.id)" -Method GET -Headers $headers
                Write-Host "    Get ticket for edit: SUCCESS" -ForegroundColor Green
                
                # Try to update ticket
                $updateData = @{
                    title = $firstOwnTicket.title + " (edited)"
                    description = $firstOwnTicket.description
                    type = $firstOwnTicket.type
                    priority = $firstOwnTicket.priority
                } | ConvertTo-Json
                
                try {
                    $updateResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets/$($firstOwnTicket.id)" -Method PUT -Headers $headers -Body $updateData
                    Write-Host "    Update ticket: SUCCESS" -ForegroundColor Green
                } catch {
                    Write-Host "    Update ticket: FAILED - $($_.Exception.Message)" -ForegroundColor Red
                }
                
            } catch {
                Write-Host "    Get ticket for edit: FAILED - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
    } catch {
        Write-Host "  Ticket list: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test route permissions
    Write-Host "`nRoute Permission Logic:" -ForegroundColor Yellow
    $routes = @{
        "tickets" = "ticket:read_own"
        "tickets/:id" = "ticket:read_own"
        "tickets/:id/edit" = "ticket:update_own"
        "tickets/create" = "ticket:create"
    }
    
    foreach ($route in $routes.Keys) {
        $requiredPerm = $routes[$route]
        $hasAccess = $userPermissions -contains $requiredPerm
        $status = if ($hasAccess) { "ALLOW" } else { "DENY" }
        $color = if ($hasAccess) { "Green" } else { "Red" }
        Write-Host "  $route (needs $requiredPerm): $status" -ForegroundColor $color
    }
    
    # Test UI button logic
    Write-Host "`nUI Button Logic:" -ForegroundColor Yellow
    if ($ticketsResponse) {
        foreach ($ticket in $ticketsResponse.data.items) {
            $isOwn = $ticket.creator_id -eq $userId
            Write-Host "  Ticket $($ticket.id) (Own: $isOwn):"
            
            # Edit button
            $canEdit = ($userPermissions -contains "ticket:update") -or (($userPermissions -contains "ticket:update_own") -and $isOwn)
            Write-Host "    Edit button: $(if ($canEdit) { 'SHOW' } else { 'HIDE' })" -ForegroundColor $(if ($canEdit) { "Green" } else { "Gray" })
            
            # Delete button
            $canDelete = ($userPermissions -contains "ticket:delete") -or (($userPermissions -contains "ticket:delete_own") -and $isOwn)
            Write-Host "    Delete button: $(if ($canDelete) { 'SHOW' } else { 'HIDE' })" -ForegroundColor $(if ($canDelete) { "Green" } else { "Gray" })
        }
    }
    
    Write-Host "`n=== AUDIT COMPLETED ===" -ForegroundColor Green
    
} catch {
    Write-Host "Audit failed: $($_.Exception.Message)" -ForegroundColor Red
}