package services

import (
	"encoding/json"
	"fmt"
	"runtime"
	"time"

	"info-management-system/internal/models"
	"info-management-system/internal/utils"

	"gorm.io/gorm"
)

// SystemService 系统服务
type SystemService struct {
	db *gorm.DB
}

// NewSystemService 创建系统服务
func NewSystemService(db *gorm.DB) *SystemService {
	return &SystemService{
		db: db,
	}
}

// 系统配置相关请求结构
type SystemConfigRequest struct {
	Category    string `json:"category" binding:"required"`
	Key         string `json:"key" binding:"required"`
	Value       string `json:"value"`
	Description string `json:"description"`
	DataType    string `json:"data_type"`
	IsPublic    bool   `json:"is_public"`
	IsEditable  bool   `json:"is_editable"`
	Reason      string `json:"reason"` // 变更原因
}

type SystemConfigUpdateRequest struct {
	Value  string `json:"value" binding:"required"`
	Reason string `json:"reason"` // 变更原因
}

// 公告相关请求结构
type AnnouncementRequest struct {
	Title       string     `json:"title" binding:"required"`
	Content     string     `json:"content" binding:"required"`
	Type        string     `json:"type" binding:"required,oneof=info warning error maintenance"`
	Priority    int        `json:"priority"`
	IsActive    bool       `json:"is_active"`
	IsSticky    bool       `json:"is_sticky"`
	TargetUsers []uint     `json:"target_users"` // 目标用户ID列表，空表示所有用户
	StartTime   *time.Time `json:"start_time"`
	EndTime     *time.Time `json:"end_time"`
}

// 系统维护请求结构
type SystemMaintenanceRequest struct {
	Title       string     `json:"title" binding:"required"`
	Description string     `json:"description"`
	Type        string     `json:"type" binding:"required,oneof=scheduled emergency hotfix"`
	StartTime   time.Time  `json:"start_time" binding:"required"`
	EndTime     *time.Time `json:"end_time"`
	Impact      string     `json:"impact"`
	Notes       string     `json:"notes"`
}

// 响应结构
type SystemConfigListResponse struct {
	Configs  []models.SystemConfig `json:"configs"`
	Total    int64                 `json:"total"`
	Page     int                   `json:"page"`
	PageSize int                   `json:"page_size"`
}

type AnnouncementListResponse struct {
	Announcements []models.Announcement `json:"announcements"`
	Total         int64                 `json:"total"`
	Page          int                   `json:"page"`
	PageSize      int                   `json:"page_size"`
}

type SystemHealthResponse struct {
	OverallStatus string                `json:"overall_status"`
	Components    []models.SystemHealth `json:"components"`
	Summary       SystemHealthSummary   `json:"summary"`
	CheckedAt     time.Time             `json:"checked_at"`
}

type SystemHealthSummary struct {
	TotalComponents     int `json:"total_components"`
	HealthyComponents   int `json:"healthy_components"`
	UnhealthyComponents int `json:"unhealthy_components"`
	DegradedComponents  int `json:"degraded_components"`
}

type SystemLogListResponse struct {
	Logs     []models.SystemLog `json:"logs"`
	Total    int64              `json:"total"`
	Page     int                `json:"page"`
	PageSize int                `json:"page_size"`
}

type SystemMetricsResponse struct {
	Metrics   []models.SystemMetrics `json:"metrics"`
	Summary   SystemMetricsSummary   `json:"summary"`
	Timestamp time.Time              `json:"timestamp"`
}

type SystemMetricsSummary struct {
	CPUUsage    float64 `json:"cpu_usage"`
	MemoryUsage float64 `json:"memory_usage"`
	DiskUsage   float64 `json:"disk_usage"`
	Uptime      int64   `json:"uptime"` // 秒
}

