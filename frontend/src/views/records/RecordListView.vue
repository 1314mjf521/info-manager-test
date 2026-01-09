<template>
  <div class="record-list">
    <!-- API连接状态提示 -->
    <el-alert
      v-if="!apiConnected && records.length === 0"
      title="后端服务连接异常"
      type="error"
      :closable="true"
      style="margin-bottom: 20px;"
    >
      <template #default>
        <div>
          <p>无法连接到后端服务，请检查：</p>
          <ul style="margin: 8px 0; padding-left: 20px;">
            <li>后端服务是否在 localhost:8080 运行</li>
            <li>网络连接是否正常</li>
            <li>防火墙是否阻止了连接</li>
          </ul>
        </div>
      </template>
    </el-alert>

    <el-card>
      <template #header>
        <div class="card-header">
          <span>记录管理</span>
          <div class="header-buttons">
            <el-button @click="handleRefresh" :loading="loading">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
            <el-dropdown @command="handleImportAction">
              <el-button type="success">
                <el-icon><Upload /></el-icon>
                导入记录
                <el-icon class="el-icon--right"><ArrowDown /></el-icon>
              </el-button>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="template">下载模板</el-dropdown-item>
                  <el-dropdown-item command="import" divided>导入记录</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
            <el-button type="primary" @click="handleCreate">
              <el-icon><Plus /></el-icon>
              新建记录
            </el-button>
          </div>
        </div>
      </template>

      <!-- 批量操作栏 -->
      <div class="batch-actions" v-if="selectedRecords.length > 0">
        <el-alert
          :title="`已选择 ${selectedRecords.length} 条记录`"
          type="info"
          :closable="false"
          style="margin-bottom: 15px;"
        >
          <template #default>
            <div class="batch-buttons">
              <el-button size="small" type="success" @click="handleBatchPublish">
                批量发布
              </el-button>
              <el-button size="small" type="warning" @click="handleBatchDraft">
                批量转草稿
              </el-button>
              <el-button size="small" type="danger" @click="handleBatchDelete">
                批量删除
              </el-button>
              <el-button size="small" @click="clearSelection">
                取消选择
              </el-button>
            </div>
          </template>
        </el-alert>
      </div>

      <!-- 搜索栏 -->
      <div class="search-bar">
        <el-form :model="searchForm" inline>
          <el-form-item label="标题">
            <el-input v-model="searchForm.title" placeholder="请输入记录标题" clearable />
          </el-form-item>
          <el-form-item label="类型">
            <el-select v-model="searchForm.type" placeholder="请选择记录类型" clearable style="width: 150px;">
              <el-option label="全部类型" value="" />
              <el-option 
                v-for="type in recordTypes" 
                :key="type.name" 
                :label="type.description" 
                :value="type.name" 
              />
            </el-select>
          </el-form-item>
          <el-form-item label="状态">
            <el-select v-model="searchForm.status" placeholder="请选择状态" clearable style="width: 120px;">
              <el-option label="全部状态" value="" />
              <el-option label="草稿" value="draft" />
              <el-option label="已发布" value="published" />
              <el-option label="已归档" value="archived" />
            </el-select>
          </el-form-item>
          <el-form-item label="标签">
            <el-input v-model="searchForm.tags" placeholder="请输入标签，用逗号分隔" clearable />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleSearch">搜索</el-button>
            <el-button @click="handleReset">重置</el-button>
          </el-form-item>
        </el-form>
      </div>

      <!-- 记录表格 -->
      <el-table 
        :data="records" 
        v-loading="loading" 
        stripe 
        :header-cell-style="{ background: '#f5f7fa', color: '#606266' }"
        style="width: 100%"
        :default-sort="{ prop: 'createdAt', order: 'descending' }"
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="50" />
        
        <!-- ID列 -->
        <el-table-column prop="id" label="ID" width="60" align="center" />
        
        <!-- 标题列 -->
        <el-table-column label="标题" min-width="200">
          <template #default="{ row }">
            <div class="record-title-cell">
              <el-icon class="record-icon"><Document /></el-icon>
              <span class="title-text">{{ row.title }}</span>
            </div>
          </template>
        </el-table-column>

        <!-- 类型列 -->
        <el-table-column label="类型" width="100">
          <template #default="{ row }">
            <el-tag size="small" class="type-tag">{{ getTypeText(row.type) }}</el-tag>
          </template>
        </el-table-column>

        <!-- 状态列 -->
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag 
              :type="getStatusType(row.status)" 
              size="small"
            >
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>

        <!-- 标签列 -->
        <el-table-column label="标签" width="150">
          <template #default="{ row }">
            <div class="tags-container">
              <el-tag
                v-for="tag in (row.tags || []).slice(0, 2)"
                :key="tag"
                size="small"
                class="tag-item"
                effect="plain"
              >
                {{ tag }}
              </el-tag>
              <el-tooltip 
                v-if="(row.tags || []).length > 2"
                :content="(row.tags || []).slice(2).join(', ')"
                placement="top"
              >
                <el-tag size="small" type="info" effect="plain">
                  +{{ (row.tags || []).length - 2 }}
                </el-tag>
              </el-tooltip>
              <span v-if="!(row.tags || []).length" class="no-tags">无</span>
            </div>
          </template>
        </el-table-column>

        <!-- 创建者列 -->
        <el-table-column label="创建者" width="120">
          <template #default="{ row }">
            <div class="creator-info">
              <el-avatar :size="24" class="creator-avatar">
                {{ getCreatorInitial(row) }}
              </el-avatar>
              <span class="creator-name">{{ getCreatorName(row) }}</span>
            </div>
          </template>
        </el-table-column>

        <!-- 版本列 -->
        <el-table-column label="版本" width="60" align="center">
          <template #default="{ row }">
            <el-tag size="small" type="info">v{{ row.version || 1 }}</el-tag>
          </template>
        </el-table-column>

        <!-- 创建时间列 -->
        <el-table-column label="创建时间" width="140" sortable prop="createdAt">
          <template #default="{ row }">
            <span class="time-text">{{ formatTime(row.createdAt) }}</span>
          </template>
        </el-table-column>

        <!-- 更新时间列 -->
        <el-table-column label="更新时间" width="140" sortable prop="updatedAt">
          <template #default="{ row }">
            <span class="time-text">{{ formatTime(row.updatedAt) }}</span>
          </template>
        </el-table-column>

        <!-- 操作列 -->
        <el-table-column label="操作" width="280" fixed="right">
          <template #default="{ row }">
            <div class="action-buttons">
              <el-button size="small" @click="handleView(row)">查看</el-button>
              <el-button size="small" type="primary" @click="handleEdit(row)">编辑</el-button>
              <el-dropdown size="small" @command="(command) => handleStatusChange(row, command)">
                <el-button size="small" type="warning" :loading="row.statusLoading">
                  状态<el-icon class="el-icon--right"><ArrowDown /></el-icon>
                </el-button>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item command="draft">设为草稿</el-dropdown-item>
                    <el-dropdown-item command="published">设为已发布</el-dropdown-item>
                    <el-dropdown-item command="archived">设为已归档</el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
              <el-button size="small" type="danger" @click="handleDelete(row)">删除</el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.size"
          :total="pagination.total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 导入记录对话框 -->
    <el-dialog v-model="importDialogVisible" title="导入记录" width="600px">
      <div class="import-section">
        <el-alert
          title="导入说明"
          type="info"
          :closable="false"
          show-icon
          style="margin-bottom: 20px;"
        >
          <template #default>
            <div style="font-size: 14px;">
              <p>1. 请先下载模板文件，按照模板格式填写记录信息</p>
              <p>2. 支持的文件格式：Excel (.xlsx, .xls) 或 CSV (.csv)</p>
              <p>3. 必填字段：标题、类型</p>
              <p>4. 可选字段：内容、标签、状态</p>
            </div>
          </template>
        </el-alert>

        <el-upload
          ref="recordUploadRef"
          class="upload-demo"
          drag
          :auto-upload="false"
          :on-change="handleRecordFileChange"
          :before-upload="beforeRecordUpload"
          accept=".xlsx,.xls,.csv"
          :limit="1"
        >
          <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
          <div class="el-upload__text">
            将文件拖到此处，或<em>点击上传</em>
          </div>
          <template #tip>
            <div class="el-upload__tip">
              只能上传 xlsx/xls/csv 文件，且不超过 10MB
            </div>
          </template>
        </el-upload>

        <div v-if="importRecordFile" class="file-info" style="margin-top: 20px;">
          <el-card>
            <div style="display: flex; align-items: center; justify-content: space-between;">
              <div>
                <el-icon><Document /></el-icon>
                <span style="margin-left: 8px;">{{ importRecordFile.name }}</span>
                <el-tag size="small" style="margin-left: 8px;">{{ formatFileSize(importRecordFile.size) }}</el-tag>
              </div>
              <el-button size="small" type="danger" @click="removeRecordFile">移除</el-button>
            </div>
          </el-card>
        </div>

        <div v-if="importRecordPreview.length > 0" class="preview-section" style="margin-top: 20px;">
          <h4>数据预览 (前5条)</h4>
          <el-table :data="importRecordPreview.slice(0, 5)" size="small" max-height="300">
            <el-table-column prop="title" label="标题" width="200" />
            <el-table-column prop="type" label="类型" width="100" />
            <el-table-column prop="content" label="内容" width="200" show-overflow-tooltip />
            <el-table-column prop="tags" label="标签" width="150" />
            <el-table-column prop="status" label="状态" width="80" />
          </el-table>
          <div style="margin-top: 10px; color: #666; font-size: 14px;">
            共 {{ importRecordPreview.length }} 条数据，将导入 {{ validImportRecordData.length }} 条有效数据
          </div>
        </div>
      </div>

      <template #footer>
        <div class="dialog-footer">
          <el-button @click="importDialogVisible = false">取消</el-button>
          <el-button @click="downloadRecordTemplate">下载模板</el-button>
          <el-button 
            type="primary" 
            @click="handleImportRecords" 
            :loading="importing"
            :disabled="!importRecordFile || validImportRecordData.length === 0"
          >
            导入记录 ({{ validImportRecordData.length }})
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onActivated } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox, ElLoading } from 'element-plus'
import { Plus, Refresh, Document, ArrowDown, Upload, UploadFilled } from '@element-plus/icons-vue'
import { http } from '../../utils/request'
import { API_ENDPOINTS } from '../../config/api'
import { useEventBus } from '../../utils/eventBus'
import dayjs from 'dayjs'

