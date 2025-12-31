<template>
  <div class="ticket-list">
    <div class="page-header">
      <h1>工单管理</h1>
      <div class="header-actions">
        <el-button 
          v-if="ticketPermissions.canCreateTickets()" 
          type="primary" 
          @click="showCreateDialog = true"
        >
          <el-icon><Plus /></el-icon>
          创建工单
        </el-button>
        <el-button 
          v-if="ticketPermissions.canImportTickets()" 
          @click="showImportDialog = true"
        >
          <el-icon><Upload /></el-icon>
          导入工单
        </el-button>
        <el-button 
          v-if="ticketPermissions.canExportTickets()" 
          @click="handleExport"
        >
          <el-icon><Download /></el-icon>
          导出工单
        </el-button>
      </div>
    </div>

    <!-- 统计卡片 -->
    <div class="stats-cards" v-if="ticketPermissions.canViewStatistics()">
      <el-row :gutter="20">
        <el-col :span="4" v-for="stat in stats" :key="stat.key">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon" :class="stat.iconClass">
                <el-icon><component :is="stat.icon" /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ stat.value }}</div>
                <div class="stat-label">{{ stat.label }}</div>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- 筛选条件 -->
    <el-card class="filter-card">
      <el-form :model="filters" inline class="filter-form">
        <el-form-item>
          <el-input 
            v-model="filters.keyword" 
            placeholder="搜索工单标题、描述或ID" 
            clearable
            style="width: 300px"
            @keyup.enter="loadTickets"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </el-form-item>
        
        <el-form-item>
          <el-select v-model="filters.status" placeholder="状态" clearable style="width: 120px">
            <el-option 
              v-for="status in availableStatuses" 
              :key="status.value" 
              :label="status.label" 
              :value="status.value"
            />
          </el-select>
        </el-form-item>

        <el-form-item>
          <el-select v-model="filters.priority" placeholder="优先级" clearable style="width: 120px">
            <el-option 
              v-for="priority in availablePriorities" 
              :key="priority.value" 
              :label="priority.label" 
              :value="priority.value"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item>
          <el-select v-model="filters.type" placeholder="类型" clearable style="width: 120px">
            <el-option 
              v-for="type in ticketTypes" 
              :key="type.value" 
              :label="type.label" 
              :value="type.value"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item>
          <el-button type="primary" @click="loadTickets">
            <el-icon><Search /></el-icon>
            搜索
          </el-button>
          <el-button @click="resetFilters">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工单表格 -->
    <el-card class="table-card">
      <el-table 
        :data="tickets" 
        v-loading="loading"
        @row-click="handleRowClick"
        style="cursor: default"
      >
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="title" label="标题" min-width="200" show-overflow-tooltip />
        <el-table-column prop="type" label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="getTypeTagType(row.type)">{{ getTypeLabel(row.type) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusTagType(row.status)">{{ getStatusLabel(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="priority" label="优先级" width="100">
          <template #default="{ row }">
            <el-tag :type="getPriorityTagType(row.priority)">{{ getPriorityLabel(row.priority) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="创建人" width="120">
          <template #default="{ row }">
            {{ row.creator?.username || '-' }}
          </template>
        </el-table-column>
        <el-table-column label="处理人" width="120">
          <template #default="{ row }">
            {{ row.assignee?.username || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="300" fixed="right">
          <template #default="{ row }">
            <div class="action-buttons">
              <!-- 查看详情 -->
              <el-button 
                size="small" 
                @click.stop="viewTicket(row.id)"
              >
                查看
              </el-button>

              <!-- 编辑工单 -->
              <el-button 
                v-if="ticketPermissions.canOperateTicket(row, 'update')"
                size="small" 
                type="primary"
                @click.stop="editTicket(row)"
              >
                编辑
              </el-button>

              <!-- 分配工单 -->
              <el-button 
                v-if="ticketPermissions.canAssignTickets() && ['submitted', 'assigned'].includes(row.status)"
                size="small" 
                type="warning"
                @click.stop="assignTicket(row)"
              >
                分配
              </el-button>

              <!-- 更多操作下拉菜单 -->
              <el-dropdown 
                v-if="getMoreActions(row).length > 0"
                @command="(command) => handleMoreAction(row, command)"
                @click.stop
              >
                <el-button size="small" @click.stop>
                  更多 <el-icon><ArrowDown /></el-icon>
                </el-button>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item 
                      v-for="action in getMoreActions(row)"
                      :key="action.value"
                      :command="action.value"
                    >
                      {{ action.label }}
                    </el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>

              <!-- 删除工单 -->
              <el-button 
                v-if="ticketPermissions.canOperateTicket(row, 'delete')"
                size="small" 
                type="danger"
                @click.stop="deleteTicket(row)"
              >
                删除
              </el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.size"
          :page-sizes="[10, 20, 50, 100]"
          :total="pagination.total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 创建工单对话框 -->
    <el-dialog v-model="showCreateDialog" title="创建工单" width="600px">
      <el-form :model="createForm" :rules="createRules" ref="createFormRef" label-width="80px">
        <el-form-item label="标题" prop="title">
          <el-input v-model="createForm.title" placeholder="请输入工单标题" />
        </el-form-item>
        <el-form-item label="类型" prop="type">
          <el-select v-model="createForm.type" placeholder="选择工单类型">
            <el-option 
              v-for="type in ticketTypes" 
              :key="type.value" 
              :label="type.label" 
              :value="type.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="优先级" prop="priority">
          <el-select v-model="createForm.priority" placeholder="选择优先级">
            <el-option 
              v-for="priority in availablePriorities" 
              :key="priority.value" 
              :label="priority.label" 
              :value="priority.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input 
            v-model="createForm.description" 
            type="textarea" 
            :rows="4" 
            placeholder="请详细描述工单内容"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="showCreateDialog = false">取消</el-button>
          <el-button type="primary" @click="handleCreateTicket" :loading="creating">创建</el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 导入工单对话框 -->
    <el-dialog v-model="showImportDialog" title="导入工单" width="500px">
      <el-upload
        class="upload-demo"
        drag
        :auto-upload="false"
        :on-change="handleFileChange"
        accept=".xlsx,.xls,.csv"
        :file-list="fileList"
      >
        <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
        <div class="el-upload__text">
          将文件拖到此处，或<em>点击上传</em>
        </div>
        <template #tip>
          <div class="el-upload__tip">
            只能上传 xlsx/xls/csv 文件，单个文件不超过10MB
          </div>
        </template>
      </el-upload>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="showImportDialog = false">取消</el-button>
          <el-button type="primary" @click="handleImport" :loading="importing" :disabled="!selectedFile">导入</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted, markRaw } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  Plus, Search, Upload, Download, ArrowDown, UploadFilled,
  Tickets, Clock, Check, Close, WarningFilled, InfoFilled
} from '@element-plus/icons-vue'
import { ticketApi } from '@/api/ticket'
import { useTicketPermissions } from '@/utils/ticketPermissions'
import { useAuthStore } from '@/stores/auth'
import { formatDateTime } from '@/utils/date'

const router = useRouter()
const ticketPermissions = useTicketPermissions()
const authStore = useAuthStore()

// 响应式数据
const loading = ref(false)
const creating = ref(false)
const importing = ref(false)
const tickets = ref([])
const stats = ref([])
const showCreateDialog = ref(false)
const showImportDialog = ref(false)
const createFormRef = ref()
const selectedFile = ref<File | null>(null)
const fileList = ref([])

// 当前用户ID
const currentUserId = computed(() => authStore.user?.id)

// 筛选条件
const filters = reactive({
  keyword: '',
  status: '',
  priority: '',
  type: '',
  creator_id: null,
  assignee_id: null
})

// 分页
const pagination = reactive({
  page: 1,
  size: 20,
  total: 0
})

// 创建工单表单
const createForm = reactive({
  title: '',
  type: '',
  priority: 'normal',
  description: ''
})

// 表单验证规则
const createRules = {
  title: [
    { required: true, message: '请输入工单标题', trigger: 'blur' }
  ],
  type: [
    { required: true, message: '请选择工单类型', trigger: 'change' }
  ],
  priority: [
    { required: true, message: '请选择优先级', trigger: 'change' }
  ],
  description: [
    { required: true, message: '请输入工单描述', trigger: 'blur' }
  ]
}

// 可用的状态选项（基于权限）
const availableStatuses = computed(() => {
  return [
    { value: 'submitted', label: '已提交' },
    { value: 'assigned', label: '已分配' },
    { value: 'accepted', label: '已接受' },
    { value: 'approved', label: '已审批' },
    { value: 'progress', label: '处理中' },
    { value: 'pending', label: '挂起' },
    { value: 'resolved', label: '已解决' },
    { value: 'closed', label: '已关闭' },
    { value: 'rejected', label: '已拒绝' },
    { value: 'returned', label: '已退回' }
  ]
})

// 可用的优先级选项（基于权限）
const availablePriorities = computed(() => {
  return [
    { value: 'low', label: '低' },
    { value: 'normal', label: '普通' },
    { value: 'high', label: '高' },
    { value: 'urgent', label: '紧急' },
    { value: 'critical', label: '严重' }
  ]
})

// 工单类型选项
const ticketTypes = ref([
  { value: 'bug', label: '故障' },
  { value: 'feature', label: '需求' },
  { value: 'support', label: '支持' },
  { value: 'maintenance', label: '维护' }
])

// 方法
const loadTickets = async () => {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      size: pagination.size,
      ...filters
    }
    const response = await ticketApi.getTickets(params)
    if (response.success) {
      tickets.value = response.data.items || []
      pagination.total = response.data.total || 0
    }
  } catch (error) {
    console.error('加载工单失败:', error)
    ElMessage.error('加载工单失败')
  } finally {
    loading.value = false
  }
}

const loadStatistics = async () => {
  if (!ticketPermissions.canViewStatistics()) return
  
  try {
    const response = await ticketApi.getTicketStatistics()
    if (response.success) {
      const statusData = response.data.status || {}
      const total = response.data.total || 0
      
      stats.value = [
        {
          key: 'total',
          label: '总工单',
          value: total,
          icon: markRaw(Tickets),
          iconClass: 'stat-icon-primary'
        },
        {
          key: 'pending',
          label: '待处理',
          value: (statusData.submitted || 0) + (statusData.assigned || 0) + (statusData.accepted || 0),
          icon: markRaw(Clock),
          iconClass: 'stat-icon-warning'
        },
        {
          key: 'processing',
          label: '处理中',
          value: (statusData.progress || 0) + (statusData.approved || 0) + (statusData.pending || 0),
          icon: markRaw(InfoFilled),
          iconClass: 'stat-icon-info'
        },
        {
          key: 'resolved',
          label: '已解决',
          value: statusData.resolved || 0,
          icon: markRaw(Check),
          iconClass: 'stat-icon-success'
        },
        {
          key: 'closed',
          label: '已关闭',
          value: statusData.closed || 0,
          icon: markRaw(Close),
          iconClass: 'stat-icon-info'
        },
        {
          key: 'issues',
          label: '异常',
          value: (statusData.rejected || 0) + (statusData.returned || 0),
          icon: markRaw(WarningFilled),
          iconClass: 'stat-icon-danger'
        }
      ]
    }
  } catch (error) {
    console.error('加载统计数据失败:', error)
  }
}

// 刷新数据（包括列表和统计）
const refreshData = async () => {
  await Promise.all([
    loadTickets(),
    loadStatistics()
  ])
}

// 重置筛选条件
const resetFilters = () => {
  Object.assign(filters, {
    keyword: '',
    status: '',
    priority: '',
    type: '',
    creator_id: null,
    assignee_id: null
  })
  pagination.page = 1
  loadTickets()
}

// 分页处理
const handleSizeChange = (size: number) => {
  pagination.size = size
  pagination.page = 1
  loadTickets()
}

const handleCurrentChange = (page: number) => {
  pagination.page = page
  loadTickets()
}

// 行点击处理
const handleRowClick = (row: any) => {
  viewTicket(row.id)
}

// 查看工单详情
const viewTicket = (id: number) => {
  router.push(`/tickets/${id}`)
}

// 编辑工单
const editTicket = (ticket: any) => {
  router.push(`/tickets/${ticket.id}/edit`)
}

// 分配工单
const assignTicket = async (ticket: any) => {
  // 直接跳转到分配页面，不显示弹窗
  router.push(`/tickets/${ticket.id}/assign`)
}

// 获取更多操作选项
const getMoreActions = (ticket: any) => {
  const actions = []
  
  // 接受工单
  if (ticketPermissions.canAcceptTickets() && ticket.status === 'assigned' && ticket.assignee_id === currentUserId.value) {
    actions.push({ value: 'accept', label: '接受工单' })
  }
  
  // 拒绝工单
  if (ticketPermissions.canRejectTickets() && ticket.status === 'assigned' && ticket.assignee_id === currentUserId.value) {
    actions.push({ value: 'reject', label: '拒绝工单' })
  }
  
  // 审批工单
  if (ticketPermissions.canApproveTickets() && ticket.status === 'accepted') {
    actions.push({ value: 'approve', label: '审批通过' })
  }
  
  // 重新提交工单
  if (['rejected', 'returned'].includes(ticket.status) && ticket.creator_id === currentUserId.value) {
    actions.push({ value: 'resubmit', label: '重新提交' })
  }
  
  // 状态操作
  if (ticketPermissions.canChangeStatus('progress') && ['accepted', 'approved'].includes(ticket.status)) {
    actions.push({ value: 'start', label: '开始处理' })
  }
  
  if (ticketPermissions.canChangeStatus('pending') && ticket.status === 'progress') {
    actions.push({ value: 'pending', label: '挂起' })
  }
  
  if (ticketPermissions.canChangeStatus('resolved') && ['progress', 'pending'].includes(ticket.status)) {
    actions.push({ value: 'resolve', label: '解决工单' })
  }
  
  if (ticketPermissions.canChangeStatus('closed') && ticket.status === 'resolved') {
    actions.push({ value: 'close', label: '关闭工单' })
  }
  
  if (ticketPermissions.canReopenTickets() && ticket.status === 'closed') {
    actions.push({ value: 'reopen', label: '重新打开' })
  }
  
  // 退回工单
  if (ticketPermissions.canReturnTickets() && ['accepted', 'approved', 'progress'].includes(ticket.status)) {
    actions.push({ value: 'return', label: '退回工单' })
  }
  
  return actions
}

// 处理更多操作
const handleMoreAction = async (ticket: any, action: string) => {
  try {
    let response
    switch (action) {
      case 'accept':
        response = await ticketApi.acceptTicket(ticket.id)
        ElMessage.success('工单接受成功')
        break
      case 'reject':
        response = await ticketApi.rejectTicket(ticket.id)
        ElMessage.success('工单拒绝成功')
        break
      case 'approve':
        response = await ticketApi.updateTicketStatus(ticket.id, 'approved')
        ElMessage.success('工单审批成功')
        break
      case 'resubmit':
        response = await ticketApi.resubmitTicket(ticket.id)
        ElMessage.success('工单重新提交成功')
        break
      case 'start':
        response = await ticketApi.updateTicketStatus(ticket.id, 'progress')
        ElMessage.success('工单已开始处理')
        break
      case 'pending':
        response = await ticketApi.updateTicketStatus(ticket.id, 'pending')
        ElMessage.success('工单已挂起')
        break
      case 'resolve':
        response = await ticketApi.updateTicketStatus(ticket.id, 'resolved')
        ElMessage.success('工单已解决')
        break
      case 'close':
        response = await ticketApi.updateTicketStatus(ticket.id, 'closed')
        ElMessage.success('工单已关闭')
        break
      case 'reopen':
        response = await ticketApi.reopenTicket(ticket.id)
        ElMessage.success('工单已重新打开')
        break
      case 'return':
        response = await ticketApi.updateTicketStatus(ticket.id, 'returned')
        ElMessage.success('工单已退回')
        break
    }
    loadTickets()
    loadStatistics() // 重新加载统计数据
  } catch (error) {
    console.error('操作失败:', error)
    ElMessage.error('操作失败')
  }
}

// 创建工单
const handleCreateTicket = async () => {
  if (!createFormRef.value) return
  
  try {
    await createFormRef.value.validate()
    creating.value = true
    
    const response = await ticketApi.createTicket(createForm)
    if (response.success) {
      ElMessage.success('工单创建成功')
      showCreateDialog.value = false
      Object.assign(createForm, {
        title: '',
        type: '',
        priority: 'normal',
        description: ''
      })
      loadTickets()
      loadStatistics() // 重新加载统计数据
    }
  } catch (error) {
    console.error('创建工单失败:', error)
    ElMessage.error('创建工单失败')
  } finally {
    creating.value = false
  }
}

// 删除工单
const deleteTicket = async (ticket: any) => {
  try {
    await ElMessageBox.confirm(`确定要删除工单 "${ticket.title}" 吗？`, '确认删除', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    const response = await ticketApi.deleteTicket(ticket.id)
    if (response.success) {
      ElMessage.success('工单删除成功')
      loadTickets()
      loadStatistics() // 重新加载统计数据
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('删除工单失败:', error)
      ElMessage.error('删除工单失败')
    }
  }
}

// 导出工单
const handleExport = async () => {
  try {
    // 构建导出参数
    const exportParams = {
      ...filters,
      format: 'csv' // 使用CSV格式，Excel可以正确打开
    }
    
    const response = await ticketApi.exportTickets(exportParams)
    
    // 创建下载链接
    const blob = new Blob([response], { 
      type: 'text/csv; charset=utf-8' 
    })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `工单导出_${new Date().toISOString().split('T')[0]}.csv`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    
    ElMessage.success('工单导出成功')
  } catch (error) {
    console.error('导出工单失败:', error)
    ElMessage.error('导出工单失败')
  }
}

// 文件选择处理
const handleFileChange = (file: any) => {
  selectedFile.value = file.raw
  fileList.value = [file]
}

// 导入工单
const handleImport = async () => {
  if (!selectedFile.value) {
    ElMessage.warning('请选择要导入的文件')
    return
  }
  
  importing.value = true
  try {
    const response = await ticketApi.importTickets(selectedFile.value)
    if (response.success) {
      ElMessage.success(`工单导入成功，共导入 ${response.data.count || 0} 条工单`)
      showImportDialog.value = false
      selectedFile.value = null
      fileList.value = []
      loadTickets()
      loadStatistics()
    }
  } catch (error: any) {
    console.error('导入工单失败:', error)
    const errorMsg = error.response?.data?.error || '导入工单失败'
    ElMessage.error(errorMsg)
  } finally {
    importing.value = false
  }
}

// 辅助方法
const getTypeTagType = (type: string) => {
  const typeMap: Record<string, string> = {
    bug: 'danger',
    feature: 'primary',
    support: 'success',
    maintenance: 'warning'
  }
  return typeMap[type] || 'info'
}

const getTypeLabel = (type: string) => {
  const typeMap: Record<string, string> = {
    bug: '故障',
    feature: '需求',
    support: '支持',
    maintenance: '维护'
  }
  return typeMap[type] || type
}

const getStatusTagType = (status: string) => {
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

const getPriorityTagType = (priority: string) => {
  const priorityMap: Record<string, string> = {
    low: 'info',
    normal: 'primary',
    high: 'warning',
    urgent: 'danger',
    critical: 'danger'
  }
  return priorityMap[priority] || 'info'
}

const getPriorityLabel = (priority: string) => {
  const priorityMap: Record<string, string> = {
    low: '低',
    normal: '普通',
    high: '高',
    urgent: '紧急',
    critical: '严重'
  }
  return priorityMap[priority] || priority
}

// 生命周期
onMounted(() => {
  loadTickets()
  loadStatistics()
  
  // 设置定时刷新统计数据（每30秒）
  const refreshInterval = setInterval(() => {
    loadStatistics()
  }, 30000)
  
  // 组件卸载时清除定时器
  onUnmounted(() => {
    clearInterval(refreshInterval)
  })
})
</script>

<style scoped>
.ticket-list {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.page-header h1 {
  margin: 0;
  color: #303133;
}

.header-actions {
  display: flex;
  gap: 12px;
}

.stats-cards {
  margin-bottom: 20px;
}

.stat-card {
  border: none;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
}

.stat-icon-primary {
  background: #e1f3ff;
  color: #409eff;
}

.stat-icon-success {
  background: #e1f8e1;
  color: #67c23a;
}

.stat-icon-warning {
  background: #fdf6ec;
  color: #e6a23c;
}

.stat-icon-danger {
  background: #fef0f0;
  color: #f56c6c;
}

.stat-icon-info {
  background: #f4f4f5;
  color: #909399;
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 24px;
  font-weight: bold;
  color: #303133;
  line-height: 1;
}

.stat-label {
  font-size: 14px;
  color: #606266;
  margin-top: 4px;
}

.filter-card {
  margin-bottom: 20px;
}

.filter-form {
  margin: 0;
}

.table-card {
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.action-buttons {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.pagination-wrapper {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}

.dialog-footer {
  text-align: right;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .ticket-list {
    padding: 10px;
  }
  
  .page-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }
  
  .header-actions {
    width: 100%;
    justify-content: flex-start;
  }
  
  .stats-cards .el-col {
    margin-bottom: 16px;
  }
  
  .action-buttons {
    flex-direction: column;
    gap: 4px;
  }
  
  .action-buttons .el-button {
    width: 100%;
    justify-content: center;
  }
}
</style>