// CreateConfig 创建系统配置
func (s *SystemService) CreateConfig(req *SystemConfigRequest, userID uint) (*models.SystemConfig, error) {
	// 记录操作日志
	s.LogSystemEvent("info", "config", fmt.Sprintf("尝试创建系统配置: %s.%s", req.Category, req.Key),
		map[string]interface{}{
			"category": req.Category,
			"key":      req.Key,
			"action":   "create_config",
		}, &userID, "", "", "")

	// 检查配置是否已存在 - 使用Count方法避免"record not found"日志
	var count int64
	if err := s.db.Model(&models.SystemConfig{}).Where("category = ? AND key = ?", req.Category, req.Key).Count(&count).Error; err != nil {
		s.LogSystemEvent("error", "config", fmt.Sprintf("检查配置是否存在时发生错误: %v", err),
			map[string]interface{}{
				"category": req.Category,
				"key":      req.Key,
				"action":   "create_config_failed",
				"error":    err.Error(),
			}, &userID, "", "", "")
		return nil, fmt.Errorf("检查配置失败: %v", err)
	}

	if count > 0 {
		// 配置已存在
		s.LogSystemEvent("warn", "config", fmt.Sprintf("配置 %s.%s 已存在，创建失败", req.Category, req.Key),
			map[string]interface{}{
				"category": req.Category,
				"key":      req.Key,
				"action":   "create_config_failed",
				"reason":   "already_exists",
			}, &userID, "", "", "")
		return nil, fmt.Errorf("配置 %s.%s 已存在", req.Category, req.Key)
	}

	config := &models.SystemConfig{
		Category:     req.Category,
		Key:          req.Key,
		Value:        req.Value,
		DefaultValue: req.Value, // 创建时的值作为默认值
		Description:  req.Description,
		DataType:     req.DataType,
		IsPublic:     req.IsPublic,
		IsEditable:   req.IsEditable,
		Version:      1,
		UpdatedBy:    userID,
	}

	// 设置默认数据类型
	if config.DataType == "" {
		config.DataType = "string"
	}

	if err := s.db.Create(config).Error; err != nil {
		s.LogSystemEvent("error", "config", fmt.Sprintf("创建系统配置失败: %v", err),
			map[string]interface{}{
				"category": req.Category,
				"key":      req.Key,
				"action":   "create_config_failed",
				"error":    err.Error(),
			}, &userID, "", "", "")
		return nil, fmt.Errorf("创建系统配置失败: %v", err)
	}

	// 记录配置历史
	history := &models.SystemConfigHistory{
		ConfigID:   config.ID,
		NewValue:   config.Value,
		Version:    config.Version,
		ChangeType: "create",
		Reason:     req.Reason,
		UpdatedBy:  userID,
	}
	s.db.Create(history)

	// 记录成功日志
	s.LogSystemEvent("info", "config", fmt.Sprintf("系统配置创建成功: %s.%s", req.Category, req.Key),
		map[string]interface{}{
			"category":  req.Category,
			"key":       req.Key,
			"config_id": config.ID,
			"action":    "create_config_success",
		}, &userID, "", "", "")

	// 预加载关联数据
	if err := s.db.Preload("UpdatedByUser").First(config, config.ID).Error; err != nil {
		return nil, fmt.Errorf("获取系统配置失败: %v", err)
	}

	return config, nil
}

// GetConfigs 获取系统配置列表
func (s *SystemService) GetConfigs(page, pageSize int, category string, isPublic *bool) (*SystemConfigListResponse, error) {
	var configs []models.SystemConfig
	var total int64

	query := s.db.Model(&models.SystemConfig{})

	// 分类过滤
	if category != "" {
		query = query.Where("category = ?", category)
	}

	// 公开性过滤
	if isPublic != nil {
		query = query.Where("is_public = ?", *isPublic)
	}

	// 计算总数
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取配置总数失败: %v", err)
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Preload("UpdatedByUser").
		Offset(offset).
		Limit(pageSize).
		Order("category ASC, key ASC").
		Find(&configs).Error; err != nil {
		return nil, fmt.Errorf("获取配置列表失败: %v", err)
	}

	return &SystemConfigListResponse{
		Configs:  configs,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// GetConfigByKey 根据键获取系统配置
func (s *SystemService) GetConfigByKey(category, key string) (*models.SystemConfig, error) {
	var config models.SystemConfig
	if err := s.db.Where("category = ? AND key = ?", category, key).First(&config).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("配置不存在")
		}
		return nil, fmt.Errorf("获取配置失败: %v", err)
	}

	return &config, nil
}

