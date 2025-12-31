package handlers

import (
	"net/http"
	"strconv"

	"info-management-system/internal/middleware"
	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// ExportHandler 导出处理器
type ExportHandler struct {
	exportService *services.ExportService
}

// NewExportHandler 创建导出处理器
func NewExportHandler(exportService *services.ExportService) *ExportHandler {
	return &ExportHandler{
		exportService: exportService,
	}
}

// CreateTemplate 创建导出模板
func (h *ExportHandler) CreateTemplate(c *gin.Context) {
	var req services.ExportTemplateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	userID := c.GetUint("user_id")

	template, err := h.exportService.CreateTemplate(&req, userID)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    template,
	})
}

// GetTemplates 获取导出模板列表
func (h *ExportHandler) GetTemplates(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 10
	}

	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_export_permission")

	result, err := h.exportService.GetTemplates(page, pageSize, userID, hasAllPermission)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, result)
}

// GetTemplateByID 根据ID获取导出模板
func (h *ExportHandler) GetTemplateByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的模板ID", "")
		return
	}

	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_export_permission")

	template, err := h.exportService.GetTemplateByID(uint(id), userID, hasAllPermission)
	if err != nil {
		if err.Error() == "模板不存在或无权访问" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "TEMPLATE_NOT_FOUND",
					"message": "模板不存在或无权访问",
				},
			})
			return
		}

		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, template)
}

// UpdateTemplate 更新导出模板
func (h *ExportHandler) UpdateTemplate(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的模板ID", "")
		return
	}

	var req services.ExportTemplateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_export_permission")

	template, err := h.exportService.UpdateTemplate(uint(id), &req, userID, hasAllPermission)
	if err != nil {
		if err.Error() == "模板不存在或无权修改" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "TEMPLATE_NOT_FOUND",
					"message": "模板不存在或无权修改",
				},
			})
			return
		}

		if err.Error() == "系统模板不允许修改" {
			c.JSON(http.StatusForbidden, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "SYSTEM_TEMPLATE_READONLY",
					"message": "系统模板不允许修改",
				},
			})
			return
		}

		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, template)
}

// DeleteTemplate 删除导出模板
func (h *ExportHandler) DeleteTemplate(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的模板ID", "")
		return
	}

	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_export_permission")

	err = h.exportService.DeleteTemplate(uint(id), userID, hasAllPermission)
	if err != nil {
		if err.Error() == "模板不存在或无权删除" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "TEMPLATE_NOT_FOUND",
					"message": "模板不存在或无权删除",
				},
			})
			return
		}

		if err.Error() == "系统模板不允许删除" {
			c.JSON(http.StatusForbidden, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "SYSTEM_TEMPLATE_READONLY",
					"message": "系统模板不允许删除",
				},
			})
			return
		}

		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, gin.H{"message": "模板删除成功"})
}

// ExportRecords 导出记录
func (h *ExportHandler) ExportRecords(c *gin.Context) {
	var req services.ExportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	userID := c.GetUint("user_id")

	result, err := h.exportService.CreateExportTask(&req, userID)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusAccepted, gin.H{
		"success": true,
		"data":    result,
	})
}

// GetTasks 获取导出任务列表
func (h *ExportHandler) GetTasks(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 10
	}

	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_export_permission")

	result, err := h.exportService.GetTasks(page, pageSize, userID, hasAllPermission)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, result)
}

// GetTaskByID 根据ID获取导出任务
func (h *ExportHandler) GetTaskByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的任务ID", "")
		return
	}

	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_export_permission")

	task, err := h.exportService.GetTaskByID(uint(id), userID, hasAllPermission)
	if err != nil {
		if err.Error() == "任务不存在或无权访问" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "TASK_NOT_FOUND",
					"message": "任务不存在或无权访问",
				},
			})
			return
		}

		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, task)
}

// GetFiles 获取导出文件列表
func (h *ExportHandler) GetFiles(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 10
	}

	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_export_permission")

	result, err := h.exportService.GetFiles(page, pageSize, userID, hasAllPermission)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, result)
}

// DownloadFile 下载导出文件（通过任务ID）
func (h *ExportHandler) DownloadFile(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的任务ID", "")
		return
	}

	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_export_permission")

	file, err := h.exportService.DownloadFileByTaskID(uint(id), userID, hasAllPermission)
	if err != nil {
		if err.Error() == "文件不存在或无权访问" || err.Error() == "文件不存在" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "FILE_NOT_FOUND",
					"message": "文件不存在或无权访问",
				},
			})
			return
		}

		if err.Error() == "文件已过期" {
			c.JSON(http.StatusGone, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "FILE_EXPIRED",
					"message": "文件已过期",
				},
			})
			return
		}

		middleware.InternalErrorResponse(c, err)
		return
	}

	// 设置响应头
	c.Header("Content-Description", "File Transfer")
	c.Header("Content-Transfer-Encoding", "binary")
	c.Header("Content-Disposition", "attachment; filename="+file.FileName)
	c.Header("Content-Type", "application/octet-stream")

	// 发送文件
	c.File(file.FilePath)
}