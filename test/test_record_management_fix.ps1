# 测试记录管理界面修复
# 编码：UTF-8

Write-Host "=== 测试记录管理界面修复 ===" -ForegroundColor Green

# 检查Vue文件语法
function Test-RecordListViewSyntax {
    Write-Host "`n--- 检查记录管理界面语法 ---" -ForegroundColor Cyan
    
    try {
        $filePath = "frontend/src/views/records/RecordListView.vue"
        if (-not (Test-Path $filePath)) {
            Write-Host "记录管理界面文件不存在" -ForegroundColor Red
            return $false
        }
        
        $content = Get-Content $filePath -Raw -Encoding UTF8
        
        # 检查重复函数定义
        $duplicateFunctions = @(
            "handleImportAction",
            "handleRecordFileChange", 
            "parseImportRecordFile",
            "removeRecordFile",
            "handleImportRecords",
            "formatFileSize"
        )
        
        $allValid = $true
        foreach ($funcName in $duplicateFunctions) {
            $matches = [regex]::Matches($content, "const\s+$funcName\s*=")
            if ($matches.Count -gt 1) {
                Write-Host "发现重复的函数定义：$funcName (出现 $($matches.Count) 次)" -ForegroundColor Red
                $allValid = $false
            } else {
                Write-Host "函数 $funcName: ✓" -ForegroundColor Green
            }
        }
        
        # 检查是否有孤立的return语句
        $orphanReturns = [regex]::Matches($content, "^\s*if.*return.*$", [System.Text.RegularExpressions.RegexOptions]::Multiline)
        if ($orphanReturns.Count -gt 0) {
            # 进一步检查这些return是否在函数内
            $functionBlocks = [regex]::Matches($content, "const\s+\w+\s*=.*?=>\s*\{.*?\}", [System.Text.RegularExpressions.RegexOptions]::Singleline)
            $orphanCount = 0
            
            foreach ($returnMatch in $orphanReturns) {
                $isInFunction = $false
                foreach ($funcBlock in $functionBlocks) {
                    if ($returnMatch.Index -gt $funcBlock.Index -and $returnMatch.Index -lt ($funcBlock.Index + $funcBlock.Length)) {
                        $isInFunction = $true
                        break
                    }
                }
                if (-not $isInFunction) {
                    $orphanCount++
                }
            }
            
            if ($orphanCount -gt 0) {
                Write-Host "发现 $orphanCount 个孤立的return语句" -ForegroundColor Red
                $allValid = $false
            }
        }
        
        # 检查基本的Vue语法结构
        if ($content -notmatch "<template>.*</template>" -or 
            $content -notmatch "<script.*>.*</script>" -or 
            $content -notmatch "<style.*>.*</style>") {
            Write-Host "Vue文件基本结构不完整" -ForegroundColor Red
            $allValid = $false
        } else {
            Write-Host "Vue文件基本结构: ✓" -ForegroundColor Green
        }
        
        # 检查导入语句
        $requiredImports = @(
            "useRouter",
            "ref",
            "reactive", 
            "onMounted",
            "ElMessage",
            "http",
            "API_ENDPOINTS"
        )
        
        foreach ($import in $requiredImports) {
            if ($content -notmatch [regex]::Escape($import)) {
                Write-Host "缺少必要的导入：$import" -ForegroundColor Red
                $allValid = $false
            }
        }
        
        if ($allValid) {
            Write-Host "记录管理界面语法检查通过" -ForegroundColor Green
        } else {
            Write-Host "记录管理界面语法检查失败" -ForegroundColor Red
        }
        
        return $allValid
    } catch {
        Write-Host "语法检查失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 检查导入功能完整性
function Test-ImportFunctionality {
    Write-Host "`n--- 检查导入功能完整性 ---" -ForegroundColor Cyan
    
    try {
        $filePath = "frontend/src/views/records/RecordListView.vue"
        $content = Get-Content $filePath -Raw -Encoding UTF8
        
        # 检查导入相关元素
        $importElements = @(
            "导入记录",
            "importDialogVisible",
            "handleImportAction",
            "downloadRecordTemplate",
            "handleRecordFileChange",
            "parseImportRecordFile",
            "removeRecordFile",
            "handleImportRecords",
            "formatFileSize"
        )
        
        $allFound = $true
        foreach ($element in $importElements) {
            if ($content -notmatch [regex]::Escape($element)) {
                Write-Host "缺少导入元素：$element" -ForegroundColor Red
                $allFound = $false
            } else {
                Write-Host "导入元素 $element: ✓" -ForegroundColor Green
            }
        }
        
        # 检查API端点使用
        if ($content -match "API_ENDPOINTS\.RECORDS\.IMPORT") {
            Write-Host "API端点使用: ✓" -ForegroundColor Green
        } else {
            Write-Host "API端点使用不正确" -ForegroundColor Red
            $allFound = $false
        }
        
        return $allFound
    } catch {
        Write-Host "导入功能检查失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 检查API配置
function Test-ApiConfiguration {
    Write-Host "`n--- 检查API配置 ---" -ForegroundColor Cyan
    
    try {
        $apiConfigPath = "frontend/src/config/api.ts"
        if (-not (Test-Path $apiConfigPath)) {
            Write-Host "API配置文件不存在" -ForegroundColor Red
            return $false
        }
        
        $content = Get-Content $apiConfigPath -Raw -Encoding UTF8
        
        # 检查记录相关的API端点
        $requiredEndpoints = @(
            "RECORDS.*LIST",
            "RECORDS.*CREATE",
            "RECORDS.*IMPORT"
        )
        
        $allFound = $true
        foreach ($endpoint in $requiredEndpoints) {
            if ($content -notmatch $endpoint) {
                Write-Host "缺少API端点：$endpoint" -ForegroundColor Red
                $allFound = $false
            } else {
                Write-Host "API端点 $endpoint: ✓" -ForegroundColor Green
            }
        }
        
        return $allFound
    } catch {
        Write-Host "API配置检查失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 主测试流程
function Main {
    Write-Host "开始测试记录管理界面修复..." -ForegroundColor Green
    
    $testResults = @()
    
    # 执行各项测试
    $testResults += @{ Name = "记录管理界面语法检查"; Result = (Test-RecordListViewSyntax) }
    $testResults += @{ Name = "导入功能完整性检查"; Result = (Test-ImportFunctionality) }
    $testResults += @{ Name = "API配置检查"; Result = (Test-ApiConfiguration) }
    
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
        Write-Host "记录管理界面修复验证成功！" -ForegroundColor Green
        Write-Host "建议：" -ForegroundColor Cyan
        Write-Host "1. 重启前端开发服务器" -ForegroundColor Gray
        Write-Host "2. 清除浏览器缓存" -ForegroundColor Gray
        Write-Host "3. 测试记录管理界面的导入功能" -ForegroundColor Gray
    } else {
        Write-Host "部分测试失败，请检查相关问题" -ForegroundColor Yellow
    }
}

# 执行主测试
Main