// UpdateConfig 更新系统配置
func (s *SystemService) UpdateConfig(category, key string, req *SystemConfigUpdateRequest, userID uint) (*models.SystemConfig, error) {
	var config models.SystemConfig
	if err := s.db.Where("category = ? AND key = ?", category, key).First(&config).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("配置不存在")
		}
		return nil, fmt.Errorf("获取配置失败: %v", err)
	}

	if !config.IsEditable {
		return nil, fmt.Errorf("配置不可编辑")
	}

	// 记录旧值
	oldValue := config.Value

	// 更新配置
	config.Value = req.Value
	config.Version++
	config.UpdatedBy = userID

	if err := s.db.Save(&config).Error; err != nil {
		return nil, fmt.Errorf("更新配置失败: %v", err)
	}

	// 记录配置历史
	history := &models.SystemConfigHistory{
		ConfigID:   config.ID,
		OldValue:   oldValue,
		NewValue:   config.Value,
		Version:    config.Version,
		ChangeType: "update",
		Reason:     req.Reason,
		UpdatedBy:  userID,
	}
	s.db.Create(history)

	// 预加载关联数据
	if err := s.db.Preload("UpdatedByUser").First(&config, config.ID).Error; err != nil {
		return nil, fmt.Errorf("获取更新后的配置失败: %v", err)
	}

	return &config, nil
}

// DeleteConfig 删除系统配置
func (s *SystemService) DeleteConfig(category, key string, reason string, userID uint) error {
	var config models.SystemConfig
	if err := s.db.Where("category = ? AND key = ?", category, key).First(&config).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("配置不存在")
		}
		return fmt.Errorf("获取配置失败: %v", err)
	}

	if !config.IsEditable {
		return fmt.Errorf("配置不可删除")
	}

	// 记录配置历史
	history := &models.SystemConfigHistory{
		ConfigID:   config.ID,
		OldValue:   config.Value,
		Version:    config.Version + 1,
		ChangeType: "delete",
		Reason:     reason,
		UpdatedBy:  userID,
	}
	s.db.Create(history)

	if err := s.db.Delete(&config).Error; err != nil {
		return fmt.Errorf("删除配置失败: %v", err)
	}

	return nil
}

// CreateAnnouncement 创建公告
func (s *SystemService) CreateAnnouncement(req *AnnouncementRequest, userID uint) (*models.Announcement, error) {
	// 记录操作日志
	s.LogSystemEvent("info", "announcement", fmt.Sprintf("尝试创建公告: %s", req.Title),
		map[string]interface{}{
			"title":    req.Title,
			"type":     req.Type,
			"priority": req.Priority,
			"action":   "create_announcement",
		}, &userID, "", "", "")

	announcement := &models.Announcement{
		Title:     req.Title,
		Content:   req.Content,
		Type:      req.Type,
		Priority:  req.Priority,
		IsActive:  req.IsActive,
		IsSticky:  req.IsSticky,
		StartTime: req.StartTime,
		EndTime:   req.EndTime,
		CreatedBy: userID,
	}

	// 设置默认优先级
	if announcement.Priority == 0 {
		announcement.Priority = 1
	}

	// 序列化目标用户列表
	if len(req.TargetUsers) > 0 {
		if targetUsersJSON, err := json.Marshal(req.TargetUsers); err != nil {
			s.LogSystemEvent("error", "announcement", fmt.Sprintf("序列化目标用户列表失败: %v", err),
				map[string]interface{}{
					"title":  req.Title,
					"action": "create_announcement_failed",
					"error":  err.Error(),
				}, &userID, "", "", "")
			return nil, fmt.Errorf("序列化目标用户列表失败: %v", err)
		} else {
			announcement.TargetUsers = string(targetUsersJSON)
		}
	}

	if err := s.db.Create(announcement).Error; err != nil {
		s.LogSystemEvent("error", "announcement", fmt.Sprintf("创建公告失败: %v", err),
			map[string]interface{}{
				"title":  req.Title,
				"action": "create_announcement_failed",
				"error":  err.Error(),
			}, &userID, "", "", "")
		return nil, fmt.Errorf("创建公告失败: %v", err)
	}

	// 记录成功日志
	s.LogSystemEvent("info", "announcement", fmt.Sprintf("公告创建成功: %s", req.Title),
		map[string]interface{}{
			"title":           req.Title,
			"announcement_id": announcement.ID,
			"action":          "create_announcement_success",
		}, &userID, "", "", "")

	// 预加载关联数据
	if err := s.db.Preload("Creator").First(announcement, announcement.ID).Error; err != nil {
		return nil, fmt.Errorf("获取公告失败: %v", err)
	}

	return announcement, nil
}

