<template>
  <div class="ticket-detail">
    <div class="page-header">
      <div class="header-left">
        <el-button @click="goBack" icon="ArrowLeft">返回</el-button>
        <h1>工单详情 #{{ ticket?.id }}</h1>
      </div>
      <div class="header-actions">
        <el-button v-if="canEdit" @click="editTicket" type="primary">编辑</el-button>
        
        <!-- 动态显示可用的操作按钮 -->
        <template v-for="action in getAvailableActions()" :key="action.value">
          <el-button 
            :type="action.type" 
            @click="handleAction(action.value)"
            :loading="actionLoading === action.value"
          >
            {{ action.label }}
          </el-button>
        </template>
        
        <!-- 更多操作下拉菜单 -->
        <el-dropdown v-if="getMoreActions().length > 0" @command="handleAction" trigger="click">
          <el-button>
            更多操作<el-icon class="el-icon--right"><ArrowDown /></el-icon>
          </el-button>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item 
                v-for="action in getMoreActions()"
                :key="action.value"
                :command="action.value"
              >
                {{ action.label }}
              </el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>
    </div>

    <div v-if="loading" class="loading">
      <el-skeleton :rows="8" animated />
    </div>

    <div v-else-if="ticket" class="ticket-content">
      <el-row :gutter="20">
        <el-col :span="16">
          <!-- 工单基本信息 -->
          <el-card class="ticket-info">
            <template #header>
              <div class="card-header">
                <span>工单信息</span>
              </div>
            </template>
            
            <div class="ticket-meta">
              <div class="meta-item">
                <label>标题：</label>
                <span class="title">{{ ticket.title }}</span>
              </div>
              
              <div class="meta-row">
                <div class="meta-item">
                  <label>类型：</label>
                  <el-tag :type="getTypeTagType(ticket.type)">{{ getTypeLabel(ticket.type) }}</el-tag>
                </div>
                <div class="meta-item">
                  <label>状态：</label>
                  <el-tag :type="getStatusTagType(ticket.status)">{{ getStatusLabel(ticket.status) }}</el-tag>
                </div>
                <div class="meta-item">
                  <label>优先级：</label>
                  <el-tag :type="getPriorityTagType(ticket.priority)">{{ getPriorityLabel(ticket.priority) }}</el-tag>
                </div>
              </div>
              
              <div class="meta-row">
                <div class="meta-item">
                  <label>创建人：</label>
                  <span>{{ ticket.creator?.username || '未知' }}</span>
                </div>
                <div class="meta-item">
                  <label>处理人：</label>
                  <span>{{ ticket.assignee?.username || '未分配' }}</span>
                </div>
              </div>
              
              <div class="meta-row">
                <div class="meta-item">
                  <label>创建时间：</label>
                  <span>{{ formatDateTime(ticket.created_at) }}</span>
                </div>
                <div class="meta-item">
                  <label>更新时间：</label>
                  <span>{{ formatDateTime(ticket.updated_at) }}</span>
                </div>
              </div>
            </div>
            
            <div class="description">
              <label>描述：</label>
              <div class="description-content">{{ ticket.description }}</div>
            </div>
          </el-card>

          <!-- 工单评论 -->
          <el-card class="comments-section">
            <template #header>
              <div class="card-header">
                <span>评论 ({{ comments.length }})</span>
              </div>
            </template>
            
            <div class="comments-list">
              <div v-for="comment in comments" :key="comment.id" class="comment-item">
                <div class="comment-header">
                  <span class="comment-author">{{ comment.user?.username }}</span>
                  <span class="comment-time">{{ formatDateTime(comment.created_at) }}</span>
                </div>
                <div class="comment-content">{{ comment.content }}</div>
              </div>
              
              <div v-if="comments.length === 0" class="no-comments">
                暂无评论
              </div>
            </div>
            
            <div class="add-comment">
              <el-input
                v-model="newComment"
                type="textarea"
                :rows="3"
                placeholder="添加评论..."
                maxlength="1000"
                show-word-limit
              />
              <div class="comment-actions">
                <el-button @click="addComment" type="primary" :loading="commenting">添加评论</el-button>
              </div>
            </div>
          </el-card>
        </el-col>
        
        <el-col :span="8">
          <!-- 审批流程进度 -->
          <el-card class="approval-progress-section">
            <template #header>
              <div class="card-header">
                <span>审批进度</span>
              </div>
            </template>
            
            <div class="approval-progress">
              <el-steps :active="getApprovalStep(ticket?.status)" direction="vertical" finish-status="success">
                <el-step title="已提交" :description="getStepDescription('submitted')">
                  <template #icon>
                    <el-icon :color="getStepColor('submitted')"><Document /></el-icon>
                  </template>
                </el-step>
                <el-step title="已分派" :description="getStepDescription('assigned')">
                  <template #icon>
                    <el-icon :color="getStepColor('assigned')"><User /></el-icon>
                  </template>
                </el-step>
                <el-step title="已审批" :description="getStepDescription('approved')">
                  <template #icon>
                    <el-icon :color="getStepColor('approved')"><Check /></el-icon>
                  </template>
                </el-step>
                <el-step title="执行中" :description="getStepDescription('progress')">
                  <template #icon>
                    <el-icon :color="getStepColor('progress')"><Loading /></el-icon>
                  </template>
                </el-step>
                <el-step title="已完成" :description="getStepDescription('resolved')">
                  <template #icon>
                    <el-icon :color="getStepColor('resolved')"><CircleCheck /></el-icon>
                  </template>
                </el-step>
              </el-steps>
            </div>
          </el-card>

          <!-- 工单历史 -->
          <el-card class="history-section">
            <template #header>
              <div class="card-header">
                <span>操作历史</span>
              </div>
            </template>
            
            <div class="history-list">
              <div v-for="history in historyList" :key="history.id" class="history-item">
                <div class="history-time">{{ formatDateTime(history.created_at) }}</div>
                <div class="history-content">
                  <span class="history-user">{{ history.user?.username }}</span>
                  <span class="history-action">{{ history.description }}</span>
                </div>
              </div>
              
              <div v-if="historyList.length === 0" class="no-history">
                暂无操作历史
              </div>
            </div>
          </el-card>
          
          <!-- 工单附件 -->
          <el-card class="attachments-section">
            <template #header>
              <div class="card-header">
                <span>附件</span>
                <el-button 
                  v-if="ticketPermissions.canUploadAttachments()"
                  size="small" 
                  type="primary"
                  @click="showUploadDialog = true"
                >
                  <el-icon><UploadFilled /></el-icon>
                  上传附件
                </el-button>
              </div>
            </template>
            
            <div class="attachments-list">
              <div v-for="attachment in attachments" :key="attachment.id" class="attachment-item">
                <el-icon><Document /></el-icon>
                <span class="attachment-name">{{ attachment.file_name }}</span>
                <el-button size="small" text @click="downloadAttachment(attachment)">下载</el-button>
                <el-button size="small" text type="danger" @click="deleteAttachment(attachment)">删除</el-button>
              </div>
              
              <div v-if="attachments.length === 0" class="no-attachments">
                暂无附件
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- 分配工单对话框 -->
    <el-dialog v-model="showAssignDialog" title="分配工单" width="400px">
      <el-form :model="assignForm" label-width="80px">
        <el-form-item label="处理人">
          <el-select v-model="assignForm.assignee_id" placeholder="选择处理人" filterable>
            <el-option 
              v-for="user in users" 
              :key="user.id" 
              :label="user.username" 
              :value="user.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input 
            v-model="assignForm.comment" 
            type="textarea" 
            :rows="3" 
            placeholder="分配说明（可选）"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showAssignDialog = false">取消</el-button>
        <el-button type="primary" @click="confirmAssign" :loading="assigning">确认分配</el-button>
      </template>
    </el-dialog>

    <!-- 上传附件对话框 -->
    <el-dialog v-model="showUploadDialog" title="上传附件" width="400px">
      <el-upload
        ref="uploadRef"
        :action="`/api/v1/tickets/${ticketId}/attachments`"
        :headers="{ Authorization: `Bearer ${authStore.token}` }"
        :on-success="handleUploadSuccess"
        :on-error="handleUploadError"
        :before-upload="beforeUpload"
        drag
        multiple
      >
        <el-icon class="el-icon--upload"><upload-filled /></el-icon>
        <div class="el-upload__text">
          将文件拖到此处，或<em>点击上传</em>
        </div>
      </el-upload>
      <template #footer>
        <el-button @click="showUploadDialog = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowLeft, ArrowDown, Document, UploadFilled, User, Check, Loading, Check as CircleCheck } from '@element-plus/icons-vue'
