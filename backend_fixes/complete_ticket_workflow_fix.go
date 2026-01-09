package handlers

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"info-management-system/internal/models"
	"info-management-system/internal/services"
)

// CompleteTicketWorkflowHandler 完整的工单流程处理器
type CompleteTicketWorkflowHandler struct {
	db                  *gorm.DB
	notificationService *services.NotificationService
}

func NewCompleteTicketWorkflowHandler(db *gorm.DB, notificationService *services.NotificationService) *CompleteTicketWorkflowHandler {
	return &CompleteTicketWorkflowHandler{
		db:                  db,
		notificationService: notificationService,
	}
}

// UpdateTicketStatusFixed 修复的工单状态更新
func (h *CompleteTicketWorkflowHandler) UpdateTicketStatusFixed(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	var req struct {
		Status  string `json:"status" binding:"required"`
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

	// 验证状态值是否有效
	validStatuses := []string{"submitted", "assigned", "accepted", "approved", "progress", "pending", "resolved", "closed", "rejected", "returned"}
	isValidStatus := false
	for _, status := range validStatuses {
		if status == req.Status {
			isValidStatus = true
			break
		}
	}
	if !isValidStatus {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的状态值: " + req.Status})
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
	if !h.isValidStatusTransitionFixed(ticket.Status, models.TicketStatus(req.Status)) {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":          "无效的状态转换",
			"current_status": string(ticket.Status),
			"target_status":  req.Status,
			"allowed_transitions": h.getAllowedTransitions(ticket.Status),
		})
		return
	}

	// 权限检查：特定状态转换需要特定权限
	if !h.checkStatusChangePermission(c, ticket, req.Status, userID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权限执行此状态转换"})
		return
	}

	// 更新状态
	oldStatus := ticket.Status
	ticket.Status = models.TicketStatus(req.Status)

	// 特殊状态处理
	switch req.Status {
	case "progress":
		if ticket.ProcessingStartedAt == nil {
			now := time.Now()
			ticket.ProcessingStartedAt = &now
		}
	case "resolved":
		now := time.Now()
		ticket.ResolvedAt = &now
	case "closed":
		now := time.Now()
		ticket.ClosedAt = &now
	}

	if err := h.db.Save(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "更新工单状态失败"})
		return
	}

	// 记录历史
	historyDesc := fmt.Sprintf("状态: %s -> %s", string(oldStatus), req.Status)
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

