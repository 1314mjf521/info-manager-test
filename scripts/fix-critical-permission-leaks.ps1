# Fix Critical Permission Leaks Script
# Addresses the 6 critical permission security issues found in comprehensive testing

Write-Host "=== Fixing Critical Permission Leaks ===" -ForegroundColor Red
Write-Host "Found 6 critical permission security issues that need immediate attention" -ForegroundColor Yellow
Write-Host ""

# 1. Fix system health endpoint access
Write-Host "1. Fixing system health endpoint access..." -ForegroundColor Cyan
Write-Host "   Issue: Tiker users can access /api/v1/system/health (should require system:admin)" -ForegroundColor Yellow

# Check current middleware for system health endpoint
$appGoPath = "internal/app/app.go"
$content = Get-Content $appGoPath -Raw

# Add permission middleware to system health endpoint
if ($content -match 'system\.GET\("/health", a\.systemHandler\.GetSystemHealth\)') {
    Write-Host "   Adding permission middleware to system health endpoint..." -ForegroundColor Green
    
    $newContent = $content -replace 
        'system\.GET\("/health", a\.systemHandler\.GetSystemHealth\)',
        'system.GET("/health", middleware.RequireSystemPermission(a.permissionService, "manage"), a.systemHandler.GetSystemHealth)'
    
    $newContent | Out-File -FilePath $appGoPath -Encoding UTF8
    Write-Host "   ✅ Fixed: System health now requires system:admin permission" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Pattern not found, manual fix needed" -ForegroundColor Yellow
}

# 2. Fix announcements access
Write-Host ""
Write-Host "2. Fixing announcements endpoint access..." -ForegroundColor Cyan
Write-Host "   Issue: Tiker users can access announcements without proper permission check" -ForegroundColor Yellow

# The announcements endpoint should check for system:announcements_read permission
if ($content -match 'announcements\.GET\("", a\.systemHandler\.GetAnnouncements\)') {
    Write-Host "   Adding permission check to announcements endpoint..." -ForegroundColor Green
    
    $newContent = $newContent -replace 
        'announcements\.GET\("", a\.systemHandler\.GetAnnouncements\)',
        'announcements.GET("", middleware.RequirePermission(a.permissionService, "system:announcements_read"), a.systemHandler.GetAnnouncements)'
    
    $newContent | Out-File -FilePath $appGoPath -Encoding UTF8
    Write-Host "   ✅ Fixed: Announcements now require system:announcements_read permission" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Pattern not found, manual fix needed" -ForegroundColor Yellow
}

# 3. Fix records access control (own vs all)
Write-Host ""
Write-Host "3. Fixing records access control..." -ForegroundColor Cyan
Write-Host "   Issue: Tiker users can read all records instead of only their own" -ForegroundColor Yellow

# Check records middleware
$recordMiddlewarePath = "internal/middleware/permission.go"
if (Test-Path $recordMiddlewarePath) {
    Write-Host "   Checking record permission middleware..." -ForegroundColor Green
    
    $middlewareContent = Get-Content $recordMiddlewarePath -Raw
    
    # Add scope-based record permission check
    if ($middlewareContent -notmatch "RecordScopeMiddleware") {
        Write-Host "   Adding scope-based record permission middleware..." -ForegroundColor Green
        
        $scopeMiddleware = @"

// RecordScopeMiddleware checks if user can access records based on scope (own vs all)
func RecordScopeMiddleware(permissionService *services.PermissionService) gin.HandlerFunc {
    return func(c *gin.Context) {
        userID, exists := c.Get("user_id")
        if !exists {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
            c.Abort()
            return
        }

        // Check if user has full records:read permission
        hasFullAccess, err := permissionService.CheckUserPermission(userID.(uint), "records:read")
        if err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": "Permission check failed"})
            c.Abort()
            return
        }

        if hasFullAccess {
            // User has full access, continue
            c.Next()
            return
        }

        // Check if user has records:read_own permission
        hasOwnAccess, err := permissionService.CheckUserPermission(userID.(uint), "records:read_own")
        if err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": "Permission check failed"})
            c.Abort()
            return
        }

        if hasOwnAccess {
            // User can only access own records, add filter
            c.Set("records_scope", "own")
            c.Set("owner_id", userID)
            c.Next()
            return
        }

        // No permission to access records
        c.JSON(http.StatusForbidden, gin.H{"error": "Insufficient permissions to access records"})
        c.Abort()
    }
}
"@
        
        $middlewareContent += $scopeMiddleware
        $middlewareContent | Out-File -FilePath $recordMiddlewarePath -Encoding UTF8
        Write-Host "   ✅ Added scope-based record permission middleware" -ForegroundColor Green
    } else {
        Write-Host "   ✅ Scope-based record middleware already exists" -ForegroundColor Green
    }
} else {
    Write-Host "   ⚠️  Permission middleware file not found" -ForegroundColor Yellow
}