import { ticketApi } from '@/api/ticket'
import { userApi } from '@/api/user'
import { useTicketPermissions } from '@/utils/ticketPermissions'
import { useAuthStore } from '@/stores/auth'
import { formatDateTime } from '@/utils/date'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const ticketPermissions = useTicketPermissions()

const ticketId = computed(() => Number(route.params.id))

// 响应式数据
const loading = ref(false)
const commenting = ref(false)
const assigning = ref(false)
const actionLoading = ref('')
const ticket = ref<any>(null)
const comments = ref([])
const historyList = ref([])
const attachments = ref([])
const users = ref([])
const newComment = ref('')
const showAssignDialog = ref(false)
const showUploadDialog = ref(false)

// 分配表单
const assignForm = reactive({
  assignee_id: null,
  comment: ''
})

// 权限检查
const canEdit = computed(() => {
  return ticket.value?.creator_id === authStore.user?.id || authStore.hasPermission('ticket', 'edit')
})

const canAssign = computed(() => {
  return authStore.hasPermission('ticket', 'assign')
})

const canUpdateStatus = computed(() => {
  return ticket.value?.creator_id === authStore.user?.id || 
         ticket.value?.assignee_id === authStore.user?.id ||
         authStore.hasPermission('ticket', 'status')
})

// 方法
const loadTicket = async () => {
  loading.value = true
  try {
    const response = await ticketApi.getTicket(ticketId.value)
    ticket.value = response.data
    
    // 加载附件
    loadAttachments()
  } catch (error) {
    ElMessage.error('加载工单详情失败')
    router.push('/tickets')
  } finally {
    loading.value = false
  }
}

