<template>
  <div class="ticket-workflow-test">
    <el-card>
      <template #header>
        <h2>工单流程测试 - 修复版本</h2>
      </template>
      
      <div class="test-section">
        <h3>1. 创建测试工单</h3>
        <el-button @click="createTestTicket" :loading="loading.create">创建工单</el-button>
        <div v-if="testTicket" class="ticket-info">
          <p><strong>工单ID:</strong> {{ testTicket.id }}</p>
          <p><strong>当前状态:</strong> 
            <el-tag :type="getStatusTagType(testTicket.status)">
              {{ getStatusLabel(testTicket.status) }}
            </el-tag>
          </p>
          <p><strong>创建人:</strong> {{ testTicket.creator?.username || '未知' }}</p>
          <p><strong>处理人:</strong> {{ testTicket.assignee?.username || '未分配' }}</p>
        </div>
      </div>

      <div class="test-section" v-if="testTicket">
        <h3>2. 工单流程操作</h3>
        <div class="workflow-actions">
          <el-space wrap>
            <!-- 分配工单 -->
            <el-button 
              v-if="canPerformAction('assign')"
              @click="assignTicket" 
              :loading="loading.assign"
              type="warning"
            >
              分配工单
            </el-button>
            
            <!-- 接受工单 -->
            <el-button 
              v-if="canPerformAction('accept')"
              @click="acceptTicket" 
              :loading="loading.accept"
              type="success"
            >
              接受工单
            </el-button>
            
            <!-- 拒绝工单 -->
            <el-button 
              v-if="canPerformAction('reject')"
              @click="rejectTicket" 
              :loading="loading.reject"
              type="danger"
            >
              拒绝工单
            </el-button>
            
            <!-- 审批工单 -->
            <el-button 
              v-if="canPerformAction('approve')"
              @click="approveTicket" 
              :loading="loading.approve"
              type="primary"
            >
              审批通过
            </el-button>
            
            <!-- 开始处理 -->
            <el-button 
              v-if="canPerformAction('start_progress')"
              @click="startProgress" 
              :loading="loading.progress"
              type="primary"
            >
              开始处理
            </el-button>
            
            <!-- 挂起工单 -->
            <el-button 
              v-if="canPerformAction('pending')"
              @click="pendingTicket" 
              :loading="loading.pending"
              type="warning"
            >
              挂起工单
            </el-button>
            
            <!-- 继续处理 -->
            <el-button 
              v-if="canPerformAction('resume')"
              @click="resumeTicket" 
              :loading="loading.resume"
              type="primary"
            >
              继续处理
            </el-button>
            
            <!-- 解决工单 -->
            <el-button 
              v-if="canPerformAction('resolve')"
              @click="resolveTicket" 
              :loading="loading.resolve"
              type="success"
            >
              解决工单
            </el-button>
            
            <!-- 关闭工单 -->
            <el-button 
              v-if="canPerformAction('close')"
              @click="closeTicket" 
              :loading="loading.close"
              type="info"
            >
              关闭工单
            </el-button>
            
            <!-- 重新打开 -->
            <el-button 
              v-if="canPerformAction('reopen')"
              @click="reopenTicket" 
              :loading="loading.reopen"
              type="warning"
            >
              重新打开
            </el-button>
            
            <!-- 重新提交 -->
            <el-button 
              v-if="canPerformAction('resubmit')"
              @click="resubmitTicket" 
              :loading="loading.resubmit"
              type="primary"
            >
              重新提交
            </el-button>
          </el-space>
        </div>
        
        <!-- 工单流程信息 -->
        <div v-if="workflowInfo" class="workflow-info">
          <h4>流程信息</h4>
          <p><strong>允许的状态转换:</strong></p>
          <el-tag 
            v-for="status in workflowInfo.allowed_transitions" 
            :key="status" 
            class="transition-tag"
          >
            {{ getStatusLabel(status) }}
          </el-tag>
          
          <p><strong>可用操作:</strong></p>
          <el-tag 
            v-for="action in workflowInfo.available_actions" 
            :key="action.action"
            :type="action.type"
            class="action-tag"
          >
            {{ action.label }}
          </el-tag>
        </div>
      </div>

      <div class="test-section">
        <h3>3. 操作日志</h3>
        <el-scrollbar height="300px">
          <div class="log-container">
            <div 
              v-for="(log, index) in apiLogs" 
              :key="index" 
              :class="['log-item', log.type]"
            >
              <span class="log-time">{{ log.time }}</span>
              <span class="log-message">{{ log.message }}</span>
            </div>
          </div>
        </el-scrollbar>
        <el-button @click="clearLogs" size="small">清空日志</el-button>
        <el-button @click="refreshWorkflowInfo" size="small" type="primary">刷新流程信息</el-button>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ticketApi } from '../../api/ticket'
