# 调试前端权限过滤逻辑
$baseUrl = "http://localhost:8080"

# 登录
$loginData = @{ username = "admin"; password = "admin123" } | ConvertTo-Json -Compress
$loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
$token = $loginResponse.data.token

$headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }

Write-Host "=== Frontend Permission Filter Debug ===" -ForegroundColor Green

# 1. 获取权限树数据
Write-Host "1. Getting permission tree data..." -ForegroundColor Yellow
$treeResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/permissions/tree" -Method GET -Headers $headers

if ($treeResponse.success) {
    $tree = $treeResponse.data
    Write-Host "   Tree nodes: $($tree.Count)" -ForegroundColor Cyan
    
    # 2. 分析每个根节点的resource
    Write-Host "`n2. Root node resources:" -ForegroundColor Yellow
    foreach ($node in $tree) {
        Write-Host "   - Resource: '$($node.resource)', Name: '$($node.name)', DisplayName: '$($node.displayName)'" -ForegroundColor Cyan
    }
    
    # 3. 模拟前端分类生成逻辑
    Write-Host "`n3. Simulating category generation:" -ForegroundColor Yellow
    $categories = @{}
    
    function Traverse-Nodes($nodes) {
        foreach ($node in $nodes) {
            if ($node.resource) {
                $key = $node.resource
                if ($categories.ContainsKey($key)) {
                    $categories[$key].count++
                } else {
                    $categories[$key] = @{
                        key = $key
                        name = Get-ResourceDisplayName $key
                        count = 1
                    }
                }
            }
            if ($node.children -and $node.children.Count -gt 0) {
                Traverse-Nodes $node.children
            }
        }
    }
    
    function Get-ResourceDisplayName($resource) {
        $resourceNames = @{
            'system' = '系统管理'
            'users' = '用户管理'
            'roles' = '角色权限管理'
            'permissions' = '权限管理'
            'records' = '记录管理'
            'files' = '文件管理'
            'export' = '数据导出'
            'notifications' = '通知管理'
            'ai' = 'AI功能'
            'audit' = '审计日志'
            'dashboard' = '仪表盘'
            'ticket' = '工单管理'
        }
        if ($resourceNames.ContainsKey($resource)) {
            return $resourceNames[$resource]
        }
        return $resource
    }
    
    Traverse-Nodes $tree
    
    Write-Host "   Generated categories:" -ForegroundColor Cyan
    foreach ($key in $categories.Keys) {
        $cat = $categories[$key]
        Write-Host "     - Key: '$($cat.key)', Name: '$($cat.name)', Count: $($cat.count)" -ForegroundColor Cyan
    }
    
    # 4. 模拟过滤逻辑
    Write-Host "`n4. Testing filter logic for 'records':" -ForegroundColor Yellow
    $selectedCategory = "records"
    $filtered = @()
    
    foreach ($node in $tree) {
        $shouldInclude = $false
        
        # 检查根节点
        if ($node.resource -eq $selectedCategory) {
            $shouldInclude = $true
            Write-Host "   Root node matches: $($node.name)" -ForegroundColor Green
        }
        
        # 检查子节点
        if ($node.children) {
            foreach ($child in $node.children) {
                if ($child.resource -eq $selectedCategory) {
                    $shouldInclude = $true
                    Write-Host "   Child node matches: $($child.name)" -ForegroundColor Green
                }
            }
        }
        
        if ($shouldInclude) {
            $filtered += $node
        }
    }
    
    Write-Host "   Filtered results: $($filtered.Count) nodes" -ForegroundColor Cyan
    foreach ($node in $filtered) {
        Write-Host "     - $($node.name) ($($node.resource))" -ForegroundColor Cyan
    }
}

Write-Host "`n=== Debug Complete ===" -ForegroundColor Green