package models

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"time"

	"gorm.io/gorm"
)

// JSONB 自定义JSONB类型
type JSONB map[string]interface{}

// Value 实现driver.Valuer接口
func (j JSONB) Value() (driver.Value, error) {
	if j == nil {
		return nil, nil
	}
	return json.Marshal(j)
}

// Scan 实现sql.Scanner接口
func (j *JSONB) Scan(value interface{}) error {
	if value == nil {
		*j = nil
		return nil
	}

	var bytes []byte
	switch v := value.(type) {
	case []byte:
		bytes = v
	case string:
		bytes = []byte(v)
	default:
		return fmt.Errorf("cannot scan %T into JSONB", value)
	}

	return json.Unmarshal(bytes, j)
}

// RecordType 记录类型模型
type RecordType struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	Name        string    `json:"name" gorm:"uniqueIndex;not null;size:100"`
	DisplayName string    `json:"display_name" gorm:"not null;size:200"`
	Schema      JSONB     `json:"schema" gorm:"type:text"`
	TableName   string    `json:"table_name" gorm:"not null;size:100"`
	IsActive    bool      `json:"is_active" gorm:"default:true"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// StringSlice 自定义字符串切片类型，用于数据库存储
type StringSlice []string

// Value 实现driver.Valuer接口
func (s StringSlice) Value() (driver.Value, error) {
	if s == nil {
		return nil, nil
	}
	return json.Marshal(s)
}

// Scan 实现sql.Scanner接口
func (s *StringSlice) Scan(value interface{}) error {
	if value == nil {
		*s = nil
		return nil
	}

	var bytes []byte
	switch v := value.(type) {
	case []byte:
		bytes = v
	case string:
		bytes = []byte(v)
	default:
		return fmt.Errorf("cannot scan %T into StringSlice", value)
	}

	return json.Unmarshal(bytes, s)
}

// Record 记录模型
type Record struct {
	ID        uint           `json:"id" gorm:"primaryKey"`
	Type      string         `json:"type" gorm:"not null;size:100;index"`
	Title     string         `json:"title" gorm:"not null;size:500"`
	Content   JSONB          `json:"content" gorm:"type:text"`
	Tags      StringSlice    `json:"tags" gorm:"type:text"`
	Status    string         `json:"status" gorm:"not null;size:20;default:'draft';index"`
	CreatedBy uint           `json:"created_by" gorm:"not null;index"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	Version   int            `json:"version" gorm:"default:1"`
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`

	// 关联关系
	Creator User `json:"creator" gorm:"foreignKey:CreatedBy"`
}

// AuditLog 审计日志模型
type AuditLog struct {
	ID           uint      `json:"id" gorm:"primaryKey"`
	UserID       uint      `json:"user_id" gorm:"not null;index"`
	Action       string    `json:"action" gorm:"not null;size:50"`
	ResourceType string    `json:"resource_type" gorm:"not null;size:100"`
	ResourceID   uint      `json:"resource_id" gorm:"not null"`
	OldValues    JSONB     `json:"old_values" gorm:"type:text"`
	NewValues    JSONB     `json:"new_values" gorm:"type:text"`
	IPAddress    string    `json:"ip_address" gorm:"size:45"`
	UserAgent    string    `json:"user_agent" gorm:"type:text"`
	CreatedAt    time.Time `json:"created_at"`

	// 关联关系
	User User `json:"user" gorm:"foreignKey:UserID"`
}

// File 文件模型
type File struct {
	ID           uint           `json:"id" gorm:"primaryKey"`
	Filename     string         `json:"filename" gorm:"not null;size:255"`
	OriginalName string         `json:"original_name" gorm:"not null;size:255"`
	MimeType     string         `json:"mime_type" gorm:"not null;size:100"`
	Size         int64          `json:"size" gorm:"not null"`
	Path         string         `json:"path" gorm:"not null;size:500"`
	Hash         string         `json:"hash" gorm:"size:64;index"`
	UploadedBy   uint           `json:"uploaded_by" gorm:"not null;index"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `json:"-" gorm:"index"`

	// 关联关系
	Uploader User `json:"uploader" gorm:"foreignKey:UploadedBy"`
}

// Config 配置模型
type Config struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	Key         string    `json:"key" gorm:"uniqueIndex;not null;size:100"`
	Value       string    `json:"value" gorm:"type:text"`
	Category    string    `json:"category" gorm:"not null;size:50;index"`
	Description string    `json:"description" gorm:"size:500"`
	IsSystem    bool      `json:"is_system" gorm:"default:false"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}
