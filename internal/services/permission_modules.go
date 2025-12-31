package services

import "info-management-system/internal/models"

// getRecordsPermissions 获取记录管理模块权限
func getRecordsPermissions() []models.Permission {
	return []models.Permission{
		// ==================== 记录管理模块 ====================
		{ID: 4, Name: "records", DisplayName: "记录管理", Description: "记录管理模块总权限", Resource: "records", Action: "manage", Scope: "all", ParentID: nil},
		
		// 记录查看权限
		{ID: 401, Name: "records:read", DisplayName: "记录查看权限", Description: "记录查看相关权限", Resource: "records", Action: "read", Scope: "all", ParentID: uintPtr(4)},
		{ID: 4011, Name: "records:read:all", DisplayName: "查看所有记录", Description: "查看系统中所有记录", Resource: "records", Action: "read:all", Scope: "all", ParentID: uintPtr(401)},
		{ID: 4012, Name: "records:read:own", DisplayName: "查看自己的记录", Description: "只能查看自己创建的记录", Resource: "records", Action: "read:own", Scope: "own", ParentID: uintPtr(401)},
		{ID: 4013, Name: "records:read:department", DisplayName: "查看部门记录", Description: "查看本部门的记录", Resource: "records", Action: "read:department", Scope: "department", ParentID: uintPtr(401)},
		{ID: 4014, Name: "records:read:details", DisplayName: "查看记录详情", Description: "查看记录的详细信息", Resource: "records", Action: "read:details", Scope: "all", ParentID: uintPtr(401)},
		
		// 记录编辑权限
		{ID: 402, Name: "records:write", DisplayName: "记录编辑权限", Description: "记录编辑相关权限", Resource: "records", Action: "write", Scope: "all", ParentID: uintPtr(4)},
		{ID: 4021, Name: "records:create", DisplayName: "创建记录", Description: "创建新记录", Resource: "records", Action: "create", Scope: "all", ParentID: uintPtr(402)},
		{ID: 4022, Name: "records:update:all", DisplayName: "编辑所有记录", Description: "编辑系统中所有记录", Resource: "records", Action: "update:all", Scope: "all", ParentID: uintPtr(402)},
		{ID: 4023, Name: "records:update:own", DisplayName: "编辑自己的记录", Description: "只能编辑自己创建的记录", Resource: "records", Action: "update:own", Scope: "own", ParentID: uintPtr(402)},
		{ID: 4024, Name: "records:update:department", DisplayName: "编辑部门记录", Description: "编辑本部门的记录", Resource: "records", Action: "update:department", Scope: "department", ParentID: uintPtr(402)},
		
		// 记录删除权限
		{ID: 403, Name: "records:delete", DisplayName: "记录删除权限", Description: "记录删除相关权限", Resource: "records", Action: "delete", Scope: "all", ParentID: uintPtr(4)},
		{ID: 4031, Name: "records:delete:all", DisplayName: "删除所有记录", Description: "删除系统中所有记录", Resource: "records", Action: "delete:all", Scope: "all", ParentID: uintPtr(403)},
		{ID: 4032, Name: "records:delete:own", DisplayName: "删除自己的记录", Description: "只能删除自己创建的记录", Resource: "records", Action: "delete:own", Scope: "own", ParentID: uintPtr(403)},
		{ID: 4033, Name: "records:delete:department", DisplayName: "删除部门记录", Description: "删除本部门的记录", Resource: "records", Action: "delete:department", Scope: "department", ParentID: uintPtr(403)},
		
		// 记录类型管理
		{ID: 404, Name: "records:types", DisplayName: "记录类型管理", Description: "记录类型管理权限", Resource: "records", Action: "types", Scope: "all", ParentID: uintPtr(4)},
		{ID: 4041, Name: "records:types:read", DisplayName: "查看记录类型", Description: "查看记录类型配置", Resource: "records", Action: "types:read", Scope: "all", ParentID: uintPtr(404)},
		{ID: 4042, Name: "records:types:write", DisplayName: "管理记录类型", Description: "创建、编辑记录类型", Resource: "records", Action: "types:write", Scope: "all", ParentID: uintPtr(404)},
		{ID: 4043, Name: "records:types:delete", DisplayName: "删除记录类型", Description: "删除记录类型配置", Resource: "records", Action: "types:delete", Scope: "all", ParentID: uintPtr(404)},
		
		// 记录批量操作
		{ID: 405, Name: "records:batch", DisplayName: "记录批量操作", Description: "记录批量操作权限", Resource: "records", Action: "batch", Scope: "all", ParentID: uintPtr(4)},
		{ID: 4051, Name: "records:batch:import", DisplayName: "批量导入记录", Description: "批量导入记录数据", Resource: "records", Action: "batch:import", Scope: "all", ParentID: uintPtr(405)},
		{ID: 4052, Name: "records:batch:export", DisplayName: "批量导出记录", Description: "批量导出记录数据", Resource: "records", Action: "batch:export", Scope: "all", ParentID: uintPtr(405)},
		{ID: 4053, Name: "records:batch:update", DisplayName: "批量更新记录", Description: "批量更新记录状态", Resource: "records", Action: "batch:update", Scope: "all", ParentID: uintPtr(405)},
		{ID: 4054, Name: "records:batch:delete", DisplayName: "批量删除记录", Description: "批量删除记录数据", Resource: "records", Action: "batch:delete", Scope: "all", ParentID: uintPtr(405)},
	}
}

