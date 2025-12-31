package handlers

import (
	"encoding/csv"
	"fmt"
	"mime/multipart"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"info-management-system/internal/models"
	"info-management-system/internal/services"
)

type TicketHandler struct {
	db                *gorm.DB
	notificationService *services.NotificationService
}

func NewTicketHandler(db *gorm.DB, notificationService *services.NotificationService) *TicketHandler {
	return &TicketHandler{
		db:                db,
		notificationService: notificationService,
	}
}

// GetTickets 获取工单列表
func (h *TicketHandler) GetTickets(c *gin.Context) {
	var query struct {
		Page       int    `form:"page,default=1"`
		Size       int    `form:"size,default=20"`
		Status     string `form:"status"`
		Type       string `form:"type"`
		Priority   string `form:"priority"`
		Keyword    string `form:"keyword"`
		CreatorID  uint   `form:"creator_id"`
		AssigneeID uint   `form:"assignee_id"`
	}

	if err := c.ShouldBindQuery(&query); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 获取当前用户
	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 构建查询
	db := h.db.Model(&models.Ticket{})

	// 权限过滤：只能看到自己创建的或分配给自己的工单，除非有管理权限
	if !hasPermission(c, "ticket:view_all") {
		db = db.Where("creator_id = ? OR assignee_id = ?", userID, userID)
	}

	// 状态过滤
	if query.Status != "" {
		db = db.Where("status = ?", query.Status)
	}

	// 类型过滤
	if query.Type != "" {
		db = db.Where("type = ?", query.Type)
	}

	// 优先级过滤
	if query.Priority != "" {
		db = db.Where("priority = ?", query.Priority)
	}

	// 关键词搜索
	if query.Keyword != "" {
		keyword := "%" + strings.ToLower(query.Keyword) + "%"
		db = db.Where("LOWER(title) LIKE ? OR LOWER(description) LIKE ?", keyword, keyword)
	}

	// 创建人过滤
	if query.CreatorID > 0 {
		db = db.Where("creator_id = ?", query.CreatorID)
	}

	// 处理人过滤
	if query.AssigneeID > 0 {
		db = db.Where("assignee_id = ?", query.AssigneeID)
	}

	// 获取总数 - 优化：只在第一页或需要精确计数时执行
	var total int64
	if query.Page == 1 {
		// 创建一个新的查询来计算总数，避免影响主查询
		countDB := h.db.Model(&models.Ticket{})
		
		// 应用相同的权限过滤
		if !hasPermission(c, "ticket:view_all") {
			countDB = countDB.Where("creator_id = ? OR assignee_id = ?", userID, userID)
		}
		
		// 应用相同的筛选条件
		if query.Status != "" {
			countDB = countDB.Where("status = ?", query.Status)
		}
		if query.Type != "" {
			countDB = countDB.Where("type = ?", query.Type)
		}
		if query.Priority != "" {
			countDB = countDB.Where("priority = ?", query.Priority)
		}
		if query.Keyword != "" {
			keyword := "%" + strings.ToLower(query.Keyword) + "%"
			countDB = countDB.Where("LOWER(title) LIKE ? OR LOWER(description) LIKE ?", keyword, keyword)
		}
		if query.CreatorID > 0 {
			countDB = countDB.Where("creator_id = ?", query.CreatorID)
		}
		if query.AssigneeID > 0 {
			countDB = countDB.Where("assignee_id = ?", query.AssigneeID)
		}
		
		countDB.Count(&total)
	} else {
		// 对于非第一页，使用估算值以提高性能
		total = int64(query.Page * query.Size)
	}

	// 分页查询
	var tickets []models.Ticket
	offset := (query.Page - 1) * query.Size
	err := db.Preload("Creator").Preload("Assignee").
		Order("created_at DESC").
		Offset(offset).Limit(query.Size).
		Find(&tickets).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		return
	}

	// 获取统计数据
	stats := h.getTicketStats(userID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"items": tickets,
			"total": total,
			"page":  query.Page,
			"size":  query.Size,
			"stats": stats,
		},
	})
}

// GetTicket 获取工单详情
func (h *TicketHandler) GetTicket(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	var ticket models.Ticket
	query := h.db.Preload("Creator").Preload("Assignee").
		Preload("Comments", func(db *gorm.DB) *gorm.DB {
			return db.Preload("User").Order("created_at ASC")
		}).
		Preload("Attachments").
		Preload("History", func(db *gorm.DB) *gorm.DB {
			return db.Preload("User").Order("created_at ASC")
		})

	// 权限检查
	if !hasPermission(c, "ticket:view_all") {
		query = query.Where("creator_id = ? OR assignee_id = ?", userID, userID)
	}

	err = query.First(&ticket, id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    ticket,
	})
}

