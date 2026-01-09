# 重新编译前端并测试文件下载修复

Write-Host "重新编译前端并测试文件下载修复..." -ForegroundColor Green

# 1. 重新编译前端
Write-Host "`n1. 重新编译前端..." -ForegroundColor Yellow
Push-Location frontend

try {
    Write-Host "   清理旧的构建文件..." -ForegroundColor Gray
    if (Test-Path "dist") {
        Remove-Item -Recurse -Force "dist"
    }
    
    Write-Host "   开始编译..." -ForegroundColor Gray
    & npm run build
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ 前端编译成功" -ForegroundColor Green
    } else {
        Write-Host "   ✗ 前端编译失败" -ForegroundColor Red
        Pop-Location
        exit 1
    }
} catch {
    Write-Host "   ✗ 编译过程中出现错误: $($_.Exception.Message)" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

# 2. 检查后端服务状态
Write-Host "`n2. 检查后端服务状态..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✓ 后端服务正常运行" -ForegroundColor Green
    }
} catch {
    Write-Host "   ✗ 后端服务未运行" -ForegroundColor Red
    Write-Host "   正在启动后端服务..." -ForegroundColor Yellow
    
    # 尝试启动后端服务
    try {
        $process = Start-Process -FilePath ".\info-management-system.exe" -PassThru -WindowStyle Hidden
        Write-Host "   ✓ 后端服务启动成功 (PID: $($process.Id))" -ForegroundColor Green
        
        # 等待服务启动
        Write-Host "   等待服务完全启动..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
        
        # 再次检查
        $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "   ✓ 后端服务启动完成" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ✗ 无法启动后端服务" -ForegroundColor Red
        Write-Host "   请手动运行: .\info-management-system.exe" -ForegroundColor Yellow
    }
}

# 3. 显示修复内容
Write-Host "`n3. 文件下载修复内容:" -ForegroundColor Cyan
Write-Host "   ✓ 修复了FileListView.vue中的下载按钮" -ForegroundColor Green
Write-Host "   ✓ 使用fetch API替代window.open" -ForegroundColor Green
Write-Host "   ✓ 正确传递Authorization头" -ForegroundColor Green
Write-Host "   ✓ 修复了图片预览功能" -ForegroundColor Green
Write-Host "   ✓ 添加了完善的错误处理" -ForegroundColor Green

# 4. 测试建议
Write-Host "`n4. 测试步骤:" -ForegroundColor Yellow
Write-Host "   1. 访问: http://localhost:8080/files" -ForegroundColor White
Write-Host "   2. 确保已登录系统" -ForegroundColor White
Write-Host "   3. 点击任意文件的'下载'按钮" -ForegroundColor White
Write-Host "   4. 检查文件是否正常下载" -ForegroundColor White
Write-Host "   5. 点击图片文件的'预览'按钮" -ForegroundColor White
Write-Host "   6. 检查图片是否正常显示" -ForegroundColor White

# 5. 故障排除
Write-Host "`n5. 如果仍有问题:" -ForegroundColor Cyan
Write-Host "   - 打开浏览器开发者工具 (F12)" -ForegroundColor White
Write-Host "   - 查看Network标签页的请求" -ForegroundColor White
Write-Host "   - 检查Console标签页的错误信息" -ForegroundColor White
Write-Host "   - 确认localStorage中有token: localStorage.getItem('token')" -ForegroundColor White
Write-Host "   - 查看后端日志文件" -ForegroundColor White

# 6. 自动测试选项
Write-Host "`n6. 自动API测试:" -ForegroundColor Yellow
$runApiTest = Read-Host "是否运行自动API测试? (y/N)"
if ($runApiTest -eq 'y' -or $runApiTest -eq 'Y') {
    $token = Read-Host "请输入认证Token (或按Enter跳过)"
    if ($token) {
        Write-Host "   运行API测试..." -ForegroundColor Gray
        & .\scripts\complete-file-download-test.ps1 -Token $token
    } else {
        Write-Host "   跳过API测试" -ForegroundColor Gray
    }
}

Write-Host "`n修复和编译完成！" -ForegroundColor Green
Write-Host "现在可以测试文件下载功能了。" -ForegroundColor Cyan