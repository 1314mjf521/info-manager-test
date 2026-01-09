#!/usr/bin/env pwsh
# 修复前端导入路径问题

Write-Host "🔧 修复前端导入路径..." -ForegroundColor Cyan

$frontendPath = "frontend"

if (!(Test-Path $frontendPath)) {
    Write-Host "[ERROR] 前端目录不存在" -ForegroundColor Red
    exit 1
}

Push-Location $frontendPath

try {
    Write-Host "📝 修复 router/index.ts 中的所有导入路径..." -ForegroundColor Yellow
    
    # 读取 router 文件内容
    $routerFile = "src/router/index.ts"
    $content = Get-Content $routerFile -Raw
    
    # 替换所有的 @/ 导入为相对路径
    $content = $content -replace "@/views/dashboard/DashboardView\.vue", "../views/dashboard/DashboardView.vue"
    $content = $content -replace "@/views/records/RecordListView\.vue", "../views/records/RecordListView.vue"
    $content = $content -replace "@/views/records/RecordFormView\.vue", "../views/records/RecordFormView.vue"
    $content = $content -replace "@/views/records/RecordDetailView\.vue", "../views/records/RecordDetailView.vue"
    $content = $content -replace "@/views/record-types/RecordTypeListView\.vue", "../views/record-types/RecordTypeListView.vue"
    $content = $content -replace "@/views/files/FileListView\.vue", "../views/files/FileListView.vue"
    $content = $content -replace "@/views/tickets/TicketListView\.vue", "../views/tickets/TicketListView.vue"
    $content = $content -replace "@/views/tickets/TicketTestView\.vue", "../views/tickets/TicketTestView.vue"
    $content = $content -replace "@/views/tickets/TicketTestSimple\.vue", "../views/tickets/TicketTestSimple.vue"
    $content = $content -replace "@/views/tickets/TicketFormView\.vue", "../views/tickets/TicketFormView.vue"
    $content = $content -replace "@/views/tickets/TicketDetailView\.vue", "../views/tickets/TicketDetailView.vue"
    $content = $content -replace "@/views/tickets/TicketAssignView\.vue", "../views/tickets/TicketAssignView.vue"
    $content = $content -replace "@/views/export/ExportView\.vue", "../views/export/ExportView.vue"
    $content = $content -replace "@/views/admin/UserManagement\.vue", "../views/admin/UserManagement.vue"
    $content = $content -replace "@/views/admin/RoleManagement\.vue", "../views/admin/RoleManagement.vue"
    $content = $content -replace "@/views/permissions/PermissionManagement\.vue", "../views/permissions/PermissionManagement.vue"
    $content = $content -replace "@/views/ai/AIManagement\.vue", "../views/ai/AIManagement.vue"
    $content = $content -replace "@/views/system/SystemView\.vue", "../views/system/SystemView.vue"
    $content = $content -replace "@/views/profile/ProfileView\.vue", "../views/profile/ProfileView.vue"
    $content = $content -replace "@/views/debug/LoginDebugView\.vue", "../views/debug/LoginDebugView.vue"
    $content = $content -replace "@/views/error/NotFoundView\.vue", "../views/error/NotFoundView.vue"
    
    # 替换 types 导入
    $content = $content -replace "@/types", "../types"
    
    # 写回文件
    $content | Out-File -FilePath $routerFile -Encoding UTF8
    
    Write-Host "  ✅ router/index.ts 路径修复完成" -ForegroundColor Green
    
    Write-Host "📝 修复 stores/auth.ts 中的导入路径..." -ForegroundColor Yellow
    
    # 修复 auth store 中的导入
    $authFile = "src/stores/auth.ts"
    $authContent = Get-Content $authFile -Raw
    
    $authContent = $authContent -replace "@/utils/request", "../utils/request"
    $authContent = $authContent -replace "@/config/api", "../config/api"
    $authContent = $authContent -replace "@/types", "../types"
    
    # 移除对 router 的导入，避免循环依赖
    $authContent = $authContent -replace "import router from '@/router'", ""
    $authContent = $authContent -replace "router\.push\('/login'\)", "window.location.href = '/login'"
    
    $authContent | Out-File -FilePath $authFile -Encoding UTF8
    
    Write-Host "  ✅ stores/auth.ts 路径修复完成" -ForegroundColor Green
    
    Write-Host "📝 修复 utils/request.ts 中的导入路径..." -ForegroundColor Yellow
    
    # 修复 request 文件中的导入
    $requestFile = "src/utils/request.ts"
    $requestContent = Get-Content $requestFile -Raw
    
    $requestContent = $requestContent -replace "@/stores/auth", "../stores/auth"
    $requestContent = $requestContent -replace "@/config/api", "../config/api"
    $requestContent = $requestContent -replace "@/router", "../router"
    
    $requestContent | Out-File -FilePath $requestFile -Encoding UTF8
    
    Write-Host "  ✅ utils/request.ts 路径修复完成" -ForegroundColor Green
    
    Write-Host "🧹 清理缓存..." -ForegroundColor Yellow
    
    # 清理 Vite 缓存
    if (Test-Path "node_modules/.vite") {
        Remove-Item "node_modules/.vite" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ 清理 Vite 缓存" -ForegroundColor Green
    }
    
    Write-Host "🚀 启动开发服务器..." -ForegroundColor Yellow
    Write-Host "修复完成，正在启动..." -ForegroundColor Cyan
    
    npm run dev
    
} catch {
    Write-Host "[ERROR] 修复失败: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}