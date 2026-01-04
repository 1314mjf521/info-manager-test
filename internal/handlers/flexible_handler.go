package handlers

import (
	"crypto/md5"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"info-management-system/internal/middleware"
	"info-management-system/internal/models"
	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// FlexibleHandler provides more lenient API endpoints for testing
type FlexibleHandler struct {
	fileService   *services.FileService
	exportService *services.ExportService
	systemService *services.SystemService
	recordService *services.RecordService
	ticketService *services.TicketService
}

// NewFlexibleHandler creates a new flexible handler
func NewFlexibleHandler(
	fileService *services.FileService,
	exportService *services.ExportService,
	systemService *services.SystemService,
	recordService *services.RecordService,
	ticketService *services.TicketService,
) *FlexibleHandler {
	return &FlexibleHandler{
		fileService:   fileService,
		exportService: exportService,
		systemService: systemService,
		recordService: recordService,
		ticketService: ticketService,
	}
}

// FlexibleFileUpload handles JSON-based file upload for testing
func (h *FlexibleHandler) FlexibleFileUpload(c *gin.Context) {
	var req struct {
		Filename    string `json:"filename"`
		Content     string `json:"content"`
		Description string `json:"description"`
		Category    string `json:"category"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	if req.Filename == "" {
		middleware.ValidationErrorResponse(c, "文件名不能为空", "")
		return
	}

	userID := c.GetUint("user_id")

	// Create a mock file record for testing
	file := &models.File{
		Filename:     fmt.Sprintf("%d_%s", time.Now().Unix(), req.Filename),
		OriginalName: req.Filename,
		MimeType:     "text/plain",
		Size:         int64(len(req.Content)),
		Hash:         fmt.Sprintf("%x", md5.Sum([]byte(req.Content))),
		UploadedBy:   userID,
		Path:         fmt.Sprintf("./uploads/%d_%s", time.Now().Unix(), req.Filename),
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := h.fileService.CreateFileRecord(file); err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data": gin.H{
			"file": file,
		},
	})
}

// FlexibleExportTemplate handles flexible export template creation
func (h *FlexibleHandler) FlexibleExportTemplate(c *gin.Context) {
	var req struct {
		Name        string                 `json:"name"`
		Description string                 `json:"description"`
		Config      map[string]interface{} `json:"config"`
		Format      string                 `json:"format"`
		IsActive    *bool                  `json:"is_active"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	if req.Name == "" {
		middleware.ValidationErrorResponse(c, "模板名称不能为空", "")
		return
	}

	// Set defaults
	if req.Format == "" {
		req.Format = "csv"
	}
	if req.Config == nil {
		req.Config = map[string]interface{}{"format": req.Format}
	}
	if req.IsActive == nil {
		active := true
		req.IsActive = &active
	}

	userID := c.GetUint("user_id")

	// Convert to service request format
	configJSON, _ := json.Marshal(req.Config)
	serviceReq := &services.ExportTemplateRequest{
		Name:        req.Name,
		Description: req.Description,
		Format:      req.Format,
		Config:      string(configJSON),
		Fields:      "[]", // Empty fields array
		IsActive:    *req.IsActive,
	}

	template, err := h.exportService.CreateTemplate(serviceReq, userID)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data": gin.H{
			"template": template,
		},
	})
}

// FlexibleAnnouncement handles flexible announcement creation
func (h *FlexibleHandler) FlexibleAnnouncement(c *gin.Context) {
	var req struct {
		Title    string `json:"title"`
		Content  string `json:"content"`
		Type     string `json:"type"`
		Priority int    `json:"priority"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	if req.Title == "" || req.Content == "" {
		middleware.ValidationErrorResponse(c, "标题和内容不能为空", "")
		return
	}

	// Set defaults
	if req.Type == "" {
		req.Type = "info"
	}
	if req.Priority == 0 {
		req.Priority = 1
	}

	userID := c.GetUint("user_id")

	// Create announcement directly in database for testing
	announcement := &models.Announcement{
		Title:     req.Title,
		Content:   req.Content,
		Type:      req.Type,
		Priority:  req.Priority,
		IsActive:  true,
		CreatedBy: userID,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := h.systemService.GetDB().Create(announcement).Error; err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data": gin.H{
			"announcement": announcement,
		},
	})
}

// FlexibleRecord handles flexible record creation
func (h *FlexibleHandler) FlexibleRecord(c *gin.Context) {
	var req struct {
		Type     string                 `json:"type"`
		Title    string                 `json:"title"`
		Content  map[string]interface{} `json:"content"`
		Metadata map[string]interface{} `json:"metadata"`
		Status   string                 `json:"status"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	if req.Type == "" || req.Title == "" {
		middleware.ValidationErrorResponse(c, "类型和标题不能为空", "")
		return
	}

	// Set defaults
	if req.Status == "" {
		req.Status = "active"
	}
	if req.Content == nil {
		req.Content = make(map[string]interface{})
	}
	if req.Metadata == nil {
		req.Metadata = make(map[string]interface{})
	}

	userID := c.GetUint("user_id")

	serviceReq := &services.CreateRecordRequest{
		Type:    req.Type,
		Title:   req.Title,
		Content: req.Content,
	}

	record, err := h.recordService.CreateRecord(serviceReq, userID, c.ClientIP(), c.GetHeader("User-Agent"))
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data": gin.H{
			"record": record,
		},
	})
}