const router = useRouter()
const { emit } = useEventBus()

// 响应式数据
const loading = ref(false)
const records = ref([])
const recordTypes = ref([])
const apiConnected = ref(true)
const selectedRecords = ref([])

// 导入相关数据
const importDialogVisible = ref(false)
const importing = ref(false)
const importRecordFile = ref(null)
const importRecordPreview = ref([])
const validImportRecordData = ref([])
const recordUploadRef = ref()

// 导入操作处理
const handleImportAction = (command: string) => {
  switch (command) {
    case 'template':
      downloadRecordTemplate()
      break
    case 'import':
      importDialogVisible.value = true
      break
  }
}

// 下载记录导入模板
const downloadRecordTemplate = () => {
  const template = [
    ['标题*', '类型*', '内容', '标签', '状态'],
    ['示例记录1', 'work', '这是一个工作记录的示例内容', '工作,重要', 'published'],
    ['示例记录2', 'study', '这是一个学习记录的示例内容', '学习,笔记', 'draft']
  ]
  
  // 创建CSV内容
  const csvContent = template.map(row => row.join(',')).join('\n')
  const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)
  
  link.setAttribute('href', url)
  link.setAttribute('download', '记录导入模板.csv')
  link.style.visibility = 'hidden'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  
  ElMessage.success('Template downloaded successfully')
}

