<template>
  <div class="ticket-assign">
    <div class="page-header">
      <div class="header-left">
        <el-button @click="goBack" icon="ArrowLeft">返回</el-button>
        <h1>分配工单 #{{ ticketId }}</h1>
      </div>
    </div>

    <div v-if="loading" class="loading">
      <el-skeleton :rows="6" animated />
    </div>

    <div v-else-if="ticket" class="assign-content">
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
                  <label>当前处理人：</label>
                  <span>{{ ticket.assignee?.username || '未分配' }}</span>
                </div>
              </div>
            </div>
            
            <div class="description">
              <label>描述：</label>
              <div class="description-content">{{ ticket.description }}</div>
            </div>
          </el-card>

          <!-- 分配表单 -->
          <el-card class="assign-form">
            <template #header>
              <div class="card-header">
                <span>分配工单</span>
              </div>
            </template>

            <el-form :model="assignForm" :rules="assignRules" ref="assignFormRef" label-width="100px">
              <el-form-item label="分配给" prop="assignee_id">
                <el-select 
                  v-model="assignForm.assignee_id" 
                  placeholder="选择处理人" 
                  filterable
                  style="width: 100%"
                >
                  <el-option 
                    v-for="user in users" 
                    :key="user.id" 
                    :label="user.display_name || user.username" 
                    :value="user.id"
                  />
                </el-select>
              </el-form-item>

              <el-form-item label="分配说明" prop="comment">
                <el-input 
                  v-model="assignForm.comment" 
                  type="textarea" 
                  :rows="4" 
                  placeholder="请输入分配说明（可选）"
                />
              </el-form-item>

              <el-form-item label="分配后操作">
                <el-radio-group v-model="assignForm.auto_accept">
                  <el-radio :label="false">仅分配</el-radio>
                  <el-radio :label="true">分配并自动接受</el-radio>
                </el-radio-group>
                <div class="form-tip">
                  <el-text size="small" type="info">
                    选择"分配并自动接受"将直接将工单状态设置为"已接受"
                  </el-text>
                </div>
              </el-form-item>

              <el-form-item>
                <el-button type="primary" @click="handleAssign" :loading="assigning">
                  {{ assignForm.auto_accept ? '分配并接受' : '分配工单' }}
                </el-button>
                <el-button @click="goBack">取消</el-button>
              </el-form-item>
            </el-form>
          </el-card>
        </el-col>

        <el-col :span="8">
          <!-- 操作历史 -->
          <el-card class="history-section">
            <template #header>
              <div class="card-header">
                <span>操作历史</span>
              </div>
            </template>
            
            <div class="history-list">
              <div v-for="history in historyList" :key="history.id" class="history-item">
                <div class="history-header">
                  <span class="history-user">{{ history.user?.username }}</span>
                  <span class="history-time">{{ formatDateTime(history.created_at) }}</span>
                </div>
                <div class="history-action">{{ history.action_type }}: {{ history.comment }}</div>
              </div>
              
              <div v-if="historyList.length === 0" class="no-history">
                暂无操作历史
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft } from '@element-plus/icons-vue'
import { ticketApi } from '@/api/ticket'
import { userApi } from '@/api/user'
import { formatDateTime } from '@/utils/date'

const route = useRoute()
const router = useRouter()

const ticketId = computed(() => Number(route.params.id))
const autoAccept = computed(() => route.query.autoAccept === 'true')

// 响应式数据
const loading = ref(false)
const assigning = ref(false)
const ticket = ref<any>(null)
const users = ref([])
const historyList = ref([])
const assignFormRef = ref()

// 分配表单
const assignForm = reactive({
  assignee_id: null,
  comment: '',
  auto_accept: autoAccept.value
})

// 表单验证规则
const assignRules = {
  assignee_id: [
    { required: true, message: '请选择处理人', trigger: 'change' }
  ]
}

