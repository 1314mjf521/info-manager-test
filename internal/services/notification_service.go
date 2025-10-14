package services

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"info-management-system/internal/models"

	"gorm.io/gorm"
)

// NotificationService 通知服务
type NotificationService struct {
	db *gorm.DB
}

// NewNotificationService 创建通知服务
func NewNotificationService(db *gorm.DB) *NotificationService {
	return &NotificationService{
		db: db,
	}
}

// 通知模板相关请求结构
type NotificationTemplateRequest struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
	Type        string `json:"type" binding:"required,oneof=email wechat sms"`
	Subject     string `json:"subject"`
	Content     string `json:"content" binding:"required"`
	Variables   string `json:"variables"`
	IsActive    bool   `json:"is_active"`
}

// 通知发送请求结构
type NotificationSendRequest struct {
	TemplateID *uint                  `json:"template_id"`
	Type       string                 `json:"type" binding:"required,oneof=email wechat sms"`
	Channel    string                 `json:"channel"`
	Recipients []string               `json:"recipients" binding:"required"`
	Subject    string                 `json:"subject"`
	Content    string                 `json:"content"`
	Variables  map[string]interface{} `json:"variables"`
	Priority   int                    `json:"priority"`
	ScheduledAt *time.Time            `json:"scheduled_at"`
}

// 通知渠道配置请求结构
type NotificationChannelRequest struct {
	Name        string                 `json:"name" binding:"required"`
	Type        string                 `json:"type" binding:"required,oneof=email wechat sms"`
	Config      map[string]interface{} `json:"config" binding:"required"`
	IsActive    bool                   `json:"is_active"`
	IsDefault   bool                   `json:"is_default"`
	Description string                 `json:"description"`
}

// 告警规则请求结构
type AlertRuleRequest struct {
	Name        string                 `json:"name" binding:"required"`
	Description string                 `json:"description"`
	Source      string                 `json:"source" binding:"required,oneof=zabbix prometheus custom"`
	Conditions  map[string]interface{} `json:"conditions" binding:"required"`
	Actions     map[string]interface{} `json:"actions" binding:"required"`
	IsActive    bool                   `json:"is_active"`
	Priority    int                    `json:"priority"`
	Cooldown    int                    `json:"cooldown"`
}

// Zabbix告警请求结构
type ZabbixAlertRequest struct {
	EventID     string                 `json:"event_id" binding:"required"`
	Level       string                 `json:"level" binding:"required,oneof=info warning error critical"`
	Title       string                 `json:"title" binding:"required"`
	Message     string                 `json:"message" binding:"required"`
	Data        map[string]interface{} `json:"data"`
	Timestamp   *time.Time             `json:"timestamp"`
}

// 响应结构
type NotificationTemplateListResponse struct {
	Templates []models.NotificationTemplate `json:"templates"`
	Total     int64                         `json:"total"`
	Page      int                           `json:"page"`
	PageSize  int                           `json:"page_size"`
}

type NotificationListResponse struct {
	Notifications []models.Notification `json:"notifications"`
	Total         int64                 `json:"total"`
	Page          int                   `json:"page"`
	PageSize      int                   `json:"page_size"`
}

type NotificationChannelListResponse struct {
	Channels []models.NotificationChannel `json:"channels"`
	Total    int64                        `json:"total"`
	Page     int                          `json:"page"`
	PageSize int                          `json:"page_size"`
}

type AlertRuleListResponse struct {
	Rules    []models.AlertRule `json:"rules"`
	Total    int64              `json:"total"`
	Page     int                `json:"page"`
	PageSize int                `json:"page_size"`
}

type AlertEventListResponse struct {
	Events   []models.AlertEvent `json:"events"`
	Total    int64               `json:"total"`
	Page     int                 `json:"page"`
	PageSize int                 `json:"page_size"`
}

// CreateTemplate 创建通知模板
func (s *NotificationService) CreateTemplate(req *NotificationTemplateRequest, userID uint) (*models.NotificationTemplate, error) {
	template := &models.NotificationTemplate{
		Name:        req.Name,
		Description: req.Description,
		Type:        req.Type,
		Subject:     req.Subject,
		Content:     req.Content,
		Variables:   req.Variables,
		IsActive:    req.IsActive,
		CreatedBy:   userID,
	}

	if err := s.db.Create(template).Error; err != nil {
		return nil, fmt.Errorf("创建通知模板失败: %v", err)
	}

	// 预加载关联数据
	if err := s.db.Preload("Creator").First(template, template.ID).Error; err != nil {
		return nil, fmt.Errorf("获取通知模板失败: %v", err)
	}

	return template, nil
}

