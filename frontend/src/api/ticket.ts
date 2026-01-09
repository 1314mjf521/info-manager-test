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

export interface ApprovalData {
  action: 'approve' | 'reject'
  comment?: string
}

export interface PriorityUpdateData {
  priority: 'low' | 'normal' | 'high' | 'urgent' | 'critical'
  comment?: string
}

export const ticketApi = {
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

  // 重新分配工单 (使用assign路由)
  reassignTicket(id: number, data: AssignTicketData) {
    return request.post(`/tickets/${id}/assign`, data)
  },

  // 接受工单
  acceptTicket(id: number, comment?: string) {
    const data: any = {}
    if (comment !== undefined && comment !== null && comment !== '') {
      data.comment = comment
    }
    return request.post(`/tickets/${id}/accept`, data)
  },

  // 拒绝工单
  rejectTicket(id: number, reason: string) {
    return request.post(`/tickets/${id}/reject`, { reason })
  },

  // 重新打开工单
  reopenTicket(id: number, comment?: string) {
    const data: any = {}
    if (comment !== undefined && comment !== null && comment !== '') {
      data.comment = comment
    }
    return request.post(`/tickets/${id}/reopen`, data)
  },

  // 重新提交工单
  resubmitTicket(id: number, comment?: string) {
    const data: any = {}
    if (comment !== undefined && comment !== null && comment !== '') {
      data.comment = comment
    }
    return request.post(`/tickets/${id}/resubmit`, data)
  },

  // 更新工单状态
  updateTicketStatus(id: number, status: string, comment?: string) {
    const data: any = { status }
    if (comment !== undefined && comment !== null && comment !== '') {
      data.comment = comment
    }
    return request.put(`/tickets/${id}/status`, data)
  },

  // 工单审批
  approveTicket(id: number, data: ApprovalData) {
    return request.post(`/tickets/${id}/approve`, data)
  },

  // 申请审批
  requestApproval(id: number, comment?: string) {
    return request.post(`/tickets/${id}/request-approval`, { comment })
  },

  // 取消审批
  cancelApproval(id: number, comment?: string) {
    return request.post(`/tickets/${id}/cancel-approval`, { comment })
  },

  // 更新优先级
  updatePriority(id: number, data: PriorityUpdateData) {
    return request.put(`/tickets/${id}/priority`, data)
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

  // 编辑工单评论
  updateTicketComment(ticketId: number, commentId: number, data: TicketCommentData) {
    return request.put(`/tickets/${ticketId}/comments/${commentId}`, data)
  },

  // 删除工单评论
  deleteTicketComment(ticketId: number, commentId: number) {
    return request.delete(`/tickets/${ticketId}/comments/${commentId}`)
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

  // 删除工单附件
  deleteTicketAttachment(ticketId: number, attachmentId: number) {
    return request.delete(`/tickets/${ticketId}/attachments/${attachmentId}`)
  },

  // 获取工单类型
  getTicketCategories() {
    return request.get('/tickets/categories')
  },

  // 获取分配规则
  getAssignmentRules() {
    return request.get('/tickets/assignment-rules')
  },

  // 更新分配规则
  updateAssignmentRules(data: any) {
    return request.put('/tickets/assignment-rules', data)
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
  }
}
