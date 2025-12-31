package services

import (
	"context"
	"fmt"
	"strings"
	"time"

	"info-management-system/internal/models"

	"gorm.io/gorm"
)

// RecordService 记录服务
type RecordService struct {
	db                *gorm.DB
	recordTypeService *RecordTypeService
	auditService      *AuditService
}

// NewRecordService 创建记录服务
func NewRecordService(db *gorm.DB, recordTypeService *RecordTypeService, auditService *AuditService) *RecordService {
	return &RecordService{
		db:                db,
		recordTypeService: recordTypeService,
		auditService:      auditService,
	}
}

// CreateRecordRequest 创建记录请求
type CreateRecordRequest struct {
	Type    string                 `json:"type" binding:"required"`
	Title   string                 `json:"title" binding:"required,min=1,max=500"`
	Content map[string]interface{} `json:"content" binding:"required"`
	Tags    []string               `json:"tags"`
}

// UpdateRecordRequest 更新记录请求
type UpdateRecordRequest struct {
	Title   string                 `json:"title" binding:"omitempty,min=1,max=500"`
	Content map[string]interface{} `json:"content"`
	Tags    []string               `json:"tags"`
}

// BatchCreateRequest 批量创建请求
type BatchCreateRequest struct {
	Records []CreateRecordRequest `json:"records" binding:"required,min=1,max=100"`
}

// ImportRecordsRequest 导入记录请求
type ImportRecordsRequest struct {
	Type    string                   `json:"type" binding:"required"`
	Records []map[string]interface{} `json:"records" binding:"required,min=1,max=100"`
}

// BatchUpdateRecordStatusRequest 批量更新记录状态请求
type BatchUpdateRecordStatusRequest struct {
	RecordIDs []uint `json:"record_ids" binding:"required"`
	Status    string `json:"status" binding:"required,oneof=draft published archived"`
}

// BatchDeleteRecordsRequest 批量删除记录请求
type BatchDeleteRecordsRequest struct {
	RecordIDs []uint `json:"record_ids" binding:"required"`
}

// RecordResponse 记录响应
type RecordResponse struct {
	ID        uint                   `json:"id"`
	Type      string                 `json:"type"`
	Title     string                 `json:"title"`
	Content   map[string]interface{} `json:"content"`
	Tags      []string               `json:"tags"`
	Status    string                 `json:"status"`
	CreatedBy uint                   `json:"created_by"`
	Creator   string                 `json:"creator"`
	Version   int                    `json:"version"`
	CreatedAt string                 `json:"created_at"`
	UpdatedAt string                 `json:"updated_at"`
}

// RecordListQuery 记录列表查询参数
type RecordListQuery struct {
	Type      string `form:"type"`
	Search    string `form:"search"`
	Tags      string `form:"tags"`
	CreatedBy uint   `form:"created_by"`
	Page      int    `form:"page,default=1"`
	PageSize  int    `form:"page_size,default=20"`
	SortBy    string `form:"sort_by,default=created_at"`
	SortOrder string `form:"sort_order,default=desc"`
}

// RecordListResponse 记录列表响应
type RecordListResponse struct {
	Records    []RecordResponse `json:"records"`
	Total      int64            `json:"total"`
	Page       int              `json:"page"`
	PageSize   int              `json:"page_size"`
	TotalPages int              `json:"total_pages"`
}

