-- 优化的权限初始化脚本
-- 删除现有权限数据
DELETE FROM role_permissions;
DELETE FROM permissions;

-- 重置自增ID
DELETE FROM sqlite_sequence WHERE name='permissions';

-- 插入优化的权限树结构
INSERT INTO permissions (id, name, display_name, description, resource, action, scope, parent_id, created_at, updated_at) VALUES

-- 1. 系统管理 (根权限)
(1, 'system', '系统管理', '系统级别的管理权限', 'system', 'manage', 'all', NULL, datetime('now'), datetime('now')),
  -- 1.1 系统配置
  (2, 'system:config', '系统配置', '系统配置管理权限', 'system', 'config', 'all', 1, datetime('now'), datetime('now')),
    (3, 'system:config:read', '查看系统配置', '查看系统配置信息', 'system', 'config_read', 'all', 2, datetime('now'), datetime('now')),
    (4, 'system:config:write', '修改系统配置', '修改系统配置信息', 'system', 'config_write', 'all', 2, datetime('now'), datetime('now')),
  -- 1.2 系统监控
  (5, 'system:monitor', '系统监控', '系统监控相关权限', 'system', 'monitor', 'all', 1, datetime('now'), datetime('now')),
    (6, 'system:monitor:health', '健康检查', '查看系统健康状态', 'system', 'health', 'all', 5, datetime('now'), datetime('now')),
    (7, 'system:monitor:metrics', '系统指标', '查看系统性能指标', 'system', 'metrics', 'all', 5, datetime('now'), datetime('now')),
    (8, 'system:monitor:logs', '系统日志', '查看和管理系统日志', 'system', 'logs', 'all', 5, datetime('now'), datetime('now')),

-- 2. 用户管理 (根权限)
(10, 'users', '用户管理', '用户相关的管理权限', 'users', 'manage', 'all', NULL, datetime('now'), datetime('now')),
  -- 2.1 用户基本操作
  (11, 'users:read', '查看用户', '查看用户信息', 'users', 'read', 'all', 10, datetime('now'), datetime('now')),
    (12, 'users:read:list', '用户列表', '查看用户列表', 'users', 'list', 'all', 11, datetime('now'), datetime('now')),
    (13, 'users:read:detail', '用户详情', '查看用户详细信息', 'users', 'detail', 'all', 11, datetime('now'), datetime('now')),
    (14, 'users:read:profile', '个人资料', '查看个人资料', 'users', 'profile', 'own', 11, datetime('now'), datetime('now')),
  -- 2.2 用户写操作
  (15, 'users:write', '用户写操作', '用户创建、修改、删除权限', 'users', 'write', 'all', 10, datetime('now'), datetime('now')),
    (16, 'users:write:create', '创建用户', '创建新用户', 'users', 'create', 'all', 15, datetime('now'), datetime('now')),
    (17, 'users:write:update', '修改用户', '修改用户信息', 'users', 'update', 'all', 15, datetime('now'), datetime('now')),
    (18, 'users:write:delete', '删除用户', '删除用户', 'users', 'delete', 'all', 15, datetime('now'), datetime('now')),
    (19, 'users:write:password', '重置密码', '重置用户密码', 'users', 'reset_password', 'all', 15, datetime('now'), datetime('now')),
  -- 2.3 用户角色管理
  (20, 'users:roles', '用户角色', '管理用户角色分配', 'users', 'roles', 'all', 10, datetime('now'), datetime('now')),
    (21, 'users:roles:assign', '分配角色', '为用户分配角色', 'users', 'assign_roles', 'all', 20, datetime('now'), datetime('now')),
    (22, 'users:roles:revoke', '撤销角色', '撤销用户角色', 'users', 'revoke_roles', 'all', 20, datetime('now'), datetime('now')),

-- 3. 角色管理 (根权限)
(30, 'roles', '角色管理', '角色相关的管理权限', 'roles', 'manage', 'all', NULL, datetime('now'), datetime('now')),
  -- 3.1 角色基本操作
  (31, 'roles:read', '查看角色', '查看角色信息', 'roles', 'read', 'all', 30, datetime('now'), datetime('now')),
    (32, 'roles:read:list', '角色列表', '查看角色列表', 'roles', 'list', 'all', 31, datetime('now'), datetime('now')),
    (33, 'roles:read:detail', '角色详情', '查看角色详细信息', 'roles', 'detail', 'all', 31, datetime('now'), datetime('now')),
  -- 3.2 角色写操作
  (34, 'roles:write', '角色写操作', '角色创建、修改、删除权限', 'roles', 'write', 'all', 30, datetime('now'), datetime('now')),
    (35, 'roles:write:create', '创建角色', '创建新角色', 'roles', 'create', 'all', 34, datetime('now'), datetime('now')),
    (36, 'roles:write:update', '修改角色', '修改角色信息', 'roles', 'update', 'all', 34, datetime('now'), datetime('now')),
    (37, 'roles:write:delete', '删除角色', '删除角色', 'roles', 'delete', 'all', 34, datetime('now'), datetime('now')),
  -- 3.3 角色权限管理
  (38, 'roles:permissions', '角色权限', '管理角色权限分配', 'roles', 'permissions', 'all', 30, datetime('now'), datetime('now')),
    (39, 'roles:permissions:assign', '分配权限', '为角色分配权限', 'roles', 'assign_permissions', 'all', 38, datetime('now'), datetime('now')),
    (40, 'roles:permissions:revoke', '撤销权限', '撤销角色权限', 'roles', 'revoke_permissions', 'all', 38, datetime('now'), datetime('now')),

