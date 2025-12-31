# 调试权限树结构
$baseUrl = "http://localhost:8080"

# 登录
$loginData = @{ username = "admin"; password = "admin123" } | ConvertTo-Json -Compress
$loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
$token = $loginResponse.data.token

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host "=== Permission Tree Structure Debug ===" -ForegroundColor Green

# 1. 获取权限树数据
Write-Host "1. Getting permission tree..." -ForegroundColor Yellow
try {
    $treeResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/permissions/tree" -Method GET -Headers $headers
    
    if ($treeResponse.success -and $treeResponse.data) {
        $tree = $treeResponse.data
        Write-Host "   Success: Found $($tree.Count) root nodes" -ForegroundColor Green
        
        # 分析树结构
        Write-Host "`n2. Analyzing tree structure..." -ForegroundColor Yellow
        foreach ($node in $tree) {
            Write-Host "   Root Node:" -ForegroundColor Cyan
            Write-Host "     - ID: $($node.id)" -ForegroundColor Cyan
            Write-Host "     - Name: $($node.name)" -ForegroundColor Cyan
            Write-Host "     - DisplayName: $($node.displayName)" -ForegroundColor Cyan
            Write-Host "     - Resource: $($node.resource)" -ForegroundColor Cyan
            Write-Host "     - Children: $($node.children.Count)" -ForegroundColor Cyan
            
            if ($node.children -and $node.children.Count -gt 0) {
                Write-Host "     - First Child Resource: $($node.children[0].resource)" -ForegroundColor Cyan
            }
            Write-Host ""
        }
        
        # 检查资源分布
        Write-Host "3. Resource distribution:" -ForegroundColor Yellow
        $resources = @{}
        foreach ($node in $tree) {
            if ($node.resource) {
                if ($resources.ContainsKey($node.resource)) {
                    $resources[$node.resource]++
                } else {
                    $resources[$node.resource] = 1
                }
            }
            
            if ($node.children) {
                foreach ($child in $node.children) {
                    if ($child.resource) {
                        if ($resources.ContainsKey($child.resource)) {
                            $resources[$child.resource]++
                        } else {
                            $resources[$child.resource] = 1
                        }
                    }
                }
            }
        }
        
        foreach ($resource in $resources.Keys) {
            Write-Host "   - ${resource}: $($resources[$resource]) permissions" -ForegroundColor Cyan
        }
    } else {
        Write-Host "   Error: No tree data returned" -ForegroundColor Red
    }
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Debug Complete ===" -ForegroundColor Green