// GetRecords 获取记录列表
func (s *RecordService) GetRecords(query *RecordListQuery, userID uint, hasAllPermission bool) (*RecordListResponse, error) {
	db := s.db.Model(&models.Record{}).Preload("Creator")

	// 权限过滤：如果没有查看所有记录的权限，只能查看自己的记录
	if !hasAllPermission {
		db = db.Where("created_by = ?", userID)
	}

	// 类型过滤
	if query.Type != "" {
		db = db.Where("type = ?", query.Type)
	}

	// 创建者过滤
	if query.CreatedBy > 0 {
		db = db.Where("created_by = ?", query.CreatedBy)
	}

	// 搜索过滤
	if query.Search != "" {
		searchTerm := "%" + query.Search + "%"
		db = db.Where("title LIKE ? OR content LIKE ?", searchTerm, searchTerm)
	}

	// 标签过滤
	if query.Tags != "" {
		tags := strings.Split(query.Tags, ",")
		for _, tag := range tags {
			tag = strings.TrimSpace(tag)
			if tag != "" {
				db = db.Where("tags LIKE ?", "%"+tag+"%")
			}
		}
	}

	// 获取总数
	var total int64
	if err := db.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取记录总数失败: %w", err)
	}

	// 排序
	orderBy := query.SortBy
	if query.SortOrder == "desc" {
		orderBy += " DESC"
	} else {
		orderBy += " ASC"
	}
	db = db.Order(orderBy)

	// 分页
	offset := (query.Page - 1) * query.PageSize
	db = db.Offset(offset).Limit(query.PageSize)

	// 查询记录
	var records []models.Record
	if err := db.Find(&records).Error; err != nil {
		return nil, fmt.Errorf("获取记录列表失败: %w", err)
	}

	// 转换响应
	recordResponses := make([]RecordResponse, len(records))
	for i, record := range records {
		recordResponses[i] = RecordResponse{
			ID:        record.ID,
			Type:      record.Type,
			Title:     record.Title,
			Content:   record.Content,
			Tags:      []string(record.Tags),
			CreatedBy: record.CreatedBy,
			Creator:   record.Creator.Username,
			Version:   record.Version,
			CreatedAt: record.CreatedAt.Format("2006-01-02 15:04:05"),
			UpdatedAt: record.UpdatedAt.Format("2006-01-02 15:04:05"),
		}
	}

	// 计算总页数
	totalPages := int((total + int64(query.PageSize) - 1) / int64(query.PageSize))

	return &RecordListResponse{
		Records:    recordResponses,
		Total:      total,
		Page:       query.Page,
		PageSize:   query.PageSize,
		TotalPages: totalPages,
	}, nil
}

// GetRecordByID 根据ID获取记录
func (s *RecordService) GetRecordByID(id uint, userID uint, hasAllPermission bool) (*RecordResponse, error) {
	var record models.Record
	query := s.db.Preload("Creator")

	// 权限过滤
	if !hasAllPermission {
		query = query.Where("created_by = ?", userID)
	}

	if err := query.First(&record, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("记录不存在或无权访问")
		}
		return nil, fmt.Errorf("获取记录失败: %w", err)
	}

	return &RecordResponse{
		ID:        record.ID,
		Type:      record.Type,
		Title:     record.Title,
		Content:   record.Content,
		Tags:      []string(record.Tags),
		CreatedBy: record.CreatedBy,
		Creator:   record.Creator.Username,
		Version:   record.Version,
		CreatedAt: record.CreatedAt.Format("2006-01-02 15:04:05"),
		UpdatedAt: record.UpdatedAt.Format("2006-01-02 15:04:05"),
	}, nil
}

// CreateRecord 创建记录
func (s *RecordService) CreateRecord(req *CreateRecordRequest, userID uint, ipAddress, userAgent string) (*RecordResponse, error) {
	// 验证记录类型和数据
	if err := s.recordTypeService.ValidateRecordData(req.Type, req.Content); err != nil {
		return nil, fmt.Errorf("数据验证失败: %w", err)
	}

	record := models.Record{
		Type:      req.Type,
		Title:     req.Title,
		Content:   models.JSONB(req.Content),
		Tags:      models.StringSlice(req.Tags),
		CreatedBy: userID,
		Version:   1,
	}

	if err := s.db.Create(&record).Error; err != nil {
		return nil, fmt.Errorf("创建记录失败: %w", err)
	}

	// 记录审计日志
	if s.auditService != nil {
		s.auditService.LogRecordOperation(userID, "CREATE", record.ID, nil, &record, ipAddress, userAgent)
	}

	// 重新获取记录（包含关联数据）
	return s.GetRecordByID(record.ID, userID, true)
}