// CreateTicket 创建工单
func (h *TicketHandler) CreateTicket(c *gin.Context) {
	var req struct {
		Title       string `json:"title" binding:"required,max=500"`
		Description string `json:"description" binding:"required"`
		Type        string `json:"type" binding:"required,oneof=bug feature support change custom"`
		Priority    string `json:"priority" binding:"required,oneof=low normal high critical"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	ticket := models.Ticket{
		Title:       req.Title,
		Description: req.Description,
		Type:        models.TicketType(req.Type),
		Priority:    models.TicketPriority(req.Priority),
		Status:      models.TicketStatusSubmitted, // 新工单默认为"已提交"状态
		CreatorID:   userID,
	}

	if err := h.db.Create(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "创建工单失败"})
		return
	}

	// 自动分配逻辑 - 根据工单类型分配给固定角色
	go h.autoAssignTicket(&ticket)

	// 记录历史
	h.addTicketHistory(ticket.ID, userID, "created", "工单已创建")

	// 发送通知
	go h.sendTicketNotification(&ticket, "created", "")

	// 重新加载完整数据
	h.db.Preload("Creator").Preload("Assignee").First(&ticket, ticket.ID)

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    ticket,
	})
}

// UpdateTicket 更新工单
func (h *TicketHandler) UpdateTicket(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	var req struct {
		Title       *string `json:"title,omitempty"`
		Description *string `json:"description,omitempty"`
		Type        *string `json:"type,omitempty"`
		Priority    *string `json:"priority,omitempty"`
		Status      *string `json:"status,omitempty"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 查找工单
	var ticket models.Ticket
	query := h.db
	if !hasPermission(c, "ticket:update") && hasPermission(c, "ticket:update_own") {
		query = query.Where("creator_id = ?", userID)
	} else if !hasPermission(c, "ticket:update") && !hasPermission(c, "ticket:update_own") {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权限编辑工单"})
		return
	}

	err = query.First(&ticket, id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在或无权限"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	// 记录变更
	changes := []string{}

	// 更新字段
	if req.Title != nil && *req.Title != ticket.Title {
		changes = append(changes, "标题: "+ticket.Title+" -> "+*req.Title)
		ticket.Title = *req.Title
	}

	if req.Description != nil && *req.Description != ticket.Description {
		changes = append(changes, "描述已更新")
		ticket.Description = *req.Description
	}

	if req.Type != nil && *req.Type != string(ticket.Type) {
		changes = append(changes, "类型: "+string(ticket.Type)+" -> "+*req.Type)
		ticket.Type = models.TicketType(*req.Type)
	}

	if req.Priority != nil && *req.Priority != string(ticket.Priority) {
		changes = append(changes, "优先级: "+string(ticket.Priority)+" -> "+*req.Priority)
		ticket.Priority = models.TicketPriority(*req.Priority)
	}

	if req.Status != nil && *req.Status != string(ticket.Status) {
		changes = append(changes, "状态: "+string(ticket.Status)+" -> "+*req.Status)
		ticket.Status = models.TicketStatus(*req.Status)
	}

	if len(changes) == 0 {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data":    ticket,
		})
		return
	}

	// 保存更新
	if err := h.db.Save(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "更新工单失败"})
		return
	}

	// 记录历史
	changeDesc := strings.Join(changes, "; ")
	h.addTicketHistory(ticket.ID, userID, "updated", changeDesc)

	// 发送通知
	go h.sendTicketNotification(&ticket, "updated", changeDesc)

	// 重新加载完整数据
	h.db.Preload("Creator").Preload("Assignee").First(&ticket, ticket.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    ticket,
	})
}

// DeleteTicket 删除工单
func (h *TicketHandler) DeleteTicket(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 检查权限
	if !hasPermission(c, "ticket:delete") && !hasPermission(c, "ticket:delete_own") {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权限删除工单"})
		return
	}

	// 查找工单
	var ticket models.Ticket
	query := h.db
	
	// 如果只有delete_own权限，只能删除自己创建的工单
	if !hasPermission(c, "ticket:delete") && hasPermission(c, "ticket:delete_own") {
		query = query.Where("creator_id = ?", userID)
	}
	
	err = query.First(&ticket, id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	// 删除工单（软删除）
	if err := h.db.Delete(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "删除工单失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "工单删除成功",
	})
}

// AssignTicket 分配工单
func (h *TicketHandler) AssignTicket(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	var req struct {
		AssigneeID uint   `json:"assignee_id" binding:"required"`
		Comment    string `json:"comment"`
		AutoAccept bool   `json:"auto_accept"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 检查权限
	if !hasPermission(c, "ticket:assign") {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权限分配工单"})
		return
	}

	// 查找工单
	var ticket models.Ticket
	err = h.db.First(&ticket, id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	// 验证处理人存在
	var assignee models.User
	if err := h.db.First(&assignee, req.AssigneeID).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "指定的处理人不存在"})
		return
	}

	// 更新工单
	ticket.AssigneeID = &req.AssigneeID
	if ticket.Status == models.TicketStatusSubmitted {
		if req.AutoAccept {
			ticket.Status = models.TicketStatusAccepted
		} else {
			ticket.Status = models.TicketStatusAssigned
		}
	}

	if err := h.db.Save(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "分配工单失败"})
		return
	}

	// 记录历史
	historyDesc := "工单已分配给 " + assignee.Username
	if req.AutoAccept {
		historyDesc += " 并自动接受"
	}
	if req.Comment != "" {
		historyDesc += "，备注：" + req.Comment
	}
	h.addTicketHistory(ticket.ID, userID, "assigned", historyDesc)

	// 如果是自动接受，再记录一条接受历史
	if req.AutoAccept {
		h.addTicketHistory(ticket.ID, req.AssigneeID, "accept", "工单已自动接受")
	}

	// 发送通知
	go h.sendTicketNotification(&ticket, "assigned", historyDesc)

	// 重新加载完整数据
	h.db.Preload("Creator").Preload("Assignee").First(&ticket, ticket.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    ticket,
	})
}

// UpdateTicketStatus 更新工单状态
func (h *TicketHandler) UpdateTicketStatus(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	var req struct {
		Status  string `json:"status" binding:"required,oneof=submitted assigned accepted approved progress pending resolved closed rejected returned"`
		Comment string `json:"comment"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 查找工单
	var ticket models.Ticket
	query := h.db
	if !hasPermission(c, "ticket:status") {
		query = query.Where("creator_id = ? OR assignee_id = ?", userID, userID)
	}

	err = query.First(&ticket, id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在或无权限"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	// 验证状态转换是否合法
	if !isValidStatusTransition(ticket.Status, models.TicketStatus(req.Status)) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的状态转换"})
		return
	}

	// 更新状态
	oldStatus := ticket.Status
	ticket.Status = models.TicketStatus(req.Status)

	// 特殊状态处理
	if req.Status == "approved" {
		// 审批通过后自动进入处理阶段
		go func() {
			time.Sleep(1 * time.Second) // 延迟1秒后自动处理
			now := time.Now()
			ticket.Status = models.TicketStatusInProgress
			ticket.ProcessingStartedAt = &now
			h.db.Save(&ticket)
			
			// 记录历史
			h.addTicketHistory(ticket.ID, userID, "auto_processing", "工单审批通过后自动进入处理阶段")
		}()
	} else if req.Status == "progress" && ticket.ProcessingStartedAt == nil {
		// 手动进入处理阶段时记录开始时间
		now := time.Now()
		ticket.ProcessingStartedAt = &now
	}

	if err := h.db.Save(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "更新工单状态失败"})
		return
	}

	// 记录历史
	historyDesc := "状态: " + string(oldStatus) + " -> " + req.Status
	if req.Comment != "" {
		historyDesc += "，备注：" + req.Comment
	}
	h.addTicketHistory(ticket.ID, userID, "status_changed", historyDesc)

	// 发送通知
	go h.sendTicketNotification(&ticket, "status_changed", historyDesc)

	// 重新加载完整数据
	h.db.Preload("Creator").Preload("Assignee").First(&ticket, ticket.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    ticket,
	})
}

