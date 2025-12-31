#!/usr/bin/env pwsh

Write-Host "=== 权限树结构详细测试 ===" -ForegroundColor Green

# 登录获取token
$loginBody = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $loginResponse.data.token
$headers = @{"Authorization" = "Bearer $token"}

Write-Host "1. 获取权限树结构..." -ForegroundColor Yellow
$treeResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions/tree" -Headers $headers

Write-Host "2. 分析系统管理权限树..." -ForegroundColor Yellow
$systemNode = $treeResponse.data | Where-Object { $_.name -eq "system" }
if ($systemNode) {
    Write-Host "系统管理根节点: $($systemNode.displayName)" -ForegroundColor Cyan
    Write-Host "二级子节点数量: $($systemNode.children.Count)" -ForegroundColor Cyan
    
    foreach ($child in $systemNode.children) {
        Write-Host "  - $($child.displayName) (ID: $($child.id))" -ForegroundColor White
        if ($child.children -and $child.children.Count -gt 0) {
            Write-Host "    三级子节点数量: $($child.children.Count)" -ForegroundColor Gray
            foreach ($grandchild in $child.children) {
                Write-Host "      * $($grandchild.displayName) (ID: $($grandchild.id))" -ForegroundColor DarkGray
            }
        } else {
            Write-Host "    无三级子节点" -ForegroundColor Red
        }
    }
} else {
    Write-Host "未找到系统管理权限节点" -ForegroundColor Red
}

Write-Host ""
Write-Host "3. 统计所有权限数量..." -ForegroundColor Yellow
function Count-AllNodes($nodes) {
    $count = 0
    foreach ($node in $nodes) {
        $count++
        if ($node.children -and $node.children.Count -gt 0) {
            $count += Count-AllNodes($node.children)
        }
    }
    return $count
}

$totalTreeNodes = Count-AllNodes($treeResponse.data)
Write-Host "权限树总节点数: $totalTreeNodes" -ForegroundColor Green

Write-Host ""
Write-Host "4. 对比平面权限数据..." -ForegroundColor Yellow
$allPermsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions" -Headers $headers
Write-Host "平面权限总数: $($allPermsResponse.data.Count)" -ForegroundColor Green

if ($totalTreeNodes -eq $allPermsResponse.data.Count) {
    Write-Host "✓ 权限树结构完整" -ForegroundColor Green
} else {
    Write-Host "✗ 权限树缺少 $($allPermsResponse.data.Count - $totalTreeNodes) 个权限" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== 测试完成 ===" -ForegroundColor Green