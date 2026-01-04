// Fix for record creation - handle nested content properly
func (h *RecordHandler) CreateRecordFlexible(c *gin.Context) {
	var req struct {
		Type     string                 `json:"type" binding:"required"`
		Title    string                 `json:"title" binding:"required"`
		Content  map[string]interface{} `json:"content"`
		Metadata map[string]interface{} `json:"metadata"`
		Status   string                 `json:"status"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
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

	// Convert content and metadata to JSON strings
	contentJSON, _ := json.Marshal(req.Content)
	metadataJSON, _ := json.Marshal(req.Metadata)

	record := &models.Record{
		Type:      req.Type,
		Title:     req.Title,
		Content:   string(contentJSON),
		Metadata:  string(metadataJSON),
		Status:    req.Status,
		CreatedBy: userID,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := h.recordService.db.Create(record).Error; err != nil {
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