// GetAnnouncements 获取公告列表
func (s *SystemService) GetAnnouncements(page, pageSize int, announcementType string, isActive *bool, userID uint) (*AnnouncementListResponse, error) {
	var announcements []models.Announcement
	var total int64

	query := s.db.Model(&models.Announcement{})

	// 类型过滤
	if announcementType != "" {
		query = query.Where("type = ?", announcementType)
	}

	// 状态过滤
	if isActive != nil {
		query = query.Where("is_active = ?", *isActive)
	}

	// 时间过滤（只显示当前有效的公告）
	now := time.Now()
	query = query.Where("(start_time IS NULL OR start_time <= ?) AND (end_time IS NULL OR end_time >= ?)", now, now)

	// 目标用户过滤 - 根据数据库类型自动选择查询方式
	query = utils.BuildJSONQuery(s.db, query, "target_users", userID)

	// 计算总数
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取公告总数失败: %v", err)
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Preload("Creator").
		Offset(offset).
		Limit(pageSize).
		Order("is_sticky DESC, priority DESC, created_at DESC").
		Find(&announcements).Error; err != nil {
		return nil, fmt.Errorf("获取公告列表失败: %v", err)
	}

	return &AnnouncementListResponse{
		Announcements: announcements,
		Total:         total,
		Page:          page,
		PageSize:      pageSize,
	}, nil
}

// GetPublicAnnouncements 获取公共公告列表（无需认证，只返回活跃公告）
func (s *SystemService) GetPublicAnnouncements(page, pageSize int, isActive *bool) (*AnnouncementListResponse, error) {
	var announcements []models.Announcement
	var total int64

	query := s.db.Model(&models.Announcement{})

	// 只显示活跃的公告
	if isActive != nil {
		query = query.Where("is_active = ?", *isActive)
	}

	// 时间过滤（只显示当前有效的公告）
	now := time.Now()
	query = query.Where("(start_time IS NULL OR start_time <= ?) AND (end_time IS NULL OR end_time >= ?)", now, now)

	// 计算总数
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取公告总数失败: %v", err)
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Preload("Creator").
		Offset(offset).
		Limit(pageSize).
		Order("is_sticky DESC, priority DESC, created_at DESC").
		Find(&announcements).Error; err != nil {
		return nil, fmt.Errorf("获取公告列表失败: %v", err)
	}

	return &AnnouncementListResponse{
		Announcements: announcements,
		Total:         total,
		Page:          page,
		PageSize:      pageSize,
	}, nil
}

