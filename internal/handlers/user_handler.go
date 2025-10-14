package handlers

import (
	"strconv"

	"info-management-system/internal/middleware"
	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// UserHandler 用户管理处理器
type UserHandler struct {
	userService *services.UserService
	roleService *services.RoleService
}

// NewUserHandler 创建用户管理处理器
func NewUserHandler(userService *services.UserService, roleService *services.RoleService) *UserHandler {
	return &UserHandler{
		userService: userService,
		roleService: roleService,
	}
}

// GetAllUsers 获取所有用户
func (h *UserHandler) GetAllUsers(c *gin.Context) {
	// 获取查询参数
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(c.DefaultQuery("size", "20"))
	username := c.Query("username")
	email := c.Query("email")
	status := c.Query("status")

	users, total, err := h.userService.GetAllUsers(page, size, username, email, status)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, gin.H{
		"items": users,
		"total": total,
		"page":  page,
		"size":  size,
	})
}

// GetUserByID 根据ID获取用户
func (h *UserHandler) GetUserByID(c *gin.Context) {
	userIDStr := c.Param("id")
	userID, err := strconv.ParseUint(userIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的用户ID", err.Error())
		return
	}

	user, err := h.userService.GetUserByID(uint(userID))
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取用户失败", err.Error())
		return
	}

	middleware.Success(c, user)
}

// CreateUser 创建用户
func (h *UserHandler) CreateUser(c *gin.Context) {
	var req services.CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	user, err := h.userService.CreateUser(&req)
	if err != nil {
		middleware.ValidationErrorResponse(c, "创建用户失败", err.Error())
		return
	}

	middleware.Created(c, user)
}

// UpdateUser 更新用户
func (h *UserHandler) UpdateUser(c *gin.Context) {
	userIDStr := c.Param("id")
	userID, err := strconv.ParseUint(userIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的用户ID", err.Error())
		return
	}

	var req services.UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	user, err := h.userService.UpdateUser(uint(userID), &req)
	if err != nil {
		middleware.ValidationErrorResponse(c, "更新用户失败", err.Error())
		return
	}

	middleware.Success(c, user)
}

// DeleteUser 删除用户
func (h *UserHandler) DeleteUser(c *gin.Context) {
	userIDStr := c.Param("id")
	userID, err := strconv.ParseUint(userIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的用户ID", err.Error())
		return
	}

	if err := h.userService.DeleteUser(uint(userID)); err != nil {
		middleware.ValidationErrorResponse(c, "删除用户失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{
		"message": "用户删除成功",
	})
}

// AssignRoles 为用户分配角色
func (h *UserHandler) AssignRoles(c *gin.Context) {
	userIDStr := c.Param("id")
	userID, err := strconv.ParseUint(userIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的用户ID", err.Error())
		return
	}

	var req services.AssignRolesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	user, err := h.userService.AssignRoles(uint(userID), &req)
	if err != nil {
		middleware.ValidationErrorResponse(c, "分配角色失败", err.Error())
		return
	}

	middleware.Success(c, user)
}

// GetUserRoles 获取用户角色
func (h *UserHandler) GetUserRoles(c *gin.Context) {
	userIDStr := c.Param("id")
	userID, err := strconv.ParseUint(userIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的用户ID", err.Error())
		return
	}

	roles, err := h.userService.GetUserRoles(uint(userID))
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取用户角色失败", err.Error())
		return
	}

	middleware.Success(c, roles)
}

// BatchUpdateStatus 批量更新用户状态
func (h *UserHandler) BatchUpdateStatus(c *gin.Context) {
	var req struct {
		UserIDs []uint `json:"user_ids" binding:"required"`
		Status  string `json:"status" binding:"required,oneof=active inactive"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	if len(req.UserIDs) == 0 {
		middleware.ValidationErrorResponse(c, "用户ID列表不能为空", "")
		return
	}

	err := h.userService.BatchUpdateStatus(req.UserIDs, req.Status)
	if err != nil {
		middleware.ValidationErrorResponse(c, "批量更新状态失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{
		"message": "批量更新状态成功",
		"count":   len(req.UserIDs),
	})
}

// BatchDeleteUsers 批量删除用户
func (h *UserHandler) BatchDeleteUsers(c *gin.Context) {
	var req struct {
		UserIDs []uint `json:"user_ids" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	if len(req.UserIDs) == 0 {
		middleware.ValidationErrorResponse(c, "用户ID列表不能为空", "")
		return
	}

	err := h.userService.BatchDeleteUsers(req.UserIDs)
	if err != nil {
		middleware.ValidationErrorResponse(c, "批量删除用户失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{
		"message": "批量删除用户成功",
		"count":   len(req.UserIDs),
	})
}

// BatchResetPassword 批量重置密码
func (h *UserHandler) BatchResetPassword(c *gin.Context) {
	var req struct {
		UserIDs []uint `json:"user_ids" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	if len(req.UserIDs) == 0 {
		middleware.ValidationErrorResponse(c, "用户ID列表不能为空", "")
		return
	}

	results, err := h.userService.BatchResetPassword(req.UserIDs)
	if err != nil {
		middleware.ValidationErrorResponse(c, "批量重置密码失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{
		"message": "批量重置密码完成",
		"results": results,
	})
}

// ResetPassword 重置单个用户密码
func (h *UserHandler) ResetPassword(c *gin.Context) {
	userIDStr := c.Param("id")
	userID, err := strconv.ParseUint(userIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的用户ID", err.Error())
		return
	}

	result, err := h.userService.ResetPassword(uint(userID))
	if err != nil {
		middleware.ValidationErrorResponse(c, "重置密码失败", err.Error())
		return
	}

	middleware.Success(c, result)
}

// ImportUsers 导入用户
func (h *UserHandler) ImportUsers(c *gin.Context) {
	var req struct {
		Users []services.ImportUserData `json:"users" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	if len(req.Users) == 0 {
		middleware.ValidationErrorResponse(c, "用户数据不能为空", "")
		return
	}

	results, err := h.userService.ImportUsers(req.Users)
	if err != nil {
		middleware.ValidationErrorResponse(c, "导入用户失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{
		"message": "用户导入完成",
		"results": results,
	})
}
