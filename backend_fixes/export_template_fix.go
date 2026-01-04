// Fix for export template creation - more flexible validation
type ExportTemplateRequestFlexible struct {
	Name        string                 `json:"name" binding:"required"`
	Description string                 `json:"description"`
	Format      string                 `json:"format"`
	Config      map[string]interface{} `json:"config"`
	Fields      []string               `json:"fields"`
	IsActive    *bool                  `json:"is_active"`
}

func (h *ExportHandler) CreateTemplateFlexible(c *gin.Context) {
	var req ExportTemplateRequestFlexible
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
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

	// Convert to original request format
	configJSON, _ := json.Marshal(req.Config)
	fieldsJSON, _ := json.Marshal(req.Fields)
	
	originalReq := &services.ExportTemplateRequest{
		Name:        req.Name,
		Description: req.Description,
		Format:      req.Format,
		Config:      string(configJSON),
		Fields:      string(fieldsJSON),
		IsActive:    *req.IsActive,
	}

	template, err := h.exportService.CreateTemplate(originalReq, userID)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    template,
	})
}
