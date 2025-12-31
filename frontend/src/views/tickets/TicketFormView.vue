<template>
  <div class="ticket-form">
    <div class="page-header">
      <h1>{{ isEdit ? '编辑工单' : '创建工单' }}</h1>
      <div class="header-actions">
        <el-button @click="goBack">返回</el-button>
        <el-button type="primary" @click="saveTicket" :loading="saving">
          {{ isEdit ? '保存' : '创建' }}
        </el-button>
      </div>
    </div>

    <el-card class="form-card">
      <el-form 
        :model="form" 
        :rules="rules" 
        ref="formRef" 
        label-width="100px"
        @submit.prevent="saveTicket"
      >
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="工单标题" prop="title">
              <el-input 
                v-model="form.title" 
                placeholder="请输入工单标题"
                maxlength="500"
                show-word-limit
              />
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="工单类型" prop="type">
              <el-select v-model="form.type" placeholder="选择工单类型">
                <el-option label="故障报告" value="bug" />
                <el-option label="功能请求" value="feature" />
                <el-option label="技术支持" value="support" />
                <el-option label="变更请求" value="change" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="优先级" prop="priority">
              <el-select v-model="form.priority" placeholder="选择优先级">
                <el-option label="低" value="low" />
                <el-option label="普通" value="normal" />
                <el-option label="高" value="high" />
                <el-option label="紧急" value="critical" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20" v-if="isEdit">
          <el-col :span="6">
            <el-form-item label="工单状态" prop="status">
              <el-select v-model="form.status" placeholder="选择状态" :disabled="!canEditStatus">
                <el-option label="待处理" value="open" />
                <el-option label="处理中" value="progress" />
                <el-option label="等待反馈" value="pending" />
                <el-option label="已解决" value="resolved" />
                <el-option label="已关闭" value="closed" />
                <el-option label="已拒绝" value="rejected" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="处理人" prop="assignee_id">
              <el-select 
                v-model="form.assignee_id" 
                placeholder="选择处理人" 
                filterable
                clearable
                :disabled="!canAssign"
              >
                <el-option 
                  v-for="user in users" 
                  :key="user.id" 
                  :label="user.display_name || user.username" 
                  :value="user.id"
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="截止时间">
              <el-date-picker
                v-model="form.due_date"
                type="datetime"
                placeholder="选择截止时间"
                format="YYYY-MM-DD HH:mm"
                value-format="YYYY-MM-DD HH:mm:ss"
              />
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="分类">
              <el-input v-model="form.category" placeholder="工单分类（可选）" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="工单描述" prop="description">
          <el-input 
            v-model="form.description" 
            type="textarea" 
            :rows="6" 
            placeholder="请详细描述工单内容"
            maxlength="2000"
            show-word-limit
          />
        </el-form-item>

        <el-form-item label="标签">
          <el-tag
            v-for="tag in form.tags"
            :key="tag"
            closable
            @close="removeTag(tag)"
            style="margin-right: 8px; margin-bottom: 8px;"
          >
            {{ tag }}
          </el-tag>
          <el-input
            v-if="tagInputVisible"
            ref="tagInputRef"
            v-model="tagInputValue"
            size="small"
            style="width: 120px;"
            @keyup.enter="addTag"
            @blur="addTag"
          />
          <el-button v-else size="small" @click="showTagInput">+ 添加标签</el-button>
        </el-form-item>

        <el-form-item label="附件">
          <div v-if="!isEdit" class="create-upload-tip">
            <el-text size="small" type="info">
              <el-icon><InfoFilled /></el-icon>
              创建工单后可在工单详情页面上传附件
            </el-text>
          </div>
          <el-upload
            v-else
            ref="uploadRef"
            :action="uploadUrl"
            :headers="uploadHeaders"
            :on-success="handleUploadSuccess"
            :on-error="handleUploadError"
            :before-upload="beforeUpload"
            multiple
            :show-file-list="false"
          >
            <el-button size="small" type="primary">
              <el-icon><Document /></el-icon>
              上传附件
            </el-button>
          </el-upload>
          
          <div class="attachment-list" v-if="attachments.length > 0">
            <div 
              v-for="attachment in attachments" 
              :key="attachment.id"
              class="attachment-item"
            >
              <el-icon><Document /></el-icon>
              <span class="attachment-name">{{ attachment.file_name }}</span>
              <span class="attachment-size">{{ formatFileSize(attachment.file_size) }}</span>
              <el-button 
                size="small" 
                type="danger" 
                text 
                @click="removeAttachment(attachment.id)"
                v-if="canDeleteAttachment(attachment)"
              >
                删除
              </el-button>
            </div>
          </div>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed, nextTick } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Document, InfoFilled } from '@element-plus/icons-vue'
import { ticketApi } from '@/api/ticket'
import { userApi } from '@/api/user'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

// 响应式数据
const saving = ref(false)
const users = ref([])
const attachments = ref([])
const formRef = ref()
const uploadRef = ref()
const tagInputRef = ref()

// 标签相关
const tagInputVisible = ref(false)
const tagInputValue = ref('')

// 表单数据
const form = reactive({
  title: '',
  description: '',
  type: '',
  priority: 'normal',
  status: 'open',
  assignee_id: null,
  due_date: null,
  category: '',
  tags: []
})

