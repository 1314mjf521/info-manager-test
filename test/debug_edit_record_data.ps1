# Debug Edit Record Data Structure
Write-Host "=== 调试编辑记录数据结构 ===" -ForegroundColor Green

Write-Host "`n🔍 这个脚本将帮助我们了解记录数据的确切结构" -ForegroundColor Yellow

# Login first
Write-Host "`n1. 登录系统..." -ForegroundColor Yellow
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    Write-Host "✅ 登录成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
}

# Get records list
Write-Host "`n2. 获取记录列表..." -ForegroundColor Yellow
try {
    $recordsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    
    if ($recordsResponse.success -and $recordsResponse.data.records) {
        $records = $recordsResponse.data.records
        Write-Host "✅ 找到 $($records.Count) 条记录" -ForegroundColor Green
        
        # Find records with attachments
        $recordsWithAttachments = @()
        foreach ($record in $records) {
            $hasAttachments = $false
            $attachmentInfo = ""
            
            # Check different possible locations for attachments
            if ($record.content) {
                if ($record.content.attachments -and $record.content.attachments.Count -gt 0) {
                    $hasAttachments = $true
                    $attachmentInfo += "content.attachments: $($record.content.attachments.Count) files; "
                }
                if ($record.content.files -and $record.content.files.Count -gt 0) {
                    $hasAttachments = $true
                    $attachmentInfo += "content.files: $($record.content.files.Count) files; "
                }
            }
            if ($record.files -and $record.files.Count -gt 0) {
                $hasAttachments = $true
                $attachmentInfo += "files: $($record.files.Count) files; "
            }
            
            if ($hasAttachments) {
                $recordsWithAttachments += @{
                    id = $record.id
                    title = $record.title
                    attachmentInfo = $attachmentInfo
                    record = $record
                }
            }
        }
        
        if ($recordsWithAttachments.Count -gt 0) {
            Write-Host "`n📎 找到 $($recordsWithAttachments.Count) 条包含附件的记录:" -ForegroundColor Cyan
            
            foreach ($recordInfo in $recordsWithAttachments) {
                Write-Host "  - ID: $($recordInfo.id), 标题: $($recordInfo.title)" -ForegroundColor White
                Write-Host "    附件位置: $($recordInfo.attachmentInfo)" -ForegroundColor Gray
            }
            
            # Get detailed info for the first record with attachments
            $testRecord = $recordsWithAttachments[0]
            Write-Host "`n3. 获取记录 ID $($testRecord.id) 的详细信息..." -ForegroundColor Yellow
            
            try {
                $detailResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records/$($testRecord.id)" -Method GET -Headers $headers
                
                Write-Host "✅ 记录详情获取成功" -ForegroundColor Green
                Write-Host "`n📋 完整记录数据结构:" -ForegroundColor Cyan
                Write-Host ($detailResponse | ConvertTo-Json -Depth 10) -ForegroundColor Gray
                
                # Analyze attachment structure
                Write-Host "`n🔍 附件数据分析:" -ForegroundColor Yellow
                
                if ($detailResponse.success -and $detailResponse.data) {
                    $recordData = $detailResponse.data
                } elseif ($detailResponse.id) {
                    $recordData = $detailResponse
                } else {
                    Write-Host "❌ 无法解析记录数据" -ForegroundColor Red
                    exit 1
                }
                
                Write-Host "记录ID: $($recordData.id)" -ForegroundColor White
                Write-Host "标题: $($recordData.title)" -ForegroundColor White
                
                if ($recordData.content) {
                    Write-Host "content 字段存在" -ForegroundColor Green
                    
                    if ($recordData.content.attachments) {
                        Write-Host "✅ content.attachments 存在，包含 $($recordData.content.attachments.Count) 个文件:" -ForegroundColor Green
                        foreach ($attachment in $recordData.content.attachments) {
                            Write-Host "  - ID: $($attachment.id), 名称: $($attachment.name), URL: $($attachment.url)" -ForegroundColor Gray
                        }
                    } else {
                        Write-Host "❌ content.attachments 不存在" -ForegroundColor Red
                    }
                    
                    if ($recordData.content.files) {
                        Write-Host "✅ content.files 存在，包含 $($recordData.content.files.Count) 个文件:" -ForegroundColor Green
                        foreach ($file in $recordData.content.files) {
                            Write-Host "  - ID: $($file.id), 名称: $($file.name), URL: $($file.url)" -ForegroundColor Gray
                        }
                    } else {
                        Write-Host "❌ content.files 不存在" -ForegroundColor Red
                    }
                } else {
                    Write-Host "❌ content 字段不存在" -ForegroundColor Red
                }
                
                if ($recordData.files) {
                    Write-Host "✅ files 字段存在，包含 $($recordData.files.Count) 个文件:" -ForegroundColor Green
                    foreach ($file in $recordData.files) {
                        Write-Host "  - ID: $($file.id), 名称: $($file.name), URL: $($file.url)" -ForegroundColor Gray
                    }
                } else {
                    Write-Host "❌ files 字段不存在" -ForegroundColor Red
                }
                
            } catch {
                Write-Host "❌ 获取记录详情失败: $($_.Exception.Message)" -ForegroundColor Red
            }
            
        } else {
            Write-Host "`n❌ 没有找到包含附件的记录" -ForegroundColor Red
            Write-Host "请先运行 .\test\update_record_with_attachments.ps1 创建测试数据" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "❌ 没有找到记录" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ 获取记录列表失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== 调试完成 ===" -ForegroundColor Green
Write-Host "请查看上面的输出，了解附件数据的确切结构" -ForegroundColor Cyan