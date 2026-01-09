<template>
  <div class="record-form">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>{{ isEdit ? '编辑记录' : '新建记录' }}</span>
          <el-button @click="handleBack">返回列表</el-button>
        </div>
      </template>

      <!-- 用户信息提示 -->
      <el-alert
        v-if="!isEdit"
        :title="`创建者：${authStore.user?.username || '当前用户'}`"
        type="info"
        :closable="false"
        style="margin-bottom: 20px;"
      >
        <template #default>
          <div>
            <p>记录将以您的身份创建，其他用户可以看到创建者信息。</p>
            <p>选择"草稿"状态可以稍后继续编辑，选择"发布"状态将对其他用户可见。</p>
          </div>
        </template>
      </el-alert>

      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="100px"
        v-loading="loading"
      >
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="记录标题" prop="title">
              <el-input v-model="form.title" placeholder="请输入记录标题" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="记录类型" prop="type">
              <el-select 
                v-model="form.type" 
                placeholder="请选择记录类型" 
                style="width: 100%"
                @change="handleTypeChange"
              >
                <el-option 
                  v-for="type in recordTypes" 
                  :key="type.name" 
                  :label="type.description" 
                  :value="type.name" 
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="记录状态" prop="status">
              <el-select 
                v-model="form.status" 
                placeholder="请选择状态" 
                style="width: 100%"
              >
                <el-option 
                  label="草稿" 
                  value="draft"
                >
                  <div class="status-option">
                    <el-tag type="info" size="small">草稿</el-tag>
                    <span class="status-desc">保存为草稿，可继续编辑</span>
                  </div>
                </el-option>
                <el-option 
                  label="发布" 
                  value="published"
                >
                  <div class="status-option">
                    <el-tag type="success" size="small">发布</el-tag>
                    <span class="status-desc">正式发布，对其他用户可见</span>
                  </div>
                </el-option>
                <el-option 
                  label="归档" 
                  value="archived"
                >
                  <div class="status-option">
                    <el-tag type="warning" size="small">归档</el-tag>
                    <span class="status-desc">归档记录，不再显示在列表中</span>
                  </div>
                </el-option>
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <!-- 动态字段渲染 -->
        <div v-if="selectedRecordType && selectedRecordType.fields && selectedRecordType.fields.length > 0" class="dynamic-fields-section">
          <el-divider content-position="left">
            <span style="color: #409eff; font-weight: bold;">{{ selectedRecordType.description }} - 字段配置</span>
          </el-divider>
          <DynamicForm
            :fields="selectedRecordType.fields"
            v-model="form.dynamicFields"
            @field-change="handleDynamicFieldChange"
          />
        </div>

        <!-- 通用字段（始终显示） -->
        <div class="common-fields-section">
          <el-divider content-position="left">
            <span style="color: #67c23a; font-weight: bold;">通用字段</span>
          </el-divider>
          
          <el-row :gutter="20">
            <el-col :span="24">
              <el-form-item label="标签" prop="tags">
                <el-input 
                  v-model="form.tags" 
                  placeholder="请输入标签，用逗号分隔（如：工作,重要,紧急）" 
                  clearable
                />
              </el-form-item>
            </el-col>
          </el-row>

          <el-form-item label="备注内容" prop="content">
            <el-input
              v-model="form.content"
              type="textarea"
              :rows="6"
              placeholder="请输入备注内容或补充说明..."
              show-word-limit
              maxlength="2000"
            />
          </el-form-item>
        </div>

        <el-form-item label="附件管理">
          <!-- 调试信息 -->
          <div v-if="isEdit" class="debug-info" style="margin-bottom: 16px; padding: 12px; background: #f0f9ff; border-radius: 4px; border-left: 4px solid #409eff;">
            <h4 style="margin: 0 0 8px 0; color: #409eff; font-size: 12px;">调试信息</h4>
            <p style="margin: 0; font-size: 12px; color: #666;">
              当前 fileList 长度: {{ fileList.length }}<br>
              fileList 内容: {{ JSON.stringify(fileList.map(f => ({ name: f.name, id: f.id, uid: f.uid })), null, 2) }}
            </p>
          </div>
          
          <!-- 现有附件显示 -->
          <div v-if="existingAttachments.length > 0" class="existing-attachments">
            <h4 style="margin: 0 0 12px 0; color: #606266; font-size: 14px;">
              <el-icon><Paperclip /></el-icon>
              当前附件 ({{ existingAttachments.length }})
            </h4>
            <div class="attachments-list">
              <div 
                v-for="(file, index) in existingAttachments" 
                :key="`existing-${file.id || index}`"
                class="attachment-item"
              >
                <div class="file-icon">
                  <el-icon size="20">
                    <Picture v-if="isImageFile(file)" />
                    <Document v-else-if="isDocumentFile(file)" />
                    <Files v-else />
                  </el-icon>
                </div>
                <div class="file-info">
                  <span class="file-name">{{ file.name || file.filename || '未知文件' }}</span>
                  <span class="file-size">{{ formatFileSize(file.size) }}</span>
                </div>
                <div class="file-actions">
                  <el-button 
                    size="small" 
                    type="danger" 
                    @click="removeExistingFile(index)"
                  >
                    删除
                  </el-button>
                </div>
              </div>
            </div>
          </div>
          
          <!-- 新上传文件显示 -->
          <div v-if="newUploadedFiles.length > 0" class="new-files">
            <h4 style="margin: 16px 0 12px 0; color: #67c23a; font-size: 14px;">
              <el-icon><Plus /></el-icon>
              新上传文件 ({{ newUploadedFiles.length }})
            </h4>
            <div class="attachments-list">
              <div 
                v-for="(file, index) in newUploadedFiles" 
                :key="`new-${file.uid || index}`"
                class="attachment-item"
              >
                <div class="file-icon">
                  <el-icon size="20">
                    <Picture v-if="isImageFile(file)" />
                    <Document v-else-if="isDocumentFile(file)" />
                    <Files v-else />
                  </el-icon>
                </div>
                <div class="file-info">
                  <span class="file-name">{{ file.name }}</span>
                  <span class="file-size">{{ formatFileSize(file.size) }}</span>
                  <span class="file-status" style="color: #67c23a; font-size: 12px;">✓ 已上传</span>
                </div>
                <div class="file-actions">
                  <el-button 
                    size="small" 
                    type="danger" 
                    @click="removeNewFile(index)"
                  >
                    删除
                  </el-button>
                </div>
              </div>
            </div>
          </div>
          
          <!-- 文件上传区域 -->
          <div class="upload-section" style="margin-top: 20px;">
            <h4 style="margin: 0 0 12px 0; color: #606266; font-size: 14px;">
              <el-icon><UploadFilled /></el-icon>
              上传新文件
            </h4>
            <el-upload
              ref="uploadRef"
              :action="uploadUrl"
              :headers="uploadHeaders"
              :on-success="handleUploadSuccess"
              :on-error="handleUploadError"
              :before-upload="beforeUpload"
              multiple
              drag
              :show-file-list="false"
              :auto-upload="true"
            >
              <el-icon class="el-icon--upload"><upload-filled /></el-icon>
              <div class="el-upload__text">
                将文件拖到此处，或<em>点击上传</em>
              </div>
              <template #tip>
                <div class="el-upload__tip">
                  支持jpg/png/gif/pdf/doc/docx/xls/xlsx文件，且不超过10MB
                </div>
              </template>
            </el-upload>
          </div>
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="handleSubmit" :loading="submitting">
            {{ isEdit ? '更新' : '创建' }}
          </el-button>
          <el-button @click="handleReset">重置</el-button>
          <el-button @click="handleBack">取消</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { UploadFilled, Paperclip, Picture, Document, Files, Delete, Plus } from '@element-plus/icons-vue'