// GetTicketStatistics 获取工单统计
func (h *TicketHandler) GetTicketStatistics(c *gin.Context) {
	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	stats := h.getTicketStats(userID)
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    stats,
	})
}

// 辅助方法
func (h *TicketHandler) getTicketStats(userID uint) map[string]interface{} {
	stats := make(map[string]interface{})

	// 使用单个查询获取所有统计数据，避免多次查询
	var results []struct {
		Status string
		Count  int64
	}

	// 构建基础查询条件
	baseCondition := "creator_id = ? OR assignee_id = ?"
	
	// 使用GROUP BY一次性获取所有状态统计
	err := h.db.Model(&models.Ticket{}).
		Select("status, COUNT(*) as count").
		Where(baseCondition, userID, userID).
		Group("status").
		Find(&results).Error
	
	if err != nil {
		// 如果查询失败，返回空统计
		return map[string]interface{}{
			"total":    int64(0),
			"status":   make(map[string]int64),
			"type":     make(map[string]int64),
			"priority": make(map[string]int64),
		}
	}

	// 处理状态统计
	statusStats := make(map[string]int64)
	var total int64
	
	// 初始化所有状态为0
	statuses := []string{"submitted", "assigned", "approved", "progress", "pending", "resolved", "closed", "rejected", "returned"}
	for _, status := range statuses {
		statusStats[status] = 0
	}
	
	// 填充实际数据
	for _, result := range results {
		statusStats[result.Status] = result.Count
		total += result.Count
	}
	
	stats["total"] = total
	stats["status"] = statusStats

	// 类型统计 - 使用类似的优化方式
	var typeResults []struct {
		Type  string
		Count int64
	}
	
	err = h.db.Model(&models.Ticket{}).
		Select("type, COUNT(*) as count").
		Where(baseCondition, userID, userID).
		Group("type").
		Find(&typeResults).Error
	
	typeStats := make(map[string]int64)
	types := []string{"bug", "feature", "support", "change"}
	for _, ticketType := range types {
		typeStats[ticketType] = 0
	}
	
	if err == nil {
		for _, result := range typeResults {
			typeStats[result.Type] = result.Count
		}
	}
	stats["type"] = typeStats

	// 优先级统计
	var priorityResults []struct {
		Priority string
		Count    int64
	}
	
	err = h.db.Model(&models.Ticket{}).
		Select("priority, COUNT(*) as count").
		Where(baseCondition, userID, userID).
		Group("priority").
		Find(&priorityResults).Error
	
	priorityStats := make(map[string]int64)
	priorities := []string{"low", "normal", "high", "critical"}
	for _, priority := range priorities {
		priorityStats[priority] = 0
	}
	
	if err == nil {
		for _, result := range priorityResults {
			priorityStats[result.Priority] = result.Count
		}
	}
	stats["priority"] = priorityStats

	return stats
}

// isValidStatusTransition 验证状态转换是否合法
func isValidStatusTransition(from, to models.TicketStatus) bool {
	// 定义合法的状态转换
	validTransitions := map[models.TicketStatus][]models.TicketStatus{
		models.TicketStatusSubmitted: {
			models.TicketStatusAssigned,
			models.TicketStatusAccepted,  // 允许直接从提交状态到接受状态（用于自动接受）
			models.TicketStatusRejected,
		},
		models.TicketStatusAssigned: {
			models.TicketStatusAccepted,
			models.TicketStatusRejected,
			models.TicketStatusReturned,
		},
		models.TicketStatusAccepted: {
			models.TicketStatusApproved,
			models.TicketStatusRejected,
			models.TicketStatusReturned,
		},
		models.TicketStatusApproved: {
			models.TicketStatusInProgress,
			models.TicketStatusReturned,
		},
		models.TicketStatusInProgress: {
			models.TicketStatusPending,
			models.TicketStatusResolved,
			models.TicketStatusReturned,
		},
		models.TicketStatusPending: {
			models.TicketStatusInProgress,
			models.TicketStatusResolved,
		},
		models.TicketStatusResolved: {
			models.TicketStatusClosed,
			models.TicketStatusReturned,
		},
		models.TicketStatusRejected: {
			models.TicketStatusSubmitted, // 拒绝后可以重新提交
		},
		models.TicketStatusReturned: {
			models.TicketStatusSubmitted, // 退回后可以重新提交
		},
		models.TicketStatusClosed: {
			// 已关闭的工单一般不允许再次更改状态
		},
	}

	allowedTransitions, exists := validTransitions[from]
	if !exists {
		return false
	}

	for _, allowed := range allowedTransitions {
		if allowed == to {
			return true
		}
	}

	return false
}

