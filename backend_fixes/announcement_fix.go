// Fix for announcement creation - more flexible validation
type AnnouncementRequestFlexible struct {
	Title     string `json:"title" binding:"required"`
	Content   string `json:"content" binding:"required"`
	Type      string `json:"type"`
	Priority  string `json:"priority"`
	IsActive  *bool  `json:"is_active"`
	StartTime string `json:"start_time"`
	EndTime   string `json:"end_time"`
}

func (h *SystemHandler) CreateAnnouncementFlexible(c *gin.Context) {
	var req AnnouncementRequestFlexible
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	// Set defaults
	if req.Type == "" {
		req.Type = "info"
	}
	if req.Priority == "" {
		req.Priority = "normal"
	}
	if req.IsActive == nil {
		active := true
		req.IsActive = &active
	}
	if req.StartTime == "" {
		req.StartTime = time.Now().Format(time.RFC3339)
	}
	if req.EndTime == "" {
		req.EndTime = time.Now().AddDate(0, 1, 0).Format(time.RFC3339)
	}

	userID := c.GetUint("user_id")

	announcement := &models.Announcement{
		Title:     req.Title,
		Content:   req.Content,
		Type:      req.Type,
		Priority:  req.Priority,
		IsActive:  *req.IsActive,
		CreatedBy: userID,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := h.systemService.db.Create(announcement).Error; err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    announcement,
	})
}