import { http } from '../../utils/request'
import { useAuthStore } from '../../stores/auth'
import { API_CONFIG, API_ENDPOINTS } from '../../config/api'
import DynamicForm from '../../components/DynamicForm.vue'
import { useEventBus } from '../../utils/eventBus'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const { emit } = useEventBus()

// 响应式数据
const formRef = ref()
const uploadRef = ref()
const loading = ref(false)
const submitting = ref(false)
const fileList = ref([]) // 保留原有的fileList用于兼容
const existingAttachments = ref([]) // 现有附件
const newUploadedFiles = ref([]) // 新上传的文件
const recordTypes = ref([])

const form = reactive({
  title: '',
  type: '',
  status: 'draft',
  content: '',
  tags: '',
  dynamicFields: {}
})

// 计算属性
const isEdit = computed(() => !!route.params.id)
const recordId = computed(() => route.params.id as string)

const selectedRecordType = computed(() => {
  return recordTypes.value.find(type => type.name === form.type)
})

const uploadUrl = computed(() => `${API_CONFIG.BASE_URL}${API_CONFIG.VERSION}${API_ENDPOINTS.FILES.UPLOAD}`)
const uploadHeaders = computed(() => ({
  Authorization: `Bearer ${authStore.token}`
}))

// 表单验证规则
const rules = {
  title: [
    { required: true, message: '请输入记录标题', trigger: 'blur' },
    { min: 2, max: 100, message: '标题长度在 2 到 100 个字符', trigger: 'blur' }
  ],
  type: [
    { required: true, message: '请选择记录类型', trigger: 'change' }
  ],
  status: [
    { required: true, message: '请选择记录状态', trigger: 'change' }
  ]
}

