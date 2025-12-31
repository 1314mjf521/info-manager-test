package models

import (
	"time"

	"gorm.io/gorm"
)

// TicketStatus 工单状态枚举
type TicketStatus string

const (
	TicketStatusSubmitted  TicketStatus = "submitted"  // 已提交（等待分派）
	TicketStatusAssigned   TicketStatus = "assigned"   // 已分派（等待接受）
	TicketStatusAccepted   TicketStatus = "accepted"   // 已接受（等待审批）
	TicketStatusApproved   TicketStatus = "approved"   // 已审批（等待执行）
	TicketStatusInProgress TicketStatus = "progress"   // 执行中
	TicketStatusPending    TicketStatus = "pending"    // 等待反馈
	TicketStatusResolved   TicketStatus = "resolved"   // 已解决
	TicketStatusClosed     TicketStatus = "closed"     // 已关闭
	TicketStatusRejected   TicketStatus = "rejected"   // 已拒绝
	TicketStatusReturned   TicketStatus = "returned"   // 已退回
)

// TicketPriority 工单优先级枚举
type TicketPriority string

const (
	TicketPriorityLow      TicketPriority = "low"      // 低
	TicketPriorityNormal   TicketPriority = "normal"   // 普通
	TicketPriorityHigh     TicketPriority = "high"     // 高
	TicketPriorityCritical TicketPriority = "critical" // 紧急
)

// TicketType 工单类型枚举
type TicketType string

const (
	TicketTypeBug     TicketType = "bug"     // 故障报告
	TicketTypeFeature TicketType = "feature" // 功能请求
	TicketTypeSupport TicketType = "support" // 技术支持
	TicketTypeChange  TicketType = "change"  // 变更请求
	TicketTypeCustom  TicketType = "custom"  // 自定义请求
)

// Ticket 工单模型
type Ticket struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Title       string         `json:"title" gorm:"not null;size:500"`
	Description string         `json:"description" gorm:"type:text"`
	Type        TicketType     `json:"type" gorm:"not null;size:20;index"`
	Status      TicketStatus   `json:"status" gorm:"not null;size:20;default:'submitted';index"`
	Priority    TicketPriority `json:"priority" gorm:"not null;size:20;default:'normal';index"`
	
	// 关联用户
	CreatorID  uint  `json:"creator_id" gorm:"not null;index"`
	AssigneeID *uint `json:"assignee_id" gorm:"index"`
	
	// 分类和标签
	Category string      `json:"category" gorm:"size:100;index"`
	Tags     StringSlice `json:"tags" gorm:"type:text"`
	
	// 时间管理
	DueDate     *time.Time `json:"due_date"`
	ResolvedAt  *time.Time `json:"resolved_at"`
	ClosedAt    *time.Time `json:"closed_at"`
	ProcessingStartedAt *time.Time `json:"processing_started_at"` // 开始处理时间
	
	// 自动处理配置
	AutoAssignRole string `json:"auto_assign_role" gorm:"size:50"` // 自动分配角色
	ProcessingTimeout int `json:"processing_timeout" gorm:"default:24"` // 处理超时时间（小时）
	
	// 元数据
	Metadata JSONB `json:"metadata" gorm:"type:text"`
	
	// 系统字段
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`
	
	// 关联关系
	Creator  User  `json:"creator" gorm:"foreignKey:CreatorID"`
	Assignee *User `json:"assignee" gorm:"foreignKey:AssigneeID"`
	
	// 工单相关数据
	Comments    []TicketComment    `json:"comments" gorm:"foreignKey:TicketID"`
	Attachments []TicketAttachment `json:"attachments" gorm:"foreignKey:TicketID"`
	History     []TicketHistory    `json:"history" gorm:"foreignKey:TicketID"`
}

// TicketComment 工单评论模型
type TicketComment struct {
	ID       uint   `json:"id" gorm:"primaryKey"`
	TicketID uint   `json:"ticket_id" gorm:"not null;index"`
	Content  string `json:"content" gorm:"type:text;not null"`
	IsPublic bool   `json:"is_public" gorm:"default:true"`
	
	// 关联用户
	UserID uint `json:"user_id" gorm:"not null;index"`
	
	// 系统字段
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`
	
	// 关联关系
	Ticket Ticket `json:"ticket" gorm:"foreignKey:TicketID"`
	User   User   `json:"user" gorm:"foreignKey:UserID"`
}

