package services

import (
	"encoding/json"
	"fmt"

	"info-management-system/internal/models"

	"gorm.io/gorm"
)

// RecordTypeService 记录类型服务
type RecordTypeService struct {
	db *gorm.DB
}

// NewRecordTypeService 创建记录类型服务
func NewRecordTypeService(db *gorm.DB) *RecordTypeService {
	return &RecordTypeService{db: db}
}

// CreateRecordTypeRequest 创建记录类型请求
type CreateRecordTypeRequest struct {
	Name        string                 `json:"name" binding:"required,min=2,max=100"`
	DisplayName string                 `json:"display_name" binding:"required,min=2,max=200"`
	Schema      map[string]interface{} `json:"schema" binding:"required"`
}

// UpdateRecordTypeRequest 更新记录类型请求
type UpdateRecordTypeRequest struct {
	DisplayName string                 `json:"display_name" binding:"omitempty,min=2,max=200"`
	Schema      map[string]interface{} `json:"schema"`
	IsActive    *bool                  `json:"is_active"`
}

// RecordTypeResponse 记录类型响应
type RecordTypeResponse struct {
	ID          uint                   `json:"id"`
	Name        string                 `json:"name"`
	DisplayName string                 `json:"display_name"`
	Schema      map[string]interface{} `json:"schema"`
	TableName   string                 `json:"table_name"`
	IsActive    bool                   `json:"is_active"`
	RecordCount int64                  `json:"record_count"`
	CreatedAt   string                 `json:"created_at"`
	UpdatedAt   string                 `json:"updated_at"`
}

// GetAllRecordTypes 获取所有记录类型
func (s *RecordTypeService) GetAllRecordTypes() ([]RecordTypeResponse, error) {
	var recordTypes []models.RecordType
	if err := s.db.Find(&recordTypes).Error; err != nil {
		return nil, fmt.Errorf("获取记录类型列表失败: %w", err)
	}

	result := make([]RecordTypeResponse, len(recordTypes))
	for i, recordType := range recordTypes {
		// 获取该类型的记录数量
		var recordCount int64
		s.db.Model(&models.Record{}).Where("type = ?", recordType.Name).Count(&recordCount)

		result[i] = RecordTypeResponse{
			ID:          recordType.ID,
			Name:        recordType.Name,
			DisplayName: recordType.DisplayName,
			Schema:      recordType.Schema,
			TableName:   recordType.TableName,
			IsActive:    recordType.IsActive,
			RecordCount: recordCount,
			CreatedAt:   recordType.CreatedAt.Format("2006-01-02 15:04:05"),
			UpdatedAt:   recordType.UpdatedAt.Format("2006-01-02 15:04:05"),
		}
	}

	return result, nil
}

// GetRecordTypeByID 根据ID获取记录类型
func (s *RecordTypeService) GetRecordTypeByID(id uint) (*RecordTypeResponse, error) {
	var recordType models.RecordType
	if err := s.db.First(&recordType, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("记录类型不存在")
		}
		return nil, fmt.Errorf("获取记录类型失败: %w", err)
	}

	// 获取该类型的记录数量
	var recordCount int64
	s.db.Model(&models.Record{}).Where("type = ?", recordType.Name).Count(&recordCount)

	return &RecordTypeResponse{
		ID:          recordType.ID,
		Name:        recordType.Name,
		DisplayName: recordType.DisplayName,
		Schema:      recordType.Schema,
		TableName:   recordType.TableName,
		IsActive:    recordType.IsActive,
		RecordCount: recordCount,
		CreatedAt:   recordType.CreatedAt.Format("2006-01-02 15:04:05"),
		UpdatedAt:   recordType.UpdatedAt.Format("2006-01-02 15:04:05"),
	}, nil
}

// GetRecordTypeByName 根据名称获取记录类型
func (s *RecordTypeService) GetRecordTypeByName(name string) (*models.RecordType, error) {
	var recordType models.RecordType
	if err := s.db.Where("name = ?", name).First(&recordType).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("记录类型不存在")
		}
		return nil, fmt.Errorf("获取记录类型失败: %w", err)
	}
	return &recordType, nil
}