// getFilesPermissions 获取文件管理模块权限
func getFilesPermissions() []models.Permission {
	return []models.Permission{
		// ==================== 文件管理模块 ====================
		{ID: 5, Name: "files", DisplayName: "文件管理", Description: "文件管理模块总权限", Resource: "files", Action: "manage", Scope: "all", ParentID: nil},
		
		// 文件基础操作
		{ID: 501, Name: "files:basic", DisplayName: "文件基础操作", Description: "文件基础操作权限", Resource: "files", Action: "basic", Scope: "all", ParentID: uintPtr(5)},
		{ID: 5011, Name: "files:read:all", DisplayName: "查看所有文件", Description: "查看和下载所有文件", Resource: "files", Action: "read:all", Scope: "all", ParentID: uintPtr(501)},
		{ID: 5012, Name: "files:read:own", DisplayName: "查看自己的文件", Description: "只能查看自己上传的文件", Resource: "files", Action: "read:own", Scope: "own", ParentID: uintPtr(501)},
		{ID: 5013, Name: "files:upload", DisplayName: "上传文件", Description: "上传文件到系统", Resource: "files", Action: "upload", Scope: "all", ParentID: uintPtr(501)},
		{ID: 5014, Name: "files:download", DisplayName: "下载文件", Description: "下载文件到本地", Resource: "files", Action: "download", Scope: "all", ParentID: uintPtr(501)},
		
		// 文件高级操作
		{ID: 502, Name: "files:advanced", DisplayName: "文件高级操作", Description: "文件高级管理功能", Resource: "files", Action: "advanced", Scope: "all", ParentID: uintPtr(5)},
		{ID: 5021, Name: "files:update:all", DisplayName: "编辑所有文件", Description: "编辑所有文件信息", Resource: "files", Action: "update:all", Scope: "all", ParentID: uintPtr(502)},
		{ID: 5022, Name: "files:update:own", DisplayName: "编辑自己的文件", Description: "只能编辑自己上传的文件", Resource: "files", Action: "update:own", Scope: "own", ParentID: uintPtr(502)},
		{ID: 5023, Name: "files:delete:all", DisplayName: "删除所有文件", Description: "删除系统中所有文件", Resource: "files", Action: "delete:all", Scope: "all", ParentID: uintPtr(502)},
		{ID: 5024, Name: "files:delete:own", DisplayName: "删除自己的文件", Description: "只能删除自己上传的文件", Resource: "files", Action: "delete:own", Scope: "own", ParentID: uintPtr(502)},
		{ID: 5025, Name: "files:share", DisplayName: "分享文件", Description: "分享文件给其他用户", Resource: "files", Action: "share", Scope: "all", ParentID: uintPtr(502)},
		
		// OCR功能
		{ID: 503, Name: "files:ocr", DisplayName: "OCR文字识别", Description: "OCR文字识别功能", Resource: "files", Action: "ocr", Scope: "all", ParentID: uintPtr(5)},
		{ID: 5031, Name: "files:ocr:use", DisplayName: "使用OCR功能", Description: "使用OCR识别文件中的文字", Resource: "files", Action: "ocr:use", Scope: "all", ParentID: uintPtr(503)},
		{ID: 5032, Name: "files:ocr:batch", DisplayName: "批量OCR识别", Description: "批量进行OCR文字识别", Resource: "files", Action: "ocr:batch", Scope: "all", ParentID: uintPtr(503)},
	}
}

