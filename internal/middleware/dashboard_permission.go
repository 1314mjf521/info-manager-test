package middleware

import (
	"net/http"

	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// DashboardPermissionMiddleware 仪表盘权限中间件
func DashboardPermissionMiddleware(permissionService *services.PermissionService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetUint("user_id")
		if userID == 0 {
			c.JSON(http.StatusUnauthorized, APIResponse{
				Success: false,
				Error: &APIError{
					Code:    "UNAUTHORIZED",
					Message: "用户未认证",
				},
			})
			c.Abort()
			return
		}

		// 获取用户权限
		permissionsResp, err := permissionService.GetUserPermissions(userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, APIResponse{
				Success: false,
				Error: &APIError{
					Code:    "PERMISSION_CHECK_FAILED",
					Message: "权限检查失败",
				},
			})
			c.Abort()
			return
		}

		// 检查用户是否有查看所有记录的权限
		hasAllRecordsPermission := false
		// 检查用户是否有查看所有文件的权限
		hasAllFilesPermission := false
		// 检查用户是否有系统管理权限（可以查看用户统计）
		hasSystemPermission := false

		for _, perm := range permissionsResp.Permissions {
			// 检查记录权限
			if perm.Resource == "records" && perm.Action == "read" && perm.Scope == "all" {
				hasAllRecordsPermission = true
			}
			
			// 检查文件权限
			if perm.Resource == "files" && perm.Action == "read" && perm.Scope == "all" {
				hasAllFilesPermission = true
			}
			
			// 检查系统权限（管理员权限或用户管理权限）
			if (perm.Resource == "system" && perm.Action == "admin") ||
			   (perm.Resource == "users" && perm.Action == "read") {
				hasSystemPermission = true
			}
		}

		// 将权限信息存储到上下文中
		c.Set("has_all_records_permission", hasAllRecordsPermission)
		c.Set("has_all_files_permission", hasAllFilesPermission)
		c.Set("has_system_permission", hasSystemPermission)

		c.Next()
	}
}