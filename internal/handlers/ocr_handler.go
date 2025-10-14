package handlers

import (
	"net/http"

	"info-management-system/internal/middleware"
	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// OCRHandler OCR处理器
type OCRHandler struct {
	ocrService *services.OCRService
}

// NewOCRHandler 创建OCR处理器
func NewOCRHandler(ocrService *services.OCRService) *OCRHandler {
	return &OCRHandler{
		ocrService: ocrService,
	}
}

// RecognizeText OCR文字识别
func (h *OCRHandler) RecognizeText(c *gin.Context) {
	var req services.OCRRequest
	if err := c.ShouldBind(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	// 验证图片文件
	if err := h.ocrService.ValidateImage(req.File); err != nil {
		middleware.ValidationErrorResponse(c, "图片验证失败", err.Error())
		return
	}

	userID := c.GetUint("user_id")

	result, err := h.ocrService.RecognizeText(&req, userID)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    result,
	})
}

// GetSupportedLanguages 获取支持的语言列表
func (h *OCRHandler) GetSupportedLanguages(c *gin.Context) {
	languages := h.ocrService.GetSupportedLanguages()
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"languages": languages,
		},
	})
}