// UpdateRecord 更新记录
func (s *RecordService) UpdateRecord(id uint, req *UpdateRecordRequest, userID uint, hasAllPermission bool, ipAddress, userAgent string) (*RecordResponse, error) {
	var record models.Record
	query := s.db

	// 权限过滤
	if !hasAllPermission {
		query = query.Where("created_by = ?", userID)
	}

	if err := query.First(&record, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("记录不存在或无权修改")
		}
		return nil, fmt.Errorf("获取记录失败: %w", err)
	}

	// 保存旧值用于审计
	oldRecord := record

	// 验证数据（如果有内容更新）
	if req.Content != nil {
		if err := s.recordTypeService.ValidateRecordData(record.Type, req.Content); err != nil {
			return nil, fmt.Errorf("数据验证失败: %w", err)
		}
		record.Content = models.JSONB(req.Content)
	}

	// 更新字段
	if req.Title != "" {
		record.Title = req.Title
	}

	if req.Tags != nil {
		record.Tags = models.StringSlice(req.Tags)
	}

	// 增加版本号
	record.Version++

	if err := s.db.Save(&record).Error; err != nil {
		return nil, fmt.Errorf("更新记录失败: %w", err)
	}

	// 记录审计日志
	if s.auditService != nil {
		s.auditService.LogRecordOperation(userID, "UPDATE", record.ID, &oldRecord, &record, ipAddress, userAgent)
	}

	// 重新获取记录
	return s.GetRecordByID(record.ID, userID, hasAllPermission)
}

// DeleteRecord 删除记录
func (s *RecordService) DeleteRecord(id uint, userID uint, hasAllPermission bool, ipAddress, userAgent string) error {
	var record models.Record
	query := s.db

	// 权限过滤
	if !hasAllPermission {
		query = query.Where("created_by = ?", userID)
	}

	if err := query.First(&record, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("记录不存在或无权删除")
		}
		return fmt.Errorf("获取记录失败: %w", err)
	}

	if err := s.db.Delete(&record).Error; err != nil {
		return fmt.Errorf("删除记录失败: %w", err)
	}

	// 记录审计日志
	if s.auditService != nil {
		s.auditService.LogRecordOperation(userID, "DELETE", record.ID, &record, nil, ipAddress, userAgent)
	}

	return nil
}

// BatchCreateRecords 批量创建记录
func (s *RecordService) BatchCreateRecords(req *BatchCreateRequest, userID uint, ipAddress, userAgent string) ([]RecordResponse, error) {
	var results []RecordResponse
	var errors []string

	// 开始事务
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	for i, recordReq := range req.Records {
		// 验证记录类型和数据
		if err := s.recordTypeService.ValidateRecordData(recordReq.Type, recordReq.Content); err != nil {
			errors = append(errors, fmt.Sprintf("记录 %d: %v", i+1, err))
			continue
		}

		record := models.Record{
			Type:      recordReq.Type,
			Title:     recordReq.Title,
			Content:   models.JSONB(recordReq.Content),
			Tags:      recordReq.Tags,
			CreatedBy: userID,
			Version:   1,
		}

		if err := tx.Create(&record).Error; err != nil {
			errors = append(errors, fmt.Sprintf("记录 %d: 创建失败 - %v", i+1, err))
			continue
		}

		// 记录审计日志
		if s.auditService != nil {
			s.auditService.LogRecordOperation(userID, "BATCH_CREATE", record.ID, nil, &record, ipAddress, userAgent)
		}

		// 获取创建者信息
		var user models.User
		tx.First(&user, userID)

		results = append(results, RecordResponse{
			ID:        record.ID,
			Type:      record.Type,
			Title:     record.Title,
			Content:   recordReq.Content,
			Tags:      []string(record.Tags),
			CreatedBy: record.CreatedBy,
			Creator:   user.Username,
			Version:   record.Version,
			CreatedAt: record.CreatedAt.Format("2006-01-02 15:04:05"),
			UpdatedAt: record.UpdatedAt.Format("2006-01-02 15:04:05"),
		})
	}

	if len(errors) > 0 {
		tx.Rollback()
		return nil, fmt.Errorf("批量创建失败: %s", strings.Join(errors, "; "))
	}

	if err := tx.Commit().Error; err != nil {
		return nil, fmt.Errorf("提交事务失败: %w", err)
	}

	return results, nil
}

