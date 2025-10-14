package services

import (
	"fmt"
	"time"

	"info-management-system/internal/models"

	"gorm.io/gorm"
)

// AuditService 审计服务
type AuditService struct {
	db *gorm.DB
}

// NewAuditService 创建审计服务
func NewAuditService(db *gorm.DB) *AuditService {
	return &AuditService{db: db}
}

// AuditLogRequest 审计日志请求
type AuditLogRequest struct {
	UserID       uint                   `json:"user_id"`
	Action       string                 `json:"action"`       // CREATE, UPDATE, DELETE, VIEW
	ResourceType string                 `json:"resource_type"` // record, record_type, user, role
	ResourceID   uint                   `json:"resource_id"`
	OldValues    map[string]interface{} `json:"old_values,omitempty"`
	NewValues    map[string]interface{} `json:"new_values,omitempty"`
	IPAddress    string                 `json:"ip_address,omitempty"`
	UserAgent    string                 `json:"user_agent,omitempty"`
}

// AuditLogResponse 审计日志响应
type AuditLogResponse struct {
	ID           uint                   `json:"id"`
	UserID       uint                   `json:"user_id"`
	Username     string                 `json:"username"`
	Action       string                 `json:"action"`
	ResourceType string                 `json:"resource_type"`
	ResourceID   uint                   `json:"resource_id"`
	OldValues    map[string]interface{} `json:"old_values"`
	NewValues    map[string]interface{} `json:"new_values"`
	IPAddress    string                 `json:"ip_address"`
	UserAgent    string                 `json:"user_agent"`
	CreatedAt    string                 `json:"created_at"`
}

// AuditLogQuery 审计日志查询参数
type AuditLogQuery struct {
	UserID       uint   `form:"user_id"`
	Action       string `form:"action"`
	ResourceType string `form:"resource_type"`
	ResourceID   uint   `form:"resource_id"`
	StartDate    string `form:"start_date"`
	EndDate      string `form:"end_date"`
	Page         int    `form:"page,default=1"`
	PageSize     int    `form:"page_size,default=20"`
}

// AuditLogListResponse 审计日志列表响应
type AuditLogListResponse struct {
	Logs       []AuditLogResponse `json:"logs"`
	Total      int64              `json:"total"`
	Page       int                `json:"page"`
	PageSize   int                `json:"page_size"`
	TotalPages int                `json:"total_pages"`
}

// CreateAuditLog 创建审计日志
func (s *AuditService) CreateAuditLog(req *AuditLogRequest) error {
	auditLog := models.AuditLog{
		UserID:       req.UserID,
		Action:       req.Action,
		ResourceType: req.ResourceType,
		ResourceID:   req.ResourceID,
		IPAddress:    req.IPAddress,
		UserAgent:    req.UserAgent,
	}

	if req.OldValues != nil {
		auditLog.OldValues = models.JSONB(req.OldValues)
	}

	if req.NewValues != nil {
		auditLog.NewValues = models.JSONB(req.NewValues)
	}

	if err := s.db.Create(&auditLog).Error; err != nil {
		return fmt.Errorf("创建审计日志失败: %w", err)
	}

	return nil
}

// GetAuditLogs 获取审计日志列表
func (s *AuditService) GetAuditLogs(query *AuditLogQuery) (*AuditLogListResponse, error) {
	db := s.db.Model(&models.AuditLog{}).Preload("User")

	// 用户过滤
	if query.UserID > 0 {
		db = db.Where("user_id = ?", query.UserID)
	}

	// 操作类型过滤
	if query.Action != "" {
		db = db.Where("action = ?", query.Action)
	}

	// 资源类型过滤
	if query.ResourceType != "" {
		db = db.Where("resource_type = ?", query.ResourceType)
	}

	// 资源ID过滤
	if query.ResourceID > 0 {
		db = db.Where("resource_id = ?", query.ResourceID)
	}

	// 时间范围过滤
	if query.StartDate != "" {
		startTime, err := time.Parse("2006-01-02", query.StartDate)
		if err == nil {
			db = db.Where("created_at >= ?", startTime)
		}
	}

	if query.EndDate != "" {
		endTime, err := time.Parse("2006-01-02", query.EndDate)
		if err == nil {
			// 结束时间设为当天的23:59:59
			endTime = endTime.Add(23*time.Hour + 59*time.Minute + 59*time.Second)
			db = db.Where("created_at <= ?", endTime)
		}
	}

	// 获取总数
	var total int64
	if err := db.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取审计日志总数失败: %w", err)
	}

	// 排序（按时间倒序）
	db = db.Order("created_at DESC")

	// 分页
	offset := (query.Page - 1) * query.PageSize
	db = db.Offset(offset).Limit(query.PageSize)

	// 查询日志
	var logs []models.AuditLog
	if err := db.Find(&logs).Error; err != nil {
		return nil, fmt.Errorf("获取审计日志列表失败: %w", err)
	}

	// 转换响应
	logResponses := make([]AuditLogResponse, len(logs))
	for i, log := range logs {
		logResponses[i] = AuditLogResponse{
			ID:           log.ID,
			UserID:       log.UserID,
			Username:     log.User.Username,
			Action:       log.Action,
			ResourceType: log.ResourceType,
			ResourceID:   log.ResourceID,
			OldValues:    log.OldValues,
			NewValues:    log.NewValues,
			IPAddress:    log.IPAddress,
			UserAgent:    log.UserAgent,
			CreatedAt:    log.CreatedAt.Format("2006-01-02 15:04:05"),
		}
	}

	// 计算总页数
	totalPages := int((total + int64(query.PageSize) - 1) / int64(query.PageSize))

	return &AuditLogListResponse{
		Logs:       logResponses,
		Total:      total,
		Page:       query.Page,
		PageSize:   query.PageSize,
		TotalPages: totalPages,
	}, nil
}

