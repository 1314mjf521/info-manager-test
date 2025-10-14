# Force Clean All Records - English Version
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
        title = "Project Requirements Analysis"
        content = @{
            description = "This is a sample project requirements analysis document"
            priority = "high"
            status = "published"
            sections = @("Requirements Overview", "Functional Requirements", "Non-functional Requirements", "Acceptance Criteria")
        }
        tags = @("project", "requirements", "documentation")
    },
    @{
        type = "study"
        title = "Vue 3 Learning Notes"
        content = @{
            description = "Vue 3 Composition API learning notes"
            topics = @("Reactivity System", "Composition API", "Lifecycle", "Component Communication")
            status = "draft"
            progress = "60%"
        }
        tags = @("learning", "vue3", "frontend")
    },
    @{
        type = "work"
        title = "System Deployment Guide"
        content = @{
            description = "Detailed steps and considerations for production deployment"
            steps = @("Environment Setup", "Code Deployment", "Database Migration", "Service Startup", "Health Check")
            status = "published"
            environment = "production"
        }
        tags = @("deployment", "devops", "production")
    },
    @{
        type = "other"
        title = "Meeting Minutes - Product Planning"
        content = @{
            description = "Q1 2025 product planning meeting minutes"
            date = "2025-01-04"
            participants = @("Product Manager", "Tech Lead", "UI Designer")
            status = "published"
            decisions = @("Define core features", "Create development plan", "Allocate resources")
        }
        tags = @("meeting", "planning", "product")
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
                        "work" { "Work Records" }
                        "study" { "Study Notes" }
                        "other" { "Other" }
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