-- 4. 权限管理 (根权限)
(50, 'permissions', '权限管理', '权限相关的管理权限', 'permissions', 'manage', 'all', NULL, datetime('now'), datetime('now')),
  -- 4.1 权限查看
  (51, 'permissions:read', '查看权限', '查看权限信息', 'permissions', 'read', 'all', 50, datetime('now'), datetime('now')),
    (52, 'permissions:read:list', '权限列表', '查看权限列表', 'permissions', 'list', 'all', 51, datetime('now'), datetime('now')),
    (53, 'permissions:read:tree', '权限树', '查看权限树结构', 'permissions', 'tree', 'all', 51, datetime('now'), datetime('now')),
  -- 4.2 权限管理
  (54, 'permissions:write', '权限写操作', '权限创建、修改、删除', 'permissions', 'write', 'all', 50, datetime('now'), datetime('now')),
    (55, 'permissions:write:create', '创建权限', '创建新权限', 'permissions', 'create', 'all', 54, datetime('now'), datetime('now')),
    (56, 'permissions:write:update', '修改权限', '修改权限信息', 'permissions', 'update', 'all', 54, datetime('now'), datetime('now')),
    (57, 'permissions:write:delete', '删除权限', '删除权限', 'permissions', 'delete', 'all', 54, datetime('now'), datetime('now')),
    (58, 'permissions:write:initialize', '初始化权限', '重新初始化系统权限', 'permissions', 'initialize', 'all', 54, datetime('now'), datetime('now')),

-- 5. 工单管理 (根权限)
(70, 'tickets', '工单管理', '工单系统相关权限', 'tickets', 'manage', 'all', NULL, datetime('now'), datetime('now')),
  -- 5.1 工单查看
  (71, 'tickets:read', '查看工单', '查看工单信息', 'tickets', 'read', 'all', 70, datetime('now'), datetime('now')),
    (72, 'tickets:read:list', '工单列表', '查看工单列表', 'tickets', 'list', 'all', 71, datetime('now'), datetime('now')),
    (73, 'tickets:read:detail', '工单详情', '查看工单详细信息', 'tickets', 'detail', 'all', 71, datetime('now'), datetime('now')),
    (74, 'tickets:read:own', '查看自己的工单', '只能查看自己创建或分配的工单', 'tickets', 'read_own', 'own', 71, datetime('now'), datetime('now')),
    (75, 'tickets:read:all', '查看所有工单', '查看系统中所有工单', 'tickets', 'read_all', 'all', 71, datetime('now'), datetime('now')),
  -- 5.2 工单创建和编辑
  (76, 'tickets:write', '工单写操作', '工单创建、修改、删除权限', 'tickets', 'write', 'all', 70, datetime('now'), datetime('now')),
    (77, 'tickets:write:create', '创建工单', '创建新工单', 'tickets', 'create', 'all', 76, datetime('now'), datetime('now')),
    (78, 'tickets:write:update', '修改工单', '修改工单信息', 'tickets', 'update', 'all', 76, datetime('now'), datetime('now')),
    (79, 'tickets:write:delete', '删除工单', '删除工单', 'tickets', 'delete', 'all', 76, datetime('now'), datetime('now')),
  -- 5.3 工单流程管理
  (80, 'tickets:workflow', '工单流程', '工单流程相关权限', 'tickets', 'workflow', 'all', 70, datetime('now'), datetime('now')),
    (81, 'tickets:workflow:assign', '分配工单', '分配工单给处理人', 'tickets', 'assign', 'all', 80, datetime('now'), datetime('now')),
    (82, 'tickets:workflow:approve', '审批工单', '审批或拒绝工单', 'tickets', 'approve', 'all', 80, datetime('now'), datetime('now')),
    (83, 'tickets:workflow:status', '更新状态', '更新工单状态', 'tickets', 'status', 'all', 80, datetime('now'), datetime('now')),
    (84, 'tickets:workflow:close', '关闭工单', '关闭已完成的工单', 'tickets', 'close', 'all', 80, datetime('now'), datetime('now')),
  -- 5.4 工单评论和附件
  (85, 'tickets:interact', '工单交互', '工单评论和附件相关权限', 'tickets', 'interact', 'all', 70, datetime('now'), datetime('now')),
    (86, 'tickets:interact:comment', '添加评论', '为工单添加评论', 'tickets', 'comment', 'all', 85, datetime('now'), datetime('now')),
    (87, 'tickets:interact:attachment', '管理附件', '上传和删除工单附件', 'tickets', 'attachment', 'all', 85, datetime('now'), datetime('now')),
  -- 5.5 工单统计和报告
  (88, 'tickets:analytics', '工单分析', '工单统计和分析权限', 'tickets', 'analytics', 'all', 70, datetime('now'), datetime('now')),
    (89, 'tickets:analytics:stats', '工单统计', '查看工单统计数据', 'tickets', 'statistics', 'all', 88, datetime('now'), datetime('now')),
    (90, 'tickets:analytics:reports', '工单报告', '生成工单报告', 'tickets', 'reports', 'all', 88, datetime('now'), datetime('now')),