// autoAssignTicket 自动分配工单
func (h *TicketHandler) autoAssignTicket(ticket *models.Ticket) {
	// 根据工单类型自动分配给相应角色的用户
	var assigneeRole string
	var defaultAssigneeID uint
	
	switch ticket.Type {
	case models.TicketTypeBug:
		assigneeRole = "developer" // 故障报告分配给开发人员
		defaultAssigneeID = 2 // 假设用户ID 2是开发人员
	case models.TicketTypeFeature:
		assigneeRole = "product_manager" // 功能请求分配给产品经理
		defaultAssigneeID = 1 // 假设用户ID 1是产品经理
	case models.TicketTypeSupport:
		assigneeRole = "support" // 技术支持分配给支持人员
		defaultAssigneeID = 1 // 假设用户ID 1是支持人员
	case models.TicketTypeChange:
		assigneeRole = "admin" // 变更请求分配给管理员
		defaultAssigneeID = 1 // 假设用户ID 1是管理员
	case models.TicketTypeCustom:
		assigneeRole = "admin" // 自定义请求分配给管理员
		defaultAssigneeID = 1 // 假设用户ID 1是管理员
	default:
		assigneeRole = "admin" // 默认分配给管理员
		defaultAssigneeID = 1
	}

	// 查找具有相应角色的用户
	// TODO: 实际实现应该根据用户角色表查找，这里简化处理
	var assignee models.User
	err := h.db.Where("id = ?", defaultAssigneeID).First(&assignee).Error
	if err != nil {
		// 如果指定用户不存在，尝试分配给管理员（ID=1）
		err = h.db.Where("id = ?", 1).First(&assignee).Error
		if err != nil {
			// 记录日志：无法找到合适的处理人员
			return
		}
	}

	// 更新工单分配
	ticket.AssigneeID = &assignee.ID
	ticket.Status = models.TicketStatusAssigned
	ticket.AutoAssignRole = assigneeRole // 记录分配的角色
	h.db.Save(ticket)

	// 记录历史
	h.addTicketHistory(ticket.ID, assignee.ID, "auto_assigned", "工单已自动分配给 "+assignee.Username+" (角色: "+assigneeRole+")")

	// 发送通知
	go h.sendTicketNotification(ticket, "auto_assigned", "工单已自动分配")
}

// autoProcessApprovedTickets 自动处理已审批的工单
func (h *TicketHandler) autoProcessApprovedTickets() {
	var tickets []models.Ticket
	h.db.Where("status = ?", models.TicketStatusApproved).Find(&tickets)

	for _, ticket := range tickets {
		// 自动进入处理阶段
		now := time.Now()
		ticket.Status = models.TicketStatusInProgress
		ticket.ProcessingStartedAt = &now
		h.db.Save(&ticket)

		// 记录历史
		h.addTicketHistory(ticket.ID, 0, "auto_processing", "工单已自动进入处理阶段")

		// 发送通知
		go h.sendTicketNotification(&ticket, "auto_processing", "工单已自动进入处理阶段")
	}
}

// checkProcessingTimeout 检查处理超时的工单
func (h *TicketHandler) checkProcessingTimeout() {
	var tickets []models.Ticket
	h.db.Where("status = ? AND processing_started_at IS NOT NULL", models.TicketStatusInProgress).Find(&tickets)

	for _, ticket := range tickets {
		if ticket.ProcessingStartedAt != nil {
			timeout := time.Duration(ticket.ProcessingTimeout) * time.Hour
			if time.Since(*ticket.ProcessingStartedAt) > timeout {
				// 超时自动关闭
				now := time.Now()
				ticket.Status = models.TicketStatusClosed
				ticket.ClosedAt = &now
				h.db.Save(&ticket)

				// 记录历史
				h.addTicketHistory(ticket.ID, 0, "auto_closed", "工单因处理超时已自动关闭")

				// 发送通知
				go h.sendTicketNotification(&ticket, "auto_closed", "工单因处理超时已自动关闭")
			}
		}
	}
}

// GetTicketCategories 获取工单类型列表
func (h *TicketHandler) GetTicketCategories(c *gin.Context) {
	// 返回默认类型和自定义类型
	defaultTypes := []map[string]interface{}{
		{"value": "bug", "label": "故障报告", "color": "#f56c6c"},
		{"value": "feature", "label": "功能请求", "color": "#67c23a"},
		{"value": "support", "label": "技术支持", "color": "#409eff"},
		{"value": "change", "label": "变更请求", "color": "#e6a23c"},
		{"value": "custom", "label": "自定义请求", "color": "#909399"},
	}

	// 查询自定义类型
	var customCategories []models.TicketCategory
	h.db.Where("is_active = ?", true).Find(&customCategories)

	var customTypes []map[string]interface{}
	for _, category := range customCategories {
		customTypes = append(customTypes, map[string]interface{}{
			"value":        category.Name,
			"label":        category.DisplayName,
			"color":        category.Color,
			"description":  category.Description,
			"customFields": category.CustomFields,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"default": defaultTypes,
			"custom":  customTypes,
		},
	})
}

