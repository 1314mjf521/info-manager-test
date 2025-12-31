package models

import (
	"time"
	"gorm.io/gorm"
)

// NotificationTemplate 通知模板
type NotificationTemplate struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Name        string         `json:"name" gorm:"size:100;not null;index"`
	Description string         `json:"description" gorm:"size:500"`
	Type        string         `json:"type" gorm:"size:20;not null;index"` // email, wechat, sms
	Subject     string         `json:"subject" gorm:"size:200"`
	Content     string         `json:"content" gorm:"type:text;not null"`
	Variables   string         `json:"variables" gorm:"type:text"` // JSON格式的变量定义
	IsActive    bool           `json:"is_active" gorm:"default:true"`
	IsSystem    bool           `json:"is_system" gorm:"default:false"`
	CreatedBy   uint           `json:"created_by" gorm:"not null;index"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联
	Creator      User                 `json:"creator,omitempty" gorm:"foreignKey:CreatedBy"`
	Notifications []Notification      `json:"notifications,omitempty" gorm:"foreignKey:TemplateID"`
}

// Notification 通知记录
type Notification struct {
	ID         uint           `json:"id" gorm:"primaryKey"`
	TemplateID *uint          `json:"template_id" gorm:"index"`
	Type       string         `json:"type" gorm:"size:20;not null;index"` // email, wechat, sms
	Channel    string         `json:"channel" gorm:"size:50;not null"`    // 具体渠道标识
	Recipients string         `json:"recipients" gorm:"type:text;not null"` // JSON格式的收件人列表
	Title      string         `json:"title" gorm:"size:200;not null"`      // 通知标题
	Subject    string         `json:"subject" gorm:"size:200"`
	Content    string         `json:"content" gorm:"type:text;not null"`
	Variables  string         `json:"variables" gorm:"type:text"` // JSON格式的变量值
	Status     string         `json:"status" gorm:"size:20;not null;index;default:'pending'"` // pending, sending, sent, failed
	Priority   int            `json:"priority" gorm:"default:1;index"` // 1-5, 5最高
	ScheduledAt *time.Time    `json:"scheduled_at" gorm:"index"`
	SentAt     *time.Time     `json:"sent_at"`
	ErrorMsg   string         `json:"error_msg" gorm:"size:1000"`
	RetryCount int            `json:"retry_count" gorm:"default:0"`
	MaxRetries int            `json:"max_retries" gorm:"default:3"`
	CreatedBy  uint           `json:"created_by" gorm:"not null;index"`
	CreatedAt  time.Time      `json:"created_at"`
	UpdatedAt  time.Time      `json:"updated_at"`
	DeletedAt  gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联
	Template *NotificationTemplate `json:"template,omitempty" gorm:"foreignKey:TemplateID"`
	Creator  User                  `json:"creator,omitempty" gorm:"foreignKey:CreatedBy"`
}

// NotificationChannel 通知渠道配置
type NotificationChannel struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Name        string         `json:"name" gorm:"size:100;not null;uniqueIndex"`
	Type        string         `json:"type" gorm:"size:20;not null;index"` // email, wechat, sms
	Config      string         `json:"config" gorm:"type:text;not null"`   // JSON格式的配置信息
	IsActive    bool           `json:"is_active" gorm:"default:true"`
	IsDefault   bool           `json:"is_default" gorm:"default:false"`
	Description string         `json:"description" gorm:"size:500"`
	CreatedBy   uint           `json:"created_by" gorm:"not null;index"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联
	Creator User `json:"creator,omitempty" gorm:"foreignKey:CreatedBy"`
}

// WechatConfig 企业微信配置结构
type WechatConfig struct {
	WebhookURL string `json:"webhook_url"`
	Secret     string `json:"secret,omitempty"`
}

