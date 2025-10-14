package handlers

import (
	"strconv"

	"info-management-system/internal/middleware"
	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// PermissionHandler 权限处理器
type PermissionHandler struct {
	permissionService *services.PermissionService
}

// NewPermissionHandler 创建权限处理器
func NewPermissionHandler(permissionService *services.PermissionService) *PermissionHandler {
	return &PermissionHandler{
		permissionService: permissionService,
	}
}

// CheckPermission 检查权限
func (h *PermissionHandler) CheckPermission(c *gin.Context) {
	var req services.PermissionCheckRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	response, err := h.permissionService.CheckPermission(&req)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, response)
}

// GetUserPermissions 获取用户权限
func (h *PermissionHandler) GetUserPermissions(c *gin.Context) {
	userIDStr := c.Param("user_id")
	userID, err := strconv.ParseUint(userIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的用户ID", err.Error())
		return
	}

	response, err := h.permissionService.GetUserPermissions(uint(userID))
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取用户权限失败", err.Error())
		return
	}

	middleware.Success(c, response)
}

// GetAllPermissions 获取所有权限
func (h *PermissionHandler) GetAllPermissions(c *gin.Context) {
	permissions, err := h.permissionService.GetAllPermissions()
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, permissions)
}

// GetPermissionTree 获取权限树结构
func (h *PermissionHandler) GetPermissionTree(c *gin.Context) {
	tree, err := h.permissionService.GetPermissionTree()
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, tree)
}