// retryOnBusy 在数据库忙时重试操作，使用指数退避策略
func retryOnBusy(operation func() error, maxRetries int) error {
	var err error
	baseDelay := 50 * time.Millisecond
	maxDelay := 2 * time.Second

	for i := 0; i < maxRetries; i++ {
		err = operation()
		if err == nil {
			return nil
		}

		// 检查是否是数据库忙错误
		if strings.Contains(err.Error(), "database is locked") ||
			strings.Contains(err.Error(), "SQLITE_BUSY") ||
			strings.Contains(err.Error(), "database is busy") {
			if i < maxRetries-1 {
				// 使用指数退避策略计算延迟时间
				multiplier := 1
				for j := 0; j < i; j++ {
					multiplier *= 2
				}
				delay := time.Duration(int64(baseDelay) * int64(multiplier))
				if delay > maxDelay {
					delay = maxDelay
				}

				// 添加随机抖动，避免多个请求同时重试
				jitter := time.Duration(float64(delay) * 0.1 * (0.5 + 0.5*float64(i%10)/10))
				time.Sleep(delay + jitter)
				continue
			}
		}

		// 非忙错误或重试次数用完，直接返回
		return err
	}
	return err
}

// ImportRecords 导入记录，优化批量处理和错误恢复
func (s *RecordService) ImportRecords(req *ImportRecordsRequest, userID uint, ipAddress, userAgent string) ([]RecordResponse, error) {
	var results []RecordResponse
	var errors []string

	// 预先验证记录类型
	if err := s.recordTypeService.ValidateRecordData(req.Type, map[string]interface{}{"test": "test"}); err != nil {
		return nil, fmt.Errorf("记录类型验证失败: %w", err)
	}

	// 预先获取用户信息，避免在循环中重复查询
	var user models.User
	if err := s.db.Select("id, username").First(&user, userID).Error; err != nil {
		return nil, fmt.Errorf("用户不存在")
	}

	// 对于SQLite，使用更小的批次大小以避免锁定问题
	batchSize := 3 // SQLite适合的小批次
	maxRetries := 3

	// 分批处理记录
	for i := 0; i < len(req.Records); i += batchSize {
		end := i + batchSize
		if end > len(req.Records) {
			end = len(req.Records)
		}

		batch := req.Records[i:end]
		
		// 重试机制处理批次
		var batchResults []RecordResponse
		var batchErrors []string
		
		for retry := 0; retry < maxRetries; retry++ {
			batchResults, batchErrors = s.importRecordBatchOptimized(batch, req.Type, userID, ipAddress, userAgent, i+1)
			
			// 如果成功或者不是数据库锁定错误，跳出重试
			if len(batchErrors) == 0 || !s.isDatabaseBusyError(batchErrors) {
				break
			}
			
			// 等待后重试
			time.Sleep(time.Duration(retry+1) * 100 * time.Millisecond)
		}

		results = append(results, batchResults...)
		if len(batchErrors) > 0 {
			errors = append(errors, batchErrors...)
		}

		// 批次间短暂延迟，让SQLite有时间处理
		if end < len(req.Records) {
			time.Sleep(50 * time.Millisecond)
		}
	}

	if len(errors) > 0 {
		return results, fmt.Errorf("部分导入失败: %s", strings.Join(errors, "; "))
	}

	return results, nil
}

// isDatabaseBusyError 检查是否是数据库忙碌错误
func (s *RecordService) isDatabaseBusyError(errors []string) bool {
	for _, err := range errors {
		if strings.Contains(err, "database is locked") || 
		   strings.Contains(err, "context deadline exceeded") ||
		   strings.Contains(err, "database is busy") {
			return true
		}
	}
	return false
}

// min 和 max 辅助函数
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

