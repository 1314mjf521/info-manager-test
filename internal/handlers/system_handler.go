package handlers

import (
	"strconv"
	"time"

	"info-management-system/internal/middleware"
	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// SystemHandler 系统管理处理器
type SystemHandler struct {
	systemService *services.SystemService
}

// NewSystemHandler 创建系统管理处理器
func NewSystemHandler(systemService *services.SystemService) *SystemHandler {
	return &SystemHandler{
		systemService: systemService,
	}
}

// CreateConfig 创建系统配置
func (h *SystemHandler) CreateConfig(c *gin.Context) {
	var req services.SystemConfigRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	userID, _ := middleware.GetCurrentUserID(c)
	config, err := h.systemService.CreateConfig(&req, userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "创建系统配置失败", err.Error())
		return
	}

	middleware.Success(c, config)
}

// GetConfigs 获取系统配置列表
func (h *SystemHandler) GetConfigs(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	category := c.Query("category")

	var isPublic *bool
	if isPublicStr := c.Query("is_public"); isPublicStr != "" {
		if val, err := strconv.ParseBool(isPublicStr); err == nil {
			isPublic = &val
		}
	}

	response, err := h.systemService.GetConfigs(page, pageSize, category, isPublic)
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取系统配置失败", err.Error())
		return
	}

	middleware.Success(c, response)
}

// GetConfigByKey 根据键获取系统配置
func (h *SystemHandler) GetConfigByKey(c *gin.Context) {
	category := c.Param("category")
	key := c.Param("key")

	config, err := h.systemService.GetConfigByKey(category, key)
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取系统配置失败", err.Error())
		return
	}

	middleware.Success(c, config)
}

// UpdateConfig 更新系统配置
func (h *SystemHandler) UpdateConfig(c *gin.Context) {
	category := c.Param("category")
	key := c.Param("key")

	var req services.SystemConfigUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	userID, _ := middleware.GetCurrentUserID(c)
	config, err := h.systemService.UpdateConfig(category, key, &req, userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "更新系统配置失败", err.Error())
		return
	}

	middleware.Success(c, config)
}

// DeleteConfig 删除系统配置
func (h *SystemHandler) DeleteConfig(c *gin.Context) {
	category := c.Param("category")
	key := c.Param("key")
	reason := c.Query("reason")

	userID, _ := middleware.GetCurrentUserID(c)
	err := h.systemService.DeleteConfig(category, key, reason, userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "删除系统配置失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "配置删除成功"})
}

// CreateAnnouncement 创建公告
func (h *SystemHandler) CreateAnnouncement(c *gin.Context) {
	var req services.AnnouncementRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	userID, _ := middleware.GetCurrentUserID(c)
	announcement, err := h.systemService.CreateAnnouncement(&req, userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "创建公告失败", err.Error())
		return
	}

	middleware.Success(c, announcement)
}

// GetAnnouncements 获取公告列表
func (h *SystemHandler) GetAnnouncements(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	announcementType := c.Query("type")

	var isActive *bool
	if isActiveStr := c.Query("is_active"); isActiveStr != "" {
		if val, err := strconv.ParseBool(isActiveStr); err == nil {
			isActive = &val
		}
	}

	userID, _ := middleware.GetCurrentUserID(c)
	response, err := h.systemService.GetAnnouncements(page, pageSize, announcementType, isActive, userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取公告列表失败", err.Error())
		return
	}

	middleware.Success(c, response)
}

// GetPublicAnnouncements 获取公共公告列表（无需认证）
func (h *SystemHandler) GetPublicAnnouncements(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	// 只获取活跃的公告
	isActive := true
	response, err := h.systemService.GetPublicAnnouncements(page, pageSize, &isActive)
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取公告列表失败", err.Error())
		return
	}

	middleware.Success(c, response)
}

// GetAnnouncementByID 根据ID获取公告
func (h *SystemHandler) GetAnnouncementByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的公告ID", err.Error())
		return
	}

	announcement, err := h.systemService.GetAnnouncementByID(uint(id))
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取公告失败", err.Error())
		return
	}

	middleware.Success(c, announcement)
}

// UpdateAnnouncement 更新公告
func (h *SystemHandler) UpdateAnnouncement(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的公告ID", err.Error())
		return
	}

	var req services.AnnouncementRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	userID, _ := middleware.GetCurrentUserID(c)
	// 检查用户是否有管理所有公告的权限
	// 这里简化处理，实际应该通过权限服务检查
	hasAllPermission := true // 暂时设为true，后续可以通过权限服务检查

	announcement, err := h.systemService.UpdateAnnouncement(uint(id), &req, userID, hasAllPermission)
	if err != nil {
		middleware.ValidationErrorResponse(c, "更新公告失败", err.Error())
		return
	}

	middleware.Success(c, announcement)
}

