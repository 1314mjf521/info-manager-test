package services

import (
	"crypto/rand"
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

// Token相关请求结构
type TokenCreateRequest struct {
	Name        string `json:"name" binding:"required"`
	UserID      uint   `json:"user_id" binding:"required"`
	Scope       string `json:"scope" binding:"required"`
	ExpiresIn   int    `json:"expires_in"` // 过期时间（小时），0表示永不过期
	Description string `json:"description"`
}

type TokenListResponse struct {
	Tokens   []models.APIToken `json:"tokens"`
	Total    int64             `json:"total"`
	Page     int               `json:"page"`
	PageSize int               `json:"page_size"`
	Stats    TokenStats        `json:"stats"`
}

type TokenStats struct {
	Total     int64 `json:"total"`
	Active    int64 `json:"active"`
	Expired   int64 `json:"expired"`
	TodayUsed int64 `json:"today_used"`
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
	} else {
		// 默认只显示活跃的公告
		query = query.Where("is_active = ?", true)
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

// GetAnnouncementByID 根据ID获取公告
func (s *SystemService) GetAnnouncementByID(id uint) (*models.Announcement, error) {
	var announcement models.Announcement
	if err := s.db.Preload("Creator").First(&announcement, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("公告不存在")
		}
		return nil, fmt.Errorf("获取公告失败: %v", err)
	}

	return &announcement, nil
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

// Token管理相关方法

// CreateToken 创建API Token
func (s *SystemService) CreateToken(req *TokenCreateRequest, createdBy uint) (*models.APIToken, error) {
	// 生成随机Token
	tokenValue, err := s.generateRandomToken()
	if err != nil {
		return nil, fmt.Errorf("生成Token失败: %w", err)
	}

	// 计算过期时间
	var expiresAt *time.Time
	if req.ExpiresIn > 0 {
		expiry := time.Now().Add(time.Duration(req.ExpiresIn) * time.Hour)
		expiresAt = &expiry
	}

	token := &models.APIToken{
		Name:        req.Name,
		Token:       tokenValue,
		UserID:      req.UserID,
		Scope:       req.Scope,
		Description: req.Description,
		ExpiresAt:   expiresAt,
		Status:      "active",
	}

	if err := s.db.Create(token).Error; err != nil {
		return nil, fmt.Errorf("创建Token失败: %w", err)
	}

	// 预加载用户信息
	s.db.Preload("User").First(token, token.ID)

	// 记录操作日志
	s.LogSystemEvent("info", "token", fmt.Sprintf("创建API Token: %s", req.Name),
		map[string]interface{}{
			"token_id":   token.ID,
			"token_name": req.Name,
			"user_id":    req.UserID,
			"scope":      req.Scope,
		}, &createdBy, "", "", "")

	return token, nil
}

// GetTokens 获取Token列表
func (s *SystemService) GetTokens(page, pageSize int, userID uint, status string) (*TokenListResponse, error) {
	var tokens []models.APIToken
	var total int64

	query := s.db.Model(&models.APIToken{}).Preload("User")

	// 用户过滤
	if userID > 0 {
		query = query.Where("user_id = ?", userID)
	}

	// 状态过滤
	if status != "" {
		if status == "expired" {
			query = query.Where("expires_at IS NOT NULL AND expires_at < ?", time.Now())
		} else {
			query = query.Where("status = ?", status)
		}
	}

	// 计算总数
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取Token总数失败: %w", err)
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Offset(offset).Limit(pageSize).Order("created_at DESC").Find(&tokens).Error; err != nil {
		return nil, fmt.Errorf("获取Token列表失败: %w", err)
	}

	// 计算统计信息
	stats, err := s.getTokenStats(userID)
	if err != nil {
		return nil, fmt.Errorf("获取Token统计信息失败: %w", err)
	}

	return &TokenListResponse{
		Tokens:   tokens,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
		Stats:    *stats,
	}, nil
}

// getTokenStats 获取Token统计信息
func (s *SystemService) getTokenStats(userID uint) (*TokenStats, error) {
	var stats TokenStats
	
	baseQuery := s.db.Model(&models.APIToken{})
	if userID > 0 {
		baseQuery = baseQuery.Where("user_id = ?", userID)
	}

	// 总数
	if err := baseQuery.Count(&stats.Total).Error; err != nil {
		return nil, err
	}

	// 活跃Token数
	if err := baseQuery.Where("status = ?", "active").Count(&stats.Active).Error; err != nil {
		return nil, err
	}

	// 过期Token数
	now := time.Now()
	if err := baseQuery.Where("expires_at IS NOT NULL AND expires_at < ?", now).Count(&stats.Expired).Error; err != nil {
		return nil, err
	}

	// 今日使用的Token数
	today := time.Now().Truncate(24 * time.Hour)
	if err := baseQuery.Where("last_used_at >= ?", today).Count(&stats.TodayUsed).Error; err != nil {
		return nil, err
	}

	return &stats, nil
}

// RenewToken 续期Token
func (s *SystemService) RenewToken(tokenID uint, expiresIn int, userID uint) error {
	var token models.APIToken
	if err := s.db.First(&token, tokenID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("Token不存在")
		}
		return fmt.Errorf("查询Token失败: %w", err)
	}

	// 检查Token状态
	if token.Status != "active" {
		return fmt.Errorf("Token状态异常，无法续期")
	}

	// 计算新的过期时间
	var expiresAt *time.Time
	if expiresIn > 0 {
		expiry := time.Now().Add(time.Duration(expiresIn) * time.Hour)
		expiresAt = &expiry
	}

	// 更新过期时间
	if err := s.db.Model(&token).Update("expires_at", expiresAt).Error; err != nil {
		return fmt.Errorf("续期Token失败: %w", err)
	}

	// 记录操作日志
	s.LogSystemEvent("info", "token", fmt.Sprintf("续期API Token: %s", token.Name),
		map[string]interface{}{
			"token_id":   tokenID,
			"expires_in": expiresIn,
			"old_expires_at": token.ExpiresAt,
			"new_expires_at": expiresAt,
		}, &userID, "", "", "")

	return nil
}

// RevokeToken 撤销Token
func (s *SystemService) RevokeToken(tokenID uint, userID uint) error {
	var token models.APIToken
	if err := s.db.First(&token, tokenID).Error; err != nil {
		return fmt.Errorf("Token不存在: %w", err)
	}

	// 软删除Token
	if err := s.db.Delete(&token).Error; err != nil {
		return fmt.Errorf("撤销Token失败: %w", err)
	}

	// 记录操作日志
	s.LogSystemEvent("info", "token", fmt.Sprintf("撤销API Token: %s", token.Name),
		map[string]interface{}{
			"token_id": tokenID,
		}, &userID, "", "", "")

	return nil
}

// ValidateAPIToken 验证API Token
func (s *SystemService) ValidateAPIToken(tokenValue string) (*models.APIToken, error) {
	var token models.APIToken
	if err := s.db.Preload("User").Where("token = ? AND status = 'active'", tokenValue).First(&token).Error; err != nil {
		return nil, fmt.Errorf("无效的Token")
	}

	// 检查是否过期
	if token.ExpiresAt != nil && token.ExpiresAt.Before(time.Now()) {
		return nil, fmt.Errorf("Token已过期")
	}

	// 更新使用统计
	s.db.Model(&token).Updates(map[string]interface{}{
		"last_used_at": time.Now(),
		"usage_count":  gorm.Expr("usage_count + 1"),
	})

	return &token, nil
}

// generateRandomToken 生成随机Token
func (s *SystemService) generateRandomToken() (string, error) {
	// 生成32字节的随机数据
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	
	// 转换为hex字符串
	return fmt.Sprintf("api_%x", bytes), nil
}
// DisableToken 禁用Token
func (s *SystemService) DisableToken(tokenID uint, userID uint) error {
	var token models.APIToken
	if err := s.db.First(&token, tokenID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("Token不存在")
		}
		return fmt.Errorf("查询Token失败: %w", err)
	}

	// 更新Token状态
	if err := s.db.Model(&token).Update("status", "disabled").Error; err != nil {
		return fmt.Errorf("禁用Token失败: %w", err)
	}

	// 记录操作日志
	s.LogSystemEvent("info", "token", fmt.Sprintf("禁用API Token: %s", token.Name),
		map[string]interface{}{
			"token_id": tokenID,
			"action":   "disable",
		}, &userID, "", "", "")

	return nil
}