// GetTemplates 获取通知模板列表
func (s *NotificationService) GetTemplates(page, pageSize int, templateType string, userID uint, hasAllPermission bool) (*NotificationTemplateListResponse, error) {
	var templates []models.NotificationTemplate
	var total int64

	query := s.db.Model(&models.NotificationTemplate{})

	// 类型过滤
	if templateType != "" {
		query = query.Where("type = ?", templateType)
	}

	// 权限控制
	if !hasAllPermission {
		query = query.Where("created_by = ? OR is_system = ?", userID, true)
	}

	// 计算总数
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取模板总数失败: %v", err)
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Preload("Creator").
		Offset(offset).
		Limit(pageSize).
		Order("created_at DESC").
		Find(&templates).Error; err != nil {
		return nil, fmt.Errorf("获取模板列表失败: %v", err)
	}

	return &NotificationTemplateListResponse{
		Templates: templates,
		Total:     total,
		Page:      page,
		PageSize:  pageSize,
	}, nil
}

// GetTemplateByID 根据ID获取通知模板
func (s *NotificationService) GetTemplateByID(id, userID uint, hasAllPermission bool) (*models.NotificationTemplate, error) {
	var template models.NotificationTemplate

	query := s.db.Preload("Creator")

	// 权限控制
	if !hasAllPermission {
		query = query.Where("created_by = ? OR is_system = ?", userID, true)
	}

	if err := query.First(&template, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("模板不存在或无权访问")
		}
		return nil, fmt.Errorf("获取模板失败: %v", err)
	}

	return &template, nil
}

// UpdateTemplate 更新通知模板
func (s *NotificationService) UpdateTemplate(id uint, req *NotificationTemplateRequest, userID uint, hasAllPermission bool) (*models.NotificationTemplate, error) {
	var template models.NotificationTemplate

	query := s.db.Model(&template)

	// 权限控制
	if !hasAllPermission {
		query = query.Where("created_by = ?", userID)
	}

	if err := query.First(&template, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("模板不存在或无权修改")
		}
		return nil, fmt.Errorf("获取模板失败: %v", err)
	}

	// 系统模板不允许修改
	if template.IsSystem && !hasAllPermission {
		return nil, fmt.Errorf("系统模板不允许修改")
	}

	// 更新字段
	updates := map[string]interface{}{
		"name":        req.Name,
		"description": req.Description,
		"type":        req.Type,
		"subject":     req.Subject,
		"content":     req.Content,
		"variables":   req.Variables,
		"is_active":   req.IsActive,
	}

	if err := s.db.Model(&template).Updates(updates).Error; err != nil {
		return nil, fmt.Errorf("更新模板失败: %v", err)
	}

	// 重新加载数据
	if err := s.db.Preload("Creator").First(&template, id).Error; err != nil {
		return nil, fmt.Errorf("获取更新后的模板失败: %v", err)
	}

	return &template, nil
}

// DeleteTemplate 删除通知模板
func (s *NotificationService) DeleteTemplate(id, userID uint, hasAllPermission bool) error {
	var template models.NotificationTemplate

	query := s.db.Model(&template)

	// 权限控制
	if !hasAllPermission {
		query = query.Where("created_by = ?", userID)
	}

	if err := query.First(&template, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("模板不存在或无权删除")
		}
		return fmt.Errorf("获取模板失败: %v", err)
	}

	// 系统模板不允许删除
	if template.IsSystem && !hasAllPermission {
		return fmt.Errorf("系统模板不允许删除")
	}

	if err := s.db.Delete(&template).Error; err != nil {
		return fmt.Errorf("删除模板失败: %v", err)
	}

	return nil
}