// NotificationRule 通知规则模型
type NotificationRule struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Name        string         `json:"name" gorm:"not null;size:200"`
	Description string         `json:"description" gorm:"size:500"`
	EventType   string         `json:"event_type" gorm:"not null;size:100"` // ticket_created, ticket_assigned, etc.
	Conditions  string         `json:"conditions" gorm:"type:text"`         // JSON格式的条件
	ChannelID   uint           `json:"channel_id" gorm:"not null;index"`
	TemplateID  uint           `json:"template_id" gorm:"not null;index"`
	Recipients  string         `json:"recipients" gorm:"type:text"`         // JSON格式的收件人列表
	IsActive    bool           `json:"is_active" gorm:"default:true"`
	CreatedBy   uint           `json:"created_by" gorm:"not null;index"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"-" gorm:"index"`

	// 关联关系
	Channel  NotificationChannel  `json:"channel" gorm:"foreignKey:ChannelID"`
	Template NotificationTemplate `json:"template" gorm:"foreignKey:TemplateID"`
	Creator  User                 `json:"creator" gorm:"foreignKey:CreatedBy"`
}

// AlertRule 告警规则
type AlertRule struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Name        string         `json:"name" gorm:"size:100;not null;index"`
	Description string         `json:"description" gorm:"size:500"`
	Source      string         `json:"source" gorm:"size:50;not null;index"` // zabbix, prometheus, custom
	Conditions  string         `json:"conditions" gorm:"type:text;not null"`  // JSON格式的条件定义
	Actions     string         `json:"actions" gorm:"type:text;not null"`     // JSON格式的动作定义
	IsActive    bool           `json:"is_active" gorm:"default:true"`
	Priority    int            `json:"priority" gorm:"default:1;index"`
	Cooldown    int            `json:"cooldown" gorm:"default:300"` // 冷却时间（秒）
	CreatedBy   uint           `json:"created_by" gorm:"not null;index"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联
	Creator User         `json:"creator,omitempty" gorm:"foreignKey:CreatedBy"`
	Alerts  []AlertEvent `json:"alerts,omitempty" gorm:"foreignKey:RuleID"`
}

// AlertEvent 告警事件
type AlertEvent struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	RuleID      uint           `json:"rule_id" gorm:"not null;index"`
	Source      string         `json:"source" gorm:"size:50;not null;index"`
	EventID     string         `json:"event_id" gorm:"size:100;not null;index"` // 外部系统事件ID
	Level       string         `json:"level" gorm:"size:20;not null;index"`     // info, warning, error, critical
	Title       string         `json:"title" gorm:"size:200;not null"`
	Message     string         `json:"message" gorm:"type:text;not null"`
	Data        string         `json:"data" gorm:"type:text"` // JSON格式的原始数据
	Status      string         `json:"status" gorm:"size:20;not null;index;default:'active'"` // active, resolved, suppressed
	ResolvedAt  *time.Time     `json:"resolved_at"`
	ProcessedAt *time.Time     `json:"processed_at"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联
	Rule          AlertRule      `json:"rule,omitempty" gorm:"foreignKey:RuleID"`
	Notifications []Notification `json:"notifications,omitempty" gorm:"many2many:alert_notifications;"`
}

// NotificationQueue 通知队列
type NotificationQueue struct {
	ID             uint      `json:"id" gorm:"primaryKey"`
	NotificationID uint      `json:"notification_id" gorm:"not null;index"`
	Status         string    `json:"status" gorm:"size:20;not null;index;default:'queued'"` // queued, processing, completed, failed
	Priority       int       `json:"priority" gorm:"default:1;index"`
	ScheduledAt    time.Time `json:"scheduled_at" gorm:"index"`
	ProcessedAt    *time.Time `json:"processed_at"`
	ErrorMsg       string    `json:"error_msg" gorm:"size:1000"`
	RetryCount     int       `json:"retry_count" gorm:"default:0"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`

	// 关联
	Notification Notification `json:"notification,omitempty" gorm:"foreignKey:NotificationID"`
}