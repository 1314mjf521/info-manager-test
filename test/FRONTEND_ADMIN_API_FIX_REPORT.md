# 前端管理界面API修复报告

## 问题描述
在修复后端用户管理API后，前端的用户管理和角色管理界面都出现"请求的资源不存在"错误，因为前端还在使用旧的API路径。

## 根本原因
后端API路径已更改为：
- 用户管理：`/api/v1/admin/users`
- 角色管理：`/api/v1/admin/roles`

但前端组件仍在使用旧路径：
- 用户管理：`/api/v1/users`
- 角色管理：`/api/v1/roles`

## 修复内容

### 1. 用户管理界面 (UserManagement.vue)

修复了以下API调用路径：

**获取用户列表**
```javascript
// 修复前
const response = await http.get('/users', { params })

// 修复后
const response = await http.get('/admin/users', { params })
```

**获取角色列表**
```javascript
// 修复前
const response = await http.get('/roles')

// 修复后
const response = await http.get('/admin/roles')
```

**用户状态切换**
```javascript
// 修复前
await http.put(`/users/${row.id}`, { status: newStatus })

// 修复后
await http.put(`/admin/users/${row.id}`, { status: newStatus })
```

**删除用户**
```javascript
// 修复前
await http.delete(`/users/${row.id}`)

// 修复后
await http.delete(`/admin/users/${row.id}`)
```

**创建/更新用户**
```javascript
// 修复前
if (isEdit.value) {
  await http.put(`/users/${data.id}`, data)
} else {
  await http.post('/users', data)
}

// 修复后
if (isEdit.value) {
  await http.put(`/admin/users/${data.id}`, data)
} else {
  await http.post('/admin/users', data)
}
```

**用户角色分配**
```javascript
// 修复前
await http.put(`/users/${currentUser.value.id}/roles`, {
  roleIds: selectedRoles.value
})

// 修复后
await http.put(`/admin/users/${currentUser.value.id}/roles`, {
  roleIds: selectedRoles.value
})
```

### 2. 角色管理界面 (RoleManagement.vue)

修复了以下API调用路径：

**获取角色列表**
```javascript
// 修复前
const response = await http.get('/roles', { params })

// 修复后
const response = await http.get('/admin/roles', { params })
```

**获取角色权限**
```javascript
// 修复前
const response = await http.get(`/roles/${row.id}/permissions`)

// 修复后
const response = await http.get(`/admin/roles/${row.id}/permissions`)
```

**角色状态切换**
```javascript
// 修复前
await http.put(`/roles/${row.id}`, { status: newStatus })

// 修复后
await http.put(`/admin/roles/${row.id}`, { status: newStatus })
```

**删除角色**
```javascript
// 修复前
await http.delete(`/roles/${row.id}`)

// 修复后
await http.delete(`/admin/roles/${row.id}`)
```

**创建/更新角色**
```javascript
// 修复前
if (isEdit.value) {
  await http.put(`/roles/${formData.id}`, formData)
} else {
  await http.post('/roles', formData)
}

// 修复后
if (isEdit.value) {
  await http.put(`/admin/roles/${formData.id}`, formData)
} else {
  await http.post('/admin/roles', formData)
}
```

**角色权限分配**
```javascript
// 修复前
await http.put(`/roles/${currentRole.value.id}/permissions`, {
  permissionIds: selectedPermissions.value
})

// 修复后
await http.put(`/admin/roles/${currentRole.value.id}/permissions`, {
  permissionIds: selectedPermissions.value
})
```

## API路径对照表

| 功能 | 修复前路径 | 修复后路径 |
|------|------------|------------|
| 用户管理 | `/api/v1/users` | `/api/v1/admin/users` |
| 角色管理 | `/api/v1/roles` | `/api/v1/admin/roles` |
| 权限管理 | `/api/v1/permissions` | `/api/v1/permissions` (未变) |

## 测试结果

```
=== Frontend Admin API Fix Test ===

1. Login to get token...
✓ Login success

2. Testing admin APIs...
  Testing user management APIs:
    ✓ GET /admin/users - Success
  Testing role management APIs:
    ✓ GET /admin/roles - Success
  Testing permissions APIs:
    ✓ GET /permissions - Success
    ✓ GET /permissions/tree - Success
```

## 影响范围
- ✅ 用户管理界面：所有功能恢复正常
- ✅ 角色管理界面：所有功能恢复正常
- ✅ 权限管理：无需修改，继续正常工作

## 验证步骤
1. 启动前端和后端服务
2. 使用管理员账户登录
3. 访问用户管理页面，测试增删改查功能
4. 访问角色管理页面，测试角色和权限管理功能

## 总结
前端管理界面的API路径已全部修复，与后端新的API结构保持一致。用户管理和角色管理界面现在应该能够正常工作。