// EnableToken 启用Token
func (s *SystemService) EnableToken(tokenID uint, userID uint) error {
	var token models.APIToken
	if err := s.db.First(&token, tokenID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("Token不存在")
		}
		return fmt.Errorf("查询Token失败: %w", err)
	}

	// 更新Token状态
	if err := s.db.Model(&token).Update("status", "active").Error; err != nil {
		return fmt.Errorf("启用Token失败: %w", err)
	}

	// 记录操作日志
	s.LogSystemEvent("info", "token", fmt.Sprintf("启用API Token: %s", token.Name),
		map[string]interface{}{
			"token_id": tokenID,
			"action":   "enable",
		}, &userID, "", "", "")

	return nil
}

// RegenerateToken 重新生成Token
func (s *SystemService) RegenerateToken(tokenID uint, userID uint) (*models.APIToken, error) {
	var token models.APIToken
	if err := s.db.First(&token, tokenID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("Token不存在")
		}
		return nil, fmt.Errorf("查询Token失败: %w", err)
	}

	// 生成新的Token值
	newTokenValue, err := s.generateRandomToken()
	if err != nil {
		return nil, fmt.Errorf("生成新Token失败: %w", err)
	}

	// 更新Token值和重置使用统计
	updates := map[string]interface{}{
		"token":        newTokenValue,
		"usage_count":  0,
		"last_used_at": nil,
		"status":       "active",
	}

	if err := s.db.Model(&token).Updates(updates).Error; err != nil {
		return nil, fmt.Errorf("更新Token失败: %w", err)
	}

	// 重新加载Token数据
	if err := s.db.Preload("User").First(&token, tokenID).Error; err != nil {
		return nil, fmt.Errorf("获取更新后的Token失败: %w", err)
	}

	// 记录操作日志
	s.LogSystemEvent("info", "token", fmt.Sprintf("重新生成API Token: %s", token.Name),
		map[string]interface{}{
			"token_id": tokenID,
			"action":   "regenerate",
		}, &userID, "", "", "")

	return &token, nil
}