-- 6. 记录管理 (根权限)
(100, 'records', '记录管理', '记录相关的管理权限', 'records', 'manage', 'all', NULL, datetime('now'), datetime('now')),
  -- 6.1 记录查看
  (101, 'records:read', '查看记录', '查看记录信息', 'records', 'read', 'all', 100, datetime('now'), datetime('now')),
    (102, 'records:read:list', '记录列表', '查看记录列表', 'records', 'list', 'all', 101, datetime('now'), datetime('now')),
    (103, 'records:read:detail', '记录详情', '查看记录详细信息', 'records', 'detail', 'all', 101, datetime('now'), datetime('now')),
  -- 6.2 记录写操作
  (104, 'records:write', '记录写操作', '记录创建、修改、删除权限', 'records', 'write', 'all', 100, datetime('now'), datetime('now')),
    (105, 'records:write:create', '创建记录', '创建新记录', 'records', 'create', 'all', 104, datetime('now'), datetime('now')),
    (106, 'records:write:update', '修改记录', '修改记录信息', 'records', 'update', 'all', 104, datetime('now'), datetime('now')),
    (107, 'records:write:delete', '删除记录', '删除记录', 'records', 'delete', 'all', 104, datetime('now'), datetime('now')),
  -- 6.3 记录类型管理
  (108, 'records:types', '记录类型', '记录类型管理权限', 'records', 'types', 'all', 100, datetime('now'), datetime('now')),
    (109, 'records:types:manage', '管理记录类型', '创建、修改、删除记录类型', 'records', 'manage_types', 'all', 108, datetime('now'), datetime('now')),

-- 7. 文件管理 (根权限)
(120, 'files', '文件管理', '文件相关的管理权限', 'files', 'manage', 'all', NULL, datetime('now'), datetime('now')),
  -- 7.1 文件基本操作
  (121, 'files:read', '查看文件', '查看文件信息', 'files', 'read', 'all', 120, datetime('now'), datetime('now')),
    (122, 'files:read:list', '文件列表', '查看文件列表', 'files', 'list', 'all', 121, datetime('now'), datetime('now')),
    (123, 'files:read:download', '下载文件', '下载文件', 'files', 'download', 'all', 121, datetime('now'), datetime('now')),
  -- 7.2 文件写操作
  (124, 'files:write', '文件写操作', '文件上传、删除权限', 'files', 'write', 'all', 120, datetime('now'), datetime('now')),
    (125, 'files:write:upload', '上传文件', '上传新文件', 'files', 'upload', 'all', 124, datetime('now'), datetime('now')),
    (126, 'files:write:delete', '删除文件', '删除文件', 'files', 'delete', 'all', 124, datetime('now'), datetime('now')),
  -- 7.3 OCR功能
  (127, 'files:ocr', 'OCR识别', '文字识别相关权限', 'files', 'ocr', 'all', 120, datetime('now'), datetime('now')),

-- 8. 数据导出 (根权限)
(140, 'export', '数据导出', '数据导出相关权限', 'export', 'manage', 'all', NULL, datetime('now'), datetime('now')),
  -- 8.1 导出操作
  (141, 'export:execute', '执行导出', '执行数据导出操作', 'export', 'execute', 'all', 140, datetime('now'), datetime('now')),
  -- 8.2 导出模板管理
  (142, 'export:templates', '导出模板', '管理导出模板', 'export', 'templates', 'all', 140, datetime('now'), datetime('now')),
    (143, 'export:templates:create', '创建模板', '创建导出模板', 'export', 'create_template', 'all', 142, datetime('now'), datetime('now')),
    (144, 'export:templates:update', '修改模板', '修改导出模板', 'export', 'update_template', 'all', 142, datetime('now'), datetime('now')),
    (145, 'export:templates:delete', '删除模板', '删除导出模板', 'export', 'delete_template', 'all', 142, datetime('now'), datetime('now')),