// getExportPermissions 获取数据导出模块权限
func getExportPermissions() []models.Permission {
	return []models.Permission{
		// ==================== 数据导出模块 ====================
		{ID: 6, Name: "export", DisplayName: "数据导出", Description: "数据导出模块总权限", Resource: "export", Action: "manage", Scope: "all", ParentID: nil},
		
		// 导出模板管理
		{ID: 601, Name: "export:templates", DisplayName: "导出模板管理", Description: "导出模板管理权限", Resource: "export", Action: "templates", Scope: "all", ParentID: uintPtr(6)},
		{ID: 6011, Name: "export:templates:read", DisplayName: "查看导出模板", Description: "查看导出模板列表", Resource: "export", Action: "templates:read", Scope: "all", ParentID: uintPtr(601)},
		{ID: 6012, Name: "export:templates:write", DisplayName: "管理导出模板", Description: "创建、编辑导出模板", Resource: "export", Action: "templates:write", Scope: "all", ParentID: uintPtr(601)},
		{ID: 6013, Name: "export:templates:delete", DisplayName: "删除导出模板", Description: "删除导出模板", Resource: "export", Action: "templates:delete", Scope: "all", ParentID: uintPtr(601)},
		
		// 数据导出操作
		{ID: 602, Name: "export:data", DisplayName: "数据导出操作", Description: "数据导出操作权限", Resource: "export", Action: "data", Scope: "all", ParentID: uintPtr(6)},
		{ID: 6021, Name: "export:records:all", DisplayName: "导出所有记录", Description: "导出系统中所有记录数据", Resource: "export", Action: "records:all", Scope: "all", ParentID: uintPtr(602)},
		{ID: 6022, Name: "export:records:own", DisplayName: "导出自己的记录", Description: "只能导出自己创建的记录", Resource: "export", Action: "records:own", Scope: "own", ParentID: uintPtr(602)},
		{ID: 6023, Name: "export:users", DisplayName: "导出用户数据", Description: "导出用户数据", Resource: "export", Action: "users", Scope: "all", ParentID: uintPtr(602)},
		{ID: 6024, Name: "export:files", DisplayName: "导出文件数据", Description: "导出文件信息数据", Resource: "export", Action: "files", Scope: "all", ParentID: uintPtr(602)},
		{ID: 6025, Name: "export:logs", DisplayName: "导出系统日志", Description: "导出系统日志数据", Resource: "export", Action: "logs", Scope: "all", ParentID: uintPtr(602)},
		
		// 导出任务管理
		{ID: 603, Name: "export:tasks", DisplayName: "导出任务管理", Description: "导出任务管理权限", Resource: "export", Action: "tasks", Scope: "all", ParentID: uintPtr(6)},
		{ID: 6031, Name: "export:tasks:read", DisplayName: "查看导出任务", Description: "查看导出任务列表和进度", Resource: "export", Action: "tasks:read", Scope: "all", ParentID: uintPtr(603)},
		{ID: 6032, Name: "export:tasks:download", DisplayName: "下载导出文件", Description: "下载导出的文件", Resource: "export", Action: "tasks:download", Scope: "all", ParentID: uintPtr(603)},
		{ID: 6033, Name: "export:tasks:delete", DisplayName: "删除导出任务", Description: "删除导出任务和文件", Resource: "export", Action: "tasks:delete", Scope: "all", ParentID: uintPtr(603)},
	}
}

