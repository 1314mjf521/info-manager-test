# 修复数据库中的ticket权限
$baseUrl = "http://localhost:8080"

Write-Host "=== Fixing Ticket Permissions in Database ===" -ForegroundColor Green

# 登录
$loginData = @{ username = "admin"; password = "admin123" } | ConvertTo-Json -Compress
$loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
$token = $loginResponse.data.token

$headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }

try {
    # 1. 获取当前权限
    Write-Host "1. Getting current permissions..." -ForegroundColor Yellow
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/permissions" -Method GET -Headers $headers
    $permissions = $response.data
    
    # 2. 找到错误的ticket权限（ID > 10000）
    $badTicketPermissions = $permissions | Where-Object { $_.resource -eq "ticket" -and $_.id -gt 10000 }
    Write-Host "   Found $($badTicketPermissions.Count) bad ticket permissions to remove" -ForegroundColor Yellow
    
    # 3. 删除错误的权限（注意：这需要后端支持删除权限的API）
    foreach ($perm in $badTicketPermissions) {
        Write-Host "   Attempting to remove permission: $($perm.name) (ID: $($perm.id))" -ForegroundColor Cyan
        try {
            # 注意：这个API可能不存在，需要检查后端是否支持
            $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/permissions/$($perm.id)" -Method DELETE -Headers $headers
            Write-Host "     ✓ Removed successfully" -ForegroundColor Green
        } catch {
            Write-Host "     ✗ Failed to remove: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "`n4. Restarting backend to trigger migration..." -ForegroundColor Yellow
    Write-Host "   Please restart the backend server manually to trigger proper migration." -ForegroundColor Yellow
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Fix Complete ===" -ForegroundColor Green
Write-Host "After restarting the backend, the correct ticket permissions should be created." -ForegroundColor Yellow