<template>
  <div class="export-view">
    <el-row :gutter="20">
      <!-- 导出配置 -->
      <el-col :span="12">
        <el-card>
          <template #header>
            <span>导出配置</span>
          </template>
          
          <el-form :model="exportForm" label-width="100px">
            <el-form-item label="导出格式">
              <el-select v-model="exportForm.format" placeholder="请选择导出格式" style="width: 100%">
                <el-option label="Excel (.xlsx)" value="excel" />
                <el-option label="PDF (.pdf)" value="pdf" />
                <el-option label="CSV (.csv)" value="csv" />
                <el-option label="JSON (.json)" value="json" />
              </el-select>
            </el-form-item>
            
            <el-form-item label="数据类型">
              <el-select v-model="exportForm.dataType" placeholder="请选择数据类型" style="width: 100%">
                <el-option label="记录数据" value="records" />
                <el-option label="文件信息" value="files" />
                <el-option label="用户数据" value="users" />
                <el-option label="系统日志" value="logs" />
              </el-select>
            </el-form-item>
            
            <el-form-item label="时间范围">
              <el-date-picker
                v-model="exportForm.dateRange"
                type="datetimerange"
                range-separator="至"
                start-placeholder="开始时间"
                end-placeholder="结束时间"
                format="YYYY-MM-DD HH:mm"
                value-format="YYYY-MM-DD HH:mm:ss"
                style="width: 100%"
              />
            </el-form-item>
            
            <el-form-item label="筛选条件">
              <el-input
                v-model="exportForm.filters"
                type="textarea"
                :rows="3"
                placeholder="请输入筛选条件（JSON格式）"
              />
            </el-form-item>
            
            <el-form-item label="导出字段">
              <el-checkbox-group v-model="exportForm.fields">
                <el-checkbox v-for="field in availableFields" :key="field.value" :label="field.value">
                  {{ field.label }}
                </el-checkbox>
              </el-checkbox-group>
            </el-form-item>
            
            <el-form-item>
              <el-button type="primary" @click="handleExport" :loading="exporting">
                <el-icon><Download /></el-icon>
                开始导出
              </el-button>
              <el-button @click="handleReset">重置</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
      
      <!-- 导出历史 -->
      <el-col :span="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>导出历史</span>
              <el-button size="small" @click="fetchExportHistory">
                <el-icon><Refresh /></el-icon>
                刷新
              </el-button>
            </div>
          </template>
          
          <el-table :data="exportHistory" v-loading="historyLoading" max-height="500">
            <el-table-column prop="id" label="ID" width="60" />
            <el-table-column prop="format" label="格式" width="80">
              <template #default="{ row }">
                <el-tag size="small">{{ row.format.toUpperCase() }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="dataType" label="数据类型" width="100">
              <template #default="{ row }">
                {{ getDataTypeText(row.dataType) }}
              </template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="100">
              <template #default="{ row }">
                <el-tag :type="getStatusType(row.status)" size="small">
                  {{ getStatusText(row.status) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="progress" label="进度" width="100">
              <template #default="{ row }">
                <el-progress
                  :percentage="row.progress"
                  :status="row.status === 'failed' ? 'exception' : undefined"
                  :stroke-width="6"
                />
              </template>
            </el-table-column>
            <el-table-column prop="createdAt" label="创建时间" width="140">
              <template #default="{ row }">
                {{ formatTime(row.createdAt) }}
              </template>
            </el-table-column>
            <el-table-column label="操作" width="120">
              <template #default="{ row }">
                <el-button
                  v-if="row.status === 'completed' && row.fileUrl"
                  size="small"
                  @click="handleDownload(row)"
                >
                  下载
                </el-button>
                <el-button
                  v-if="row.status === 'failed'"
                  size="small"
                  type="danger"
                  @click="handleRetry(row)"
                >
                  重试
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
    
    <!-- 导出模板管理 -->
    <el-card style="margin-top: 20px;">
      <template #header>
        <div class="card-header">
          <span>导出模板</span>
          <el-button type="primary" @click="handleCreateTemplate">
            <el-icon><Plus /></el-icon>
            新建模板
          </el-button>
        </div>
      </template>
      
      <el-table :data="templates" v-loading="templatesLoading">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="name" label="模板名称" min-width="150" />
        <el-table-column prop="format" label="格式" width="80">
          <template #default="{ row }">
            <el-tag size="small">{{ row.format.toUpperCase() }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="描述" min-width="200" show-overflow-tooltip />
        <el-table-column prop="createdAt" label="创建时间" width="160">
          <template #default="{ row }">
            {{ formatTime(row.createdAt) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200">
          <template #default="{ row }">
            <el-button size="small" @click="handleUseTemplate(row)">使用</el-button>
            <el-button size="small" @click="handleEditTemplate(row)">编辑</el-button>
            <el-button size="small" type="danger" @click="handleDeleteTemplate(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Download, Refresh, Plus } from '@element-plus/icons-vue'
import { http } from '../../utils/request'
import { API_ENDPOINTS } from '../../config/api'
import dayjs from 'dayjs'

// 响应式数据
const exporting = ref(false)
const historyLoading = ref(false)
const templatesLoading = ref(false)
const exportHistory = ref([])
const templates = ref([])

const exportForm = reactive({
  format: 'excel',
  dataType: 'records',
  dateRange: [],
  filters: '',
  fields: ['id', 'title', 'type', 'status', 'createdAt']
})

// 可用字段配置
const availableFields = computed(() => {
  const fieldMap = {
    records: [
      { label: 'ID', value: 'id' },
      { label: '标题', value: 'title' },
      { label: '类型', value: 'type' },
      { label: '状态', value: 'status' },
      { label: '内容', value: 'content' },
      { label: '创建者', value: 'creator' },
      { label: '创建时间', value: 'createdAt' },
      { label: '更新时间', value: 'updatedAt' }
    ],
    files: [
      { label: 'ID', value: 'id' },
      { label: '文件名', value: 'originalName' },
      { label: '文件类型', value: 'mimeType' },
      { label: '文件大小', value: 'size' },
      { label: '上传者', value: 'uploader' },
      { label: '上传时间', value: 'createdAt' }
    ],
    users: [
      { label: 'ID', value: 'id' },
      { label: '用户名', value: 'username' },
      { label: '邮箱', value: 'email' },
      { label: '角色', value: 'roles' },
      { label: '状态', value: 'isActive' },
      { label: '最后登录', value: 'lastLogin' },
      { label: '创建时间', value: 'createdAt' }
    ],
    logs: [
      { label: 'ID', value: 'id' },
      { label: '级别', value: 'level' },
      { label: '分类', value: 'category' },
      { label: '消息', value: 'message' },
      { label: '用户', value: 'user' },
      { label: '时间', value: 'createdAt' }
    ]
  }
  return fieldMap[exportForm.dataType] || []
})

// 开始导出
const handleExport = async () => {
  if (!exportForm.format || !exportForm.dataType) {
    ElMessage.warning('请选择导出格式和数据类型')
    return
  }
  
  if (exportForm.fields.length === 0) {
    ElMessage.warning('请至少选择一个导出字段')
    return
  }
  
  exporting.value = true
  try {
    // 构建符合后端期望的数据结构
    const filters: Record<string, string> = {}
    
    // 处理时间范围
    if (exportForm.dateRange && exportForm.dateRange.length === 2) {
      filters.start_time = exportForm.dateRange[0]
      filters.end_time = exportForm.dateRange[1]
    }
    
    // 处理自定义筛选条件
    if (exportForm.filters) {
      try {
        const customFilters = JSON.parse(exportForm.filters)
        Object.assign(filters, customFilters)
      } catch (e) {
        console.warn('筛选条件JSON格式错误，已忽略')
      }
    }
    
    const data = {
      format: exportForm.format,
      task_name: `${exportForm.dataType}_export_${new Date().getTime()}`,
      filters: filters,
      fields: exportForm.fields,
      config: {
        data_type: exportForm.dataType,
        date_range: exportForm.dateRange
      }
    }
    
    console.log('发送导出请求:', data)
    
    const response = await http.post(API_ENDPOINTS.EXPORT.RECORDS, data)
    
    if (response.success && response.data) {
      ElMessage.success('导出任务已创建，请在导出历史中查看进度')
      fetchExportHistory()
    } else {
      ElMessage.success('导出成功')
    }
  } catch (error: any) {
    console.error('导出失败:', error)
    let errorMessage = '导出失败'
    if (error.response?.data?.error?.message) {
      errorMessage = error.response.data.error.message
    } else if (error.message) {
      errorMessage = error.message
    }
    ElMessage.error(errorMessage)
  } finally {
    exporting.value = false
  }
}

// 重置表单
const handleReset = () => {
  Object.assign(exportForm, {
    format: 'excel',
    dataType: 'records',
    dateRange: [],
    filters: '',
    fields: ['id', 'title', 'type', 'status', 'createdAt']
  })
}

// 获取导出历史
const fetchExportHistory = async () => {
  historyLoading.value = true
  try {
    // 获取导出任务列表
    const response = await http.get(API_ENDPOINTS.EXPORT.TASKS)
    
    if (response.success && response.data && response.data.tasks) {
      // 转换后端数据格式为前端期望的格式
      exportHistory.value = response.data.tasks.map((task: any) => ({
        id: task.id,
        format: task.format,
        dataType: task.config ? JSON.parse(task.config).data_type || 'records' : 'records',
        status: task.status,
        progress: task.progress || 0,
        fileUrl: task.status === 'completed' && task.file_path ? 
          `/export/files/${task.id}/download` : null,
        createdAt: task.created_at,
        taskName: task.task_name,
        totalRecords: task.total_records,
        processedRecords: task.processed_records,
        errorMessage: task.error_message
      }))
    } else {
      exportHistory.value = []
    }
  } catch (error) {
    console.error('获取导出历史失败:', error)
    ElMessage.error('获取导出历史失败')
    exportHistory.value = []
  } finally {
    historyLoading.value = false
  }
}

// 获取正确的文件扩展名
const getFileExtension = (format: string) => {
  const extensionMap: { [key: string]: string } = {
    'excel': 'xlsx',
    'pdf': 'pdf',
    'csv': 'csv',
    'json': 'json'
  }
  return extensionMap[format] || format
}

// 下载导出文件
const handleDownload = async (row: any) => {
  if (!row.fileUrl) return
  
  try {
    // 使用带认证的请求下载文件
    const response = await http.get(row.fileUrl, {
      responseType: 'blob'
    })
    
    // 创建下载链接
    const blob = new Blob([response])
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `export_${row.id}.${getFileExtension(row.format)}`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    
    ElMessage.success('文件下载成功')
  } catch (error) {
    console.error('下载文件失败:', error)
    ElMessage.error('下载文件失败')
  }
}

// 重试导出
const handleRetry = async (row: any) => {
  try {
    await http.post(`${API_ENDPOINTS.EXPORT.RECORDS}/${row.id}/retry`)
    ElMessage.success('重试任务已创建')
    fetchExportHistory()
  } catch (error) {
    console.error('重试失败:', error)
    ElMessage.error('重试失败')
  }
}

// 获取导出模板
const fetchTemplates = async () => {
  templatesLoading.value = true
  try {
    const response = await http.get(API_ENDPOINTS.EXPORT.TEMPLATES)
    
    if (response.success && response.data && response.data.templates) {
      templates.value = response.data.templates
    } else {
      // 使用模拟数据
      templates.value = [
        {
          id: 1,
          name: '记录导出模板',
          format: 'excel',
          description: '导出所有记录的基本信息',
          createdAt: new Date().toISOString()
        },
        {
          id: 2,
          name: '文件信息模板',
          format: 'csv',
          description: '导出文件的详细信息',
          createdAt: new Date(Date.now() - 86400000).toISOString()
        }
      ]
    }
  } catch (error) {
    console.error('获取模板失败:', error)
    templates.value = []
  } finally {
    templatesLoading.value = false
  }
}

// 模板操作
const handleCreateTemplate = () => {
  ElMessage.info('创建模板功能开发中')
}

const handleUseTemplate = (row: any) => {
  ElMessage.success(`已应用模板: ${row.name}`)
  // TODO: 应用模板配置到导出表单
}

const handleEditTemplate = (row: any) => {
  ElMessage.info('编辑模板功能开发中')
}

const handleDeleteTemplate = async (row: any) => {
  try {
    await ElMessageBox.confirm('确定要删除这个模板吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await http.delete(`${API_ENDPOINTS.EXPORT.TEMPLATES}/${row.id}`)
    ElMessage.success('删除成功')
    fetchTemplates()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除模板失败:', error)
      ElMessage.error('删除模板失败')
    }
  }
}

// 工具函数
const getDataTypeText = (dataType: string) => {
  const typeMap: { [key: string]: string } = {
    records: '记录数据',
    files: '文件信息',
    users: '用户数据',
    logs: '系统日志'
  }
  return typeMap[dataType] || dataType
}

const getStatusType = (status: string) => {
  const statusMap: { [key: string]: string } = {
    pending: 'info',
    processing: 'warning',
    completed: 'success',
    failed: 'danger'
  }
  return statusMap[status] || 'info'
}

const getStatusText = (status: string) => {
  const statusMap: { [key: string]: string } = {
    pending: '等待中',
    processing: '处理中',
    completed: '已完成',
    failed: '失败'
  }
  return statusMap[status] || status
}

const formatTime = (time: string) => {
  return dayjs(time).format('MM-DD HH:mm')
}

// 生命周期
onMounted(() => {
  fetchExportHistory()
  fetchTemplates()
})
</script>

<style scoped>
.export-view {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.el-checkbox-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.el-checkbox-group .el-checkbox {
  margin-right: 0;
}

@media (max-width: 768px) {
  .export-view {
    padding: 10px;
  }
  
  .el-row {
    flex-direction: column;
  }
  
  .el-col {
    margin-bottom: 20px;
  }
}
</style>
