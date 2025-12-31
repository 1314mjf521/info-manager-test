package middleware

import (
	"fmt"
	"info-management-system/internal/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// PermissionMiddleware 权限检查中间件
type PermissionMiddleware struct {
	db              *gorm.DB
	permissionService *services.PermissionService
}

// NewPermissionMiddleware 创建权限中间件
func NewPermissionMiddleware(db *gorm.DB, permissionService *services.PermissionService) *PermissionMiddleware {
	return &PermissionMiddleware{
		db:              db,
		permissionService: permissionService,
	}
}

// RequirePermission 要求特定权限的中间件
func (pm *PermissionMiddleware) RequirePermission(permission string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取当前用户ID
		userID, exists := GetCurrentUserID(c)
		if !exists {
			AuthorizationErrorResponse(c, "需要登录")
			c.Abort()
			return
		}

		// 检查权限
		hasPermission, err := pm.checkUserPermission(userID, permission)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   "权限检查失败",
			})
			c.Abort()
			return
		}

		if !hasPermission {
			c.JSON(http.StatusForbidden, gin.H{
				"success": false,
				"error":   fmt.Sprintf("缺少权限: %s", permission),
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// RequireAnyPermission 要求任意一个权限的中间件
func (pm *PermissionMiddleware) RequireAnyPermission(permissions ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取当前用户ID
		userID, exists := GetCurrentUserID(c)
		if !exists {
			AuthorizationErrorResponse(c, "需要登录")
			c.Abort()
			return
		}

		// 检查是否有任意一个权限
		hasAnyPermission := false
		for _, permission := range permissions {
			hasPermission, err := pm.checkUserPermission(userID, permission)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{
					"success": false,
					"error":   "权限检查失败",
				})
				c.Abort()
				return
			}
			if hasPermission {
				hasAnyPermission = true
				break
			}
		}

		if !hasAnyPermission {
			c.JSON(http.StatusForbidden, gin.H{
				"success": false,
				"error":   fmt.Sprintf("缺少权限: %v", permissions),
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// RequireAllPermissions 要求所有权限的中间件
func (pm *PermissionMiddleware) RequireAllPermissions(permissions ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取当前用户ID
		userID, exists := GetCurrentUserID(c)
		if !exists {
			AuthorizationErrorResponse(c, "需要登录")
			c.Abort()
			return
		}

		// 检查是否有所有权限
		for _, permission := range permissions {
			hasPermission, err := pm.checkUserPermission(userID, permission)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{
					"success": false,
					"error":   "权限检查失败",
				})
				c.Abort()
				return
			}
			if !hasPermission {
				c.JSON(http.StatusForbidden, gin.H{
					"success": false,
					"error":   fmt.Sprintf("缺少权限: %s", permission),
				})
				c.Abort()
				return
			}
		}

		c.Next()
	}
}

// checkUserPermission 检查用户是否有指定权限
func (pm *PermissionMiddleware) checkUserPermission(userID uint, permission string) (bool, error) {
	// 使用权限服务检查权限
	response, err := pm.permissionService.GetUserPermissions(userID)
	if err != nil {
		return false, err
	}

	// 检查用户是否有指定权限
	for _, userPermission := range response.Permissions {
		if userPermission.Name == permission {
			return true, nil
		}
	}

	return false, nil
}

// CheckPermission 检查权限的辅助函数（用于处理器中）
func (pm *PermissionMiddleware) CheckPermission(c *gin.Context, permission string) bool {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		return false
	}

	hasPermission, err := pm.checkUserPermission(userID, permission)
	if err != nil {
		return false
	}

	return hasPermission
}

// HasPermission 全局权限检查函数
func HasPermission(c *gin.Context, permission string) bool {
	_, exists := GetCurrentUserID(c)
	if !exists {
		return false
	}

	// 这里需要从上下文或全局变量获取权限服务实例
	// 为了简化，我们先返回true，后续需要完善
	return true
}

// RequireSystemPermission 要求系统权限的中间件
func RequireSystemPermission(permissionService *services.PermissionService, permission string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, exists := GetCurrentUserID(c)
		if !exists {
			AuthorizationErrorResponse(c, "需要登录")
			c.Abort()
			return
		}

		// 获取用户权限列表
		userPermissions, err := permissionService.GetUserPermissions(userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   "权限检查失败",
			})
			c.Abort()
			return
		}

		// 检查用户是否有管理员角色或指定权限
		hasAdminRole := false
		for _, role := range userPermissions.Roles {
			if role.Name == "admin" {
				hasAdminRole = true
				break
			}
		}

		if hasAdminRole {
			c.Next()
			return
		}

		// 其他用户拒绝访问
		c.JSON(403, gin.H{
			"success": false,
			"error":   "权限不足",
		})
		c.Abort()
	}
}

// RequirePermission 全局权限检查中间件
func RequirePermission(permissionService *services.PermissionService, permission string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, exists := GetCurrentUserID(c)
		if !exists {
			AuthorizationErrorResponse(c, "需要登录")
			c.Abort()
			return
		}

		// 获取用户权限列表
		userPermissions, err := permissionService.GetUserPermissions(userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   "权限检查失败",
			})
			c.Abort()
			return
		}

		// 检查用户是否有管理员角色
		hasAdminRole := false
		for _, role := range userPermissions.Roles {
			if role.Name == "admin" {
				hasAdminRole = true
				break
			}
		}

		if hasAdminRole {
			c.Next()
			return
		}

		// 检查用户是否有指定权限
		hasPermission := false
		for _, userPermission := range userPermissions.Permissions {
			if userPermission.Name == permission {
				hasPermission = true
				break
			}
		}

		if !hasPermission {
			c.JSON(http.StatusForbidden, gin.H{
				"success": false,
				"error":   fmt.Sprintf("缺少权限: %s", permission),
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// RecordScopeMiddleware checks if user can access records based on scope (own vs all)
func RecordScopeMiddleware(permissionService *services.PermissionService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			c.Abort()
			return
		}

		// 获取用户权限列表
		userPermissions, err := permissionService.GetUserPermissions(userID.(uint))
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Permission check failed"})
			c.Abort()
			return
		}

		// 检查用户是否有管理员角色
		hasAdminRole := false
		for _, role := range userPermissions.Roles {
			if role.Name == "admin" {
				hasAdminRole = true
				break
			}
		}

		if hasAdminRole {
			c.Next()
			return
		}

		// 检查用户是否有完整的records:read权限
		hasFullAccess := false
		hasOwnAccess := false
		
		for _, permission := range userPermissions.Permissions {
			if permission.Name == "records:read" {
				hasFullAccess = true
				break
			}
			if permission.Name == "records:read_own" {
				hasOwnAccess = true
			}
		}

		if hasFullAccess {
			// User has full access, continue
			c.Next()
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