package services

import (
	"fmt"

	"gorm.io/gorm"

	"info-management-system/internal/models"
)

// TicketService 工单服务
type TicketService struct {
	db            *gorm.DB
	wechatService *WechatService
}

// NewTicketService 创建工单服务
func NewTicketService(db *gorm.DB, wechatService *WechatService) *TicketService {
	return &TicketService{
		db:            db,
		wechatService: wechatService,
	}
}

// GetDB 获取数据库连接
func (s *TicketService) GetDB() *gorm.DB {
	return s.db
}

// CreateTicket 创建工单
func (s *TicketService) CreateTicket(ticket *models.Ticket) error {
	if err := s.db.Create(ticket).Error; err != nil {
		return err
	}

	// 预加载关联数据
	s.db.Preload("Creator").Preload("Assignee").First(ticket, ticket.ID)

	// 发送通知
	go s.sendNotification(ticket, "created")

	return nil
}

// UpdateTicket 更新工单
func (s *TicketService) UpdateTicket(ticket *models.Ticket, updates map[string]interface{}) error {
	oldStatus := ticket.Status
	
	if err := s.db.Model(ticket).Updates(updates).Error; err != nil {
		return err
	}

	// 重新加载数据
	s.db.Preload("Creator").Preload("Assignee").First(ticket, ticket.ID)

	// 检查状态变化并发送通知
	if newStatus, ok := updates["status"]; ok && newStatus != oldStatus {
		go s.sendNotification(ticket, "status_changed")
	} else if _, ok := updates["assigned_to"]; ok {
		go s.sendNotification(ticket, "assigned")
	} else {
		go s.sendNotification(ticket, "updated")
	}

	return nil
}

// GetTicketByID 根据ID获取工单
func (s *TicketService) GetTicketByID(id uint) (*models.Ticket, error) {
	var ticket models.Ticket
	err := s.db.Preload("Creator").Preload("Assignee").
		Preload("Comments", func(db *gorm.DB) *gorm.DB {
			return db.Preload("Creator").Order("created_at ASC")
		}).
		Preload("Attachments", func(db *gorm.DB) *gorm.DB {
			return db.Preload("File").Preload("Uploader")
		}).
		Preload("History", func(db *gorm.DB) *gorm.DB {
			return db.Preload("Creator").Order("created_at DESC")
		}).
		First(&ticket, id).Error

	if err != nil {
		return nil, err
	}

	return &ticket, nil
}

// DeleteTicket 删除工单
func (s *TicketService) DeleteTicket(id uint) error {
	return s.db.Delete(&models.Ticket{}, id).Error
}

// AddComment 添加评论
func (s *TicketService) AddComment(comment *models.TicketComment) error {
	if err := s.db.Create(comment).Error; err != nil {
		return err
	}

	// 预加载关联数据
	s.db.Preload("Creator").First(comment, comment.ID)

	// 获取工单信息并发送通知
	var ticket models.Ticket
	if err := s.db.Preload("Creator").Preload("Assignee").First(&ticket, comment.TicketID).Error; err == nil {
		go s.sendNotification(&ticket, "commented")
	}

	return nil
}

// GetTicketStats 获取工单统计
func (s *TicketService) GetTicketStats() (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	// 总数统计
	var total int64
	s.db.Model(&models.Ticket{}).Count(&total)
	stats["total"] = total

	// 按状态统计
	statusStats := make(map[string]int64)
	statuses := []models.TicketStatus{
		models.TicketStatusSubmitted,
		models.TicketStatusAssigned,
		models.TicketStatusApproved,
		models.TicketStatusInProgress,
		models.TicketStatusPending,
		models.TicketStatusResolved,
		models.TicketStatusClosed,
		models.TicketStatusRejected,
		models.TicketStatusReturned,
	}

	for _, status := range statuses {
		var count int64
		s.db.Model(&models.Ticket{}).Where("status = ?", status).Count(&count)
		statusStats[string(status)] = count
	}
	stats["by_status"] = statusStats

	// 按优先级统计
	priorityStats := make(map[string]int64)
	priorities := []models.TicketPriority{
		models.TicketPriorityLow,
		models.TicketPriorityNormal,
		models.TicketPriorityHigh,
		models.TicketPriorityCritical,
	}

	for _, priority := range priorities {
		var count int64
		s.db.Model(&models.Ticket{}).Where("priority = ?", priority).Count(&count)
		priorityStats[string(priority)] = count
	}
	stats["by_priority"] = priorityStats

	// 按类型统计
	typeStats := make(map[string]int64)
	types := []models.TicketType{
		models.TicketTypeBug,
		models.TicketTypeFeature,
		models.TicketTypeSupport,
		models.TicketTypeChange,
	}

	for _, ticketType := range types {
		var count int64
		s.db.Model(&models.Ticket{}).Where("type = ?", ticketType).Count(&count)
		typeStats[string(ticketType)] = count
	}
	stats["by_type"] = typeStats

	// 过期工单统计
	var overdueCount int64
	s.db.Model(&models.Ticket{}).
		Where("due_date < NOW() AND status NOT IN (?)", 
			[]models.TicketStatus{models.TicketStatusResolved, models.TicketStatusClosed}).
		Count(&overdueCount)
	stats["overdue"] = overdueCount

	return stats, nil
}

