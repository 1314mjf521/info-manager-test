# 验证PowerShell脚本语法和编码格式的脚本
# 编码：UTF-8

Write-Host "=== 验证PowerShell脚本语法和编码格式 ===" -ForegroundColor Green

# 获取所有PowerShell测试脚本
$scriptFiles = Get-ChildItem -Path "test" -Filter "*.ps1" | Where-Object { $_.Name -ne "validate_scripts.ps1" }

$totalScripts = $scriptFiles.Count
$validScripts = 0
$invalidScripts = 0

Write-Host "找到 $totalScripts 个PowerShell脚本文件" -ForegroundColor Cyan

foreach ($script in $scriptFiles) {
    Write-Host "`n检查脚本: $($script.Name)" -ForegroundColor Yellow
    
    try {
        # 检查语法
        $syntaxErrors = $null
        $tokens = $null
        $parseErrors = $null
        
        # 使用PowerShell AST解析器检查语法
        $scriptContent = Get-Content -Path $script.FullName -Raw -Encoding UTF8
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$tokens, [ref]$parseErrors)
        
        if ($parseErrors.Count -eq 0) {
            Write-Host "  ✓ 语法检查通过" -ForegroundColor Green
            
            # 检查编码格式
            $encoding = Get-FileEncoding -Path $script.FullName
            Write-Host "  ✓ 编码格式: $encoding" -ForegroundColor Green
            
            # 检查是否包含BOM
            $bytes = [System.IO.File]::ReadAllBytes($script.FullName)
            if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                Write-Host "  ✓ 包含UTF-8 BOM" -ForegroundColor Green
            } else {
                Write-Host "  ! 不包含UTF-8 BOM（可能影响中文显示）" -ForegroundColor Yellow
            }
            
            # 检查脚本结构
            $hasMainLogic = $scriptContent -match "try\s*\{"
            $hasErrorHandling = $scriptContent -match "catch\s*\{"
            $hasLogging = $scriptContent -match "Write-Host"
            
            if ($hasMainLogic) {
                Write-Host "  ✓ 包含主要逻辑结构" -ForegroundColor Green
            }
            if ($hasErrorHandling) {
                Write-Host "  ✓ 包含错误处理" -ForegroundColor Green
            }
            if ($hasLogging) {
                Write-Host "  ✓ 包含日志输出" -ForegroundColor Green
            }
            
            $validScripts++
        } else {
            Write-Host "  ✗ 语法错误:" -ForegroundColor Red
            foreach ($error in $parseErrors) {
                Write-Host "    - 行 $($error.Extent.StartLineNumber): $($error.Message)" -ForegroundColor Red
            }
            $invalidScripts++
        }
        
    } catch {
        Write-Host "  ✗ 检查失败: $($_.Exception.Message)" -ForegroundColor Red
        $invalidScripts++
    }
}

# 函数：获取文件编码
function Get-FileEncoding {
    param([string]$Path)
    
    $bytes = [byte[]](Get-Content $Path -Encoding byte -ReadCount 4 -TotalCount 4)
    
    if (!$bytes) { return "ASCII" }
    
    switch -regex ('{0:x2}{1:x2}{2:x2}{3:x2}' -f $bytes[0], $bytes[1], $bytes[2], $bytes[3]) {
        '^efbbbf'   { return "UTF-8 BOM" }
        '^2b2f76'   { return "UTF-7" }
        '^fffe'     { return "UTF-16 LE BOM" }
        '^feff'     { return "UTF-16 BE BOM" }
        '^0000feff' { return "UTF-32 BE BOM" }
        '^fffe0000' { return "UTF-32 LE BOM" }
        default     { return "ASCII/UTF-8" }
    }
}

# 生成验证报告
Write-Host "`n=== 验证报告 ===" -ForegroundColor Magenta
Write-Host "总脚本数: $totalScripts" -ForegroundColor White
Write-Host "有效脚本: $validScripts" -ForegroundColor Green
Write-Host "无效脚本: $invalidScripts" -ForegroundColor Red

$successRate = if ($totalScripts -gt 0) { [math]::Round(($validScripts / $totalScripts) * 100, 2) } else { 0 }
Write-Host "有效率: $successRate%" -ForegroundColor $(if ($successRate -eq 100) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })

if ($invalidScripts -eq 0) {
    Write-Host "`n✓ 所有脚本验证通过！" -ForegroundColor Green
} else {
    Write-Host "`n! 发现 $invalidScripts 个脚本存在问题，请检查并修复" -ForegroundColor Yellow
}

Write-Host "`n=== 脚本验证完成 ===" -ForegroundColor Green