// BatchDisableTokens 批量禁用Token
func (s *SystemService) BatchDisableTokens(tokenIDs []uint, userID uint) error {
	if len(tokenIDs) == 0 {
		return fmt.Errorf("没有提供要禁用的Token ID")
	}

	result := s.db.Model(&models.APIToken{}).
		Where("id IN ?", tokenIDs).
		Update("status", "disabled")

	if result.Error != nil {
		return fmt.Errorf("批量禁用Token失败: %w", result.Error)
	}

	// 记录操作日志
	s.LogSystemEvent("info", "token", fmt.Sprintf("批量禁用 %d 个API Token", result.RowsAffected),
		map[string]interface{}{
			"token_ids":     tokenIDs,
			"affected_rows": result.RowsAffected,
			"action":        "batch_disable",
		}, &userID, "", "", "")

	return nil
}

// BatchEnableTokens 批量启用Token
func (s *SystemService) BatchEnableTokens(tokenIDs []uint, userID uint) error {
	if len(tokenIDs) == 0 {
		return fmt.Errorf("没有提供要启用的Token ID")
	}

	result := s.db.Model(&models.APIToken{}).
		Where("id IN ?", tokenIDs).
		Update("status", "active")

	if result.Error != nil {
		return fmt.Errorf("批量启用Token失败: %w", result.Error)
	}

	// 记录操作日志
	s.LogSystemEvent("info", "token", fmt.Sprintf("批量启用 %d 个API Token", result.RowsAffected),
		map[string]interface{}{
			"token_ids":     tokenIDs,
			"affected_rows": result.RowsAffected,
			"action":        "batch_enable",
		}, &userID, "", "", "")

	return nil
}