// 文件上传处理
const handleRecordFileChange = (file: any) => {
  importRecordFile.value = file.raw
  parseImportRecordFile(file.raw)
}

// 文件上传前检查
const beforeRecordUpload = (file: any) => {
  const isValidType = ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 
                      'application/vnd.ms-excel', 
                      'text/csv'].includes(file.type)
  const isLt10M = file.size / 1024 / 1024 < 10

  if (!isValidType) {
    ElMessage.error('Only Excel or CSV files are allowed!')
    return false
  }
  if (!isLt10M) {
    ElMessage.error('File size cannot exceed 10MB!')
    return false
  }
  return false // 阻止自动上传
}

// 解析导入文件
const parseImportRecordFile = async (file: File) => {
  try {
    const text = await file.text()
    const lines = text.split('\n').filter(line => line.trim())
    
    if (lines.length < 2) {
      ElMessage.error('File content cannot be empty')
      return
    }
    
    // 解析CSV数据
    const data = lines.slice(1).map(line => {
      const values = line.split(',').map(v => v.trim().replace(/"/g, ''))
      return {
        title: values[0] || '',
        type: values[1] || '',
        content: values[2] || '',
        tags: values[3] || '',
        status: values[4] || 'draft'
      }
    })
    
    importRecordPreview.value = data
    
    // 验证数据
    validImportRecordData.value = data.filter(item => 
      item.title && item.type
    )
    
    if (validImportRecordData.value.length === 0) {
      ElMessage.error('No valid record data found')
    } else {
      ElMessage.success(`Parsing successful, found ${validImportRecordData.value.length} valid records`)
    }
  } catch (error) {
    console.error('解析文件失败:', error)
    ElMessage.error('File parsing failed')
  }
}

// 移除文件
const removeRecordFile = () => {
  importRecordFile.value = null
  importRecordPreview.value = []
  validImportRecordData.value = []
  recordUploadRef.value?.clearFiles()
}

// 执行导入 - 优化版本，支持进度显示和错误处理
const handleImportRecords = async () => {
  if (validImportRecordData.value.length === 0) {
    ElMessage.warning('No valid data to import')
    return
  }
  
  try {
    importing.value = true
    
    // 显示进度提示
    const loadingInstance = ElLoading.service({
      lock: true,
      text: 'Importing records, please wait...',
      background: 'rgba(0, 0, 0, 0.7)'
    })
    
    // 按记录类型分组
    const recordsByType = {}
    validImportRecordData.value.forEach(record => {
      if (!recordsByType[record.type]) {
        recordsByType[record.type] = []
      }
      recordsByType[record.type].push({
        title: record.title,
        content: { description: record.content },
        tags: record.tags ? record.tags.split(',').map(tag => tag.trim()) : [],
        status: record.status || 'draft'
      })
    })

    // 分批导入，避免一次性导入过多数据
    const allResults = []
    const allErrors = []
    let processedCount = 0
    const totalCount = validImportRecordData.value.length
    
    for (const [type, records] of Object.entries(recordsByType)) {
      try {
        // Update progress
        loadingInstance.setText(`Importing ${type} type records... (${processedCount}/${totalCount})`)
        
        const response = await http.post(API_ENDPOINTS.RECORDS.IMPORT, {
          type: type,
          records: records
        })
        
        if (response.success && response.data) {
          allResults.push(...response.data)
          processedCount += records.length
        } else {
          allErrors.push(`${type} type import failed: ${response.message || 'Unknown error'}`)
        }
        
        // 添加短暂延迟，避免过快请求
        await new Promise(resolve => setTimeout(resolve, 100))
        
      } catch (error) {
        console.error(`导入 ${type} 类型记录失败:`, error)
        allErrors.push(`${type} type import failed: ${error.message || 'Network error'}`)
      }
    }
    
    loadingInstance.close()
    
    // 显示结果
    const successCount = allResults.length
    const failCount = totalCount - successCount
    
    if (allErrors.length === 0) {
      ElMessage.success(`Successfully imported ${successCount} records`)
    } else if (successCount > 0) {
      ElMessage.warning({
        message: `Import completed: ${successCount} successful, ${failCount} failed`,
        duration: 5000
      })
      
      // 显示详细错误信息
      if (allErrors.length > 0) {
        ElMessageBox.alert(
          allErrors.join('\n'),
          'Import Error Details',
          {
            type: 'warning',
            confirmButtonText: '确定'
          }
        )
      }
    } else {
      ElMessage.error('Import failed, please check data format or network connection')
      if (allErrors.length > 0) {
        ElMessageBox.alert(
          allErrors.join('\n'),
          'Import Failure Details',
          {
            type: 'error',
            confirmButtonText: '确定'
          }
        )
      }
    }
    
    importDialogVisible.value = false
    removeRecordFile()
    fetchRecords()
    
    // 如果有成功导入的记录，触发仪表盘刷新事件
    if (successCount > 0) {
      emit('record:created')
    }
    
  } catch (error) {
    console.error('导入记录失败:', error)
    ElMessage.error('Import records failed: ' + (error.message || 'Unknown error'))
  } finally {
    importing.value = false
  }
}

// 格式化文件大小
const formatFileSize = (size: any) => {
  if (!size || size === 0) return '未知大小'
  
  const bytes = parseInt(size)
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
  return (bytes / (1024 * 1024 * 1024)).toFixed(1) + ' GB'
}

const searchForm = reactive({
  title: '',
  type: '',
  status: '',
  tags: ''
})

const pagination = reactive({
  page: 1,
  size: 20,
  total: 0
})

// 获取记录列表
const fetchRecords = async () => {
  loading.value = true
  
  try {
    const params = {
      search: searchForm.title,
      type: searchForm.type,
      tags: searchForm.tags,
      page: pagination.page,
      page_size: pagination.size
    }
    
    // 过滤空值参数
    Object.keys(params).forEach(key => {
      if (params[key] === '' || params[key] === null || params[key] === undefined) {
        delete params[key]
      }
    })
    
    const response = await http.get(API_ENDPOINTS.RECORDS.LIST, { params })
    
    // 设置连接状态为正常
    apiConnected.value = true
    
    // 处理响应数据
    if (response.success && response.data) {
      let recordsData = []
      let totalCount = 0
      
      if (response.data.records) {
        recordsData = response.data.records
        totalCount = response.data.total || 0
      } else if (Array.isArray(response.data)) {
        recordsData = response.data
        totalCount = recordsData.length
      }
      
      records.value = recordsData.map((record: any) => ({
        id: record.id,
        title: record.title || '未命名记录',
        type: record.type || 'other',
        status: record.status || 
                record.state || 
                (record.content && record.content.status) || 
                'draft',
        content: record.content || {},
        tags: Array.isArray(record.tags) ? record.tags : [],
        creator: record.creator || { username: record.creator_name || '未知用户' },
        createdBy: record.created_by || record.createdBy || 0,
        version: record.version || 1,
        createdAt: record.created_at || record.createdAt || new Date().toISOString(),
        updatedAt: record.updated_at || record.updatedAt || new Date().toISOString(),
        statusLoading: false
      }))
      pagination.total = totalCount
      
    } else {
      // 空数据情况
      records.value = []
      pagination.total = 0
    }
    
  } catch (error: any) {
    console.error('获取记录列表失败:', error)
    
    // 根据错误类型设置连接状态
    if (error.code === 'ECONNREFUSED' || 
        error.code === 'ENOTFOUND' ||
        error.message?.includes('Network Error') ||
        error.message?.includes('timeout') ||
        !error.response) {
      // 真正的网络连接问题
      apiConnected.value = false
    } else {
      // HTTP错误，服务器可达
      apiConnected.value = true
    }
    
    // 设置空数据
    records.value = []
    pagination.total = 0
    
  } finally {
    loading.value = false
  }
}

// 搜索
const handleSearch = () => {
  pagination.page = 1
  fetchRecords()
}

// 重置
const handleReset = () => {
  Object.assign(searchForm, {
    title: '',
    type: '',
    status: '',
    tags: ''
  })
  handleSearch()
}

// 刷新
const handleRefresh = () => {
  fetchRecords()
}

// 新建记录
const handleCreate = () => {
  router.push('/records/create')
}

// 查看记录
const handleView = (row: any) => {
  router.push(`/records/${row.id}`)
}

// 编辑记录
const handleEdit = (row: any) => {
  router.push(`/records/${row.id}/edit`)
}

// 状态更新
const handleStatusChange = async (row: any, newStatus: string) => {
  row.statusLoading = true
  
  try {
    const updateData = {
      title: row.title,
      content: {
        ...row.content,
        status: newStatus,
        statusUpdatedAt: new Date().toISOString()
      },
      tags: row.tags || []
    }
    
    const response = await http.put(API_ENDPOINTS.RECORDS.UPDATE(row.id), updateData)
    
    if (response.success) {
      ElMessage.success(`记录状态已更新为${getStatusText(newStatus)}`)
      row.status = newStatus
      row.content = updateData.content
    } else {
      throw new Error(response.message || '更新失败')
    }
    
  } catch (error: any) {
    console.error('状态更新失败:', error)
    
    let errorMessage = '状态更新失败'
    if (error.response?.status === 404) {
      errorMessage = '记录不存在或已被删除'
    } else if (error.response?.status === 403) {
      errorMessage = '没有权限修改此记录'
    } else if (error.response?.status === 400) {
      errorMessage = '请求参数错误'
    } else if (error.message) {
      errorMessage = `状态更新失败: ${error.message}`
    }
    
    ElMessage.error(errorMessage)
  } finally {
    row.statusLoading = false
  }
}

// 删除记录
const handleDelete = async (row: any) => {
  try {
    await ElMessageBox.confirm('确定要删除这条记录吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await http.delete(API_ENDPOINTS.RECORDS.DELETE(row.id))
    ElMessage.success('删除成功')
    fetchRecords()
    // 触发仪表盘刷新事件
    emit('record:deleted')
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除记录失败:', error)
      ElMessage.error('删除记录失败')
    }
  }
}

// 分页处理
const handleSizeChange = (size: number) => {
  pagination.size = size
  fetchRecords()
}

const handleCurrentChange = (page: number) => {
  pagination.page = page
  fetchRecords()
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

const getStatusText = (status: string) => {
  const statusMap: { [key: string]: string } = {
    draft: '草稿',
    published: '已发布',
    archived: '已归档'
  }
  return statusMap[status] || '草稿'
}

const getStatusType = (status: string) => {
  const statusTypeMap: { [key: string]: string } = {
    draft: 'info',
    published: 'success',
    archived: 'warning'
  }
  return statusTypeMap[status] || 'info'
}

const formatTime = (time: string) => {
  return dayjs(time).format('YYYY-MM-DD HH:mm')
}

// 获取创建者姓名
const getCreatorName = (row: any) => {
  if (row.creator?.username && row.creator.username !== 'undefined') {
    return row.creator.username
  }
  
  const userMap: { [key: number]: string } = {
    1: '系统管理员',
    2: '开发者',
    3: '项目经理',
    4: '测试工程师',
    5: '运维工程师'
  }
  
  if (row.createdBy && userMap[row.createdBy]) {
    return userMap[row.createdBy]
  }
  
  if (row.createdBy) {
    return `用户${row.createdBy}`
  }
  
  return '未知用户'
}

// 获取创建者头像首字母
const getCreatorInitial = (row: any) => {
  const name = getCreatorName(row)
  return name.charAt(0).toUpperCase()
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
          description: type.display_name || type.description
        }))
    } else {
      // 使用默认类型
      recordTypes.value = [
        { name: 'work', description: '工作记录' },
        { name: 'study', description: '学习笔记' },
        { name: 'project', description: '项目文档' },
        { name: 'other', description: '其他' }
      ]
    }
  } catch (error) {
    console.error('获取记录类型失败:', error)
    // 使用默认类型
    recordTypes.value = [
      { name: 'work', description: '工作记录' },
      { name: 'study', description: '学习笔记' },
      { name: 'project', description: '项目文档' },
      { name: 'other', description: '其他' }
    ]
  }
}

