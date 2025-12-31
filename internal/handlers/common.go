package handlers

import (
	"net/http"
	"strconv"

	"info-management-system/internal/middleware"

	"github.com/gin-gonic/gin"
)

// parseUintParam 解析URL参数为uint
func parseUintParam(c *gin.Context, paramName string) (uint, error) {
	paramStr := c.Param(paramName)
	if paramStr == "" {
		middleware.ValidationErrorResponse(c, "参数不能为空", "")
		return 0, gin.Error{}
	}

	id, err := strconv.ParseUint(paramStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的参数", err.Error())
		return 0, err
	}

	return uint(id), nil
}

// handleValidationError 处理验证错误
func handleValidationError(c *gin.Context, err error) {
	middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
}

// handleInternalError 处理内部错误
func handleInternalError(c *gin.Context, message string, err error) {
	middleware.InternalErrorResponse(c, err)
}

// handleNotFoundError 处理未找到错误
func handleNotFoundError(c *gin.Context, message string) {
	c.JSON(http.StatusNotFound, gin.H{
		"success": false,
		"error": gin.H{
			"code":    "NOT_FOUND",
			"message": message,
		},
	})
}

// handleForbiddenError 处理权限错误
func handleForbiddenError(c *gin.Context, message string) {
	c.JSON(http.StatusForbidden, gin.H{
		"success": false,
		"error": gin.H{
			"code":    "FORBIDDEN",
			"message": message,
		},
	})
}

// handleConflictError 处理冲突错误
func handleConflictError(c *gin.Context, message string) {
	c.JSON(http.StatusConflict, gin.H{
		"success": false,
		"error": gin.H{
			"code":    "CONFLICT",
			"message": message,
		},
	})
}

// successResponse 成功响应
func successResponse(c *gin.Context, data interface{}) {
	middleware.Success(c, data)
}

// createdResponse 创建成功响应
func createdResponse(c *gin.Context, data interface{}) {
	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    data,
	})
}

// getUserID 从上下文中获取用户ID
func getUserID(c *gin.Context) uint {
	userID, exists := c.Get("user_id")
	if !exists {
		return 0
	}
	
	if id, ok := userID.(uint); ok {
		return id
	}
	
	return 0
}

// hasPermission 检查用户是否有指定权限
func hasPermission(c *gin.Context, permission string) bool {
	userID := getUserID(c)
	if userID == 0 {
		return false
	}

	// 管理员用户（ID=1）拥有所有权限
	if userID == 1 {
		return true
	}

	// 获取用户角色
	userRoles, exists := c.Get("user_roles")
	if !exists {
		return false
	}

	roles, ok := userRoles.([]string)
	if !ok {
		return false
	}

	// 检查是否是管理员角色
	for _, role := range roles {
		if role == "admin" || role == "系统管理员" || role == "administrator" {
			return true
		}
	}

	// 动态权限检查 - 从JWT token中获取用户权限
	userPermissions, exists := c.Get("user_permissions")
	if exists {
		if permissions, ok := userPermissions.([]string); ok {
			return contains(permissions, permission)
		}
	}

	// 如果JWT中没有权限信息，使用硬编码的权限列表作为后备
	// 对于tiker_user角色，检查数据库中实际分配的权限
	if contains(roles, "tiker_user") || contains(roles, "ticker") {
		// 工单申请人权限列表（与数据库权限保持一致）
		tikerPermissions := []string{
			// 工单权限（仅自己的）
			"ticket:read_own", "ticket:create", "ticket:update_own", "ticket:delete_own",
			"ticket:assign", "ticket:comment_read", "ticket:comment_write", 
			"ticket:attachment_upload", "ticket:statistics",
			// 注意：移除了 ticket:export 和 ticket:import，因为数据库中没有分配这些权限
			// 文件权限
			"files:read", "files:upload", "files:download",
			// 记录权限（仅自己的）
			"records:read_own", "records:create", "records:update_own", "records:delete_own",
		}
		return contains(tikerPermissions, permission)
	}

	// 其他角色默认拒绝
	return false
}

// contains 检查字符串切片是否包含指定字符串
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}