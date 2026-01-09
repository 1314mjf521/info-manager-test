#!/usr/bin/env pwsh

Write-Host "=== 完整工单流程验证测试 ===" -ForegroundColor Green

# 全局变量
$baseUrl = "http://localhost:8080/api/v1"
$frontendUrl = "http://localhost:3000"
$adminToken = ""
$userToken = ""
$testTicketId = 0

# 测试用户信息
$adminCredentials = @{
    username = "admin"
    password = "admin123"
}

$userCredentials = @{
    username = "test1"
    password = "test123"
}

# 辅助函数：发送HTTP请求
function Invoke-ApiRequest {
    param(
        [string]$Method,
        [string]$Uri,
        [hashtable]$Headers = @{},
        [object]$Body = $null
    )
    
    try {
        $params = @{
            Method = $Method
            Uri = $Uri
            Headers = $Headers
            ContentType = "application/json"
        }
        
        if ($Body) {
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
        }
        
        $response = Invoke-RestMethod @params
        return $response
    } catch {
        Write-Host "API请求失败: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "响应内容: $responseBody" -ForegroundColor Red
        }
        throw
    }
}

# 步骤1：检查服务状态
Write-Host "`n=== 步骤1: 检查服务状态 ===" -ForegroundColor Cyan
try {
    $healthCheck = Invoke-ApiRequest -Method GET -Uri "http://localhost:8080/health"
    Write-Host "✅ 后端服务正常运行" -ForegroundColor Green
} catch {
    Write-Host "❌ 后端服务异常，请检查服务状态" -ForegroundColor Red
    exit 1
}

try {
    $frontendCheck = Invoke-WebRequest -Uri $frontendUrl -Method GET -TimeoutSec 5
    Write-Host "✅ 前端服务正常运行" -ForegroundColor Green
} catch {
    Write-Host "❌ 前端服务异常，请检查服务状态" -ForegroundColor Red
    exit 1
}