// GetAssignmentRules 获取自动分配规则
func (h *TicketHandler) GetAssignmentRules(c *gin.Context) {
	rules := map[string]interface{}{
		"bug": map[string]interface{}{
			"role": "developer",
			"assignee_id": 2,
			"assignee_name": "开发人员",
		},
		"feature": map[string]interface{}{
			"role": "product_manager", 
			"assignee_id": 1,
			"assignee_name": "产品经理",
		},
		"support": map[string]interface{}{
			"role": "support",
			"assignee_id": 1,
			"assignee_name": "技术支持",
		},
		"change": map[string]interface{}{
			"role": "admin",
			"assignee_id": 1,
			"assignee_name": "系统管理员",
		},
		"custom": map[string]interface{}{
			"role": "admin",
			"assignee_id": 1,
			"assignee_name": "系统管理员",
		},
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    rules,
	})
}

// UpdateAssignmentRules 更新自动分配规则
func (h *TicketHandler) UpdateAssignmentRules(c *gin.Context) {
	var req map[string]interface{}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: 实际实现应该将规则保存到数据库
	// 这里简化处理，返回成功
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "分配规则更新成功",
	})
}

func (h *TicketHandler) addTicketHistory(ticketID uint, userID uint, action, description string) {
	history := models.TicketHistory{
		TicketID:    ticketID,
		UserID:      userID,
		Action:      action,
		Description: description,
	}
	h.db.Create(&history)
}

func (h *TicketHandler) sendTicketNotification(ticket *models.Ticket, action, description string) {
	if h.notificationService == nil {
		return
	}

	// 构建通知内容
	title := "工单通知"
	content := ""

	switch action {
	case "created":
		content = "新工单已创建：" + ticket.Title
	case "assigned":
		content = "工单已分配：" + ticket.Title
	case "status_changed":
		content = "工单状态已更新：" + ticket.Title
	case "updated":
		content = "工单已更新：" + ticket.Title
	}

	if description != "" {
		content += "\n" + description
	}

	// 发送给相关人员
	recipients := []uint{}
	if ticket.CreatorID > 0 {
		recipients = append(recipients, ticket.CreatorID)
	}
	if ticket.AssigneeID != nil && *ticket.AssigneeID > 0 {
		recipients = append(recipients, *ticket.AssigneeID)
	}

	for _, recipientID := range recipients {
		h.notificationService.SendSimpleNotification(recipientID, title, content, "ticket")
	}
}

// GetTicketComments 获取工单评论
func (h *TicketHandler) GetTicketComments(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 检查工单访问权限
	var ticket models.Ticket
	query := h.db
	if !hasPermission(c, "ticket:view_all") {
		query = query.Where("creator_id = ? OR assignee_id = ?", userID, userID)
	}

	err = query.First(&ticket, id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在或无权限"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	// 获取评论
	var comments []models.TicketComment
	err = h.db.Preload("User").Where("ticket_id = ?", id).
		Order("created_at ASC").Find(&comments).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询评论失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    comments,
	})
}

// AddTicketComment 添加工单评论
func (h *TicketHandler) AddTicketComment(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	var req struct {
		Content  string `json:"content" binding:"required"`
		IsPublic *bool  `json:"is_public"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 检查工单访问权限
	var ticket models.Ticket
	query := h.db
	if !hasPermission(c, "ticket:view_all") {
		query = query.Where("creator_id = ? OR assignee_id = ?", userID, userID)
	}

	err = query.First(&ticket, id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在或无权限"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	// 创建评论
	comment := models.TicketComment{
		TicketID: uint(id),
		UserID:   userID,
		Content:  req.Content,
		IsPublic: true,
	}

	if req.IsPublic != nil {
		comment.IsPublic = *req.IsPublic
	}

	if err := h.db.Create(&comment).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "添加评论失败"})
		return
	}

	// 记录历史
	h.addTicketHistory(uint(id), userID, "commented", "添加了评论")

	// 发送通知
	go h.sendTicketNotification(&ticket, "commented", "工单有新评论")

	// 重新加载完整数据
	h.db.Preload("User").First(&comment, comment.ID)

	c.JSON(http.StatusCreated, comment)
}

// GetTicketHistory 获取工单历史
func (h *TicketHandler) GetTicketHistory(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 检查工单访问权限
	var ticket models.Ticket
	query := h.db
	if !hasPermission(c, "ticket:view_all") {
		query = query.Where("creator_id = ? OR assignee_id = ?", userID, userID)
	}

	err = query.First(&ticket, id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在或无权限"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	// 获取历史记录
	var history []models.TicketHistory
	err = h.db.Preload("User").Where("ticket_id = ?", id).
		Order("created_at ASC").Find(&history).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询历史记录失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    history,
	})
}

// UploadTicketAttachment 上传工单附件
func (h *TicketHandler) UploadTicketAttachment(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 检查工单访问权限
	var ticket models.Ticket
	query := h.db
	if !hasPermission(c, "ticket:view_all") {
		query = query.Where("creator_id = ? OR assignee_id = ?", userID, userID)
	}

	err = query.First(&ticket, id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在或无权限"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	// 处理文件上传
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "获取上传文件失败"})
		return
	}
	defer file.Close()

	// 这里应该调用文件服务来处理文件上传
	// 为了简化，我们假设有一个文件服务
	// fileService := services.NewFileService(h.db)
	// uploadedFile, err := fileService.UploadFile(file, header, userID)
	// if err != nil {
	//     c.JSON(http.StatusInternalServerError, gin.H{"error": "文件上传失败"})
	//     return
	// }

	// 创建附件记录（这里简化处理）
	attachment := models.TicketAttachment{
		TicketID:     uint(id),
		FileName:     header.Filename,
		FileSize:     header.Size,
		ContentType:  header.Header.Get("Content-Type"),
		UploadedBy:   userID,
	}

	if err := h.db.Create(&attachment).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "保存附件记录失败"})
		return
	}

	// 记录历史
	h.addTicketHistory(uint(id), userID, "attachment_added", "上传了附件："+header.Filename)

	c.JSON(http.StatusCreated, attachment)
}

// DeleteTicketAttachment 删除工单附件
func (h *TicketHandler) DeleteTicketAttachment(c *gin.Context) {
	ticketID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	attachmentID, err := strconv.ParseUint(c.Param("attachment_id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的附件ID"})
		return
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 检查工单访问权限
	var ticket models.Ticket
	query := h.db
	if !hasPermission(c, "ticket:view_all") {
		query = query.Where("creator_id = ? OR assignee_id = ?", userID, userID)
	}

	err = query.First(&ticket, ticketID).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在或无权限"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	// 查找附件
	var attachment models.TicketAttachment
	err = h.db.Where("id = ? AND ticket_id = ?", attachmentID, ticketID).First(&attachment).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "附件不存在"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询附件失败"})
		}
		return
	}

	// 检查删除权限（只有上传者或管理员可以删除）
	if attachment.UploadedBy != userID && !hasPermission(c, "ticket:delete_attachment") {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权限删除此附件"})
		return
	}

	// 删除附件记录
	if err := h.db.Delete(&attachment).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "删除附件失败"})
		return
	}

	// 记录历史
	h.addTicketHistory(uint(ticketID), userID, "attachment_deleted", "删除了附件："+attachment.FileName)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "附件删除成功",
	})
}

// AcceptTicket 接受工单
func (h *TicketHandler) AcceptTicket(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	var req struct {
		Comment string `json:"comment"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		// 如果没有请求体，也允许
		req.Comment = ""
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 查找工单
	var ticket models.Ticket
	err = h.db.Where("id = ? AND assignee_id = ?", id, userID).First(&ticket).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在或无权限"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	// 检查工单状态
	if ticket.Status != models.TicketStatusAssigned {
		c.JSON(http.StatusBadRequest, gin.H{"error": "只能接受已分配的工单"})
		return
	}

	// 更新状态为已接受
	ticket.Status = models.TicketStatusAccepted

	if err := h.db.Save(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "接受工单失败"})
		return
	}

	// 添加历史记录
	h.addTicketHistory(ticket.ID, userID, "accept", "工单已接受"+func() string {
		if req.Comment != "" {
			return "：" + req.Comment
		}
		return ""
	}())

	// 重新加载工单数据
	h.db.Preload("Creator").Preload("Assignee").First(&ticket, ticket.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    ticket,
		"message": "工单接受成功",
	})
}