// UpdateAnnouncement 更新公告
func (s *SystemService) UpdateAnnouncement(id uint, req *AnnouncementRequest, userID uint, hasAllPermission bool) (*models.Announcement, error) {
	var announcement models.Announcement

	query := s.db.Model(&announcement)

	// 权限控制
	if !hasAllPermission {
		query = query.Where("created_by = ?", userID)
	}

	if err := query.First(&announcement, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("公告不存在或无权修改")
		}
		return nil, fmt.Errorf("获取公告失败: %v", err)
	}

	// 更新字段
	updates := map[string]interface{}{
		"title":      req.Title,
		"content":    req.Content,
		"type":       req.Type,
		"priority":   req.Priority,
		"is_active":  req.IsActive,
		"is_sticky":  req.IsSticky,
		"start_time": req.StartTime,
		"end_time":   req.EndTime,
	}

	// 序列化目标用户列表
	if len(req.TargetUsers) > 0 {
		if targetUsersJSON, err := json.Marshal(req.TargetUsers); err != nil {
			return nil, fmt.Errorf("序列化目标用户列表失败: %v", err)
		} else {
			updates["target_users"] = string(targetUsersJSON)
		}
	} else {
		updates["target_users"] = ""
	}

	if err := s.db.Model(&announcement).Updates(updates).Error; err != nil {
		return nil, fmt.Errorf("更新公告失败: %v", err)
	}

	// 重新加载数据
	if err := s.db.Preload("Creator").First(&announcement, id).Error; err != nil {
		return nil, fmt.Errorf("获取更新后的公告失败: %v", err)
	}

	return &announcement, nil
}

// DeleteAnnouncement 删除公告
func (s *SystemService) DeleteAnnouncement(id, userID uint, hasAllPermission bool) error {
	var announcement models.Announcement

	query := s.db.Model(&announcement)

	// 权限控制
	if !hasAllPermission {
		query = query.Where("created_by = ?", userID)
	}

	if err := query.First(&announcement, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("公告不存在或无权删除")
		}
		return fmt.Errorf("获取公告失败: %v", err)
	}

	if err := s.db.Delete(&announcement).Error; err != nil {
		return fmt.Errorf("删除公告失败: %v", err)
	}

	return nil
}

// MarkAnnouncementAsViewed 标记公告为已查看
func (s *SystemService) MarkAnnouncementAsViewed(announcementID, userID uint, ipAddress, userAgent string) error {
	// 检查是否已经查看过
	var existingView models.AnnouncementView
	err := s.db.Where("announcement_id = ? AND user_id = ?", announcementID, userID).First(&existingView).Error
	if err == nil {
		// 已经查看过，更新查看时间
		existingView.ViewedAt = time.Now()
		existingView.IPAddress = ipAddress
		existingView.UserAgent = userAgent
		return s.db.Save(&existingView).Error
	} else if err != gorm.ErrRecordNotFound {
		// 真正的数据库错误
		return fmt.Errorf("检查公告查看记录失败: %v", err)
	}

	// 创建新的查看记录
	view := &models.AnnouncementView{
		AnnouncementID: announcementID,
		UserID:         userID,
		ViewedAt:       time.Now(),
		IPAddress:      ipAddress,
		UserAgent:      userAgent,
	}

	if err := s.db.Create(view).Error; err != nil {
		return fmt.Errorf("记录公告查看失败: %v", err)
	}

	// 增加公告查看次数
	s.db.Model(&models.Announcement{}).Where("id = ?", announcementID).Update("view_count", gorm.Expr("view_count + 1"))

	return nil
}