// importRecordBatchOptimized 优化的批次导入方法
func (s *RecordService) importRecordBatchOptimized(records []map[string]interface{}, recordType string, userID uint, ipAddress, userAgent string, startIndex int) ([]RecordResponse, []string) {
	var results []RecordResponse
	var errors []string

	// 使用更短的超时时间，适合SQLite
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	// 预处理和验证所有记录
	validRecords := make([]models.Record, 0, len(records))
	for i, recordData := range records {
		// 提取标题
		title, ok := recordData["title"].(string)
		if !ok || title == "" {
			errors = append(errors, fmt.Sprintf("记录 %d: 缺少标题", startIndex+i))
			continue
		}

		// 移除title，剩余的作为content
		content := make(map[string]interface{})
		for k, v := range recordData {
			if k != "title" && k != "tags" {
				content[k] = v
			}
		}

		// 验证数据
		if err := s.recordTypeService.ValidateRecordData(recordType, content); err != nil {
			errors = append(errors, fmt.Sprintf("记录 %d: %v", startIndex+i, err))
			continue
		}

		// 提取标签
		var tags []string
		if tagsData, exists := recordData["tags"]; exists && tagsData != nil {
			if tagsList, ok := tagsData.([]interface{}); ok {
				for _, tag := range tagsList {
					if tagStr, ok := tag.(string); ok {
						tags = append(tags, tagStr)
					}
				}
			}
		}

		record := models.Record{
			Type:      recordType,
			Title:     title,
			Content:   models.JSONB(content),
			Tags:      tags,
			CreatedBy: userID,
			Status:    "draft",
			Version:   1,
		}

		validRecords = append(validRecords, record)
	}

	// 如果没有有效记录，直接返回
	if len(validRecords) == 0 {
		return results, errors
	}

	// 使用事务批量插入
	tx := s.db.WithContext(ctx).Begin()
	if tx.Error != nil {
		errors = append(errors, fmt.Sprintf("批次导入失败: 开始事务失败 - %v", tx.Error))
		return results, errors
	}

	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
			panic(r)
		}
	}()

	// 批量创建记录
	if err := tx.Create(&validRecords).Error; err != nil {
		tx.Rollback()
		errors = append(errors, fmt.Sprintf("批次导入失败: %v", err))
		return results, errors
	}

	// 提交事务
	if err := tx.Commit().Error; err != nil {
		errors = append(errors, fmt.Sprintf("批次导入失败: 提交事务失败 - %v", err))
		return results, errors
	}

	// 构建返回结果
	for _, record := range validRecords {
		results = append(results, RecordResponse{
			ID:        record.ID,
			Type:      record.Type,
			Title:     record.Title,
			Content:   map[string]interface{}(record.Content),
			Tags:      record.Tags,
			Status:    record.Status,
			CreatedBy: record.CreatedBy,
			CreatedAt: record.CreatedAt.Format("2006-01-02 15:04:05"),
			UpdatedAt: record.UpdatedAt.Format("2006-01-02 15:04:05"),
			Version:   record.Version,
		})
	}

	return results, errors
}

