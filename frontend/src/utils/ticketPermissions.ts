import { useAuthStore } from '../stores/auth'

// 工单权限检查工具
export class TicketPermissionChecker {
  // 获取当前认证store
  private getAuthStore() {
    return useAuthStore()
  }

  // 检查是否有指定权限
  private hasPermission(permission: string): boolean {
    const authStore = this.getAuthStore()
    if (!authStore.user) {
      return false
    }
    
    // 管理员拥有所有权限
    if (authStore.hasRole('系统管理员') || authStore.hasRole('admin')) {
      return true
    }
    
    // 解析权限字符串 (例如: "ticket:create" 或 "ticket:read:own")
    const parts = permission.split(':')
    if (parts.length < 2) return false
    
    const resource = parts[0]
    const action = parts[1]
    const scope = parts[2] || 'all'
    
    // 使用认证store的权限检查方法
    return authStore.hasPermission(resource, action, scope)
  }

  // 简化的权限检查 - 如果没有详细权限配置，使用基础角色检查
  private hasBasicPermission(action: string): boolean {
    const authStore = this.getAuthStore()
    if (!authStore.user) {
      return false
    }
    
    // 管理员拥有所有权限
    if (authStore.hasRole('系统管理员') || authStore.hasRole('admin')) {
      return true
    }
    
    // 根据用户角色提供基础权限
    const userRoles = authStore.userRoles
    
    // 基础权限映射
    const basicPermissions: Record<string, string[]> = {
      'read': ['用户', '管理员', '系统管理员', 'user', 'admin'],
      'create': ['用户', '管理员', '系统管理员', 'user', 'admin'],
      'update': ['管理员', '系统管理员', 'admin'],
      'delete': ['管理员', '系统管理员', 'admin'],
      'assign': ['管理员', '系统管理员', 'admin'],
      'approve': ['管理员', '系统管理员', 'admin'],
      'status': ['用户', '管理员', '系统管理员', 'user', 'admin']
    }
    
    const allowedRoles = basicPermissions[action] || []
    return userRoles.some(role => allowedRoles.includes(role))
  }

  // 基础权限检查
  canReadTickets(): boolean {
    return this.hasPermission('ticket:read') || this.hasPermission('ticket:read_own') || this.hasPermission('ticket:read:department') || this.hasBasicPermission('read')
  }

  canCreateTickets(): boolean {
    return this.hasPermission('ticket:create') || this.hasBasicPermission('create')
  }

  canUpdateTickets(): boolean {
    return this.hasPermission('ticket:update') || this.hasPermission('ticket:update_own') || this.hasBasicPermission('update')
  }

  canDeleteTickets(): boolean {
    return this.hasPermission('ticket:delete') || this.hasPermission('ticket:delete_own') || this.hasBasicPermission('delete')
  }

  // 分配权限检查
  canAssignTickets(): boolean {
    return this.hasPermission('ticket:assign') || this.hasPermission('ticket:assign:department') || this.hasBasicPermission('assign')
  }

  canReassignTickets(): boolean {
    return this.hasPermission('ticket:reassign') || this.hasBasicPermission('assign')
  }

  canAcceptTickets(): boolean {
    return this.hasPermission('ticket:accept') || this.hasBasicPermission('status')
  }

  canRejectTickets(): boolean {
    return this.hasPermission('ticket:reject') || this.hasBasicPermission('status')
  }

  canReturnTickets(): boolean {
    return this.hasPermission('ticket:return') || this.hasBasicPermission('status')
  }

  // 状态管理权限检查
  canChangeStatus(status: string): boolean {
    const statusPermissions: Record<string, string> = {
      'progress': 'ticket:status:progress',
      'pending': 'ticket:status:pending',
      'resolved': 'ticket:status:resolved',
      'closed': 'ticket:status:closed',
      'approved': 'ticket:status:approved'
    }
    return this.hasPermission(statusPermissions[status] || `ticket:status:${status}`) || this.hasBasicPermission('status')
  }

  canReopenTickets(): boolean {
    return this.hasPermission('ticket:status:reopen') || this.hasBasicPermission('status')
  }

  // 审批权限检查
  canApproveTickets(): boolean {
    return this.hasPermission('ticket:approve') || this.hasPermission('ticket:approve:department') || this.hasBasicPermission('approve')
  }

  canRejectApproval(): boolean {
    return this.hasPermission('ticket:reject_approval')
  }

