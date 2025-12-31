package services

import "info-management-system/internal/models"

// GetSimplifiedPermissions 获取简化的权限数据（扁平化结构）
func GetSimplifiedPermissions() []models.Permission {
	return []models.Permission{
		// ==================== 系统管理权限 ====================
		{ID: 1001, Name: "system:admin", DisplayName: "系统管理", Description: "系统管理总权限", Resource: "system", Action: "admin", Scope: "all"},
		{ID: 1002, Name: "system:config_read", DisplayName: "查看系统配置", Description: "查看系统配置", Resource: "system", Action: "config_read", Scope: "all"},
		{ID: 1003, Name: "system:config_write", DisplayName: "编辑系统配置", Description: "编辑系统配置", Resource: "system", Action: "config_write", Scope: "all"},
		{ID: 1004, Name: "system:announcements_read", DisplayName: "查看公告", Description: "查看系统公告", Resource: "system", Action: "announcements_read", Scope: "all"},
		{ID: 1005, Name: "system:announcements_write", DisplayName: "管理公告", Description: "创建、编辑、删除公告", Resource: "system", Action: "announcements_write", Scope: "all"},
		{ID: 1006, Name: "system:logs_read", DisplayName: "查看日志", Description: "查看系统日志", Resource: "system", Action: "logs_read", Scope: "all"},
		{ID: 1007, Name: "system:logs_delete", DisplayName: "删除日志", Description: "删除系统日志", Resource: "system", Action: "logs_delete", Scope: "all"},
		{ID: 1008, Name: "system:health_read", DisplayName: "系统监控", Description: "查看系统健康状态", Resource: "system", Action: "health_read", Scope: "all"},
		{ID: 1009, Name: "system:stats_read", DisplayName: "系统统计", Description: "查看系统统计信息", Resource: "system", Action: "stats_read", Scope: "all"},

		// ==================== 用户管理权限 ====================
		{ID: 2001, Name: "users:read", DisplayName: "查看用户", Description: "查看用户列表和详情", Resource: "users", Action: "read", Scope: "all"},
		{ID: 2002, Name: "users:create", DisplayName: "创建用户", Description: "创建新用户", Resource: "users", Action: "create", Scope: "all"},
		{ID: 2003, Name: "users:update", DisplayName: "编辑用户", Description: "编辑用户信息", Resource: "users", Action: "update", Scope: "all"},
		{ID: 2004, Name: "users:delete", DisplayName: "删除用户", Description: "删除用户", Resource: "users", Action: "delete", Scope: "all"},
		{ID: 2005, Name: "users:assign_roles", DisplayName: "分配角色", Description: "为用户分配角色", Resource: "users", Action: "assign_roles", Scope: "all"},
		{ID: 2006, Name: "users:reset_password", DisplayName: "重置密码", Description: "重置用户密码", Resource: "users", Action: "reset_password", Scope: "all"},
		{ID: 2007, Name: "users:change_status", DisplayName: "修改状态", Description: "启用/禁用用户", Resource: "users", Action: "change_status", Scope: "all"},
		{ID: 2008, Name: "users:import", DisplayName: "导入用户", Description: "批量导入用户", Resource: "users", Action: "import", Scope: "all"},

		// ==================== 角色管理权限 ====================
		{ID: 3001, Name: "roles:read", DisplayName: "查看角色", Description: "查看角色列表和详情", Resource: "roles", Action: "read", Scope: "all"},
		{ID: 3002, Name: "roles:create", DisplayName: "创建角色", Description: "创建新角色", Resource: "roles", Action: "create", Scope: "all"},
		{ID: 3003, Name: "roles:update", DisplayName: "编辑角色", Description: "编辑角色信息", Resource: "roles", Action: "update", Scope: "all"},
		{ID: 3004, Name: "roles:delete", DisplayName: "删除角色", Description: "删除角色", Resource: "roles", Action: "delete", Scope: "all"},
		{ID: 3005, Name: "roles:assign_permissions", DisplayName: "分配权限", Description: "为角色分配权限", Resource: "roles", Action: "assign_permissions", Scope: "all"},
		{ID: 3006, Name: "roles:import", DisplayName: "导入角色", Description: "批量导入角色", Resource: "roles", Action: "import", Scope: "all"},

		// ==================== 权限管理权限 ====================
		{ID: 4001, Name: "permissions:read", DisplayName: "查看权限", Description: "查看权限列表和详情", Resource: "permissions", Action: "read", Scope: "all"},
		{ID: 4002, Name: "permissions:create", DisplayName: "创建权限", Description: "创建新权限", Resource: "permissions", Action: "create", Scope: "all"},
		{ID: 4003, Name: "permissions:update", DisplayName: "编辑权限", Description: "编辑权限信息", Resource: "permissions", Action: "update", Scope: "all"},
		{ID: 4004, Name: "permissions:delete", DisplayName: "删除权限", Description: "删除权限", Resource: "permissions", Action: "delete", Scope: "all"},
		{ID: 4005, Name: "permissions:initialize", DisplayName: "初始化权限", Description: "初始化系统权限", Resource: "permissions", Action: "initialize", Scope: "all"},

		// ==================== 工单管理权限 ====================
		{ID: 5001, Name: "ticket:read", DisplayName: "查看工单", Description: "查看工单列表和详情", Resource: "ticket", Action: "read", Scope: "all"},
		{ID: 5002, Name: "ticket:read_own", DisplayName: "查看自己的工单", Description: "只能查看自己创建的工单", Resource: "ticket", Action: "read", Scope: "own"},
		{ID: 5003, Name: "ticket:create", DisplayName: "创建工单", Description: "创建新工单", Resource: "ticket", Action: "create", Scope: "all"},
		{ID: 5004, Name: "ticket:update", DisplayName: "编辑工单", Description: "编辑工单信息", Resource: "ticket", Action: "update", Scope: "all"},
		{ID: 5005, Name: "ticket:update_own", DisplayName: "编辑自己的工单", Description: "只能编辑自己创建的工单", Resource: "ticket", Action: "update", Scope: "own"},
		{ID: 5006, Name: "ticket:delete", DisplayName: "删除工单", Description: "删除工单", Resource: "ticket", Action: "delete", Scope: "all"},
		{ID: 5007, Name: "ticket:delete_own", DisplayName: "删除自己的工单", Description: "只能删除自己创建的工单", Resource: "ticket", Action: "delete", Scope: "own"},
		{ID: 5008, Name: "ticket:assign", DisplayName: "分配工单", Description: "分配工单给其他用户", Resource: "ticket", Action: "assign", Scope: "all"},
		{ID: 5009, Name: "ticket:accept", DisplayName: "接受工单", Description: "接受分配的工单", Resource: "ticket", Action: "accept", Scope: "all"},
		{ID: 5010, Name: "ticket:reject", DisplayName: "拒绝工单", Description: "拒绝工单", Resource: "ticket", Action: "reject", Scope: "all"},
		{ID: 5011, Name: "ticket:reopen", DisplayName: "重新打开工单", Description: "重新打开已关闭的工单", Resource: "ticket", Action: "reopen", Scope: "all"},
		{ID: 5012, Name: "ticket:status_change", DisplayName: "修改工单状态", Description: "修改工单状态", Resource: "ticket", Action: "status_change", Scope: "all"},
		{ID: 5013, Name: "ticket:comment_read", DisplayName: "查看评论", Description: "查看工单评论", Resource: "ticket", Action: "comment_read", Scope: "all"},
		{ID: 5014, Name: "ticket:comment_write", DisplayName: "添加评论", Description: "为工单添加评论", Resource: "ticket", Action: "comment_write", Scope: "all"},
		{ID: 5015, Name: "ticket:attachment_upload", DisplayName: "上传附件", Description: "为工单上传附件", Resource: "ticket", Action: "attachment_upload", Scope: "all"},
		{ID: 5016, Name: "ticket:attachment_delete", DisplayName: "删除附件", Description: "删除工单附件", Resource: "ticket", Action: "attachment_delete", Scope: "all"},
		{ID: 5017, Name: "ticket:statistics", DisplayName: "工单统计", Description: "查看工单统计数据", Resource: "ticket", Action: "statistics", Scope: "all"},
		{ID: 5018, Name: "ticket:export", DisplayName: "导出工单", Description: "导出工单数据", Resource: "ticket", Action: "export", Scope: "all"},
		{ID: 5019, Name: "ticket:import", DisplayName: "导入工单", Description: "批量导入工单", Resource: "ticket", Action: "import", Scope: "all"},

		// ==================== 记录管理权限 ====================
		{ID: 6001, Name: "records:read", DisplayName: "查看记录", Description: "查看记录列表和详情", Resource: "records", Action: "read", Scope: "all"},
		{ID: 6002, Name: "records:read_own", DisplayName: "查看自己的记录", Description: "只能查看自己创建的记录", Resource: "records", Action: "read", Scope: "own"},
		{ID: 6003, Name: "records:create", DisplayName: "创建记录", Description: "创建新记录", Resource: "records", Action: "create", Scope: "all"},
		{ID: 6004, Name: "records:update", DisplayName: "编辑记录", Description: "编辑记录信息", Resource: "records", Action: "update", Scope: "all"},
		{ID: 6005, Name: "records:update_own", DisplayName: "编辑自己的记录", Description: "只能编辑自己创建的记录", Resource: "records", Action: "update", Scope: "own"},
		{ID: 6006, Name: "records:delete", DisplayName: "删除记录", Description: "删除记录", Resource: "records", Action: "delete", Scope: "all"},
		{ID: 6007, Name: "records:delete_own", DisplayName: "删除自己的记录", Description: "只能删除自己创建的记录", Resource: "records", Action: "delete", Scope: "own"},
		{ID: 6008, Name: "records:import", DisplayName: "导入记录", Description: "批量导入记录", Resource: "records", Action: "import", Scope: "all"},

		// ==================== 记录类型管理权限 ====================
		{ID: 7001, Name: "record_types:read", DisplayName: "查看记录类型", Description: "查看记录类型列表和详情", Resource: "record_types", Action: "read", Scope: "all"},
		{ID: 7002, Name: "record_types:create", DisplayName: "创建记录类型", Description: "创建新记录类型", Resource: "record_types", Action: "create", Scope: "all"},
		{ID: 7003, Name: "record_types:update", DisplayName: "编辑记录类型", Description: "编辑记录类型信息", Resource: "record_types", Action: "update", Scope: "all"},
		{ID: 7004, Name: "record_types:delete", DisplayName: "删除记录类型", Description: "删除记录类型", Resource: "record_types", Action: "delete", Scope: "all"},
		{ID: 7005, Name: "record_types:import", DisplayName: "导入记录类型", Description: "批量导入记录类型", Resource: "record_types", Action: "import", Scope: "all"},

		// ==================== 文件管理权限 ====================
		{ID: 8001, Name: "files:read", DisplayName: "查看文件", Description: "查看文件列表和详情", Resource: "files", Action: "read", Scope: "all"},
		{ID: 8002, Name: "files:upload", DisplayName: "上传文件", Description: "上传文件", Resource: "files", Action: "upload", Scope: "all"},
		{ID: 8003, Name: "files:download", DisplayName: "下载文件", Description: "下载文件", Resource: "files", Action: "download", Scope: "all"},
		{ID: 8004, Name: "files:delete", DisplayName: "删除文件", Description: "删除文件", Resource: "files", Action: "delete", Scope: "all"},
		{ID: 8005, Name: "files:ocr", DisplayName: "OCR识别", Description: "使用OCR功能识别文件内容", Resource: "files", Action: "ocr", Scope: "all"},

		// ==================== 导出管理权限 ====================
		{ID: 9001, Name: "export:read", DisplayName: "查看导出", Description: "查看导出模板和任务", Resource: "export", Action: "read", Scope: "all"},
		{ID: 9002, Name: "export:create", DisplayName: "创建导出模板", Description: "创建导出模板", Resource: "export", Action: "create", Scope: "all"},
		{ID: 9003, Name: "export:update", DisplayName: "编辑导出模板", Description: "编辑导出模板", Resource: "export", Action: "update", Scope: "all"},
		{ID: 9004, Name: "export:delete", DisplayName: "删除导出模板", Description: "删除导出模板", Resource: "export", Action: "delete", Scope: "all"},
		{ID: 9005, Name: "export:execute", DisplayName: "执行导出", Description: "执行数据导出", Resource: "export", Action: "execute", Scope: "all"},
		{ID: 9006, Name: "export:download", DisplayName: "下载导出文件", Description: "下载导出的文件", Resource: "export", Action: "download", Scope: "all"},

		// ==================== AI功能权限 ====================
		{ID: 10001, Name: "ai:features", DisplayName: "AI功能", Description: "使用AI相关功能", Resource: "ai", Action: "features", Scope: "all"},
		{ID: 10002, Name: "ai:config", DisplayName: "AI配置管理", Description: "管理AI配置", Resource: "ai", Action: "config", Scope: "all"},
		{ID: 10003, Name: "ai:chat", DisplayName: "AI对话", Description: "使用AI对话功能", Resource: "ai", Action: "chat", Scope: "all"},
		{ID: 10004, Name: "ai:optimize", DisplayName: "AI优化", Description: "使用AI优化功能", Resource: "ai", Action: "optimize", Scope: "all"},
		{ID: 10005, Name: "ai:speech", DisplayName: "语音识别", Description: "使用语音识别功能", Resource: "ai", Action: "speech", Scope: "all"},
	}
}