// sendNotification 发送通知
func (s *TicketService) sendNotification(ticket *models.Ticket, action string) {
	// 获取企业微信配置
	webhookURL := s.getWechatWebhookURL()
	if webhookURL == "" {
		return // 没有配置企业微信，跳过通知
	}

	// 发送企业微信通知
	if err := s.wechatService.SendTicketNotification(
		webhookURL, 
		"", // token 暂时为空
		ticket.ID, 
		ticket.Title, 
		action, 
		ticket.Description,
	); err != nil {
		// 记录错误日志，但不影响主流程
		fmt.Printf("发送企业微信通知失败: %v\n", err)
	}
}

// getWechatWebhookURL 获取企业微信Webhook URL
func (s *TicketService) getWechatWebhookURL() string {
	// 从数据库配置中获取企业微信Webhook URL
	var config models.Config
	if err := s.db.Where("category = ? AND key = ?", "notification", "wechat_webhook_url").First(&config).Error; err != nil {
		return ""
	}
	return config.Value
}

// InitializeTicketPermissions 初始化工单权限
func (s *TicketService) InitializeTicketPermissions() error {
	permissions := []models.Permission{
		{
			Name:        "ticket:view",
			DisplayName: "查看工单",
			Description: "可以查看工单信息",
			Resource:    "ticket",
			Action:      "view",
			Scope:       "all",
		},
		{
			Name:        "ticket:create",
			DisplayName: "创建工单",
			Description: "可以创建新工单",
			Resource:    "ticket",
			Action:      "create",
			Scope:       "all",
		},
		{
			Name:        "ticket:edit",
			DisplayName: "编辑工单",
			Description: "可以编辑工单信息",
			Resource:    "ticket",
			Action:      "edit",
			Scope:       "all",
		},
		{
			Name:        "ticket:delete",
			DisplayName: "删除工单",
			Description: "可以删除工单",
			Resource:    "ticket",
			Action:      "delete",
			Scope:       "all",
		},
		{
			Name:        "ticket:assign",
			DisplayName: "分配工单",
			Description: "可以将工单分配给其他用户",
			Resource:    "ticket",
			Action:      "assign",
			Scope:       "all",
		},
		{
			Name:        "ticket:view_all",
			DisplayName: "查看所有工单",
			Description: "可以查看系统中的所有工单",
			Resource:    "ticket",
			Action:      "view_all",
			Scope:       "all",
		},
		{
			Name:        "ticket:edit_all",
			DisplayName: "编辑所有工单",
			Description: "可以编辑任何工单",
			Resource:    "ticket",
			Action:      "edit_all",
			Scope:       "all",
		},
		{
			Name:        "ticket:status_all",
			DisplayName: "更新工单状态",
			Description: "可以更新任何工单的状态",
			Resource:    "ticket",
			Action:      "status_all",
			Scope:       "all",
		},
		{
			Name:        "ticket:delete_attachment",
			DisplayName: "删除工单附件",
			Description: "可以删除工单附件",
			Resource:    "ticket",
			Action:      "delete_attachment",
			Scope:       "all",
		},
	}

	for _, permission := range permissions {
		// 检查权限是否已存在
		var existing models.Permission
		if err := s.db.Where("name = ?", permission.Name).First(&existing).Error; err == gorm.ErrRecordNotFound {
			// 权限不存在，创建新权限
			if err := s.db.Create(&permission).Error; err != nil {
				return fmt.Errorf("创建权限 %s 失败: %v", permission.Name, err)
			}
		}
	}

	// 为admin用户分配工单权限
	var adminUser models.User
	if err := s.db.Where("username = ?", "admin").First(&adminUser).Error; err == nil {
		// 获取所有工单权限
		var ticketPermissions []models.Permission
		s.db.Where("resource = ?", "ticket").Find(&ticketPermissions)
		
		// 为admin用户分配权限
		for _, permission := range ticketPermissions {
			var existing models.UserPermission
			if err := s.db.Where("user_id = ? AND permission_id = ?", adminUser.ID, permission.ID).First(&existing).Error; err == gorm.ErrRecordNotFound {
				userPermission := models.UserPermission{
					UserID:       adminUser.ID,
					PermissionID: permission.ID,
				}
				s.db.Create(&userPermission)
			}
		}
	}

	return nil
}

// AssignTicket assigns a ticket to a user
func (s *TicketService) AssignTicket(ticketID, assigneeID, userID uint, reason string) error {
	var ticket models.Ticket
	if err := s.db.First(&ticket, ticketID).Error; err != nil {
		return fmt.Errorf("工单不存在: %w", err)
	}

	// 更新分配人
	updates := map[string]interface{}{
		"assignee_id": assigneeID,
		"status":      "assigned",
	}

	return s.db.Model(&ticket).Updates(updates).Error
}

// RejectTicket 拒绝工单
func (s *TicketService) RejectTicket(ticketID, userID uint, reason string) error {
	var ticket models.Ticket
	if err := s.db.First(&ticket, ticketID).Error; err != nil {
		return fmt.Errorf("工单不存在: %w", err)
	}

	// 更新状态为拒绝
	updates := map[string]interface{}{
		"status": "rejected",
	}

	return s.db.Model(&ticket).Updates(updates).Error
}

// UpdateTicketStatus 更新工单状态
func (s *TicketService) UpdateTicketStatus(ticketID uint, status string, userID uint, comment string) error {
	var ticket models.Ticket
	if err := s.db.First(&ticket, ticketID).Error; err != nil {
		return fmt.Errorf("工单不存在: %w", err)
	}

	// 更新状态
	updates := map[string]interface{}{
		"status": status,
	}

	return s.db.Model(&ticket).Updates(updates).Error
}