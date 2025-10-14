# Clean Vite HMR Logs from Records
Write-Host "=== Cleaning Vite HMR Logs from Records ===" -ForegroundColor Green

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

# Get records to find the problematic one
Write-Host "`n2. Finding records with Vite HMR logs..." -ForegroundColor Yellow
$headers = @{
    "Authorization" = "Bearer $token"
}

try {
    $records = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    
    $problematicRecords = @()
    foreach ($record in $records.data.records) {
        $contentStr = $record.content | ConvertTo-Json -Depth 10
        if ($contentStr -like "*vite*hmr*" -or $contentStr -like "*[vite]*") {
            $problematicRecords += $record
            Write-Host "Found problematic record ID: $($record.id) - $($record.title)" -ForegroundColor Red
        }
    }
    
    if ($problematicRecords.Count -eq 0) {
        Write-Host "No records with Vite HMR logs found" -ForegroundColor Green
        exit 0
    }
    
    Write-Host "Found $($problematicRecords.Count) problematic record(s)" -ForegroundColor Yellow
    
} catch {
    Write-Host "Failed to get records: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Clean each problematic record
Write-Host "`n3. Cleaning problematic records..." -ForegroundColor Yellow

foreach ($record in $problematicRecords) {
    Write-Host "Cleaning record ID: $($record.id)" -ForegroundColor Cyan
    
    try {
        # Create clean content
        $cleanContent = @{
            description = "This record has been cleaned from Vite HMR logs"
            originalTitle = $record.title
            cleanedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            status = "published"
        }
        
        $updateData = @{
            title = "Cleaned: $($record.title)"
            content = $cleanContent
            tags = @("cleaned", "system-maintenance")
        } | ConvertTo-Json -Depth 10
        
        $updateResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records/$($record.id)" -Method PUT -Body $updateData -ContentType "application/json" -Headers $headers
        
        if ($updateResponse.success) {
            Write-Host "Successfully cleaned record ID: $($record.id)" -ForegroundColor Green
        } else {
            Write-Host "Failed to clean record ID: $($record.id)" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "Error cleaning record ID $($record.id): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Verify the cleanup
Write-Host "`n4. Verifying cleanup..." -ForegroundColor Yellow
try {
    $verifyRecords = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/records" -Method GET -Headers $headers
    
    $stillProblematic = 0
    foreach ($record in $verifyRecords.data.records) {
        $contentStr = $record.content | ConvertTo-Json -Depth 10
        if ($contentStr -like "*vite*hmr*" -or $contentStr -like "*[vite]*") {
            $stillProblematic++
        }
    }
    
    if ($stillProblematic -eq 0) {
        Write-Host "All Vite HMR logs have been cleaned successfully!" -ForegroundColor Green
    } else {
        Write-Host "Warning: $stillProblematic record(s) still contain Vite HMR logs" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Failed to verify cleanup: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Cleanup Complete ===" -ForegroundColor Green