// DeleteAnnouncement 删除公告
func (h *SystemHandler) DeleteAnnouncement(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的公告ID", err.Error())
		return
	}

	userID, _ := middleware.GetCurrentUserID(c)
	// 检查用户是否有管理所有公告的权限
	// 这里简化处理，实际应该通过权限服务检查
	hasAllPermission := true // 暂时设为true，后续可以通过权限服务检查

	err = h.systemService.DeleteAnnouncement(uint(id), userID, hasAllPermission)
	if err != nil {
		middleware.ValidationErrorResponse(c, "删除公告失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "公告删除成功"})
}

// MarkAnnouncementAsViewed 标记公告为已查看
func (h *SystemHandler) MarkAnnouncementAsViewed(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的公告ID", err.Error())
		return
	}

	userID, _ := middleware.GetCurrentUserID(c)
	ipAddress := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	err = h.systemService.MarkAnnouncementAsViewed(uint(id), userID, ipAddress, userAgent)
	if err != nil {
		middleware.ValidationErrorResponse(c, "标记公告查看失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "标记成功"})
}

// GetSystemHealth 获取系统健康状态
func (h *SystemHandler) GetSystemHealth(c *gin.Context) {
	response, err := h.systemService.GetSystemHealth()
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取系统健康状态失败", err.Error())
		return
	}

	middleware.Success(c, response)
}

// GetSystemLogs 获取系统日志
func (h *SystemHandler) GetSystemLogs(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "50"))
	level := c.Query("level")
	category := c.Query("category")

	var startTime, endTime *time.Time
	if startTimeStr := c.Query("start_time"); startTimeStr != "" {
		if t, err := time.Parse(time.RFC3339, startTimeStr); err == nil {
			startTime = &t
		}
	}
	if endTimeStr := c.Query("end_time"); endTimeStr != "" {
		if t, err := time.Parse(time.RFC3339, endTimeStr); err == nil {
			endTime = &t
		}
	}

	response, err := h.systemService.GetSystemLogs(page, pageSize, level, category, startTime, endTime)
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取系统日志失败", err.Error())
		return
	}

	middleware.Success(c, response)
}

// CleanupOldLogs 清理旧日志
func (h *SystemHandler) CleanupOldLogs(c *gin.Context) {
	retentionDays, _ := strconv.Atoi(c.DefaultQuery("retention_days", "30"))

	deletedCount, err := h.systemService.CleanupOldLogs(retentionDays)
	if err != nil {
		middleware.ValidationErrorResponse(c, "清理旧日志失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{
		"message":       "日志清理完成",
		"deleted_count": deletedCount,
	})
}

// DeleteSingleLog 删除单条日志
func (h *SystemHandler) DeleteSingleLog(c *gin.Context) {
	logIDStr := c.Param("id")
	logID, err := strconv.ParseUint(logIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的日志ID", "日志ID必须是有效的数字")
		return
	}

	err = h.systemService.DeleteSingleLog(uint(logID))
	if err != nil {
		middleware.ValidationErrorResponse(c, "删除日志失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{
		"message": "日志删除成功",
	})
}