// importRecordBatch 导入记录批次，优化事务处理和错误恢复（保留原方法以兼容）
func (s *RecordService) importRecordBatch(records []map[string]interface{}, recordType string, userID uint, ipAddress, userAgent string) ([]RecordResponse, []string) {
	var results []RecordResponse
	var errors []string

	// 预先获取用户信息，避免在事务中查询
	var user models.User
	s.db.First(&user, userID)

	// 使用更强的重试机制执行批次导入
	err := retryOnBusy(func() error {
		// 清空之前的结果和错误，准备重试
		results = results[:0]
		errors = errors[:0]

		// 使用上下文控制事务超时
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		tx := s.db.WithContext(ctx).Begin()
		if tx.Error != nil {
			return fmt.Errorf("开始事务失败: %w", tx.Error)
		}

		defer func() {
			if r := recover(); r != nil {
				tx.Rollback()
				panic(r)
			}
		}()

		// 预处理所有记录，验证数据
		validRecords := make([]map[string]interface{}, 0, len(records))
		for i, recordData := range records {
			// 提取标题
			title, ok := recordData["title"].(string)
			if !ok || title == "" {
				errors = append(errors, fmt.Sprintf("记录 %d: 缺少标题", i+1))
				continue
			}

			// 移除title，剩余的作为content
			content := make(map[string]interface{})
			for k, v := range recordData {
				if k != "title" && k != "tags" {
					content[k] = v
				}
			}

			// 验证数据
			if err := s.recordTypeService.ValidateRecordData(recordType, content); err != nil {
				errors = append(errors, fmt.Sprintf("记录 %d: %v", i+1, err))
				continue
			}

			// 添加处理后的数据
			processedRecord := make(map[string]interface{})
			processedRecord["title"] = title
			processedRecord["content"] = content
			processedRecord["tags"] = recordData["tags"]
			processedRecord["index"] = i + 1
			validRecords = append(validRecords, processedRecord)
		}

		// 批量插入有效记录
		for _, processedRecord := range validRecords {
			title := processedRecord["title"].(string)
			content := processedRecord["content"].(map[string]interface{})
			index := processedRecord["index"].(int)

			// 提取标签
			var tags []string
			if tagsData, exists := processedRecord["tags"]; exists && tagsData != nil {
				if tagsList, ok := tagsData.([]interface{}); ok {
					for _, tag := range tagsList {
						if tagStr, ok := tag.(string); ok {
							tags = append(tags, tagStr)
						}
					}
				}
			}

			record := models.Record{
				Type:      recordType,
				Title:     title,
				Content:   models.JSONB(content),
				Tags:      tags,
				CreatedBy: userID,
				Version:   1,
			}

			if err := tx.Create(&record).Error; err != nil {
				errors = append(errors, fmt.Sprintf("记录 %d: 创建失败 - %v", index, err))
				continue
			}

			// 异步记录审计日志，避免阻塞事务
			go func(recordID uint) {
				if s.auditService != nil {
					s.auditService.LogRecordOperation(userID, "IMPORT", recordID, nil, &record, ipAddress, userAgent)
				}
			}(record.ID)

			results = append(results, RecordResponse{
				ID:        record.ID,
				Type:      record.Type,
				Title:     record.Title,
				Content:   content,
				Tags:      []string(record.Tags),
				CreatedBy: record.CreatedBy,
				Creator:   user.Username,
				Version:   record.Version,
				CreatedAt: record.CreatedAt.Format("2006-01-02 15:04:05"),
				UpdatedAt: record.UpdatedAt.Format("2006-01-02 15:04:05"),
			})
		}

		// 如果有太多错误，回滚事务
		if len(errors) > len(records)/2 {
			tx.Rollback()
			return fmt.Errorf("批次导入失败，错误过多")
		}

		// 提交事务
		if err := tx.Commit().Error; err != nil {
			return fmt.Errorf("提交事务失败: %w", err)
		}

		return nil
	}, 5) // 增加重试次数到5次

	if err != nil {
		errors = append(errors, fmt.Sprintf("批次导入失败: %v", err))
		// 清空结果，因为事务已回滚
		results = results[:0]
	}

	return results, errors
}

// GetRecordOwner 获取记录所有者ID（用于权限检查）
func (s *RecordService) GetRecordOwner(recordID uint) (uint, error) {
	var record models.Record
	if err := s.db.Select("created_by").First(&record, recordID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return 0, fmt.Errorf("记录不存在")
		}
		return 0, fmt.Errorf("获取记录失败: %w", err)
	}
	return record.CreatedBy, nil
}

