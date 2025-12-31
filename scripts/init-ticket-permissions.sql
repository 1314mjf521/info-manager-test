-- 工单管理权限初始化脚本
-- 创建工单相关权限

-- 插入工单权限
INSERT INTO permissions (name, display_name, description, resource, action, scope, created_at, updated_at) VALUES
-- 工单基础权限
('ticket:view', '查看工单', '查看工单列表和详情', 'ticket', 'view', 'all', NOW(), NOW()),
('ticket:create', '创建工单', '创建新工单', 'ticket', 'create', 'all', NOW(), NOW()),
('ticket:edit', '编辑工单', '编辑工单信息', 'ticket', 'edit', 'own', NOW(), NOW()),
('ticket:delete', '删除工单', '删除工单', 'ticket', 'delete', 'own', NOW(), NOW()),

-- 工单管理权限
('ticket:view_all', '查看所有工单', '查看所有用户的工单', 'ticket', 'view', 'all', NOW(), NOW()),
('ticket:edit_all', '编辑所有工单', '编辑所有用户的工单', 'ticket', 'edit', 'all', NOW(), NOW()),
('ticket:assign', '分配工单', '分配工单给其他用户', 'ticket', 'assign', 'all', NOW(), NOW()),
('ticket:status_all', '更新所有工单状态', '更新任何工单的状态', 'ticket', 'status', 'all', NOW(), NOW()),

-- 工单评论权限
('ticket:comment', '添加工单评论', '在工单中添加评论', 'ticket', 'comment', 'all', NOW(), NOW()),
('ticket:comment_view', '查看工单评论', '查看工单评论', 'ticket', 'comment_view', 'all', NOW(), NOW()),

-- 工单附件权限
('ticket:attachment_upload', '上传工单附件', '上传工单附件', 'ticket', 'attachment_upload', 'all', NOW(), NOW()),
('ticket:attachment_download', '下载工单附件', '下载工单附件', 'ticket', 'attachment_download', 'all', NOW(), NOW()),
('ticket:delete_attachment', '删除工单附件', '删除工单附件', 'ticket', 'delete_attachment', 'all', NOW(), NOW()),

-- 工单统计权限
('ticket:statistics', '查看工单统计', '查看工单统计数据', 'ticket', 'statistics', 'all', NOW(), NOW())

ON DUPLICATE KEY UPDATE
display_name = VALUES(display_name),
description = VALUES(description),
updated_at = NOW();

-- 为管理员角色分配所有工单权限
INSERT INTO role_permissions (role_id, permission_id, created_at, updated_at)
SELECT r.id, p.id, NOW(), NOW()
FROM roles r, permissions p 
WHERE r.name = 'admin' AND p.name LIKE 'ticket:%'
ON DUPLICATE KEY UPDATE updated_at = NOW();

-- 为普通用户角色分配基础工单权限
INSERT INTO role_permissions (role_id, permission_id, created_at, updated_at)
SELECT r.id, p.id, NOW(), NOW()
FROM roles r, permissions p 
WHERE r.name = 'user' AND p.name IN (
    'ticket:view', 
    'ticket:create', 
    'ticket:edit', 
    'ticket:comment', 
    'ticket:comment_view',
    'ticket:attachment_upload',
    'ticket:attachment_download'
)
ON DUPLICATE KEY UPDATE updated_at = NOW();

-- 为查看者角色分配只读工单权限
INSERT INTO role_permissions (role_id, permission_id, created_at, updated_at)
SELECT r.id, p.id, NOW(), NOW()
FROM roles r, permissions p 
WHERE r.name = 'viewer' AND p.name IN (
    'ticket:view', 
    'ticket:comment_view',
    'ticket:attachment_download'
)
ON DUPLICATE KEY UPDATE updated_at = NOW();