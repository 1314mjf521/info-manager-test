package middleware

import (
	"strings"

	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// AuthMiddleware JWT认证中间件
func AuthMiddleware(authService *services.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取Authorization头
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			AuthorizationErrorResponse(c, "缺少认证token")
			c.Abort()
			return
		}

		// 检查Bearer前缀
		if !strings.HasPrefix(authHeader, "Bearer ") {
			AuthorizationErrorResponse(c, "无效的token格式")
			c.Abort()
			return
		}

		// 提取token
		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == "" {
			AuthorizationErrorResponse(c, "token不能为空")
			c.Abort()
			return
		}

		// 验证token
		claims, err := authService.ValidateToken(tokenString)
		if err != nil {
			AuthorizationErrorResponse(c, "无效的token")
			c.Abort()
			return
		}

		// 将用户信息存储到上下文
		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)
		c.Set("user_roles", claims.Roles)

		c.Next()
	}
}

// OptionalAuthMiddleware 可选认证中间件
func OptionalAuthMiddleware(authService *services.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader != "" && strings.HasPrefix(authHeader, "Bearer ") {
			tokenString := strings.TrimPrefix(authHeader, "Bearer ")
			if claims, err := authService.ValidateToken(tokenString); err == nil {
				c.Set("user_id", claims.UserID)
				c.Set("username", claims.Username)
				c.Set("user_roles", claims.Roles)
			}
		}
		c.Next()
	}
}

// GetCurrentUserID 获取当前用户ID
func GetCurrentUserID(c *gin.Context) (uint, bool) {
	if userID, exists := c.Get("user_id"); exists {
		if id, ok := userID.(uint); ok {
			return id, true
		}
	}
	return 0, false
}

// GetCurrentUsername 获取当前用户名
func GetCurrentUsername(c *gin.Context) (string, bool) {
	if username, exists := c.Get("username"); exists {
		if name, ok := username.(string); ok {
			return name, true
		}
	}
	return "", false
}

// GetCurrentUserRoles 获取当前用户角色
func GetCurrentUserRoles(c *gin.Context) ([]string, bool) {
	if roles, exists := c.Get("user_roles"); exists {
		if roleList, ok := roles.([]string); ok {
			return roleList, true
		}
	}
	return nil, false
}

// RequireAuth 要求认证的中间件
func RequireAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		if _, exists := GetCurrentUserID(c); !exists {
			AuthorizationErrorResponse(c, "需要登录")
			c.Abort()
			return
		}
		c.Next()
	}
}