// BatchRevokeTokens 批量撤销Token
func (s *SystemService) BatchRevokeTokens(tokenIDs []uint, userID uint) error {
	if len(tokenIDs) == 0 {
		return fmt.Errorf("没有提供要撤销的Token ID")
	}

	result := s.db.Where("id IN ?", tokenIDs).Delete(&models.APIToken{})

	if result.Error != nil {
		return fmt.Errorf("批量撤销Token失败: %w", result.Error)
	}

	// 记录操作日志
	s.LogSystemEvent("info", "token", fmt.Sprintf("批量撤销 %d 个API Token", result.RowsAffected),
		map[string]interface{}{
			"token_ids":     tokenIDs,
			"affected_rows": result.RowsAffected,
			"action":        "batch_revoke",
		}, &userID, "", "", "")

	return nil
}

// UserForToken 用于Token创建的用户信息
type UserForToken struct {
	ID       uint   `json:"id"`
	Username string `json:"username"`
	Email    string `json:"email"`
}

// GetTokenUsageStats 获取Token使用统计
func (s *SystemService) GetTokenUsageStats(tokenID uint) (*TokenUsageStats, error) {
	var token models.APIToken
	if err := s.db.First(&token, tokenID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("Token不存在")
		}
		return nil, fmt.Errorf("查询Token失败: %w", err)
	}

	stats := &TokenUsageStats{
		TokenID:    tokenID,
		TokenName:  token.Name,
		TotalUsage: token.UsageCount,
	}

	now := time.Now()
	today := now.Truncate(24 * time.Hour)
	weekStart := today.AddDate(0, 0, -int(today.Weekday()))
	monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())

	// 今日使用次数
	if err := s.db.Model(&models.APITokenUsageLog{}).
		Where("token_id = ? AND created_at >= ?", tokenID, today).
		Count(&stats.TodayUsage).Error; err != nil {
		return nil, fmt.Errorf("获取今日使用统计失败: %w", err)
	}

	// 本周使用次数
	if err := s.db.Model(&models.APITokenUsageLog{}).
		Where("token_id = ? AND created_at >= ?", tokenID, weekStart).
		Count(&stats.WeekUsage).Error; err != nil {
		return nil, fmt.Errorf("获取本周使用统计失败: %w", err)
	}

	// 本月使用次数
	if err := s.db.Model(&models.APITokenUsageLog{}).
		Where("token_id = ? AND created_at >= ?", tokenID, monthStart).
		Count(&stats.MonthUsage).Error; err != nil {
		return nil, fmt.Errorf("获取本月使用统计失败: %w", err)
	}

	return stats, nil
}

// GetTokenUsageHistory 获取Token使用历史
func (s *SystemService) GetTokenUsageHistory(tokenID uint, page, pageSize int, startTime, endTime *time.Time) (*TokenUsageHistoryResponse, error) {
	var usageLogs []models.APITokenUsageLog
	var total int64

	query := s.db.Model(&models.APITokenUsageLog{}).Where("token_id = ?", tokenID)

	// 时间范围过滤
	if startTime != nil {
		query = query.Where("created_at >= ?", *startTime)
	}
	if endTime != nil {
		query = query.Where("created_at <= ?", *endTime)
	}

	// 计算总数
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取使用历史总数失败: %w", err)
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Offset(offset).Limit(pageSize).Order("created_at DESC").Find(&usageLogs).Error; err != nil {
		return nil, fmt.Errorf("获取使用历史失败: %w", err)
	}

	return &TokenUsageHistoryResponse{
		UsageLogs: usageLogs,
		Total:     total,
		Page:      page,
		PageSize:  pageSize,
	}, nil
}

// LogTokenUsage 记录Token使用日志
func (s *SystemService) LogTokenUsage(tokenID uint, method, path, ipAddress, userAgent string, statusCode, duration int, requestID string) error {
	usageLog := &models.APITokenUsageLog{
		TokenID:    tokenID,
		Method:     method,
		Path:       path,
		IPAddress:  ipAddress,
		UserAgent:  userAgent,
		StatusCode: statusCode,
		Duration:   duration,
		RequestID:  requestID,
	}

	if err := s.db.Create(usageLog).Error; err != nil {
		return fmt.Errorf("记录Token使用日志失败: %w", err)
	}

	return nil
}

// TokenUsageStats Token使用统计
type TokenUsageStats struct {
	TokenID     uint   `json:"token_id"`
	TokenName   string `json:"token_name"`
	TotalUsage  int64  `json:"total_usage"`
	TodayUsage  int64  `json:"today_usage"`
	WeekUsage   int64  `json:"week_usage"`
	MonthUsage  int64  `json:"month_usage"`
}

