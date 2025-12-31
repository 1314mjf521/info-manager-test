# 权限分配问题修复指南

## 问题描述
在角色权限分配时出现"分配权限失败"错误，原因是前端使用模拟权限数据（数字ID），但数据库中实际权限使用字符串ID。

## 修复步骤

### 1. 初始化数据库权限数据

**方法一：使用MySQL命令行**
```bash
mysql -u root -p123456 info_manager < scripts/check-and-init-permissions.sql
```

**方法二：使用MySQL工具**
1. 打开MySQL Workbench、phpMyAdmin或其他MySQL管理工具
2. 连接到数据库 `info_manager`
3. 执行文件 `scripts/check-and-init-permissions.sql`

**方法三：手动执行SQL**
```sql
-- 检查现有权限
SELECT COUNT(*) FROM permissions WHERE resource = 'ticket';

-- 如果结果为0，执行以下插入语句
INSERT IGNORE INTO permissions (name, display_name, description, resource, action, scope, created_at, updated_at) VALUES
('ticket:view', '查看工单', '查看工单列表和详情', 'ticket', 'view', 'own', NOW(), NOW()),
('ticket:view_all', '查看所有工单', '查看所有用户的工单', 'ticket', 'view', 'all', NOW(), NOW()),
('ticket:create', '创建工单', '创建新工单', 'ticket', 'create', 'all', NOW(), NOW()),
('ticket:edit', '编辑工单', '编辑工单信息', 'ticket', 'edit', 'own', NOW(), NOW()),
('ticket:edit_all', '编辑所有工单', '编辑所有用户的工单', 'ticket', 'edit', 'all', NOW(), NOW()),
('ticket:delete', '删除工单', '删除工单', 'ticket', 'delete', 'own', NOW(), NOW()),
('ticket:assign', '分配工单', '分配工单给其他用户', 'ticket', 'assign', 'all', NOW(), NOW()),
('ticket:status_all', '更新所有工单状态', '更新任何工单的状态', 'ticket', 'status', 'all', NOW(), NOW()),
('ticket:approve', '审批工单', '审批工单，将状态从已分派改为已审批', 'ticket', 'approve', 'all', NOW(), NOW()),
('ticket:comment', '添加工单评论', '在工单中添加评论', 'ticket', 'comment', 'all', NOW(), NOW()),
('ticket:comment_view', '查看工单评论', '查看工单评论', 'ticket', 'comment_view', 'all', NOW(), NOW()),
('ticket:attachment_upload', '上传工单附件', '上传工单附件', 'ticket', 'attachment_upload', 'all', NOW(), NOW()),
('ticket:attachment_download', '下载工单附件', '下载工单附件', 'ticket', 'attachment_download', 'all', NOW(), NOW()),
('ticket:delete_attachment', '删除工单附件', '删除工单附件', 'ticket', 'delete_attachment', 'all', NOW(), NOW()),
('ticket:statistics', '查看工单统计', '查看工单统计数据', 'ticket', 'statistics', 'all', NOW(), NOW());
```

### 2. 修复前端语法错误

前端文件 `frontend/src/views/admin/RoleManagement.vue` 存在语法错误。

**临时解决方案：**
在 `vite.config.ts` 中添加以下配置来禁用错误覆盖：
```typescript
export default defineConfig({
  // ... 其他配置
  server: {
    hmr: {
      overlay: false
    }
  }
})
```

### 3. 重启服务

1. 重启后端服务（如果使用 `rebuild-and-start.bat`，重新运行该脚本）
2. 重启前端服务（如果前端语法错误已修复）

### 4. 测试权限分配

1. 访问角色管理页面：`http://localhost:5173/admin/roles`
2. 点击任意角色的"权限"按钮
3. 在权限树中找到"工单系统"模块
4. 选择需要的工单权限
5. 点击"保存权限"按钮
6. 检查是否成功保存

## 验证步骤

### 检查数据库权限数据
```sql
-- 查看工单权限
SELECT id, name, display_name FROM permissions WHERE resource = 'ticket';

-- 查看角色权限分配
SELECT r.name as role_name, p.name as permission_name, p.display_name 
FROM role_permissions rp 
JOIN roles r ON rp.role_id = r.id 
JOIN permissions p ON rp.permission_id = p.id 
WHERE p.resource = 'ticket';
```

### 检查前端权限加载
1. 打开浏览器开发者工具
2. 访问角色管理页面
3. 检查网络请求 `/api/v1/permissions` 和 `/api/v1/permissions/tree`
4. 确认返回的权限数据包含工单权限

## 常见问题

### Q: 权限分配仍然失败
A: 检查以下几点：
- 数据库中是否有工单权限数据
- 后端服务是否正常运行
- 前端是否正确加载权限数据

### Q: 前端无法访问
A: 修复语法错误或使用临时解决方案禁用错误覆盖

### Q: 选择权限时自动选择全部
A: 这个问题已修复，设置了 `check-strictly="true"` 允许独立选择权限

## 修复完成标志

- ✅ 数据库中有工单权限数据
- ✅ 前端可以正常访问
- ✅ 角色权限分配页面可以打开
- ✅ 可以看到工单系统权限模块
- ✅ 可以独立选择单个权限
- ✅ 权限保存成功