// 获取记录详情
const fetchRecord = async () => {
  if (!isEdit.value) return
  
  loading.value = true
  try {
    const response = await http.get(API_ENDPOINTS.RECORDS.DETAIL(parseInt(recordId.value)))
    
    // 处理后端响应格式
    let recordData
    if (response.success && response.data) {
      recordData = response.data
    } else if (response.id) {
      recordData = response
    } else {
      throw new Error('无效的响应格式')
    }
    
    // 处理状态字段
    const status = recordData.status || 
                   (recordData.content && recordData.content.status) || 
                   'draft'
    
    // 处理标签字段
    let tagsString = ''
    if (Array.isArray(recordData.tags)) {
      tagsString = recordData.tags.join(', ')
    } else if (typeof recordData.tags === 'string') {
      tagsString = recordData.tags
    } else if (recordData.content && recordData.content.tags) {
      if (Array.isArray(recordData.content.tags)) {
        tagsString = recordData.content.tags.join(', ')
      } else {
        tagsString = recordData.content.tags
      }
    }
    
    // 处理内容字段
    let contentString = ''
    let dynamicFieldsData = {}
    
    if (recordData.content) {
      if (typeof recordData.content === 'string') {
        contentString = recordData.content
      } else if (typeof recordData.content === 'object') {
        dynamicFieldsData = recordData.content
        if (recordData.content.description) {
          contentString = recordData.content.description
        } else if (recordData.content.content) {
          contentString = recordData.content.content
        }
      }
    }
    
    Object.assign(form, {
      title: recordData.title || '未命名记录',
      type: recordData.type || 'other',
      status: status,
      content: contentString,
      tags: tagsString,
      dynamicFields: dynamicFieldsData
    })
    
    // 清空附件数据
    existingAttachments.value = []
    newUploadedFiles.value = []
    fileList.value = []
    
    // 从多个可能的位置获取附件数据
    let attachmentSources = []
    
    console.log('记录数据结构:', recordData)
    
    // 检查不同的附件数据位置
    if (recordData.content) {
      console.log('content字段存在:', recordData.content)
      
      if (recordData.content.attachments && Array.isArray(recordData.content.attachments)) {
        console.log('找到 content.attachments:', recordData.content.attachments)
        attachmentSources.push(...recordData.content.attachments)
      }
      
      if (recordData.content.files && Array.isArray(recordData.content.files)) {
        console.log('找到 content.files:', recordData.content.files)
        attachmentSources.push(...recordData.content.files)
      }
    }
    
    if (recordData.files && Array.isArray(recordData.files)) {
      console.log('找到 files:', recordData.files)
      attachmentSources.push(...recordData.files)
    }
    
    // 去重（基于ID）
    const uniqueAttachments = []
    const seenIds = new Set()
    
    attachmentSources.forEach((file, index) => {
      const fileId = file.id || `temp-${index}`
      if (!seenIds.has(fileId)) {
        seenIds.add(fileId)
        uniqueAttachments.push({
          id: file.id,
          name: file.name || file.filename || file.original_name || `文件${index + 1}`,
          filename: file.filename || file.name,
          original_name: file.original_name || file.name,
          size: file.size || 0,
          mimeType: file.mimeType || file.mime_type || file.type,
          type: file.type || file.mimeType || file.mime_type,
          url: file.url || file.path,
          path: file.path || file.url,
          uid: file.id || `existing-${index}`,
          status: 'success'
        })
      }
    })
    
    existingAttachments.value = uniqueAttachments
    console.log('加载的现有附件:', existingAttachments.value)
    
    console.log('编辑记录数据:', form)
  } catch (error) {
    console.error('获取记录详情失败:', error)
    
    let errorMessage = '获取记录详情失败'
    if (error.response?.status === 404) {
      errorMessage = '记录不存在或已被删除'
    } else if (error.response?.status === 403) {
      errorMessage = '没有权限编辑此记录'
    }
    
    ElMessage.error(errorMessage)
    handleBack()
  } finally {
    loading.value = false
  }
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return
  
  try {
    await formRef.value.validate()
    
    submitting.value = true
    
    // 构建内容数据 - 确保content不为空对象
    let contentData = {}
    
    // 如果有动态字段，使用动态字段数据
    if (selectedRecordType.value?.fields && Object.keys(form.dynamicFields).length > 0) {
      contentData = { ...form.dynamicFields }
    }
    
    // 添加通用内容
    if (form.content) {
      contentData.description = form.content
    }
    
    // 添加状态信息到内容中
    if (form.status) {
      contentData.status = form.status
    }
    
    // 合并所有附件（现有的 + 新上传的）
    const allAttachments = [
      ...existingAttachments.value,
      ...newUploadedFiles.value
    ]
    
    console.log('准备保存的所有附件:', allAttachments)
    
    if (allAttachments.length > 0) {
      const attachments = allAttachments
        .filter((file: any) => file.id && file.status === 'success')
        .map((file: any) => ({
          id: file.id,
          name: file.name || file.filename,
          filename: file.filename || file.name,
          original_name: file.original_name || file.name,
          size: file.size || 0,
          mimeType: file.mimeType || file.type,
          type: file.type || file.mimeType,
          url: file.url || file.path,
          path: file.path || file.url
        }))
      
      if (attachments.length > 0) {
        contentData.attachments = attachments
        console.log('最终保存的附件信息:', attachments)
        console.log(`共包含 ${attachments.length} 个附件`)
      }
    } else {
      console.log('没有附件需要保存')
    }
    
    // 确保content至少有一个字段
    if (Object.keys(contentData).length === 0) {
      contentData.description = form.title || '记录内容'
    }
    
    // 处理标签
    const tagsArray = form.tags ? 
      form.tags.split(',').map(tag => tag.trim()).filter(Boolean) : 
      []
    
    // 构建最终提交数据
    const submitData = {
      type: form.type,  // 添加必需的type字段
      title: form.title,
      content: contentData,
      tags: tagsArray
    }
    
    console.log('提交数据:', submitData)
    
    let response
    if (isEdit.value) {
      response = await http.put(API_ENDPOINTS.RECORDS.UPDATE(parseInt(recordId.value)), submitData)
      ElMessage.success('记录更新成功')
      // 触发记录更新事件
      emit('record:updated')
    } else {
      response = await http.post(API_ENDPOINTS.RECORDS.CREATE, submitData)
      ElMessage.success('记录创建成功')
      // 触发记录创建事件
      emit('record:created')
    }
    
    console.log('提交响应:', response)
    
    // 延迟一下再返回，确保后端数据已更新
    setTimeout(() => {
      handleBack()
    }, 500)
  } catch (error: any) {
    if (error.fields) {
      // 表单验证错误
      return
    }
    
    console.error('保存记录失败:', error)
    
    let errorMessage = '保存记录失败'
    if (error.response?.status === 400) {
      errorMessage = '请求参数错误，请检查输入内容'
    } else if (error.response?.status === 403) {
      errorMessage = '没有权限执行此操作'
    } else if (error.response?.status === 404) {
      errorMessage = '记录不存在或已被删除'
    } else if (error.response?.data?.message) {
      errorMessage = error.response.data.message
    } else if (error.message) {
      errorMessage = error.message
    }
    
    ElMessage.error(errorMessage)
  } finally {
    submitting.value = false
  }
}

