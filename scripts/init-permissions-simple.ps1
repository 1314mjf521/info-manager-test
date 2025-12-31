#!/usr/bin/env pwsh

Write-Host "=== Initializing Optimized Permission Tree ===" -ForegroundColor Green

# Check database file
$dbPath = "data/info_management.db"
if (-not (Test-Path $dbPath)) {
    Write-Host "Error: Database file not found: $dbPath" -ForegroundColor Red
    Write-Host "Please start the application first to create the database" -ForegroundColor Yellow
    exit 1
}

# Backup database
$backupPath = "data/info_management_backup_permissions_$(Get-Date -Format 'yyyyMMdd_HHmmss').db"
Copy-Item $dbPath $backupPath
Write-Host "Database backed up to: $backupPath" -ForegroundColor Blue

# Execute permission initialization SQL
Write-Host "Initializing permission tree..." -ForegroundColor Yellow

if (Get-Command sqlite3 -ErrorAction SilentlyContinue) {
    try {
        # Execute permission initialization script
        Get-Content "scripts/init-optimized-permissions.sql" | sqlite3 $dbPath
        Write-Host "Permission tree initialization completed" -ForegroundColor Green
        
        # Verify permission count
        $permissionCount = sqlite3 $dbPath "SELECT COUNT(*) FROM permissions;"
        Write-Host "Total permissions: $permissionCount" -ForegroundColor Blue
        
        # Verify root permission count
        $rootPermissionCount = sqlite3 $dbPath "SELECT COUNT(*) FROM permissions WHERE parent_id IS NULL;"
        Write-Host "Root permissions: $rootPermissionCount" -ForegroundColor Blue
        
    } catch {
        Write-Host "Permission initialization failed: $($_.Exception.Message)" -ForegroundColor Red
        
        # Restore backup
        Write-Host "Restoring database backup..." -ForegroundColor Yellow
        Copy-Item $backupPath $dbPath -Force
        Write-Host "Database restored" -ForegroundColor Blue
        exit 1
    }
} else {
    Write-Host "Error: sqlite3 command not found" -ForegroundColor Red
    Write-Host "Please install SQLite3 or execute SQL script manually" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=== Permission Initialization Complete ===" -ForegroundColor Green
Write-Host "Optimizations:" -ForegroundColor White
Write-Host "- 12 main functional modules" -ForegroundColor Green
Write-Host "- Fine-grained permission control" -ForegroundColor Green
Write-Host "- Clear permission tree structure" -ForegroundColor Green
Write-Host "- Complete ticket management permissions" -ForegroundColor Green

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Restart the application to load new permissions" -ForegroundColor White
Write-Host "2. View the optimized permission tree in the permission management page" -ForegroundColor White
Write-Host "3. Assign appropriate permissions to different roles" -ForegroundColor White
Write-Host "4. Test permission control for each functional module" -ForegroundColor White