// 表单验证规则
const rules = {
  title: [
    { required: true, message: '请输入工单标题', trigger: 'blur' },
    { min: 5, max: 500, message: '标题长度应在 5 到 500 个字符', trigger: 'blur' }
  ],
  description: [
    { required: true, message: '请输入工单描述', trigger: 'blur' },
    { min: 10, max: 2000, message: '描述长度应在 10 到 2000 个字符', trigger: 'blur' }
  ],
  type: [
    { required: true, message: '请选择工单类型', trigger: 'change' }
  ],
  priority: [
    { required: true, message: '请选择优先级', trigger: 'change' }
  ]
}

// 计算属性
const isEdit = computed(() => !!route.params.id)
const ticketId = computed(() => route.params.id ? Number(route.params.id) : null)

const canEditStatus = computed(() => {
  return authStore.hasPermission('ticket', 'status') || 
         (form.assignee_id === authStore.user?.id)
})

const canAssign = computed(() => {
  return authStore.hasPermission('ticket', 'assign')
})

const uploadUrl = computed(() => {
  return ticketId.value ? `/api/v1/tickets/${ticketId.value}/attachments` : ''
})

const uploadHeaders = computed(() => {
  return {
    'Authorization': `Bearer ${authStore.token}`
  }
})

// 方法
const loadUsers = async () => {
  try {
    const response = await userApi.getUsers({ page: 1, size: 1000 })
    users.value = response.data.items || []
  } catch (error) {
    console.error('加载用户列表失败:', error)
  }
}

const loadTicket = async () => {
  if (!ticketId.value) return
  
  try {
    const response = await ticketApi.getTicket(ticketId.value)
    const ticket = response.data
    
    // 填充表单数据
    Object.assign(form, {
      title: ticket.title,
      description: ticket.description,
      type: ticket.type,
      priority: ticket.priority,
      status: ticket.status,
      assignee_id: ticket.assignee_id,
      due_date: ticket.due_date,
      category: ticket.category,
      tags: ticket.tags || []
    })
    
    // 加载附件
    attachments.value = ticket.attachments || []
  } catch (error) {
    ElMessage.error('加载工单信息失败')
    goBack()
  }
}

const saveTicket = async () => {
  if (!formRef.value) return
  
  try {
    await formRef.value.validate()
    saving.value = true
    
    const data = { ...form }
    
    if (isEdit.value) {
      await ticketApi.updateTicket(ticketId.value, data)
      ElMessage.success('工单更新成功')
    } else {
      const response = await ticketApi.createTicket(data)
      ElMessage.success('工单创建成功')
      router.push(`/tickets/${response.data.id}`)
      return
    }
    
    goBack()
  } catch (error) {
    if (error !== false) { // 不是表单验证错误
      ElMessage.error(isEdit.value ? '更新工单失败' : '创建工单失败')
    }
  } finally {
    saving.value = false
  }
}

const goBack = () => {
  router.back()
}

// 标签管理
const showTagInput = () => {
  tagInputVisible.value = true
  nextTick(() => {
    tagInputRef.value?.focus()
  })
}

const addTag = () => {
  const tag = tagInputValue.value.trim()
  if (tag && !form.tags.includes(tag)) {
    form.tags.push(tag)
  }
  tagInputVisible.value = false
  tagInputValue.value = ''
}

const removeTag = (tag: string) => {
  const index = form.tags.indexOf(tag)
  if (index > -1) {
    form.tags.splice(index, 1)
  }
}

// 附件管理
const beforeUpload = (file: File) => {
  const isValidType = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf', 
                      'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                      'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                      'text/plain'].includes(file.type)
  
  if (!isValidType) {
    ElMessage.error('只能上传图片、PDF、Word、Excel或文本文件')
    return false
  }
  
  const isLt10M = file.size / 1024 / 1024 < 10
  if (!isLt10M) {
    ElMessage.error('文件大小不能超过 10MB')
    return false
  }
  
  return true
}

const handleUploadSuccess = (response: any) => {
  ElMessage.success('附件上传成功')
  attachments.value.push(response.data)
}

const handleUploadError = () => {
  ElMessage.error('附件上传失败')
}

const removeAttachment = async (attachmentId: number) => {
  try {
    await ElMessageBox.confirm('确定要删除这个附件吗？', '确认删除', {
      type: 'warning'
    })
    
    await ticketApi.deleteTicketAttachment(ticketId.value, attachmentId)
    attachments.value = attachments.value.filter(item => item.id !== attachmentId)
    ElMessage.success('附件删除成功')
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除附件失败')
    }
  }
}

const canDeleteAttachment = (attachment: any) => {
  return attachment.uploaded_by === authStore.user?.id || 
         authStore.hasPermission('ticket', 'delete_attachment')
}

const formatFileSize = (bytes: number) => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

// 生命周期
onMounted(() => {
  loadUsers()
  if (isEdit.value) {
    loadTicket()
  }
})
</script>

<style scoped>
.ticket-form {
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
  font-size: 24px;
  font-weight: 600;
}

.form-card {
  margin-bottom: 20px;
}

.attachment-list {
  margin-top: 10px;
}

.attachment-item {
  display: flex;
  align-items: center;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.attachment-item:last-child {
  border-bottom: none;
}

.attachment-name {
  flex: 1;
  margin-left: 8px;
  color: #606266;
}

.attachment-size {
  margin-right: 10px;
  color: #909399;
  font-size: 12px;
}

:deep(.el-form-item__label) {
  font-weight: 500;
}

:deep(.el-textarea__inner) {
  resize: vertical;
}
</style>