package handlers

import (
	"strconv"

	"info-management-system/internal/middleware"
	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// AuditHandler 审计处理器
type AuditHandler struct {
	auditService *services.AuditService
}

// NewAuditHandler 创建审计处理器
func NewAuditHandler(auditService *services.AuditService) *AuditHandler {
	return &AuditHandler{
		auditService: auditService,
	}
}

// GetAuditLogs 获取审计日志列表
// @Summary 获取审计日志列表
// @Description 获取系统审计日志，支持多种过滤条件
// @Tags 审计管理
// @Accept json
// @Produce json
// @Param user_id query int false "用户ID"
// @Param action query string false "操作类型"
// @Param resource_type query string false "资源类型"
// @Param resource_id query int false "资源ID"
// @Param start_date query string false "开始日期 (YYYY-MM-DD)"
// @Param end_date query string false "结束日期 (YYYY-MM-DD)"
// @Param page query int false "页码" default(1)
// @Param page_size query int false "每页数量" default(20)
// @Success 200 {object} APIResponse{data=services.AuditLogListResponse}
// @Failure 400 {object} APIResponse
// @Failure 401 {object} APIResponse
// @Failure 403 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Security BearerAuth
// @Router /api/v1/audit/logs [get]
func (h *AuditHandler) GetAuditLogs(c *gin.Context) {
	var query services.AuditLogQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	logs, err := h.auditService.GetAuditLogs(&query)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, logs)
}

// GetResourceAuditLogs 获取特定资源的审计日志
// @Summary 获取特定资源的审计日志
// @Description 获取指定资源的所有操作历史
// @Tags 审计管理
// @Accept json
// @Produce json
// @Param resource_type path string true "资源类型"
// @Param resource_id path int true "资源ID"
// @Success 200 {object} APIResponse{data=[]services.AuditLogResponse}
// @Failure 400 {object} APIResponse
// @Failure 401 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Security BearerAuth
// @Router /api/v1/audit/resources/{resource_type}/{resource_id} [get]
func (h *AuditHandler) GetResourceAuditLogs(c *gin.Context) {
	resourceType := c.Param("resource_type")
	resourceIDStr := c.Param("resource_id")

	resourceID, err := strconv.ParseUint(resourceIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的资源ID", "")
		return
	}

	logs, err := h.auditService.GetResourceAuditLogs(resourceType, uint(resourceID))
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, logs)
}

// GetUserAuditLogs 获取用户的审计日志
// @Summary 获取用户的审计日志
// @Description 获取指定用户的操作历史
// @Tags 审计管理
// @Accept json
// @Produce json
// @Param user_id path int true "用户ID"
// @Param limit query int false "限制数量" default(100)
// @Success 200 {object} APIResponse{data=[]services.AuditLogResponse}
// @Failure 400 {object} APIResponse
// @Failure 401 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Security BearerAuth
// @Router /api/v1/audit/users/{user_id} [get]
func (h *AuditHandler) GetUserAuditLogs(c *gin.Context) {
	userIDStr := c.Param("user_id")
	userID, err := strconv.ParseUint(userIDStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的用户ID", "")
		return
	}

	limitStr := c.DefaultQuery("limit", "100")
	limit, err := strconv.Atoi(limitStr)
	if err != nil {
		limit = 100
	}

	logs, err := h.auditService.GetUserAuditLogs(uint(userID), limit)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, logs)
}

// GetAuditStatistics 获取审计统计信息
// @Summary 获取审计统计信息
// @Description 获取系统审计统计数据
// @Tags 审计管理
// @Accept json
// @Produce json
// @Param days query int false "统计天数" default(30)
// @Success 200 {object} APIResponse{data=map[string]interface{}}
// @Failure 400 {object} APIResponse
// @Failure 401 {object} APIResponse
// @Failure 403 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Security BearerAuth
// @Router /api/v1/audit/statistics [get]
func (h *AuditHandler) GetAuditStatistics(c *gin.Context) {
	daysStr := c.DefaultQuery("days", "30")
	days, err := strconv.Atoi(daysStr)
	if err != nil || days <= 0 {
		days = 30
	}

	// 限制最大查询天数
	if days > 365 {
		days = 365
	}

	statistics, err := h.auditService.GetAuditStatistics(days)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, statistics)
}

// CleanupOldAuditLogs 清理旧的审计日志
// @Summary 清理旧的审计日志
// @Description 清理指定天数之前的审计日志
// @Tags 审计管理
// @Accept json
// @Produce json
// @Param retention_days query int false "保留天数" default(90)
// @Success 200 {object} APIResponse{data=map[string]interface{}}
// @Failure 400 {object} APIResponse
// @Failure 401 {object} APIResponse
// @Failure 403 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Security BearerAuth
// @Router /api/v1/audit/cleanup [post]
func (h *AuditHandler) CleanupOldAuditLogs(c *gin.Context) {
	retentionDaysStr := c.DefaultQuery("retention_days", "90")
	retentionDays, err := strconv.Atoi(retentionDaysStr)
	if err != nil || retentionDays <= 0 {
		retentionDays = 90
	}

	// 最少保留7天的日志
	if retentionDays < 7 {
		retentionDays = 7
	}

	deletedCount, err := h.auditService.CleanupOldAuditLogs(retentionDays)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, gin.H{
		"message":        "审计日志清理完成",
		"deleted_count":  deletedCount,
		"retention_days": retentionDays,
	})
}