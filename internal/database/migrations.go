package database

import (
	"fmt"
	"time"

	"info-management-system/internal/models"
	"info-management-system/internal/services"

	"gorm.io/gorm"
)

// runCustomMigrations 执行自定义迁移逻辑
func runCustomMigrations(db *gorm.DB) error {
	// 这里可以添加自定义的数据库迁移逻辑
	// 例如：数据转换、索引创建、约束添加等
	
	// 创建必要的索引
	if err := createIndexes(db); err != nil {
		return fmt.Errorf("failed to create indexes: %w", err)
	}
	
	return nil
}

// createIndexes 创建数据库索引
func createIndexes(db *gorm.DB) error {
	// 为用户表创建索引
	if err := db.Exec("CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)").Error; err != nil {
		return fmt.Errorf("failed to create index on users.username: %w", err)
	}
	
	if err := db.Exec("CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)").Error; err != nil {
		return fmt.Errorf("failed to create index on users.email: %w", err)
	}
	
	// 为记录表创建索引
	if err := db.Exec("CREATE INDEX IF NOT EXISTS idx_records_type ON records(type)").Error; err != nil {
		return fmt.Errorf("failed to create index on records.type: %w", err)
	}
	
	if err := db.Exec("CREATE INDEX IF NOT EXISTS idx_records_created_by ON records(created_by)").Error; err != nil {
		return fmt.Errorf("failed to create index on records.created_by: %w", err)
	}
	
	// 为审计日志创建索引
	if err := db.Exec("CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id)").Error; err != nil {
		return fmt.Errorf("failed to create index on audit_logs.user_id: %w", err)
	}
	
	if err := db.Exec("CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at)").Error; err != nil {
		return fmt.Errorf("failed to create index on audit_logs.created_at: %w", err)
	}
	
	// 为工单表创建索引
	if err := db.Exec("CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status)").Error; err != nil {
		return fmt.Errorf("failed to create index on tickets.status: %w", err)
	}
	
	if err := db.Exec("CREATE INDEX IF NOT EXISTS idx_tickets_type ON tickets(type)").Error; err != nil {
		return fmt.Errorf("failed to create index on tickets.type: %w", err)
	}
	
	if err := db.Exec("CREATE INDEX IF NOT EXISTS idx_tickets_priority ON tickets(priority)").Error; err != nil {
		return fmt.Errorf("failed to create index on tickets.priority: %w", err)
	}
	
	if err := db.Exec("CREATE INDEX IF NOT EXISTS idx_tickets_creator_id ON tickets(creator_id)").Error; err != nil {
		return fmt.Errorf("failed to create index on tickets.creator_id: %w", err)
	}
	
	if err := db.Exec("CREATE INDEX IF NOT EXISTS idx_tickets_assignee_id ON tickets(assignee_id)").Error; err != nil {
		return fmt.Errorf("failed to create index on tickets.assignee_id: %w", err)
	}
	
	if err := db.Exec("CREATE INDEX IF NOT EXISTS idx_ticket_comments_ticket_id ON ticket_comments(ticket_id)").Error; err != nil {
		return fmt.Errorf("failed to create index on ticket_comments.ticket_id: %w", err)
	}
	
	if err := db.Exec("CREATE INDEX IF NOT EXISTS idx_ticket_history_ticket_id ON ticket_histories(ticket_id)").Error; err != nil {
		return fmt.Errorf("failed to create index on ticket_histories.ticket_id: %w", err)
	}
	
	return nil
}