// BatchUpdateRecordStatus 批量更新记录状态
func (s *RecordService) BatchUpdateRecordStatus(req *BatchUpdateRecordStatusRequest, userID uint) error {
	// 验证请求参数
	if len(req.RecordIDs) == 0 {
		return fmt.Errorf("无效的记录ID")
	}

	// 检查记录是否存在并且用户有权限更新
	var existingRecords []models.Record
	query := s.db.Where("id IN ?", req.RecordIDs)

	// 如果不是管理员，只能更新自己的记录
	// 这里简化处理，实际应该通过权限服务检查
	query = query.Where("created_by = ?", userID)

	if err := query.Find(&existingRecords).Error; err != nil {
		return fmt.Errorf("查询记录失败: %w", err)
	}

	if len(existingRecords) == 0 {
		return fmt.Errorf("没有找到可更新的记录，请检查记录ID和权限")
	}

	// 获取要更新的记录ID
	var recordIDsToUpdate []uint
	for _, record := range existingRecords {
		recordIDsToUpdate = append(recordIDsToUpdate, record.ID)
	}

	// 使用事务进行批量更新
	err := s.db.Transaction(func(tx *gorm.DB) error {
		// 执行批量更新
		result := tx.Model(&models.Record{}).Where("id IN ?", recordIDsToUpdate).Update("status", req.Status)
		if result.Error != nil {
			return fmt.Errorf("批量更新记录状态失败: %w", result.Error)
		}

		return nil
	})

	if err != nil {
		return err
	}

	// 异步记录审计日志，避免阻塞主流程
	if s.auditService != nil {
		go func() {
			for _, recordID := range recordIDsToUpdate {
				s.auditService.LogRecordOperation(userID, "BATCH_UPDATE_STATUS", recordID, nil, nil, "", "")
			}
		}()
	}

	return nil
}

// BatchDeleteRecords 批量删除记录
func (s *RecordService) BatchDeleteRecords(req *BatchDeleteRecordsRequest, userID uint) error {
	// 验证请求参数
	if len(req.RecordIDs) == 0 {
		return fmt.Errorf("无效的记录ID")
	}

	// 检查记录是否存在并且用户有权限删除
	var existingRecords []models.Record
	query := s.db.Where("id IN ?", req.RecordIDs)

	// 如果不是管理员，只能删除自己的记录
	// 这里简化处理，实际应该通过权限服务检查
	query = query.Where("created_by = ?", userID)

	if err := query.Find(&existingRecords).Error; err != nil {
		return fmt.Errorf("查询记录失败: %w", err)
	}

	if len(existingRecords) == 0 {
		return fmt.Errorf("没有找到可删除的记录，请检查记录ID和权限")
	}

	// 获取要删除的记录ID
	var recordIDsToDelete []uint
	for _, record := range existingRecords {
		recordIDsToDelete = append(recordIDsToDelete, record.ID)
	}

	// 使用事务进行批量删除
	err := s.db.Transaction(func(tx *gorm.DB) error {
		// 执行软删除
		result := tx.Where("id IN ?", recordIDsToDelete).Delete(&models.Record{})
		if result.Error != nil {
			return fmt.Errorf("批量删除记录失败: %w", result.Error)
		}

		return nil
	})

	if err != nil {
		return err
	}

	// 异步记录审计日志，避免阻塞主流程
	if s.auditService != nil {
		go func() {
			for _, recordID := range recordIDsToDelete {
				s.auditService.LogRecordOperation(userID, "BATCH_DELETE", recordID, nil, nil, "", "")
			}
		}()
	}

	return nil
}

// GetRecordsByType 根据类型获取记录
func (s *RecordService) GetRecordsByType(recordType string, userID uint, hasAllPermission bool) ([]RecordResponse, error) {
	query := s.db.Model(&models.Record{}).Preload("Creator").Where("type = ?", recordType)

	// 权限过滤
	if !hasAllPermission {
		query = query.Where("created_by = ?", userID)
	}

	var records []models.Record
	if err := query.Find(&records).Error; err != nil {
		return nil, fmt.Errorf("获取记录失败: %w", err)
	}

	results := make([]RecordResponse, len(records))
	for i, record := range records {
		results[i] = RecordResponse{
			ID:        record.ID,
			Type:      record.Type,
			Title:     record.Title,
			Content:   record.Content,
			Tags:      []string(record.Tags),
			CreatedBy: record.CreatedBy,
			Creator:   record.Creator.Username,
			Version:   record.Version,
			CreatedAt: record.CreatedAt.Format("2006-01-02 15:04:05"),
			UpdatedAt: record.UpdatedAt.Format("2006-01-02 15:04:05"),
		}
	}

	return results, nil
}
