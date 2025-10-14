# Force Clean All Records
Write-Host "=== Force Cleaning All Records ===" -ForegroundColor Green

# Login to get token
Write-Host "`n1. Logging in..." -ForegroundColor Yellow
try {
    $loginData = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.token
    Write-Host "Login successful" -ForegroundColor Green
} catch {
    Write-Host "Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
}

# Delete all existing records and create clean demo records
Write-Host "`n2. Getting all records..." -ForegroundColor Yellow
try {
    $records = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    
    Write-Host "Found $($records.data.records.Count) records to clean" -ForegroundColor Cyan
    
    # Delete all existing records
    Write-Host "`n3. Deleting all existing records..." -ForegroundColor Yellow
    foreach ($record in $records.data.records) {
        try {
            $deleteResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records/$($record.id)" -Method DELETE -Headers $headers
            Write-Host "Deleted record ID: $($record.id)" -ForegroundColor Green
        } catch {
            Write-Host "Failed to delete record ID: $($record.id) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "Failed to get records: $($_.Exception.Message)" -ForegroundColor Red
}

# Create clean demo records
Write-Host "`n4. Creating clean demo records..." -ForegroundColor Yellow

$demoRecords = @(
    @{
        type = "work"
        title = "项目需求分析文档"
        content = @{
            description = "这是一个项目需求分析文档的示例"
            priority = "high"
            status = "published"
            sections = @("需求概述", "功能需求", "非功能需求", "验收标准")
        }
        tags = @("项目", "需求", "文档")
    },
    @{
        type = "study"
        title = "Vue 3 学习笔记"
        content = @{
            description = "Vue 3 Composition API 学习笔记"
            topics = @("响应式系统", "组合式API", "生命周期", "组件通信")
            status = "draft"
            progress = "60%"
        }
        tags = @("学习", "Vue3", "前端")
    },
    @{
        type = "work"
        title = "系统部署指南"
        content = @{
            description = "生产环境部署的详细步骤和注意事项"
            steps = @("环境准备", "代码部署", "数据库迁移", "服务启动", "健康检查")
            status = "published"
            environment = "production"
        }
        tags = @("部署", "运维", "生产")
    },
    @{
        type = "other"
        title = "会议纪要 - 产品规划"
        content = @{
            description = "2025年第一季度产品规划会议纪要"
            date = "2025-01-04"
            participants = @("产品经理", "技术负责人", "UI设计师")
            status = "published"
            decisions = @("确定核心功能", "制定开发计划", "分配资源")
        }
        tags = @("会议", "规划", "产品")
    }
)

foreach ($demoRecord in $demoRecords) {
    try {
        $createData = $demoRecord | ConvertTo-Json -Depth 10
        $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Body $createData -ContentType "application/json" -Headers $headers
        
        if ($createResponse.success) {
            Write-Host "Created demo record: $($demoRecord.title)" -ForegroundColor Green
        } else {
            Write-Host "Failed to create demo record: $($demoRecord.title)" -ForegroundColor Red
        }
    } catch {
        Write-Host "Error creating demo record '$($demoRecord.title)': $($_.Exception.Message)" -ForegroundColor Red
        
        # If record type doesn't exist, try to create it
        if ($_.Exception.Response.StatusCode -eq 400) {
            Write-Host "Attempting to create record type: $($demoRecord.type)" -ForegroundColor Yellow
            try {
                $typeData = @{
                    name = $demoRecord.type
                    display_name = switch ($demoRecord.type) {
                        "work" { "工作记录" }
                        "study" { "学习笔记" }
                        "other" { "其他" }
                        default { $demoRecord.type }
                    }
                    schema = @{
                        fields = @(
                            @{ name = "description"; type = "text"; required = $true },
                            @{ name = "status"; type = "select"; options = @("draft", "published", "archived") }
                        )
                    }
                } | ConvertTo-Json -Depth 10
                
                $typeResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/record-types" -Method POST -Body $typeData -ContentType "application/json" -Headers $headers
                Write-Host "Created record type: $($demoRecord.type)" -ForegroundColor Green
                
                # Retry creating the record
                $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method POST -Body $createData -ContentType "application/json" -Headers $headers
                Write-Host "Created demo record: $($demoRecord.title)" -ForegroundColor Green
                
            } catch {
                Write-Host "Failed to create record type: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# Verify the results
Write-Host "`n5. Verifying results..." -ForegroundColor Yellow
try {
    $finalRecords = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    
    Write-Host "Final record count: $($finalRecords.data.records.Count)" -ForegroundColor Cyan
    
    $hasViteLogs = $false
    foreach ($record in $finalRecords.data.records) {
        Write-Host "Record: $($record.title) (Type: $($record.type))" -ForegroundColor White
        
        $contentStr = $record.content | ConvertTo-Json -Depth 10
        if ($contentStr -like "*vite*hmr*" -or $contentStr -like "*[vite]*") {
            Write-Host "  WARNING: Still contains Vite logs" -ForegroundColor Red
            $hasViteLogs = $true
        } else {
            Write-Host "  Clean content" -ForegroundColor Green
        }
    }
    
    if (-not $hasViteLogs) {
        Write-Host "`nSUCCESS: All records are now clean!" -ForegroundColor Green
    } else {
        Write-Host "`nWARNING: Some records still contain Vite logs" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Failed to verify results: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Force Cleanup Complete ===" -ForegroundColor Green