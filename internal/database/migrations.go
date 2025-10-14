package database

import (
	"fmt"

	"info-management-system/internal/models"

	"gorm.io/gorm"
)

// Migrate 执行数据库迁移
func Migrate(db *gorm.DB) error {
	// 执行自定义迁移
	if err := runCustomMigrations(db); err != nil {
		return fmt.Errorf("failed to run custom migrations: %w", err)
	}

	// 自动迁移所有模型
	err := db.AutoMigrate(
		&models.User{},
		&models.Role{},
		&models.Permission{},
		&models.RolePermission{},
		&models.UserRole{},
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
	)

	if err != nil {
		return fmt.Errorf("failed to migrate database: %w", err)
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

	return nil
}

// createAdminUser 创建管理员用户
func createAdminUser(db *gorm.DB) error {
	var adminUser models.User
	if err := db.Where("username = ?", "admin").First(&adminUser).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			// 创建管理员用户
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

			// 分配管理员角色
			var adminRole models.Role
			if err := db.Where("name = ?", "admin").First(&adminRole).Error; err != nil {
				return fmt.Errorf("failed to find admin role: %w", err)
			}

			userRole := models.UserRole{
				UserID: adminUser.ID,
				RoleID: adminRole.ID,
			}

			if err := db.Create(&userRole).Error; err != nil {
				return fmt.Errorf("failed to assign admin role: %w", err)
			}
		} else {
			return fmt.Errorf("failed to check admin user: %w", err)
		}
	}

	return nil
}
