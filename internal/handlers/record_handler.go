package handlers

import (
	"net/http"
	"strconv"

	"info-management-system/internal/middleware"
	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// RecordHandler 记录处理器
type RecordHandler struct {
	recordService *services.RecordService
}

// NewRecordHandler 创建记录处理器
func NewRecordHandler(recordService *services.RecordService) *RecordHandler {
	return &RecordHandler{
		recordService: recordService,
	}
}

// GetRecords 获取记录列表
func (h *RecordHandler) GetRecords(c *gin.Context) {
	var query services.RecordListQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	// 获取用户信息和权限
	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_records_permission")

	records, err := h.recordService.GetRecords(&query, userID, hasAllPermission)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, records)
}

// GetRecordByID 根据ID获取记录
func (h *RecordHandler) GetRecordByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的记录ID", "")
		return
	}

	// 获取用户信息和权限
	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_records_permission")

	record, err := h.recordService.GetRecordByID(uint(id), userID, hasAllPermission)
	if err != nil {
		if err.Error() == "记录不存在或无权访问" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "RECORD_NOT_FOUND",
					"message": "记录不存在或无权访问",
				},
			})
			return
		}

		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, record)
}

// CreateRecord 创建记录
func (h *RecordHandler) CreateRecord(c *gin.Context) {
	var req services.CreateRecordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	userID := c.GetUint("user_id")
	clientIP := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	record, err := h.recordService.CreateRecord(&req, userID, clientIP, userAgent)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    record,
	})
}

// UpdateRecord 更新记录
func (h *RecordHandler) UpdateRecord(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的记录ID", "")
		return
	}

	var req services.UpdateRecordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	// 获取用户信息和权限
	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_records_permission")
	clientIP := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	record, err := h.recordService.UpdateRecord(uint(id), &req, userID, hasAllPermission, clientIP, userAgent)
	if err != nil {
		if err.Error() == "记录不存在或无权修改" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "RECORD_NOT_FOUND",
					"message": "记录不存在或无权修改",
				},
			})
			return
		}

		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, record)
}

// DeleteRecord 删除记录
func (h *RecordHandler) DeleteRecord(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的记录ID", "")
		return
	}

	// 获取用户信息和权限
	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_records_permission")
	clientIP := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	err = h.recordService.DeleteRecord(uint(id), userID, hasAllPermission, clientIP, userAgent)
	if err != nil {
		if err.Error() == "记录不存在或无权删除" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "RECORD_NOT_FOUND",
					"message": "记录不存在或无权删除",
				},
			})
			return
		}

		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, gin.H{"message": "记录删除成功"})
}

// BatchCreateRecords 批量创建记录
func (h *RecordHandler) BatchCreateRecords(c *gin.Context) {
	var req services.BatchCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	userID := c.GetUint("user_id")
	clientIP := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	records, err := h.recordService.BatchCreateRecords(&req, userID, clientIP, userAgent)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    records,
	})
}

// ImportRecords 导入记录
func (h *RecordHandler) ImportRecords(c *gin.Context) {
	var req services.ImportRecordsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	userID := c.GetUint("user_id")
	clientIP := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	records, err := h.recordService.ImportRecords(&req, userID, clientIP, userAgent)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    records,
	})
}

// BatchUpdateRecordStatus 批量更新记录状态
func (h *RecordHandler) BatchUpdateRecordStatus(c *gin.Context) {
	var req services.BatchUpdateRecordStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	userID := c.GetUint("user_id")
	err := h.recordService.BatchUpdateRecordStatus(&req, userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "批量更新记录状态失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "批量更新成功"})
}

// BatchDeleteRecords 批量删除记录
func (h *RecordHandler) BatchDeleteRecords(c *gin.Context) {
	var req services.BatchDeleteRecordsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	userID := c.GetUint("user_id")
	err := h.recordService.BatchDeleteRecords(&req, userID)
	if err != nil {
		middleware.ValidationErrorResponse(c, "批量删除记录失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "批量删除成功"})
}

// GetRecordsByType 根据类型获取记录
func (h *RecordHandler) GetRecordsByType(c *gin.Context) {
	recordType := c.Param("type")
	if recordType == "" {
		middleware.ValidationErrorResponse(c, "记录类型不能为空", "")
		return
	}

	// 获取用户信息和权限
	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_records_permission")

	records, err := h.recordService.GetRecordsByType(recordType, userID, hasAllPermission)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, records)
}
