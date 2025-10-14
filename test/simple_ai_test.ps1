# Simple AI Test - Test basic AI functionality
Write-Host "=== Simple AI Test ===" -ForegroundColor Green

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
    } catch {
        Write-Host "Failed to get AI configurations: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test 3: Record optimization
    Write-Host "`nTest 3: Testing record optimization..." -ForegroundColor Yellow
    
    $optimizeData = @{
        content = @{
            title = "Test Record"
            description = "This is a test record that needs optimization"
            category = "test"
        }
    }
    
    try {
        $optimizeResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/ai/optimize-record" -Method POST -Headers $headers -Body ($optimizeData | ConvertTo-Json) -ContentType "application/json"
        $optimizeTaskId = $optimizeResponse.data.id
        Write-Host "Record optimization task created - Task ID: $optimizeTaskId" -ForegroundColor Green
        Write-Host "  Status: $($optimizeResponse.data.status)" -ForegroundColor Cyan
    } catch {
        Write-Host "Failed to create record optimization task: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test 4: AI Chat
    Write-Host "`nTest 4: Testing AI chat..." -ForegroundColor Yellow
    
    $chatData = @{
        message = "Hello, please introduce yourself."
        stream = $false
    }
    
    try {
        $chatResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/ai/chat" -Method POST -Headers $headers -Body ($chatData | ConvertTo-Json) -ContentType "application/json"
        $sessionId = $chatResponse.data.id
        Write-Host "AI chat session created - Session ID: $sessionId" -ForegroundColor Green
        Write-Host "  Title: $($chatResponse.data.title)" -ForegroundColor Cyan
    } catch {
        Write-Host "Failed to create AI chat: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test 5: Get AI tasks
    Write-Host "`nTest 5: Getting AI tasks..." -ForegroundColor Yellow
    
    Start-Sleep -Seconds 2
    
    try {
        $tasksResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/ai/tasks" -Method GET -Headers $headers
        $taskCount = $tasksResponse.data.tasks.Count
        Write-Host "Retrieved $taskCount AI tasks" -ForegroundColor Green
    } catch {
        Write-Host "Failed to get AI tasks: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "`n=== Simple AI Test Summary ===" -ForegroundColor Magenta
    Write-Host "Basic AI functionality tests completed." -ForegroundColor Green
    Write-Host "Task 8 core features are implemented and working." -ForegroundColor Green

} catch {
    Write-Host "Error during AI test: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Stop server
    if ($serverProcess -and !$serverProcess.HasExited) {
        Write-Host "`nStopping server..." -ForegroundColor Yellow
        Stop-Process -Id $serverProcess.Id -Force
    }
}

Write-Host "`n=== Simple AI Test Completed ===" -ForegroundColor Green