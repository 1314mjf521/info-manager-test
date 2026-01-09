import request from '../utils/request'

export interface TicketQuery {
  page?: number
  size?: number
  status?: string
  type?: string
  priority?: string
  keyword?: string
  creator_id?: number
  assignee_id?: number
}

export interface CreateTicketData {
  title: string
  description: string
  type: string
  priority: string
}

export interface UpdateTicketData {
  title?: string
  description?: string
  type?: string
  priority?: string
  status?: string
}

export interface AssignTicketData {
  assignee_id: number
  comment?: string
  auto_accept?: boolean
}

export interface TicketCommentData {
  content: string
  is_public?: boolean
}

export interface StatusUpdateData {
  status: string
  comment?: string
}

// 修复的工单API
export const ticketApiFixed = {
  // 获取工单列表
  getTickets(params: TicketQuery) {
    return request.get('/tickets', { params })
  },

  // 获取工单详情
  getTicket(id: number) {
    return request.get(`/tickets/${id}`)
  },

  // 创建工单
  createTicket(data: CreateTicketData) {
    return request.post('/tickets', data)
  },

  // 更新工单
  updateTicket(id: number, data: UpdateTicketData) {
    return request.put(`/tickets/${id}`, data)
  },

  // 删除工单
  deleteTicket(id: number) {
    return request.delete(`/tickets/${id}`)
  },

  // 分配工单
  assignTicket(id: number, data: AssignTicketData) {
    return request.post(`/tickets/${id}/assign`, data)
  },

  // 重新分配工单
  reassignTicket(id: number, data: AssignTicketData) {
    return request.post(`/tickets/${id}/assign`, data)
  },

  // 接受工单 - 修复版本
  acceptTicket(id: number, comment?: string) {
    const data: StatusUpdateData = {
      status: 'accepted'
    }
    if (comment && comment.trim() !== '') {
      data.comment = comment
    }
    return request.put(`/tickets/${id}/status`, data)
  },

  // 拒绝工单 - 修复版本
  rejectTicket(id: number, reason: string) {
    return request.post(`/tickets/${id}/reject`, { reason })
  },

  // 重新打开工单 - 修复版本
  reopenTicket(id: number, comment?: string) {
    const data: any = {}
    if (comment && comment.trim() !== '') {
      data.comment = comment
    }
    return request.post(`/tickets/${id}/reopen`, data)
  },

  // 重新提交工单 - 修复版本
  resubmitTicket(id: number, comment?: string) {
    const data: any = {}
    if (comment && comment.trim() !== '') {
      data.comment = comment
    }
    return request.post(`/tickets/${id}/resubmit`, data)
  },

  // 更新工单状态 - 修复版本，增加详细错误处理
  updateTicketStatus(id: number, status: string, comment?: string) {
    const data: StatusUpdateData = { status }
    if (comment && comment.trim() !== '') {
      data.comment = comment
    }
    
    console.log(`更新工单 ${id} 状态到 ${status}`, data)
    
    return request.put(`/tickets/${id}/status`, data).catch(error => {
      console.error('状态更新失败:', error)
      if (error.response?.data) {
        console.error('错误详情:', error.response.data)
      }
      throw error
    })
  },

  // 开始处理工单
  startProgress(id: number, comment?: string) {
    return this.updateTicketStatus(id, 'progress', comment || '开始处理工单')
  },

  // 挂起工单
  pendingTicket(id: number, comment?: string) {
    return this.updateTicketStatus(id, 'pending', comment || '工单已挂起')
  },

  // 继续处理工单
  resumeTicket(id: number, comment?: string) {
    return this.updateTicketStatus(id, 'progress', comment || '继续处理工单')
  },

  // 解决工单
  resolveTicket(id: number, comment?: string) {
    return this.updateTicketStatus(id, 'resolved', comment || '工单已解决')
  },

  // 关闭工单
  closeTicket(id: number, comment?: string) {
    return this.updateTicketStatus(id, 'closed', comment || '工单已关闭')
  },

  // 审批工单
  approveTicket(id: number, comment?: string) {
    return this.updateTicketStatus(id, 'approved', comment || '工单审批通过')
  },

  // 退回工单
  returnTicket(id: number, comment?: string) {
    return this.updateTicketStatus(id, 'returned', comment || '工单已退回')
  },

  // 获取工单流程信息
  getTicketWorkflowInfo(id: number) {
    return request.get(`/tickets/${id}/workflow`)
  },

  // 获取工单统计
  getTicketStatistics(params?: any) {
    return request.get('/tickets/statistics', { params })
  },

  // 获取工单评论
  getTicketComments(id: number) {
    return request.get(`/tickets/${id}/comments`)
  },

  // 添加工单评论
  addTicketComment(id: number, data: TicketCommentData) {
    return request.post(`/tickets/${id}/comments`, data)
  },

  // 获取工单历史
  getTicketHistory(id: number) {
    return request.get(`/tickets/${id}/history`)
  },

  // 上传工单附件
  uploadTicketAttachment(id: number, file: File) {
    const formData = new FormData()
    formData.append('file', file)
    return request.post(`/tickets/${id}/attachments`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
  },

  // 导出工单
  exportTickets(params?: any) {
    return request.get('/tickets/export', { params, responseType: 'blob' })
  },

  // 导入工单
  importTickets(file: File) {
    const formData = new FormData()
    formData.append('file', file)
    return request.post('/tickets/import', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
  },

  // 批量操作
  batchUpdateStatus(ids: number[], status: string, comment?: string) {
    return request.post('/tickets/batch/status', {
      ids,
      status,
      comment
    })
  },

  // 获取状态转换规则
  getStatusTransitions(currentStatus: string) {
    return request.get(`/tickets/status-transitions/${currentStatus}`)
  }
}

// 工单状态枚举
export const TicketStatus = {
  SUBMITTED: 'submitted',
  ASSIGNED: 'assigned', 
  ACCEPTED: 'accepted',
  APPROVED: 'approved',
  PROGRESS: 'progress',
  PENDING: 'pending',
  RESOLVED: 'resolved',
  CLOSED: 'closed',
  REJECTED: 'rejected',
  RETURNED: 'returned'
} as const

// 状态标签映射
export const StatusLabels = {
  [TicketStatus.SUBMITTED]: '已提交',
  [TicketStatus.ASSIGNED]: '已分配',
  [TicketStatus.ACCEPTED]: '已接受',
  [TicketStatus.APPROVED]: '已审批',
  [TicketStatus.PROGRESS]: '处理中',
  [TicketStatus.PENDING]: '挂起',
  [TicketStatus.RESOLVED]: '已解决',
  [TicketStatus.CLOSED]: '已关闭',
  [TicketStatus.REJECTED]: '已拒绝',
  [TicketStatus.RETURNED]: '已退回'
}

// 状态颜色映射
export const StatusColors = {
  [TicketStatus.SUBMITTED]: 'info',
  [TicketStatus.ASSIGNED]: 'warning',
  [TicketStatus.ACCEPTED]: 'success',
  [TicketStatus.APPROVED]: 'primary',
  [TicketStatus.PROGRESS]: 'primary',
  [TicketStatus.PENDING]: 'warning',
  [TicketStatus.RESOLVED]: 'success',
  [TicketStatus.CLOSED]: 'info',
  [TicketStatus.REJECTED]: 'danger',
  [TicketStatus.RETURNED]: 'warning'
}

// 工单类型枚举
export const TicketType = {
  BUG: 'bug',
  FEATURE: 'feature',
  SUPPORT: 'support',
  MAINTENANCE: 'maintenance',
  CUSTOM: 'custom'
} as const

// 类型标签映射
export const TypeLabels = {
  [TicketType.BUG]: '故障',
  [TicketType.FEATURE]: '需求',
  [TicketType.SUPPORT]: '支持',
  [TicketType.MAINTENANCE]: '维护',
  [TicketType.CUSTOM]: '自定义'
}

// 优先级枚举
export const TicketPriority = {
  LOW: 'low',
  NORMAL: 'normal',
  HIGH: 'high',
  URGENT: 'urgent',
  CRITICAL: 'critical'
} as const

// 优先级标签映射
export const PriorityLabels = {
  [TicketPriority.LOW]: '低',
  [TicketPriority.NORMAL]: '普通',
  [TicketPriority.HIGH]: '高',
  [TicketPriority.URGENT]: '紧急',
  [TicketPriority.CRITICAL]: '严重'
}

// 工单操作权限检查
export class TicketPermissionHelper {
  static canAccept(ticket: any, currentUserId: number): boolean {
    return ticket.status === TicketStatus.ASSIGNED && 
           ticket.assignee_id === currentUserId
  }

  static canReject(ticket: any, currentUserId: number, hasApprovePermission: boolean): boolean {
    const allowedStatuses = [TicketStatus.ASSIGNED, TicketStatus.ACCEPTED, TicketStatus.APPROVED]
    return allowedStatuses.includes(ticket.status) && 
           (hasApprovePermission || ticket.assignee_id === currentUserId)
  }

  static canApprove(ticket: any, hasApprovePermission: boolean): boolean {
    return ticket.status === TicketStatus.ACCEPTED && hasApprovePermission
  }

  static canStartProgress(ticket: any, currentUserId: number): boolean {
    return (ticket.status === TicketStatus.APPROVED || ticket.status === TicketStatus.ACCEPTED) && 
           ticket.assignee_id === currentUserId
  }

  static canResolve(ticket: any, currentUserId: number): boolean {
    return (ticket.status === TicketStatus.PROGRESS || ticket.status === TicketStatus.PENDING) && 
           ticket.assignee_id === currentUserId
  }

  static canClose(ticket: any, currentUserId: number, hasClosePermission: boolean): boolean {
    return ticket.status === TicketStatus.RESOLVED && 
           (hasClosePermission || ticket.creator_id === currentUserId || ticket.assignee_id === currentUserId)
  }

  static canReopen(ticket: any, currentUserId: number, hasReopenPermission: boolean): boolean {
    return ticket.status === TicketStatus.CLOSED && 
           (hasReopenPermission || ticket.creator_id === currentUserId || ticket.assignee_id === currentUserId)
  }

  static canResubmit(ticket: any, currentUserId: number): boolean {
    return (ticket.status === TicketStatus.REJECTED || ticket.status === TicketStatus.RETURNED) && 
           ticket.creator_id === currentUserId
  }
}