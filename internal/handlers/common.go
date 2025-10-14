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
	// 这里应该实现权限检查逻辑
	// 暂时返回true，实际应该检查用户权限
	return true
}