// Add these routes to your router setup for flexible API endpoints
func RegisterFlexibleRoutes(r *gin.Engine, handlers *Handlers) {
	api := r.Group("/api/v1")
	
	// Flexible file upload
	api.POST("/files/upload-json", middleware.AuthRequired(), handlers.File.UploadFileJSON)
	
	// Flexible export templates
	api.POST("/export/templates-flexible", middleware.AuthRequired(), handlers.Export.CreateTemplateFlexible)
	
	// Flexible announcements
	api.POST("/announcements-flexible", middleware.AuthRequired(), handlers.System.CreateAnnouncementFlexible)
	
	// Flexible records
	api.POST("/records-flexible", middleware.AuthRequired(), handlers.Record.CreateRecordFlexible)
	
	// Flexible ticket operations
	api.POST("/tickets/:id/assign-flexible", middleware.AuthRequired(), handlers.Ticket.AssignTicketFlexible)
	api.POST("/tickets/:id/reject-flexible", middleware.AuthRequired(), handlers.Ticket.RejectTicketFlexible)
}