// Migrate 执行数据库迁移
func Migrate(db *gorm.DB) error {
	// 先自动迁移所有模型（创建表）
	err := db.AutoMigrate(
		&models.User{},
		&models.Role{},
		&models.Permission{},
		&models.RolePermission{},
		&models.UserRole{},
		&models.UserPermission{},
		&models.RecordType{},
		&models.Record{},
		&models.AuditLog{},
		&models.File{},
		&models.ExportTemplate{},
		&models.ExportTask{},
		&models.ExportFile{},
		&models.NotificationTemplate{},
		&models.Notification{},
		&models.NotificationChannel{},
		&models.AlertRule{},
		&models.AlertEvent{},
		&models.NotificationQueue{},
		&models.Ticket{},
		&models.TicketComment{},
		&models.TicketAttachment{},
		&models.TicketHistory{},
		&models.AIConfig{},
		&models.AIChatSession{},
		&models.AIChatMessage{},
		&models.AITask{},
		&models.AIUsageStats{},
		&models.AIHealthCheck{},
		&models.SystemConfig{},
		&models.SystemConfigHistory{},
		&models.Announcement{},
		&models.AnnouncementView{},
		&models.SystemHealth{},
		&models.SystemLog{},
		&models.SystemMetrics{},
		&models.SystemMaintenance{},
		&models.APIToken{},
		&models.APITokenUsageLog{},
	)

	if err != nil {
		return fmt.Errorf("failed to migrate database: %w", err)
	}

	// 执行自定义迁移（创建索引等）
	if err := runCustomMigrations(db); err != nil {
		return fmt.Errorf("failed to run custom migrations: %w", err)
	}

	// 创建初始数据
	if err := createInitialData(db); err != nil {
		return fmt.Errorf("failed to create initial data: %w", err)
	}

	return nil
}

// createInitialData 创建初始数据
func createInitialData(db *gorm.DB) error {
	// 创建默认角色
	if err := createDefaultRoles(db); err != nil {
		return err
	}

	// 创建默认权限
	if err := createDefaultPermissions(db); err != nil {
		return err
	}

	// 创建管理员用户
	if err := createAdminUser(db); err != nil {
		return err
	}

	// 为管理员角色分配所有权限
	if err := AssignAdminPermissions(db); err != nil {
		return err
	}

	// 创建默认公告
	if err := createDefaultAnnouncements(db); err != nil {
		return err
	}

	// 创建默认系统配置
	if err := createDefaultSystemConfigs(db); err != nil {
		return err
	}

	return nil
}

// createDefaultRoles 创建默认角色
func createDefaultRoles(db *gorm.DB) error {
	roles := []models.Role{
		{Name: "admin", DisplayName: "系统管理员", Description: "系统管理员", Status: "active", IsSystem: true},
		{Name: "user", DisplayName: "普通用户", Description: "普通用户", Status: "active", IsSystem: true},
		{Name: "viewer", DisplayName: "只读用户", Description: "只读用户", Status: "active", IsSystem: true},
	}

	for _, role := range roles {
		var existingRole models.Role
		if err := db.Where("name = ?", role.Name).First(&existingRole).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				if err := db.Create(&role).Error; err != nil {
					return fmt.Errorf("failed to create role %s: %w", role.Name, err)
				}
			} else {
				return fmt.Errorf("failed to check role %s: %w", role.Name, err)
			}
		} else {
			// 更新现有角色的DisplayName和Status
			if existingRole.DisplayName == "" {
				existingRole.DisplayName = role.DisplayName
				existingRole.Status = role.Status
				if err := db.Save(&existingRole).Error; err != nil {
					return fmt.Errorf("failed to update role %s: %w", role.Name, err)
				}
			}
		}
	}

	return nil
}

