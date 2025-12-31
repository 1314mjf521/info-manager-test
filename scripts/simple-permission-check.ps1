# Simple permission system verification
Write-Host "=== Permission System Check ===" -ForegroundColor Green

$headers = @{
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJ1c2VybmFtZSI6ImFkbWluIiwicm9sZXMiOlsiYWRtaW4iXSwiaXNzIjoiaW5mby1tYW5hZ2VtZW50LXN5c3RlbSIsInN1YiI6IjEiLCJleHAiOjE3NjY4MzI0MjYsIm5iZiI6MTc2Njc0NjAyNiwiaWF0IjoxNzY2NzQ2MDI2fQ.quE5hkIgg_2GdcImQD3cMbLMpUuic7AcwYLTYw_Bax8"
    "Content-Type" = "application/json"
}

# Check permissions
$permissionsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/permissions" -Method GET -Headers $headers
$permissions = $permissionsResponse.data
$groupedPermissions = $permissions | Group-Object resource

Write-Host "Total permissions: $($permissions.Count)"
Write-Host "Total modules: $($groupedPermissions.Count)"
Write-Host ""

Write-Host "Modules:"
$groupedPermissions | Sort-Object Name | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) permissions"
}

# Check DisplayName
$emptyDisplayNames = $permissions | Where-Object { [string]::IsNullOrEmpty($_.displayName) }
Write-Host ""
if ($emptyDisplayNames.Count -eq 0) {
    Write-Host "All permissions have DisplayName: OK" -ForegroundColor Green
} else {
    Write-Host "Missing DisplayName: $($emptyDisplayNames.Count) permissions" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Check Complete ===" -ForegroundColor Green