package handlers

import (
	"strconv"

	"info-management-system/internal/middleware"
	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// RoleHandler 角色处理器
type RoleHandler struct {
	roleService *services.RoleService
}

// NewRoleHandler 创建角色处理器
func NewRoleHandler(roleService *services.RoleService) *RoleHandler {
	return &RoleHandler{
		roleService: roleService,
	}
}

// GetAllRoles 获取所有角色
func (h *RoleHandler) GetAllRoles(c *gin.Context) {
	roles, err := h.roleService.GetAllRoles()
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, roles)
}

// GetRoleByID 根据ID获取角色
func (h *RoleHandler) GetRoleByID(c *gin.Context) {
	roleIDStr := c.Param("id")
	roleID, err := strconv.ParseUint(roleIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的角色ID", err.Error())
		return
	}

	role, err := h.roleService.GetRoleByID(uint(roleID))
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取角色失败", err.Error())
		return
	}

	middleware.Success(c, role)
}

// CreateRole 创建角色
func (h *RoleHandler) CreateRole(c *gin.Context) {
	var req services.CreateRoleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	role, err := h.roleService.CreateRole(&req)
	if err != nil {
		middleware.ValidationErrorResponse(c, "创建角色失败", err.Error())
		return
	}

	middleware.Created(c, role)
}

// UpdateRole 更新角色
func (h *RoleHandler) UpdateRole(c *gin.Context) {
	roleIDStr := c.Param("id")
	roleID, err := strconv.ParseUint(roleIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的角色ID", err.Error())
		return
	}

	var req services.UpdateRoleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	role, err := h.roleService.UpdateRole(uint(roleID), &req)
	if err != nil {
		middleware.ValidationErrorResponse(c, "更新角色失败", err.Error())
		return
	}

	middleware.Success(c, role)
}

// DeleteRole 删除角色
func (h *RoleHandler) DeleteRole(c *gin.Context) {
	roleIDStr := c.Param("id")
	roleID, err := strconv.ParseUint(roleIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的角色ID", err.Error())
		return
	}

	if err := h.roleService.DeleteRole(uint(roleID)); err != nil {
		middleware.ValidationErrorResponse(c, "删除角色失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{
		"message": "角色删除成功",
	})
}

// AssignPermissions 为角色分配权限
func (h *RoleHandler) AssignPermissions(c *gin.Context) {
	roleIDStr := c.Param("id")
	roleID, err := strconv.ParseUint(roleIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的角色ID", err.Error())
		return
	}

	var req services.AssignPermissionsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	role, err := h.roleService.AssignPermissions(uint(roleID), &req)
	if err != nil {
		middleware.ValidationErrorResponse(c, "分配权限失败", err.Error())
		return
	}

	middleware.Success(c, role)
}

// UpdateRolePermissions 更新角色权限（支持前端格式）
func (h *RoleHandler) UpdateRolePermissions(c *gin.Context) {
	roleIDStr := c.Param("id")
	roleID, err := strconv.ParseUint(roleIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的角色ID", err.Error())
		return
	}

	var req services.AssignPermissionsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	role, err := h.roleService.AssignPermissions(uint(roleID), &req)
	if err != nil {
		middleware.ValidationErrorResponse(c, "分配权限失败", err.Error())
		return
	}

	middleware.Success(c, role)
}

// GetRolePermissions 获取角色权限
func (h *RoleHandler) GetRolePermissions(c *gin.Context) {
	roleIDStr := c.Param("id")
	roleID, err := strconv.ParseUint(roleIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的角色ID", err.Error())
		return
	}

	permissions, err := h.roleService.GetRolePermissions(uint(roleID))
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取角色权限失败", err.Error())
		return
	}

	middleware.Success(c, permissions)
}

// ImportRoles 导入角色
func (h *RoleHandler) ImportRoles(c *gin.Context) {
	var req services.ImportRolesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	results, err := h.roleService.ImportRoles(&req)
	if err != nil {
		middleware.ValidationErrorResponse(c, "导入角色失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"results": results})
}

// BatchUpdateRoleStatus 批量更新角色状态
func (h *RoleHandler) BatchUpdateRoleStatus(c *gin.Context) {
	var req services.BatchUpdateRoleStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	err := h.roleService.BatchUpdateRoleStatus(&req)
	if err != nil {
		middleware.ValidationErrorResponse(c, "批量更新角色状态失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "批量更新成功"})
}

// BatchDeleteRoles 批量删除角色
func (h *RoleHandler) BatchDeleteRoles(c *gin.Context) {
	var req services.BatchDeleteRolesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	err := h.roleService.BatchDeleteRoles(&req)
	if err != nil {
		middleware.ValidationErrorResponse(c, "批量删除角色失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "批量删除成功"})
}
