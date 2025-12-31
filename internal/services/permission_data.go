package services

import "info-management-system/internal/models"

// GetAllDetailedPermissions 获取所有精细化权限数据
func GetAllDetailedPermissions() []models.Permission {
	permissions := []models.Permission{
		// ==================== 系统管理模块 ====================
		{ID: 1, Name: "system", DisplayName: "系统管理", Description: "系统管理模块总权限", Resource: "system", Action: "manage", Scope: "all", ParentID: nil},
		
		// 系统配置管理
		{ID: 101, Name: "system:config", DisplayName: "系统配置管理", Description: "系统配置相关权限", Resource: "system", Action: "config", Scope: "all", ParentID: uintPtr(1)},
		{ID: 1011, Name: "system:config:read", DisplayName: "查看系统配置", Description: "查看系统配置列表和详情", Resource: "system", Action: "config:read", Scope: "all", ParentID: uintPtr(101)},
		{ID: 1012, Name: "system:config:write", DisplayName: "编辑系统配置", Description: "创建、修改系统配置", Resource: "system", Action: "config:write", Scope: "all", ParentID: uintPtr(101)},
		{ID: 1013, Name: "system:config:delete", DisplayName: "删除系统配置", Description: "删除系统配置项", Resource: "system", Action: "config:delete", Scope: "all", ParentID: uintPtr(101)},
		{ID: 1014, Name: "system:config:import", DisplayName: "导入系统配置", Description: "批量导入系统配置", Resource: "system", Action: "config:import", Scope: "all", ParentID: uintPtr(101)},
		{ID: 1015, Name: "system:config:export", DisplayName: "导出系统配置", Description: "导出系统配置数据", Resource: "system", Action: "config:export", Scope: "all", ParentID: uintPtr(101)},
		
		// 系统监控
		{ID: 102, Name: "system:monitor", DisplayName: "系统监控", Description: "系统监控相关权限", Resource: "system", Action: "monitor", Scope: "all", ParentID: uintPtr(1)},
		{ID: 1021, Name: "system:monitor:health", DisplayName: "系统健康检查", Description: "查看系统健康状态", Resource: "system", Action: "monitor:health", Scope: "all", ParentID: uintPtr(102)},
		{ID: 1022, Name: "system:monitor:metrics", DisplayName: "系统指标监控", Description: "查看系统性能指标", Resource: "system", Action: "monitor:metrics", Scope: "all", ParentID: uintPtr(102)},
		
		// 系统日志
		{ID: 103, Name: "system:logs", DisplayName: "系统日志管理", Description: "系统日志相关权限", Resource: "system", Action: "logs", Scope: "all", ParentID: uintPtr(1)},
		{ID: 1031, Name: "system:logs:read", DisplayName: "查看系统日志", Description: "查看系统日志记录", Resource: "system", Action: "logs:read", Scope: "all", ParentID: uintPtr(103)},
		{ID: 1032, Name: "system:logs:delete", DisplayName: "删除系统日志", Description: "删除系统日志记录", Resource: "system", Action: "logs:delete", Scope: "all", ParentID: uintPtr(103)},
		{ID: 1033, Name: "system:logs:export", DisplayName: "导出系统日志", Description: "导出系统日志数据", Resource: "system", Action: "logs:export", Scope: "all", ParentID: uintPtr(103)},
		
		// 公告管理
		{ID: 104, Name: "system:announcements", DisplayName: "公告管理", Description: "系统公告相关权限", Resource: "system", Action: "announcements", Scope: "all", ParentID: uintPtr(1)},
		{ID: 1041, Name: "system:announcements:read", DisplayName: "查看公告", Description: "查看系统公告", Resource: "system", Action: "announcements:read", Scope: "all", ParentID: uintPtr(104)},
		{ID: 1042, Name: "system:announcements:write", DisplayName: "发布公告", Description: "创建、编辑系统公告", Resource: "system", Action: "announcements:write", Scope: "all", ParentID: uintPtr(104)},
		{ID: 1043, Name: "system:announcements:delete", DisplayName: "删除公告", Description: "删除系统公告", Resource: "system", Action: "announcements:delete", Scope: "all", ParentID: uintPtr(104)},

		// ==================== 用户管理模块 ====================
		{ID: 2, Name: "users", DisplayName: "用户管理", Description: "用户管理模块总权限", Resource: "users", Action: "manage", Scope: "all", ParentID: nil},
		
		// 用户基础操作
		{ID: 201, Name: "users:basic", DisplayName: "用户基础操作", Description: "用户基础CRUD操作", Resource: "users", Action: "basic", Scope: "all", ParentID: uintPtr(2)},
		{ID: 2011, Name: "users:read", DisplayName: "查看用户", Description: "查看用户列表和详情", Resource: "users", Action: "read", Scope: "all", ParentID: uintPtr(201)},
		{ID: 2012, Name: "users:create", DisplayName: "创建用户", Description: "创建新用户账号", Resource: "users", Action: "create", Scope: "all", ParentID: uintPtr(201)},
		{ID: 2013, Name: "users:update", DisplayName: "编辑用户", Description: "编辑用户基本信息", Resource: "users", Action: "update", Scope: "all", ParentID: uintPtr(201)},
		{ID: 2014, Name: "users:delete", DisplayName: "删除用户", Description: "删除用户账号", Resource: "users", Action: "delete", Scope: "all", ParentID: uintPtr(201)},
		
		// 用户高级操作
		{ID: 202, Name: "users:advanced", DisplayName: "用户高级操作", Description: "用户高级管理功能", Resource: "users", Action: "advanced", Scope: "all", ParentID: uintPtr(2)},
		{ID: 2021, Name: "users:reset_password", DisplayName: "重置密码", Description: "重置用户密码", Resource: "users", Action: "reset_password", Scope: "all", ParentID: uintPtr(202)},
		{ID: 2022, Name: "users:change_status", DisplayName: "修改用户状态", Description: "启用/禁用用户账号", Resource: "users", Action: "change_status", Scope: "all", ParentID: uintPtr(202)},
		{ID: 2023, Name: "users:assign_roles", DisplayName: "分配角色", Description: "为用户分配角色", Resource: "users", Action: "assign_roles", Scope: "all", ParentID: uintPtr(202)},
		{ID: 2024, Name: "users:batch_operations", DisplayName: "批量操作", Description: "批量管理用户", Resource: "users", Action: "batch_operations", Scope: "all", ParentID: uintPtr(202)},
		
		// 用户数据操作
		{ID: 203, Name: "users:data", DisplayName: "用户数据操作", Description: "用户数据导入导出", Resource: "users", Action: "data", Scope: "all", ParentID: uintPtr(2)},
		{ID: 2031, Name: "users:import", DisplayName: "导入用户", Description: "批量导入用户数据", Resource: "users", Action: "import", Scope: "all", ParentID: uintPtr(203)},
		{ID: 2032, Name: "users:export", DisplayName: "导出用户", Description: "导出用户数据", Resource: "users", Action: "export", Scope: "all", ParentID: uintPtr(203)},

		// ==================== 角色权限管理模块 ====================
		{ID: 3, Name: "roles", DisplayName: "角色权限管理", Description: "角色权限管理模块总权限", Resource: "roles", Action: "manage", Scope: "all", ParentID: nil},
		
		// 角色基础操作
		{ID: 301, Name: "roles:basic", DisplayName: "角色基础操作", Description: "角色基础CRUD操作", Resource: "roles", Action: "basic", Scope: "all", ParentID: uintPtr(3)},
		{ID: 3011, Name: "roles:read", DisplayName: "查看角色", Description: "查看角色列表和详情", Resource: "roles", Action: "read", Scope: "all", ParentID: uintPtr(301)},
		{ID: 3012, Name: "roles:create", DisplayName: "创建角色", Description: "创建新角色", Resource: "roles", Action: "create", Scope: "all", ParentID: uintPtr(301)},
		{ID: 3013, Name: "roles:update", DisplayName: "编辑角色", Description: "编辑角色基本信息", Resource: "roles", Action: "update", Scope: "all", ParentID: uintPtr(301)},
		{ID: 3014, Name: "roles:delete", DisplayName: "删除角色", Description: "删除角色", Resource: "roles", Action: "delete", Scope: "all", ParentID: uintPtr(301)},
		
		// 权限管理
		{ID: 302, Name: "roles:permissions", DisplayName: "权限管理", Description: "角色权限分配管理", Resource: "roles", Action: "permissions", Scope: "all", ParentID: uintPtr(3)},
		{ID: 3021, Name: "roles:assign_permissions", DisplayName: "分配权限", Description: "为角色分配权限", Resource: "roles", Action: "assign_permissions", Scope: "all", ParentID: uintPtr(302)},
		{ID: 3022, Name: "roles:view_permissions", DisplayName: "查看权限", Description: "查看角色权限详情", Resource: "roles", Action: "view_permissions", Scope: "all", ParentID: uintPtr(302)},
		{ID: 3023, Name: "roles:copy_permissions", DisplayName: "复制权限", Description: "复制角色权限到其他角色", Resource: "roles", Action: "copy_permissions", Scope: "all", ParentID: uintPtr(302)},
		
		// 角色数据操作
		{ID: 303, Name: "roles:data", DisplayName: "角色数据操作", Description: "角色数据导入导出", Resource: "roles", Action: "data", Scope: "all", ParentID: uintPtr(3)},
		{ID: 3031, Name: "roles:import", DisplayName: "导入角色", Description: "批量导入角色数据", Resource: "roles", Action: "import", Scope: "all", ParentID: uintPtr(303)},
		{ID: 3032, Name: "roles:export", DisplayName: "导出角色", Description: "导出角色数据", Resource: "roles", Action: "export", Scope: "all", ParentID: uintPtr(303)},
	}

	// 添加更多模块权限...
	permissions = append(permissions, getRecordsPermissions()...)
	permissions = append(permissions, getFilesPermissions()...)
	permissions = append(permissions, getExportPermissions()...)
	permissions = append(permissions, getNotificationsPermissions()...)
	permissions = append(permissions, getAIPermissions()...)
	permissions = append(permissions, getDashboardPermissions()...)
	permissions = append(permissions, getAuditPermissions()...)
	permissions = append(permissions, getTicketPermissions()...)

	return permissions
}