const loadComments = async () => {
  try {
    const response = await ticketApi.getTicketComments(ticketId.value)
    comments.value = response.data
  } catch (error) {
    console.error('加载评论失败:', error)
  }
}

const loadAttachments = async () => {
  try {
    // 从工单详情中获取附件信息
    if (ticket.value && ticket.value.attachments) {
      attachments.value = ticket.value.attachments
    }
  } catch (error) {
    console.error('加载附件失败:', error)
  }
}

const loadHistory = async () => {
  try {
    const response = await ticketApi.getTicketHistory(ticketId.value)
    historyList.value = response.data
  } catch (error) {
    console.error('加载历史记录失败:', error)
  }
}

const loadUsers = async () => {
  try {
    const response = await userApi.getUsers({ page: 1, size: 1000 })
    users.value = response.data.items || []
  } catch (error) {
    console.error('加载用户列表失败:', error)
  }
}

const addComment = async () => {
  if (!newComment.value.trim()) {
    ElMessage.warning('请输入评论内容')
    return
  }
  
  try {
    commenting.value = true
    await ticketApi.addTicketComment(ticketId.value, {
      content: newComment.value,
      is_public: true
    })
    ElMessage.success('评论添加成功')
    newComment.value = ''
    loadComments()
    loadHistory()
  } catch (error) {
    ElMessage.error('添加评论失败')
  } finally {
    commenting.value = false
  }
}

const confirmAssign = async () => {
  if (!assignForm.assignee_id) {
    ElMessage.warning('请选择处理人')
    return
  }
  
  try {
    assigning.value = true
    await ticketApi.assignTicket(ticketId.value, assignForm)
    ElMessage.success('工单分配成功')
    showAssignDialog.value = false
    loadTicket()
    loadHistory()
  } catch (error) {
    ElMessage.error('分配工单失败')
  } finally {
    assigning.value = false
  }
}

const updateStatus = async (status: string) => {
  try {
    await ElMessageBox.confirm(`确认将工单状态更新为"${getStatusLabel(status)}"吗？`, '确认操作')
    
    await ticketApi.updateTicketStatus(ticketId.value, status, '')
    ElMessage.success('状态更新成功')
    loadTicket()
    loadHistory()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('状态更新失败')
    }
  }
}

const editTicket = () => {
  router.push(`/tickets/${ticketId.value}/edit`)
}

const goBack = () => {
  router.push('/tickets')
}