// RejectTicket 拒绝工单
func (h *TicketHandler) RejectTicket(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	var req struct {
		Comment string `json:"comment"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		// 如果没有请求体，也允许
		req.Comment = ""
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 检查权限
	if !hasPermission(c, "ticket:reject") {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权限拒绝工单"})
		return
	}

	// 查找工单
	var ticket models.Ticket
	query := h.db
	if !hasPermission(c, "ticket:reject_all") {
		// 如果没有全局拒绝权限，只能拒绝分配给自己的工单
		query = query.Where("assignee_id = ?", userID)
	}
	
	err = query.First(&ticket, id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在或无权限"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	// 检查工单状态 - 允许拒绝已分配或已接受的工单
	if ticket.Status != models.TicketStatusAssigned && ticket.Status != models.TicketStatusAccepted {
		c.JSON(http.StatusBadRequest, gin.H{"error": "只能拒绝已分配或已接受的工单"})
		return
	}

	// 更新状态为已拒绝
	ticket.Status = models.TicketStatusRejected

	if err := h.db.Save(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "拒绝工单失败"})
		return
	}

	// 添加历史记录
	h.addTicketHistory(ticket.ID, userID, "reject", "工单已拒绝"+func() string {
		if req.Comment != "" {
			return "：" + req.Comment
		}
		return ""
	}())

	// 发送通知
	go h.sendTicketNotification(&ticket, "rejected", "工单已被拒绝")

	// 重新加载工单数据
	h.db.Preload("Creator").Preload("Assignee").First(&ticket, ticket.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    ticket,
		"message": "工单拒绝成功",
	})
}

// ReopenTicket 重新打开工单
func (h *TicketHandler) ReopenTicket(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	var req struct {
		Comment string `json:"comment"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		// 如果没有请求体，也允许
		req.Comment = ""
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 查找工单
	var ticket models.Ticket
	query := h.db
	if !hasPermission(c, "ticket:reopen_all") {
		query = query.Where("creator_id = ? OR assignee_id = ?", userID, userID)
	}

	err = query.First(&ticket, id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在或无权限"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	// 检查工单状态
	if ticket.Status != models.TicketStatusClosed {
		c.JSON(http.StatusBadRequest, gin.H{"error": "只能重新打开已关闭的工单"})
		return
	}

	// 更新状态为已提交
	ticket.Status = models.TicketStatusSubmitted
	// 清除关闭时间
	ticket.ClosedAt = nil

	if err := h.db.Save(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "重新打开工单失败"})
		return
	}

	// 添加历史记录
	h.addTicketHistory(ticket.ID, userID, "reopen", "工单已重新打开"+func() string {
		if req.Comment != "" {
			return "：" + req.Comment
		}
		return ""
	}())

	// 重新加载工单数据
	h.db.Preload("Creator").Preload("Assignee").First(&ticket, ticket.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    ticket,
		"message": "工单重新打开成功",
	})
}

