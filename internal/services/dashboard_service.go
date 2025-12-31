package services

import (
	"fmt"
	"time"

	"info-management-system/internal/models"

	"gorm.io/gorm"
)

// DashboardService 仪表盘服务
type DashboardService struct {
	db *gorm.DB
}

// NewDashboardService 创建仪表盘服务
func NewDashboardService(db *gorm.DB) *DashboardService {
	return &DashboardService{db: db}
}

// DashboardStats 仪表盘统计数据
type DashboardStats struct {
	Records      int64 `json:"records"`       // 记录总数
	Files        int64 `json:"files"`         // 文件总数
	Users        int64 `json:"users"`         // 用户总数
	TodayRecords int64 `json:"today_records"` // 今日新增记录
}

// RecentRecord 最近记录
type RecentRecord struct {
	ID        uint   `json:"id"`
	Title     string `json:"title"`
	Type      string `json:"type"`
	CreatedAt string `json:"created_at"`
	Creator   string `json:"creator"`
}

// SystemInfo 系统信息
type SystemInfo struct {
	Uptime   string `json:"uptime"`
	DBStatus string `json:"db_status"`
	Version  string `json:"version"`
}

// GetDashboardStats 获取仪表盘统计数据
func (s *DashboardService) GetDashboardStats(userID uint, hasAllRecordsPermission, hasAllFilesPermission, hasSystemPermission bool) (*DashboardStats, error) {
	stats := &DashboardStats{}

	// 获取记录总数
	recordQuery := s.db.Model(&models.Record{})
	if !hasAllRecordsPermission {
		recordQuery = recordQuery.Where("created_by = ?", userID)
	}
	if err := recordQuery.Count(&stats.Records).Error; err != nil {
		return nil, fmt.Errorf("failed to count records: %w", err)
	}

	// 获取文件总数
	fileQuery := s.db.Model(&models.File{})
	if !hasAllFilesPermission {
		fileQuery = fileQuery.Where("uploaded_by = ?", userID)
	}
	if err := fileQuery.Count(&stats.Files).Error; err != nil {
		return nil, fmt.Errorf("failed to count files: %w", err)
	}

	// 获取用户总数（只有有系统权限的用户能看到）
	if hasSystemPermission {
		if err := s.db.Model(&models.User{}).Count(&stats.Users).Error; err != nil {
			return nil, fmt.Errorf("failed to count users: %w", err)
		}
	}

	// 获取今日新增记录数
	today := time.Now().Format("2006-01-02")
	todayQuery := s.db.Model(&models.Record{}).Where("DATE(created_at) = ?", today)
	if !hasAllRecordsPermission {
		todayQuery = todayQuery.Where("created_by = ?", userID)
	}
	if err := todayQuery.Count(&stats.TodayRecords).Error; err != nil {
		return nil, fmt.Errorf("failed to count today records: %w", err)
	}

	return stats, nil
}

// GetRecentRecords 获取最近记录
func (s *DashboardService) GetRecentRecords(userID uint, hasAllRecordsPermission bool, limit int) ([]RecentRecord, error) {
	var records []models.Record
	
	query := s.db.Preload("Creator").Order("created_at DESC").Limit(limit)
	if !hasAllRecordsPermission {
		query = query.Where("created_by = ?", userID)
	}
	
	if err := query.Find(&records).Error; err != nil {
		return nil, fmt.Errorf("failed to get recent records: %w", err)
	}

	recentRecords := make([]RecentRecord, len(records))
	for i, record := range records {
		creatorName := "未知用户"
		if record.Creator.ID != 0 {
			if record.Creator.DisplayName != "" {
				creatorName = record.Creator.DisplayName
			} else {
				creatorName = record.Creator.Username
			}
		}

		recentRecords[i] = RecentRecord{
			ID:        record.ID,
			Title:     record.Title,
			Type:      record.Type,
			CreatedAt: record.CreatedAt.Format("2006-01-02 15:04:05"),
			Creator:   creatorName,
		}
	}

	return recentRecords, nil
}

// GetSystemInfo 获取系统信息
func (s *DashboardService) GetSystemInfo() (*SystemInfo, error) {
	// 检查数据库状态
	dbStatus := "healthy"
	if err := s.db.Exec("SELECT 1").Error; err != nil {
		dbStatus = "unhealthy"
	}

	// 获取系统运行时间
	uptime := s.getSystemUptime()

	return &SystemInfo{
		Uptime:   uptime,
		DBStatus: dbStatus,
		Version:  "v1.0.0",
	}, nil
}

// getSystemUptime 获取系统运行时间
func (s *DashboardService) getSystemUptime() string {
	// 查询系统启动日志来计算运行时间
	var systemLog models.SystemLog
	err := s.db.Where("category = ? AND message = ?", "system", "系统启动").
		Order("created_at DESC").
		First(&systemLog).Error
	
	if err != nil {
		return "运行中"
	}
	
	// 计算运行时间
	duration := time.Since(systemLog.CreatedAt)
	
	days := int(duration.Hours()) / 24
	hours := int(duration.Hours()) % 24
	minutes := int(duration.Minutes()) % 60
	
	if days > 0 {
		return fmt.Sprintf("%d天 %d小时 %d分钟", days, hours, minutes)
	} else if hours > 0 {
		return fmt.Sprintf("%d小时 %d分钟", hours, minutes)
	} else {
		return fmt.Sprintf("%d分钟", minutes)
	}
}