import { useAuthStore } from '../../stores/auth'

// 工单状态枚举
const TicketStatus = {
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
const StatusLabels = {
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
const StatusColors = {
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

const authStore = useAuthStore()
const workflowInfo = ref<any>(null)
const apiLogs = ref<any[]>([])

const loading = reactive({
  create: false,
  assign: false,
  accept: false,
  reject: false,
  approve: false,
  progress: false,
  pending: false,
  resume: false,
  resolve: false,
  close: false,
  reopen: false,
  resubmit: false
})

// 当前用户ID
const currentUserId = computed(() => authStore.user?.id || 0)

// 添加日志
const addLog = (message: string, type: 'success' | 'error' | 'info' = 'info') => {
  apiLogs.value.unshift({
    time: new Date().toLocaleTimeString(),
    message,
    type
  })
}

// 获取状态标签
const getStatusLabel = (status: string) => {
  return StatusLabels[status as keyof typeof StatusLabels] || status
}

// 获取状态标签类型
const getStatusTagType = (status: string) => {
  return StatusColors[status as keyof typeof StatusColors] || 'info'
}

// 检查是否可以执行某个操作
const canPerformAction = (action: string): boolean => {
  if (!testTicket.value) return false
  
  const ticket = testTicket.value
  const userId = currentUserId.value
  
  // 简化的权限检查（实际应用中应该从后端获取）
  const hasApprovePermission = authStore.hasRole('admin') || authStore.hasRole('系统管理员')
  const hasClosePermission = authStore.hasRole('admin') || authStore.hasRole('系统管理员')
  const hasReopenPermission = authStore.hasRole('admin') || authStore.hasRole('系统管理员')
  
  switch (action) {
    case 'assign':
      return ticket.status === TicketStatus.SUBMITTED
    case 'accept':
      return TicketPermissionHelper.canAccept(ticket, userId)
    case 'reject':
      return TicketPermissionHelper.canReject(ticket, userId, hasApprovePermission)
    case 'approve':
      return TicketPermissionHelper.canApprove(ticket, hasApprovePermission)
    case 'start_progress':
      return TicketPermissionHelper.canStartProgress(ticket, userId)
    case 'pending':
      return ticket.status === TicketStatus.PROGRESS && ticket.assignee_id === userId
    case 'resume':
      return ticket.status === TicketStatus.PENDING && ticket.assignee_id === userId
    case 'resolve':
      return TicketPermissionHelper.canResolve(ticket, userId)
    case 'close':
      return TicketPermissionHelper.canClose(ticket, userId, hasClosePermission)
    case 'reopen':
      return TicketPermissionHelper.canReopen(ticket, userId, hasReopenPermission)
    case 'resubmit':
      return TicketPermissionHelper.canResubmit(ticket, userId)
    default:
      return false
  }
}

// 创建测试工单
const createTestTicket = async () => {
  loading.create = true
  try {
    addLog('正在创建测试工单...', 'info')
    const response = await ticketApi.createTicket({
      title: '工单流程测试 - ' + new Date().toLocaleString(),
      description: '这是一个用于测试工单流程的测试工单',
      type: 'bug',
      priority: 'normal'
    })
    
    if (response.success) {
      testTicket.value = response.data
      addLog(`工单创建成功，ID: ${response.data.id}`, 'success')
      ElMessage.success('测试工单创建成功')
      await refreshWorkflowInfo()
    } else {
      addLog('工单创建失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('工单创建失败')
    }
  } catch (error: any) {
    addLog('工单创建异常: ' + error.message, 'error')
    ElMessage.error('工单创建异常')
    console.error('创建工单失败:', error)
  } finally {
    loading.create = false
  }
}

// 分配工单
const assignTicket = async () => {
  loading.assign = true
  try {
    addLog('正在分配工单...', 'info')
    const response = await ticketApi.assignTicket(testTicket.value.id, {
      assignee_id: currentUserId.value,
      comment: '自动分配给当前用户',
      auto_accept: false
    })
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单分配成功', 'success')
      ElMessage.success('工单分配成功')
      await refreshWorkflowInfo()
    } else {
      addLog('工单分配失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('工单分配失败')
    }
  } catch (error: any) {
    addLog('工单分配异常: ' + error.message, 'error')
    ElMessage.error('工单分配异常')
    console.error('分配工单失败:', error)
  } finally {
    loading.assign = false
  }
}

// 接受工单
const acceptTicket = async () => {
  loading.accept = true
  try {
    addLog('正在接受工单...', 'info')
    const response = await ticketApi.acceptTicket(testTicket.value.id, '自动化测试接受工单')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单接受成功', 'success')
      ElMessage.success('工单接受成功')
      await refreshWorkflowInfo()
    } else {
      addLog('工单接受失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('工单接受失败')
    }
  } catch (error: any) {
    addLog('工单接受异常: ' + error.message, 'error')
    ElMessage.error('工单接受异常')
    console.error('接受工单失败:', error)
  } finally {
    loading.accept = false
  }
}

// 拒绝工单
const rejectTicket = async () => {
  loading.reject = true
  try {
    const reason = await ElMessageBox.prompt('请输入拒绝原因', '拒绝工单', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      inputPattern: /.+/,
      inputErrorMessage: '拒绝原因不能为空'
    })
    
    addLog('正在拒绝工单...', 'info')
    const response = await ticketApi.rejectTicket(testTicket.value.id, reason.value)
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单拒绝成功', 'success')
      ElMessage.success('工单拒绝成功')
      await refreshWorkflowInfo()
    } else {
      addLog('工单拒绝失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('工单拒绝失败')
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      addLog('工单拒绝异常: ' + error.message, 'error')
      ElMessage.error('工单拒绝异常')
      console.error('拒绝工单失败:', error)
    }
  } finally {
    loading.reject = false
  }
}

// 审批工单
const approveTicket = async () => {
  loading.approve = true
  try {
    addLog('正在审批工单...', 'info')
    const response = await ticketApiFixed.approveTicket(testTicket.value.id, '自动化测试审批通过')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单审批成功', 'success')
      ElMessage.success('工单审批成功')
      await refreshWorkflowInfo()
    } else {
      addLog('工单审批失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('工单审批失败')
    }
  } catch (error: any) {
    addLog('工单审批异常: ' + error.message, 'error')
    ElMessage.error('工单审批异常')
    console.error('审批工单失败:', error)
  } finally {
    loading.approve = false
  }
}

// 开始处理
const startProgress = async () => {
  loading.progress = true
  try {
    addLog('正在开始处理工单...', 'info')
    const response = await ticketApiFixed.startProgress(testTicket.value.id, '自动化测试开始处理')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单已开始处理', 'success')
      ElMessage.success('工单已开始处理')
      await refreshWorkflowInfo()
    } else {
      addLog('开始处理失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('开始处理失败')
    }
  } catch (error: any) {
    addLog('开始处理异常: ' + error.message, 'error')
    ElMessage.error('开始处理异常')
    console.error('开始处理失败:', error)
  } finally {
    loading.progress = false
  }
}

// 挂起工单
const pendingTicket = async () => {
  loading.pending = true
  try {
    addLog('正在挂起工单...', 'info')
    const response = await ticketApiFixed.pendingTicket(testTicket.value.id, '自动化测试挂起工单')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单已挂起', 'success')
      ElMessage.success('工单已挂起')
      await refreshWorkflowInfo()
    } else {
      addLog('挂起工单失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('挂起工单失败')
    }
  } catch (error: any) {
    addLog('挂起工单异常: ' + error.message, 'error')
    ElMessage.error('挂起工单异常')
    console.error('挂起工单失败:', error)
  } finally {
    loading.pending = false
  }
}

// 继续处理
const resumeTicket = async () => {
  loading.resume = true
  try {
    addLog('正在继续处理工单...', 'info')
    const response = await ticketApiFixed.resumeTicket(testTicket.value.id, '自动化测试继续处理')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单已继续处理', 'success')
      ElMessage.success('工单已继续处理')
      await refreshWorkflowInfo()
    } else {
      addLog('继续处理失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('继续处理失败')
    }
  } catch (error: any) {
    addLog('继续处理异常: ' + error.message, 'error')
    ElMessage.error('继续处理异常')
    console.error('继续处理失败:', error)
  } finally {
    loading.resume = false
  }
}

// 解决工单
const resolveTicket = async () => {
  loading.resolve = true
  try {
    addLog('正在解决工单...', 'info')
    const response = await ticketApiFixed.resolveTicket(testTicket.value.id, '自动化测试解决工单')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单已解决', 'success')
      ElMessage.success('工单已解决')
      await refreshWorkflowInfo()
    } else {
      addLog('解决工单失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('解决工单失败')
    }
  } catch (error: any) {
    addLog('解决工单异常: ' + error.message, 'error')
    ElMessage.error('解决工单异常')
    console.error('解决工单失败:', error)
  } finally {
    loading.resolve = false
  }
}

// 关闭工单
const closeTicket = async () => {
  loading.close = true
  try {
    addLog('正在关闭工单...', 'info')
    const response = await ticketApiFixed.closeTicket(testTicket.value.id, '自动化测试关闭工单')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单已关闭', 'success')
      ElMessage.success('工单已关闭')
      await refreshWorkflowInfo()
    } else {
      addLog('关闭工单失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('关闭工单失败')
    }
  } catch (error: any) {
    addLog('关闭工单异常: ' + error.message, 'error')
    ElMessage.error('关闭工单异常')
    console.error('关闭工单失败:', error)
  } finally {
    loading.close = false
  }
}

// 重新打开工单
const reopenTicket = async () => {
  loading.reopen = true
  try {
    addLog('正在重新打开工单...', 'info')
    const response = await ticketApiFixed.reopenTicket(testTicket.value.id, '自动化测试重新打开')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单已重新打开', 'success')
      ElMessage.success('工单已重新打开')
      await refreshWorkflowInfo()
    } else {
      addLog('重新打开失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('重新打开失败')
    }
  } catch (error: any) {
    addLog('重新打开异常: ' + error.message, 'error')
    ElMessage.error('重新打开异常')
    console.error('重新打开失败:', error)
  } finally {
    loading.reopen = false
  }
}

// 重新提交工单
const resubmitTicket = async () => {
  loading.resubmit = true
  try {
    addLog('正在重新提交工单...', 'info')
    const response = await ticketApiFixed.resubmitTicket(testTicket.value.id, '自动化测试重新提交')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单重新提交成功', 'success')
      ElMessage.success('工单重新提交成功')
      await refreshWorkflowInfo()
    } else {
      addLog('工单重新提交失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('工单重新提交失败')
    }
  } catch (error: any) {
    addLog('工单重新提交异常: ' + error.message, 'error')
    ElMessage.error('工单重新提交异常')
    console.error('重新提交工单失败:', error)
  } finally {
    loading.resubmit = false
  }
}

// 刷新工单流程信息
const refreshWorkflowInfo = async () => {
  if (!testTicket.value) return
  
  try {
    const response = await ticketApiFixed.getTicketWorkflowInfo(testTicket.value.id)
    if (response.success) {
      workflowInfo.value = response.data
    }
  } catch (error) {
    console.error('获取流程信息失败:', error)
  }
}

// 清空日志
const clearLogs = () => {
  apiLogs.value = []
}
</script>

<style scoped>
.ticket-workflow-test {
  padding: 20px;
}

.test-section {
  margin-bottom: 30px;
  padding: 20px;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
}

.test-section h3 {
  margin-top: 0;
  color: #303133;
}

.ticket-info {
  margin-top: 15px;
  padding: 15px;
  background: #f5f7fa;
  border-radius: 4px;
}

.ticket-info p {
  margin: 5px 0;
}

.workflow-actions {
  margin-bottom: 20px;
}

.workflow-info {
  margin-top: 20px;
  padding: 15px;
  background: #f0f9ff;
  border-radius: 4px;
}

.transition-tag, .action-tag {
  margin: 2px 5px 2px 0;
}

.log-container {
  background: #f5f7fa;
  padding: 10px;
  border-radius: 4px;
}

.log-item {
  display: block;
  padding: 5px 0;
  border-bottom: 1px solid #e4e7ed;
}

.log-item:last-child {
  border-bottom: none;
}

.log-time {
  color: #909399;
  font-size: 12px;
  margin-right: 10px;
}

.log-message {
  font-size: 14px;
}

.log-item.success .log-message {
  color: #67c23a;
}

.log-item.error .log-message {
  color: #f56c6c;
}

.log-item.info .log-message {
  color: #409eff;
}
</style>