import request from '../utils/request'

export interface UserQuery {
  page?: number
  size?: number
  username?: string
  email?: string
  status?: string
  role_id?: number
}

export interface CreateUserData {
  username: string
  email: string
  password: string
  display_name?: string
  status?: string
}

export interface UpdateUserData {
  username?: string
  email?: string
  display_name?: string
  status?: string
}

export interface UserRoleData {
  role_ids: number[]
}

export const userApi = {
  // 获取用户列表
  getUsers(params: UserQuery) {
    return request.get('/users', { params })
  },

  // 获取用户详情
  getUser(id: number) {
    return request.get(`/users/${id}`)
  },

  // 创建用户
  createUser(data: CreateUserData) {
    return request.post('/admin/users', data)
  },

  // 更新用户
  updateUser(id: number, data: UpdateUserData) {
    return request.put(`/admin/users/${id}`, data)
  },

  // 删除用户
  deleteUser(id: number) {
    return request.delete(`/admin/users/${id}`)
  },

  // 分配角色
  assignRoles(id: number, data: UserRoleData) {
    return request.put(`/admin/users/${id}/roles`, data)
  },

  // 获取用户角色
  getUserRoles(id: number) {
    return request.get(`/admin/users/${id}/roles`)
  },

  // 重置密码
  resetPassword(id: number) {
    return request.post(`/admin/users/${id}/reset-password`)
  },

  // 批量操作
  batchUpdateStatus(data: { user_ids: number[], status: string }) {
    return request.put('/admin/users/batch-status', data)
  },

  batchDeleteUsers(data: { user_ids: number[] }) {
    return request.delete('/admin/users/batch', { data })
  },

  batchResetPassword(data: { user_ids: number[] }) {
    return request.post('/admin/users/batch-reset-password', data)
  }
}
