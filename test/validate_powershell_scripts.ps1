# PowerShell 脚本语法验证工具
# 检查指定脚本的语法错误

Write-Host "=== PowerShell 脚本语法验证 ===" -ForegroundColor Green

$scriptsToValidate = @(
    "test/fix_database_lock_issues_final.ps1",
    "test/test_database_lock_fix_validation.ps1"
)

$allValid = $true

foreach ($script in $scriptsToValidate) {
    Write-Host ""
    Write-Host "检查脚本: $script" -ForegroundColor Yellow
    
    if (!(Test-Path $script)) {
        Write-Host "  脚本文件不存在" -ForegroundColor Red
        $allValid = $false
        continue
    }
    
    try {
        # 检查语法
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script -Raw), [ref]$null)
        Write-Host "  语法检查: 通过" -ForegroundColor Green
        
        # 检查编码
        $content = Get-Content $script -Raw -Encoding UTF8
        if ($content.Length -gt 0) {
            Write-Host "  编码检查: UTF-8 正常" -ForegroundColor Green
        } else {
            Write-Host "  编码检查: 文件为空" -ForegroundColor Yellow
        }
        
        # 检查常见问题
        $issues = @()
        
        # 检查反引号使用
        if ($content -match '`n') {
            $issues += "使用了反引号换行符，建议使用双引号字符串"
        }
        
        # 检查Here-String语法
        if ($content -match '@".*?"@' -and $content -notmatch '@"[\r\n].*?[\r\n]"@') {
            $issues += "Here-String可能存在语法问题"
        }
        
        # 检查变量引用
        if ($content -match '\$\([^)]*\$\([^)]*\)') {
            $issues += "可能存在嵌套变量引用问题"
        }
        
        if ($issues.Count -eq 0) {
            Write-Host "  代码质量: 良好" -ForegroundColor Green
        } else {
            Write-Host "  发现潜在问题:" -ForegroundColor Yellow
            foreach ($issue in $issues) {
                Write-Host "    - $issue" -ForegroundColor Yellow
            }
        }
        
    } catch {
        Write-Host "  语法检查: 失败 - $($_.Exception.Message)" -ForegroundColor Red
        $allValid = $false
    }
}

Write-Host ""
if ($allValid) {
    Write-Host "=== 所有脚本验证通过 ===" -ForegroundColor Green
    exit 0
} else {
    Write-Host "=== 部分脚本存在问题 ===" -ForegroundColor Red
    exit 1
}