// createDefaultPermissions 创建默认权限
func createDefaultPermissions(db *gorm.DB) error {
	// 检查是否已有权限数据
	var count int64
	if err := db.Model(&models.Permission{}).Count(&count).Error; err != nil {
		return fmt.Errorf("failed to count permissions: %w", err)
	}

	// 如果已有权限数据，跳过创建
	if count > 0 {
		return nil
	}

	// 使用统一的权限数据源
	permissions := services.GetAllDetailedPermissions()
	
	// 批量创建权限
	for _, perm := range permissions {
		if err := db.Create(&perm).Error; err != nil {
			return fmt.Errorf("创建权限失败 (ID: %d, Name: %s): %v", perm.ID, perm.Name, err)
		}
	}

	return nil
	
	// 以下代码已禁用，权限由权限初始化过程管理
	/*
	// 创建层次化权限结构
	permissions := []models.Permission{
		// 系统管理 - 根权限
		{Name: "system", DisplayName: "系统管理", Description: "系统管理相关权限", Resource: "system", Action: "manage", Scope: "all"},
		{Name: "system:admin", DisplayName: "系统管理员", Description: "系统管理员权限", Resource: "system", Action: "admin", Scope: "all"},
		{Name: "system:config", DisplayName: "系统配置", Description: "系统配置管理权限", Resource: "system", Action: "config", Scope: "all"},

		// 用户管理 - 根权限
		{Name: "users", DisplayName: "用户管理", Description: "用户管理相关权限", Resource: "users", Action: "manage", Scope: "all"},
		{Name: "users:read", DisplayName: "查看用户", Description: "查看用户列表和详情", Resource: "users", Action: "read", Scope: "all"},
		{Name: "users:write", DisplayName: "编辑用户", Description: "创建和编辑用户", Resource: "users", Action: "write", Scope: "all"},
		{Name: "users:delete", DisplayName: "删除用户", Description: "删除用户账号", Resource: "users", Action: "delete", Scope: "all"},

		// 角色管理 - 根权限
		{Name: "roles", DisplayName: "角色管理", Description: "角色管理相关权限", Resource: "roles", Action: "manage", Scope: "all"},
		{Name: "roles:read", DisplayName: "查看角色", Description: "查看角色列表和详情", Resource: "roles", Action: "read", Scope: "all"},
		{Name: "roles:write", DisplayName: "编辑角色", Description: "创建和编辑角色", Resource: "roles", Action: "write", Scope: "all"},
		{Name: "roles:delete", DisplayName: "删除角色", Description: "删除角色", Resource: "roles", Action: "delete", Scope: "all"},
		{Name: "roles:assign", DisplayName: "分配权限", Description: "为角色分配权限", Resource: "roles", Action: "assign", Scope: "all"},

		// 记录管理 - 根权限
		{Name: "records", DisplayName: "记录管理", Description: "记录管理相关权限", Resource: "records", Action: "manage", Scope: "all"},
		{Name: "records:read", DisplayName: "查看记录", Description: "查看记录列表和详情", Resource: "records", Action: "read", Scope: "all"},
		{Name: "records:write", DisplayName: "编辑记录", Description: "创建和编辑记录", Resource: "records", Action: "write", Scope: "all"},
		{Name: "records:delete", DisplayName: "删除记录", Description: "删除记录数据", Resource: "records", Action: "delete", Scope: "all"},

		// 文件管理 - 根权限
		{Name: "files", DisplayName: "文件管理", Description: "文件管理相关权限", Resource: "files", Action: "manage", Scope: "all"},
		{Name: "files:read", DisplayName: "查看文件", Description: "查看和下载文件", Resource: "files", Action: "read", Scope: "all"},
		{Name: "files:upload", DisplayName: "上传文件", Description: "上传文件", Resource: "files", Action: "upload", Scope: "all"},
		{Name: "files:write", DisplayName: "编辑文件", Description: "编辑文件信息", Resource: "files", Action: "write", Scope: "all"},
		{Name: "files:delete", DisplayName: "删除文件", Description: "删除文件数据", Resource: "files", Action: "delete", Scope: "all"},
		{Name: "files:share", DisplayName: "分享文件", Description: "分享文件给其他用户", Resource: "files", Action: "share", Scope: "all"},

		// 导出功能 - 根权限
		{Name: "export", DisplayName: "数据导出", Description: "数据导出相关权限", Resource: "export", Action: "manage", Scope: "all"},
		{Name: "export:records", DisplayName: "导出记录", Description: "导出记录数据", Resource: "export", Action: "records", Scope: "all"},
		{Name: "export:users", DisplayName: "导出用户", Description: "导出用户数据", Resource: "export", Action: "users", Scope: "all"},

		// 通知功能 - 根权限
		{Name: "notifications", DisplayName: "通知管理", Description: "通知管理相关权限", Resource: "notifications", Action: "manage", Scope: "all"},
		{Name: "notifications:send", DisplayName: "发送通知", Description: "发送通知消息", Resource: "notifications", Action: "send", Scope: "all"},
		{Name: "notifications:template", DisplayName: "通知模板", Description: "管理通知模板", Resource: "notifications", Action: "template", Scope: "all"},

		// AI功能 - 根权限
		{Name: "ai", DisplayName: "AI功能", Description: "AI相关功能权限", Resource: "ai", Action: "manage", Scope: "all"},
		{Name: "ai:chat", DisplayName: "AI聊天", Description: "使用AI聊天功能", Resource: "ai", Action: "chat", Scope: "all"},
		{Name: "ai:ocr", DisplayName: "OCR识别", Description: "使用OCR文字识别功能", Resource: "ai", Action: "ocr", Scope: "all"},
		{Name: "ai:speech", DisplayName: "语音识别", Description: "使用语音识别功能", Resource: "ai", Action: "speech", Scope: "all"},
		{Name: "ai:config", DisplayName: "AI配置", Description: "管理AI配置", Resource: "ai", Action: "config", Scope: "all"},

		// 审计功能 - 根权限
		{Name: "audit", DisplayName: "审计管理", Description: "审计管理相关权限", Resource: "audit", Action: "manage", Scope: "all"},
		{Name: "audit:read", DisplayName: "查看审计", Description: "查看审计日志", Resource: "audit", Action: "read", Scope: "all"},
		{Name: "audit:cleanup", DisplayName: "清理审计", Description: "清理旧的审计日志", Resource: "audit", Action: "cleanup", Scope: "all"},
	}
	*/ 

	// 以下代码也已禁用，权限由权限初始化过程管理
	/*
	// 首先创建所有权限
	for _, permission := range permissions {
		var existingPermission models.Permission
		if err := db.Where("name = ?", permission.Name).First(&existingPermission).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				if err := db.Create(&permission).Error; err != nil {
					return fmt.Errorf("failed to create permission %s: %w", permission.Name, err)
				}
			} else {
				return fmt.Errorf("failed to check permission %s: %w", permission.Name, err)
			}
		} else {
			// 更新现有权限的名称和显示名称
			if existingPermission.Name == "" {
				existingPermission.Name = permission.Name
				existingPermission.DisplayName = permission.DisplayName
				existingPermission.Description = permission.Description
				if err := db.Save(&existingPermission).Error; err != nil {
					return fmt.Errorf("failed to update permission %s: %w", permission.Name, err)
				}
			}
		}
	}

	// 设置父子关系
	parentChildMap := map[string]string{
		"system:admin":           "system",
		"system:config":          "system",
		"users:read":             "users",
		"users:write":            "users",
		"users:delete":           "users",
		"roles:read":             "roles",
		"roles:write":            "roles",
		"roles:delete":           "roles",
		"roles:assign":           "roles",
		"records:read":           "records",
		"records:write":          "records",
		"records:delete":         "records",
		"files:read":             "files",
		"files:upload":           "files",
		"files:write":            "files",
		"files:delete":           "files",
		"files:share":            "files",
		"export:records":         "export",
		"export:users":           "export",
		"notifications:send":     "notifications",
		"notifications:template": "notifications",
		"ai:chat":                "ai",
		"ai:ocr":                 "ai",
		"ai:speech":              "ai",
		"ai:config":              "ai",
		"audit:read":             "audit",
		"audit:cleanup":          "audit",
	}

	for childName, parentName := range parentChildMap {
		var childPermission, parentPermission models.Permission

		if err := db.Where("name = ?", childName).First(&childPermission).Error; err != nil {
			continue // 跳过不存在的权限
		}

		if err := db.Where("name = ?", parentName).First(&parentPermission).Error; err != nil {
			continue // 跳过不存在的父权限
		}

		if childPermission.ParentID == nil {
			childPermission.ParentID = &parentPermission.ID
			if err := db.Save(&childPermission).Error; err != nil {
				return fmt.Errorf("failed to set parent for permission %s: %w", childName, err)
			}
		}
	}
	*/

	return nil
}

