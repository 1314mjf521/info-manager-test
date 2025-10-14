package middleware

import (
	"fmt"

	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// PermissionMiddleware 权限验证中间件
func PermissionMiddleware(permissionService *services.PermissionService, resource, action, scope string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, exists := GetCurrentUserID(c)
		if !exists {
			AuthorizationErrorResponse(c, "需要登录")
			c.Abort()
			return
		}

		// 检查权限
		req := &services.PermissionCheckRequest{
			UserID:   userID,
			Resource: resource,
			Action:   action,
			Scope:    scope,
		}

		response, err := permissionService.CheckPermission(req)
		if err != nil {
			InternalErrorResponse(c, err)
			c.Abort()
			return
		}

		if !response.HasPermission {
			AuthorizationErrorResponse(c, response.Message)
			c.Abort()
			return
		}

		c.Next()
	}
}

// RequirePermission 要求特定权限的中间件工厂函数
func RequirePermission(permissionService *services.PermissionService, resource, action string) gin.HandlerFunc {
	return PermissionMiddleware(permissionService, resource, action, "")
}

// RequirePermissionWithScope 要求特定权限和范围的中间件工厂函数
func RequirePermissionWithScope(permissionService *services.PermissionService, resource, action, scope string) gin.HandlerFunc {
	return PermissionMiddleware(permissionService, resource, action, scope)
}

// RequireAdminPermission 要求管理员权限的中间件
func RequireAdminPermission(permissionService *services.PermissionService) gin.HandlerFunc {
	return PermissionMiddleware(permissionService, "system", "admin", "all")
}

// RequireSystemPermission 要求系统权限的中间件
func RequireSystemPermission(permissionService *services.PermissionService, action string) gin.HandlerFunc {
	return PermissionMiddleware(permissionService, "system", action, "all")
}

// RequireUserPermission 要求用户权限的中间件
func RequireUserPermission(permissionService *services.PermissionService, action, scope string) gin.HandlerFunc {
	return PermissionMiddleware(permissionService, "users", action, scope)
}

// RequireRecordPermission 要求记录权限的中间件
func RequireRecordPermission(permissionService *services.PermissionService, action, scope string) gin.HandlerFunc {
	return PermissionMiddleware(permissionService, "records", action, scope)
}

// CheckOwnership 检查资源所有权的中间件
func CheckOwnership(resourceIDParam string, getResourceOwnerFunc func(uint) (uint, error)) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, exists := GetCurrentUserID(c)
		if !exists {
			AuthorizationErrorResponse(c, "需要登录")
			c.Abort()
			return
		}

		// 获取资源ID
		resourceIDStr := c.Param(resourceIDParam)
		if resourceIDStr == "" {
			ValidationErrorResponse(c, "资源ID不能为空", "")
			c.Abort()
			return
		}

		// 转换为uint
		var resourceID uint
		if _, err := fmt.Sscanf(resourceIDStr, "%d", &resourceID); err != nil {
			ValidationErrorResponse(c, "无效的资源ID", err.Error())
			c.Abort()
			return
		}

		// 获取资源所有者
		ownerID, err := getResourceOwnerFunc(resourceID)
		if err != nil {
			NotFoundErrorResponse(c, "资源不存在")
			c.Abort()
			return
		}

		// 检查所有权
		if ownerID != userID {
			AuthorizationErrorResponse(c, "无权访问该资源")
			c.Abort()
			return
		}

		// 将资源ID存储到上下文中
		c.Set("resource_id", resourceID)
		c.Set("resource_owner_id", ownerID)
		c.Next()
	}
}

// GetResourceID 从上下文获取资源ID
func GetResourceID(c *gin.Context) (uint, bool) {
	if resourceID, exists := c.Get("resource_id"); exists {
		if id, ok := resourceID.(uint); ok {
			return id, true
		}
	}
	return 0, false
}

// GetResourceOwnerID 从上下文获取资源所有者ID
func GetResourceOwnerID(c *gin.Context) (uint, bool) {
	if ownerID, exists := c.Get("resource_owner_id"); exists {
		if id, ok := ownerID.(uint); ok {
			return id, true
		}
	}
	return 0, false
}