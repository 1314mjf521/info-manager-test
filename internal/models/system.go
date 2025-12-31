package models

import (
	"time"
	"gorm.io/gorm"
)

// SystemConfig 系统配置
type SystemConfig struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Category    string         `json:"category" gorm:"size:50;not null;index"`    // system, database, cache, etc.
	Key         string         `json:"key" gorm:"size:100;not null;index"`        // 配置键
	Value       string         `json:"value" gorm:"type:text"`                    // 配置值
	DefaultValue string        `json:"default_value" gorm:"type:text"`            // 默认值
	Description string         `json:"description" gorm:"size:500"`               // 配置描述
	DataType    string         `json:"data_type" gorm:"size:20;default:'string'"` // string, int, bool, json
	IsPublic    bool           `json:"is_public" gorm:"default:false"`            // 是否公开（前端可访问）
	IsEditable  bool           `json:"is_editable" gorm:"default:true"`           // 是否可编辑
	Version     int            `json:"version" gorm:"default:1"`                  // 配置版本
	UpdatedBy   uint           `json:"updated_by" gorm:"index"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联
	UpdatedByUser User `json:"updated_by_user,omitempty" gorm:"foreignKey:UpdatedBy"`

	// 唯一索引
	_ struct{} `gorm:"uniqueIndex:idx_category_key,category,key"`
}

// SystemConfigHistory 系统配置历史
type SystemConfigHistory struct {
	ID         uint      `json:"id" gorm:"primaryKey"`
	ConfigID   uint      `json:"config_id" gorm:"not null;index"`
	OldValue   string    `json:"old_value" gorm:"type:text"`
	NewValue   string    `json:"new_value" gorm:"type:text"`
	Version    int       `json:"version" gorm:"not null"`
	ChangeType string    `json:"change_type" gorm:"size:20;not null"` // create, update, delete
	Reason     string    `json:"reason" gorm:"size:500"`              // 变更原因
	UpdatedBy  uint      `json:"updated_by" gorm:"not null;index"`
	CreatedAt  time.Time `json:"created_at"`

	// 关联
	Config        SystemConfig `json:"config,omitempty" gorm:"foreignKey:ConfigID"`
	UpdatedByUser User         `json:"updated_by_user,omitempty" gorm:"foreignKey:UpdatedBy"`
}

// Announcement 系统公告
type Announcement struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Title       string         `json:"title" gorm:"size:200;not null"`
	Content     string         `json:"content" gorm:"type:text;not null"`
	Type        string         `json:"type" gorm:"size:20;not null;index"` // info, warning, error, maintenance
	Priority    int            `json:"priority" gorm:"default:1;index"`    // 1-5, 5最高
	IsActive    bool           `json:"is_active" gorm:"default:true"`
	IsSticky    bool           `json:"is_sticky" gorm:"default:false"`     // 是否置顶
	TargetUsers string         `json:"target_users" gorm:"type:text"`      // JSON格式的目标用户列表，空表示所有用户
	StartTime   *time.Time     `json:"start_time"`                         // 开始显示时间
	EndTime     *time.Time     `json:"end_time"`                           // 结束显示时间
	ViewCount   int            `json:"view_count" gorm:"default:0"`        // 查看次数
	CreatedBy   uint           `json:"created_by" gorm:"not null;index"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联
	Creator User                   `json:"creator,omitempty" gorm:"foreignKey:CreatedBy"`
	Views   []AnnouncementView     `json:"views,omitempty" gorm:"foreignKey:AnnouncementID"`
}

// AnnouncementView 公告查看记录
type AnnouncementView struct {
	ID             uint      `json:"id" gorm:"primaryKey"`
	AnnouncementID uint      `json:"announcement_id" gorm:"not null;index"`
	UserID         uint      `json:"user_id" gorm:"not null;index"`
	ViewedAt       time.Time `json:"viewed_at" gorm:"not null"`
	IPAddress      string    `json:"ip_address" gorm:"size:45"`
	UserAgent      string    `json:"user_agent" gorm:"size:500"`

	// 关联
	Announcement Announcement `json:"announcement,omitempty" gorm:"foreignKey:AnnouncementID"`
	User         User         `json:"user,omitempty" gorm:"foreignKey:UserID"`

	// 唯一索引
	_ struct{} `gorm:"uniqueIndex:idx_announcement_user,announcement_id,user_id"`
}

// SystemHealth 系统健康状态
type SystemHealth struct {
	ID           uint      `json:"id" gorm:"primaryKey"`
	Component    string    `json:"component" gorm:"size:50;not null;index"` // database, redis, external_api, etc.
	Status       string    `json:"status" gorm:"size:20;not null"`          // healthy, unhealthy, degraded
	ResponseTime int       `json:"response_time" gorm:"default:0"`          // 响应时间（毫秒）
	ErrorMsg     string    `json:"error_msg" gorm:"size:1000"`
	Details      string    `json:"details" gorm:"type:text"`                // JSON格式的详细信息
	CheckedAt    time.Time `json:"checked_at" gorm:"not null;index"`
	CreatedAt    time.Time `json:"created_at"`

	// 索引
	_ struct{} `gorm:"index:idx_component_checked,component,checked_at"`
}