// createAdminUser 创建管理员用户
func createAdminUser(db *gorm.DB) error {
	var adminUser models.User
	
	// 检查admin用户是否已存在
	err := db.Where("username = ? OR email = ?", "admin", "admin@example.com").First(&adminUser).Error
	if err != nil && err != gorm.ErrRecordNotFound {
		return fmt.Errorf("failed to check admin user: %w", err)
	}
	
	// 如果用户不存在，创建它
	if err == gorm.ErrRecordNotFound {
		hashedPassword, err := models.HashPassword("admin123")
		if err != nil {
			return fmt.Errorf("failed to hash admin password: %w", err)
		}

		adminUser = models.User{
			Username:     "admin",
			Email:        "admin@example.com",
			DisplayName:  "系统管理员",
			PasswordHash: hashedPassword,
			Status:       "active",
			IsActive:     true,
		}

		if err := db.Create(&adminUser).Error; err != nil {
			return fmt.Errorf("failed to create admin user: %w", err)
		}
	}

	// 确保admin用户有admin角色
	var adminRole models.Role
	if err := db.Where("name = ?", "admin").First(&adminRole).Error; err != nil {
		return fmt.Errorf("failed to find admin role: %w", err)
	}

	// 检查用户是否已有admin角色
	var userRole models.UserRole
	err = db.Where("user_id = ? AND role_id = ?", adminUser.ID, adminRole.ID).First(&userRole).Error
	if err != nil && err != gorm.ErrRecordNotFound {
		return fmt.Errorf("failed to check user role: %w", err)
	}
	
	// 如果没有角色关联，创建它
	if err == gorm.ErrRecordNotFound {
		userRole = models.UserRole{
			UserID: adminUser.ID,
			RoleID: adminRole.ID,
		}

		if err := db.Create(&userRole).Error; err != nil {
			return fmt.Errorf("failed to assign admin role: %w", err)
		}
	}

	return nil
}

