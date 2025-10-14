package handlers

import (
	"net/http"
	"strconv"

	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// NotificationHandler 通知处理器
type NotificationHandler struct {
	notificationService *services.NotificationService
}

// NewNotificationHandler 创建通知处理器
func NewNotificationHandler(notificationService *services.NotificationService) *NotificationHandler {
	return &NotificationHandler{
		notificationService: notificationService,
	}
}

// CreateTemplate 创建通知模板
func (h *NotificationHandler) CreateTemplate(c *gin.Context) {
	var req services.NotificationTemplateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	template, err := h.notificationService.CreateTemplate(&req, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "通知模板创建成功",
		"data":    template,
	})
}

// GetTemplates 获取通知模板列表
func (h *NotificationHandler) GetTemplates(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
	templateType := c.Query("type")

	userID := getUserID(c)
	hasAllPermission := hasPermission(c, "notification:template:all")

	templates, err := h.notificationService.GetTemplates(page, pageSize, templateType, userID, hasAllPermission)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "获取通知模板列表成功",
		"data":    templates,
	})
}

// GetTemplate 获取通知模板详情
func (h *NotificationHandler) GetTemplate(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的模板ID"})
		return
	}

	userID := getUserID(c)
	hasAllPermission := hasPermission(c, "notification:template:all")

	template, err := h.notificationService.GetTemplateByID(uint(id), userID, hasAllPermission)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "获取通知模板成功",
		"data":    template,
	})
}

// UpdateTemplate 更新通知模板
func (h *NotificationHandler) UpdateTemplate(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的模板ID"})
		return
	}

	var req services.NotificationTemplateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	hasAllPermission := hasPermission(c, "notification:template:all")

	template, err := h.notificationService.UpdateTemplate(uint(id), &req, userID, hasAllPermission)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "通知模板更新成功",
		"data":    template,
	})
}

// DeleteTemplate 删除通知模板
func (h *NotificationHandler) DeleteTemplate(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的模板ID"})
		return
	}

	userID := getUserID(c)
	hasAllPermission := hasPermission(c, "notification:template:all")

	if err := h.notificationService.DeleteTemplate(uint(id), userID, hasAllPermission); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "通知模板删除成功",
	})
}

// SendNotification 发送通知
func (h *NotificationHandler) SendNotification(c *gin.Context) {
	var req services.NotificationSendRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	notification, err := h.notificationService.SendNotification(&req, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "通知发送成功",
		"data":    notification,
	})
}

// GetNotifications 获取通知历史
func (h *NotificationHandler) GetNotifications(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
	status := c.Query("status")
	notificationType := c.Query("type")

	userID := getUserID(c)
	hasAllPermission := hasPermission(c, "notification:all")

	notifications, err := h.notificationService.GetNotifications(page, pageSize, status, notificationType, userID, hasAllPermission)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "获取通知历史成功",
		"data":    notifications,
	})
}

// CreateAlertRule 创建告警规则
func (h *NotificationHandler) CreateAlertRule(c *gin.Context) {
	var req services.AlertRuleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	rule, err := h.notificationService.CreateAlertRule(&req, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "告警规则创建成功",
		"data":    rule,
	})
}

// GetAlertRules 获取告警规则列表
func (h *NotificationHandler) GetAlertRules(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
	source := c.Query("source")

	userID := getUserID(c)
	hasAllPermission := hasPermission(c, "alert:rule:all")

	rules, err := h.notificationService.GetAlertRules(page, pageSize, source, userID, hasAllPermission)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "获取告警规则列表成功",
		"data":    rules,
	})
}

// ProcessZabbixAlert 处理Zabbix告警
func (h *NotificationHandler) ProcessZabbixAlert(c *gin.Context) {
	var req services.ZabbixAlertRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	event, err := h.notificationService.ProcessZabbixAlert(&req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Zabbix告警处理成功",
		"data":    event,
	})
}

// GetAlertEvents 获取告警事件列表
func (h *NotificationHandler) GetAlertEvents(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
	level := c.Query("level")
	status := c.Query("status")

	userID := getUserID(c)
	hasAllPermission := hasPermission(c, "alert:event:all")

	events, err := h.notificationService.GetAlertEvents(page, pageSize, level, status, userID, hasAllPermission)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "获取告警事件列表成功",
		"data":    events,
	})
}

// CreateNotificationChannel 创建通知渠道
func (h *NotificationHandler) CreateNotificationChannel(c *gin.Context) {
	var req services.NotificationChannelRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	channel, err := h.notificationService.CreateNotificationChannel(&req, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "通知渠道创建成功",
		"data":    channel,
	})
}

// GetNotificationChannels 获取通知渠道列表
func (h *NotificationHandler) GetNotificationChannels(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
	channelType := c.Query("type")

	userID := getUserID(c)
	hasAllPermission := hasPermission(c, "notification:channel:all")

	channels, err := h.notificationService.GetNotificationChannels(page, pageSize, channelType, userID, hasAllPermission)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "获取通知渠道列表成功",
		"data":    channels,
	})
}