  canRequestApproval(): boolean {
    return this.hasPermission('ticket:request_approval')
  }

  canCancelApproval(): boolean {
    return this.hasPermission('ticket:cancel_approval')
  }

  // 优先级权限检查
  canSetPriority(priority: string): boolean {
    const priorityPermissions: Record<string, string> = {
      'low': 'ticket:priority:low',
      'normal': 'ticket:priority:normal',
      'high': 'ticket:priority:high',
      'urgent': 'ticket:priority:urgent',
      'critical': 'ticket:priority:critical'
    }
    return this.hasPermission(priorityPermissions[priority] || '')
  }

  // 评论权限检查
  canReadComments(): boolean {
    return this.hasPermission('ticket:comment_read')
  }

  canWriteComments(): boolean {
    return this.hasPermission('ticket:comment_write')
  }

  canEditComments(): boolean {
    return this.hasPermission('ticket:comment_edit')
  }

  canDeleteComments(): boolean {
    return this.hasPermission('ticket:comment_delete')
  }

  // 附件权限检查
  canUploadAttachments(): boolean {
    return this.hasPermission('ticket:attachment_upload')
  }

  canDownloadAttachments(): boolean {
    return this.hasPermission('ticket:attachment_download')
  }

  canDeleteAttachments(): boolean {
    return this.hasPermission('ticket:attachment_delete')
  }

  // 报表权限检查
  canViewStatistics(): boolean {
    return this.hasPermission('ticket:statistics') || this.hasBasicPermission('read')
  }

  canGenerateReports(): boolean {
    return this.hasPermission('ticket:report:generate') || this.hasBasicPermission('read')
  }

  canExportTickets(): boolean {
    return this.hasPermission('ticket:export') || this.hasBasicPermission('read')
  }

  canImportTickets(): boolean {
    return this.hasPermission('ticket:import') || this.hasBasicPermission('create')
  }

  // 配置权限检查
  canManageCategories(): boolean {
    return this.hasPermission('ticket:category:manage')
  }

  canManageTemplates(): boolean {
    return this.hasPermission('ticket:template:manage')
  }

  canManageWorkflow(): boolean {
    return this.hasPermission('ticket:workflow:manage')
  }

  canManageSLA(): boolean {
    return this.hasPermission('ticket:sla:manage')
  }

  canManageNotifications(): boolean {
    return this.hasPermission('ticket:notification:manage')
  }

  // 综合权限检查 - 检查用户对特定工单的操作权限
  canOperateTicket(ticket: any, operation: string): boolean {
    const authStore = this.getAuthStore()
    const currentUserId = authStore.user?.id

    switch (operation) {
      case 'update':
        if (this.hasPermission('ticket:update')) return true
        if (this.hasPermission('ticket:update_own') && ticket.creator_id === currentUserId) return true
        return false

      case 'delete':
        if (this.hasPermission('ticket:delete')) return true
        if (this.hasPermission('ticket:delete_own') && ticket.creator_id === currentUserId) return true
        return false

      case 'assign':
        return this.canAssignTickets()

      case 'approve':
        if (this.hasPermission('ticket:approve')) return true
        if (this.hasPermission('ticket:approve:department') && ticket.department_id === authStore.user?.department_id) return true
        return false

      default:
        return false
    }
  }

  // 获取用户可用的状态选项
  getAvailableStatuses(): Array<{value: string, label: string}> {
    const allStatuses = [
      { value: 'open', label: '打开' },
      { value: 'in_progress', label: '处理中' },
      { value: 'pending', label: '挂起' },
      { value: 'resolved', label: '已解决' },
      { value: 'closed', label: '已关闭' }
    ]

    return allStatuses.filter(status => this.canChangeStatus(status.value))
  }

  // 获取用户可用的优先级选项
  getAvailablePriorities(): Array<{value: string, label: string}> {
    const allPriorities = [
      { value: 'low', label: '低' },
      { value: 'normal', label: '普通' },
      { value: 'high', label: '高' },
      { value: 'urgent', label: '紧急' },
      { value: 'critical', label: '严重' }
    ]

    return allPriorities.filter(priority => this.canSetPriority(priority.value))
  }
}

// 创建全局实例
export const ticketPermissions = new TicketPermissionChecker()

// Vue 3 Composition API 使用
export function useTicketPermissions() {
  return ticketPermissions
}