// SendNotification 发送通知
func (s *NotificationService) SendNotification(req *NotificationSendRequest, userID uint) (*models.Notification, error) {
	// 验证必填字段
	if req.Type == "" {
		return nil, fmt.Errorf("通知类型不能为空")
	}
	if len(req.Recipients) == 0 {
		return nil, fmt.Errorf("收件人列表不能为空")
	}
	// 如果没有使用模板，则内容是必需的
	if req.TemplateID == nil && req.Content == "" {
		return nil, fmt.Errorf("通知内容不能为空")
	}

	// 创建通知记录
	notification := &models.Notification{
		Type:       req.Type,
		Channel:    req.Channel,
		Title:      req.Subject, // 使用subject作为title
		Subject:    req.Subject,
		Content:    req.Content,
		Status:     "pending",
		Priority:   req.Priority,
		CreatedBy:  userID,
	}

	// 如果使用模板，先处理模板内容
	if req.TemplateID != nil {
		template, err := s.GetTemplateByID(*req.TemplateID, userID, true)
		if err != nil {
			return nil, fmt.Errorf("获取模板失败: %v", err)
		}

		if !template.IsActive {
			return nil, fmt.Errorf("模板已禁用")
		}

		// 使用模板内容
		if notification.Subject == "" {
			notification.Subject = template.Subject
		}
		if notification.Content == "" {
			notification.Content = template.Content
		}

		// 处理模板变量替换
		notification.Content = s.processTemplateVariables(template.Content, req.Variables)
		notification.Subject = s.processTemplateVariables(template.Subject, req.Variables)
	}

	// 设置标题
	if notification.Title == "" {
		if notification.Subject != "" {
			notification.Title = notification.Subject
		} else {
			notification.Title = fmt.Sprintf("%s通知", strings.ToUpper(req.Type))
		}
	}

	// 如果没有指定渠道，使用默认渠道
	if notification.Channel == "" {
		notification.Channel = "default"
	}

	// 设置默认优先级
	if notification.Priority == 0 {
		notification.Priority = 1
	}

	if req.TemplateID != nil {
		notification.TemplateID = req.TemplateID
	}

	if req.ScheduledAt != nil {
		notification.ScheduledAt = req.ScheduledAt
	}

	// 序列化收件人列表
	if recipientsJSON, err := json.Marshal(req.Recipients); err != nil {
		return nil, fmt.Errorf("序列化收件人列表失败: %v", err)
	} else {
		notification.Recipients = string(recipientsJSON)
	}

	// 序列化变量
	if len(req.Variables) > 0 {
		if variablesJSON, err := json.Marshal(req.Variables); err != nil {
			return nil, fmt.Errorf("序列化变量失败: %v", err)
		} else {
			notification.Variables = string(variablesJSON)
		}
	}



	// 保存通知记录
	if err := s.db.Create(notification).Error; err != nil {
		return nil, fmt.Errorf("创建通知记录失败: %v", err)
	}

	// 添加到通知队列
	if err := s.addToQueue(notification); err != nil {
		return nil, fmt.Errorf("添加到通知队列失败: %v", err)
	}

	// 预加载关联数据
	if err := s.db.Preload("Template").Preload("Creator").First(notification, notification.ID).Error; err != nil {
		return nil, fmt.Errorf("获取通知记录失败: %v", err)
	}

	return notification, nil
}

// processTemplateVariables 处理模板变量替换
func (s *NotificationService) processTemplateVariables(content string, variables map[string]interface{}) string {
	if len(variables) == 0 {
		return content
	}

	// 简单的变量替换实现
	result := content
	for key, value := range variables {
		placeholder := fmt.Sprintf("{{%s}}", key)
		replacement := fmt.Sprintf("%v", value)
		result = fmt.Sprintf(strings.ReplaceAll(result, placeholder, replacement))
	}

	return result
}

// addToQueue 添加通知到队列
func (s *NotificationService) addToQueue(notification *models.Notification) error {
	if notification.ID == 0 {
		return fmt.Errorf("通知ID无效")
	}

	scheduledAt := time.Now()
	if notification.ScheduledAt != nil {
		scheduledAt = *notification.ScheduledAt
	}

	queueItem := &models.NotificationQueue{
		NotificationID: notification.ID,
		Status:         "queued",
		Priority:       notification.Priority,
		ScheduledAt:    scheduledAt,
	}

	if err := s.db.Create(queueItem).Error; err != nil {
		return fmt.Errorf("添加到队列失败: %v", err)
	}

	return nil
}

// GetNotifications 获取通知历史
func (s *NotificationService) GetNotifications(page, pageSize int, status, notificationType string, userID uint, hasAllPermission bool) (*NotificationListResponse, error) {
	var notifications []models.Notification
	var total int64

	query := s.db.Model(&models.Notification{})

	// 状态过滤
	if status != "" {
		query = query.Where("status = ?", status)
	}

	// 类型过滤
	if notificationType != "" {
		query = query.Where("type = ?", notificationType)
	}

	// 权限控制
	if !hasAllPermission {
		query = query.Where("created_by = ?", userID)
	}

	// 计算总数
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取通知总数失败: %v", err)
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Preload("Template").Preload("Creator").
		Offset(offset).
		Limit(pageSize).
		Order("created_at DESC").
		Find(&notifications).Error; err != nil {
		return nil, fmt.Errorf("获取通知列表失败: %v", err)
	}

	return &NotificationListResponse{
		Notifications: notifications,
		Total:         total,
		Page:          page,
		PageSize:      pageSize,
	}, nil
}

