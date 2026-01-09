package main

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	
	"info-management-system/internal/handlers"
	"info-management-system/internal/middleware"
	"info-management-system/internal/services"
)

// SetupFixedTicketRoutes 设置修复的工单路由
func SetupFixedTicketRoutes(router *gin.Engine, db *gorm.DB, notificationService *services.NotificationService) {
	// 创建修复的工单处理器
	fixedHandler := handlers.NewCompleteTicketWorkflowHandler(db, notificationService)
	
	// API路由组
	api := router.Group("/api/v1")
	api.Use(middleware.AuthRequired())
	
	// 工单路由组
	tickets := api.Group("/tickets")
	
	// 修复的工单状态更新路由
	tickets.PUT("/:id/status-fixed", fixedHandler.UpdateTicketStatusFixed)
	
	// 修复的工单操作路由
	tickets.POST("/:id/accept-fixed", fixedHandler.AcceptTicketFixed)
	tickets.POST("/:id/reject-fixed", fixedHandler.RejectTicketFixed)
	tickets.POST("/:id/reopen-fixed", fixedHandler.ReopenTicketFixed)
	tickets.POST("/:id/resubmit-fixed", fixedHandler.ResubmitTicketFixed)
	
	// 工单流程信息路由
	tickets.GET("/:id/workflow", fixedHandler.GetTicketWorkflowInfo)
	
	// 替换原有的路由（如果需要）
	// 注意：这会覆盖原有的路由，请谨慎使用
	tickets.PUT("/:id/status", fixedHandler.UpdateTicketStatusFixed)
	tickets.POST("/:id/accept", fixedHandler.AcceptTicketFixed)
	tickets.POST("/:id/reject", fixedHandler.RejectTicketFixed)
	tickets.POST("/:id/reopen", fixedHandler.ReopenTicketFixed)
	tickets.POST("/:id/resubmit", fixedHandler.ResubmitTicketFixed)
}