# 步骤2：管理员登录
Write-Host "`n=== 步骤2: 管理员登录验证 ===" -ForegroundColor Cyan
try {
    $adminLoginResponse = Invoke-ApiRequest -Method POST -Uri "$baseUrl/auth/login" -Body $adminCredentials
    
    if ($adminLoginResponse.success -and $adminLoginResponse.data.token) {
        $adminToken = $adminLoginResponse.data.token
        Write-Host "✅ 管理员登录成功" -ForegroundColor Green
        Write-Host "管理员用户: $($adminLoginResponse.data.user.username)" -ForegroundColor Gray
        if ($adminLoginResponse.data.user.roles) {
            $roleNames = $adminLoginResponse.data.user.roles | ForEach-Object { $_.name }
            Write-Host "管理员角色: $($roleNames -join ', ')" -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ 管理员登录失败: 响应格式不正确" -ForegroundColor Red
        Write-Host "响应: $($adminLoginResponse | ConvertTo-Json)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ 管理员登录失败" -ForegroundColor Red
    exit 1
}

# 步骤3：创建测试用户（如果不存在）
Write-Host "`n=== 步骤3: 创建测试用户 ===" -ForegroundColor Cyan
$adminHeaders = @{
    "Authorization" = "Bearer $adminToken"
}

try {
    # 检查用户是否存在
    $existingUsers = Invoke-ApiRequest -Method GET -Uri "$baseUrl/admin/users" -Headers $adminHeaders
    $testUser = $existingUsers.data.items | Where-Object { $_.username -eq "test1" }
    
    if (-not $testUser) {
        Write-Host "创建测试用户..." -ForegroundColor Yellow
        $newUser = @{
            username = "test1"
            email = "test1@example.com"
            password = "test123"
            roles = @("用户")
        }
        
        $createUserResponse = Invoke-ApiRequest -Method POST -Uri "$baseUrl/admin/users" -Headers $adminHeaders -Body $newUser
        Write-Host "✅ 测试用户创建成功" -ForegroundColor Green
    } else {
        Write-Host "✅ 测试用户已存在" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ 测试用户创建/检查失败，继续使用现有用户" -ForegroundColor Yellow
}

# 步骤4：普通用户登录
Write-Host "`n=== 步骤4: 普通用户登录验证 ===" -ForegroundColor Cyan
try {
    $userLoginResponse = Invoke-ApiRequest -Method POST -Uri "$baseUrl/auth/login" -Body $userCredentials
    
    if ($userLoginResponse.success -and $userLoginResponse.data.token) {
        $userToken = $userLoginResponse.data.token
        Write-Host "✅ 普通用户登录成功" -ForegroundColor Green
        Write-Host "用户名: $($userLoginResponse.data.user.username)" -ForegroundColor Gray
        if ($userLoginResponse.data.user.roles) {
            $roleNames = $userLoginResponse.data.user.roles | ForEach-Object { $_.name }
            Write-Host "用户角色: $($roleNames -join ', ')" -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ 普通用户登录失败，使用管理员账户继续测试" -ForegroundColor Yellow
        $userToken = $adminToken
    }
} catch {
    Write-Host "⚠️ 普通用户登录失败，使用管理员账户继续测试" -ForegroundColor Yellow
    $userToken = $adminToken
}

# 步骤5：创建工单（普通用户）
Write-Host "`n=== 步骤5: 创建工单 ===" -ForegroundColor Cyan
$userHeaders = @{
    "Authorization" = "Bearer $userToken"
}

$newTicket = @{
    title = "测试工单 - 系统验证"
    type = "bug"
    priority = "normal"
    description = "这是一个用于验证工单流程的测试工单，包含完整的状态流转测试。"
}

try {
    $createTicketResponse = Invoke-ApiRequest -Method POST -Uri "$baseUrl/tickets" -Headers $userHeaders -Body $newTicket
    
    if ($createTicketResponse.success -and $createTicketResponse.data.id) {
        $testTicketId = $createTicketResponse.data.id
        Write-Host "✅ 工单创建成功" -ForegroundColor Green
        Write-Host "工单ID: $testTicketId" -ForegroundColor Gray
        Write-Host "工单状态: $($createTicketResponse.data.status)" -ForegroundColor Gray
    } else {
        Write-Host "❌ 工单创建失败" -ForegroundColor Red
        Write-Host "响应: $($createTicketResponse | ConvertTo-Json)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ 工单创建失败" -ForegroundColor Red
    exit 1
}

# 步骤6：获取工单列表验证
Write-Host "`n=== 步骤6: 验证工单列表 ===" -ForegroundColor Cyan
try {
    $ticketListResponse = Invoke-ApiRequest -Method GET -Uri "$baseUrl/tickets" -Headers $adminHeaders
    
    if ($ticketListResponse.success) {
        $tickets = $ticketListResponse.data.items
        $ourTicket = $tickets | Where-Object { $_.id -eq $testTicketId }
        
        if ($ourTicket) {
            Write-Host "✅ 工单在列表中找到" -ForegroundColor Green
            Write-Host "当前状态: $($ourTicket.status)" -ForegroundColor Gray
        } else {
            Write-Host "❌ 工单未在列表中找到" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "❌ 获取工单列表失败" -ForegroundColor Red
}

# 步骤7：分配工单（管理员）
Write-Host "`n=== 步骤7: 分配工单 ===" -ForegroundColor Cyan
try {
    # 获取用户列表用于分配
    $usersResponse = Invoke-ApiRequest -Method GET -Uri "$baseUrl/system/users" -Headers $adminHeaders
    
    if ($usersResponse.success -and $usersResponse.data.length -gt 0) {
        $assigneeId = $usersResponse.data[0].id
        
        $assignData = @{
            assignee_id = $assigneeId
            comment = "分配给处理人员"
        }
        
        $assignResponse = Invoke-ApiRequest -Method POST -Uri "$baseUrl/tickets/$testTicketId/assign" -Headers $adminHeaders -Body $assignData
        
        if ($assignResponse.success) {
            Write-Host "✅ 工单分配成功" -ForegroundColor Green
            Write-Host "分配给用户ID: $assigneeId" -ForegroundColor Gray
        } else {
            Write-Host "❌ 工单分配失败" -ForegroundColor Red
            Write-Host "响应: $($assignResponse | ConvertTo-Json)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "❌ 工单分配过程失败" -ForegroundColor Red
    Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Red
}

# 步骤8：接受工单
Write-Host "`n=== 步骤8: 接受工单 ===" -ForegroundColor Cyan
try {
    $acceptResponse = Invoke-ApiRequest -Method POST -Uri "$baseUrl/tickets/$testTicketId/accept" -Headers $adminHeaders
    
    if ($acceptResponse.success) {
        Write-Host "✅ 工单接受成功" -ForegroundColor Green
    } else {
        Write-Host "❌ 工单接受失败" -ForegroundColor Red
        Write-Host "响应: $($acceptResponse | ConvertTo-Json)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ 工单接受过程失败" -ForegroundColor Red
    Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Red
}

# 步骤9：更新工单状态为处理中
Write-Host "`n=== 步骤9: 开始处理工单 ===" -ForegroundColor Cyan
try {
    $statusUpdateResponse = Invoke-ApiRequest -Method PUT -Uri "$baseUrl/tickets/$testTicketId/status" -Headers $adminHeaders -Body @{ status = "progress" }
    
    if ($statusUpdateResponse.success) {
        Write-Host "✅ 工单状态更新为处理中" -ForegroundColor Green
    } else {
        Write-Host "❌ 工单状态更新失败" -ForegroundColor Red
        Write-Host "响应: $($statusUpdateResponse | ConvertTo-Json)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ 工单状态更新过程失败" -ForegroundColor Red
    Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Red
}

# 步骤10：解决工单
Write-Host "`n=== 步骤10: 解决工单 ===" -ForegroundColor Cyan
try {
    $resolveResponse = Invoke-ApiRequest -Method PUT -Uri "$baseUrl/tickets/$testTicketId/status" -Headers $adminHeaders -Body @{ status = "resolved" }
    
    if ($resolveResponse.success) {
        Write-Host "✅ 工单解决成功" -ForegroundColor Green
    } else {
        Write-Host "❌ 工单解决失败" -ForegroundColor Red
        Write-Host "响应: $($resolveResponse | ConvertTo-Json)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ 工单解决过程失败" -ForegroundColor Red
    Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Red
}

# 步骤11：关闭工单
Write-Host "`n=== 步骤11: 关闭工单 ===" -ForegroundColor Cyan
try {
    $closeResponse = Invoke-ApiRequest -Method PUT -Uri "$baseUrl/tickets/$testTicketId/status" -Headers $adminHeaders -Body @{ status = "closed" }
    
    if ($closeResponse.success) {
        Write-Host "✅ 工单关闭成功" -ForegroundColor Green
    } else {
        Write-Host "❌ 工单关闭失败" -ForegroundColor Red
        Write-Host "响应: $($closeResponse | ConvertTo-Json)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ 工单关闭过程失败" -ForegroundColor Red
    Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Red
}

# 步骤12：验证最终状态
Write-Host "`n=== 步骤12: 验证最终工单状态 ===" -ForegroundColor Cyan
try {
    $finalTicketResponse = Invoke-ApiRequest -Method GET -Uri "$baseUrl/tickets/$testTicketId" -Headers $adminHeaders
    
    if ($finalTicketResponse.success) {
        $finalTicket = $finalTicketResponse.data
        Write-Host "✅ 工单最终状态验证" -ForegroundColor Green
        Write-Host "工单ID: $($finalTicket.id)" -ForegroundColor Gray
        Write-Host "标题: $($finalTicket.title)" -ForegroundColor Gray
        Write-Host "状态: $($finalTicket.status)" -ForegroundColor Gray
        Write-Host "创建时间: $($finalTicket.created_at)" -ForegroundColor Gray
        Write-Host "更新时间: $($finalTicket.updated_at)" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ 最终状态验证失败" -ForegroundColor Red
}

# 步骤13：权限验证测试
Write-Host "`n=== 步骤13: 权限系统验证 ===" -ForegroundColor Cyan

# 测试普通用户权限
Write-Host "测试普通用户权限..." -ForegroundColor Yellow
try {
    # 普通用户尝试访问管理员功能
    $userAdminTest = Invoke-ApiRequest -Method GET -Uri "$baseUrl/admin/users" -Headers $userHeaders
    Write-Host "⚠️ 普通用户可以访问管理员功能（权限配置可能有问题）" -ForegroundColor Yellow
} catch {
    Write-Host "✅ 普通用户无法访问管理员功能（权限正常）" -ForegroundColor Green
}

# 测试工单操作权限
try {
    $userTicketTest = Invoke-ApiRequest -Method GET -Uri "$baseUrl/tickets" -Headers $userHeaders
    if ($userTicketTest.success) {
        Write-Host "✅ 普通用户可以查看工单列表" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ 普通用户无法查看工单列表" -ForegroundColor Red
}

# 步骤14：前端集成测试
Write-Host "`n=== 步骤14: 前端集成验证 ===" -ForegroundColor Cyan
Write-Host "请手动验证以下前端功能:" -ForegroundColor Yellow
Write-Host "1. 访问 $frontendUrl" -ForegroundColor White
Write-Host "2. 使用 admin/admin123 登录" -ForegroundColor White
Write-Host "3. 进入工单管理页面" -ForegroundColor White
Write-Host "4. 验证工单 ID $testTicketId 的状态显示" -ForegroundColor White
Write-Host "5. 验证不同状态工单的操作按钮" -ForegroundColor White

# 清理测试数据
Write-Host "`n=== 步骤15: 清理测试数据 ===" -ForegroundColor Cyan
$cleanup = Read-Host "是否删除测试工单? (y/N)"
if ($cleanup -eq "y" -or $cleanup -eq "Y") {
    try {
        $deleteResponse = Invoke-ApiRequest -Method DELETE -Uri "$baseUrl/tickets/$testTicketId" -Headers $adminHeaders
        if ($deleteResponse.success) {
            Write-Host "✅ 测试工单已删除" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️ 测试工单删除失败，请手动删除" -ForegroundColor Yellow
    }
}

Write-Host "`n=== 工单流程验证完成 ===" -ForegroundColor Green
Write-Host "测试工单ID: $testTicketId" -ForegroundColor Gray
Write-Host "请检查前端界面确认所有功能正常工作" -ForegroundColor Yellow