// createDefaultAnnouncements 创建默认公告
func createDefaultAnnouncements(db *gorm.DB) error {
	// 检查是否已有公告
	var count int64
	if err := db.Model(&models.Announcement{}).Count(&count).Error; err != nil {
		return fmt.Errorf("failed to count announcements: %w", err)
	}

	// 如果已有公告，跳过创建
	if count > 0 {
		return nil
	}

	// 创建时间变量
	now := time.Now()
	oneYearLater := now.AddDate(1, 0, 0)
	sixMonthsLater := now.AddDate(0, 6, 0)

	// 创建默认公告
	announcements := []models.Announcement{
		{
			Title:       "欢迎使用信息管理系统",
			Content:     "欢迎使用信息管理系统！本系统提供完整的信息管理功能，包括记录管理、文件处理、数据导出等。如有任何问题，请联系系统管理员。",
			Type:        "info",
			Priority:    1,
			IsActive:    true,
			IsSticky:    true,
			StartTime:   &now,
			EndTime:     &oneYearLater, // 一年后过期
			CreatedBy:   1, // 管理员用户ID
		},
		{
			Title:       "系统功能介绍",
			Content:     "系统主要功能包括：\n1. 记录管理 - 创建、编辑、查询各类记录\n2. 文件管理 - 上传、下载、OCR识别\n3. 数据导出 - 支持Excel、PDF、CSV等格式\n4. 用户管理 - 用户和角色权限管理\n5. 系统配置 - 灵活的系统参数配置",
			Type:        "info",
			Priority:    2,
			IsActive:    true,
			IsSticky:    false,
			StartTime:   &now,
			EndTime:     &sixMonthsLater, // 六个月后过期
			CreatedBy:   1,
		},
	}

	for _, announcement := range announcements {
		if err := db.Create(&announcement).Error; err != nil {
			return fmt.Errorf("failed to create announcement '%s': %w", announcement.Title, err)
		}
	}

	return nil
}

