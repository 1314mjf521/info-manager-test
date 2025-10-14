package middleware

import (
	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// ExportPermissionMiddleware 导出权限中间件
func ExportPermissionMiddleware(permissionService *services.PermissionService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetUint("user_id")
		if userID == 0 {
			c.Next()
			return
		}

		// 检查用户是否有导出所有数据的权限
		req := &services.PermissionCheckRequest{
			UserID:   userID,
			Resource: "export",
			Action:   "read",
			Scope:    "all",
		}
		
		response, err := permissionService.CheckPermission(req)
		hasAllExportPermission := false
		if err == nil && response != nil {
			hasAllExportPermission = response.HasPermission
		}

		// 将权限信息存储到上下文中
		c.Set("has_all_export_permission", hasAllExportPermission)

		c.Next()
	}
}