// SystemLog 系统日志
type SystemLog struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Level     string    `json:"level" gorm:"size:10;not null;index"`     // debug, info, warn, error, fatal
	Category  string    `json:"category" gorm:"size:50;not null;index"`  // auth, api, database, etc.
	Message   string    `json:"message" gorm:"type:text;not null"`
	Context   string    `json:"context" gorm:"type:text"`                // JSON格式的上下文信息
	UserID    *uint     `json:"user_id" gorm:"index"`                    // 关联用户（可选）
	IPAddress string    `json:"ip_address" gorm:"size:45;index"`
	UserAgent string    `json:"user_agent" gorm:"size:500"`
	RequestID string    `json:"request_id" gorm:"size:100;index"`        // 请求ID
	CreatedAt time.Time `json:"created_at" gorm:"index"`

	// 关联
	User User `json:"user,omitempty" gorm:"foreignKey:UserID"`

	// 索引
	_ struct{} `gorm:"index:idx_level_created,level,created_at"`
	_ struct{} `gorm:"index:idx_category_created,category,created_at"`
}

// SystemMetrics 系统指标
type SystemMetrics struct {
	ID         uint      `json:"id" gorm:"primaryKey"`
	MetricName string    `json:"metric_name" gorm:"size:100;not null;index"` // cpu_usage, memory_usage, disk_usage, etc.
	Value      float64   `json:"value" gorm:"not null"`
	Unit       string    `json:"unit" gorm:"size:20"`                        // %, MB, GB, count, etc.
	Tags       string    `json:"tags" gorm:"type:text"`                      // JSON格式的标签
	Timestamp  time.Time `json:"timestamp" gorm:"not null;index"`
	CreatedAt  time.Time `json:"created_at"`

	// 索引
	_ struct{} `gorm:"index:idx_metric_timestamp,metric_name,timestamp"`
}

// SystemMaintenance 系统维护记录
type SystemMaintenance struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Title       string         `json:"title" gorm:"size:200;not null"`
	Description string         `json:"description" gorm:"type:text"`
	Type        string         `json:"type" gorm:"size:20;not null"` // scheduled, emergency, hotfix
	Status      string         `json:"status" gorm:"size:20;not null;default:'planned'"` // planned, in_progress, completed, cancelled
	StartTime   time.Time      `json:"start_time" gorm:"not null"`
	EndTime     *time.Time     `json:"end_time"`
	Duration    int            `json:"duration" gorm:"default:0"`                        // 实际持续时间（分钟）
	Impact      string         `json:"impact" gorm:"size:20;default:'low'"`              // low, medium, high, critical
	Notes       string         `json:"notes" gorm:"type:text"`                           // 维护记录和备注
	CreatedBy   uint           `json:"created_by" gorm:"not null;index"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联
	Creator User `json:"creator,omitempty" gorm:"foreignKey:CreatedBy"`
}

// APIToken API访问令牌
type APIToken struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Name        string         `json:"name" gorm:"size:100;not null"`                    // Token名称
	Token       string         `json:"token" gorm:"size:255;not null;uniqueIndex"`      // Token值
	UserID      uint           `json:"user_id" gorm:"not null;index"`                   // 所属用户
	Scope       string         `json:"scope" gorm:"size:50;not null;default:'read'"`    // 权限范围: read, write, admin
	Status      string         `json:"status" gorm:"size:20;not null;default:'active'"` // 状态: active, disabled
	Description string         `json:"description" gorm:"type:text"`                    // 描述
	ExpiresAt   *time.Time     `json:"expires_at"`                                      // 过期时间，null表示永不过期
	LastUsedAt  *time.Time     `json:"last_used_at"`                                    // 最后使用时间
	UsageCount  int64          `json:"usage_count" gorm:"default:0"`                    // 使用次数
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at,omitempty" gorm:"index"`

	// 关联
	User         User                `json:"user,omitempty" gorm:"foreignKey:UserID"`
	UsageHistory []APITokenUsageLog  `json:"usage_history,omitempty" gorm:"foreignKey:TokenID"`
}

// APITokenUsageLog API Token使用日志
type APITokenUsageLog struct {
	ID         uint      `json:"id" gorm:"primaryKey"`
	TokenID    uint      `json:"token_id" gorm:"not null;index"`                 // Token ID
	Method     string    `json:"method" gorm:"size:10;not null"`                 // HTTP方法: GET, POST, PUT, DELETE
	Path       string    `json:"path" gorm:"size:500;not null"`                  // 请求路径
	IPAddress  string    `json:"ip_address" gorm:"size:45;not null;index"`       // 客户端IP
	UserAgent  string    `json:"user_agent" gorm:"size:1000"`                    // 用户代理
	StatusCode int       `json:"status_code" gorm:"not null;index"`              // HTTP状态码
	Duration   int       `json:"duration" gorm:"default:0"`                      // 请求耗时（毫秒）
	RequestID  string    `json:"request_id" gorm:"size:100;index"`               // 请求ID
	CreatedAt  time.Time `json:"created_at" gorm:"not null;index"`

	// 关联
	Token APIToken `json:"token,omitempty" gorm:"foreignKey:TokenID"`

	// 索引
	_ struct{} `gorm:"index:idx_token_created,token_id,created_at"`
	_ struct{} `gorm:"index:idx_ip_created,ip_address,created_at"`
}