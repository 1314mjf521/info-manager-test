package models

import (
	"time"

	"gorm.io/gorm"
)

// ExportTemplate 导出模板模型
type ExportTemplate struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Name        string         `json:"name" gorm:"not null;size:255"`
	Description string         `json:"description" gorm:"size:500"`
	Format      string         `json:"format" gorm:"not null;size:50"` // excel, pdf, csv, json
	Config      string         `json:"config" gorm:"type:text"`        // JSON配置
	Fields      string         `json:"fields" gorm:"type:text"`        // 导出字段配置
	IsSystem    bool           `json:"is_system" gorm:"default:false"` // 是否系统模板
	IsActive    bool           `json:"is_active" gorm:"default:true"`  // 是否启用
	CreatedBy   uint           `json:"created_by" gorm:"not null"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"-" gorm:"index"`

	// 关联关系
	Creator User `json:"creator" gorm:"foreignKey:CreatedBy"`
}

// ExportTask 导出任务模型
type ExportTask struct {
	ID           uint           `json:"id" gorm:"primaryKey"`
	TaskName     string         `json:"task_name" gorm:"not null;size:255"`
	TemplateID   *uint          `json:"template_id"`                    // 可选，使用模板
	Format       string         `json:"format" gorm:"not null;size:50"` // excel, pdf, csv, json
	Status       string         `json:"status" gorm:"not null;size:50"` // pending, processing, completed, failed
	Progress     int            `json:"progress" gorm:"default:0"`      // 进度百分比
	TotalRecords int            `json:"total_records" gorm:"default:0"` // 总记录数
	ProcessedRecords int        `json:"processed_records" gorm:"default:0"` // 已处理记录数
	FilePath     string         `json:"file_path" gorm:"size:500"`      // 导出文件路径
	FileSize     int64          `json:"file_size" gorm:"default:0"`     // 文件大小
	ErrorMessage string         `json:"error_message" gorm:"type:text"` // 错误信息
	Config       string         `json:"config" gorm:"type:text"`        // 导出配置
	StartedAt    *time.Time     `json:"started_at"`                     // 开始时间
	CompletedAt  *time.Time     `json:"completed_at"`                   // 完成时间
	ExpiresAt    *time.Time     `json:"expires_at"`                     // 过期时间
	CreatedBy    uint           `json:"created_by" gorm:"not null"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `json:"-" gorm:"index"`

	// 关联关系
	Template *ExportTemplate `json:"template" gorm:"foreignKey:TemplateID"`
	Creator  User            `json:"creator" gorm:"foreignKey:CreatedBy"`
}

// ExportFile 导出文件模型
type ExportFile struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	TaskID      uint           `json:"task_id" gorm:"not null"`
	FileName    string         `json:"file_name" gorm:"not null;size:255"`
	FilePath    string         `json:"file_path" gorm:"not null;size:500"`
	FileSize    int64          `json:"file_size" gorm:"not null"`
	Format      string         `json:"format" gorm:"not null;size:50"`
	DownloadCount int          `json:"download_count" gorm:"default:0"`
	ExpiresAt   *time.Time     `json:"expires_at"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"-" gorm:"index"`

	// 关联关系
	Task ExportTask `json:"task" gorm:"foreignKey:TaskID"`
}

// TableName 设置表名
func (ExportTemplate) TableName() string {
	return "export_templates"
}

func (ExportTask) TableName() string {
	return "export_tasks"
}

func (ExportFile) TableName() string {
	return "export_files"
}