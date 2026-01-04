// Fix for ticket operations - more flexible parameter handling
func (h *TicketHandler) AssignTicketFlexible(c *gin.Context) {
	ticketID := c.Param("id")
	id, err := strconv.ParseUint(ticketID, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的工单ID", "")
		return
	}

	var req struct {
		AssigneeID uint   `json:"assigneeId" binding:"required"`
		Reason     string `json:"reason"`
		Notify     *bool  `json:"notifyAssignee"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	userID := c.GetUint("user_id")

	// Set defaults
	if req.Notify == nil {
		notify := true
		req.Notify = &notify
	}

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

func (h *TicketHandler) RejectTicketFlexible(c *gin.Context) {
	ticketID := c.Param("id")
	id, err := strconv.ParseUint(ticketID, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的工单ID", "")
		return
	}

	var req struct {
		Reason    string `json:"reason" binding:"required"`
		Comment   string `json:"comment"`
		Reassign  *bool  `json:"reassign"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	userID := c.GetUint("user_id")

	// Set defaults
	if req.Reassign == nil {
		reassign := false
		req.Reassign = &reassign
	}

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