// CreateRecordType 创建记录类型
func (s *RecordTypeService) CreateRecordType(req *CreateRecordTypeRequest) (*RecordTypeResponse, error) {
	// 检查名称是否已存在
	var count int64
	if err := s.db.Model(&models.RecordType{}).Where("name = ?", req.Name).Count(&count).Error; err != nil {
		return nil, fmt.Errorf("检查记录类型名称失败: %v", err)
	}
	if count > 0 {
		return nil, fmt.Errorf("记录类型名称已存在")
	}

	// 生成表名
	tableName := fmt.Sprintf("records_%s", req.Name)

	recordType := models.RecordType{
		Name:        req.Name,
		DisplayName: req.DisplayName,
		Schema:      models.JSONB(req.Schema),
		TableName:   tableName,
		IsActive:    true,
	}

	if err := s.db.Create(&recordType).Error; err != nil {
		return nil, fmt.Errorf("创建记录类型失败: %w", err)
	}

	return &RecordTypeResponse{
		ID:          recordType.ID,
		Name:        recordType.Name,
		DisplayName: recordType.DisplayName,
		Schema:      req.Schema,
		TableName:   recordType.TableName,
		IsActive:    recordType.IsActive,
		RecordCount: 0,
		CreatedAt:   recordType.CreatedAt.Format("2006-01-02 15:04:05"),
		UpdatedAt:   recordType.UpdatedAt.Format("2006-01-02 15:04:05"),
	}, nil
}

// UpdateRecordType 更新记录类型
func (s *RecordTypeService) UpdateRecordType(id uint, req *UpdateRecordTypeRequest) (*RecordTypeResponse, error) {
	var recordType models.RecordType
	if err := s.db.First(&recordType, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("记录类型不存在")
		}
		return nil, fmt.Errorf("获取记录类型失败: %w", err)
	}

	// 更新字段
	if req.DisplayName != "" {
		recordType.DisplayName = req.DisplayName
	}

	if req.Schema != nil {
		recordType.Schema = models.JSONB(req.Schema)
	}

	if req.IsActive != nil {
		recordType.IsActive = *req.IsActive
	}

	if err := s.db.Save(&recordType).Error; err != nil {
		return nil, fmt.Errorf("更新记录类型失败: %w", err)
	}

	// 重新获取记录类型详情
	return s.GetRecordTypeByID(id)
}

// DeleteRecordType 删除记录类型
func (s *RecordTypeService) DeleteRecordType(id uint) error {
	var recordType models.RecordType
	if err := s.db.First(&recordType, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("记录类型不存在")
		}
		return fmt.Errorf("获取记录类型失败: %w", err)
	}

	// 检查是否有记录使用该类型
	var recordCount int64
	s.db.Model(&models.Record{}).Where("type = ?", recordType.Name).Count(&recordCount)
	if recordCount > 0 {
		return fmt.Errorf("该记录类型正在被 %d 条记录使用，无法删除", recordCount)
	}

	if err := s.db.Delete(&recordType).Error; err != nil {
		return fmt.Errorf("删除记录类型失败: %w", err)
	}

	return nil
}

// ValidateRecordData 验证记录数据是否符合类型定义
func (s *RecordTypeService) ValidateRecordData(typeName string, data map[string]interface{}) error {
	recordType, err := s.GetRecordTypeByName(typeName)
	if err != nil {
		return err
	}

	if !recordType.IsActive {
		return fmt.Errorf("记录类型已禁用")
	}

	// 这里可以根据Schema进行更详细的数据验证
	// 目前只做基本检查
	if len(data) == 0 {
		return fmt.Errorf("记录内容不能为空")
	}

	return nil
}

// ImportRecordTypeData 导入记录类型数据结构
type ImportRecordTypeData struct {
	Name        string `json:"name" binding:"required"`
	DisplayName string `json:"displayName" binding:"required"`
	Schema      string `json:"schema"` // JSON字符串格式的Schema
	IsActive    string `json:"isActive"`
}

// ImportRecordTypesRequest 导入记录类型请求
type ImportRecordTypesRequest struct {
	RecordTypes []ImportRecordTypeData `json:"recordTypes" binding:"required"`
}

