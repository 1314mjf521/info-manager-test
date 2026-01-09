import { computed } from 'vue'
import { useAuthStore } from '../stores/auth'
import http from '../utils/request'

/**
 * 权限管理组合式函数
 */
export function usePermissions() {
  const authStore = useAuthStore()

  /**
   * 检查用户是否具有指定权限
   * @param resource 资源类型
   * @param action 操作类型
   * @param scope 作用域
   */
  const hasPermission = (resource: string, action: string, scope: string = 'all'): boolean => {
    return authStore.hasPermission(resource, action, scope)
  }

  /**
   * 检查用户是否具有任意一个权限
   * @param permissions 权限列表，格式：[{resource, action, scope?}]
   */
  const hasAnyPermission = (permissions: Array<{resource: string, action: string, scope?: string}>): boolean => {
    return permissions.some(perm => hasPermission(perm.resource, perm.action, perm.scope))
  }

  /**
   * 检查用户是否具有所有权限
   * @param permissions 权限列表，格式：[{resource, action, scope?}]
   */
  const hasAllPermissions = (permissions: Array<{resource: string, action: string, scope?: string}>): boolean => {
    return permissions.every(perm => hasPermission(perm.resource, perm.action, perm.scope))
  }

  /**
   * 检查是否为系统管理员
   */
  const isAdmin = computed(() => {
    return hasPermission('system', 'admin') || hasPermission('system', 'manage')
  })

  /**
   * 检查是否可以管理用户
   */
  const canManageUsers = computed(() => {
    return hasPermission('users', 'manage') || hasPermission('users', 'write')
  })

  /**
   * 检查是否可以管理角色
   */
  const canManageRoles = computed(() => {
    return hasPermission('roles', 'manage') || hasPermission('roles', 'write')
  })

  /**
   * 检查是否可以管理权限
   */
  const canManagePermissions = computed(() => {
    return hasPermission('permissions', 'manage') || hasPermission('system', 'admin')
  })

  /**
   * 检查是否可以查看审计日志
   */
  const canViewAuditLogs = computed(() => {
    return hasPermission('audit', 'read') || hasPermission('audit', 'manage')
  })

  /**
   * 检查是否可以导出数据
   */
  const canExportData = computed(() => {
    return hasPermission('export', 'export') || hasPermission('records', 'read')
  })

  /**
   * 检查是否可以使用AI功能
   */
  const canUseAI = computed(() => {
    return hasPermission('ai', 'chat') || hasPermission('ai', 'manage')
  })

  /**
   * 远程权限检查（调用后端API）
   * @param resource 资源类型
   * @param action 操作类型
   * @param scope 作用域
   */
  const checkPermissionRemote = async (resource: string, action: string, scope: string = 'all'): Promise<boolean> => {
    try {
      const response = await http.post('/permissions/check', {
        user_id: authStore.user?.id,
        resource,
        action,
        scope
      })
      return response.success && response.data?.has_permission
    } catch (error) {
      console.error('权限检查失败:', error)
      return false
    }
  }

  /**
   * 获取用户所有权限
   */
  const getUserPermissions = async (userId?: number) => {
    try {
      const targetUserId = userId || authStore.user?.id
      if (!targetUserId) return null

      const response = await http.get(`/permissions/user/${targetUserId}`)
      return response.success ? response.data : null
    } catch (error) {
      console.error('获取用户权限失败:', error)
      return null
    }
  }

  /**
   * 权限常量
   */
  const PERMISSIONS = {
    // 系统管理
    SYSTEM_ADMIN: { resource: 'system', action: 'admin' },
    SYSTEM_MANAGE: { resource: 'system', action: 'manage' },
    
    // 用户管理
    USERS_READ: { resource: 'users', action: 'read' },
    USERS_WRITE: { resource: 'users', action: 'write' },
    USERS_DELETE: { resource: 'users', action: 'delete' },
    USERS_MANAGE: { resource: 'users', action: 'manage' },
    
    // 角色管理
    ROLES_READ: { resource: 'roles', action: 'read' },
    ROLES_WRITE: { resource: 'roles', action: 'write' },
    ROLES_DELETE: { resource: 'roles', action: 'delete' },
    ROLES_MANAGE: { resource: 'roles', action: 'manage' },
    
    // 权限管理
    PERMISSIONS_READ: { resource: 'permissions', action: 'read' },
    PERMISSIONS_WRITE: { resource: 'permissions', action: 'write' },
    PERMISSIONS_DELETE: { resource: 'permissions', action: 'delete' },
    PERMISSIONS_MANAGE: { resource: 'permissions', action: 'manage' },
    
    // 记录管理
    RECORDS_READ: { resource: 'records', action: 'read' },
    RECORDS_WRITE: { resource: 'records', action: 'write' },
    RECORDS_DELETE: { resource: 'records', action: 'delete' },
    RECORDS_MANAGE: { resource: 'records', action: 'manage' },
    
    // 文件管理
    FILES_READ: { resource: 'files', action: 'read' },
    FILES_UPLOAD: { resource: 'files', action: 'upload' },
    FILES_DELETE: { resource: 'files', action: 'delete' },
    FILES_MANAGE: { resource: 'files', action: 'manage' },
    
    // 导出功能
    EXPORT_RECORDS: { resource: 'export', action: 'export' },
    EXPORT_MANAGE: { resource: 'export', action: 'manage' },
    
    // AI功能
    AI_CHAT: { resource: 'ai', action: 'chat' },
    AI_OCR: { resource: 'ai', action: 'ocr' },
    AI_MANAGE: { resource: 'ai', action: 'manage' },
    
    // 审计日志
    AUDIT_READ: { resource: 'audit', action: 'read' },
    AUDIT_MANAGE: { resource: 'audit', action: 'manage' },
    
    // 仪表盘
    DASHBOARD_VIEW: { resource: 'dashboard', action: 'read' }
  } as const

  return {
    // 权限检查方法
    hasPermission,
    hasAnyPermission,
    hasAllPermissions,
    checkPermissionRemote,
    getUserPermissions,
    
    // 计算属性
    isAdmin,
    canManageUsers,
    canManageRoles,
    canManagePermissions,
    canViewAuditLogs,
    canExportData,
    canUseAI,
    
    // 权限常量
    PERMISSIONS
  }
}

