#!/usr/bin/env pwsh
# 更新测试脚本中的API参数格式

Write-Host "🔧 Updating test parameters..." -ForegroundColor Cyan

# 备份原始文件
$scriptPath = "scripts/complete-permission-validation-en.ps1"
$backupPath = "scripts/complete-permission-validation-en.ps1.backup"

if (Test-Path $scriptPath) {
    Copy-Item $scriptPath $backupPath -Force
    Write-Host "✅ Backup created: $backupPath" -ForegroundColor Green
    
    # 读取文件内容
    $content = Get-Content $scriptPath -Raw
    
    # 修复用户创建参数
    $content = $content -replace '"name":\s*"Test User"', '"displayName": "Test User"'
    
    # 修复角色创建参数
    $content = $content -replace '"displayName":\s*"Test Role"', '"displayName": "Test Role"'
    
    # 修复工单创建参数 - 移除status字段，使用正确的枚举值
    $content = $content -replace '"type":\s*"general"', '"type": "bug"'
    $content = $content -replace '"priority":\s*"medium"', '"priority": "normal"'
    $content = $content -replace '"status":\s*"open",?\s*', ''
    
    # 修复记录创建参数
    $content = $content -replace '"type_id":\s*1', '"type": "general"'
    
    # 修复记录类型创建参数
    $content = $content -replace '"displayName":\s*"Test Record Type"', '"display_name": "Test Record Type"'
    
    # 修复系统配置参数
    $content = $content -replace '"key":\s*"test_setting"', '"category": "system", "key": "test_setting"'
    
    # 修复AI配置参数
    $content = $content -replace '"api_key":\s*"test_key"', '"name": "Test AI Config", "api_key": "test_key"'
    
    # 保存修改后的文件
    Set-Content $scriptPath $content -Encoding UTF8
    
    Write-Host "✅ Test parameters updated successfully!" -ForegroundColor Green
    Write-Host "📝 Changes made:" -ForegroundColor Yellow
    Write-Host "  - Fixed user creation: name → displayName" -ForegroundColor Gray
    Write-Host "  - Fixed ticket creation: removed status, fixed type/priority" -ForegroundColor Gray
    Write-Host "  - Fixed record creation: type_id → type" -ForegroundColor Gray
    Write-Host "  - Fixed record type creation: displayName → display_name" -ForegroundColor Gray
    Write-Host "  - Fixed system config: added category field" -ForegroundColor Gray
    Write-Host "  - Fixed AI config: added name field" -ForegroundColor Gray
} else {
    Write-Host "❌ Test script not found: $scriptPath" -ForegroundColor Red
}

Write-Host "`n🎯 Parameter update complete!" -ForegroundColor Green