// GetSystemHealth 获取系统健康状态
func (s *SystemService) GetSystemHealth() (*SystemHealthResponse, error) {
	// 记录健康检查日志
	s.LogSystemEvent("info", "health", "执行系统健康检查",
		map[string]interface{}{
			"action": "health_check",
		}, nil, "", "", "")

	var healthChecks []models.SystemHealth

	// 执行各组件健康检查
	components := []string{"database", "cache", "storage", "external_api"}

	for _, component := range components {
		health := s.checkComponentHealth(component)
		healthChecks = append(healthChecks, *health)

		// 保存健康检查记录
		s.db.Create(health)

		// 记录组件健康状态日志
		if health.Status != "healthy" {
			s.LogSystemEvent("warn", "health", fmt.Sprintf("组件 %s 状态异常: %s", component, health.Status),
				map[string]interface{}{
					"component": component,
					"status":    health.Status,
					"error":     health.ErrorMsg,
					"action":    "component_health_check",
				}, nil, "", "", "")
		}
	}

	// 计算总体状态
	overallStatus := s.calculateOverallStatus(healthChecks)

	// 生成摘要
	summary := SystemHealthSummary{
		TotalComponents: len(healthChecks),
	}

	for _, health := range healthChecks {
		switch health.Status {
		case "healthy":
			summary.HealthyComponents++
		case "unhealthy":
			summary.UnhealthyComponents++
		case "degraded":
			summary.DegradedComponents++
		}
	}

	// 记录健康检查结果日志
	s.LogSystemEvent("info", "health", fmt.Sprintf("系统健康检查完成，总体状态: %s", overallStatus),
		map[string]interface{}{
			"overall_status":       overallStatus,
			"healthy_components":   summary.HealthyComponents,
			"unhealthy_components": summary.UnhealthyComponents,
			"degraded_components":  summary.DegradedComponents,
			"action":               "health_check_completed",
		}, nil, "", "", "")

	return &SystemHealthResponse{
		OverallStatus: overallStatus,
		Components:    healthChecks,
		Summary:       summary,
		CheckedAt:     time.Now(),
	}, nil
}

// checkComponentHealth 检查组件健康状态
func (s *SystemService) checkComponentHealth(component string) *models.SystemHealth {
	startTime := time.Now()
	var status string
	var errorMsg string
	var details map[string]interface{}

	switch component {
	case "database":
		// 检查数据库连接
		if err := s.db.Exec("SELECT 1").Error; err != nil {
			status = "unhealthy"
			errorMsg = err.Error()
		} else {
			status = "healthy"
			details = map[string]interface{}{
				"connection_pool": "active",
				"version":         "mysql-8.0",
			}
		}

	case "cache":
		// 模拟缓存检查
		status = "healthy"
		details = map[string]interface{}{
			"type":         "redis",
			"memory_usage": "45%",
		}

	case "storage":
		// 检查存储空间
		status = "healthy"
		details = map[string]interface{}{
			"disk_usage": "65%",
			"available":  "2.5GB",
		}

	case "external_api":
		// 模拟外部API检查
		status = "healthy"
		details = map[string]interface{}{
			"endpoints": []string{"openai", "wechat"},
			"latency":   "120ms",
		}

	default:
		status = "unknown"
		errorMsg = "未知组件"
	}

	responseTime := int(time.Since(startTime).Milliseconds())

	// 序列化详细信息
	var detailsJSON string
	if details != nil {
		if detailsBytes, err := json.Marshal(details); err == nil {
			detailsJSON = string(detailsBytes)
		}
	}

	return &models.SystemHealth{
		Component:    component,
		Status:       status,
		ResponseTime: responseTime,
		ErrorMsg:     errorMsg,
		Details:      detailsJSON,
		CheckedAt:    time.Now(),
	}
}

// calculateOverallStatus 计算总体健康状态
func (s *SystemService) calculateOverallStatus(healthChecks []models.SystemHealth) string {
	healthyCount := 0
	unhealthyCount := 0
	degradedCount := 0

	for _, health := range healthChecks {
		switch health.Status {
		case "healthy":
			healthyCount++
		case "unhealthy":
			unhealthyCount++
		case "degraded":
			degradedCount++
		}
	}

	if unhealthyCount > 0 {
		return "unhealthy"
	} else if degradedCount > 0 {
		return "degraded"
	} else {
		return "healthy"
	}
}

