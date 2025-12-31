package handlers

import (
	"info-management-system/internal/middleware"
	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// DashboardHandler 仪表盘处理器
type DashboardHandler struct {
	dashboardService *services.DashboardService
}

// NewDashboardHandler 创建仪表盘处理器
func NewDashboardHandler(dashboardService *services.DashboardService) *DashboardHandler {
	return &DashboardHandler{
		dashboardService: dashboardService,
	}
}

// GetDashboardStats 获取仪表盘统计数据
func (h *DashboardHandler) GetDashboardStats(c *gin.Context) {
	userID := c.GetUint("user_id")
	hasAllRecordsPermission := c.GetBool("has_all_records_permission")
	hasAllFilesPermission := c.GetBool("has_all_files_permission")
	hasSystemPermission := c.GetBool("has_system_permission")

	stats, err := h.dashboardService.GetDashboardStats(userID, hasAllRecordsPermission, hasAllFilesPermission, hasSystemPermission)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, stats)
}

// GetRecentRecords 获取最近记录
func (h *DashboardHandler) GetRecentRecords(c *gin.Context) {
	userID := c.GetUint("user_id")
	hasAllRecordsPermission := c.GetBool("has_all_records_permission")

	records, err := h.dashboardService.GetRecentRecords(userID, hasAllRecordsPermission, 10)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, records)
}

// GetSystemInfo 获取系统信息
func (h *DashboardHandler) GetSystemInfo(c *gin.Context) {
	systemInfo, err := h.dashboardService.GetSystemInfo()
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, systemInfo)
}