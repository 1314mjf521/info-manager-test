package handlers

import (
	"net/http"
	"strconv"
	"strings"

	"info-management-system/internal/middleware"
	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// RecordTypeHandler 记录类型处理器
type RecordTypeHandler struct {
	recordTypeService *services.RecordTypeService
}

// NewRecordTypeHandler 创建记录类型处理器
func NewRecordTypeHandler(recordTypeService *services.RecordTypeService) *RecordTypeHandler {
	return &RecordTypeHandler{
		recordTypeService: recordTypeService,
	}
}

// GetAllRecordTypes 获取所有记录类型
func (h *RecordTypeHandler) GetAllRecordTypes(c *gin.Context) {
	recordTypes, err := h.recordTypeService.GetAllRecordTypes()
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, recordTypes)
}

// GetRecordTypeByID 根据ID获取记录类型
func (h *RecordTypeHandler) GetRecordTypeByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的记录类型ID", "")
		return
	}

	recordType, err := h.recordTypeService.GetRecordTypeByID(uint(id))
	if err != nil {
		if err.Error() == "记录类型不存在" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "RECORD_TYPE_NOT_FOUND",
					"message": "记录类型不存在",
				},
			})
			return
		}

		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, recordType)
}

// CreateRecordType 创建记录类型
func (h *RecordTypeHandler) CreateRecordType(c *gin.Context) {
	var req services.CreateRecordTypeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	recordType, err := h.recordTypeService.CreateRecordType(&req)
	if err != nil {
		if err.Error() == "记录类型名称已存在" {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "DUPLICATE_NAME",
					"message": "记录类型名称已存在",
				},
			})
			return
		}

		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    recordType,
	})
}

// UpdateRecordType 更新记录类型
func (h *RecordTypeHandler) UpdateRecordType(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的记录类型ID", "")
		return
	}

	var req services.UpdateRecordTypeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	recordType, err := h.recordTypeService.UpdateRecordType(uint(id), &req)
	if err != nil {
		if err.Error() == "记录类型不存在" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "RECORD_TYPE_NOT_FOUND",
					"message": "记录类型不存在",
				},
			})
			return
		}

		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, recordType)
}

// DeleteRecordType 删除记录类型
func (h *RecordTypeHandler) DeleteRecordType(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的记录类型ID", "")
		return
	}

	err = h.recordTypeService.DeleteRecordType(uint(id))
	if err != nil {
		if err.Error() == "记录类型不存在" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "RECORD_TYPE_NOT_FOUND",
					"message": "记录类型不存在",
				},
			})
			return
		}

		if strings.Contains(err.Error(), "该记录类型正在被") {
			c.JSON(http.StatusConflict, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "TYPE_IN_USE",
					"message": err.Error(),
				},
			})
			return
		}

		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, gin.H{"message": "记录类型删除成功"})
}

// ImportRecordTypes 导入记录类型
func (h *RecordTypeHandler) ImportRecordTypes(c *gin.Context) {
	var req services.ImportRecordTypesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	results, err := h.recordTypeService.ImportRecordTypes(&req)
	if err != nil {
		middleware.ValidationErrorResponse(c, "导入记录类型失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"results": results})
}

// BatchUpdateRecordTypeStatus 批量更新记录类型状态
func (h *RecordTypeHandler) BatchUpdateRecordTypeStatus(c *gin.Context) {
	var req services.BatchUpdateRecordTypeStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	err := h.recordTypeService.BatchUpdateRecordTypeStatus(&req)
	if err != nil {
		middleware.ValidationErrorResponse(c, "批量更新记录类型状态失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "批量更新成功"})
}

// BatchDeleteRecordTypes 批量删除记录类型
func (h *RecordTypeHandler) BatchDeleteRecordTypes(c *gin.Context) {
	var req services.BatchDeleteRecordTypesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	err := h.recordTypeService.BatchDeleteRecordTypes(&req)
	if err != nil {
		middleware.ValidationErrorResponse(c, "批量删除记录类型失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{"message": "批量删除成功"})
}