// isValidStatusTransitionFixed 修复的状态转换验证
func (h *CompleteTicketWorkflowHandler) isValidStatusTransitionFixed(from, to models.TicketStatus) bool {
	// 定义完整的状态转换规则
	validTransitions := map[models.TicketStatus][]models.TicketStatus{
		models.TicketStatusSubmitted: {
			models.TicketStatusAssigned,
			models.TicketStatusAccepted,  // 允许直接接受
			models.TicketStatusRejected,
		},
		models.TicketStatusAssigned: {
			models.TicketStatusAccepted,
			models.TicketStatusRejected,
			models.TicketStatusReturned,
			models.TicketStatusSubmitted, // 允许退回到提交状态
		},
		models.TicketStatusAccepted: {
			models.TicketStatusApproved,
			models.TicketStatusRejected,
			models.TicketStatusReturned,
			models.TicketStatusInProgress, // 允许直接开始处理
		},
		models.TicketStatusApproved: {
			models.TicketStatusInProgress, // "progress"
			models.TicketStatusReturned,
			models.TicketStatusRejected,
		},
		models.TicketStatusInProgress: {
			models.TicketStatusPending,
			models.TicketStatusResolved,
			models.TicketStatusReturned,
			models.TicketStatusApproved, // 允许退回到审批状态
		},
		models.TicketStatusPending: {
			models.TicketStatusInProgress,
			models.TicketStatusResolved,
			models.TicketStatusReturned,
		},
		models.TicketStatusResolved: {
			models.TicketStatusClosed,
			models.TicketStatusReturned,
			models.TicketStatusInProgress, // 允许重新处理
		},
		models.TicketStatusRejected: {
			models.TicketStatusSubmitted, // 拒绝后可以重新提交
			models.TicketStatusAssigned,  // 允许重新分配
		},
		models.TicketStatusReturned: {
			models.TicketStatusSubmitted, // 退回后可以重新提交
			models.TicketStatusAssigned,  // 允许重新分配
		},
		models.TicketStatusClosed: {
			models.TicketStatusInProgress, // 允许重新打开并处理
			models.TicketStatusSubmitted,  // 允许重新提交
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

// getAllowedTransitions 获取当前状态允许的转换
func (h *CompleteTicketWorkflowHandler) getAllowedTransitions(status models.TicketStatus) []string {
	validTransitions := map[models.TicketStatus][]models.TicketStatus{
		models.TicketStatusSubmitted: {
			models.TicketStatusAssigned,
			models.TicketStatusAccepted,
			models.TicketStatusRejected,
		},
		models.TicketStatusAssigned: {
			models.TicketStatusAccepted,
			models.TicketStatusRejected,
			models.TicketStatusReturned,
			models.TicketStatusSubmitted,
		},
		models.TicketStatusAccepted: {
			models.TicketStatusApproved,
			models.TicketStatusRejected,
			models.TicketStatusReturned,
			models.TicketStatusInProgress,
		},
		models.TicketStatusApproved: {
			models.TicketStatusInProgress,
			models.TicketStatusReturned,
			models.TicketStatusRejected,
		},
		models.TicketStatusInProgress: {
			models.TicketStatusPending,
			models.TicketStatusResolved,
			models.TicketStatusReturned,
			models.TicketStatusApproved,
		},
		models.TicketStatusPending: {
			models.TicketStatusInProgress,
			models.TicketStatusResolved,
			models.TicketStatusReturned,
		},
		models.TicketStatusResolved: {
			models.TicketStatusClosed,
			models.TicketStatusReturned,
			models.TicketStatusInProgress,
		},
		models.TicketStatusRejected: {
			models.TicketStatusSubmitted,
			models.TicketStatusAssigned,
		},
		models.TicketStatusReturned: {
			models.TicketStatusSubmitted,
			models.TicketStatusAssigned,
		},
		models.TicketStatusClosed: {
			models.TicketStatusInProgress,
			models.TicketStatusSubmitted,
		},
	}

	transitions, exists := validTransitions[status]
	if !exists {
		return []string{}
	}

	result := make([]string, len(transitions))
	for i, transition := range transitions {
		result[i] = string(transition)
	}
	return result
}

// checkStatusChangePermission 检查状态变更权限
func (h *CompleteTicketWorkflowHandler) checkStatusChangePermission(c *gin.Context, ticket models.Ticket, targetStatus string, userID uint) bool {
	// 管理员拥有所有权限
	if hasPermission(c, "ticket:admin") || hasPermission(c, "ticket:status") {
		return true
	}

	switch targetStatus {
	case "assigned":
		// 只有管理员或有分配权限的用户可以分配工单
		return hasPermission(c, "ticket:assign")
		
	case "accepted":
		// 只有被分配的用户可以接受工单
		return ticket.AssigneeID != nil && *ticket.AssigneeID == userID
		
	case "approved":
		// 只有有审批权限的用户可以审批
		return hasPermission(c, "ticket:approve")
		
	case "progress":
		// 只有被分配的用户或有处理权限的用户可以开始处理
		return (ticket.AssigneeID != nil && *ticket.AssigneeID == userID) || hasPermission(c, "ticket:process")
		
	case "resolved":
		// 只有被分配的用户或有处理权限的用户可以解决工单
		return (ticket.AssigneeID != nil && *ticket.AssigneeID == userID) || hasPermission(c, "ticket:process")
		
	case "closed":
		// 创建者、被分配者或管理员可以关闭工单
		return ticket.CreatorID == userID || 
			   (ticket.AssigneeID != nil && *ticket.AssigneeID == userID) || 
			   hasPermission(c, "ticket:close")
		
	case "rejected":
		// 有审批权限或被分配的用户可以拒绝
		return hasPermission(c, "ticket:approve") || 
			   (ticket.AssigneeID != nil && *ticket.AssigneeID == userID)
		
	case "returned":
		// 有审批权限的用户可以退回
		return hasPermission(c, "ticket:approve")
		
	case "pending":
		// 被分配的用户可以挂起工单
		return ticket.AssigneeID != nil && *ticket.AssigneeID == userID
		
	case "submitted":
		// 创建者可以重新提交
		return ticket.CreatorID == userID
		
	default:
		return false
	}
}

// AcceptTicketFixed 修复的接受工单
func (h *CompleteTicketWorkflowHandler) AcceptTicketFixed(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	var req struct {
		Comment string `json:"comment"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		// 允许空请求体
		req.Comment = ""
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
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

	// 检查工单状态
	if ticket.Status != models.TicketStatusAssigned {
		c.JSON(http.StatusBadRequest, gin.H{"error": "只能接受已分配的工单"})
		return
	}

	// 检查权限：只有被分配的用户可以接受工单
	if ticket.AssigneeID == nil || *ticket.AssigneeID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "只有被分配的用户可以接受工单"})
		return
	}

	// 更新状态
	ticket.Status = models.TicketStatus(req.Status)
	if err := h.db.Save(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "接受工单失败"})
		return
	}

	// 记录历史
	historyDesc := "工单已接受"
	if req.Comment != "" {
		historyDesc += "，备注：" + req.Comment
	}
	h.addTicketHistory(ticket.ID, userID, "accepted", historyDesc)

	// 发送通知
	go h.sendTicketNotification(&ticket, "accepted", historyDesc)

	// 重新加载完整数据
	h.db.Preload("Creator").Preload("Assignee").First(&ticket, ticket.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    ticket,
	})
}

// RejectTicketFixed 修复的拒绝工单
func (h *CompleteTicketWorkflowHandler) RejectTicketFixed(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	var req struct {
		Reason string `json:"reason" binding:"required"`
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
	err = h.db.First(&ticket, id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	// 检查工单状态
	allowedStatuses := []models.TicketStatus{
		models.TicketStatusAssigned,
		models.TicketStatusAccepted,
		models.TicketStatusApproved,
	}
	
	isAllowed := false
	for _, status := range allowedStatuses {
		if ticket.Status == status {
			isAllowed = true
			break
		}
	}
	
	if !isAllowed {
		c.JSON(http.StatusBadRequest, gin.H{"error": "当前状态不允许拒绝操作"})
		return
	}

	// 检查权限
	canReject := false
	if hasPermission(c, "ticket:approve") {
		canReject = true
	} else if ticket.AssigneeID != nil && *ticket.AssigneeID == userID {
		canReject = true
	}

	if !canReject {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权限拒绝此工单"})
		return
	}

	// 更新状态
	ticket.Status = models.TicketStatusRejected
	if err := h.db.Save(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "拒绝工单失败"})
		return
	}

	// 记录历史
	historyDesc := "工单已拒绝，原因：" + req.Reason
	h.addTicketHistory(ticket.ID, userID, "rejected", historyDesc)

	// 发送通知
	go h.sendTicketNotification(&ticket, "rejected", historyDesc)

	// 重新加载完整数据
	h.db.Preload("Creator").Preload("Assignee").First(&ticket, ticket.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    ticket,
	})
}

// ReopenTicketFixed 修复的重新打开工单
func (h *CompleteTicketWorkflowHandler) ReopenTicketFixed(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	var req struct {
		Comment string `json:"comment"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		req.Comment = ""
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
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

	// 检查工单状态
	if ticket.Status != models.TicketStatusClosed {
		c.JSON(http.StatusBadRequest, gin.H{"error": "只能重新打开已关闭的工单"})
		return
	}

	// 检查权限
	canReopen := false
	if hasPermission(c, "ticket:reopen") {
		canReopen = true
	} else if ticket.CreatorID == userID {
		canReopen = true
	} else if ticket.AssigneeID != nil && *ticket.AssigneeID == userID {
		canReopen = true
	}

	if !canReopen {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权限重新打开此工单"})
		return
	}

	// 更新状态 - 重新打开后回到处理中状态
	ticket.Status = models.TicketStatusInProgress
	ticket.ClosedAt = nil // 清除关闭时间

	if err := h.db.Save(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "重新打开工单失败"})
		return
	}

	// 记录历史
	historyDesc := "工单已重新打开"
	if req.Comment != "" {
		historyDesc += "，备注：" + req.Comment
	}
	h.addTicketHistory(ticket.ID, userID, "reopened", historyDesc)

	// 发送通知
	go h.sendTicketNotification(&ticket, "reopened", historyDesc)

	// 重新加载完整数据
	h.db.Preload("Creator").Preload("Assignee").First(&ticket, ticket.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    ticket,
	})
}

// ResubmitTicketFixed 修复的重新提交工单
func (h *CompleteTicketWorkflowHandler) ResubmitTicketFixed(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的工单ID"})
		return
	}

	var req struct {
		Comment string `json:"comment"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		req.Comment = ""
	}

	userID := getUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
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

	// 检查工单状态
	allowedStatuses := []models.TicketStatus{
		models.TicketStatusRejected,
		models.TicketStatusReturned,
	}
	
	isAllowed := false
	for _, status := range allowedStatuses {
		if ticket.Status == status {
			isAllowed = true
			break
		}
	}
	
	if !isAllowed {
		c.JSON(http.StatusBadRequest, gin.H{"error": "只能重新提交已拒绝或已退回的工单"})
		return
	}

	// 检查权限：只有创建者可以重新提交
	if ticket.CreatorID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "只有工单创建者可以重新提交"})
		return
	}

	// 更新状态
	ticket.Status = models.TicketStatusSubmitted
	if err := h.db.Save(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "重新提交工单失败"})
		return
	}

	// 记录历史
	historyDesc := "工单已重新提交"
	if req.Comment != "" {
		historyDesc += "，备注：" + req.Comment
	}
	h.addTicketHistory(ticket.ID, userID, "resubmitted", historyDesc)

	// 发送通知
	go h.sendTicketNotification(&ticket, "resubmitted", historyDesc)

	// 重新加载完整数据
	h.db.Preload("Creator").Preload("Assignee").First(&ticket, ticket.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    ticket,
	})
}

// GetTicketWorkflowInfo 获取工单流程信息
func (h *CompleteTicketWorkflowHandler) GetTicketWorkflowInfo(c *gin.Context) {
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

	// 查找工单
	var ticket models.Ticket
	err = h.db.Preload("Creator").Preload("Assignee").First(&ticket, id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "工单不存在"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询工单失败"})
		}
		return
	}

	// 获取允许的状态转换
	allowedTransitions := h.getAllowedTransitions(ticket.Status)
	
	// 获取用户可执行的操作
	availableActions := h.getAvailableActions(c, ticket, userID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"ticket":              ticket,
			"current_status":      string(ticket.Status),
			"allowed_transitions": allowedTransitions,
			"available_actions":   availableActions,
		},
	})
}

// getAvailableActions 获取用户可执行的操作
func (h *CompleteTicketWorkflowHandler) getAvailableActions(c *gin.Context, ticket models.Ticket, userID uint) []map[string]interface{} {
	actions := []map[string]interface{}{}

	// 根据当前状态和用户权限确定可用操作
	switch ticket.Status {
	case models.TicketStatusSubmitted:
		if hasPermission(c, "ticket:assign") {
			actions = append(actions, map[string]interface{}{
				"action": "assign",
				"label":  "分配工单",
				"type":   "warning",
			})
		}
		
	case models.TicketStatusAssigned:
		if ticket.AssigneeID != nil && *ticket.AssigneeID == userID {
			actions = append(actions, map[string]interface{}{
				"action": "accept",
				"label":  "接受工单",
				"type":   "success",
			})
			actions = append(actions, map[string]interface{}{
				"action": "reject",
				"label":  "拒绝工单",
				"type":   "danger",
			})
		}
		if hasPermission(c, "ticket:assign") {
			actions = append(actions, map[string]interface{}{
				"action": "reassign",
				"label":  "重新分配",
				"type":   "warning",
			})
		}
		
	case models.TicketStatusAccepted:
		if hasPermission(c, "ticket:approve") {
			actions = append(actions, map[string]interface{}{
				"action": "approve",
				"label":  "审批通过",
				"type":   "primary",
			})
			actions = append(actions, map[string]interface{}{
				"action": "reject",
				"label":  "审批拒绝",
				"type":   "danger",
			})
		}
		if ticket.AssigneeID != nil && *ticket.AssigneeID == userID {
			actions = append(actions, map[string]interface{}{
				"action": "start_progress",
				"label":  "开始处理",
				"type":   "primary",
			})
		}
		
	case models.TicketStatusApproved:
		if ticket.AssigneeID != nil && *ticket.AssigneeID == userID {
			actions = append(actions, map[string]interface{}{
				"action": "start_progress",
				"label":  "开始处理",
				"type":   "primary",
			})
		}
		
	case models.TicketStatusInProgress:
		if ticket.AssigneeID != nil && *ticket.AssigneeID == userID {
			actions = append(actions, map[string]interface{}{
				"action": "pending",
				"label":  "挂起工单",
				"type":   "warning",
			})
			actions = append(actions, map[string]interface{}{
				"action": "resolve",
				"label":  "解决工单",
				"type":   "success",
			})
		}
		
	case models.TicketStatusPending:
		if ticket.AssigneeID != nil && *ticket.AssigneeID == userID {
			actions = append(actions, map[string]interface{}{
				"action": "resume",
				"label":  "继续处理",
				"type":   "primary",
			})
			actions = append(actions, map[string]interface{}{
				"action": "resolve",
				"label":  "解决工单",
				"type":   "success",
			})
		}
		
	case models.TicketStatusResolved:
		if hasPermission(c, "ticket:close") || ticket.CreatorID == userID {
			actions = append(actions, map[string]interface{}{
				"action": "close",
				"label":  "关闭工单",
				"type":   "info",
			})
		}
		
	case models.TicketStatusClosed:
		if hasPermission(c, "ticket:reopen") || ticket.CreatorID == userID || 
		   (ticket.AssigneeID != nil && *ticket.AssigneeID == userID) {
			actions = append(actions, map[string]interface{}{
				"action": "reopen",
				"label":  "重新打开",
				"type":   "warning",
			})
		}
		
	case models.TicketStatusRejected, models.TicketStatusReturned:
		if ticket.CreatorID == userID {
			actions = append(actions, map[string]interface{}{
				"action": "resubmit",
				"label":  "重新提交",
				"type":   "primary",
			})
		}
	}

	return actions
}

// 辅助函数
func (h *CompleteTicketWorkflowHandler) addTicketHistory(ticketID uint, userID uint, action, description string) {
	history := models.TicketHistory{
		TicketID:    ticketID,
		UserID:      userID,
		Action:      action,
		Description: description,
	}
	h.db.Create(&history)
}

func (h *CompleteTicketWorkflowHandler) sendTicketNotification(ticket *models.Ticket, action, description string) {
	if h.notificationService == nil {
		return
	}

	title := "工单通知"
	content := fmt.Sprintf("工单 #%d: %s", ticket.ID, ticket.Title)
	
	switch action {
	case "status_changed":
		content += "\n状态已更新"
	case "accepted":
		content += "\n工单已被接受"
	case "rejected":
		content += "\n工单已被拒绝"
	case "reopened":
		content += "\n工单已重新打开"
	case "resubmitted":
		content += "\n工单已重新提交"
	}

	if description != "" {
		content += "\n" + description
	}

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