// createDefaultSystemConfigs 创建默认系统配置
func createDefaultSystemConfigs(db *gorm.DB) error {
	// 检查是否已有配置
	var count int64
	if err := db.Model(&models.SystemConfig{}).Count(&count).Error; err != nil {
		return fmt.Errorf("failed to count system configs: %w", err)
	}

	// 如果已有配置，跳过创建
	if count > 0 {
		return nil
	}

	// 默认系统配置
	configs := []models.SystemConfig{
		// 系统基础配置
		{
			Category:     "system",
			Key:          "app_name",
			Value:        "信息管理系统",
			DefaultValue: "信息管理系统",
			Description:  "应用程序名称",
			DataType:     "string",
			IsPublic:     true,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1, // 管理员用户ID
		},
		{
			Category:     "system",
			Key:          "app_version",
			Value:        "1.0.0",
			DefaultValue: "1.0.0",
			Description:  "应用程序版本号",
			DataType:     "string",
			IsPublic:     true,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},
		{
			Category:     "system",
			Key:          "maintenance_mode",
			Value:        "false",
			DefaultValue: "false",
			Description:  "系统维护模式开关",
			DataType:     "bool",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},
		{
			Category:     "system",
			Key:          "max_upload_size",
			Value:        "10485760",
			DefaultValue: "10485760",
			Description:  "最大文件上传大小（字节），默认10MB",
			DataType:     "int",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},

		// 数据库配置
		{
			Category:     "database",
			Key:          "connection_pool_size",
			Value:        "10",
			DefaultValue: "10",
			Description:  "数据库连接池大小",
			DataType:     "int",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},
		{
			Category:     "database",
			Key:          "query_timeout",
			Value:        "30",
			DefaultValue: "30",
			Description:  "数据库查询超时时间（秒）",
			DataType:     "int",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},
		{
			Category:     "database",
			Key:          "backup_enabled",
			Value:        "true",
			DefaultValue: "true",
			Description:  "是否启用数据库自动备份",
			DataType:     "bool",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},

		// 文件存储配置
		{
			Category:     "storage",
			Key:          "upload_path",
			Value:        "./uploads",
			DefaultValue: "./uploads",
			Description:  "文件上传存储路径",
			DataType:     "string",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},
		{
			Category:     "storage",
			Key:          "allowed_extensions",
			Value:        `["jpg","jpeg","png","gif","pdf","doc","docx","xls","xlsx","txt"]`,
			DefaultValue: `["jpg","jpeg","png","gif","pdf","doc","docx","xls","xlsx","txt"]`,
			Description:  "允许上传的文件扩展名",
			DataType:     "json",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},
		{
			Category:     "storage",
			Key:          "cleanup_enabled",
			Value:        "true",
			DefaultValue: "true",
			Description:  "是否启用临时文件自动清理",
			DataType:     "bool",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},

		// 缓存配置
		{
			Category:     "cache",
			Key:          "enabled",
			Value:        "true",
			DefaultValue: "true",
			Description:  "是否启用缓存",
			DataType:     "bool",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},
		{
			Category:     "cache",
			Key:          "ttl",
			Value:        "3600",
			DefaultValue: "3600",
			Description:  "缓存默认过期时间（秒）",
			DataType:     "int",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},

		// 安全配置
		{
			Category:     "security",
			Key:          "session_timeout",
			Value:        "7200",
			DefaultValue: "7200",
			Description:  "会话超时时间（秒），默认2小时",
			DataType:     "int",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},
		{
			Category:     "security",
			Key:          "password_min_length",
			Value:        "6",
			DefaultValue: "6",
			Description:  "密码最小长度",
			DataType:     "int",
			IsPublic:     true,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},
		{
			Category:     "security",
			Key:          "login_attempts_limit",
			Value:        "5",
			DefaultValue: "5",
			Description:  "登录失败次数限制",
			DataType:     "int",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},

		// 邮件配置
		{
			Category:     "email",
			Key:          "smtp_enabled",
			Value:        "false",
			DefaultValue: "false",
			Description:  "是否启用SMTP邮件发送",
			DataType:     "bool",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},
		{
			Category:     "email",
			Key:          "smtp_host",
			Value:        "smtp.example.com",
			DefaultValue: "smtp.example.com",
			Description:  "SMTP服务器地址",
			DataType:     "string",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},
		{
			Category:     "email",
			Key:          "smtp_port",
			Value:        "587",
			DefaultValue: "587",
			Description:  "SMTP服务器端口",
			DataType:     "int",
			IsPublic:     false,
			IsEditable:   true,
			Version:      1,
			UpdatedBy:    1,
		},
	}

	// 创建配置
	for _, config := range configs {
		if err := db.Create(&config).Error; err != nil {
			return fmt.Errorf("failed to create system config '%s.%s': %w", config.Category, config.Key, err)
		}
	}

	return nil
}



