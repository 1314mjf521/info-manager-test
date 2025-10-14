#!/usr/bin/env pwsh
# 测试导入功能修复脚本

Write-Host "=== 测试导入功能修复 ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080"
$token = ""

# 登录获取token
Write-Host "`n1. 登录获取token..." -ForegroundColor Yellow
try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method Post -Body (@{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json) -ContentType "application/json"
    
    $token = $loginResponse.data.token
    Write-Host "✓ 登录成功，获取到token" -ForegroundColor Green
} catch {
    Write-Host "✗ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# 测试角色导入接口
Write-Host "`n2. 测试角色导入接口..." -ForegroundColor Yellow
try {
    $roleImportData = @{
        roles = @(
            @{
                name = "test_role_import"
                displayName = "测试导入角色"
                description = "通过导入功能创建的测试角色"
                status = "active"
                permissions = "users:read,records:read"
            }
        )
    }
    
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/admin/roles/import" -Method Post -Body ($roleImportData | ConvertTo-Json -Depth 3) -Headers $headers
    
    if ($response.success) {
        Write-Host "✓ 角色导入接口测试成功" -ForegroundColor Green
        Write-Host "  导入结果: $($response.data.results.Count) 个角色" -ForegroundColor Cyan
    } else {
        Write-Host "✗ 角色导入接口返回失败" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 角色导入接口测试失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试角色批量操作接口
Write-Host "`n3. 测试角色批量操作接口..." -ForegroundColor Yellow
try {
    # 先获取角色列表
    $rolesResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/admin/roles" -Method Get -Headers $headers
    
    if ($rolesResponse.success -and $rolesResponse.data.Count -gt 0) {
        $testRoleId = $rolesResponse.data[0].id
        
        # 测试批量更新状态
        $batchUpdateData = @{
            role_ids = @($testRoleId)
            status = "active"
        }
        
        $updateResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/admin/roles/batch-status" -Method Put -Body ($batchUpdateData | ConvertTo-Json) -Headers $headers
        
        if ($updateResponse.success) {
            Write-Host "✓ 角色批量更新接口测试成功" -ForegroundColor Green
        } else {
            Write-Host "✗ 角色批量更新接口返回失败" -ForegroundColor Red
        }
    } else {
        Write-Host "! 没有找到可测试的角色" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ 角色批量操作接口测试失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试记录导入接口
Write-Host "`n4. 测试记录导入接口..." -ForegroundColor Yellow
try {
    $recordImportData = @{
        type = "daily_report"
        records = @(
            @{
                title = "测试导入记录"
                content = @{
                    summary = "这是通过导入功能创建的测试记录"
                    details = "测试内容"
                }
                tags = @("测试", "导入")
            }
        )
    }
    
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/records/import" -Method Post -Body ($recordImportData | ConvertTo-Json -Depth 3) -Headers $headers
    
    if ($response.success) {
        Write-Host "✓ 记录导入接口测试成功" -ForegroundColor Green
        Write-Host "  导入结果: $($response.data.Count) 条记录" -ForegroundColor Cyan
    } else {
        Write-Host "✗ 记录导入接口返回失败" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 记录导入接口测试失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试记录批量操作接口
Write-Host "`n5. 测试记录批量操作接口..." -ForegroundColor Yellow
try {
    # 先获取记录列表
    $recordsResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/records" -Method Get -Headers $headers
    
    if ($recordsResponse.success -and $recordsResponse.data.items.Count -gt 0) {
        $testRecordId = $recordsResponse.data.items[0].id
        
        # 测试批量更新状态
        $batchUpdateData = @{
            record_ids = @($testRecordId)
            status = "published"
        }
        
        $updateResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/records/batch-status" -Method Put -Body ($batchUpdateData | ConvertTo-Json) -Headers $headers
        
        if ($updateResponse.success) {
            Write-Host "✓ 记录批量更新接口测试成功" -ForegroundColor Green
        } else {
            Write-Host "✗ 记录批量更新接口返回失败" -ForegroundColor Red
        }
    } else {
        Write-Host "! 没有找到可测试的记录" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ 记录批量操作接口测试失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== 导入功能修复测试完成 ===" -ForegroundColor Green
Write-Host "请检查上述测试结果，确认导入功能是否正常工作" -ForegroundColor Cyan