// 获取可用的主要操作（显示为独立按钮）
const getAvailableActions = () => {
  if (!ticket.value) return []
  
  const actions = []
  const currentUserId = authStore.user?.id
  const status = ticket.value.status
  
  // 分配工单
  if (ticketPermissions.canAssignTickets() && ['submitted', 'returned'].includes(status)) {
    actions.push({ value: 'assign', label: '分配工单', type: 'success' })
  }
  
  // 接受工单
  if (ticketPermissions.canAcceptTickets() && status === 'assigned' && ticket.value.assignee_id === currentUserId) {
    actions.push({ value: 'accept', label: '接受工单', type: 'primary' })
  }
  
  // 审批通过
  if (ticketPermissions.canOperateTicket(ticket.value, 'approve') && status === 'accepted') {
    actions.push({ value: 'approve', label: '审批通过', type: 'success' })
  }
  
  // 开始处理
  if (ticketPermissions.canChangeStatus('progress') && ['accepted', 'approved'].includes(status)) {
    actions.push({ value: 'start', label: '开始处理', type: 'primary' })
  }
  
  // 解决工单
  if (ticketPermissions.canChangeStatus('resolved') && ['progress', 'pending'].includes(status)) {
    actions.push({ value: 'resolve', label: '解决工单', type: 'success' })
  }
  
  // 关闭工单
  if (ticketPermissions.canChangeStatus('closed') && status === 'resolved') {
    actions.push({ value: 'close', label: '关闭工单', type: 'info' })
  }
  
  // 重新提交
  if (['rejected', 'returned'].includes(status) && ticket.value.creator_id === currentUserId) {
    actions.push({ value: 'resubmit', label: '重新提交', type: 'primary' })
  }
  
  // 重新打开
  if (ticketPermissions.canReopenTickets() && status === 'closed') {
    actions.push({ value: 'reopen', label: '重新打开', type: 'warning' })
  }
  
  return actions
}

// 获取更多操作（显示在下拉菜单中）
const getMoreActions = () => {
  if (!ticket.value) return []
  
  const actions = []
  const currentUserId = authStore.user?.id
  const status = ticket.value.status
  
  // 拒绝工单
  if (ticketPermissions.canRejectTickets() && ['assigned', 'accepted'].includes(status) && ticket.value.assignee_id === currentUserId) {
    actions.push({ value: 'reject', label: '拒绝工单' })
  }
  
  // 退回工单
  if (['accepted', 'approved', 'progress'].includes(status)) {
    actions.push({ value: 'return', label: '退回工单' })
  }
  
  // 挂起工单
  if (ticketPermissions.canChangeStatus('pending') && status === 'progress') {
    actions.push({ value: 'pending', label: '挂起工单' })
  }
  
  // 恢复处理
  if (ticketPermissions.canChangeStatus('progress') && status === 'pending') {
    actions.push({ value: 'resume', label: '恢复处理' })
  }
  
  return actions
}

// 处理操作
const handleAction = async (action: string) => {
  if (!ticket.value) return
  
  actionLoading.value = action
  
  try {
    let response
    let message = ''
    
    switch (action) {
      case 'assign':
        router.push(`/tickets/${ticketId.value}/assign`)
        return
        
      case 'accept':
        response = await ticketApi.acceptTicket(ticketId.value)
        message = '工单接受成功'
        break
        
      case 'reject':
        response = await ticketApi.rejectTicket(ticketId.value)
        message = '工单拒绝成功'
        break
        
      case 'approve':
        response = await ticketApi.updateTicketStatus(ticketId.value, 'approved')
        message = '工单审批成功'
        break
        
      case 'start':
        response = await ticketApi.updateTicketStatus(ticketId.value, 'progress')
        message = '工单已开始处理'
        break
        
      case 'pending':
        response = await ticketApi.updateTicketStatus(ticketId.value, 'pending')
        message = '工单已挂起'
        break
        
      case 'resume':
        response = await ticketApi.updateTicketStatus(ticketId.value, 'progress')
        message = '工单已恢复处理'
        break
        
      case 'resolve':
        response = await ticketApi.updateTicketStatus(ticketId.value, 'resolved')
        message = '工单已解决'
        break
        
      case 'close':
        response = await ticketApi.updateTicketStatus(ticketId.value, 'closed')
        message = '工单已关闭'
        break
        
      case 'return':
        response = await ticketApi.updateTicketStatus(ticketId.value, 'returned')
        message = '工单已退回'
        break
        
      case 'resubmit':
        response = await ticketApi.resubmitTicket(ticketId.value)
        message = '工单重新提交成功'
        break
        
      case 'reopen':
        response = await ticketApi.reopenTicket(ticketId.value)
        message = '工单已重新打开'
        break
        
      default:
        ElMessage.warning('未知操作')
        return
    }
    
    if (response?.success) {
      ElMessage.success(message)
      // 重新加载工单数据
      await loadTicket()
      await loadHistory()
    }
  } catch (error) {
    console.error('操作失败:', error)
    ElMessage.error('操作失败')
  } finally {
    actionLoading.value = ''
  }
}

