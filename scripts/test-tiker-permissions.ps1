# 测试tiker用户权限
Write-Host "=== 测试tiker用户权限 ===" -ForegroundColor Green

# 登录tiker用户
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
    
    Write-Host "1. 用户信息:" -ForegroundColor Yellow
    Write-Host "   用户名: $($loginResponse.data.user.username)"
    Write-Host "   用户ID: $($loginResponse.data.user.id)"
    Write-Host "   角色: $($loginResponse.data.user.roles[0].name)"
    
    Write-Host "`n2. 用户权限:" -ForegroundColor Yellow
    $loginResponse.data.user.permissions | ForEach-Object {
        Write-Host "   $($_.name) - $($_.display_name)"
    }
    
    Write-Host "`n3. 工单列表测试:" -ForegroundColor Yellow
    $ticketsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/tickets" -Method GET -Headers $tikerHeaders
    Write-Host "   可见工单数量: $($ticketsResponse.data.items.Count)"
    
    $ticketsResponse.data.items | ForEach-Object {
        $creatorInfo = if ($_.creator_id -eq 2) { "(自己创建)" } else { "(分配给自己)" }
        Write-Host "   - ID: $($_.id), 标题: $($_.title), 状态: $($_.status) $creatorInfo"
    }
    
    Write-Host "`n4. 权限验证结果:" -ForegroundColor Yellow
    $permissions = $loginResponse.data.user.permissions | ForEach-Object { $_.name }
    
    $permissionChecks = @{
        "创建工单" = $permissions -contains "ticket:create"
        "查看自己工单" = $permissions -contains "ticket:read_own"
        "编辑自己工单" = $permissions -contains "ticket:update_own"
        "删除自己工单" = $permissions -contains "ticket:delete_own"
        "上传附件" = $permissions -contains "ticket:attachment_upload"
        "查看评论" = $permissions -contains "ticket:comment_read"
        "添加评论" = $permissions -contains "ticket:comment_write"
        "工单统计" = $permissions -contains "ticket:statistics"
        "退回工单" = $permissions -contains "ticket:return"
        "接受工单" = $permissions -contains "ticket:accept"
        "拒绝工单" = $permissions -contains "ticket:reject"
        "审批工单" = $permissions -contains "ticket:approve"
        "分配工单" = $permissions -contains "ticket:assign"
    }
    
    $permissionChecks.GetEnumerator() | ForEach-Object {
        $status = if ($_.Value) { "✓" } else { "✗" }
        $color = if ($_.Value) { "Green" } else { "Red" }
        Write-Host "   $status $($_.Key)" -ForegroundColor $color
    }
    
    Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
    
} catch {
    Write-Host "测试失败: $($_.Exception.Message)" -ForegroundColor Red
}