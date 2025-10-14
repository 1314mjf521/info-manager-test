# PDF Encoding Fix Test - 专门测试PDF导出乱码修复
Write-Host "=== PDF编码修复测试 ===" -ForegroundColor Green

# 启动服务器
Write-Host "启动服务器..." -ForegroundColor Yellow
$serverProcess = Start-Process -FilePath ".\build\server.exe" -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 3

try {
    # 登录
    $loginData = @{ username = "admin"; password = "admin123" }
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
    $token = $loginResponse.data.token
    $headers = @{ "Authorization" = "Bearer $token" }

    Write-Host "登录成功" -ForegroundColor Green

    # 创建包含中文的测试数据
    Write-Host "`n创建包含中文的PDF导出任务..." -ForegroundColor Yellow
    
    $exportData = @{
        task_name = "PDF中文编码测试"
        format = "pdf"
        fields = @("id", "title", "content", "created_at")
        config = @{
            include_headers = $true
            encoding = "utf-8"
        }
    }
    
    $exportResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/records" -Method POST -Headers $headers -Body ($exportData | ConvertTo-Json) -ContentType "application/json"
    $taskId = $exportResponse.data.task_id
    
    Write-Host "PDF导出任务已创建 - 任务ID: $taskId" -ForegroundColor Green

    # 等待任务完成
    Write-Host "`n等待PDF导出任务完成..." -ForegroundColor Yellow
    $maxWaitTime = 30
    $waitTime = 0
    $taskCompleted = $false

    while ($waitTime -lt $maxWaitTime -and -not $taskCompleted) {
        Start-Sleep -Seconds 2
        $waitTime += 2
        
        try {
            $taskResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/tasks/$taskId" -Method GET -Headers $headers
            $status = $taskResponse.data.status
            $progress = $taskResponse.data.progress
            
            Write-Host "  任务状态: $status ($progress%)" -ForegroundColor Cyan
            
            if ($status -eq "completed") {
                $taskCompleted = $true
                Write-Host "  PDF导出任务完成!" -ForegroundColor Green
            } elseif ($status -eq "failed") {
                $errorMessage = $taskResponse.data.error_message
                Write-Host "  PDF导出任务失败: $errorMessage" -ForegroundColor Red
                break
            }
        } catch {
            Write-Host "  获取任务状态失败: $($_.Exception.Message)" -ForegroundColor Red
            break
        }
    }

    if ($taskCompleted) {
        # 获取生成的PDF文件
        Write-Host "`n获取生成的PDF文件..." -ForegroundColor Yellow
        
        $filesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/export/files" -Method GET -Headers $headers
        $pdfFiles = $filesResponse.data.files | Where-Object { $_.format -eq "pdf" } | Sort-Object created_at -Descending
        
        if ($pdfFiles.Count -gt 0) {
            $latestPdfFile = $pdfFiles[0]
            $fileName = $latestPdfFile.file_name
            $fileSize = $latestPdfFile.file_size
            
            Write-Host "找到最新的PDF文件: $fileName ($fileSize 字节)" -ForegroundColor Green
            
            # 测试下载PDF文件
            Write-Host "`n测试下载PDF文件..." -ForegroundColor Yellow
            try {
                $downloadPath = "test\downloaded_pdf_test.pdf"
                $downloadResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/export/files/$($latestPdfFile.id)/download" -Method GET -Headers $headers -OutFile $downloadPath
                
                if (Test-Path $downloadPath) {
                    $downloadedSize = (Get-Item $downloadPath).Length
                    Write-Host "PDF文件下载成功: $downloadPath ($downloadedSize 字节)" -ForegroundColor Green
                    
                    # 检查PDF文件内容
                    Write-Host "`n检查PDF文件内容..." -ForegroundColor Yellow
                    $pdfContent = Get-Content $downloadPath -Raw -Encoding UTF8
                    
                    if ($pdfContent -match "%PDF") {
                        Write-Host "✓ PDF文件格式正确" -ForegroundColor Green
                    } else {
                        Write-Host "✗ PDF文件格式可能有问题" -ForegroundColor Red
                    }
                    
                    if ($pdfContent -match "数据导出报告") {
                        Write-Host "✓ PDF包含中文标题" -ForegroundColor Green
                    } else {
                        Write-Host "✗ PDF可能不包含正确的中文内容" -ForegroundColor Red
                    }
                    
                    # 文件大小检查
                    if ($downloadedSize -gt 500) {
                        Write-Host "✓ PDF文件大小合理 ($downloadedSize 字节)" -ForegroundColor Green
                    } else {
                        Write-Host "⚠ PDF文件可能过小 ($downloadedSize 字节)" -ForegroundColor Yellow
                    }
                    
                } else {
                    Write-Host "PDF文件下载失败" -ForegroundColor Red
                }
            } catch {
                Write-Host "下载PDF文件时出错: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "未找到PDF文件" -ForegroundColor Red
        }
    } else {
        Write-Host "PDF导出任务未在预期时间内完成" -ForegroundColor Yellow
    }

    # 生成测试报告
    Write-Host "`n=== PDF编码修复测试报告 ===" -ForegroundColor Magenta
    Write-Host "测试目标: 修复PDF导出中文乱码问题" -ForegroundColor White
    Write-Host "修复方案: 改进PDF生成算法，正确处理UTF-8编码" -ForegroundColor White
    
    if ($taskCompleted) {
        Write-Host "测试结果: PDF导出任务成功完成" -ForegroundColor Green
        Write-Host "建议: 请手动打开下载的PDF文件验证中文显示是否正常" -ForegroundColor Yellow
    } else {
        Write-Host "测试结果: PDF导出任务未成功完成" -ForegroundColor Red
        Write-Host "建议: 检查服务器日志以获取详细错误信息" -ForegroundColor Yellow
    }

} catch {
    Write-Host "测试过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # 停止服务器
    if ($serverProcess -and !$serverProcess.HasExited) {
        Write-Host "`n停止服务器..." -ForegroundColor Yellow
        Stop-Process -Id $serverProcess.Id -Force
    }
}

Write-Host "`n=== PDF编码修复测试完成 ===" -ForegroundColor Green