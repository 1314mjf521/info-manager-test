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

// InitializePermissions 初始化精细化权限数据
func (h *PermissionHandler) InitializePermissions(c *gin.Context) {
	err := h.permissionService.InitializeDetailedPermissions()
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, gin.H{
		"message": "权限数据初始化成功",
	})
}

// InitializeSimplifiedPermissions 初始化简化权限数据
func (h *PermissionHandler) InitializeSimplifiedPermissions(c *gin.Context) {
	err := h.permissionService.InitializeSimplifiedPermissions()
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, gin.H{
		"message": "简化权限数据初始化成功",
	})
}

// CreatePermission 创建权限
func (h *PermissionHandler) CreatePermission(c *gin.Context) {
	var req struct {
		Name        string `json:"name" binding:"required"`
		DisplayName string `json:"displayName" binding:"required"`
		Description string `json:"description"`
		Resource    string `json:"resource" binding:"required"`
		Action      string `json:"action" binding:"required"`
		Scope       string `json:"scope" binding:"required"`
		ParentID    *uint  `json:"parentId"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	permission, err := h.permissionService.CreatePermissionWithDetails(
		req.Name, req.DisplayName, req.Description,
		req.Resource, req.Action, req.Scope, req.ParentID,
	)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, permission)
}

// UpdatePermission 更新权限
func (h *PermissionHandler) UpdatePermission(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的权限ID", err.Error())
		return
	}

	var req services.UpdatePermissionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	permission, err := h.permissionService.UpdatePermission(uint(id), &req)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, permission)
}

// DeletePermission 删除权限
func (h *PermissionHandler) DeletePermission(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的权限ID", err.Error())
		return
	}

	err = h.permissionService.DeletePermission(uint(id))
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, gin.H{
		"message": "权限删除成功",
	})
}