// CreateAlertRule 创建告警规则
func (s *NotificationService) CreateAlertRule(req *AlertRuleRequest, userID uint) (*models.AlertRule, error) {
	rule := &models.AlertRule{
		Name:        req.Name,
		Description: req.Description,
		Source:      req.Source,
		IsActive:    req.IsActive,
		Priority:    req.Priority,
		Cooldown:    req.Cooldown,
		CreatedBy:   userID,
	}

	// 序列化条件
	if conditionsJSON, err := json.Marshal(req.Conditions); err != nil {
		return nil, fmt.Errorf("序列化条件失败: %v", err)
	} else {
		rule.Conditions = string(conditionsJSON)
	}

	// 序列化动作
	if actionsJSON, err := json.Marshal(req.Actions); err != nil {
		return nil, fmt.Errorf("序列化动作失败: %v", err)
	} else {
		rule.Actions = string(actionsJSON)
	}

	if err := s.db.Create(rule).Error; err != nil {
		return nil, fmt.Errorf("创建告警规则失败: %v", err)
	}

	// 预加载关联数据
	if err := s.db.Preload("Creator").First(rule, rule.ID).Error; err != nil {
		return nil, fmt.Errorf("获取告警规则失败: %v", err)
	}

	return rule, nil
}

// GetAlertRules 获取告警规则列表
func (s *NotificationService) GetAlertRules(page, pageSize int, source string, userID uint, hasAllPermission bool) (*AlertRuleListResponse, error) {
	var rules []models.AlertRule
	var total int64

	query := s.db.Model(&models.AlertRule{})

	// 来源过滤
	if source != "" {
		query = query.Where("source = ?", source)
	}

	// 权限控制
	if !hasAllPermission {
		query = query.Where("created_by = ?", userID)
	}

	// 计算总数
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取规则总数失败: %v", err)
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Preload("Creator").
		Offset(offset).
		Limit(pageSize).
		Order("created_at DESC").
		Find(&rules).Error; err != nil {
		return nil, fmt.Errorf("获取规则列表失败: %v", err)
	}

	return &AlertRuleListResponse{
		Rules:    rules,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// ProcessZabbixAlert 处理Zabbix告警
func (s *NotificationService) ProcessZabbixAlert(req *ZabbixAlertRequest) (*models.AlertEvent, error) {
	// 查找匹配的告警规则
	var rules []models.AlertRule
	if err := s.db.Where("source = ? AND is_active = ?", "zabbix", true).Find(&rules).Error; err != nil {
		return nil, fmt.Errorf("查找告警规则失败: %v", err)
	}

	if len(rules) == 0 {
		return nil, fmt.Errorf("未找到匹配的Zabbix告警规则")
	}

	// 创建告警事件
	event := &models.AlertEvent{
		RuleID:    rules[0].ID, // 简化处理，使用第一个规则
		Source:    "zabbix",
		EventID:   req.EventID,
		Level:     req.Level,
		Title:     req.Title,
		Message:   req.Message,
		Status:    "active",
	}

	// 序列化数据
	if req.Data != nil {
		if dataJSON, err := json.Marshal(req.Data); err != nil {
			return nil, fmt.Errorf("序列化数据失败: %v", err)
		} else {
			event.Data = string(dataJSON)
		}
	}

	if err := s.db.Create(event).Error; err != nil {
		return nil, fmt.Errorf("创建告警事件失败: %v", err)
	}

	// 处理告警动作
	if err := s.processAlertActions(event, &rules[0]); err != nil {
		return nil, fmt.Errorf("处理告警动作失败: %v", err)
	}

	// 预加载关联数据
	if err := s.db.Preload("Rule").Preload("Rule.Creator").First(event, event.ID).Error; err != nil {
		return nil, fmt.Errorf("获取告警事件失败: %v", err)
	}

	return event, nil
}

// processAlertActions 处理告警动作
func (s *NotificationService) processAlertActions(event *models.AlertEvent, rule *models.AlertRule) error {
	// 解析动作配置
	var actions map[string]interface{}
	if err := json.Unmarshal([]byte(rule.Actions), &actions); err != nil {
		return fmt.Errorf("解析动作配置失败: %v", err)
	}

	// 检查是否需要发送通知
	if notifyConfig, ok := actions["notify"].(map[string]interface{}); ok {
		if enabled, ok := notifyConfig["enabled"].(bool); ok && enabled {
			// 创建通知
			notificationReq := &NotificationSendRequest{
				Type:       "email", // 默认邮件通知
				Recipients: []string{"admin@example.com"}, // 默认收件人
				Subject:    fmt.Sprintf("告警通知: %s", event.Title),
				Content:    fmt.Sprintf("告警级别: %s\n告警消息: %s\n时间: %s", event.Level, event.Message, event.CreatedAt.Format("2006-01-02 15:04:05")),
				Priority:   rule.Priority,
			}

			// 从配置中获取收件人
			if recipients, ok := notifyConfig["recipients"].([]interface{}); ok {
				var recipientList []string
				for _, recipient := range recipients {
					if email, ok := recipient.(string); ok {
						recipientList = append(recipientList, email)
					}
				}
				if len(recipientList) > 0 {
					notificationReq.Recipients = recipientList
				}
			}

			// 发送通知
			notification, err := s.SendNotification(notificationReq, rule.CreatedBy)
			if err != nil {
				return fmt.Errorf("发送告警通知失败: %v", err)
			}

			// 关联通知和告警事件
			if err := s.db.Model(event).Association("Notifications").Append(notification); err != nil {
				return fmt.Errorf("关联通知和告警事件失败: %v", err)
			}
		}
	}

	// 更新事件处理时间
	now := time.Now()
	event.ProcessedAt = &now
	return s.db.Save(event).Error
}

// GetAlertEvents 获取告警事件列表
func (s *NotificationService) GetAlertEvents(page, pageSize int, level, status string, userID uint, hasAllPermission bool) (*AlertEventListResponse, error) {
	var events []models.AlertEvent
	var total int64

	query := s.db.Model(&models.AlertEvent{})

	// 级别过滤
	if level != "" {
		query = query.Where("level = ?", level)
	}

	// 状态过滤
	if status != "" {
		query = query.Where("status = ?", status)
	}

	// 权限控制 - 通过规则创建者过滤
	if !hasAllPermission {
		query = query.Joins("JOIN alert_rules ON alert_events.rule_id = alert_rules.id").
			Where("alert_rules.created_by = ?", userID)
	}

	// 计算总数
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取事件总数失败: %v", err)
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Preload("Rule").Preload("Rule.Creator").
		Offset(offset).
		Limit(pageSize).
		Order("created_at DESC").
		Find(&events).Error; err != nil {
		return nil, fmt.Errorf("获取事件列表失败: %v", err)
	}

	return &AlertEventListResponse{
		Events:   events,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// CreateNotificationChannel 创建通知渠道
func (s *NotificationService) CreateNotificationChannel(req *NotificationChannelRequest, userID uint) (*models.NotificationChannel, error) {
	channel := &models.NotificationChannel{
		Name:        req.Name,
		Type:        req.Type,
		IsActive:    req.IsActive,
		IsDefault:   req.IsDefault,
		Description: req.Description,
		CreatedBy:   userID,
	}

	// 序列化配置
	if configJSON, err := json.Marshal(req.Config); err != nil {
		return nil, fmt.Errorf("序列化配置失败: %v", err)
	} else {
		channel.Config = string(configJSON)
	}

	// 如果设置为默认渠道，取消其他同类型的默认设置
	if req.IsDefault {
		if err := s.db.Model(&models.NotificationChannel{}).
			Where("type = ? AND is_default = ?", req.Type, true).
			Update("is_default", false).Error; err != nil {
			return nil, fmt.Errorf("更新默认渠道设置失败: %v", err)
		}
	}

	if err := s.db.Create(channel).Error; err != nil {
		return nil, fmt.Errorf("创建通知渠道失败: %v", err)
	}

	// 预加载关联数据
	if err := s.db.Preload("Creator").First(channel, channel.ID).Error; err != nil {
		return nil, fmt.Errorf("获取通知渠道失败: %v", err)
	}

	return channel, nil
}

// GetNotificationChannels 获取通知渠道列表
func (s *NotificationService) GetNotificationChannels(page, pageSize int, channelType string, userID uint, hasAllPermission bool) (*NotificationChannelListResponse, error) {
	var channels []models.NotificationChannel
	var total int64

	query := s.db.Model(&models.NotificationChannel{})

	// 类型过滤
	if channelType != "" {
		query = query.Where("type = ?", channelType)
	}

	// 权限控制
	if !hasAllPermission {
		query = query.Where("created_by = ?", userID)
	}

	// 计算总数
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取渠道总数失败: %v", err)
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Preload("Creator").
		Offset(offset).
		Limit(pageSize).
		Order("created_at DESC").
		Find(&channels).Error; err != nil {
		return nil, fmt.Errorf("获取渠道列表失败: %v", err)
	}

	return &NotificationChannelListResponse{
		Channels: channels,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// ProcessNotificationQueue 处理通知队列
func (s *NotificationService) ProcessNotificationQueue() error {
	// 获取待处理的通知队列项
	var queueItems []models.NotificationQueue
	if err := s.db.Preload("Notification").
		Where("status = ? AND scheduled_at <= ?", "queued", time.Now()).
		Order("priority DESC, scheduled_at ASC").
		Limit(10). // 每次处理10个
		Find(&queueItems).Error; err != nil {
		return fmt.Errorf("获取通知队列失败: %v", err)
	}

	for _, item := range queueItems {
		// 更新队列项状态为处理中
		item.Status = "processing"
		s.db.Save(&item)

		// 处理通知发送
		if err := s.processNotificationSending(&item.Notification); err != nil {
			// 处理失败，更新错误信息
			item.Status = "failed"
			item.ErrorMsg = err.Error()
			item.RetryCount++
			
			// 如果重试次数未达到上限，重新排队
			if item.RetryCount < 3 {
				item.Status = "queued"
				item.ScheduledAt = time.Now().Add(time.Duration(item.RetryCount*5) * time.Minute) // 递增延迟重试
			}
		} else {
			// 处理成功
			item.Status = "completed"
			now := time.Now()
			item.ProcessedAt = &now
		}

		s.db.Save(&item)
	}

	return nil
}

// processNotificationSending 处理通知发送
func (s *NotificationService) processNotificationSending(notification *models.Notification) error {
	// 更新通知状态为发送中
	notification.Status = "sending"
	s.db.Save(notification)

	// 根据通知类型选择发送方式
	var err error
	switch notification.Type {
	case "email":
		err = s.sendEmailNotification(notification)
	case "wechat":
		err = s.sendWechatNotification(notification)
	case "sms":
		err = s.sendSMSNotification(notification)
	default:
		err = fmt.Errorf("不支持的通知类型: %s", notification.Type)
	}

	if err != nil {
		// 发送失败
		notification.Status = "failed"
		notification.ErrorMsg = err.Error()
		notification.RetryCount++
	} else {
		// 发送成功
		notification.Status = "sent"
		now := time.Now()
		notification.SentAt = &now
	}

	return s.db.Save(notification).Error
}

// sendEmailNotification 发送邮件通知
func (s *NotificationService) sendEmailNotification(notification *models.Notification) error {
	// 这里应该集成实际的邮件发送服务
	// 例如：SMTP、SendGrid、阿里云邮件推送等
	
	// 模拟邮件发送
	fmt.Printf("发送邮件通知: %s -> %s\n", notification.Subject, notification.Recipients)
	
	// 模拟发送延迟
	time.Sleep(100 * time.Millisecond)
	
	return nil // 模拟发送成功
}

// sendWechatNotification 发送微信通知
func (s *NotificationService) sendWechatNotification(notification *models.Notification) error {
	// 这里应该集成微信企业号或服务号API
	
	// 模拟微信发送
	fmt.Printf("发送微信通知: %s -> %s\n", notification.Subject, notification.Recipients)
	
	// 模拟发送延迟
	time.Sleep(200 * time.Millisecond)
	
	return nil // 模拟发送成功
}

// sendSMSNotification 发送短信通知
func (s *NotificationService) sendSMSNotification(notification *models.Notification) error {
	// 这里应该集成短信服务提供商API
	// 例如：阿里云短信、腾讯云短信等
	
	// 模拟短信发送
	fmt.Printf("发送短信通知: %s -> %s\n", notification.Subject, notification.Recipients)
	
	// 模拟发送延迟
	time.Sleep(150 * time.Millisecond)
	
	return nil // 模拟发送成功
}