// 重置表单
const handleReset = () => {
  if (formRef.value) {
    formRef.value.resetFields()
  }
  form.content = ''
  form.dynamicFields = {}
  
  // 重置附件相关数据
  fileList.value = []
  existingAttachments.value = []
  newUploadedFiles.value = []
}

// 返回列表
const handleBack = () => {
  router.push('/records')
}

// 文件上传处理
const beforeUpload = (file: File) => {
  const isValidType = [
    'image/jpeg', 'image/png', 'image/gif',
    'application/pdf',
    'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  ].includes(file.type)
  
  if (!isValidType) {
    ElMessage.error('只支持jpg/png/gif/pdf/doc/docx/xls/xlsx格式的文件')
    return false
  }
  
  const isLt10M = file.size / 1024 / 1024 < 10
  if (!isLt10M) {
    ElMessage.error('文件大小不能超过10MB')
    return false
  }
  
  return true
}

const handleUploadSuccess = (response: any, file: any) => {
  console.log('文件上传成功响应:', response)
  console.log('上传的文件对象:', file)
  
  if (response.success && response.data) {
    const fileInfo = {
      id: response.data.id,
      name: response.data.filename || response.data.original_name || file.name,
      filename: response.data.filename || file.name,
      original_name: response.data.original_name || file.name,
      size: response.data.size || file.size,
      mimeType: response.data.mime_type || file.type,
      type: response.data.mime_type || file.type,
      url: response.data.url || response.data.path,
      path: response.data.path || response.data.url,
      uid: file.uid || `upload-${Date.now()}`,
      status: 'success'
    }
    
    // 添加到新上传文件列表
    newUploadedFiles.value.push(fileInfo)
    
    console.log('新上传文件已添加:', fileInfo.name)
    console.log('当前新上传文件列表:', newUploadedFiles.value)
    
    ElMessage.success(`文件 "${fileInfo.name}" 上传成功`)
  } else {
    console.error('文件上传失败，响应:', response)
    ElMessage.error('文件上传失败')
  }
}

const handleUploadError = (error: any, file: any) => {
  console.error('文件上传错误:', error, file)
  ElMessage.error(`文件 "${file.name}" 上传失败`)
}

// 删除现有附件
const removeExistingFile = (index: number) => {
  const file = existingAttachments.value[index]
  console.log('删除现有附件:', file)
  
  existingAttachments.value.splice(index, 1)
  ElMessage.success(`文件 "${file.name}" 已从记录中移除`)
  
  console.log('删除后的现有附件列表:', existingAttachments.value)
}

// 删除新上传的文件
const removeNewFile = (index: number) => {
  const file = newUploadedFiles.value[index]
  console.log('删除新上传文件:', file)
  
  newUploadedFiles.value.splice(index, 1)
  ElMessage.success(`文件 "${file.name}" 已移除`)
  
  console.log('删除后的新上传文件列表:', newUploadedFiles.value)
}

// 保留原有的删除函数用于兼容
const handleRemoveFile = async (file: any) => {
  console.log('删除文件（兼容函数）:', file)
  // 这个函数现在主要用于兼容，实际删除通过上面两个函数处理
}

// 获取记录类型列表
const fetchRecordTypes = async () => {
  try {
    const response = await http.get(API_ENDPOINTS.RECORD_TYPES.LIST)
    
    if (response.success && response.data) {
      recordTypes.value = response.data
        .filter((type: any) => type.is_active !== false)
        .map((type: any) => ({
          name: type.name,
          description: type.display_name || type.description,
          fields: type.schema?.fields || type.fields || []
        }))
    } else {
      // 使用默认类型（包含字段定义）
      recordTypes.value = [
        { 
          name: 'work', 
          description: '工作记录',
          fields: [
            { name: 'title', label: '标题', type: 'text', required: true },
            { name: 'description', label: '描述', type: 'textarea', required: true },
            { name: 'tags', label: '标签', type: 'tags', required: false }
          ]
        },
        { 
          name: 'study', 
          description: '学习笔记',
          fields: [
            { name: 'title', label: '标题', type: 'text', required: true },
            { name: 'content', label: '内容', type: 'textarea', required: true },
            { name: 'tags', label: '标签', type: 'tags', required: false }
          ]
        },
        { 
          name: 'project', 
          description: '项目文档',
          fields: [
            { name: 'title', label: '标题', type: 'text', required: true },
            { name: 'description', label: '描述', type: 'textarea', required: true },
            { name: 'status', label: '状态', type: 'select', required: true, options: ['进行中', '已完成', '暂停'] },
            { name: 'tags', label: '标签', type: 'tags', required: false }
          ]
        },
        { 
          name: 'other', 
          description: '其他',
          fields: [
            { name: 'title', label: '标题', type: 'text', required: true },
            { name: 'content', label: '内容', type: 'textarea', required: true },
            { name: 'tags', label: '标签', type: 'tags', required: false }
          ]
        }
      ]
    }
  } catch (error) {
    console.error('获取记录类型失败:', error)
    // 使用默认类型（包含字段定义）
    recordTypes.value = [
      { 
        name: 'work', 
        description: '工作记录',
        fields: [
          { name: 'title', label: '标题', type: 'text', required: true },
          { name: 'description', label: '描述', type: 'textarea', required: true },
          { name: 'tags', label: '标签', type: 'tags', required: false }
        ]
      },
      { 
        name: 'study', 
        description: '学习笔记',
        fields: [
          { name: 'title', label: '标题', type: 'text', required: true },
          { name: 'content', label: '内容', type: 'textarea', required: true },
          { name: 'tags', label: '标签', type: 'tags', required: false }
        ]
      }
    ]
    ElMessage.warning('API连接异常，使用默认记录类型。请检查后端服务是否正常运行。')
  }
}

// 处理类型变化
const handleTypeChange = (typeValue: string) => {
  console.log('选择的记录类型:', typeValue)
  
  // 重置动态字段
  form.dynamicFields = {}
  
  // 根据选择的类型初始化字段默认值
  const selectedType = recordTypes.value.find(type => type.name === typeValue)
  if (selectedType && selectedType.fields) {
    const initialFields = {}
    selectedType.fields.forEach(field => {
      if (field.type === 'tags') {
        initialFields[field.name] = []
      } else if (field.type === 'file') {
        initialFields[field.name] = []
      } else {
        initialFields[field.name] = ''
      }
    })
    form.dynamicFields = initialFields
  }
  
  ElMessage.success(`已切换到 ${selectedType?.description || typeValue} 类型`)
}

// 处理动态字段变化
const handleDynamicFieldChange = (fieldName: string, value: any) => {
  console.log('动态字段变化:', fieldName, value)
}

// 文件类型判断工具函数
const isImageFile = (file: any) => {
  if (!file) return false
  const mimeType = file.mimeType || file.type || ''
  const filename = file.name || file.filename || ''
  return mimeType.startsWith('image/') || /\.(jpg|jpeg|png|gif|bmp|webp|svg)$/i.test(filename)
}

const isDocumentFile = (file: any) => {
  if (!file) return false
  const mimeType = file.mimeType || file.type || ''
  const filename = file.name || file.filename || ''
  return mimeType.includes('pdf') || 
         mimeType.includes('document') || 
         mimeType.includes('text') ||
         /\.(pdf|doc|docx|txt|md|rtf)$/i.test(filename)
}

const formatFileSize = (size: any) => {
  if (!size || size === 0) return '未知大小'
  
  const bytes = parseInt(size)
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
  return (bytes / (1024 * 1024 * 1024)).toFixed(1) + ' GB'
}

// 生命周期
onMounted(() => {
  fetchRecordTypes()
  if (isEdit.value) {
    fetchRecord()
  }
})
</script>

<style scoped>
.record-form {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.el-upload {
  width: 100%;
}

.dynamic-fields-section {
  margin-bottom: 20px;
  padding: 15px;
  background-color: #f8f9fa;
  border-radius: 6px;
  border-left: 4px solid #409eff;
}

.common-fields-section {
  margin-bottom: 20px;
  padding: 15px;
  background-color: #f0f9ff;
  border-radius: 6px;
  border-left: 4px solid #67c23a;
}

.el-upload {
  width: 100%;
}

.el-upload__tip {
  color: #606266;
  font-size: 12px;
  margin-top: 7px;
}

.status-option {
  display: flex;
  align-items: center;
  gap: 8px;
}

.status-desc {
  color: #606266;
  font-size: 12px;
}

/* 附件管理样式 */
.existing-attachments {
  margin-bottom: 16px;
  padding: 16px;
  background-color: #f8f9fa;
  border-radius: 6px;
  border: 1px solid #e9ecef;
}

.attachments-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.attachment-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 12px;
  background-color: white;
  border-radius: 4px;
  border: 1px solid #e4e7ed;
  transition: box-shadow 0.2s;
}

.attachment-item:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.file-icon {
  color: #606266;
  flex-shrink: 0;
}

.file-info {
  flex: 1;
  min-width: 0;
}

.file-name {
  display: block;
  font-weight: 500;
  color: #303133;
  margin-bottom: 2px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.file-size {
  display: block;
  font-size: 12px;
  color: #909399;
}

.file-actions {
  flex-shrink: 0;
}

.upload-section {
  border: 2px dashed #d9d9d9;
  border-radius: 6px;
  padding: 16px;
  transition: border-color 0.3s;
}

.upload-section:hover {
  border-color: #409eff;
}

@media (max-width: 768px) {
  .record-form {
    padding: 10px;
  }
  
  .el-col {
    margin-bottom: 10px;
  }
  
  .dynamic-fields-section,
  .common-fields-section {
    padding: 10px;
  }
  
  .status-desc {
    display: none;
  }
}
</style>