// TicketAttachment 工单附件模型
type TicketAttachment struct {
	ID         uint   `json:"id" gorm:"primaryKey"`
	TicketID   uint   `json:"ticket_id" gorm:"not null;index"`
	FileName   string `json:"file_name" gorm:"not null;size:255"`
	FileSize   int64  `json:"file_size" gorm:"not null"`
	ContentType string `json:"content_type" gorm:"size:100"`
	FilePath   string `json:"file_path" gorm:"size:500"`
	
	// 关联用户
	UploadedBy uint `json:"uploaded_by" gorm:"not null;index"`
	
	// 系统字段
	CreatedAt time.Time `json:"created_at"`
	
	// 关联关系
	Ticket   Ticket `json:"ticket" gorm:"foreignKey:TicketID"`
	Uploader User   `json:"uploader" gorm:"foreignKey:UploadedBy"`
}

// TicketHistory 工单历史记录模型
type TicketHistory struct {
	ID          uint   `json:"id" gorm:"primaryKey"`
	TicketID    uint   `json:"ticket_id" gorm:"not null;index"`
	Action      string `json:"action" gorm:"not null;size:50"`
	Description string `json:"description" gorm:"type:text"`
	
	// 关联用户
	UserID uint `json:"user_id" gorm:"not null;index"`
	
	// 系统字段
	CreatedAt time.Time `json:"created_at"`
	
	// 关联关系
	Ticket Ticket `json:"ticket" gorm:"foreignKey:TicketID"`
	User   User   `json:"user" gorm:"foreignKey:UserID"`
}

// TicketTemplate 工单模板模型
type TicketTemplate struct {
	ID          uint       `json:"id" gorm:"primaryKey"`
	Name        string     `json:"name" gorm:"not null;size:200"`
	Description string     `json:"description" gorm:"size:500"`
	Type        TicketType `json:"type" gorm:"not null;size:20"`
	Template    JSONB      `json:"template" gorm:"type:text"`
	IsActive    bool       `json:"is_active" gorm:"default:true"`
	
	// 关联用户
	CreatedBy uint `json:"created_by" gorm:"not null;index"`
	
	// 系统字段
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`
	
	// 关联关系
	Creator User `json:"creator" gorm:"foreignKey:CreatedBy"`
}

// TicketCategory 工单分类模型
type TicketCategory struct {
	ID          uint   `json:"id" gorm:"primaryKey"`
	Name        string `json:"name" gorm:"not null;size:100;uniqueIndex"`
	DisplayName string `json:"display_name" gorm:"not null;size:200"`
	Description string `json:"description" gorm:"size:500"`
	Color       string `json:"color" gorm:"size:7"` // 十六进制颜色值
	IsActive    bool   `json:"is_active" gorm:"default:true"`
	
	// 自定义字段配置
	CustomFields JSONB `json:"custom_fields" gorm:"type:text"`
	
	// 系统字段
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`
}

// BeforeCreate 创建前钩子
func (t *Ticket) BeforeCreate(tx *gorm.DB) error {
	// 设置默认值
	if t.Status == "" {
		t.Status = TicketStatusSubmitted
	}
	if t.Priority == "" {
		t.Priority = TicketPriorityNormal
	}
	return nil
}

// BeforeUpdate 更新前钩子
func (t *Ticket) BeforeUpdate(tx *gorm.DB) error {
	// 自动设置解决时间和关闭时间
	if t.Status == TicketStatusResolved && t.ResolvedAt == nil {
		now := time.Now()
		t.ResolvedAt = &now
	}
	if t.Status == TicketStatusClosed && t.ClosedAt == nil {
		now := time.Now()
		t.ClosedAt = &now
	}
	return nil
}

// IsOverdue 检查工单是否过期
func (t *Ticket) IsOverdue() bool {
	if t.DueDate == nil {
		return false
	}
	return time.Now().After(*t.DueDate) && 
		   t.Status != TicketStatusResolved && 
		   t.Status != TicketStatusClosed
}

// CanAssign 检查是否可以分配工单
func (t *Ticket) CanAssign() bool {
	return t.Status != TicketStatusClosed && t.Status != TicketStatusRejected
}

// CanComment 检查是否可以评论
func (t *Ticket) CanComment() bool {
	return t.Status != TicketStatusClosed
}