/**
 * 权限指令工具函数
 */
export function createPermissionDirective() {
  return {
    mounted(el: HTMLElement, binding: any) {
      const { hasPermission } = usePermissions()
      const { resource, action, scope = 'all' } = binding.value || {}
      
      if (resource && action) {
        if (!hasPermission(resource, action, scope)) {
          el.style.display = 'none'
        }
      }
    },
    
    updated(el: HTMLElement, binding: any) {
      const { hasPermission } = usePermissions()
      const { resource, action, scope = 'all' } = binding.value || {}
      
      if (resource && action) {
        if (!hasPermission(resource, action, scope)) {
          el.style.display = 'none'
        } else {
          el.style.display = ''
        }
      }
    }
  }
}

/**
 * 权限工具函数
 */
export const permissionUtils = {
  /**
   * 格式化权限显示名称
   */
  formatPermissionName(resource: string, action: string, scope?: string): string {
    const resourceNames: Record<string, string> = {
      system: '系统',
      users: '用户',
      roles: '角色',
      permissions: '权限',
      records: '记录',
      files: '文件',
      export: '导出',
      ai: 'AI',
      audit: '审计',
      dashboard: '仪表盘'
    }
    
    const actionNames: Record<string, string> = {
      read: '查看',
      write: '编辑',
      create: '创建',
      update: '更新',
      delete: '删除',
      manage: '管理',
      admin: '管理员',
      upload: '上传',
      download: '下载',
      export: '导出',
      chat: '聊天',
      ocr: '识别'
    }
    
    const scopeNames: Record<string, string> = {
      all: '全部',
      own: '自己',
      department: '部门'
    }
    
    const resourceName = resourceNames[resource] || resource
    const actionName = actionNames[action] || action
    const scopeName = scope ? scopeNames[scope] || scope : ''
    
    return scopeName ? `${resourceName}${actionName}(${scopeName})` : `${resourceName}${actionName}`
  },
  
  /**
   * 解析权限字符串
   */
  parsePermissionString(permissionStr: string): { resource: string, action: string, scope?: string } {
    const parts = permissionStr.split(':')
    return {
      resource: parts[0] || '',
      action: parts[1] || '',
      scope: parts[2] || 'all'
    }
  },
  
  /**
   * 构建权限字符串
   */
  buildPermissionString(resource: string, action: string, scope: string = 'all'): string {
    return `${resource}:${action}:${scope}`
  }
}