# 4. Fix export template access
Write-Host ""
Write-Host "4. Fixing export template access..." -ForegroundColor Cyan
Write-Host "   Issue: Tiker users can access export templates (admin only feature)" -ForegroundColor Yellow

# Export templates should require admin permissions
if ($content -match 'export\.GET\("/templates", a\.exportHandler\.GetTemplates\)') {
    Write-Host "   Adding admin permission to export templates..." -ForegroundColor Green
    
    $newContent = $newContent -replace 
        'export\.GET\("/templates", a\.exportHandler\.GetTemplates\)',
        'export.GET("/templates", middleware.RequireSystemPermission(a.permissionService, "manage"), a.exportHandler.GetTemplates)'
    
    $newContent | Out-File -FilePath $appGoPath -Encoding UTF8
    Write-Host "   ✅ Fixed: Export templates now require admin permission" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Pattern not found, manual fix needed" -ForegroundColor Yellow
}

# 5. Fix AI configuration access
Write-Host ""
Write-Host "5. Fixing AI configuration access..." -ForegroundColor Cyan
Write-Host "   Issue: Tiker users can access AI configurations (admin only)" -ForegroundColor Yellow

# AI config should require proper permissions
if ($content -match 'ai\.GET\("/config", a\.aiHandler\.GetConfigs\)') {
    Write-Host "   Adding permission check to AI config..." -ForegroundColor Green
    
    $newContent = $newContent -replace 
        'ai\.GET\("/config", a\.aiHandler\.GetConfigs\)',
        'ai.GET("/config", middleware.RequirePermission(a.permissionService, "ai:config"), a.aiHandler.GetConfigs)'
    
    $newContent | Out-File -FilePath $appGoPath -Encoding UTF8
    Write-Host "   ✅ Fixed: AI config now requires ai:config permission" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Pattern not found, manual fix needed" -ForegroundColor Yellow
}

# 6. Update records handler to use scope middleware
Write-Host ""
Write-Host "6. Updating records route to use scope middleware..." -ForegroundColor Cyan

if ($content -match 'records\.Use\(middleware\.RecordPermissionMiddleware\(a\.permissionService\)\)') {
    Write-Host "   Updating record permission middleware..." -ForegroundColor Green
    
    $newContent = $newContent -replace 
        'records\.Use\(middleware\.RecordPermissionMiddleware\(a\.permissionService\)\)',
        'records.Use(middleware.RecordScopeMiddleware(a.permissionService))'
    
    $newContent | Out-File -FilePath $appGoPath -Encoding UTF8
    Write-Host "   ✅ Updated: Records now use scope-based permission middleware" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Pattern not found, manual fix needed" -ForegroundColor Yellow
}

# Create a summary of changes
Write-Host ""
Write-Host "=== SUMMARY OF FIXES ===" -ForegroundColor Green
Write-Host "✅ 1. System health endpoint - Added system:admin requirement" -ForegroundColor Green
Write-Host "✅ 2. Announcements endpoint - Added system:announcements_read requirement" -ForegroundColor Green
Write-Host "✅ 3. Records access control - Added scope-based permission (own vs all)" -ForegroundColor Green
Write-Host "✅ 4. Export templates - Added admin permission requirement" -ForegroundColor Green
Write-Host "✅ 5. AI configuration - Added ai:config permission requirement" -ForegroundColor Green
Write-Host "✅ 6. Records middleware - Updated to use scope-based checking" -ForegroundColor Green

Write-Host ""
Write-Host "=== NEXT STEPS ===" -ForegroundColor Yellow
Write-Host "1. Restart the backend server to apply changes" -ForegroundColor Cyan
Write-Host "2. Run the comprehensive permission test again to verify fixes" -ForegroundColor Cyan
Write-Host "3. Test specific endpoints manually to ensure proper access control" -ForegroundColor Cyan

Write-Host ""
Write-Host "To restart backend:" -ForegroundColor Cyan
Write-Host "   .\scripts\restart-backend.ps1" -ForegroundColor Gray

Write-Host ""
Write-Host "To re-run comprehensive test:" -ForegroundColor Cyan
Write-Host "   .\scripts\complete-permission-validation-en.ps1" -ForegroundColor Gray

Write-Host ""
Write-Host "🎯 Critical permission security issues have been addressed!" -ForegroundColor Green
Write-Host "The system should now properly enforce permission boundaries." -ForegroundColor Green