// 选择变化处理
const handleSelectionChange = (selection: any[]) => {
  selectedRecords.value = selection
}

// 清除选择
const clearSelection = () => {
  selectedRecords.value = []
}

// 批量发布 - 优化版本
const handleBatchPublish = async () => {
  if (selectedRecords.value.length === 0) {
    ElMessage.warning('Please select records to publish first')
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要批量发布选中的 ${selectedRecords.value.length} 条记录吗？`,
      '批量发布确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    const loadingInstance = ElLoading.service({
      lock: true,
      text: 'Publishing records in batch...',
      background: 'rgba(0, 0, 0, 0.7)'
    })

    try {
      const recordIds = selectedRecords.value.map(record => record.id)
      const response = await http.put(API_ENDPOINTS.RECORDS.BATCH_STATUS, {
        record_ids: recordIds,
        status: 'published'
      })

      loadingInstance.close()

      if (response.success) {
        ElMessage.success(`Successfully published ${selectedRecords.value.length} records`)
        clearSelection()
        fetchRecords()
      } else {
        ElMessage.error('Batch publish failed: ' + (response.message || 'Unknown error'))
      }
    } catch (error) {
      loadingInstance.close()
      console.error('批量发布失败:', error)
      ElMessage.error('Batch publish failed: ' + (error.message || 'Network error'))
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('批量发布失败:', error)
    }
  }
}

// 批量转草稿 - 优化版本
const handleBatchDraft = async () => {
  if (selectedRecords.value.length === 0) {
    ElMessage.warning('Please select records to convert to draft first')
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要将选中的 ${selectedRecords.value.length} 条记录转为草稿吗？`,
      '批量转草稿确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    const loadingInstance = ElLoading.service({
      lock: true,
      text: '正在批量转换记录状态...',
      background: 'rgba(0, 0, 0, 0.7)'
    })

    try {
      const recordIds = selectedRecords.value.map(record => record.id)
      const response = await http.put(API_ENDPOINTS.RECORDS.BATCH_STATUS, {
        record_ids: recordIds,
        status: 'draft'
      })

      loadingInstance.close()

      if (response.success) {
        ElMessage.success(`成功将 ${selectedRecords.value.length} 条记录转为草稿`)
        clearSelection()
        fetchRecords()
      } else {
        ElMessage.error('批量转草稿失败: ' + (response.message || '未知错误'))
      }
    } catch (error) {
      loadingInstance.close()
      console.error('批量转草稿失败:', error)
      ElMessage.error('批量转草稿失败: ' + (error.message || '网络错误'))
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('批量转草稿失败:', error)
    }
  }
}

