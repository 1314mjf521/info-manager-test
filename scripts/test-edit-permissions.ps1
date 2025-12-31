# Test edit permissions for tiker user
Write-Host "=== Testing Edit Permissions ===" -ForegroundColor Green

# Login tiker user
$loginData = @{
    username = "tiker"
    password = "QAZwe@01010"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $tikerUserId = $loginResponse.data.user.id
    $tikerToken = $loginResponse.data.token
    $tikerHeaders = @{
        "Authorization" = "Bearer $tikerToken"
        "Content-Type" = "application/json"
    }
    
    Write-Host "Tiker user ID: $tikerUserId" -ForegroundColor Yellow
    
    Write-Host "`nUser permissions:" -ForegroundColor Yellow
    $permissions = $loginResponse.data.user.permissions | ForEach-Object { $_.name }
    $permissions | ForEach-Object {
        Write-Host "  $_"
    }
    
    Write-Host "`nPermission checks:" -ForegroundColor Yellow
    Write-Host "  Has ticket:update: $(if ($permissions -contains 'ticket:update') { 'YES' } else { 'NO' })"
    Write-Host "  Has ticket:update_own: $(if ($permissions -contains 'ticket:update_own') { 'YES' } else { 'NO' })"
    Write-Host "  Has ticket:delete_own: $(if ($permissions -contains 'ticket:delete_own') { 'YES' } else { 'NO' })"
    
    Write-Host "`nTesting tickets:" -ForegroundColor Yellow
    $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $tikerHeaders
    
    $ticketsResponse.data.items | ForEach-Object {
        $isOwnTicket = $_.creator_id -eq $tikerUserId
        $canEdit = ($permissions -contains 'ticket:update') -or (($permissions -contains 'ticket:update_own') -and $isOwnTicket)
        $canDelete = ($permissions -contains 'ticket:delete') -or (($permissions -contains 'ticket:delete_own') -and $isOwnTicket)
        
        Write-Host "  Ticket ID: $($_.id)"
        Write-Host "    Title: $($_.title)"
        Write-Host "    Creator ID: $($_.creator_id) (Own: $isOwnTicket)"
        Write-Host "    Can Edit: $canEdit"
        Write-Host "    Can Delete: $canDelete"
        Write-Host ""
    }
    
    Write-Host "=== Test completed ===" -ForegroundColor Green
    
} catch {
    Write-Host "Test failed: $($_.Exception.Message)" -ForegroundColor Red
}