-- 9. 通知管理 (根权限)
(160, 'notifications', '通知管理', '通知相关的管理权限', 'notifications', 'manage', 'all', NULL, datetime('now'), datetime('now')),
  -- 9.1 通知查看
  (161, 'notifications:read', '查看通知', '查看通知信息', 'notifications', 'read', 'all', 160, datetime('now'), datetime('now')),
  -- 9.2 通知发送
  (162, 'notifications:send', '发送通知', '发送通知消息', 'notifications', 'send', 'all', 160, datetime('now'), datetime('now')),
  -- 9.3 通知模板管理
  (163, 'notifications:templates', '通知模板', '管理通知模板', 'notifications', 'templates', 'all', 160, datetime('now'), datetime('now')),
  -- 9.4 通知渠道管理
  (164, 'notifications:channels', '通知渠道', '管理通知渠道', 'notifications', 'channels', 'all', 160, datetime('now'), datetime('now')),

-- 10. 审计日志 (根权限)
(180, 'audit', '审计日志', '审计日志相关权限', 'audit', 'manage', 'all', NULL, datetime('now'), datetime('now')),
  -- 10.1 审计查看
  (181, 'audit:read', '查看审计日志', '查看审计日志信息', 'audit', 'read', 'all', 180, datetime('now'), datetime('now')),
    (182, 'audit:read:logs', '审计日志列表', '查看审计日志列表', 'audit', 'logs', 'all', 181, datetime('now'), datetime('now')),
    (183, 'audit:read:stats', '审计统计', '查看审计统计信息', 'audit', 'statistics', 'all', 181, datetime('now'), datetime('now')),
  -- 10.2 审计管理
  (184, 'audit:manage', '审计管理', '审计日志管理权限', 'audit', 'manage_logs', 'all', 180, datetime('now'), datetime('now')),
    (185, 'audit:manage:cleanup', '清理日志', '清理旧的审计日志', 'audit', 'cleanup', 'all', 184, datetime('now'), datetime('now')),

-- 11. 仪表盘 (根权限)
(200, 'dashboard', '仪表盘', '仪表盘相关权限', 'dashboard', 'manage', 'all', NULL, datetime('now'), datetime('now')),
  -- 11.1 仪表盘查看
  (201, 'dashboard:read', '查看仪表盘', '查看仪表盘信息', 'dashboard', 'read', 'all', 200, datetime('now'), datetime('now')),
    (202, 'dashboard:read:stats', '统计数据', '查看统计数据', 'dashboard', 'stats', 'all', 201, datetime('now'), datetime('now')),
    (203, 'dashboard:read:charts', '图表数据', '查看图表数据', 'dashboard', 'charts', 'all', 201, datetime('now'), datetime('now')),
    (204, 'dashboard:read:system', '系统信息', '查看系统信息', 'dashboard', 'system_info', 'all', 201, datetime('now'), datetime('now')),

-- 12. AI功能 (根权限)
(220, 'ai', 'AI功能', 'AI相关功能权限', 'ai', 'manage', 'all', NULL, datetime('now'), datetime('now')),
  -- 12.1 AI使用
  (221, 'ai:use', '使用AI功能', '使用AI相关功能', 'ai', 'use', 'all', 220, datetime('now'), datetime('now')),
    (222, 'ai:use:chat', 'AI对话', '使用AI对话功能', 'ai', 'chat', 'all', 221, datetime('now'), datetime('now')),
    (223, 'ai:use:optimize', '内容优化', '使用AI优化内容', 'ai', 'optimize', 'all', 221, datetime('now'), datetime('now')),
    (224, 'ai:use:speech', '语音识别', '使用AI语音识别', 'ai', 'speech', 'all', 221, datetime('now'), datetime('now')),
  -- 12.2 AI配置管理
  (225, 'ai:config', 'AI配置', '管理AI配置', 'ai', 'config', 'all', 220, datetime('now'), datetime('now')),
    (226, 'ai:config:create', '创建配置', '创建AI配置', 'ai', 'create_config', 'all', 225, datetime('now'), datetime('now')),
    (227, 'ai:config:update', '修改配置', '修改AI配置', 'ai', 'update_config', 'all', 225, datetime('now'), datetime('now')),
    (228, 'ai:config:delete', '删除配置', '删除AI配置', 'ai', 'delete_config', 'all', 225, datetime('now'), datetime('now'));

-- 为管理员角色分配所有权限
INSERT INTO role_permissions (role_id, permission_id, created_at)
SELECT 1, id, datetime('now')
FROM permissions
WHERE NOT EXISTS (
    SELECT 1 FROM role_permissions 
    WHERE role_id = 1 AND permission_id = permissions.id
);