// GetResourceAuditLogs 获取特定资源的审计日志
func (s *AuditService) GetResourceAuditLogs(resourceType string, resourceID uint) ([]AuditLogResponse, error) {
	var logs []models.AuditLog
	if err := s.db.Preload("User").
		Where("resource_type = ? AND resource_id = ?", resourceType, resourceID).
		Order("created_at DESC").
		Find(&logs).Error; err != nil {
		return nil, fmt.Errorf("获取资源审计日志失败: %w", err)
	}

	results := make([]AuditLogResponse, len(logs))
	for i, log := range logs {
		results[i] = AuditLogResponse{
			ID:           log.ID,
			UserID:       log.UserID,
			Username:     log.User.Username,
			Action:       log.Action,
			ResourceType: log.ResourceType,
			ResourceID:   log.ResourceID,
			OldValues:    log.OldValues,
			NewValues:    log.NewValues,
			IPAddress:    log.IPAddress,
			UserAgent:    log.UserAgent,
			CreatedAt:    log.CreatedAt.Format("2006-01-02 15:04:05"),
		}
	}

	return results, nil
}

// GetUserAuditLogs 获取用户的审计日志
func (s *AuditService) GetUserAuditLogs(userID uint, limit int) ([]AuditLogResponse, error) {
	var logs []models.AuditLog
	query := s.db.Preload("User").Where("user_id = ?", userID).Order("created_at DESC")
	
	if limit > 0 {
		query = query.Limit(limit)
	}

	if err := query.Find(&logs).Error; err != nil {
		return nil, fmt.Errorf("获取用户审计日志失败: %w", err)
	}

	results := make([]AuditLogResponse, len(logs))
	for i, log := range logs {
		results[i] = AuditLogResponse{
			ID:           log.ID,
			UserID:       log.UserID,
			Username:     log.User.Username,
			Action:       log.Action,
			ResourceType: log.ResourceType,
			ResourceID:   log.ResourceID,
			OldValues:    log.OldValues,
			NewValues:    log.NewValues,
			IPAddress:    log.IPAddress,
			UserAgent:    log.UserAgent,
			CreatedAt:    log.CreatedAt.Format("2006-01-02 15:04:05"),
		}
	}

	return results, nil
}

// LogRecordOperation 记录记录操作的审计日志
func (s *AuditService) LogRecordOperation(userID uint, action string, recordID uint, oldRecord, newRecord *models.Record, ipAddress, userAgent string) error {
	var oldValues, newValues map[string]interface{}

	if oldRecord != nil {
		oldValues = map[string]interface{}{
			"type":    oldRecord.Type,
			"title":   oldRecord.Title,
			"content": oldRecord.Content,
			"tags":    oldRecord.Tags,
			"version": oldRecord.Version,
		}
	}

	if newRecord != nil {
		newValues = map[string]interface{}{
			"type":    newRecord.Type,
			"title":   newRecord.Title,
			"content": newRecord.Content,
			"tags":    newRecord.Tags,
			"version": newRecord.Version,
		}
	}

	return s.CreateAuditLog(&AuditLogRequest{
		UserID:       userID,
		Action:       action,
		ResourceType: "record",
		ResourceID:   recordID,
		OldValues:    oldValues,
		NewValues:    newValues,
		IPAddress:    ipAddress,
		UserAgent:    userAgent,
	})
}