// uintPtr 辅助函数，返回uint指针
func uintPtr(u uint) *uint {
	return &u
}

// getTicketPermissions 获取工单管理权限
func getTicketPermissions() []models.Permission {
	return []models.Permission{
		// ==================== 工单管理模块 ====================
		{ID: 11, Name: "ticket", DisplayName: "工单管理", Description: "工单管理模块总权限", Resource: "ticket", Action: "manage", Scope: "all", ParentID: nil},
		
		// 工单基础操作
		{ID: 1101, Name: "ticket:basic", DisplayName: "工单基础操作", Description: "工单基础CRUD操作", Resource: "ticket", Action: "basic", Scope: "all", ParentID: uintPtr(11)},
		{ID: 11011, Name: "ticket:read", DisplayName: "查看工单", Description: "查看工单列表和详情", Resource: "ticket", Action: "read", Scope: "all", ParentID: uintPtr(1101)},
		{ID: 11012, Name: "ticket:read:own", DisplayName: "查看自己的工单", Description: "只能查看自己创建或分配的工单", Resource: "ticket", Action: "read", Scope: "own", ParentID: uintPtr(1101)},
		{ID: 11013, Name: "ticket:read:department", DisplayName: "查看部门工单", Description: "查看本部门的工单", Resource: "ticket", Action: "read", Scope: "department", ParentID: uintPtr(1101)},
		{ID: 11014, Name: "ticket:create", DisplayName: "创建工单", Description: "创建新工单", Resource: "ticket", Action: "create", Scope: "all", ParentID: uintPtr(1101)},
		{ID: 11015, Name: "ticket:update", DisplayName: "编辑工单", Description: "编辑工单基本信息", Resource: "ticket", Action: "update", Scope: "all", ParentID: uintPtr(1101)},
		{ID: 11016, Name: "ticket:update:own", DisplayName: "编辑自己的工单", Description: "只能编辑自己创建的工单", Resource: "ticket", Action: "update", Scope: "own", ParentID: uintPtr(1101)},
		{ID: 11017, Name: "ticket:delete", DisplayName: "删除工单", Description: "删除工单", Resource: "ticket", Action: "delete", Scope: "all", ParentID: uintPtr(1101)},
		{ID: 11018, Name: "ticket:delete:own", DisplayName: "删除自己的工单", Description: "只能删除自己创建的工单", Resource: "ticket", Action: "delete", Scope: "own", ParentID: uintPtr(1101)},
		
		// 工单分配管理
		{ID: 1102, Name: "ticket:assignment", DisplayName: "工单分配管理", Description: "工单分配相关权限", Resource: "ticket", Action: "assignment", Scope: "all", ParentID: uintPtr(11)},
		{ID: 11021, Name: "ticket:assign", DisplayName: "分配工单", Description: "分配工单给其他用户", Resource: "ticket", Action: "assign", Scope: "all", ParentID: uintPtr(1102)},
		{ID: 11022, Name: "ticket:assign:department", DisplayName: "部门内分配", Description: "在部门内分配工单", Resource: "ticket", Action: "assign", Scope: "department", ParentID: uintPtr(1102)},
		{ID: 11023, Name: "ticket:reassign", DisplayName: "重新分配工单", Description: "重新分配已分配的工单", Resource: "ticket", Action: "reassign", Scope: "all", ParentID: uintPtr(1102)},
		{ID: 11024, Name: "ticket:accept", DisplayName: "接受工单", Description: "接受分配给自己的工单", Resource: "ticket", Action: "accept", Scope: "own", ParentID: uintPtr(1102)},
		{ID: 11025, Name: "ticket:reject", DisplayName: "拒绝工单", Description: "拒绝分配给自己的工单", Resource: "ticket", Action: "reject", Scope: "own", ParentID: uintPtr(1102)},
		
		// 工单状态管理
		{ID: 1103, Name: "ticket:status", DisplayName: "工单状态管理", Description: "工单状态变更权限", Resource: "ticket", Action: "status", Scope: "all", ParentID: uintPtr(11)},
		{ID: 11031, Name: "ticket:status:open", DisplayName: "打开工单", Description: "将工单状态设为打开", Resource: "ticket", Action: "status:open", Scope: "all", ParentID: uintPtr(1103)},
		{ID: 11032, Name: "ticket:status:progress", DisplayName: "开始处理", Description: "将工单状态设为处理中", Resource: "ticket", Action: "status:progress", Scope: "all", ParentID: uintPtr(1103)},
		{ID: 11033, Name: "ticket:status:pending", DisplayName: "挂起工单", Description: "将工单状态设为挂起", Resource: "ticket", Action: "status:pending", Scope: "all", ParentID: uintPtr(1103)},
		{ID: 11034, Name: "ticket:status:resolved", DisplayName: "解决工单", Description: "将工单状态设为已解决", Resource: "ticket", Action: "status:resolved", Scope: "all", ParentID: uintPtr(1103)},
		{ID: 11035, Name: "ticket:status:closed", DisplayName: "关闭工单", Description: "将工单状态设为已关闭", Resource: "ticket", Action: "status:closed", Scope: "all", ParentID: uintPtr(1103)},
		{ID: 11036, Name: "ticket:status:reopen", DisplayName: "重新打开工单", Description: "重新打开已关闭的工单", Resource: "ticket", Action: "status:reopen", Scope: "all", ParentID: uintPtr(1103)},
		
		// 工单审批管理
		{ID: 1104, Name: "ticket:approval", DisplayName: "工单审批管理", Description: "工单审批相关权限", Resource: "ticket", Action: "approval", Scope: "all", ParentID: uintPtr(11)},
		{ID: 11041, Name: "ticket:approve", DisplayName: "审批工单", Description: "审批工单请求", Resource: "ticket", Action: "approve", Scope: "all", ParentID: uintPtr(1104)},
		{ID: 11042, Name: "ticket:approve:department", DisplayName: "部门审批", Description: "审批本部门的工单", Resource: "ticket", Action: "approve", Scope: "department", ParentID: uintPtr(1104)},
		{ID: 11043, Name: "ticket:reject_approval", DisplayName: "拒绝审批", Description: "拒绝工单审批请求", Resource: "ticket", Action: "reject_approval", Scope: "all", ParentID: uintPtr(1104)},
		{ID: 11044, Name: "ticket:request_approval", DisplayName: "申请审批", Description: "为工单申请审批", Resource: "ticket", Action: "request_approval", Scope: "all", ParentID: uintPtr(1104)},
		{ID: 11045, Name: "ticket:cancel_approval", DisplayName: "取消审批", Description: "取消工单审批请求", Resource: "ticket", Action: "cancel_approval", Scope: "all", ParentID: uintPtr(1104)},
		
		// 工单优先级管理
		{ID: 1105, Name: "ticket:priority", DisplayName: "工单优先级管理", Description: "工单优先级设置权限", Resource: "ticket", Action: "priority", Scope: "all", ParentID: uintPtr(11)},
		{ID: 11051, Name: "ticket:priority:low", DisplayName: "设置低优先级", Description: "将工单设为低优先级", Resource: "ticket", Action: "priority:low", Scope: "all", ParentID: uintPtr(1105)},
		{ID: 11052, Name: "ticket:priority:normal", DisplayName: "设置普通优先级", Description: "将工单设为普通优先级", Resource: "ticket", Action: "priority:normal", Scope: "all", ParentID: uintPtr(1105)},
		{ID: 11053, Name: "ticket:priority:high", DisplayName: "设置高优先级", Description: "将工单设为高优先级", Resource: "ticket", Action: "priority:high", Scope: "all", ParentID: uintPtr(1105)},
		{ID: 11054, Name: "ticket:priority:urgent", DisplayName: "设置紧急优先级", Description: "将工单设为紧急优先级", Resource: "ticket", Action: "priority:urgent", Scope: "all", ParentID: uintPtr(1105)},
		{ID: 11055, Name: "ticket:priority:critical", DisplayName: "设置严重优先级", Description: "将工单设为严重优先级", Resource: "ticket", Action: "priority:critical", Scope: "all", ParentID: uintPtr(1105)},
		
		// 工单评论和附件
		{ID: 1106, Name: "ticket:communication", DisplayName: "工单沟通管理", Description: "工单评论和附件权限", Resource: "ticket", Action: "communication", Scope: "all", ParentID: uintPtr(11)},
		{ID: 11061, Name: "ticket:comment:read", DisplayName: "查看评论", Description: "查看工单评论", Resource: "ticket", Action: "comment:read", Scope: "all", ParentID: uintPtr(1106)},
		{ID: 11062, Name: "ticket:comment:write", DisplayName: "添加评论", Description: "为工单添加评论", Resource: "ticket", Action: "comment:write", Scope: "all", ParentID: uintPtr(1106)},
		{ID: 11063, Name: "ticket:comment:edit", DisplayName: "编辑评论", Description: "编辑工单评论", Resource: "ticket", Action: "comment:edit", Scope: "own", ParentID: uintPtr(1106)},
		{ID: 11064, Name: "ticket:comment:delete", DisplayName: "删除评论", Description: "删除工单评论", Resource: "ticket", Action: "comment:delete", Scope: "all", ParentID: uintPtr(1106)},
		{ID: 11065, Name: "ticket:attachment:upload", DisplayName: "上传附件", Description: "为工单上传附件", Resource: "ticket", Action: "attachment:upload", Scope: "all", ParentID: uintPtr(1106)},
		{ID: 11066, Name: "ticket:attachment:download", DisplayName: "下载附件", Description: "下载工单附件", Resource: "ticket", Action: "attachment:download", Scope: "all", ParentID: uintPtr(1106)},
		{ID: 11067, Name: "ticket:attachment:delete", DisplayName: "删除附件", Description: "删除工单附件", Resource: "ticket", Action: "attachment:delete", Scope: "all", ParentID: uintPtr(1106)},
		
		// 工单报表和统计
		{ID: 1107, Name: "ticket:reporting", DisplayName: "工单报表统计", Description: "工单报表和统计权限", Resource: "ticket", Action: "reporting", Scope: "all", ParentID: uintPtr(11)},
		{ID: 11071, Name: "ticket:statistics", DisplayName: "查看统计", Description: "查看工单统计数据", Resource: "ticket", Action: "statistics", Scope: "all", ParentID: uintPtr(1107)},
		{ID: 11072, Name: "ticket:report:generate", DisplayName: "生成报表", Description: "生成工单报表", Resource: "ticket", Action: "report:generate", Scope: "all", ParentID: uintPtr(1107)},
		{ID: 11073, Name: "ticket:export", DisplayName: "导出工单", Description: "导出工单数据", Resource: "ticket", Action: "export", Scope: "all", ParentID: uintPtr(1107)},
		{ID: 11074, Name: "ticket:import", DisplayName: "导入工单", Description: "批量导入工单数据", Resource: "ticket", Action: "import", Scope: "all", ParentID: uintPtr(1107)},
		
		// 工单配置管理
		{ID: 1108, Name: "ticket:config", DisplayName: "工单配置管理", Description: "工单系统配置权限", Resource: "ticket", Action: "config", Scope: "all", ParentID: uintPtr(11)},
		{ID: 11081, Name: "ticket:category:manage", DisplayName: "管理工单类型", Description: "管理工单分类和类型", Resource: "ticket", Action: "category:manage", Scope: "all", ParentID: uintPtr(1108)},
		{ID: 11082, Name: "ticket:template:manage", DisplayName: "管理工单模板", Description: "管理工单模板", Resource: "ticket", Action: "template:manage", Scope: "all", ParentID: uintPtr(1108)},
		{ID: 11083, Name: "ticket:workflow:manage", DisplayName: "管理工作流", Description: "管理工单工作流程", Resource: "ticket", Action: "workflow:manage", Scope: "all", ParentID: uintPtr(1108)},
		{ID: 11084, Name: "ticket:sla:manage", DisplayName: "管理SLA", Description: "管理服务级别协议", Resource: "ticket", Action: "sla:manage", Scope: "all", ParentID: uintPtr(1108)},
		{ID: 11085, Name: "ticket:notification:manage", DisplayName: "管理通知规则", Description: "管理工单通知规则", Resource: "ticket", Action: "notification:manage", Scope: "all", ParentID: uintPtr(1108)},
	}
}