// GetStandardRoles 获取标准角色配置
func GetStandardRoles() []struct {
	Role        models.Role
	Permissions []uint
} {
	return []struct {
		Role        models.Role
		Permissions []uint
	}{
		{
			Role: models.Role{
				ID:          1,
				Name:        "系统管理员",
				DisplayName: "系统管理员",
				Description: "拥有系统所有权限的超级管理员",
				IsSystem:    true,
			},
			Permissions: []uint{
				// 系统管理
				1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009,
				// 用户管理
				2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008,
				// 角色管理
				3001, 3002, 3003, 3004, 3005, 3006,
				// 权限管理
				4001, 4002, 4003, 4004, 4005,
				// 工单管理
				5001, 5003, 5004, 5006, 5008, 5009, 5010, 5011, 5012, 5013, 5014, 5015, 5016, 5017, 5018, 5019,
				// 记录管理
				6001, 6003, 6004, 6006, 6008,
				// 记录类型管理
				7001, 7002, 7003, 7004, 7005,
				// 文件管理
				8001, 8002, 8003, 8004, 8005,
				// 导出管理
				9001, 9002, 9003, 9004, 9005, 9006,
				// AI功能
				10001, 10002, 10003, 10004, 10005,
			},
		},
		{
			Role: models.Role{
				ID:          2,
				Name:        "工单管理员",
				DisplayName: "工单管理员",
				Description: "负责工单系统管理的管理员",
				IsSystem:    false,
			},
			Permissions: []uint{
				// 工单管理
				5001, 5003, 5004, 5006, 5008, 5009, 5010, 5011, 5012, 5013, 5014, 5015, 5016, 5017, 5018, 5019,
				// 用户查看（用于分配工单）
				2001,
				// 文件管理（用于附件）
				8001, 8002, 8003, 8004,
			},
		},
		{
			Role: models.Role{
				ID:          3,
				Name:        "工单处理人",
				DisplayName: "工单处理人",
				Description: "负责处理工单的用户",
				IsSystem:    false,
			},
			Permissions: []uint{
				// 工单管理（受限）
				5001, 5009, 5012, 5013, 5014, 5015, 5017,
				// 文件管理（用于附件）
				8001, 8002, 8003,
			},
		},
		{
			Role: models.Role{
				ID:          4,
				Name:        "工单申请人",
				DisplayName: "工单申请人",
				Description: "可以创建和查看自己工单的普通用户",
				IsSystem:    false,
			},
			Permissions: []uint{
				// 工单管理（仅自己的）
				5002, 5003, 5005, 5007, 5013, 5014, 5015, 5017,
				// 文件管理（用于附件）
				8001, 8002, 8003,
			},
		},
		{
			Role: models.Role{
				ID:          5,
				Name:        "记录管理员",
				DisplayName: "记录管理员",
				Description: "负责记录管理的用户",
				IsSystem:    false,
			},
			Permissions: []uint{
				// 记录管理
				6001, 6003, 6004, 6006, 6008,
				// 记录类型管理
				7001, 7002, 7003, 7004, 7005,
				// 文件管理
				8001, 8002, 8003, 8004, 8005,
				// 导出管理
				9001, 9002, 9003, 9004, 9005, 9006,
			},
		},
		{
			Role: models.Role{
				ID:          6,
				Name:        "普通用户",
				DisplayName: "普通用户",
				Description: "只能查看和管理自己数据的普通用户",
				IsSystem:    false,
			},
			Permissions: []uint{
				// 记录管理（仅自己的）
				6002, 6003, 6005, 6007,
				// 工单管理（仅自己的）
				5002, 5003, 5005, 5007, 5013, 5014, 5015,
				// 文件管理（基础）
				8001, 8002, 8003,
			},
		},
		{
			Role: models.Role{
				ID:          7,
				Name:        "只读用户",
				DisplayName: "只读用户",
				Description: "只能查看数据的用户",
				IsSystem:    false,
			},
			Permissions: []uint{
				// 记录查看（仅自己的）
				6002,
				// 工单查看（仅自己的）
				5002, 5013,
				// 文件查看
				8001, 8003,
			},
		},
	}
}