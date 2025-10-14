<template>
  <div class="record-detail">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>记录详情</span>
          <div>
            <el-button @click="handleEdit">编辑</el-button>
            <el-button @click="handleBack">返回</el-button>
          </div>
        </div>
      </template>

      <div v-loading="loading">
        <el-descriptions v-if="record" :column="2" border>
          <el-descriptions-item label="记录ID">{{ record.id }}</el-descriptions-item>
          <el-descriptions-item label="标题">{{ record.title }}</el-descriptions-item>
          <el-descriptions-item label="类型">
            <el-tag>{{ getTypeText(record.type) }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="getStatusType(record.status)">
              {{ getStatusText(record.status) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="创建者">{{ record.creator }}</el-descriptions-item>
          <el-descriptions-item label="版本">{{ record.version }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ formatTime(record.createdAt) }}</el-descriptions-item>
          <el-descriptions-item label="更新时间">{{ formatTime(record.updatedAt) }}</el-descriptions-item>
          <el-descriptions-item label="标签" :span="2">
            <el-tag
              v-for="tag in record.tags"
              :key="tag"
              size="small"
              style="margin-right: 4px;"
            >
              {{ tag }}
            </el-tag>
            <span v-if="!record.tags || record.tags.length === 0" class="no-tags">无标签</span>
          </el-descriptions-item>
        </el-descriptions>

        <!-- 内容详情区域 -->
        <div v-if="record" class="content-section">
          <h3>记录内容</h3>
          
          <!-- 备注/描述内容 -->
          <div v-if="getDescription(record.content)" class="description-section">
            <h4><el-icon><Document /></el-icon> 描述</h4>
            <div class="description-content">
              {{ getDescription(record.content) }}
            </div>
          </div>

          <!-- 附件文件 -->
          <div v-if="getAttachments(record.content).length > 0" class="attachments-section">
            <h4><el-icon><Paperclip /></el-icon> 附件 ({{ getAttachments(record.content).length }})</h4>
            
            <!-- 调试信息 -->
            <div v-if="showRawData" class="debug-attachments" style="margin-bottom: 16px;">
              <el-alert title="附件调试信息" type="info" :closable="false">
                <pre style="font-size: 12px; margin: 8px 0;">{{ JSON.stringify(getAttachments(record.content), null, 2) }}</pre>
              </el-alert>
            </div>
            
            <div class="attachments-grid">
              <div 
                v-for="(file, index) in getAttachments(record.content)" 
                :key="index"
                class="attachment-item"
              >
                <!-- 图片预览 -->
                <div v-if="isImage(file)" class="image-preview">
                  <SimpleImagePreview :file="file" />
                  <div class="file-info">
                    <span class="file-name">{{ file.name || file.filename || '未知文件' }}</span>
                    <span class="file-size">{{ formatFileSize(file.size) }}</span>
                    <span class="file-url" style="font-size: 10px; color: #999;">{{ getFileUrl(file) }}</span>
                  </div>
                </div>

                <!-- 非图片文件 -->
                <div v-else class="file-item">
                  <div class="file-icon">
                    <el-icon size="32">
                      <Document v-if="isDocument(file)" />
                      <VideoPlay v-else-if="isVideo(file)" />
                      <Headset v-else-if="isAudio(file)" />
                      <Files v-else />
                    </el-icon>
                  </div>
                  <div class="file-info">
                    <span class="file-name">{{ file.name || file.filename || '未知文件' }}</span>
                    <span class="file-size">{{ formatFileSize(file.size) }}</span>
                    <span class="file-type">{{ getFileType(file) }}</span>
                  </div>
                  <div class="file-actions">
                    <el-button size="small" @click="downloadFile(file)">
                      <el-icon><Download /></el-icon>
                      下载
                    </el-button>
                    <el-button v-if="canPreview(file)" size="small" @click="previewFile(file)">
                      <el-icon><View /></el-icon>
                      预览
                    </el-button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- 其他内容字段 -->
          <div v-if="getOtherFields(record.content).length > 0" class="other-fields-section">
            <h4><el-icon><List /></el-icon> 其他信息</h4>
            <el-descriptions :column="1" border>
              <el-descriptions-item 
                v-for="field in getOtherFields(record.content)"
                :key="field.key"
                :label="field.label"
              >
                <div class="field-content">
                  {{ field.value }}
                </div>
              </el-descriptions-item>
            </el-descriptions>
          </div>

          <!-- 原始JSON数据（调试用） -->
          <el-collapse v-if="showRawData" style="margin-top: 20px;">
            <el-collapse-item title="原始数据 (调试)" name="raw">
              <pre class="raw-data">{{ JSON.stringify(record.content, null, 2) }}</pre>
            </el-collapse-item>
          </el-collapse>
          
          <div class="debug-toggle">
            <el-button size="small" text @click="showRawData = !showRawData">
              {{ showRawData ? '隐藏' : '显示' }}原始数据
            </el-button>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 文件预览对话框 -->
    <el-dialog
      v-model="previewDialogVisible"
      title="文件预览"
      width="80%"
      :before-close="closePreview"
    >
      <div v-if="currentPreviewFile" class="file-preview">
        <!-- 图片预览 -->
        <div v-if="isImage(currentPreviewFile)" class="image-preview-large">
          <SimpleImagePreview :file="currentPreviewFile" />
        </div>
        
        <!-- 文本文件预览 -->
        <div v-else-if="isText(currentPreviewFile)" class="text-preview">
          <pre>{{ previewContent }}</pre>
        </div>
        
        <!-- 其他文件类型 -->
        <div v-else class="unsupported-preview">
          <el-icon size="64"><Document /></el-icon>
          <p>此文件类型不支持预览</p>
          <el-button @click="downloadFile(currentPreviewFile)">下载文件</el-button>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, defineComponent, h, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, ElImage, ElIcon } from 'element-plus'
import { 
  Document, 
  Paperclip, 
  Picture, 
  VideoPlay, 
  Headset, 
  Files, 
  Download, 
  View,
  List,
  Loading
} from '@element-plus/icons-vue'
import { http } from '@/utils/request'
import { useAuthStore } from '@/stores/auth'
import { API_ENDPOINTS, API_CONFIG } from '@/config/api'
import dayjs from 'dayjs'

// 简单图片预览组件 - 参考文件管理组件的实现
const SimpleImagePreview = defineComponent({
  props: {
    file: {
      type: Object,
      required: true
    }
  },
  setup(props) {
    const authStore = useAuthStore()
    const imageUrl = ref('')
    const loading = ref(true)
    const error = ref(false)
    
    const fileUrl = computed(() => {
      console.log('构建文件URL，文件信息:', props.file)
      
      // 优先使用文件ID构建标准API路径
      if (props.file.id) {
        const url = `${API_CONFIG.BASE_URL}${API_CONFIG.VERSION}/files/${props.file.id}`
        console.log('使用文件ID构建URL:', url)
        return url
      }
      
      // 备用：使用其他路径信息
      let url = props.file.url || props.file.path || props.file.src
      
      if (url) {
        if (url.startsWith('/api/')) {
          return `${API_CONFIG.BASE_URL}${url}`
        }
        if (url.startsWith('/')) {
          return `${API_CONFIG.BASE_URL}${url}`
        }
        if (url.startsWith('http://') || url.startsWith('https://')) {
          return url
        }
        return `${API_CONFIG.BASE_URL}/${url}`
      }
      
      console.warn('无法构建文件URL，文件信息:', props.file)
      return ''
    })
    
    const loadImage = async () => {
      try {
        loading.value = true
        error.value = false
        
        if (!fileUrl.value) {
          throw new Error('无法获取文件URL')
        }
        
        if (!authStore.token) {
          throw new Error('用户未登录')
        }
        
        console.log('开始加载图片:', fileUrl.value)
        console.log('使用认证token:', authStore.token.substring(0, 20) + '...')
        
        // 使用fetch API带认证头请求，完全参考文件管理组件的实现
        const response = await fetch(fileUrl.value, {
          headers: {
            'Authorization': `Bearer ${authStore.token}`,
            'Accept': 'image/*'
          }
        })
        
        console.log('图片请求响应:', response.status, response.statusText)
        
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`)
        }
        
        const blob = await response.blob()
        console.log('图片blob信息:', {
          type: blob.type,
          size: blob.size
        })
        
        // 验证是否为图片格式
        if (!blob.type.startsWith('image/')) {
          throw new Error(`文件不是图片格式: ${blob.type}`)
        }
        
        const objectUrl = URL.createObjectURL(blob)
        imageUrl.value = objectUrl
        loading.value = false
        
        console.log('图片加载成功，ObjectURL:', objectUrl)
        
      } catch (err) {
        console.error('加载图片失败:', err)
        error.value = true
        loading.value = false
      }
    }
    
    onMounted(() => {
      console.log('SimpleImagePreview组件挂载，开始加载图片')
      loadImage()
    })
    
    // 组件卸载时清理URL
    onUnmounted(() => {
      if (imageUrl.value) {
        console.log('清理ObjectURL:', imageUrl.value)
        URL.revokeObjectURL(imageUrl.value)
      }
    })
    
    return () => {
      if (loading.value) {
        return h('div', { 
          class: 'image-loading',
          style: 'display: flex; flex-direction: column; align-items: center; justify-content: center; height: 200px; background-color: #f0f9ff; color: #409eff;'
        }, [
          h(ElIcon, { 
            size: 32,
            style: 'margin-bottom: 8px; animation: spin 1s linear infinite;'
          }, () => h(Loading)),
          h('span', '加载中...')
        ])
      }
      
      if (error.value) {
        return h('div', { 
          class: 'image-error',
          style: 'display: flex; flex-direction: column; align-items: center; justify-content: center; height: 200px; background-color: #f5f7fa; color: #c0c4cc; padding: 16px; text-align: center;'
        }, [
          h(ElIcon, { 
            size: 48,
            style: 'margin-bottom: 8px;'
          }, () => h(Picture)),
          h('span', { style: 'margin-bottom: 4px;' }, '加载失败'),
          h('div', { 
            class: 'error-url',
            style: 'font-size: 10px; color: #999; word-break: break-all; max-width: 100%;'
          }, fileUrl.value)
        ])
      }
      
      return h(ElImage, {
        src: imageUrl.value,
        previewSrcList: [imageUrl.value],
        fit: 'cover',
        alt: props.file.name || props.file.filename || '图片',
        style: 'width: 100%; height: 200px; display: block;',
        lazy: true,
        onError: () => {
          console.error('ElImage组件加载失败')
          error.value = true
        },
        onLoad: () => {
          console.log('ElImage组件加载成功')
        }
      })
    }
  }
})

// 图片加载现在由SimpleImagePreview组件独立处理

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const loading = ref(false)
const record = ref(null)
const showRawData = ref(false)
const previewDialogVisible = ref(false)
const currentPreviewFile = ref(null)
const previewContent = ref('')

const recordId = route.params.id as string

// 获取记录详情
const fetchRecord = async () => {
  loading.value = true
  try {
    const response = await http.get(API_ENDPOINTS.RECORDS.DETAIL(parseInt(recordId)))
    console.log('获取记录详情响应:', response)
    
    // 处理后端响应格式
    let recordData
    if (response.success && response.data) {
      recordData = response.data
    } else if (response.id) {
      // 直接返回记录数据的情况
      recordData = response
    } else {
      throw new Error('无效的响应格式')
    }
    
    // 处理标签数据
    let tagsArray = []
    if (Array.isArray(recordData.tags)) {
      tagsArray = recordData.tags
    } else if (typeof recordData.tags === 'string') {
      tagsArray = recordData.tags.split(',').filter(t => t.trim())
    } else if (recordData.content && recordData.content.tags) {
      if (Array.isArray(recordData.content.tags)) {
        tagsArray = recordData.content.tags
      } else if (typeof recordData.content.tags === 'string') {
        tagsArray = recordData.content.tags.split(',').filter(t => t.trim())
      }
    }
    
    record.value = {
      id: recordData.id,
      title: recordData.title || '未命名记录',
      type: recordData.type || 'other',
      status: recordData.status || 
              (recordData.content && recordData.content.status) || 
              'draft',
      content: recordData.content || {},
      tags: tagsArray,
      creator: recordData.creator || recordData.creator_name || '未知用户',
      version: recordData.version || 1,
      createdAt: recordData.created_at || recordData.createdAt || new Date().toISOString(),
      updatedAt: recordData.updated_at || recordData.updatedAt || new Date().toISOString()
    }
    
    console.log('处理后的记录数据:', record.value)
    console.log('记录内容:', record.value.content)
    console.log('附件数据:', getAttachments(record.value.content))
  } catch (error) {
    console.error('获取记录详情失败:', error)
    
    let errorMessage = '获取记录详情失败'
    if (error.response?.status === 404) {
      errorMessage = '记录不存在或已被删除'
    } else if (error.response?.status === 403) {
      errorMessage = '没有权限查看此记录'
    }
    
    ElMessage.error(errorMessage)
    handleBack()
  } finally {
    loading.value = false
  }
}

// 编辑记录
const handleEdit = () => {
  router.push(`/records/${recordId}/edit`)
}

// 返回列表
const handleBack = () => {
  router.push('/records')
}

// 工具函数
const getTypeText = (type: string) => {
  const typeMap: { [key: string]: string } = {
    work: '工作记录',
    study: '学习笔记',
    project: '项目文档',
    other: '其他'
  }
  return typeMap[type] || type
}

const getStatusType = (status: string) => {
  const statusMap: { [key: string]: string } = {
    draft: 'info',
    published: 'success',
    archived: 'warning'
  }
  return statusMap[status] || 'info'
}

const getStatusText = (status: string) => {
  const statusMap: { [key: string]: string } = {
    draft: '草稿',
    published: '已发布',
    archived: '已归档'
  }
  return statusMap[status] || status
}

const getContentText = (content: any) => {
  if (typeof content === 'string') {
    return content
  } else if (content && content.description) {
    return content.description
  } else if (content) {
    return JSON.stringify(content, null, 2)
  }
  return '无内容'
}

const formatTime = (time: string) => {
  return dayjs(time).format('YYYY-MM-DD HH:mm:ss')
}

// 内容处理函数
const getDescription = (content: any) => {
  if (!content) return ''
  
  // 尝试多种可能的描述字段
  return content.description || 
         content.content ||
         content.备注 || 
         content.remark || 
         content.note || 
         content.comment || 
         (typeof content === 'string' ? content : '')
}

const getAttachments = (content: any) => {
  if (!content) return []
  
  // 尝试多种可能的附件字段
  let attachments = content.attachments || 
                   content.files || 
                   content.images || 
                   content.附件 || 
                   content.文件 || 
                   []
  
  // 确保返回数组
  if (!Array.isArray(attachments)) {
    return []
  }
  
  // 过滤掉无效的附件对象
  return attachments.filter(file => 
    file && 
    (file.name || file.filename || file.original_name) &&
    (file.url || file.path || file.id)
  )
}

const getOtherFields = (content: any) => {
  if (!content || typeof content !== 'object') return []
  
  const excludeKeys = [
    'description', '备注', 'remark', 'note', 'comment', 'content',
    'attachments', 'files', 'images', '附件', '文件', 
    'status', 'statusUpdatedAt'
  ]
  const fields = []
  
  for (const [key, value] of Object.entries(content)) {
    if (!excludeKeys.includes(key) && value !== null && value !== undefined && value !== '') {
      // 跳过空数组和空对象
      if (Array.isArray(value) && value.length === 0) continue
      if (typeof value === 'object' && Object.keys(value).length === 0) continue
      
      fields.push({
        key,
        label: getFieldLabel(key),
        value: formatFieldValue(value)
      })
    }
  }
  
  return fields
}

const getFieldLabel = (key: string) => {
  const labelMap: { [key: string]: string } = {
    title: '标题',
    type: '类型',
    priority: '优先级',
    deadline: '截止时间',
    assignee: '负责人',
    progress: '进度',
    category: '分类',
    location: '位置',
    url: '链接',
    phone: '电话',
    email: '邮箱',
    amount: '金额',
    quantity: '数量'
  }
  return labelMap[key] || key
}

const formatFieldValue = (value: any) => {
  if (Array.isArray(value)) {
    return value.join(', ')
  } else if (typeof value === 'object') {
    return JSON.stringify(value, null, 2)
  } else {
    return String(value)
  }
}

// 文件处理函数
const isImage = (file: any) => {
  if (!file) return false
  const mimeType = file.mimeType || file.mime_type || file.type || ''
  const filename = file.name || file.filename || file.original_name || ''
  
  return mimeType.startsWith('image/') || 
         /\.(jpg|jpeg|png|gif|bmp|webp|svg)$/i.test(filename)
}

const isDocument = (file: any) => {
  if (!file) return false
  const mimeType = file.mimeType || file.mime_type || file.type || ''
  const filename = file.name || file.filename || file.original_name || ''
  
  return mimeType.includes('pdf') || 
         mimeType.includes('document') || 
         mimeType.includes('text') ||
         /\.(pdf|doc|docx|txt|md|rtf)$/i.test(filename)
}

const isVideo = (file: any) => {
  if (!file) return false
  const mimeType = file.mimeType || file.mime_type || file.type || ''
  const filename = file.name || file.filename || file.original_name || ''
  
  return mimeType.startsWith('video/') || 
         /\.(mp4|avi|mov|wmv|flv|webm)$/i.test(filename)
}

const isAudio = (file: any) => {
  if (!file) return false
  const mimeType = file.mimeType || file.mime_type || file.type || ''
  const filename = file.name || file.filename || file.original_name || ''
  
  return mimeType.startsWith('audio/') || 
         /\.(mp3|wav|flac|aac|ogg)$/i.test(filename)
}

const isText = (file: any) => {
  if (!file) return false
  const mimeType = file.mimeType || file.mime_type || file.type || ''
  const filename = file.name || file.filename || file.original_name || ''
  
  return mimeType.startsWith('text/') || 
         /\.(txt|md|json|xml|csv|log)$/i.test(filename)
}

const canPreview = (file: any) => {
  return isImage(file) || isText(file)
}

const getFileType = (file: any) => {
  const filename = file.name || file.filename || file.original_name || ''
  const extension = filename.split('.').pop()?.toUpperCase()
  return extension || '未知'
}

const formatFileSize = (size: any) => {
  if (!size || size === 0) return '未知大小'
  
  const bytes = parseInt(size)
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
  return (bytes / (1024 * 1024 * 1024)).toFixed(1) + ' GB'
}

const getFileUrl = (file: any) => {
  // 尝试多种可能的URL字段
  let url = file.url || file.path || file.src || file.downloadUrl
  
  if (url) {
    // 如果是相对路径，添加API基础URL
    if (url.startsWith('/')) {
      return `${API_CONFIG.BASE_URL}${url}`
    }
    // 如果是完整URL，直接返回
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url
    }
    // 其他情况，添加基础URL
    return `${API_CONFIG.BASE_URL}/${url}`
  }
  
  // 如果有文件ID，构造下载URL
  if (file.id) {
    return `${API_CONFIG.BASE_URL}${API_CONFIG.VERSION}/files/${file.id}`
  }
  
  // 如果有文件名但没有URL，尝试构造默认路径
  if (file.name || file.filename) {
    const filename = file.name || file.filename
    return `${API_CONFIG.BASE_URL}/uploads/${filename}`
  }
  
  return ''
}

// 简化的图片处理逻辑已移至SimpleImagePreview组件

const downloadFile = async (file: any) => {
  try {
    const url = getFileUrl(file)
    console.log('下载文件URL:', url)
    console.log('文件信息:', file)
    
    if (!url) {
      ElMessage.error('无法获取文件下载链接')
      return
    }
    
    if (!authStore.token) {
      ElMessage.error('用户未登录，无法下载文件')
      return
    }
    
    // 使用带认证的请求下载文件
    const response = await http.get(url, {
      responseType: 'blob'
    })
    
    console.log('下载响应:', response)
    
    // 创建下载链接
    const blob = new Blob([response.data])
    const downloadUrl = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = downloadUrl
    link.download = file.name || file.filename || file.original_name || 'download'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(downloadUrl)
    
    ElMessage.success('文件下载成功')
  } catch (error) {
    console.error('下载文件失败:', error)
    
    let errorMessage = '下载文件失败'
    if (error.response?.status === 403) {
      errorMessage = '没有权限访问此文件'
    } else if (error.response?.status === 404) {
      errorMessage = '文件不存在'
    } else if (error.response?.status === 401) {
      errorMessage = '认证失败，请重新登录'
    }
    
    ElMessage.error(errorMessage)
  }
}

const previewFile = async (file: any) => {
  currentPreviewFile.value = file
  previewContent.value = ''
  
  if (isText(file)) {
    try {
      // 使用带认证的请求获取文本内容
      const url = getFileUrl(file)
      const response = await http.get(url, {
        responseType: 'text',
        headers: {
          'Authorization': `Bearer ${authStore.token}`
        }
      })
      previewContent.value = response.data
    } catch (error) {
      console.error('获取文件内容失败:', error)
      previewContent.value = '无法加载文件内容'
    }
  }
  
  previewDialogVisible.value = true
}

const closePreview = () => {
  previewDialogVisible.value = false
  currentPreviewFile.value = null
  previewContent.value = ''
}

// 生命周期
onMounted(() => {
  fetchRecord()
})
</script>

<style scoped>
.record-detail {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.no-tags {
  color: #c0c4cc;
  font-style: italic;
}

/* 内容区域 */
.content-section {
  margin-top: 24px;
}

.content-section h3 {
  margin: 0 0 16px 0;
  color: #303133;
  font-size: 18px;
  border-bottom: 2px solid #409eff;
  padding-bottom: 8px;
}

.content-section h4 {
  margin: 16px 0 12px 0;
  color: #606266;
  font-size: 14px;
  display: flex;
  align-items: center;
  gap: 6px;
}

/* 描述区域 */
.description-section {
  margin-bottom: 24px;
}

.description-content {
  background-color: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 6px;
  padding: 16px;
  line-height: 1.6;
  white-space: pre-wrap;
  word-wrap: break-word;
  min-height: 60px;
}

/* 附件区域 */
.attachments-section {
  margin-bottom: 24px;
}

.attachments-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 16px;
  margin-top: 12px;
}

.attachment-item {
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  overflow: hidden;
  background: white;
  transition: box-shadow 0.2s;
}

.attachment-item:hover {
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

/* 图片预览 */
.image-preview {
  position: relative;
}

.preview-image {
  width: 100%;
  height: 200px;
  display: block;
}

.image-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 200px;
  color: #409eff;
  background-color: #f0f9ff;
}

.image-loading .el-icon {
  font-size: 32px;
  margin-bottom: 8px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

/* 确保图片预览容器正确显示 */
.image-preview {
  position: relative;
  background: white;
  border-radius: 8px;
  overflow: hidden;
}

.image-preview .el-image {
  display: block;
  width: 100%;
  height: 200px;
}

/* 加载和错误状态样式 */
.image-loading {
  display: flex !important;
  flex-direction: column !important;
  align-items: center !important;
  justify-content: center !important;
  height: 200px !important;
  background-color: #f0f9ff !important;
  color: #409eff !important;
}

.image-error {
  display: flex !important;
  flex-direction: column !important;
  align-items: center !important;
  justify-content: center !important;
  height: 200px !important;
  background-color: #f5f7fa !important;
  color: #c0c4cc !important;
  padding: 16px !important;
  text-align: center !important;
}

.image-error {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 200px;
  color: #c0c4cc;
  background-color: #f5f7fa;
  padding: 16px;
  text-align: center;
}

.image-error .el-icon {
  font-size: 48px;
  margin-bottom: 8px;
}

.error-url {
  word-break: break-all;
  max-width: 100%;
}

/* 文件项 */
.file-item {
  padding: 16px;
  display: flex;
  align-items: center;
  gap: 12px;
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
  margin-bottom: 4px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.file-size {
  display: block;
  font-size: 12px;
  color: #909399;
  margin-bottom: 2px;
}

.file-url {
  display: block;
  font-size: 10px;
  color: #c0c4cc;
  word-break: break-all;
  margin-top: 2px;
}

.authenticated-image-container {
  position: relative;
  width: 100%;
  height: 200px;
}

.authenticated-image-container .preview-image {
  width: 100%;
  height: 100%;
}

.file-type {
  display: inline-block;
  background-color: #f0f2f5;
  color: #606266;
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 11px;
  font-weight: 500;
}

.file-actions {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.file-actions .el-button {
  margin: 0;
  padding: 4px 8px;
  font-size: 12px;
}

/* 其他字段区域 */
.other-fields-section {
  margin-bottom: 24px;
}

.field-content {
  white-space: pre-wrap;
  word-wrap: break-word;
  max-height: 200px;
  overflow-y: auto;
}

/* 原始数据 */
.raw-data {
  background-color: #f5f5f5;
  padding: 12px;
  border-radius: 4px;
  font-size: 12px;
  line-height: 1.4;
  overflow-x: auto;
}

.debug-toggle {
  text-align: center;
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid #e4e7ed;
}

/* 预览对话框 */
.file-preview {
  text-align: center;
}

.image-preview-large {
  max-height: 70vh;
  overflow: auto;
}

.text-preview {
  text-align: left;
  background-color: #f5f5f5;
  padding: 16px;
  border-radius: 6px;
  max-height: 60vh;
  overflow: auto;
}

.text-preview pre {
  margin: 0;
  white-space: pre-wrap;
  word-wrap: break-word;
  font-family: 'Courier New', monospace;
  font-size: 13px;
  line-height: 1.4;
}

.unsupported-preview {
  padding: 40px;
  color: #909399;
}

.unsupported-preview .el-icon {
  color: #c0c4cc;
  margin-bottom: 16px;
}

.unsupported-preview p {
  margin: 16px 0;
  font-size: 14px;
}

@media (max-width: 768px) {
  .record-detail {
    padding: 10px;
  }
  
  .attachments-grid {
    grid-template-columns: 1fr;
  }
  
  .file-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
  
  .file-actions {
    flex-direction: row;
    width: 100%;
  }
  
  .file-actions .el-button {
    flex: 1;
  }
}
</style>