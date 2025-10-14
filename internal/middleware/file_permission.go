package middleware

import (
	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// FilePermissionMiddleware 文件权限中间件
func FilePermissionMiddleware(permissionService *services.PermissionService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetUint("user_id")
		if userID == 0 {
			c.Next()
			return
		}

		// 检查用户是否有查看所有文件的权限
		req := &services.PermissionCheckRequest{
			UserID:   userID,
			Resource: "files",
			Action:   "read",
			Scope:    "all",
		}
		
		response, err := permissionService.CheckPermission(req)
		hasAllFilesPermission := false
		if err == nil && response != nil {
			hasAllFilesPermission = response.HasPermission
		}

		// 将权限信息存储到上下文中
		c.Set("has_all_files_permission", hasAllFilesPermission)

		c.Next()
	}
}