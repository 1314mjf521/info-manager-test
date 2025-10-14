-- 初始化权限数据
-- 添加新字段到现有表（如果不存在）
ALTER TABLE roles ADD COLUMN IF NOT EXISTS display_name VARCHAR(200);
ALTER TABLE roles ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active';

ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name VARCHAR(200);
ALTER TABLE users ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active';

ALTER TABLE permissions ADD COLUMN IF NOT EXISTS name VARCHAR(100);
ALTER TABLE permissions ADD COLUMN IF NOT EXISTS display_name VARCHAR(200);
ALTER TABLE permissions ADD COLUMN IF NOT EXISTS description VARCHAR(500);
ALTER TABLE permissions ADD COLUMN IF NOT EXISTS parent_id INTEGER REFERENCES permissions(id);

-- 创建唯一索引
CREATE UNIQUE INDEX IF NOT EXISTS idx_permissions_name ON permissions(name);

-- 插入系统权限数据
INSERT INTO permissions (name, display_name, description, resource, action, scope, parent_id) VALUES
-- 系统管理
('system', '系统管理', '系统管理相关权限', 'system', 'manage', 'all', NULL),
('system:admin', '系统管理员', '系统管理员权限', 'system', 'admin', 'all', (SELECT id FROM permissions WHERE name = 'system')),
('system:config', '系统配置', '系统配置管理权限', 'system', 'config', 'all', (SELECT id FROM permissions WHERE name = 'system')),

-- 用户管理
('users', '用户管理', '用户管理相关权限', 'users', 'manage', 'all', NULL),
('users:read', '查看用户', '查看用户列表和详情', 'users', 'read', 'all', (SELECT id FROM permissions WHERE name = 'users')),
('users:write', '编辑用户', '创建和编辑用户', 'users', 'write', 'all', (SELECT id FROM permissions WHERE name = 'users')),
('users:delete', '删除用户', '删除用户账号', 'users', 'delete', 'all', (SELECT id FROM permissions WHERE name = 'users')),

-- 角色管理
('roles', '角色管理', '角色管理相关权限', 'roles', 'manage', 'all', NULL),
('roles:read', '查看角色', '查看角色列表和详情', 'roles', 'read', 'all', (SELECT id FROM permissions WHERE name = 'roles')),
('roles:write', '编辑角色', '创建和编辑角色', 'roles', 'write', 'all', (SELECT id FROM permissions WHERE name = 'roles')),
('roles:delete', '删除角色', '删除角色', 'roles', 'delete', 'all', (SELECT id FROM permissions WHERE name = 'roles')),
('roles:assign', '分配权限', '为角色分配权限', 'roles', 'assign', 'all', (SELECT id FROM permissions WHERE name = 'roles')),

-- 记录管理
('records', '记录管理', '记录管理相关权限', 'records', 'manage', 'all', NULL),
('records:read', '查看记录', '查看记录列表和详情', 'records', 'read', 'all', (SELECT id FROM permissions WHERE name = 'records')),
('records:read:own', '查看自己的记录', '只能查看自己创建的记录', 'records', 'read', 'own', (SELECT id FROM permissions WHERE name = 'records')),
('records:write', '编辑记录', '创建和编辑记录', 'records', 'write', 'all', (SELECT id FROM permissions WHERE name = 'records')),
('records:write:own', '编辑自己的记录', '只能编辑自己创建的记录', 'records', 'write', 'own', (SELECT id FROM permissions WHERE name = 'records')),
('records:delete', '删除记录', '删除记录数据', 'records', 'delete', 'all', (SELECT id FROM permissions WHERE name = 'records')),
('records:delete:own', '删除自己的记录', '只能删除自己创建的记录', 'records', 'delete', 'own', (SELECT id FROM permissions WHERE name = 'records')),

-- 文件管理
('files', '文件管理', '文件管理相关权限', 'files', 'manage', 'all', NULL),
('files:read', '查看文件', '查看和下载文件', 'files', 'read', 'all', (SELECT id FROM permissions WHERE name = 'files')),
('files:upload', '上传文件', '上传文件', 'files', 'upload', 'all', (SELECT id FROM permissions WHERE name = 'files')),
('files:write', '编辑文件', '编辑文件信息', 'files', 'write', 'all', (SELECT id FROM permissions WHERE name = 'files')),
('files:delete', '删除文件', '删除文件数据', 'files', 'delete', 'all', (SELECT id FROM permissions WHERE name = 'files')),
('files:share', '分享文件', '分享文件给其他用户', 'files', 'share', 'all', (SELECT id FROM permissions WHERE name = 'files')),

-- 导出功能
('export', '数据导出', '数据导出相关权限', 'export', 'manage', 'all', NULL),
('export:records', '导出记录', '导出记录数据', 'export', 'records', 'all', (SELECT id FROM permissions WHERE name = 'export')),
('export:users', '导出用户', '导出用户数据', 'export', 'users', 'all', (SELECT id FROM permissions WHERE name = 'export')),

-- AI功能
('ai', 'AI功能', 'AI相关功能权限', 'ai', 'manage', 'all', NULL),
('ai:chat', 'AI聊天', '使用AI聊天功能', 'ai', 'chat', 'all', (SELECT id FROM permissions WHERE name = 'ai')),
('ai:ocr', 'OCR识别', '使用OCR文字识别功能', 'ai', 'ocr', 'all', (SELECT id FROM permissions WHERE name = 'ai')),
('ai:speech', '语音识别', '使用语音识别功能', 'ai', 'speech', 'all', (SELECT id FROM permissions WHERE name = 'ai'))

ON CONFLICT (name) DO NOTHING;

-- 更新现有角色的显示名称
UPDATE roles SET display_name = '管理员' WHERE name = 'admin' AND display_name IS NULL;
UPDATE roles SET display_name = '用户' WHERE name = 'user' AND display_name IS NULL;
UPDATE roles SET display_name = '访客' WHERE name = 'guest' AND display_name IS NULL;

-- 更新现有用户的显示名称（如果为空）
UPDATE users SET display_name = username WHERE display_name IS NULL OR display_name = '';