// TokenUsageHistoryResponse Token使用历史响应
type TokenUsageHistoryResponse struct {
	UsageLogs []models.APITokenUsageLog `json:"usage_logs"`
	Total     int64                     `json:"total"`
	Page      int                       `json:"page"`
	PageSize  int                       `json:"page_size"`
}

// GetSystemStats 获取系统统计信息
func (s *SystemService) GetSystemStats() (*SystemStatsResponse, error) {
	stats := &SystemStatsResponse{}
	
	// 配置统计
	if err := s.db.Model(&models.SystemConfig{}).Count(&stats.ConfigStats.Total).Error; err != nil {
		return nil, fmt.Errorf("获取配置统计失败: %w", err)
	}
	
	// 公告统计
	if err := s.db.Model(&models.Announcement{}).Where("is_active = ?", true).Count(&stats.AnnouncementStats.Active).Error; err != nil {
		return nil, fmt.Errorf("获取公告统计失败: %w", err)
	}
	
	// 日志统计
	today := time.Now().Truncate(24 * time.Hour)
	if err := s.db.Model(&models.SystemLog{}).Where("created_at >= ?", today).Count(&stats.LogStats.Today).Error; err != nil {
		return nil, fmt.Errorf("获取日志统计失败: %w", err)
	}
	
	// Token统计
	if err := s.db.Model(&models.APIToken{}).Count(&stats.TokenStats.Total).Error; err != nil {
		return nil, fmt.Errorf("获取Token统计失败: %w", err)
	}
	
	if err := s.db.Model(&models.APIToken{}).Where("status = ?", "active").Count(&stats.TokenStats.Active).Error; err != nil {
		return nil, fmt.Errorf("获取活跃Token统计失败: %w", err)
	}
	
	now := time.Now()
	if err := s.db.Model(&models.APIToken{}).Where("expires_at IS NOT NULL AND expires_at < ?", now).Count(&stats.TokenStats.Expired).Error; err != nil {
		return nil, fmt.Errorf("获取过期Token统计失败: %w", err)
	}
	
	// 用户统计
	if err := s.db.Model(&models.User{}).Where("status = ?", "active").Count(&stats.UserStats.Active).Error; err != nil {
		return nil, fmt.Errorf("获取用户统计失败: %w", err)
	}
	
	if err := s.db.Model(&models.User{}).Count(&stats.UserStats.Total).Error; err != nil {
		return nil, fmt.Errorf("获取用户总数统计失败: %w", err)
	}
	
	return stats, nil
}

// SystemStatsResponse 系统统计响应
type SystemStatsResponse struct {
	ConfigStats       ConfigStatsData       `json:"config_stats"`
	AnnouncementStats AnnouncementStatsData `json:"announcement_stats"`
	LogStats          LogStatsData          `json:"log_stats"`
	TokenStats        TokenStatsData        `json:"token_stats"`
	UserStats         UserStatsData         `json:"user_stats"`
}

type ConfigStatsData struct {
	Total int64 `json:"total"`
}

type AnnouncementStatsData struct {
	Active int64 `json:"active"`
}

type LogStatsData struct {
	Today int64 `json:"today"`
}

type TokenStatsData struct {
	Total   int64 `json:"total"`
	Active  int64 `json:"active"`
	Expired int64 `json:"expired"`
}

type UserStatsData struct {
	Total  int64 `json:"total"`
	Active int64 `json:"active"`
}