// 加载工单详情
const loadTicket = async () => {
  loading.value = true
  try {
    const response = await ticketApi.getTicket(ticketId.value)
    if (response.success) {
      ticket.value = response.data
      
      // 如果工单已经有处理人，设置为默认值
      if (ticket.value.assignee_id) {
        assignForm.assignee_id = ticket.value.assignee_id
      }
    }
  } catch (error) {
    ElMessage.error('加载工单详情失败')
    console.error('加载工单详情失败:', error)
  } finally {
    loading.value = false
  }
}

// 加载用户列表
const loadUsers = async () => {
  try {
    const response = await userApi.getUsers({ page: 1, size: 100 })
    if (response.success) {
      users.value = response.data.items || []
    }
  } catch (error) {
    console.error('加载用户列表失败:', error)
  }
}

// 加载操作历史
const loadHistory = async () => {
  try {
    const response = await ticketApi.getTicketHistory(ticketId.value)
    if (response.success) {
      historyList.value = response.data || []
    }
  } catch (error) {
    console.error('加载操作历史失败:', error)
  }
}

// 处理分配
const handleAssign = async () => {
  if (!assignFormRef.value) return
  
  try {
    await assignFormRef.value.validate()
    assigning.value = true
    
    const data = {
      assignee_id: assignForm.assignee_id,
      comment: assignForm.comment,
      auto_accept: assignForm.auto_accept
    }
    
    const response = await ticketApi.assignTicket(ticketId.value, data)
    if (response.success) {
      if (assignForm.auto_accept) {
        ElMessage.success('工单分配并接受成功')
      } else {
        ElMessage.success('工单分配成功')
      }
      
      // 跳转回工单详情页面
      router.push(`/tickets/${ticketId.value}`)
    }
  } catch (error) {
    if (error !== false) { // 不是表单验证错误
      ElMessage.error('分配工单失败')
      console.error('分配工单失败:', error)
    }
  } finally {
    assigning.value = false
  }
}

// 返回
const goBack = () => {
  router.back()
}

// 辅助方法
const getTypeTagType = (type: string) => {
  const typeMap: Record<string, string> = {
    bug: 'danger',
    feature: 'success',
    support: 'info',
    change: 'warning'
  }
  return typeMap[type] || 'info'
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

const getPriorityTagType = (priority: string) => {
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

// 生命周期
onMounted(() => {
  loadTicket()
  loadUsers()
  loadHistory()
})
</script>

<style scoped>
.ticket-assign {
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

.page-header h1 {
  margin: 0;
  color: #303133;
}

.assign-content {
  gap: 20px;
}

.ticket-info,
.assign-form,
.history-section {
  margin-bottom: 20px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.ticket-meta {
  margin-bottom: 20px;
}

.meta-item {
  display: flex;
  align-items: center;
  margin-bottom: 12px;
}

.meta-row {
  display: flex;
  gap: 24px;
  margin-bottom: 12px;
}

.meta-item label {
  font-weight: 500;
  color: #606266;
  margin-right: 8px;
  min-width: 80px;
}

.title {
  font-size: 16px;
  font-weight: 500;
  color: #303133;
}

.description {
  border-top: 1px solid #ebeef5;
  padding-top: 16px;
}

.description label {
  font-weight: 500;
  color: #606266;
  margin-bottom: 8px;
  display: block;
}

.description-content {
  color: #606266;
  line-height: 1.6;
  white-space: pre-wrap;
}

.form-tip {
  margin-top: 8px;
}

.history-list {
  max-height: 400px;
  overflow-y: auto;
}

.history-item {
  padding: 12px 0;
  border-bottom: 1px solid #f0f0f0;
}

.history-item:last-child {
  border-bottom: none;
}

.history-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}

.history-user {
  font-weight: 500;
  color: #303133;
}

.history-time {
  font-size: 12px;
  color: #909399;
}

.history-action {
  color: #606266;
  font-size: 14px;
}

.no-history {
  text-align: center;
  color: #909399;
  padding: 20px;
}

.loading {
  padding: 20px;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .ticket-assign {
    padding: 10px;
  }
  
  .header-left {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
  
  .meta-row {
    flex-direction: column;
    gap: 8px;
  }
}
</style>