// 标签样式方法
const getTypeTagType = (type: string) => {
  if (!type) return 'info'
  const typeMap: Record<string, string> = {
    bug: 'danger',
    feature: 'success',
    support: 'info',
    change: 'warning'
  }
  return typeMap[type] || 'info'
}

const getStatusTagType = (status: string) => {
  if (!status) return 'info'
  const statusMap: Record<string, string> = {
    submitted: 'info',
    assigned: 'warning',
    accepted: 'success',
    approved: 'primary',
    progress: 'primary',
    pending: 'warning',
    resolved: 'success',
    closed: 'info',
    rejected: 'danger',
    returned: 'warning'
  }
  return statusMap[status] || 'info'
}

const getPriorityTagType = (priority: string) => {
  if (!priority) return 'info'
  const priorityMap: Record<string, string> = {
    low: 'info',
    normal: 'primary',
    high: 'warning',
    critical: 'danger'
  }
  return priorityMap[priority] || 'info'
}

const getTypeLabel = (type: string) => {
  const typeMap: Record<string, string> = {
    bug: '故障报告',
    feature: '功能请求',
    support: '技术支持',
    change: '变更请求'
  }
  return typeMap[type] || type
}

const getStatusLabel = (status: string) => {
  const statusMap: Record<string, string> = {
    submitted: '已提交',
    assigned: '已分配',
    accepted: '已接受',
    approved: '已审批',
    progress: '处理中',
    pending: '挂起',
    resolved: '已解决',
    closed: '已关闭',
    rejected: '已拒绝',
    returned: '已退回'
  }
  return statusMap[status] || status
}

const getPriorityLabel = (priority: string) => {
  const priorityMap: Record<string, string> = {
    low: '低',
    normal: '普通',
    high: '高',
    critical: '紧急'
  }
  return priorityMap[priority] || priority
}

// 附件相关方法
const handleUploadSuccess = () => {
  ElMessage.success('附件上传成功')
  showUploadDialog.value = false
  // 重新加载工单详情以获取最新的附件列表
  loadTicket()
}

const handleUploadError = () => {
  ElMessage.error('附件上传失败')
}

const beforeUpload = (file: File) => {
  const isLt10M = file.size / 1024 / 1024 < 10
  if (!isLt10M) {
    ElMessage.error('文件大小不能超过 10MB!')
  }
  return isLt10M
}

const downloadAttachment = (attachment: any) => {
  // 实现附件下载
  ElMessage.info('下载功能待实现')
}

const deleteAttachment = async (attachment: any) => {
  try {
    await ElMessageBox.confirm('确认删除此附件吗？', '确认操作')
    await ticketApi.deleteTicketAttachment(ticketId.value, attachment.id)
    ElMessage.success('附件删除成功')
    // 重新加载工单详情以获取最新的附件列表
    loadTicket()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除附件失败')
    }
  }
}

// 审批流程相关方法
const getApprovalStep = (status: string) => {
  const stepMap: Record<string, number> = {
    'submitted': 0,
    'assigned': 1,
    'approved': 2,
    'progress': 3,
    'resolved': 4,
    'closed': 4,
    'rejected': -1,
    'returned': 0
  }
  return stepMap[status] || 0
}