// 批量删除 - 优化版本
const handleBatchDelete = async () => {
  if (selectedRecords.value.length === 0) {
    ElMessage.warning('请先选择要删除的记录')
    return
  }

  try {
    const recordTitles = selectedRecords.value.map(record => record.title).join('、')
    const confirmText = selectedRecords.value.length > 5 
      ? `确定要批量删除选中的 ${selectedRecords.value.length} 条记录吗？\n\n此操作不可恢复！`
      : `确定要批量删除以下记录吗？\n\n${recordTitles}\n\n此操作不可恢复！`
    
    await ElMessageBox.confirm(
      confirmText,
      '批量删除确认',
      {
        confirmButtonText: '确定删除',
        cancelButtonText: '取消',
        type: 'error',
        dangerouslyUseHTMLString: false
      }
    )

    const loadingInstance = ElLoading.service({
      lock: true,
      text: '正在批量删除记录...',
      background: 'rgba(0, 0, 0, 0.7)'
    })

    try {
      const recordIds = selectedRecords.value.map(record => record.id)
      const response = await http.delete(API_ENDPOINTS.RECORDS.BATCH_DELETE, {
        data: { record_ids: recordIds }
      })

      loadingInstance.close()

      if (response.success) {
        ElMessage.success(`成功删除 ${selectedRecords.value.length} 条记录`)
        clearSelection()
        fetchRecords()
      } else {
        ElMessage.error('批量删除失败: ' + (response.message || '未知错误'))
      }
    } catch (error) {
      loadingInstance.close()
      console.error('批量删除失败:', error)
      ElMessage.error('批量删除失败: ' + (error.message || '网络错误'))
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('批量删除失败:', error)
    }
  }
}