// LogRecordTypeOperation 记录记录类型操作的审计日志
func (s *AuditService) LogRecordTypeOperation(userID uint, action string, recordTypeID uint, oldRecordType, newRecordType *models.RecordType, ipAddress, userAgent string) error {
	var oldValues, newValues map[string]interface{}

	if oldRecordType != nil {
		oldValues = map[string]interface{}{
			"name":         oldRecordType.Name,
			"display_name": oldRecordType.DisplayName,
			"schema":       oldRecordType.Schema,
			"is_active":    oldRecordType.IsActive,
		}
	}

	if newRecordType != nil {
		newValues = map[string]interface{}{
			"name":         newRecordType.Name,
			"display_name": newRecordType.DisplayName,
			"schema":       newRecordType.Schema,
			"is_active":    newRecordType.IsActive,
		}
	}

	return s.CreateAuditLog(&AuditLogRequest{
		UserID:       userID,
		Action:       action,
		ResourceType: "record_type",
		ResourceID:   recordTypeID,
		OldValues:    oldValues,
		NewValues:    newValues,
		IPAddress:    ipAddress,
		UserAgent:    userAgent,
	})
}

// GetAuditStatistics 获取审计统计信息
func (s *AuditService) GetAuditStatistics(days int) (map[string]interface{}, error) {
	startTime := time.Now().AddDate(0, 0, -days)

	// 按操作类型统计
	var actionStats []struct {
		Action string `json:"action"`
		Count  int64  `json:"count"`
	}

	if err := s.db.Model(&models.AuditLog{}).
		Select("action, COUNT(*) as count").
		Where("created_at >= ?", startTime).
		Group("action").
		Find(&actionStats).Error; err != nil {
		return nil, fmt.Errorf("获取操作统计失败: %w", err)
	}

	// 按资源类型统计
	var resourceStats []struct {
		ResourceType string `json:"resource_type"`
		Count        int64  `json:"count"`
	}

	if err := s.db.Model(&models.AuditLog{}).
		Select("resource_type, COUNT(*) as count").
		Where("created_at >= ?", startTime).
		Group("resource_type").
		Find(&resourceStats).Error; err != nil {
		return nil, fmt.Errorf("获取资源统计失败: %w", err)
	}

	// 按用户统计（前10名）
	var userStats []struct {
		UserID   uint   `json:"user_id"`
		Username string `json:"username"`
		Count    int64  `json:"count"`
	}

	if err := s.db.Model(&models.AuditLog{}).
		Select("audit_logs.user_id, users.username, COUNT(*) as count").
		Joins("LEFT JOIN users ON audit_logs.user_id = users.id").
		Where("audit_logs.created_at >= ?", startTime).
		Group("audit_logs.user_id, users.username").
		Order("count DESC").
		Limit(10).
		Find(&userStats).Error; err != nil {
		return nil, fmt.Errorf("获取用户统计失败: %w", err)
	}

	// 总操作数
	var totalOperations int64
	if err := s.db.Model(&models.AuditLog{}).
		Where("created_at >= ?", startTime).
		Count(&totalOperations).Error; err != nil {
		return nil, fmt.Errorf("获取总操作数失败: %w", err)
	}

	return map[string]interface{}{
		"total_operations": totalOperations,
		"action_stats":     actionStats,
		"resource_stats":   resourceStats,
		"user_stats":       userStats,
		"period_days":      days,
	}, nil
}

// LogFileOperation 记录文件操作的审计日志
func (s *AuditService) LogFileOperation(userID uint, action string, fileID uint, oldFile, newFile *models.File, ipAddress, userAgent string) error {
	var oldValues, newValues map[string]interface{}

	if oldFile != nil {
		oldValues = map[string]interface{}{
			"filename":      oldFile.Filename,
			"original_name": oldFile.OriginalName,
			"mime_type":     oldFile.MimeType,
			"size":          oldFile.Size,
			"path":          oldFile.Path,
			"hash":          oldFile.Hash,
		}
	}

	if newFile != nil {
		newValues = map[string]interface{}{
			"filename":      newFile.Filename,
			"original_name": newFile.OriginalName,
			"mime_type":     newFile.MimeType,
			"size":          newFile.Size,
			"path":          newFile.Path,
			"hash":          newFile.Hash,
		}
	}

	return s.CreateAuditLog(&AuditLogRequest{
		UserID:       userID,
		Action:       action,
		ResourceType: "file",
		ResourceID:   fileID,
		OldValues:    oldValues,
		NewValues:    newValues,
		IPAddress:    ipAddress,
		UserAgent:    userAgent,
	})
}

// CleanupOldAuditLogs 清理旧的审计日志
func (s *AuditService) CleanupOldAuditLogs(retentionDays int) (int64, error) {
	cutoffTime := time.Now().AddDate(0, 0, -retentionDays)

	result := s.db.Where("created_at < ?", cutoffTime).Delete(&models.AuditLog{})
	if result.Error != nil {
		return 0, fmt.Errorf("清理审计日志失败: %w", result.Error)
	}

	return result.RowsAffected, nil
}