const getStepDescription = (step: string) => {
  if (!ticket.value) return ''
  
  const descriptions: Record<string, string> = {
    'submitted': `${formatDateTime(ticket.value.created_at)} 由 ${ticket.value.creator?.username} 提交`,
    'assigned': ticket.value.assignee ? `分派给 ${ticket.value.assignee.username}` : '等待分派',
    'approved': ticket.value.status === 'approved' || getApprovalStep(ticket.value.status) > 2 ? '审批通过' : '等待审批',
    'progress': ticket.value.status === 'progress' || getApprovalStep(ticket.value.status) > 3 ? '正在处理' : '等待执行',
    'resolved': ticket.value.status === 'resolved' || ticket.value.status === 'closed' ? 
      `${formatDateTime(ticket.value.resolved_at || ticket.value.updated_at)} 已完成` : '等待完成'
  }
  return descriptions[step] || ''
}

const getStepColor = (step: string) => {
  if (!ticket.value) return '#C0C4CC'
  
  const currentStep = getApprovalStep(ticket.value.status)
  const stepIndex = getApprovalStep(step)
  
  if (ticket.value.status === 'rejected') {
    return stepIndex === 0 ? '#F56C6C' : '#C0C4CC'
  }
  
  if (stepIndex <= currentStep) {
    return '#67C23A'
  } else {
    return '#C0C4CC'
  }
}

// 生命周期
onMounted(() => {
  loadTicket()
  loadComments()
  loadHistory()
  loadUsers()
})
</script>

<style scoped>
.ticket-detail {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.header-left h1 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
}

.loading {
  padding: 20px;
}

.ticket-content {
  margin-bottom: 20px;
}

.ticket-info {
  margin-bottom: 20px;
}

.ticket-meta {
  margin-bottom: 20px;
}

.meta-item {
  margin-bottom: 12px;
}

.meta-row {
  display: flex;
  gap: 32px;
  margin-bottom: 12px;
}

.meta-row .meta-item {
  margin-bottom: 0;
}

.meta-item label {
  font-weight: 600;
  color: #606266;
  margin-right: 8px;
}

.title {
  font-size: 18px;
  font-weight: 600;
  color: #303133;
}

.description {
  border-top: 1px solid #ebeef5;
  padding-top: 16px;
}

.description label {
  font-weight: 600;
  color: #606266;
  display: block;
  margin-bottom: 8px;
}

.description-content {
  background: #f5f7fa;
  padding: 12px;
  border-radius: 4px;
  white-space: pre-wrap;
  line-height: 1.6;
}

.comments-section {
  margin-bottom: 20px;
}

.comments-list {
  margin-bottom: 20px;
}

.comment-item {
  border-bottom: 1px solid #ebeef5;
  padding: 16px 0;
}

.comment-item:last-child {
  border-bottom: none;
}

.comment-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.comment-author {
  font-weight: 600;
  color: #409eff;
}

.comment-time {
  color: #909399;
  font-size: 12px;
}

.comment-content {
  color: #606266;
  line-height: 1.6;
  white-space: pre-wrap;
}

.no-comments {
  text-align: center;
  color: #909399;
  padding: 20px;
}

.add-comment {
  border-top: 1px solid #ebeef5;
  padding-top: 16px;
}

.comment-actions {
  margin-top: 12px;
  text-align: right;
}

.history-section {
  margin-bottom: 20px;
}

.approval-progress-section {
  margin-bottom: 20px;
}

.approval-progress {
  padding: 16px 0;
}

.approval-progress .el-steps {
  max-height: 400px;
  overflow-y: auto;
}

.approval-progress .el-step__description {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
}

.history-section {
  margin-bottom: 20px;
}

.history-list {
  max-height: 400px;
  overflow-y: auto;
}

.history-item {
  border-bottom: 1px solid #ebeef5;
  padding: 12px 0;
}

.history-item:last-child {
  border-bottom: none;
}

.history-time {
  font-size: 12px;
  color: #909399;
  margin-bottom: 4px;
}

.history-content {
  font-size: 14px;
  color: #606266;
}

.history-user {
  font-weight: 600;
  color: #409eff;
  margin-right: 8px;
}

.no-history {
  text-align: center;
  color: #909399;
  padding: 20px;
}

.attachments-section {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.attachments-list {
  max-height: 300px;
  overflow-y: auto;
}

.attachment-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 0;
  border-bottom: 1px solid #ebeef5;
}

.attachment-item:last-child {
  border-bottom: none;
}

.attachment-name {
  flex: 1;
  color: #606266;
}

.no-attachments {
  text-align: center;
  color: #909399;
  padding: 20px;
}
</style>