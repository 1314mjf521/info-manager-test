package app

import (
	"fmt"
	"os"

	"info-management-system/internal/config"
	"info-management-system/internal/database"
	"info-management-system/internal/handlers"
	"info-management-system/internal/middleware"
	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// App 应用结构
type App struct {
	config              *config.Config
	router              *gin.Engine
	logger              *logrus.Logger
	authService         *services.AuthService
	userService         *services.UserService
	permissionService   *services.PermissionService
	roleService         *services.RoleService
	recordService       *services.RecordService
	recordTypeService   *services.RecordTypeService
	auditService        *services.AuditService
	fileService         *services.FileService
	ocrService          *services.OCRService
	exportService       *services.ExportService
	notificationService *services.NotificationService
	aiService           *services.AIService
	systemService       *services.SystemService
	authHandler         *handlers.AuthHandler
	userHandler         *handlers.UserHandler
	permissionHandler   *handlers.PermissionHandler
	roleHandler         *handlers.RoleHandler
	recordHandler       *handlers.RecordHandler
	recordTypeHandler   *handlers.RecordTypeHandler
	auditHandler        *handlers.AuditHandler
	fileHandler         *handlers.FileHandler
	ocrHandler          *handlers.OCRHandler
	exportHandler       *handlers.ExportHandler
	notificationHandler *handlers.NotificationHandler
	aiHandler           *handlers.AIHandler
	systemHandler       *handlers.SystemHandler
}

// New 创建新的应用实例
func New(cfg *config.Config) (*App, error) {
	app := &App{
		config: cfg,
	}

	// 初始化日志
	if err := app.initLogger(); err != nil {
		return nil, fmt.Errorf("failed to initialize logger: %w", err)
	}

	// 连接数据库
	if err := database.Connect(&cfg.Database); err != nil {
		return nil, fmt.Errorf("failed to connect database: %w", err)
	}

	// 执行数据库迁移
	if err := database.Migrate(database.GetDB()); err != nil {
		return nil, fmt.Errorf("failed to migrate database: %w", err)
	}

	// 初始化服务
	if err := app.initServices(); err != nil {
		return nil, fmt.Errorf("failed to initialize services: %w", err)
	}

	// 初始化路由
	app.initRouter()

	return app, nil
}

// initLogger 初始化日志
func (a *App) initLogger() error {
	a.logger = logrus.New()

	// 设置日志级别
	level, err := logrus.ParseLevel(a.config.Log.Level)
	if err != nil {
		return fmt.Errorf("invalid log level: %w", err)
	}
	a.logger.SetLevel(level)

	// 设置日志格式
	if a.config.Log.Format == "json" {
		a.logger.SetFormatter(&logrus.JSONFormatter{})
	} else {
		a.logger.SetFormatter(&logrus.TextFormatter{
			FullTimestamp: true,
		})
	}

	// 设置输出
	a.logger.SetOutput(os.Stdout)

	return nil
}

// initServices 初始化服务
func (a *App) initServices() error {
	db := database.GetDB()

	// 初始化服务
	a.authService = services.NewAuthService(db, a.config)
	a.userService = services.NewUserService(db)
	a.permissionService = services.NewPermissionService(db)
	a.roleService = services.NewRoleService(db)
	a.auditService = services.NewAuditService(db)
	a.recordTypeService = services.NewRecordTypeService(db)
	a.recordService = services.NewRecordService(db, a.recordTypeService, a.auditService)
	a.fileService = services.NewFileService(db, a.auditService)
	a.ocrService = services.NewOCRService("", "") // 暂时使用空配置，将使用模拟模式
	a.exportService = services.NewExportService(db, a.recordService)
	a.notificationService = services.NewNotificationService(db)
	a.aiService = services.NewAIService(db)
	a.systemService = services.NewSystemService(db)

	// 初始化处理器
	a.authHandler = handlers.NewAuthHandler(a.authService, a.userService)
	a.userHandler = handlers.NewUserHandler(a.userService, a.roleService)
	a.permissionHandler = handlers.NewPermissionHandler(a.permissionService)
	a.roleHandler = handlers.NewRoleHandler(a.roleService)
	a.recordHandler = handlers.NewRecordHandler(a.recordService)
	a.recordTypeHandler = handlers.NewRecordTypeHandler(a.recordTypeService)
	a.auditHandler = handlers.NewAuditHandler(a.auditService)
	a.fileHandler = handlers.NewFileHandler(a.fileService)
	a.ocrHandler = handlers.NewOCRHandler(a.ocrService)
	a.exportHandler = handlers.NewExportHandler(a.exportService)
	a.notificationHandler = handlers.NewNotificationHandler(a.notificationService)
	a.aiHandler = handlers.NewAIHandler(a.aiService)
	a.systemHandler = handlers.NewSystemHandler(a.systemService)

	return nil
}

// initRouter 初始化路由
func (a *App) initRouter() {
	// 设置Gin模式
	gin.SetMode(a.config.Server.Mode)

	a.router = gin.New()

	// 添加中间件
	a.router.Use(middleware.RequestID())
	a.router.Use(middleware.Logger(a.logger))
	a.router.Use(middleware.OptionalAuthMiddleware(a.authService))   // 添加可选认证中间件（全局）
	a.router.Use(middleware.SystemLoggerMiddleware(a.systemService)) // 添加系统日志中间件
	a.router.Use(middleware.AuthLoggerMiddleware(a.systemService))   // 添加认证日志中间件
	a.router.Use(middleware.CORS())
	a.router.Use(middleware.ErrorHandler(a.logger))
	a.router.Use(gin.Recovery())

	// 记录系统启动日志
	middleware.InitialSystemLogs(a.systemService)

	// 健康检查路由
	a.router.GET("/health", a.healthCheck)
	a.router.GET("/ready", a.readinessCheck)

	// API路由组
	v1 := a.router.Group("/api/v1")
	{
		// 认证路由（无需认证）
		auth := v1.Group("/auth")
		{
			auth.POST("/login", a.authHandler.Login)
			auth.POST("/register", a.authHandler.Register)
			auth.POST("/refresh", a.authHandler.RefreshToken)
			auth.POST("/logout", a.authHandler.Logout)
		}

		// 用户个人资料路由（需要认证）
		userProfile := v1.Group("/users")
		userProfile.Use(middleware.AuthMiddleware(a.authService))
		{
			userProfile.GET("/profile", a.authHandler.GetProfile)
			userProfile.PUT("/profile", a.authHandler.UpdateProfile)
			userProfile.PUT("/password", a.authHandler.ChangePassword)
		}

		// 管理员路由组
		admin := v1.Group("/admin")
		admin.Use(middleware.AuthMiddleware(a.authService))
		admin.Use(middleware.RequireSystemPermission(a.permissionService, "admin"))
		{
			// 用户管理路由
			users := admin.Group("/users")
			{
				users.GET("", a.userHandler.GetAllUsers)
				users.POST("", a.userHandler.CreateUser)
				users.GET("/:id", a.userHandler.GetUserByID)
				users.PUT("/:id", a.userHandler.UpdateUser)
				users.DELETE("/:id", a.userHandler.DeleteUser)
				users.PUT("/:id/roles", a.userHandler.AssignRoles)
				users.GET("/:id/roles", a.userHandler.GetUserRoles)

				// 批量操作API
				users.PUT("/batch-status", a.userHandler.BatchUpdateStatus)
				users.DELETE("/batch", a.userHandler.BatchDeleteUsers)
				users.POST("/batch-reset-password", a.userHandler.BatchResetPassword)
				users.POST("/:id/reset-password", a.userHandler.ResetPassword)
				users.POST("/import", a.userHandler.ImportUsers)
			}

			// 角色管理路由
			roles := admin.Group("/roles")
			{
				roles.GET("", a.roleHandler.GetAllRoles)
				roles.POST("", a.roleHandler.CreateRole)
				roles.GET("/:id", a.roleHandler.GetRoleByID)
				roles.PUT("/:id", a.roleHandler.UpdateRole)
				roles.DELETE("/:id", a.roleHandler.DeleteRole)
				roles.POST("/:id/permissions", a.roleHandler.AssignPermissions)
				roles.PUT("/:id/permissions", a.roleHandler.UpdateRolePermissions)
				roles.GET("/:id/permissions", a.roleHandler.GetRolePermissions)

				// 批量操作和导入
				roles.POST("/import", a.roleHandler.ImportRoles)
				roles.PUT("/batch-status", a.roleHandler.BatchUpdateRoleStatus)
				roles.DELETE("/batch", a.roleHandler.BatchDeleteRoles)
			}
		}

		// 权限路由
		permissions := v1.Group("/permissions")
		permissions.Use(middleware.AuthMiddleware(a.authService))
		{
			permissions.POST("/check", a.permissionHandler.CheckPermission)
			permissions.GET("/user/:user_id", a.permissionHandler.GetUserPermissions)
			// 获取所有权限需要管理员权限
			permissions.GET("", middleware.RequireSystemPermission(a.permissionService, "manage"), a.permissionHandler.GetAllPermissions)
			// 获取权限树结构 - 允许所有认证用户访问（用于前端权限管理界面）
			permissions.GET("/tree", a.permissionHandler.GetPermissionTree)
			// 权限管理API（需要管理员权限）
			permissions.POST("", middleware.RequireSystemPermission(a.permissionService, "manage"), a.permissionHandler.CreatePermission)
			permissions.PUT("/:id", middleware.RequireSystemPermission(a.permissionService, "manage"), a.permissionHandler.UpdatePermission)
			permissions.DELETE("/:id", middleware.RequireSystemPermission(a.permissionService, "manage"), a.permissionHandler.DeletePermission)
			// 初始化精细化权限数据
			permissions.POST("/initialize", middleware.RequireSystemPermission(a.permissionService, "manage"), a.permissionHandler.InitializePermissions)
			// 初始化简化权限数据
			permissions.POST("/initialize-simplified", middleware.RequireSystemPermission(a.permissionService, "manage"), a.permissionHandler.InitializeSimplifiedPermissions)
		}

		// 记录路由
		records := v1.Group("/records")
		records.Use(middleware.AuthMiddleware(a.authService))
		records.Use(middleware.AuditMiddleware())
		records.Use(middleware.RecordScopeMiddleware(a.permissionService))
		{
			records.GET("", a.recordHandler.GetRecords)
			records.POST("", a.recordHandler.CreateRecord)
			records.GET("/:id", a.recordHandler.GetRecordByID)
			records.PUT("/:id", a.recordHandler.UpdateRecord)
			records.DELETE("/:id", a.recordHandler.DeleteRecord)
			records.POST("/batch", a.recordHandler.BatchCreateRecords)
			records.PUT("/batch-status", a.recordHandler.BatchUpdateRecordStatus)
			records.DELETE("/batch", a.recordHandler.BatchDeleteRecords)
			records.POST("/import", a.recordHandler.ImportRecords)
			records.GET("/type/:type", a.recordHandler.GetRecordsByType)
		}

		// 工单路由
		tickets := v1.Group("/tickets")
		tickets.Use(middleware.AuthMiddleware(a.authService))
		tickets.Use(middleware.AuditMiddleware())
		{
			tickets.GET("", a.ticketHandler.GetTickets)
			tickets.POST("", a.ticketHandler.CreateTicket)
			tickets.GET("/statistics", a.ticketHandler.GetTicketStatistics)
			tickets.GET("/:id", a.ticketHandler.GetTicket)
			tickets.PUT("/:id", a.ticketHandler.UpdateTicket)
			tickets.DELETE("/:id", a.ticketHandler.DeleteTicket)
			
			// 工单导入导出
			tickets.GET("/export", a.ticketHandler.ExportTickets)
			tickets.POST("/import", a.ticketHandler.ImportTickets)
			
			// 工单流程管理
			tickets.POST("/:id/assign", a.ticketHandler.AssignTicket)
			tickets.PUT("/:id/status", a.ticketHandler.UpdateTicketStatus)
			tickets.POST("/:id/accept", a.ticketHandler.AcceptTicket)
			tickets.POST("/:id/reject", a.ticketHandler.RejectTicket)
			tickets.POST("/:id/reopen", a.ticketHandler.ReopenTicket)
			tickets.POST("/:id/resubmit", a.ticketHandler.ResubmitTicket)
			
			// 工单评论
			tickets.GET("/:id/comments", a.ticketHandler.GetTicketComments)
			tickets.POST("/:id/comments", a.ticketHandler.AddTicketComment)
			
			// 工单历史
			tickets.GET("/:id/history", a.ticketHandler.GetTicketHistory)
			
			// 工单附件
			tickets.POST("/:id/attachments", a.ticketHandler.UploadTicketAttachment)
			tickets.DELETE("/:id/attachments/:attachment_id", a.ticketHandler.DeleteTicketAttachment)
			
			// 工单类型
			tickets.GET("/categories", a.ticketHandler.GetTicketCategories)
			
			// 自动分配规则
			tickets.GET("/assignment-rules", a.ticketHandler.GetAssignmentRules)
			tickets.PUT("/assignment-rules", a.ticketHandler.UpdateAssignmentRules)
		}

		// 记录类型路由
		recordTypes := v1.Group("/record-types")
		recordTypes.Use(middleware.AuthMiddleware(a.authService))
		recordTypes.Use(middleware.RequireSystemPermission(a.permissionService, "admin"))
		{
			recordTypes.GET("", a.recordTypeHandler.GetAllRecordTypes)
			recordTypes.POST("", a.recordTypeHandler.CreateRecordType)
			recordTypes.GET("/:id", a.recordTypeHandler.GetRecordTypeByID)
			recordTypes.PUT("/:id", a.recordTypeHandler.UpdateRecordType)
			recordTypes.DELETE("/:id", a.recordTypeHandler.DeleteRecordType)

			// 批量操作和导入
			recordTypes.POST("/import", a.recordTypeHandler.ImportRecordTypes)
			recordTypes.PUT("/batch-status", a.recordTypeHandler.BatchUpdateRecordTypeStatus)
			recordTypes.DELETE("/batch", a.recordTypeHandler.BatchDeleteRecordTypes)
		}

		// 审计路由
		audit := v1.Group("/audit")
		audit.Use(middleware.AuthMiddleware(a.authService))
		audit.Use(middleware.RequireSystemPermission(a.permissionService, "admin"))
		{
			audit.GET("/logs", a.auditHandler.GetAuditLogs)
			audit.GET("/resources/:resource_type/:resource_id", a.auditHandler.GetResourceAuditLogs)
			audit.GET("/users/:user_id", a.auditHandler.GetUserAuditLogs)
			audit.GET("/statistics", a.auditHandler.GetAuditStatistics)
			audit.POST("/cleanup", a.auditHandler.CleanupOldAuditLogs)
		}

		// 文件路由
		files := v1.Group("/files")
		files.Use(middleware.AuthMiddleware(a.authService))
		files.Use(middleware.AuditMiddleware())
		files.Use(middleware.FilePermissionMiddleware(a.permissionService))
		{
			files.POST("/upload", a.fileHandler.UploadFile)
			files.GET("", a.fileHandler.GetFiles)
			files.GET("/:id", a.fileHandler.DownloadFile)
			files.GET("/:id/info", a.fileHandler.GetFileByID)
			files.DELETE("/:id", a.fileHandler.DeleteFile)
			files.POST("/ocr", a.ocrHandler.RecognizeText)
			files.GET("/ocr/languages", a.ocrHandler.GetSupportedLanguages)
		}

		// 导出路由
		export := v1.Group("/export")
		export.Use(middleware.AuthMiddleware(a.authService))
		export.Use(middleware.AuditMiddleware())
		export.Use(middleware.ExportPermissionMiddleware(a.permissionService))
		{
			// 导出模板管理
			export.GET("/templates", middleware.RequireSystemPermission(a.permissionService, "manage"), a.exportHandler.GetTemplates)
			export.POST("/templates", a.exportHandler.CreateTemplate)
			export.GET("/templates/:id", a.exportHandler.GetTemplateByID)
			export.PUT("/templates/:id", a.exportHandler.UpdateTemplate)
			export.DELETE("/templates/:id", a.exportHandler.DeleteTemplate)

			// 数据导出
			export.POST("/records", a.exportHandler.ExportRecords)

			// 导出任务管理
			export.GET("/tasks", a.exportHandler.GetTasks)
			export.GET("/tasks/:id", a.exportHandler.GetTaskByID)

			// 导出文件管理
			export.GET("/files", a.exportHandler.GetFiles)
			export.GET("/files/:id/download", a.exportHandler.DownloadFile)
		}

		// 通知路由
		notifications := v1.Group("/notifications")
		notifications.Use(middleware.AuthMiddleware(a.authService))
		notifications.Use(middleware.AuditMiddleware())
		{
			// 通知模板管理
			notifications.GET("/templates", a.notificationHandler.GetTemplates)
			notifications.POST("/templates", a.notificationHandler.CreateTemplate)
			notifications.GET("/templates/:id", a.notificationHandler.GetTemplate)
			notifications.PUT("/templates/:id", a.notificationHandler.UpdateTemplate)
			notifications.DELETE("/templates/:id", a.notificationHandler.DeleteTemplate)

			// 通知发送
			notifications.POST("/send", a.notificationHandler.SendNotification)

			// 通知历史
			notifications.GET("/history", a.notificationHandler.GetNotifications)

			// 通知渠道管理
			notifications.GET("/channels", a.notificationHandler.GetNotificationChannels)
			notifications.POST("/channels", a.notificationHandler.CreateNotificationChannel)
		}

		// 告警路由
		alerts := v1.Group("/alerts")
		alerts.Use(middleware.AuthMiddleware(a.authService))
		alerts.Use(middleware.AuditMiddleware())
		{
			// Zabbix告警集成
			alerts.POST("/zabbix", a.notificationHandler.ProcessZabbixAlert)

			// 告警规则管理
			alerts.GET("/rules", a.notificationHandler.GetAlertRules)
			alerts.POST("/rules", a.notificationHandler.CreateAlertRule)

			// 告警事件查询
			alerts.GET("/events", a.notificationHandler.GetAlertEvents)
		}

		// AI路由
		ai := v1.Group("/ai")
		ai.Use(middleware.AuthMiddleware(a.authService))
		ai.Use(middleware.AuditMiddleware())
		{
			// AI配置管理
			ai.GET("/config", middleware.RequirePermission(a.permissionService, "ai:config"), a.aiHandler.GetConfigs)
			ai.POST("/config", a.aiHandler.CreateConfig)
			ai.GET("/config/:id", a.aiHandler.GetConfig)
			ai.PUT("/config/:id", a.aiHandler.UpdateConfig)
			ai.DELETE("/config/:id", a.aiHandler.DeleteConfig)

			// AI功能API
			ai.POST("/optimize-record", a.aiHandler.OptimizeRecord)
			ai.POST("/speech-to-text", a.aiHandler.SpeechToText)
			ai.POST("/chat", a.aiHandler.Chat)

			// AI任务和会话管理
			ai.GET("/tasks", a.aiHandler.GetTasks)
			ai.GET("/sessions", a.aiHandler.GetChatSessions)
			ai.GET("/stats", a.aiHandler.GetUsageStats)

			// 健康检查
			ai.POST("/health/:id", a.aiHandler.HealthCheck)
		}

		// 系统配置路由
		config := v1.Group("/config")
		config.Use(middleware.AuthMiddleware(a.authService))
		config.Use(middleware.AuditMiddleware())
		{
			// 系统配置管理（需要管理员权限）
			config.GET("", middleware.RequireSystemPermission(a.permissionService, "admin"), a.systemHandler.GetConfigs)
			config.POST("", middleware.RequireSystemPermission(a.permissionService, "admin"), a.systemHandler.CreateConfig)
			config.GET("/:category/:key", a.systemHandler.GetConfigByKey)
			config.PUT("/:category/:key", middleware.RequireSystemPermission(a.permissionService, "admin"), a.systemHandler.UpdateConfig)
			config.DELETE("/:category/:key", middleware.RequireSystemPermission(a.permissionService, "admin"), a.systemHandler.DeleteConfig)
		}

		// 公共公告路由（无需认证）
		v1.GET("/announcements/public", a.systemHandler.GetPublicAnnouncements)

		// 公告路由（需要认证）
		announcements := v1.Group("/announcements")
		announcements.Use(middleware.AuthMiddleware(a.authService))
		announcements.Use(middleware.AuditMiddleware())
		{
			announcements.GET("", middleware.RequirePermission(a.permissionService, "system:announcements_read"), a.systemHandler.GetAnnouncements)
			announcements.POST("", middleware.RequireSystemPermission(a.permissionService, "admin"), a.systemHandler.CreateAnnouncement)
			announcements.GET("/:id", a.systemHandler.GetAnnouncementByID)
			announcements.PUT("/:id", a.systemHandler.UpdateAnnouncement)
			announcements.DELETE("/:id", a.systemHandler.DeleteAnnouncement)
			announcements.POST("/:id/view", a.systemHandler.MarkAnnouncementAsViewed)
		}

		// 系统监控路由
		system := v1.Group("/system")
		system.Use(middleware.AuthMiddleware(a.authService))
		{
			// 健康检查（需要管理员权限）
			system.GET("/health", middleware.RequireSystemPermission(a.permissionService, "manage"), a.systemHandler.GetSystemHealth)

			// 获取用户列表（用于Token创建，所有登录用户可访问）
			system.GET("/users", a.systemHandler.GetUsersForToken)

			// 系统统计信息（需要管理员权限）
			system.GET("/stats", middleware.RequireSystemPermission(a.permissionService, "manage"), a.systemHandler.GetSystemStats)

			// 系统指标（需要管理员权限）
			system.GET("/metrics", middleware.RequireSystemPermission(a.permissionService, "manage"), a.systemHandler.GetSystemMetrics)
		}

		// 日志路由
		logs := v1.Group("/logs")
		logs.Use(middleware.AuthMiddleware(a.authService))
		logs.Use(middleware.RequireSystemPermission(a.permissionService, "admin"))
		{
			logs.GET("", a.systemHandler.GetSystemLogs)
			logs.POST("/cleanup", a.systemHandler.CleanupOldLogs)
			logs.DELETE("/:id", a.systemHandler.DeleteSingleLog)
			logs.POST("/batch-delete", a.systemHandler.BatchDeleteLogs)
		}
	}
}

// Run 启动应用
func (a *App) Run(addr string) error {
	a.logger.Infof("Starting server on %s", addr)
	return a.router.Run(addr)
}

// healthCheck 健康检查
func (a *App) healthCheck(c *gin.Context) {
	// 检查数据库连接
	if err := database.HealthCheck(); err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	// 获取数据库信息
	dbInfo := a.getDatabaseInfo()

	middleware.Success(c, gin.H{
		"status":    "healthy",
		"timestamp": gin.H{},
		"version":   "1.0.0",
		"database":  dbInfo,
	})
}

// getDatabaseInfo 获取数据库信息
func (a *App) getDatabaseInfo() gin.H {
	driver := a.config.Database.GetDriver()
	dsn := a.config.Database.GetDSN()

	// 隐藏敏感信息
	safeDSN := dsn
	if driver == "mysql" || driver == "postgres" {
		// 对于MySQL和PostgreSQL，隐藏密码
		safeDSN = "***hidden***"
	}

	return gin.H{
		"driver": driver,
		"dsn":    safeDSN,
	}
}

// readinessCheck 就绪检查
func (a *App) readinessCheck(c *gin.Context) {
	// 检查数据库连接
	if err := database.HealthCheck(); err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, gin.H{
		"status": "ready",
	})
}

// placeholder 占位符处理函数
func (a *App) placeholder(c *gin.Context) {
	middleware.Success(c, gin.H{
		"message": "This endpoint is not implemented yet",
		"path":    c.Request.URL.Path,
		"method":  c.Request.Method,
	})
}
