# 清理错误的ticket权限
$baseUrl = "http://localhost:8080"

Write-Host "=== Cleaning Bad Ticket Permissions ===" -ForegroundColor Green

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
    
    if ($badTicketPermissions.Count -eq 0) {
        Write-Host "   No bad ticket permissions found!" -ForegroundColor Green
        return
    }
    
    # 3. 删除错误的权限
    $successCount = 0
    $failCount = 0
    
    foreach ($perm in $badTicketPermissions) {
        Write-Host "   Removing permission: $($perm.name) (ID: $($perm.id))" -ForegroundColor Cyan
        try {
            $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/permissions/$($perm.id)" -Method DELETE -Headers $headers
            Write-Host "     ✓ Removed successfully" -ForegroundColor Green
            $successCount++
        } catch {
            Write-Host "     ✗ Failed to remove: $($_.Exception.Message)" -ForegroundColor Red
            $failCount++
        }
    }
    
    Write-Host "`n4. Summary:" -ForegroundColor Yellow
    Write-Host "   Successfully removed: $successCount permissions" -ForegroundColor Green
    Write-Host "   Failed to remove: $failCount permissions" -ForegroundColor Red
    
    if ($successCount -gt 0) {
        Write-Host "`n5. Restarting backend to trigger proper migration..." -ForegroundColor Yellow
        
        # 停止后端
        try {
            taskkill /F /IM server.exe 2>$null
            Start-Sleep -Seconds 3
            Write-Host "   Backend stopped" -ForegroundColor Green
        } catch {
            Write-Host "   Failed to stop backend: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # 重新启动后端
        try {
            Start-Process -FilePath "./build/server.exe" -WindowStyle Hidden
            Start-Sleep -Seconds 5
            Write-Host "   Backend restarted" -ForegroundColor Green
            
            # 验证修复结果
            Write-Host "`n6. Verifying fix..." -ForegroundColor Yellow
            $newResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/permissions/tree" -Method GET -Headers $headers
            
            if ($newResponse.success) {
                $ticketNodes = $newResponse.data | Where-Object { $_.resource -eq "ticket" }
                if ($ticketNodes.Count -eq 1 -and $ticketNodes[0].children.Count -gt 0) {
                    Write-Host "   ✓ Ticket permissions now have proper tree structure!" -ForegroundColor Green
                } else {
                    Write-Host "   ✗ Ticket permissions still have issues" -ForegroundColor Red
                }
            }
        } catch {
            Write-Host "   Failed to restart or verify: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Cleanup Complete ===" -ForegroundColor Green