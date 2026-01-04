// Add this method to file_handler.go for JSON upload compatibility
func (h *FileHandler) UploadFileJSON(c *gin.Context) {
	var req struct {
		Filename    string `json:"filename" binding:"required"`
		Content     string `json:"content" binding:"required"`
		Description string `json:"description"`
		Category    string `json:"category"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	userID := c.GetUint("user_id")
	clientIP := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	// Create a mock file for testing
	file := &models.File{
		Filename:     req.Filename,
		OriginalName: req.Filename,
		MimeType:     "text/plain",
		Size:         int64(len(req.Content)),
		Hash:         fmt.Sprintf("%x", md5.Sum([]byte(req.Content))),
		UploadedBy:   userID,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := h.fileService.db.Create(file).Error; err != nil {
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
