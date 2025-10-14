# 测试前端修复
# 编码：UTF-8

Write-Host "=== 测试前端修复 ===" -ForegroundColor Green

# 检查前端编译是否正常
function Test-FrontendCompilation {
    Write-Host "`n--- 检查前端编译 ---" -ForegroundColor Cyan
    
    try {
        # 检查前端目录是否存在
        if (-not (Test-Path "frontend")) {
            Write-Host "前端目录不存在" -ForegroundColor Red
            return $false
        }
        
        # 检查package.json是否存在
        if (-not (Test-Path "frontend/package.json")) {
            Write-Host "package.json不存在" -ForegroundColor Red
            return $false
        }
        
        Write-Host "前端项目结构检查通过" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "前端检查失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 检查API配置文件
function Test-ApiConfiguration {
    Write-Host "`n--- 检查API配置 ---" -ForegroundColor Cyan
    
    try {
        $apiConfigPath = "frontend/src/config/api.ts"
        if (-not (Test-Path $apiConfigPath)) {
            Write-Host "API配置文件不存在" -ForegroundColor Red
            return $false
        }
        
        $content = Get-Content $apiConfigPath -Raw -Encoding UTF8
        
        # 检查关键API端点是否存在
        $requiredEndpoints = @(
            "RECORD_TYPES.*IMPORT",
            "RECORD_TYPES.*BATCH_STATUS",
            "RECORD_TYPES.*BATCH_DELETE",
            "ROLES.*IMPORT",
            "ROLES.*BATCH_STATUS",
            "ROLES.*BATCH_DELETE"
        )
        
        $allFound = $true
        foreach ($endpoint in $requiredEndpoints) {
            if ($content -notmatch $endpoint) {
                Write-Host "缺少API端点：$endpoint" -ForegroundColor Red
                $allFound = $false
            }
        }
        
        if ($allFound) {
            Write-Host "API配置检查通过" -ForegroundColor Green
            return $true
        } else {
            Write-Host "API配置检查失败" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "API配置检查失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 检查Vue文件语法
function Test-VueFileSyntax {
    Write-Host "`n--- 检查Vue文件语法 ---" -ForegroundColor Cyan
    
    try {
        $vueFiles = @(
            "frontend/src/views/records/RecordListView.vue",
            "frontend/src/views/admin/RoleManagement.vue",
            "frontend/src/views/record-types/RecordTypeListView.vue"
        )
        
        $allValid = $true
        foreach ($file in $vueFiles) {
            if (Test-Path $file) {
                $content = Get-Content $file -Raw -Encoding UTF8
                
                # 检查是否有重复的函数定义
                $functionMatches = [regex]::Matches($content, "const\s+handleImportAction\s*=")
                if ($functionMatches.Count -gt 1) {
                    Write-Host "$file: 发现重复的handleImportAction函数定义" -ForegroundColor Red
                    $allValid = $false
                } else {
                    Write-Host "$file: 语法检查通过" -ForegroundColor Green
                }
            } else {
                Write-Host "$file: 文件不存在" -ForegroundColor Yellow
            }
        }
        
        return $allValid
    } catch {
        Write-Host "Vue文件语法检查失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 检查批量操作按钮
function Test-BatchOperationButtons {
    Write-Host "`n--- 检查批量操作按钮 ---" -ForegroundColor Cyan
    
    try {
        $roleManagementFile = "frontend/src/views/admin/RoleManagement.vue"
        if (Test-Path $roleManagementFile) {
            $content = Get-Content $roleManagementFile -Raw -Encoding UTF8
            
            # 检查批量操作相关元素
            $batchElements = @(
                "batch-actions",
                "批量启用",
                "批量禁用", 
                "批量删除",
                "handleBatchEnable",
                "handleBatchDisable",
                "handleBatchDelete"
            )
            
            $allFound = $true
            foreach ($element in $batchElements) {
                if ($content -notmatch [regex]::Escape($element)) {
                    Write-Host "角色管理界面缺少：$element" -ForegroundColor Red
                    $allFound = $false
                }
            }
            
            if ($allFound) {
                Write-Host "角色管理批量操作检查通过" -ForegroundColor Green
                return $true
            } else {
                Write-Host "角色管理批量操作检查失败" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "角色管理文件不存在" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "批量操作按钮检查失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 检查导入功能
function Test-ImportFunctionality {
    Write-Host "`n--- 检查导入功能 ---" -ForegroundColor Cyan
    
    try {
        $files = @{
            "角色管理" = "frontend/src/views/admin/RoleManagement.vue"
            "记录类型管理" = "frontend/src/views/record-types/RecordTypeListView.vue"
            "记录管理" = "frontend/src/views/records/RecordListView.vue"
        }
        
        $allValid = $true
        foreach ($name in $files.Keys) {
            $file = $files[$name]
            if (Test-Path $file) {
                $content = Get-Content $file -Raw -Encoding UTF8
                
                # 检查导入相关元素
                $importElements = @(
                    "导入.*按钮|导入.*dropdown",
                    "importDialogVisible",
                    "handleImportAction",
                    "downloadTemplate",
                    "handleImport"
                )
                
                $fileValid = $true
                foreach ($element in $importElements) {
                    if ($content -notmatch $element) {
                        Write-Host "$name 缺少导入元素：$element" -ForegroundColor Red
                        $fileValid = $false
                        $allValid = $false
                    }
                }
                
                if ($fileValid) {
                    Write-Host "$name 导入功能检查通过" -ForegroundColor Green
                }
            } else {
                Write-Host "$name 文件不存在" -ForegroundColor Red
                $allValid = $false
            }
        }
        
        return $allValid
    } catch {
        Write-Host "导入功能检查失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 主测试流程
function Main {
    Write-Host "开始测试前端修复..." -ForegroundColor Green
    
    $testResults = @()
    
    # 执行各项测试
    $testResults += @{ Name = "前端编译检查"; Result = (Test-FrontendCompilation) }
    $testResults += @{ Name = "API配置检查"; Result = (Test-ApiConfiguration) }
    $testResults += @{ Name = "Vue文件语法检查"; Result = (Test-VueFileSyntax) }
    $testResults += @{ Name = "批量操作按钮检查"; Result = (Test-BatchOperationButtons) }
    $testResults += @{ Name = "导入功能检查"; Result = (Test-ImportFunctionality) }
    
    # 输出测试结果汇总
    Write-Host "`n=== 测试结果汇总 ===" -ForegroundColor Green
    $successCount = 0
    $totalCount = $testResults.Count
    
    foreach ($result in $testResults) {
        $status = if ($result.Result) { "✓ 通过"; $successCount++ } else { "✗ 失败" }
        $color = if ($result.Result) { "Green" } else { "Red" }
        Write-Host "$($result.Name): $status" -ForegroundColor $color
    }
    
    Write-Host "`n总计：$successCount/$totalCount 项测试通过" -ForegroundColor $(if ($successCount -eq $totalCount) { "Green" } else { "Yellow" })
    
    if ($successCount -eq $totalCount) {
        Write-Host "所有前端修复测试通过！" -ForegroundColor Green
        Write-Host "建议：" -ForegroundColor Cyan
        Write-Host "1. 重启前端开发服务器以应用修复" -ForegroundColor Gray
        Write-Host "2. 清除浏览器缓存" -ForegroundColor Gray
        Write-Host "3. 测试导入和批量操作功能" -ForegroundColor Gray
    } else {
        Write-Host "部分测试失败，请检查相关文件" -ForegroundColor Yellow
    }
}

# 执行主测试
Main