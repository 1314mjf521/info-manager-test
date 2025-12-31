package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"info-management-system/internal/app/services"
	"info-management-system/internal/models"
)

// TicketHandler 工单处理器
type TicketHandler struct {
	ticketService *services.TicketService
}

// NewTicketHandler 创建工单处理器
func NewTicketHandler(ticketService *services.TicketService) *TicketHandler {
	return &TicketHandler{ticketService: ticketService}
}

// CreateTicket 创建工单
func (h *TicketHandler) CreateTicket(c *gin.Context) {
	var req struct {
		Title       string                  `json:"title" binding:"required,max=500"`
		Description string                  `json:"description"`
		Type        models.TicketType       `json:"type" binding:"required"`
		Priority    models.TicketPriority   `json:"priority"`
		Category    string                  `json:"category"`
		Tags        []string                `json:"tags"`
		AssignedTo  *uint                   `json:"assigned_to"`
		DueDate     *time.Time              `json:"due_date"`
		Metadata    map[string]interface{}  `json:"metadata"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	
	ticket := models.Ticket{
		Title:       req.Title,
		Description: req.Description,
		Type:        req.Type,
		Priority:    req.Priority,
		Category:    req.Category,
		Tags:        models.StringSlice(req.Tags),
		CreatedBy:   userID,
		AssignedTo:  req.AssignedTo,
		DueDate:     req.DueDate,
		Metadata:    models.JSONB(req.Metadata),
	}

	if err := h.ticketService.CreateTicket(&ticket); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "创建工单失败"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    ticket,
		"message": "工单创建成功",
	})
}

// GetTickets 获取工单列表
func (h *TicketHandler) GetTickets(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if pageSize > 100 {
		pageSize = 100
	}

	// 构建查询
	db := h.ticketService.GetDB().Model(&models.Ticket{})

	// 过滤条件
	if status := c.Query("status"); status != "" {
		db = db.Where("status = ?", status)
	}
	if ticketType := c.Query("type"); ticketType != "" {
		db = db.Where("type = ?", ticketType)
	}
	if priority := c.Query("priority"); priority != "" {
		db = db.Where("priority = ?", priority)
	}
	if category := c.Query("category"); category != "" {
		db = db.Where("category = ?", category)
	}
	if assignedTo := c.Query("assigned_to"); assignedTo != "" {
		db = db.Where("assigned_to = ?", assignedTo)
	}
	if createdBy := c.Query("created_by"); createdBy != "" {
		db = db.Where("created_by = ?", createdBy)
	}
	if search := c.Query("search"); search != "" {
		db = db.Where("title LIKE ? OR description LIKE ?", "%"+search+"%", "%"+search+"%")
	}

	// 排序
	sort := c.DefaultQuery("sort", "created_at")
	order := c.DefaultQuery("order", "desc")
	db = db.Order(sort + " " + order)

	// 分页
	var total int64
	db.Count(&total)

	var tickets []models.Ticket
	offset := (page - 1) * pageSize
	err := db.Preload("Creator").Preload("Assignee").
		Offset(offset).Limit(pageSize).Find(&tickets).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取工单列表失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"items":       tickets,
			"total":       total,
			"page":        page,
			"page_size":   pageSize,
			"total_pages": (total + int64(pageSize) - 1) / int64(pageSize),
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

	ticket, err := h.ticketService.GetTicketByID(uint(id))
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "获取工单详情失败"})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{
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
		Title       *string                 `json:"title"`
		Description *string                 `json:"description"`
		Type        *models.TicketType      `json:"type"`
		Status      *models.TicketStatus    `json:"status"`
		Priority    *models.TicketPriority  `json:"priority"`
		Category    *string                 `json:"category"`
		Tags        *[]string               `json:"tags"`
		AssignedTo  *uint                   `json:"assigned_to"`
		DueDate     *time.Time              `json:"due_date"`
		Metadata    *map[string]interface{} `json:"metadata"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ticket, err := h.ticketService.GetTicketByID(uint(id))
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "获取工单失败"})
		}
		return
	}

	updates := make(map[string]interface{})

	// 构建更新字段
	if req.Title != nil {
		updates["title"] = *req.Title
	}
	if req.Description != nil {
		updates["description"] = *req.Description
	}
	if req.Type != nil {
		updates["type"] = *req.Type
	}
	if req.Status != nil {
		updates["status"] = *req.Status
	}
	if req.Priority != nil {
		updates["priority"] = *req.Priority
	}
	if req.Category != nil {
		updates["category"] = *req.Category
	}
	if req.Tags != nil {
		updates["tags"] = models.StringSlice(*req.Tags)
	}
	if req.AssignedTo != nil {
		if *req.AssignedTo == 0 {
			updates["assigned_to"] = nil
		} else {
			updates["assigned_to"] = *req.AssignedTo
		}
	}
	if req.DueDate != nil {
		updates["due_date"] = *req.DueDate
	}
	if req.Metadata != nil {
		updates["metadata"] = models.JSONB(*req.Metadata)
	}

	if len(updates) > 0 {
		if err := h.ticketService.UpdateTicket(ticket, updates); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "更新工单失败"})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    ticket,
		"message": "工单更新成功",
	})
}

// DeleteTicket 删除工单
func (h *TicketHandler) DeleteTicket(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	if err := h.ticketService.DeleteTicket(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "删除工单失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "工单删除成功",
	})
}

// AddComment 添加评论
func (h *TicketHandler) AddComment(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	var req struct {
		Content  string `json:"content" binding:"required"`
		IsPublic bool   `json:"is_public"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	
	comment := models.TicketComment{
		TicketID:  uint(id),
		Content:   req.Content,
		IsPublic:  req.IsPublic,
		CreatedBy: userID,
	}

	if err := h.ticketService.AddComment(&comment); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "添加评论失败"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    comment,
		"message": "评论添加成功",
	})
}

// GetTicketStats 获取工单统计
func (h *TicketHandler) GetTicketStats(c *gin.Context) {
	stats, err := h.ticketService.GetTicketStats()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取工单统计失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    stats,
	})
}

// getUserID 从上下文获取用户ID
func getUserID(c *gin.Context) uint {
	if userID, exists := c.Get("user_id"); exists {
		if id, ok := userID.(uint); ok {
			return id
		}
	}
	return 0
}