// getNotificationsPermissions 获取通知管理模块权限
func getNotificationsPermissions() []models.Permission {
	return []models.Permission{
		// ==================== 通知管理模块 ====================
		{ID: 7, Name: "notifications", DisplayName: "通知管理", Description: "通知管理模块总权限", Resource: "notifications", Action: "manage", Scope: "all", ParentID: nil},
		
		// 通知模板管理
		{ID: 701, Name: "notifications:templates", DisplayName: "通知模板管理", Description: "通知模板管理权限", Resource: "notifications", Action: "templates", Scope: "all", ParentID: uintPtr(7)},
		{ID: 7011, Name: "notifications:templates:read", DisplayName: "查看通知模板", Description: "查看通知模板列表", Resource: "notifications", Action: "templates:read", Scope: "all", ParentID: uintPtr(701)},
		{ID: 7012, Name: "notifications:templates:write", DisplayName: "管理通知模板", Description: "创建、编辑通知模板", Resource: "notifications", Action: "templates:write", Scope: "all", ParentID: uintPtr(701)},
		{ID: 7013, Name: "notifications:templates:delete", DisplayName: "删除通知模板", Description: "删除通知模板", Resource: "notifications", Action: "templates:delete", Scope: "all", ParentID: uintPtr(701)},
		
		// 通知发送
		{ID: 702, Name: "notifications:send", DisplayName: "通知发送", Description: "通知发送权限", Resource: "notifications", Action: "send", Scope: "all", ParentID: uintPtr(7)},
		{ID: 7021, Name: "notifications:send:single", DisplayName: "发送单个通知", Description: "发送单个通知消息", Resource: "notifications", Action: "send:single", Scope: "all", ParentID: uintPtr(702)},
		{ID: 7022, Name: "notifications:send:batch", DisplayName: "批量发送通知", Description: "批量发送通知消息", Resource: "notifications", Action: "send:batch", Scope: "all", ParentID: uintPtr(702)},
		{ID: 7023, Name: "notifications:send:system", DisplayName: "发送系统通知", Description: "发送系统级通知", Resource: "notifications", Action: "send:system", Scope: "all", ParentID: uintPtr(702)},
		
		// 通知历史
		{ID: 703, Name: "notifications:history", DisplayName: "通知历史", Description: "通知历史查看权限", Resource: "notifications", Action: "history", Scope: "all", ParentID: uintPtr(7)},
		{ID: 7031, Name: "notifications:history:read", DisplayName: "查看通知历史", Description: "查看通知发送历史", Resource: "notifications", Action: "history:read", Scope: "all", ParentID: uintPtr(703)},
		{ID: 7032, Name: "notifications:history:export", DisplayName: "导出通知历史", Description: "导出通知历史数据", Resource: "notifications", Action: "history:export", Scope: "all", ParentID: uintPtr(703)},
	}
}

