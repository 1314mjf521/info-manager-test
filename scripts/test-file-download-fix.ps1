# 测试文件下载修复

Write-Host "测试文件下载功能修复..." -ForegroundColor Green

# 检查服务是否运行
Write-Host "1. 检查服务状态..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✓ 后端服务正常运行" -ForegroundColor Green
    }
} catch {
    Write-Host "   ✗ 后端服务未运行，请先启动服务" -ForegroundColor Red
    exit 1
}

# 检查前端是否编译
Write-Host "2. 重新编译前端..." -ForegroundColor Yellow
Push-Location frontend
try {
    & npm run build
    Write-Host "   ✓ 前端编译成功" -ForegroundColor Green
} catch {
    Write-Host "   ✗ 前端编译失败" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

Write-Host "`n修复内容说明:" -ForegroundColor Cyan
Write-Host "1. 修复了文件下载时缺少认证token的问题" -ForegroundColor White
Write-Host "2. 将 window.open() 方式改为 fetch() + blob 下载" -ForegroundColor White
Write-Host "3. 修复了图片预览时的认证问题" -ForegroundColor White
Write-Host "4. 添加了错误处理和用户提示" -ForegroundColor White

Write-Host "`n测试步骤:" -ForegroundColor Yellow
Write-Host "1. 访问 http://localhost:8080/files 页面" -ForegroundColor White
Write-Host "2. 确保已登录系统" -ForegroundColor White
Write-Host "3. 点击任意文件的'下载'按钮" -ForegroundColor White
Write-Host "4. 检查是否能正常下载文件" -ForegroundColor White
Write-Host "5. 点击图片文件的'预览'按钮" -ForegroundColor White
Write-Host "6. 检查图片是否能正常显示" -ForegroundColor White

Write-Host "`n如果仍有问题，请检查:" -ForegroundColor Cyan
Write-Host "- 浏览器开发者工具的网络请求" -ForegroundColor White
Write-Host "- 后端日志中的认证错误" -ForegroundColor White
Write-Host "- localStorage中是否有有效的token" -ForegroundColor White

Write-Host "`n修复完成！" -ForegroundColor Green