// ResubmitTicket 重新提交工单
func (h *TicketHandler) ResubmitTicket(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	var req struct {
		Comment string `json:"comment"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		// 如果没有请求体，也允许
		req.Comment = ""
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 查找工单
	var ticket models.Ticket
	query := h.db
	if !hasPermission(c, "ticket:resubmit_all") {
		query = query.Where("creator_id = ?", userID)
	}

	err = query.First(&ticket, id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在或无权限"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	// 检查工单状态
	if ticket.Status != models.TicketStatusRejected && ticket.Status != models.TicketStatusReturned {
		c.JSON(http.StatusBadRequest, gin.H{"error": "只能重新提交已拒绝或已退回的工单"})
		return
	}

	// 更新状态为已提交
	ticket.Status = models.TicketStatusSubmitted
	// 清除分配信息
	ticket.AssigneeID = nil

	if err := h.db.Save(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "重新提交工单失败"})
		return
	}

	// 添加历史记录
	h.addTicketHistory(ticket.ID, userID, "resubmit", "工单已重新提交"+func() string {
		if req.Comment != "" {
			return "：" + req.Comment
		}
		return ""
	}())

	// 重新加载工单数据
	h.db.Preload("Creator").Preload("Assignee").First(&ticket, ticket.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    ticket,
		"message": "工单重新提交成功",
	})
}

// ExportTickets 导出工单
func (h *TicketHandler) ExportTickets(c *gin.Context) {
	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 检查权限
	if !hasPermission(c, "ticket:export") {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权限导出工单"})
		return
	}

	// 获取查询参数
	var query struct {
		Keyword    string `form:"keyword"`
		Status     string `form:"status"`
		Type       string `form:"type"`
		Priority   string `form:"priority"`
		CreatorID  uint   `form:"creator_id"`
		AssigneeID uint   `form:"assignee_id"`
		Format     string `form:"format,default=xlsx"`
	}

	if err := c.ShouldBindQuery(&query); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 构建查询条件
	db := h.db.Model(&models.Ticket{}).Preload("Creator").Preload("Assignee")

	// 权限过滤
	if !hasPermission(c, "ticket:read_all") {
		db = db.Where("creator_id = ? OR assignee_id = ?", userID, userID)
	}

	// 应用筛选条件
	if query.Keyword != "" {
		db = db.Where("title LIKE ? OR description LIKE ?", "%"+query.Keyword+"%", "%"+query.Keyword+"%")
	}
	if query.Status != "" {
		db = db.Where("status = ?", query.Status)
	}
	if query.Type != "" {
		db = db.Where("type = ?", query.Type)
	}
	if query.Priority != "" {
		db = db.Where("priority = ?", query.Priority)
	}
	if query.CreatorID != 0 {
		db = db.Where("creator_id = ?", query.CreatorID)
	}
	if query.AssigneeID != 0 {
		db = db.Where("assignee_id = ?", query.AssigneeID)
	}

	// 查询工单
	var tickets []models.Ticket
	if err := db.Find(&tickets).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		return
	}

	// 根据格式生成内容
	var content []byte
	var filename string
	var contentType string

	if query.Format == "xlsx" {
		// 对于xlsx请求，我们返回CSV内容但使用Excel兼容的格式
		csvContent := "ID,标题,类型,状态,优先级,创建人,处理人,创建时间,更新时间,描述\n"
		for _, ticket := range tickets {
			creatorName := ""
			if ticket.Creator.ID != 0 {
				creatorName = ticket.Creator.Username
			}
			assigneeName := ""
			if ticket.Assignee != nil {
				assigneeName = ticket.Assignee.Username
			}

			// 转换状态和类型为中文
			statusLabel := getStatusLabel(string(ticket.Status))
			typeLabel := getTypeLabel(string(ticket.Type))
			priorityLabel := getPriorityLabel(string(ticket.Priority))

			csvContent += fmt.Sprintf("%d,\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n",
				ticket.ID,
				ticket.Title,
				typeLabel,
				statusLabel,
				priorityLabel,
				creatorName,
				assigneeName,
				ticket.CreatedAt.Format("2006-01-02 15:04:05"),
				ticket.UpdatedAt.Format("2006-01-02 15:04:05"),
				strings.ReplaceAll(ticket.Description, "\"", "\"\""), // 转义双引号
			)
		}

		// 添加BOM以支持Excel正确显示中文
		bomBytes := []byte{0xEF, 0xBB, 0xBF}
		csvBytes := []byte(csvContent)
		content = append(bomBytes, csvBytes...)
		filename = fmt.Sprintf("tickets_export_%s.csv", time.Now().Format("20060102_150405"))
		contentType = "text/csv; charset=utf-8"
	} else {
		// CSV格式
		csvContent := "ID,标题,类型,状态,优先级,创建人,处理人,创建时间,更新时间,描述\n"
		for _, ticket := range tickets {
			creatorName := ""
			if ticket.Creator.ID != 0 {
				creatorName = ticket.Creator.Username
			}
			assigneeName := ""
			if ticket.Assignee != nil {
				assigneeName = ticket.Assignee.Username
			}

			// 转换状态和类型为中文
			statusLabel := getStatusLabel(string(ticket.Status))
			typeLabel := getTypeLabel(string(ticket.Type))
			priorityLabel := getPriorityLabel(string(ticket.Priority))

			csvContent += fmt.Sprintf("%d,\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n",
				ticket.ID,
				ticket.Title,
				typeLabel,
				statusLabel,
				priorityLabel,
				creatorName,
				assigneeName,
				ticket.CreatedAt.Format("2006-01-02 15:04:05"),
				ticket.UpdatedAt.Format("2006-01-02 15:04:05"),
				strings.ReplaceAll(ticket.Description, "\"", "\"\""), // 转义双引号
			)
		}

		// 添加BOM以支持Excel正确显示中文
		bomBytes := []byte{0xEF, 0xBB, 0xBF}
		csvBytes := []byte(csvContent)
		content = append(bomBytes, csvBytes...)
		filename = fmt.Sprintf("tickets_export_%s.csv", time.Now().Format("20060102_150405"))
		contentType = "text/csv; charset=utf-8"
	}

	// 设置响应头
	c.Header("Content-Type", contentType)
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", filename))
	c.Header("Content-Length", fmt.Sprintf("%d", len(content)))

	// 写入完整内容
	c.Data(http.StatusOK, contentType, content)
}

// ImportTickets 导入工单
func (h *TicketHandler) ImportTickets(c *gin.Context) {
	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	// 检查权限
	if !hasPermission(c, "ticket:import") {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权限导入工单"})
		return
	}

	// 获取上传的文件
	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "获取上传文件失败"})
		return
	}

	// 检查文件大小（限制10MB）
	if file.Size > 10*1024*1024 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "文件大小不能超过10MB"})
		return
	}

	// 检查文件类型
	ext := strings.ToLower(filepath.Ext(file.Filename))
	if ext != ".csv" && ext != ".xlsx" && ext != ".xls" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "只支持CSV、XLSX、XLS格式文件"})
		return
	}

	// 打开文件
	src, err := file.Open()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "打开文件失败"})
		return
	}
	defer src.Close()

	var importedCount int
	var errors []string

	if ext == ".csv" {
		importedCount, errors = h.importFromCSV(src, userID)
	} else {
		// 对于Excel文件，暂时返回不支持的错误
		c.JSON(http.StatusBadRequest, gin.H{"error": "暂不支持Excel格式，请使用CSV格式"})
		return
	}

	if len(errors) > 0 {
		c.JSON(http.StatusPartialContent, gin.H{
			"success": true,
			"data": gin.H{
				"count":  importedCount,
				"errors": errors,
			},
			"message": fmt.Sprintf("部分导入成功，共导入%d条工单，%d条失败", importedCount, len(errors)),
		})
	} else {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data": gin.H{
				"count": importedCount,
			},
			"message": fmt.Sprintf("导入成功，共导入%d条工单", importedCount),
		})
	}
}

// importFromCSV 从CSV文件导入工单
func (h *TicketHandler) importFromCSV(src multipart.File, userID uint) (int, []string) {
	reader := csv.NewReader(src)
	records, err := reader.ReadAll()
	if err != nil {
		return 0, []string{"读取CSV文件失败: " + err.Error()}
	}

	if len(records) < 2 {
		return 0, []string{"CSV文件格式错误，至少需要标题行和一行数据"}
	}

	var importedCount int
	var errors []string

	// 跳过标题行
	for i, record := range records[1:] {
		if len(record) < 4 { // 至少需要标题、类型、优先级、描述
			errors = append(errors, fmt.Sprintf("第%d行：数据列数不足", i+2))
			continue
		}

		// 解析数据
		title := strings.TrimSpace(record[0])
		ticketType := strings.TrimSpace(record[1])
		priority := strings.TrimSpace(record[2])
		description := strings.TrimSpace(record[3])

		if title == "" {
			errors = append(errors, fmt.Sprintf("第%d行：标题不能为空", i+2))
			continue
		}

		// 转换类型和优先级
		var modelType models.TicketType
		var modelPriority models.TicketPriority

		switch ticketType {
		case "故障", "bug":
			modelType = models.TicketTypeBug
		case "需求", "feature":
			modelType = models.TicketTypeFeature
		case "支持", "support":
			modelType = models.TicketTypeSupport
		case "维护", "change":
			modelType = models.TicketTypeChange
		case "自定义", "custom":
			modelType = models.TicketTypeCustom
		default:
			modelType = models.TicketTypeBug // 默认为故障
		}

		switch priority {
		case "低", "low":
			modelPriority = models.TicketPriorityLow
		case "普通", "normal":
			modelPriority = models.TicketPriorityNormal
		case "高", "high":
			modelPriority = models.TicketPriorityHigh
		case "紧急", "严重", "critical":
			modelPriority = models.TicketPriorityCritical
		default:
			modelPriority = models.TicketPriorityNormal // 默认为普通
		}

		// 创建工单
		ticket := models.Ticket{
			Title:       title,
			Description: description,
			Type:        modelType,
			Priority:    modelPriority,
			Status:      models.TicketStatusSubmitted,
			CreatorID:   userID,
		}

		if err := h.db.Create(&ticket).Error; err != nil {
			errors = append(errors, fmt.Sprintf("第%d行：创建工单失败 - %s", i+2, err.Error()))
			continue
		}

		// 记录历史
		h.addTicketHistory(ticket.ID, userID, "created", "工单通过导入创建")
		importedCount++
	}

	return importedCount, errors
}

// 辅助函数：获取状态标签
func getStatusLabel(status string) string {
	statusMap := map[string]string{
		"submitted": "已提交",
		"assigned":  "已分配",
		"accepted":  "已接受",
		"approved":  "已审批",
		"progress":  "处理中",
		"pending":   "挂起",
		"resolved":  "已解决",
		"closed":    "已关闭",
		"rejected":  "已拒绝",
		"returned":  "已退回",
	}
	if label, ok := statusMap[status]; ok {
		return label
	}
	return status
}

// 辅助函数：获取类型标签
func getTypeLabel(ticketType string) string {
	typeMap := map[string]string{
		"bug":         "故障",
		"feature":     "需求",
		"support":     "支持",
		"maintenance": "维护",
	}
	if label, ok := typeMap[ticketType]; ok {
		return label
	}
	return ticketType
}

// 辅助函数：获取优先级标签
func getPriorityLabel(priority string) string {
	priorityMap := map[string]string{
		"low":      "低",
		"normal":   "普通",
		"high":     "高",
		"urgent":   "紧急",
		"critical": "严重",
	}
	if label, ok := priorityMap[priority]; ok {
		return label
	}
	return priority
}