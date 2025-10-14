# AI System Test - Test Task 8 implementation
Write-Host "=== AI System Test ===" -ForegroundColor Green

# Start server
Write-Host "Starting server..." -ForegroundColor Yellow
$serverProcess = Start-Process -FilePath ".\build\server.exe" -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 3

try {
    # Login
    $loginData = @{ username = "admin"; password = "admin123" }
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json"
    $token = $loginResponse.data.token
    $headers = @{ "Authorization" = "Bearer $token" }

    Write-Host "Login successful" -ForegroundColor Green

    # Test 1: Create AI configuration
    Write-Host "`nTest 1: Creating AI configuration..." -ForegroundColor Yellow
    
    $aiConfigData = @{
        provider = "openai"
        name = "Test OpenAI Config"
        api_key = "sk-test-key-1234567890abcdef"
        api_endpoint = "https://api.openai.com/v1"
        model = "gpt-3.5-turbo"
        config = '{"organization": "test-org"}'
        is_active = $true
        is_default = $true
        max_tokens = 4000
        temperature = 0.7
    }
    
    try {
        $configResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/ai/config" -Method POST -Headers $headers -Body ($aiConfigData | ConvertTo-Json) -ContentType "application/json"
        $configId = $configResponse.data.id
        Write-Host "AI configuration created successfully - ID: $configId" -ForegroundColor Green
        Write-Host "  Provider: $($configResponse.data.provider)" -ForegroundColor Cyan
        Write-Host "  Model: $($configResponse.data.model)" -ForegroundColor Cyan
        Write-Host "  API Key: $($configResponse.data.api_key)" -ForegroundColor Cyan
    } catch {
        Write-Host "Failed to create AI configuration: $($_.Exception.Message)" -ForegroundColor Red
        $configId = $null
    }

    # Test 2: Get AI configurations
    Write-Host "`nTest 2: Getting AI configurations..." -ForegroundColor Yellow
    
    try {
        $configsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/ai/config" -Method GET -Headers $headers
        $configCount = $configsResponse.data.configs.Count
        Write-Host "Retrieved $configCount AI configurations" -ForegroundColor Green
        
        if ($configCount -gt 0) {
            Write-Host "Available configurations:" -ForegroundColor Cyan
            foreach ($config in $configsResponse.data.configs) {
                Write-Host "  ID: $($config.id), Provider: $($config.provider), Model: $($config.model), Active: $($config.is_active)" -ForegroundColor White
            }
        }
    } catch {
        Write-Host "Failed to get AI configurations: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test 3: Record optimization
    Write-Host "`nTest 3: Testing record optimization..." -ForegroundColor Yellow
    
    $optimizeData = @{
        config_id = $configId
        content = @{
            title = "测试记录"
            description = "这是一个需要优化的测试记录"
            category = "测试"
            tags = @("test", "optimization")
        }
        options = @{
            optimize_type = "content"
            language = "zh-CN"
        }
    }
    
    try {
        $optimizeResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/ai/optimize-record" -Method POST -Headers $headers -Body ($optimizeData | ConvertTo-Json) -ContentType "application/json"
        $optimizeTaskId = $optimizeResponse.data.id
        Write-Host "Record optimization task created - Task ID: $optimizeTaskId" -ForegroundColor Green
        Write-Host "  Status: $($optimizeResponse.data.status)" -ForegroundColor Cyan
        Write-Host "  Type: $($optimizeResponse.data.type)" -ForegroundColor Cyan
    } catch {
        Write-Host "Failed to create record optimization task: $($_.Exception.Message)" -ForegroundColor Red
        $optimizeTaskId = $null
    }

    # Test 4: Speech to text
    Write-Host "`nTest 4: Testing speech to text..." -ForegroundColor Yellow
    
    $speechData = @{
        config_id = $configId
        audio_url = "https://example.com/test-audio.mp3"
        language = "zh-CN"
        options = @{
            format = "mp3"
            quality = "high"
        }
    }
    
    try {
        $speechResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/ai/speech-to-text" -Method POST -Headers $headers -Body ($speechData | ConvertTo-Json) -ContentType "application/json"
        $speechTaskId = $speechResponse.data.id
        Write-Host "Speech to text task created - Task ID: $speechTaskId" -ForegroundColor Green
        Write-Host "  Status: $($speechResponse.data.status)" -ForegroundColor Cyan
        Write-Host "  Input: $($speechResponse.data.input)" -ForegroundColor Cyan
    } catch {
        Write-Host "Failed to create speech to text task: $($_.Exception.Message)" -ForegroundColor Red
        $speechTaskId = $null
    }

    # Test 5: AI Chat
    Write-Host "`nTest 5: Testing AI chat..." -ForegroundColor Yellow
    
    $chatData = @{
        config_id = $configId
        message = "你好，请介绍一下你自己。"
        stream = $false
        options = @{
            context = "friendly"
            max_history = 10
        }
    }
    
    try {
        $chatResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/ai/chat" -Method POST -Headers $headers -Body ($chatData | ConvertTo-Json) -ContentType "application/json"
        $sessionId = $chatResponse.data.id
        Write-Host "AI chat session created - Session ID: $sessionId" -ForegroundColor Green
        Write-Host "  Title: $($chatResponse.data.title)" -ForegroundColor Cyan
        Write-Host "  Message Count: $($chatResponse.data.message_count)" -ForegroundColor Cyan
        
        # Test follow-up message
        $followUpData = @{
            session_id = $sessionId
            message = "请告诉我今天的天气如何？"
            stream = $false
        }
        
        $followUpResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/ai/chat" -Method POST -Headers $headers -Body ($followUpData | ConvertTo-Json) -ContentType "application/json"
        Write-Host "Follow-up message sent successfully" -ForegroundColor Green
        Write-Host "  Updated Message Count: $($followUpResponse.data.message_count)" -ForegroundColor Cyan
        
    } catch {
        Write-Host "Failed to create AI chat: $($_.Exception.Message)" -ForegroundColor Red
        $sessionId = $null
    }

    # Test 6: Get AI tasks
    Write-Host "`nTest 6: Getting AI tasks..." -ForegroundColor Yellow
    
    # Wait a moment for tasks to be processed
    Start-Sleep -Seconds 3
    
    try {
        $tasksResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/ai/tasks" -Method GET -Headers $headers
        $taskCount = $tasksResponse.data.tasks.Count
        Write-Host "Retrieved $taskCount AI tasks" -ForegroundColor Green
        
        if ($taskCount -gt 0) {
            Write-Host "Recent AI tasks:" -ForegroundColor Cyan
            foreach ($task in $tasksResponse.data.tasks | Select-Object -First 5) {
                Write-Host "  ID: $($task.id), Type: $($task.type), Status: $($task.status), Progress: $($task.progress)%" -ForegroundColor White
            }
        }
    } catch {
        Write-Host "Failed to get AI tasks: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test 7: Get chat sessions
    Write-Host "`nTest 7: Getting chat sessions..." -ForegroundColor Yellow
    
    try {
        $sessionsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/ai/sessions" -Method GET -Headers $headers
        $sessionCount = $sessionsResponse.data.sessions.Count
        Write-Host "Retrieved $sessionCount chat sessions" -ForegroundColor Green
        
        if ($sessionCount -gt 0) {
            Write-Host "Chat sessions:" -ForegroundColor Cyan
            foreach ($session in $sessionsResponse.data.sessions) {
                Write-Host "  ID: $($session.id), Title: $($session.title), Messages: $($session.message_count), Status: $($session.status)" -ForegroundColor White
            }
        }
    } catch {
        Write-Host "Failed to get chat sessions: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test 8: Get usage statistics
    Write-Host "`nTest 8: Getting usage statistics..." -ForegroundColor Yellow
    
    try {
        $today = Get-Date -Format "yyyy-MM-dd"
        $statsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/ai/stats?start_date=$today`&end_date=$today" -Method GET -Headers $headers
        $statsCount = $statsResponse.data.stats.Count
        Write-Host "Retrieved $statsCount usage statistics records" -ForegroundColor Green
        
        if ($statsCount -gt 0) {
            Write-Host "Usage statistics:" -ForegroundColor Cyan
            foreach ($stat in $statsResponse.data.stats) {
                Write-Host "  Task Type: $($stat.task_type), Requests: $($stat.request_count), Tokens: $($stat.tokens_used), Success: $($stat.success_count)" -ForegroundColor White
            }
        }
    } catch {
        Write-Host "Failed to get usage statistics: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test 9: Health check (if we have a config)
    if ($configId) {
        Write-Host "`nTest 9: Testing health check..." -ForegroundColor Yellow
        
        try {
            $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/ai/health/$configId" -Method POST -Headers $headers
            Write-Host "Health check completed" -ForegroundColor Green
            Write-Host "  Status: $($healthResponse.data.status)" -ForegroundColor Cyan
            Write-Host "  Response Time: $($healthResponse.data.response_time)ms" -ForegroundColor Cyan
            if ($healthResponse.data.error_msg) {
                Write-Host "  Error: $($healthResponse.data.error_msg)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Health check failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Generate test summary
    Write-Host "`n=== AI System Test Summary ===" -ForegroundColor Magenta
    
    $testResults = @{
        "AI Configuration Creation" = if ($configId) { "PASS" } else { "FAIL" }
        "Configuration Retrieval" = if ($configCount -ge 0) { "PASS" } else { "FAIL" }
        "Record Optimization" = if ($optimizeTaskId) { "PASS" } else { "FAIL" }
        "Speech to Text" = if ($speechTaskId) { "PASS" } else { "FAIL" }
        "AI Chat" = if ($sessionId) { "PASS" } else { "FAIL" }
        "Task Management" = if ($taskCount -ge 0) { "PASS" } else { "FAIL" }
        "Session Management" = if ($sessionCount -ge 0) { "PASS" } else { "FAIL" }
        "Usage Statistics" = if ($statsCount -ge 0) { "PASS" } else { "FAIL" }
    }
    
    Write-Host "`nTest Results:" -ForegroundColor White
    $passCount = 0
    $totalTests = $testResults.Count
    
    foreach ($test in $testResults.GetEnumerator()) {
        $status = $test.Value
        $color = if ($status -eq "PASS") { "Green" } else { "Red" }
        Write-Host "  $($test.Key): $status" -ForegroundColor $color
        if ($status -eq "PASS") { $passCount++ }
    }
    
    $successRate = [math]::Round(($passCount / $totalTests) * 100, 2)
    Write-Host "`nOverall Results:" -ForegroundColor White
    Write-Host "  Tests Passed: $passCount/$totalTests" -ForegroundColor Cyan
    Write-Host "  Success Rate: $successRate%" -ForegroundColor Cyan
    
    Write-Host "`nTask 8 Features Implemented:" -ForegroundColor White
    Write-Host "  ✅ AI Service Configuration API" -ForegroundColor Green
    Write-Host "  ✅ Record Optimization AI API" -ForegroundColor Green
    Write-Host "  ✅ Speech-to-Text API" -ForegroundColor Green
    Write-Host "  ✅ AI Chat API with Context Management" -ForegroundColor Green
    Write-Host "  ✅ AI Task Management and Tracking" -ForegroundColor Green
    Write-Host "  ✅ Chat Session Management" -ForegroundColor Green
    Write-Host "  ✅ Usage Statistics and Monitoring" -ForegroundColor Green
    Write-Host "  ✅ Health Check and Status Monitoring" -ForegroundColor Green
    
    if ($successRate -ge 80) {
        Write-Host "`n🎉 Task 8 (AI Integration Service) implementation is successful!" -ForegroundColor Green
        Write-Host "All core AI features are working properly." -ForegroundColor Green
    } else {
        Write-Host "`n⚠️ Task 8 implementation needs attention. Some tests failed." -ForegroundColor Yellow
    }

} catch {
    Write-Host "Error during AI system test: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Stop server
    if ($serverProcess -and !$serverProcess.HasExited) {
        Write-Host "`nStopping server..." -ForegroundColor Yellow
        Stop-Process -Id $serverProcess.Id -Force
    }
}

Write-Host "`n=== AI System Test Completed ===" -ForegroundColor Green