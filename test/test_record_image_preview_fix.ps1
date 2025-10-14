# 记录管理图片预览修复验证脚本
$BaseUrl = "http://localhost:8080"
$Headers = @{}

Write-Host "=== 记录管理图片预览修复验证 ===" -ForegroundColor Cyan

# 登录
Write-Host "1. 登录测试..." -ForegroundColor Yellow
$loginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($response.success -and $response.data.token) {
        $Headers = @{
            "Authorization" = "Bearer $($response.data.token)"
            "Content-Type" = "application/json"
        }
        Write-Host "✓ 登录成功" -ForegroundColor Green
    } else {
        Write-Host "✗ 登录失败" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ 登录请求失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 测试记录列表API
Write-Host "2. 获取记录列表..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/records" -Method GET -Headers $Headers
    
    if ($response.success) {
        Write-Host "✓ 记录列表获取成功" -ForegroundColor Green
        $records = $response.data
        Write-Host "  记录数量: $($records.Count)" -ForegroundColor Cyan
        
        if ($records.Count -gt 0) {
            $recordWithAttachments = $records | Where-Object { 
                $_.content -and 
                ($_.content.attachments -or $_.content.files -or $_.content.images) 
            } | Select-Object -First 1
            
            if ($recordWithAttachments) {
                Write-Host "  找到包含附件的记录: ID $($recordWithAttachments.id)" -ForegroundColor Cyan
                
                # 测试记录详情API
                Write-Host "3. 获取记录详情..." -ForegroundColor Yellow
                try {
                    $detailResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/records/$($recordWithAttachments.id)" -Method GET -Headers $Headers
                    
                    if ($detailResponse.success) {
                        Write-Host "✓ 记录详情获取成功" -ForegroundColor Green
                        $record = $detailResponse.data
                        
                        # 检查附件信息
                        if ($record.content) {
                            $attachments = $record.content.attachments -or $record.content.files -or $record.content.images -or @()
                            if ($attachments -and $attachments.Count -gt 0) {
                                Write-Host "  附件数量: $($attachments.Count)" -ForegroundColor Cyan
                                
                                foreach ($attachment in $attachments) {
                                    Write-Host "    - 文件: $($attachment.name -or $attachment.filename)" -ForegroundColor White
                                    Write-Host "      ID: $($attachment.id)" -ForegroundColor Gray
                                    Write-Host "      类型: $($attachment.mimeType -or $attachment.type)" -ForegroundColor Gray
                                    
                                    # 测试文件访问
                                    if ($attachment.id) {
                                        Write-Host "4. 测试文件访问..." -ForegroundColor Yellow
                                        try {
                                            $fileUrl = "$BaseUrl/api/v1/files/$($attachment.id)"
                                            $fileResponse = Invoke-WebRequest -Uri $fileUrl -Headers $Headers -Method HEAD
                                            
                                            if ($fileResponse.StatusCode -eq 200) {
                                                Write-Host "✓ 文件访问正常" -ForegroundColor Green
                                                Write-Host "  文件大小: $($fileResponse.Headers.'Content-Length')" -ForegroundColor Cyan
                                                Write-Host "  内容类型: $($fileResponse.Headers.'Content-Type')" -ForegroundColor Cyan
                                            }
                                        } catch {
                                            Write-Host "✗ 文件访问失败: $($_.Exception.Message)" -ForegroundColor Red
                                        }
                                    }
                                }
                            } else {
                                Write-Host "  该记录没有附件" -ForegroundColor Yellow
                            }
                        }
                    } else {
                        Write-Host "✗ 记录详情获取失败: $($detailResponse.message)" -ForegroundColor Red
                    }
                } catch {
                    Write-Host "✗ 记录详情请求失败: $($_.Exception.Message)" -ForegroundColor Red
                }
            } else {
                Write-Host "  没有找到包含附件的记录" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  没有记录数据" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ 记录列表获取失败: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 记录列表请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试文件列表API（用于对比）
Write-Host "5. 测试文件管理API..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/files" -Method GET -Headers $Headers
    
    if ($response.success) {
        Write-Host "✓ 文件列表获取成功" -ForegroundColor Green
        $files = $response.data
        Write-Host "  文件数量: $($files.Count)" -ForegroundColor Cyan
        
        if ($files.Count -gt 0) {
            $imageFile = $files | Where-Object { 
                $_.mimeType -and $_.mimeType.StartsWith('image/') 
            } | Select-Object -First 1
            
            if ($imageFile) {
                Write-Host "  找到图片文件: $($imageFile.name)" -ForegroundColor Cyan
                Write-Host "    文件ID: $($imageFile.id)" -ForegroundColor Gray
                Write-Host "    MIME类型: $($imageFile.mimeType)" -ForegroundColor Gray
                
                # 测试图片文件访问
                try {
                    $imageUrl = "$BaseUrl/api/v1/files/$($imageFile.id)"
                    $imageResponse = Invoke-WebRequest -Uri $imageUrl -Headers $Headers -Method HEAD
                    
                    if ($imageResponse.StatusCode -eq 200) {
                        Write-Host "✓ 图片文件访问正常" -ForegroundColor Green
                    }
                } catch {
                    Write-Host "✗ 图片文件访问失败: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "✗ 文件列表获取失败: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 文件列表请求失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=== 测试完成 ===" -ForegroundColor Green
Write-Host ""
Write-Host "修复说明:" -ForegroundColor Cyan
Write-Host "1. 修复了记录管理组件中SimpleImagePreview组件的图片加载逻辑" -ForegroundColor White
Write-Host "2. 添加了详细的调试日志，便于排查问题" -ForegroundColor White
Write-Host "3. 优化了错误处理和用户反馈" -ForegroundColor White
Write-Host "4. 修复了预览对话框中的变量名不一致问题" -ForegroundColor White
Write-Host "5. 添加了必要的CSS样式确保正确显示" -ForegroundColor White
Write-Host ""
Write-Host "请在浏览器中打开记录详情页面，查看图片预览是否正常工作" -ForegroundColor Yellow