// FlexibleTicketAssign handles flexible ticket assignment
func (h *FlexibleHandler) FlexibleTicketAssign(c *gin.Context) {
	ticketID := c.Param("id")
	id, err := strconv.ParseUint(ticketID, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的工单ID", "")
		return
	}

	var req struct {
		AssigneeID uint   `json:"assigneeId"`
		Reason     string `json:"reason"`
		Notify     *bool  `json:"notifyAssignee"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	if req.AssigneeID == 0 {
		middleware.ValidationErrorResponse(c, "分配人ID不能为空", "")
		return
	}

	userID := c.GetUint("user_id")

	err = h.ticketService.AssignTicket(uint(id), req.AssigneeID, userID, req.Reason)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "工单分配成功",
	})
}

// FlexibleTicketReject handles flexible ticket rejection
func (h *FlexibleHandler) FlexibleTicketReject(c *gin.Context) {
	ticketID := c.Param("id")
	id, err := strconv.ParseUint(ticketID, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的工单ID", "")
		return
	}

	var req struct {
		Reason   string `json:"reason"`
		Comment  string `json:"comment"`
		Reassign *bool  `json:"reassign"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	if req.Reason == "" {
		middleware.ValidationErrorResponse(c, "拒绝原因不能为空", "")
		return
	}

	userID := c.GetUint("user_id")

	err = h.ticketService.RejectTicket(uint(id), userID, req.Reason)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "工单拒绝成功",
	})
}

// FlexibleTicketStatusChange handles flexible ticket status change
func (h *FlexibleHandler) FlexibleTicketStatusChange(c *gin.Context) {
	ticketID := c.Param("id")
	id, err := strconv.ParseUint(ticketID, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的工单ID", "")
		return
	}

	var req struct {
		Status  string `json:"status"`
		Comment string `json:"comment"`
		Notify  *bool  `json:"notifyStakeholders"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	if req.Status == "" {
		middleware.ValidationErrorResponse(c, "状态不能为空", "")
		return
	}

	userID := c.GetUint("user_id")

	err = h.ticketService.UpdateTicketStatus(uint(id), req.Status, userID, req.Comment)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "工单状态更新成功",
	})
}

// FlexibleExportRecords handles flexible record export
func (h *FlexibleHandler) FlexibleExportRecords(c *gin.Context) {
	var req struct {
		Format  string            `json:"format"`
		Filters map[string]string `json:"filters"`
		Fields  []string          `json:"fields"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	// Set defaults
	if req.Format == "" {
		req.Format = "csv"
	}
	if req.Fields == nil {
		req.Fields = []string{"id", "title", "created_at"}
	}

	userID := c.GetUint("user_id")

	// Create export request
	exportReq := &services.ExportRequest{
		Format:   req.Format,
		TaskName: fmt.Sprintf("Records Export %d", time.Now().Unix()),
		Filters:  req.Filters,
		Fields:   req.Fields,
		Config:   map[string]interface{}{"format": req.Format},
	}

	result, err := h.exportService.ExportRecords(exportReq, userID)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    result,
	})
}

// FlexibleOCR handles flexible OCR processing
func (h *FlexibleHandler) FlexibleOCR(c *gin.Context) {
	var req struct {
		FileID   uint   `json:"fileId"`
		Language string `json:"language"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	if req.FileID == 0 {
		middleware.ValidationErrorResponse(c, "文件ID不能为空", "")
		return
	}

	// Set defaults
	if req.Language == "" {
		req.Language = "eng"
	}

	// Mock OCR result for testing
	result := map[string]interface{}{
		"file_id":    req.FileID,
		"language":   req.Language,
		"text":       "Mock OCR result for testing",
		"confidence": 0.95,
		"processed_at": time.Now().Format(time.RFC3339),
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    result,
	})
}