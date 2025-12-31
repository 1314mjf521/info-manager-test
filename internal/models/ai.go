package models

import (
	"time"
	"gorm.io/gorm"
)

// AIConfig AI服务配置
type AIConfig struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Provider    string         `json:"provider" gorm:"size:50;not null;index"` // openai, azure, anthropic, etc.
	Name        string         `json:"name" gorm:"size:100;not null"`
	APIKey      string         `json:"api_key" gorm:"type:text;not null"`       // 加密存储
	APIEndpoint string         `json:"api_endpoint" gorm:"size:500"`
	Model       string         `json:"model" gorm:"size:100"`                   // gpt-4, gpt-3.5-turbo, etc.
	Config      string         `json:"config" gorm:"type:text"`                 // JSON格式的额外配置
	
	// 新增功能分类和用途标签
	Categories  string         `json:"categories" gorm:"type:text"`             // JSON数组: ["chat", "optimize", "speech", "image"]
	Tags        string         `json:"tags" gorm:"type:text"`                   // JSON数组: ["production", "development", "fast", "accurate"]
	Description string         `json:"description" gorm:"size:500"`             // 配置描述
	Priority    int            `json:"priority" gorm:"default:1;index"`         // 优先级 1-10，数字越大优先级越高
	
	// 性能和限制配置
	IsActive    bool           `json:"is_active" gorm:"default:true"`
	IsDefault   bool           `json:"is_default" gorm:"default:false"`
	MaxTokens   int            `json:"max_tokens" gorm:"default:4000"`
	Temperature float32        `json:"temperature" gorm:"default:0.7"`
	
	// 使用限制
	DailyLimit    int          `json:"daily_limit" gorm:"default:0"`            // 每日使用限制，0表示无限制
	MonthlyLimit  int          `json:"monthly_limit" gorm:"default:0"`          // 每月使用限制，0表示无限制
	CostPerToken  float64      `json:"cost_per_token" gorm:"default:0"`         // 每token成本
	
	// 状态字段
	Status        string       `json:"status" gorm:"size:20;default:'active'"` // active, inactive, testing, deprecated
	LastTestedAt  *time.Time   `json:"last_tested_at"`                         // 最后测试时间
	
	CreatedBy   uint           `json:"created_by" gorm:"not null;index"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联
	Creator User `json:"creator,omitempty" gorm:"foreignKey:CreatedBy"`
}

// AIChatSession AI聊天会话
type AIChatSession struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	UserID      uint           `json:"user_id" gorm:"not null;index"`
	Title       string         `json:"title" gorm:"size:200;not null"`
	ConfigID    uint           `json:"config_id" gorm:"not null;index"`
	Context     string         `json:"context" gorm:"type:text"`      // JSON格式的上下文
	Status      string         `json:"status" gorm:"size:20;default:'active'"` // active, archived, deleted
	MessageCount int           `json:"message_count" gorm:"default:0"`
	TokensUsed  int            `json:"tokens_used" gorm:"default:0"`
	LastUsedAt  *time.Time     `json:"last_used_at"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联
	User     User            `json:"user,omitempty" gorm:"foreignKey:UserID"`
	Config   AIConfig        `json:"config,omitempty" gorm:"foreignKey:ConfigID"`
	Messages []AIChatMessage `json:"messages,omitempty" gorm:"foreignKey:SessionID"`
}

// AIChatMessage AI聊天消息
type AIChatMessage struct {
	ID        uint           `json:"id" gorm:"primaryKey"`
	SessionID uint           `json:"session_id" gorm:"not null;index"`
	Role      string         `json:"role" gorm:"size:20;not null"` // user, assistant, system
	Content   string         `json:"content" gorm:"type:text;not null"`
	Tokens    int            `json:"tokens" gorm:"default:0"`
	Metadata  string         `json:"metadata" gorm:"type:text"` // JSON格式的元数据
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联
	Session AIChatSession `json:"session,omitempty" gorm:"foreignKey:SessionID"`
}

// AITask AI任务记录
type AITask struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Type        string         `json:"type" gorm:"size:50;not null;index"` // optimize, speech-to-text, chat, etc.
	ConfigID    uint           `json:"config_id" gorm:"not null;index"`
	UserID      uint           `json:"user_id" gorm:"not null;index"`
	Input       string         `json:"input" gorm:"type:text"`              // 输入内容
	Output      string         `json:"output" gorm:"type:text"`             // 输出结果
	Status      string         `json:"status" gorm:"size:20;default:'pending'"` // pending, processing, completed, failed
	Progress    int            `json:"progress" gorm:"default:0"`           // 0-100
	TokensUsed  int            `json:"tokens_used" gorm:"default:0"`
	Duration    int            `json:"duration" gorm:"default:0"`           // 处理时间（毫秒）
	ErrorMsg    string         `json:"error_msg" gorm:"size:1000"`
	Metadata    string         `json:"metadata" gorm:"type:text"`           // JSON格式的元数据
	StartedAt   *time.Time     `json:"started_at"`
	CompletedAt *time.Time     `json:"completed_at"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联
	Config AIConfig `json:"config,omitempty" gorm:"foreignKey:ConfigID"`
	User   User     `json:"user,omitempty" gorm:"foreignKey:UserID"`
}

// AIUsageStats AI使用统计
type AIUsageStats struct {
	ID           uint      `json:"id" gorm:"primaryKey"`
	UserID       uint      `json:"user_id" gorm:"not null;index"`
	ConfigID     uint      `json:"config_id" gorm:"not null;index"`
	Date         time.Time `json:"date" gorm:"not null;index"`
	TaskType     string    `json:"task_type" gorm:"size:50;not null;index"`
	RequestCount int       `json:"request_count" gorm:"default:0"`
	TokensUsed   int       `json:"tokens_used" gorm:"default:0"`
	Duration     int       `json:"duration" gorm:"default:0"` // 总处理时间（毫秒）
	SuccessCount int       `json:"success_count" gorm:"default:0"`
	FailureCount int       `json:"failure_count" gorm:"default:0"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`

	// 关联
	User   User     `json:"user,omitempty" gorm:"foreignKey:UserID"`
	Config AIConfig `json:"config,omitempty" gorm:"foreignKey:ConfigID"`
}

// AIHealthCheck AI服务健康检查
type AIHealthCheck struct {
	ID           uint      `json:"id" gorm:"primaryKey"`
	ConfigID     uint      `json:"config_id" gorm:"not null;index"`
	Status       string    `json:"status" gorm:"size:20;not null"` // healthy, unhealthy, unknown
	ResponseTime int       `json:"response_time" gorm:"default:0"` // 响应时间（毫秒）
	ErrorMsg     string    `json:"error_msg" gorm:"size:1000"`
	CheckedAt    time.Time `json:"checked_at" gorm:"not null;index"`
	CreatedAt    time.Time `json:"created_at"`

	// 关联
	Config AIConfig `json:"config,omitempty" gorm:"foreignKey:ConfigID"`
}