// BatchDeleteLogs 批量删除日志
func (h *SystemHandler) BatchDeleteLogs(c *gin.Context) {
	var request struct {
		IDs []uint `json:"ids" binding:"required"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	if len(request.IDs) == 0 {
		middleware.ValidationErrorResponse(c, "参数错误", "请提供要删除的日志ID列表")
		return
	}

	// 限制批量删除的数量，避免一次删除过多
	if len(request.IDs) > 1000 {
		middleware.ValidationErrorResponse(c, "参数错误", "一次最多只能删除1000条日志")
		return
	}

	deletedCount, err := h.systemService.BatchDeleteLogs(request.IDs)
	if err != nil {
		middleware.ValidationErrorResponse(c, "批量删除日志失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{
		"message":       "批量删除完成",
		"deleted_count": deletedCount,
	})
}

// GetSystemMetrics 获取系统指标
func (h *SystemHandler) GetSystemMetrics(c *gin.Context) {
	response, err := h.systemService.GetSystemMetrics()
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取系统指标失败", err.Error())
		return
	}

	middleware.Success(c, response)
}

// GetSystemStats 获取系统统计信息
func (h *SystemHandler) GetSystemStats(c *gin.Context) {
	stats, err := h.systemService.GetSystemStats()
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取系统统计信息失败", err.Error())
		return
	}

	middleware.Success(c, stats)
}

// InitializeDefaultConfigs 初始化默认配置
func (h *SystemHandler) InitializeDefaultConfigs(c *gin.Context) {
	userID, _ := middleware.GetCurrentUserID(c)
	count, err := h.systemService.InitializeDefaultConfigs(userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "初始化默认配置失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{
		"message": "默认配置初始化成功",
		"count":   count,
	})
}

// Token管理相关处理器

// CreateToken 创建API Token
func (h *SystemHandler) CreateToken(c *gin.Context) {
	var req services.TokenCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	userID, _ := middleware.GetCurrentUserID(c)
	token, err := h.systemService.CreateToken(&req, userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "创建Token失败", err.Error())
		return
	}

	middleware.Success(c, token)
}

// GetTokens 获取Token列表
func (h *SystemHandler) GetTokens(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	
	var userID uint
	if userIDStr := c.Query("user_id"); userIDStr != "" {
		if id, err := strconv.ParseUint(userIDStr, 10, 32); err == nil {
			userID = uint(id)
		}
	}
	
	status := c.Query("status")

	response, err := h.systemService.GetTokens(page, pageSize, userID, status)
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取Token列表失败", err.Error())
		return
	}

	middleware.Success(c, response)
}

// RenewToken 续期Token
func (h *SystemHandler) RenewToken(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的Token ID", err.Error())
		return
	}

	var req struct {
		ExpiresIn int `json:"expires_in"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		// 如果没有提供过期时间，默认30天
		req.ExpiresIn = 720
	}

	userID, _ := middleware.GetCurrentUserID(c)
	err = h.systemService.RenewToken(uint(id), req.ExpiresIn, userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "续期Token失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "Token续期成功"})
}

// RevokeToken 撤销Token
func (h *SystemHandler) RevokeToken(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的Token ID", err.Error())
		return
	}

	userID, _ := middleware.GetCurrentUserID(c)
	err = h.systemService.RevokeToken(uint(id), userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "撤销Token失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "Token撤销成功"})
}
// DisableToken 禁用Token
func (h *SystemHandler) DisableToken(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的Token ID", err.Error())
		return
	}

	userID, _ := middleware.GetCurrentUserID(c)
	err = h.systemService.DisableToken(uint(id), userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "禁用Token失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "Token禁用成功"})
}

// EnableToken 启用Token
func (h *SystemHandler) EnableToken(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的Token ID", err.Error())
		return
	}

	userID, _ := middleware.GetCurrentUserID(c)
	err = h.systemService.EnableToken(uint(id), userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "启用Token失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "Token启用成功"})
}

// RegenerateToken 重新生成Token
func (h *SystemHandler) RegenerateToken(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的Token ID", err.Error())
		return
	}

	userID, _ := middleware.GetCurrentUserID(c)
	token, err := h.systemService.RegenerateToken(uint(id), userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "重新生成Token失败", err.Error())
		return
	}

	middleware.Success(c, token)
}

// BatchDisableTokens 批量禁用Token
func (h *SystemHandler) BatchDisableTokens(c *gin.Context) {
	var req struct {
		TokenIDs []uint `json:"token_ids" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	userID, _ := middleware.GetCurrentUserID(c)
	err := h.systemService.BatchDisableTokens(req.TokenIDs, userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "批量禁用Token失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "批量禁用成功"})
}

// BatchEnableTokens 批量启用Token
func (h *SystemHandler) BatchEnableTokens(c *gin.Context) {
	var req struct {
		TokenIDs []uint `json:"token_ids" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	userID, _ := middleware.GetCurrentUserID(c)
	err := h.systemService.BatchEnableTokens(req.TokenIDs, userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "批量启用Token失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "批量启用成功"})
}

// BatchRevokeTokens 批量撤销Token
func (h *SystemHandler) BatchRevokeTokens(c *gin.Context) {
	var req struct {
		TokenIDs []uint `json:"token_ids" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	userID, _ := middleware.GetCurrentUserID(c)
	err := h.systemService.BatchRevokeTokens(req.TokenIDs, userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "批量撤销Token失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "批量撤销成功"})
}

// GetTokenUsageStats 获取Token使用统计
func (h *SystemHandler) GetTokenUsageStats(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的Token ID", err.Error())
		return
	}

	stats, err := h.systemService.GetTokenUsageStats(uint(id))
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取Token使用统计失败", err.Error())
		return
	}

	middleware.Success(c, stats)
}

// GetTokenUsageHistory 获取Token使用历史
func (h *SystemHandler) GetTokenUsageHistory(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的Token ID", err.Error())
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	var startTime, endTime *time.Time
	if startTimeStr := c.Query("start_time"); startTimeStr != "" {
		if t, err := time.Parse(time.RFC3339, startTimeStr); err == nil {
			startTime = &t
		}
	}
	if endTimeStr := c.Query("end_time"); endTimeStr != "" {
		if t, err := time.Parse(time.RFC3339, endTimeStr); err == nil {
			endTime = &t
		}
	}

	history, err := h.systemService.GetTokenUsageHistory(uint(id), page, pageSize, startTime, endTime)
	if err != nil {
		middleware.ValidationErrorResponse(c, "获取Token使用历史失败", err.Error())
		return
	}

	middleware.Success(c, history)
}

// GetUsersForToken 获取用于Token创建的用户列表（简化版，不需要管理员权限）
func (h *SystemHandler) GetUsersForToken(c *gin.Context) {
	// 获取当前用户ID，确保用户已登录
	userID, exists := middleware.GetCurrentUserID(c)
	if !exists {
		middleware.AuthorizationErrorResponse(c, "用户未登录")
		return
	}

	// 调用服务获取用户列表
	users, err := h.systemService.GetUsersForToken(userID)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, gin.H{
		"users": users,
	})
}