// getAIPermissions 获取AI功能模块权限
func getAIPermissions() []models.Permission {
	return []models.Permission{
		// ==================== AI功能模块 ====================
		{ID: 8, Name: "ai", DisplayName: "AI功能", Description: "AI功能模块总权限", Resource: "ai", Action: "manage", Scope: "all", ParentID: nil},
		
		// AI配置管理
		{ID: 801, Name: "ai:config", DisplayName: "AI配置管理", Description: "AI配置管理权限", Resource: "ai", Action: "config", Scope: "all", ParentID: uintPtr(8)},
		{ID: 8011, Name: "ai:config:read", DisplayName: "查看AI配置", Description: "查看AI服务配置", Resource: "ai", Action: "config:read", Scope: "all", ParentID: uintPtr(801)},
		{ID: 8012, Name: "ai:config:write", DisplayName: "管理AI配置", Description: "创建、编辑AI配置", Resource: "ai", Action: "config:write", Scope: "all", ParentID: uintPtr(801)},
		
		// AI功能使用
		{ID: 802, Name: "ai:features", DisplayName: "AI功能使用", Description: "AI功能使用权限", Resource: "ai", Action: "features", Scope: "all", ParentID: uintPtr(8)},
		{ID: 8021, Name: "ai:chat", DisplayName: "AI聊天", Description: "使用AI聊天功能", Resource: "ai", Action: "chat", Scope: "all", ParentID: uintPtr(802)},
		{ID: 8022, Name: "ai:optimize", DisplayName: "AI优化记录", Description: "使用AI优化记录内容", Resource: "ai", Action: "optimize", Scope: "all", ParentID: uintPtr(802)},
		{ID: 8023, Name: "ai:speech_to_text", DisplayName: "语音识别", Description: "使用AI语音转文字功能", Resource: "ai", Action: "speech_to_text", Scope: "all", ParentID: uintPtr(802)},
	}
}

// getDashboardPermissions 获取仪表盘模块权限
func getDashboardPermissions() []models.Permission {
	return []models.Permission{
		// ==================== 仪表盘模块 ====================
		{ID: 9, Name: "dashboard", DisplayName: "仪表盘", Description: "仪表盘模块总权限", Resource: "dashboard", Action: "manage", Scope: "all", ParentID: nil},
		{ID: 901, Name: "dashboard:view", DisplayName: "查看仪表盘", Description: "查看仪表盘数据", Resource: "dashboard", Action: "view", Scope: "all", ParentID: uintPtr(9)},
		{ID: 9011, Name: "dashboard:stats:all", DisplayName: "查看全部统计", Description: "查看系统全部统计数据", Resource: "dashboard", Action: "stats:all", Scope: "all", ParentID: uintPtr(901)},
		{ID: 9012, Name: "dashboard:stats:own", DisplayName: "查看个人统计", Description: "只能查看个人相关统计", Resource: "dashboard", Action: "stats:own", Scope: "own", ParentID: uintPtr(901)},
		{ID: 9013, Name: "dashboard:recent_records", DisplayName: "查看最近记录", Description: "查看最近的记录动态", Resource: "dashboard", Action: "recent_records", Scope: "all", ParentID: uintPtr(901)},
		{ID: 9014, Name: "dashboard:system_info", DisplayName: "查看系统信息", Description: "查看系统运行信息", Resource: "dashboard", Action: "system_info", Scope: "all", ParentID: uintPtr(901)},
	}
}

// getAuditPermissions 获取审计日志模块权限
func getAuditPermissions() []models.Permission {
	return []models.Permission{
		// ==================== 审计日志模块 ====================
		{ID: 10, Name: "audit", DisplayName: "审计日志", Description: "审计日志模块总权限", Resource: "audit", Action: "manage", Scope: "all", ParentID: nil},
		{ID: 1001, Name: "audit:logs", DisplayName: "审计日志查看", Description: "审计日志查看权限", Resource: "audit", Action: "logs", Scope: "all", ParentID: uintPtr(10)},
		{ID: 10011, Name: "audit:logs:read:all", DisplayName: "查看所有审计日志", Description: "查看系统所有审计日志", Resource: "audit", Action: "logs:read:all", Scope: "all", ParentID: uintPtr(1001)},
		{ID: 10012, Name: "audit:logs:read:own", DisplayName: "查看个人审计日志", Description: "只能查看个人操作日志", Resource: "audit", Action: "logs:read:own", Scope: "own", ParentID: uintPtr(1001)},
		{ID: 10013, Name: "audit:logs:export", DisplayName: "导出审计日志", Description: "导出审计日志数据", Resource: "audit", Action: "logs:export", Scope: "all", ParentID: uintPtr(1001)},
		{ID: 10014, Name: "audit:logs:cleanup", DisplayName: "清理审计日志", Description: "清理过期的审计日志", Resource: "audit", Action: "logs:cleanup", Scope: "all", ParentID: uintPtr(1001)},
	}
}