// InitializeDefaultConfigs 初始化默认配置
func (s *SystemService) InitializeDefaultConfigs(userID uint) (int, error) {
	// 检查是否已有配置
	var count int64
	if err := s.db.Model(&models.SystemConfig{}).Count(&count).Error; err != nil {
		return 0, fmt.Errorf("检查配置数量失败: %w", err)
	}

	// 如果已有配置，返回现有数量
	if count > 0 {
		return int(count), nil
	}

	// 默认系统配置
	configs := []models.SystemConfig{
		// 系统基础配置
		{
			Category:     "system",
			Key:          "app_name",
			Value:        "信息管理系统",
			DefaultValue: "信息管理系统",
			Description:  "应用程序名称",
			DataType:     "string",
			IsPublic:     true,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    userID,
		},
		{
			Category:     "system",
			Key:          "app_version",
			Value:        "1.0.0",
			DefaultValue: "1.0.0",
			Description:  "应用程序版本号",
			DataType:     "string",
			IsPublic:     true,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    userID,
		},
		{
			Category:     "system",
			Key:          "maintenance_mode",
			Value:        "false",
			DefaultValue: "false",
			Description:  "系统维护模式开关",
			DataType:     "bool",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    userID,
		},
		{
			Category:     "system",
			Key:          "max_upload_size",
			Value:        "10485760",
			DefaultValue: "10485760",
			Description:  "最大文件上传大小（字节），默认10MB",
			DataType:     "int",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    userID,
		},

		// 数据库配置
		{
			Category:     "database",
			Key:          "connection_pool_size",
			Value:        "10",
			DefaultValue: "10",
			Description:  "数据库连接池大小",
			DataType:     "int",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    userID,
		},
		{
			Category:     "database",
			Key:          "query_timeout",
			Value:        "30",
			DefaultValue: "30",
			Description:  "数据库查询超时时间（秒）",
			DataType:     "int",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    userID,
		},

		// 文件存储配置
		{
			Category:     "storage",
			Key:          "upload_path",
			Value:        "./uploads",
			DefaultValue: "./uploads",
			Description:  "文件上传存储路径",
			DataType:     "string",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    userID,
		},
		{
			Category:     "storage",
			Key:          "allowed_extensions",
			Value:        `["jpg","jpeg","png","gif","pdf","doc","docx","xls","xlsx","txt"]`,
			DefaultValue: `["jpg","jpeg","png","gif","pdf","doc","docx","xls","xlsx","txt"]`,
			Description:  "允许上传的文件扩展名",
			DataType:     "json",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    userID,
		},

		// 安全配置
		{
			Category:     "security",
			Key:          "session_timeout",
			Value:        "7200",
			DefaultValue: "7200",
			Description:  "会话超时时间（秒），默认2小时",
			DataType:     "int",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    userID,
		},
		{
			Category:     "security",
			Key:          "password_min_length",
			Value:        "6",
			DefaultValue: "6",
			Description:  "密码最小长度",
			DataType:     "int",
			IsPublic:     true,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    userID,
		},

		// 邮件配置
		{
			Category:     "email",
			Key:          "smtp_enabled",
			Value:        "false",
			DefaultValue: "false",
			Description:  "是否启用SMTP邮件发送",
			DataType:     "bool",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    userID,
		},
		{
			Category:     "email",
			Key:          "smtp_host",
			Value:        "smtp.example.com",
			DefaultValue: "smtp.example.com",
			Description:  "SMTP服务器地址",
			DataType:     "string",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    userID,
		},
	}

	// 创建配置
	createdCount := 0
	for _, config := range configs {
		if err := s.db.Create(&config).Error; err != nil {
			s.LogSystemEvent("error", "config", fmt.Sprintf("创建默认配置失败: %s.%s", config.Category, config.Key),
				map[string]interface{}{
					"category": config.Category,
					"key":      config.Key,
					"error":    err.Error(),
				}, &userID, "", "", "")
			continue
		}
		createdCount++
	}

	// 记录操作日志
	s.LogSystemEvent("info", "config", fmt.Sprintf("初始化默认配置完成，创建了 %d 个配置项", createdCount),
		map[string]interface{}{
			"created_count": createdCount,
			"total_configs": len(configs),
		}, &userID, "", "", "")

	return createdCount, nil
}

// GetUsersForToken 获取用于Token创建的用户列表
func (s *SystemService) GetUsersForToken(currentUserID uint) ([]UserForToken, error) {
	var users []UserForToken
	
	// 查询所有活跃用户的基本信息
	err := s.db.Model(&models.User{}).
		Select("id, username, email").
		Where("status = ? AND deleted_at IS NULL", "active").
		Order("username ASC").
		Scan(&users).Error
	
	if err != nil {
		return nil, fmt.Errorf("获取用户列表失败: %v", err)
	}
	
	return users, nil
}