#!/usr/bin/env pwsh
# 用户管理API测试脚本

$BaseUrl = "http://localhost:8080"
$Headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=== 用户管理API测试 ===" -ForegroundColor Yellow
Write-Host ""

# 1. 测试获取用户列表
Write-Host "1. 测试获取用户列表..." -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/users" -Method GET -Headers $Headers
    
    if ($response.success) {
        Write-Host "✓ 获取用户列表成功" -ForegroundColor Green
        Write-Host "  用户总数: $($response.data.total)" -ForegroundColor Cyan
    } else {
        Write-Host "✗ 获取用户列表失败: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 2. 测试创建用户
Write-Host "2. 测试创建用户..." -ForegroundColor Blue

$userData = @{
    username = "testuser_$(Get-Date -Format 'yyyyMMddHHmmss')"
    email = "testuser_$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
    displayName = "Test User"
    password = "password123"
    status = "active"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/users" -Method POST -Body $userData -Headers $Headers
    
    if ($response.success) {
        Write-Host "✓ 用户创建成功" -ForegroundColor Green
        Write-Host "  新用户ID: $($response.data.id)" -ForegroundColor Cyan
        $newUserId = $response.data.id
    } else {
        Write-Host "✗ 用户创建失败: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 3. 测试获取单个用户
if ($newUserId) {
    Write-Host "3. 测试获取单个用户..." -ForegroundColor Blue
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/admin/users/$newUserId" -Method GET -Headers $Headers
        
        if ($response.success) {
            Write-Host "✓ 获取用户详情成功" -ForegroundColor Green
            Write-Host "  用户名: $($response.data.username)" -ForegroundColor Cyan
        } else {
            Write-Host "✗ 获取用户详情失败: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "=== 测试完成 ===" -ForegroundColor Yellow
Write-Host "现在用户管理界面应该能正常工作了" -ForegroundColor Green