// ImportRecordTypeResult 导入记录类型结果
type ImportRecordTypeResult struct {
	Name         string `json:"name"`
	DisplayName  string `json:"displayName"`
	Success      bool   `json:"success"`
	Error        string `json:"error,omitempty"`
	RecordTypeID uint   `json:"record_type_id,omitempty"`
}

// BatchUpdateRecordTypeStatusRequest 批量更新记录类型状态请求
type BatchUpdateRecordTypeStatusRequest struct {
	RecordTypeIDs []uint `json:"record_type_ids" binding:"required"`
	IsActive      bool   `json:"is_active"`
}

// BatchDeleteRecordTypesRequest 批量删除记录类型请求
type BatchDeleteRecordTypesRequest struct {
	RecordTypeIDs []uint `json:"record_type_ids" binding:"required"`
}

// ImportRecordTypes 导入记录类型
func (s *RecordTypeService) ImportRecordTypes(req *ImportRecordTypesRequest) ([]ImportRecordTypeResult, error) {
	results := make([]ImportRecordTypeResult, 0, len(req.RecordTypes))

	for _, data := range req.RecordTypes {
		result := ImportRecordTypeResult{
			Name:        data.Name,
			DisplayName: data.DisplayName,
			Success:     false,
		}

		// 检查记录类型名是否已存在
		var existingRecordType models.RecordType
		if err := s.db.Where("name = ?", data.Name).First(&existingRecordType).Error; err == nil {
			result.Error = "记录类型名已存在"
			results = append(results, result)
			continue
		}

		// 解析Schema
		var schema map[string]interface{}
		if data.Schema != "" {
			// 尝试解析JSON字符串
			if err := json.Unmarshal([]byte(data.Schema), &schema); err != nil {
				// 如果解析失败，使用默认Schema
				schema = map[string]interface{}{
					"type": "object",
					"properties": map[string]interface{}{
						"content": map[string]interface{}{
							"type":        "string",
							"description": "内容",
						},
					},
				}
			}
		} else {
			// 使用默认Schema
			schema = map[string]interface{}{
				"type": "object",
				"properties": map[string]interface{}{
					"title": map[string]interface{}{
						"type":        "string",
						"description": "标题",
					},
					"content": map[string]interface{}{
						"type":        "string",
						"description": "内容",
					},
				},
				"required": []string{"title"},
			}
		}

		// 设置默认状态
		isActive := true
		if data.IsActive == "false" || data.IsActive == "0" {
			isActive = false
		}

		// 生成表名
		tableName := fmt.Sprintf("records_%s", data.Name)

		// 创建记录类型
		recordType := models.RecordType{
			Name:        data.Name,
			DisplayName: data.DisplayName,
			Schema:      models.JSONB(schema),
			TableName:   tableName,
			IsActive:    isActive,
		}

		if err := s.db.Create(&recordType).Error; err != nil {
			result.Error = "创建记录类型失败"
			results = append(results, result)
			continue
		}

		result.Success = true
		result.RecordTypeID = recordType.ID
		results = append(results, result)
	}

	return results, nil
}

// BatchUpdateRecordTypeStatus 批量更新记录类型状态
func (s *RecordTypeService) BatchUpdateRecordTypeStatus(req *BatchUpdateRecordTypeStatusRequest) error {
	return s.db.Model(&models.RecordType{}).Where("id IN ?", req.RecordTypeIDs).Update("is_active", req.IsActive).Error
}

// BatchDeleteRecordTypes 批量删除记录类型
func (s *RecordTypeService) BatchDeleteRecordTypes(req *BatchDeleteRecordTypesRequest) error {
	// 检查是否有记录使用这些类型
	var recordTypes []models.RecordType
	if err := s.db.Where("id IN ?", req.RecordTypeIDs).Find(&recordTypes).Error; err != nil {
		return fmt.Errorf("获取记录类型失败: %w", err)
	}

	for _, recordType := range recordTypes {
		var recordCount int64
		s.db.Model(&models.Record{}).Where("type = ?", recordType.Name).Count(&recordCount)
		if recordCount > 0 {
			return fmt.Errorf("记录类型 %s 正在被 %d 条记录使用，无法删除", recordType.DisplayName, recordCount)
		}
	}

	return s.db.Where("id IN ?", req.RecordTypeIDs).Delete(&models.RecordType{}).Error
}