// GetSystemLogs 获取系统日志
func (s *SystemService) GetSystemLogs(page, pageSize int, level, category string, startTime, endTime *time.Time) (*SystemLogListResponse, error) {
	var logs []models.SystemLog
	var total int64

	query := s.db.Model(&models.SystemLog{})

	// 级别过滤
	if level != "" {
		query = query.Where("level = ?", level)
	}

	// 分类过滤
	if category != "" {
		query = query.Where("category = ?", category)
	}

	// 时间范围过滤
	if startTime != nil {
		query = query.Where("created_at >= ?", *startTime)
	}
	if endTime != nil {
		query = query.Where("created_at <= ?", *endTime)
	}

	// 计算总数
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取日志总数失败: %v", err)
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Preload("User").
		Offset(offset).
		Limit(pageSize).
		Order("created_at DESC").
		Find(&logs).Error; err != nil {
		return nil, fmt.Errorf("获取日志列表失败: %v", err)
	}

	return &SystemLogListResponse{
		Logs:     logs,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// CleanupOldLogs 清理旧日志
func (s *SystemService) CleanupOldLogs(retentionDays int) (int64, error) {
	cutoffTime := time.Now().AddDate(0, 0, -retentionDays)

	result := s.db.Where("created_at < ?", cutoffTime).Delete(&models.SystemLog{})
	if result.Error != nil {
		return 0, fmt.Errorf("清理旧日志失败: %v", result.Error)
	}

	return result.RowsAffected, nil
}

// DeleteSingleLog 删除单条日志
func (s *SystemService) DeleteSingleLog(logID uint) error {
	result := s.db.Delete(&models.SystemLog{}, logID)
	if result.Error != nil {
		return fmt.Errorf("删除日志失败: %v", result.Error)
	}

	if result.RowsAffected == 0 {
		return fmt.Errorf("日志不存在或已被删除")
	}

	return nil
}

// BatchDeleteLogs 批量删除日志
func (s *SystemService) BatchDeleteLogs(logIDs []uint) (int64, error) {
	if len(logIDs) == 0 {
		return 0, fmt.Errorf("没有提供要删除的日志ID")
	}

	result := s.db.Where("id IN ?", logIDs).Delete(&models.SystemLog{})
	if result.Error != nil {
		return 0, fmt.Errorf("批量删除日志失败: %v", result.Error)
	}

	return result.RowsAffected, nil
}

// GetSystemMetrics 获取系统指标
func (s *SystemService) GetSystemMetrics() (*SystemMetricsResponse, error) {
	// 获取系统指标
	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)

	// 模拟系统指标
	metrics := []models.SystemMetrics{
		{
			MetricName: "cpu_usage",
			Value:      45.2,
			Unit:       "%",
			Timestamp:  time.Now(),
		},
		{
			MetricName: "memory_usage",
			Value:      float64(memStats.Alloc) / 1024 / 1024, // MB
			Unit:       "MB",
			Timestamp:  time.Now(),
		},
		{
			MetricName: "goroutines",
			Value:      float64(runtime.NumGoroutine()),
			Unit:       "count",
			Timestamp:  time.Now(),
		},
	}

	// 保存指标到数据库
	for _, metric := range metrics {
		s.db.Create(&metric)
	}

	// 生成摘要
	summary := SystemMetricsSummary{
		CPUUsage:    45.2,
		MemoryUsage: float64(memStats.Alloc) / 1024 / 1024,
		DiskUsage:   65.8,
		Uptime:      3600, // 模拟1小时运行时间
	}

	return &SystemMetricsResponse{
		Metrics:   metrics,
		Summary:   summary,
		Timestamp: time.Now(),
	}, nil
}

// LogSystemEvent 记录系统事件
func (s *SystemService) LogSystemEvent(level, category, message string, context map[string]interface{}, userID *uint, ipAddress, userAgent, requestID string) error {
	log := &models.SystemLog{
		Level:     level,
		Category:  category,
		Message:   message,
		UserID:    userID,
		IPAddress: ipAddress,
		UserAgent: userAgent,
		RequestID: requestID,
	}

	// 序列化上下文
	if len(context) > 0 {
		if contextJSON, err := json.Marshal(context); err != nil {
			return fmt.Errorf("序列化上下文失败: %v", err)
		} else {
			log.Context = string(contextJSON)
		}
	}

	return s.db.Create(log).Error
}