// 生命周期
onMounted(() => {
  fetchRecordTypes()
  fetchRecords()
})

// 页面激活时刷新数据（从其他页面返回时）
onActivated(() => {
  fetchRecords()
})
</script>

<style scoped>
.record-list {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-buttons {
  display: flex;
  gap: 10px;
}

.search-bar {
  margin-bottom: 20px;
}

.pagination {
  margin-top: 20px;
  text-align: right;
}

/* 记录标题单元格样式 */
.record-title-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.record-icon {
  color: #409eff;
  font-size: 16px;
  flex-shrink: 0;
}

.title-text {
  font-weight: 500;
  color: #303133;
  line-height: 1.4;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.type-tag {
  background-color: #ecf5ff;
  color: #409eff;
  border: 1px solid #d9ecff;
}

/* 标签容器样式 */
.tags-container {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  align-items: center;
}

.tag-item {
  margin: 0;
}

.no-tags {
  color: #c0c4cc;
  font-size: 12px;
  font-style: italic;
}

/* 创建者信息样式 */
.creator-info {
  display: flex;
  align-items: center;
  gap: 6px;
}

.creator-avatar {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  font-weight: 600;
  font-size: 12px;
}

.creator-name {
  font-size: 13px;
  color: #606266;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 80px;
}

/* 时间文本样式 */
.time-text {
  font-size: 12px;
  color: #606266;
}

/* 操作按钮样式 */
.action-buttons {
  display: flex;
  gap: 4px;
  flex-wrap: nowrap;
  justify-content: flex-start;
  align-items: center;
}

.action-buttons .el-button {
  margin: 0;
  padding: 4px 6px;
  font-size: 12px;
  min-width: auto;
  white-space: nowrap;
}

@media (max-width: 768px) {
  .record-list {
    padding: 10px;
  }
  
  .search-bar .el-form {
    flex-direction: column;
  }
  
  .search-bar .el-form-item {
    margin-right: 0;
    margin-bottom: 10px;
  }
}
</style>
