package handlers

import (
	"net/http"
	"strconv"
	"time"

	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// AIHandler AI处理器
type AIHandler struct {
	aiService *services.AIService
}

// NewAIHandler 创建AI处理器
func NewAIHandler(aiService *services.AIService) *AIHandler {
	return &AIHandler{
		aiService: aiService,
	}
}

// CreateConfig 创建AI配置
func (h *AIHandler) CreateConfig(c *gin.Context) {
	var req services.AIConfigRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	config, err := h.aiService.CreateConfig(&req, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "AI配置创建成功",
		"data":    config,
	})
}

// GetConfigs 获取AI配置列表
func (h *AIHandler) GetConfigs(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
	provider := c.Query("provider")

	userID := getUserID(c)
	hasAllPermission := hasPermission(c, "ai:config:all")

	configs, err := h.aiService.GetConfigs(page, pageSize, provider, userID, hasAllPermission)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "获取AI配置列表成功",
		"data":    configs,
	})
}

// GetConfig 获取AI配置详情
func (h *AIHandler) GetConfig(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的配置ID"})
		return
	}

	userID := getUserID(c)
	hasAllPermission := hasPermission(c, "ai:config:all")

	config, err := h.aiService.GetConfigByID(uint(id), userID, hasAllPermission)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "获取AI配置成功",
		"data":    config,
	})
}

// UpdateConfig 更新AI配置
func (h *AIHandler) UpdateConfig(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的配置ID"})
		return
	}

	var req services.AIConfigRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	hasAllPermission := hasPermission(c, "ai:config:all")

	config, err := h.aiService.UpdateConfig(uint(id), &req, userID, hasAllPermission)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "AI配置更新成功",
		"data":    config,
	})
}

// DeleteConfig 删除AI配置
func (h *AIHandler) DeleteConfig(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的配置ID"})
		return
	}

	userID := getUserID(c)
	hasAllPermission := hasPermission(c, "ai:config:all")

	if err := h.aiService.DeleteConfig(uint(id), userID, hasAllPermission); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "AI配置删除成功",
	})
}

// OptimizeRecord 优化记录
func (h *AIHandler) OptimizeRecord(c *gin.Context) {
	var req services.RecordOptimizeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	task, err := h.aiService.OptimizeRecord(&req, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "记录优化任务创建成功",
		"data":    task,
	})
}

// SpeechToText 语音识别
func (h *AIHandler) SpeechToText(c *gin.Context) {
	var req services.SpeechToTextRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	task, err := h.aiService.SpeechToText(&req, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "语音识别任务创建成功",
		"data":    task,
	})
}

// Chat AI聊天
func (h *AIHandler) Chat(c *gin.Context) {
	var req services.AIChatRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	session, err := h.aiService.Chat(&req, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "AI聊天处理成功",
		"data":    session,
	})
}

// GetTasks 获取AI任务列表
func (h *AIHandler) GetTasks(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
	taskType := c.Query("type")
	status := c.Query("status")

	userID := getUserID(c)
	hasAllPermission := hasPermission(c, "ai:task:all")

	tasks, err := h.aiService.GetTasks(page, pageSize, taskType, status, userID, hasAllPermission)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "获取AI任务列表成功",
		"data":    tasks,
	})
}

// GetChatSessions 获取聊天会话列表
func (h *AIHandler) GetChatSessions(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))

	userID := getUserID(c)
	sessions, err := h.aiService.GetChatSessions(page, pageSize, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "获取聊天会话列表成功",
		"data":    sessions,
	})
}

// GetUsageStats 获取使用统计
func (h *AIHandler) GetUsageStats(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")
	taskType := c.Query("type")

	var startDate, endDate time.Time
	var err error

	if startDateStr != "" {
		startDate, err = time.Parse("2006-01-02", startDateStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "无效的开始日期格式"})
			return
		}
	}

	if endDateStr != "" {
		endDate, err = time.Parse("2006-01-02", endDateStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "无效的结束日期格式"})
			return
		}
	}

	userID := getUserID(c)
	stats, err := h.aiService.GetUsageStats(userID, startDate, endDate, taskType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "获取使用统计成功",
		"data":    stats,
	})
}

// HealthCheck 健康检查
func (h *AIHandler) HealthCheck(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的配置ID"})
		return
	}

	healthCheck, err := h.aiService.HealthCheck(uint(id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "健康检查完成",
		"data":    healthCheck,
	})
}