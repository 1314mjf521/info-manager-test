<template>
  <div class="ai-config">
    <!-- 工具栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button type="primary" @click="handleCreateClick">
          <el-icon><Plus /></el-icon>
          添加配置
        </el-button>
        <el-button @click="fetchConfigs">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
      </div>
      <div class="toolbar-right">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索配置名称或提供商"
          style="width: 250px"
          clearable
          @input="handleSearch"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
      </div>
    </div>

    <!-- 空状态 -->
    <div v-if="!loading && configs.length === 0" class="empty-state">
      <el-empty description="暂无AI配置">
        <el-button type="primary" @click="handleCreateClick">
          <el-icon><Plus /></el-icon>
          创建第一个AI配置
        </el-button>
      </el-empty>
    </div>

    <!-- 配置列表 -->
    <el-table
      v-else
      :data="filteredConfigs"
      v-loading="loading"
      stripe
      style="width: 100%"
    >
      <el-table-column prop="name" label="配置名称" min-width="150">
        <template #default="{ row }">
          <div class="config-name">
            <span>{{ row.name }}</span>
            <el-tag v-if="row.is_default" type="success" size="small">默认</el-tag>
          </div>
        </template>
      </el-table-column>

      <el-table-column prop="provider" label="服务提供商" width="120">
        <template #default="{ row }">
          <el-tag :type="getProviderTagType(row.provider)">
            {{ getProviderName(row.provider) }}
          </el-tag>
        </template>
      </el-table-column>

      <el-table-column prop="model" label="模型" width="150" />

      <el-table-column prop="api_key" label="API密钥" width="200">
        <template #default="{ row }">
          <span class="api-key">{{ maskApiKey(row.api_key) }}</span>
        </template>
      </el-table-column>

      <el-table-column prop="status" label="状态" width="100">
        <template #default="{ row }">
          <el-tag :type="row.status === 'active' ? 'success' : 'danger'">
            {{ row.status === 'active' ? '启用' : '禁用' }}
          </el-tag>
        </template>
      </el-table-column>

      <el-table-column prop="created_at" label="创建时间" width="180">
        <template #default="{ row }">
          {{ formatTime(row.created_at) }}
        </template>
      </el-table-column>

      <el-table-column label="操作" width="200" fixed="right">
        <template #default="{ row }">
          <el-button size="small" @click="testConfig(row)">
            <el-icon><Connection /></el-icon>
            测试
          </el-button>
          <el-button size="small" @click="editConfig(row)">
            <el-icon><Edit /></el-icon>
            编辑
          </el-button>
          <el-button
            size="small"
            type="danger"
            @click="deleteConfig(row)"
            :disabled="row.is_default"
          >
            <el-icon><Delete /></el-icon>
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <div class="pagination">
      <el-pagination
        v-model:current-page="pagination.page"
        v-model:page-size="pagination.pageSize"
        :total="pagination.total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="fetchConfigs"
        @current-change="fetchConfigs"
      />
    </div>

    <!-- 配置表单对话框 -->
    <el-dialog
      v-model="showConfigDialog"
      :title="isEdit ? '编辑AI配置' : '添加AI配置'"
      width="600px"
      :before-close="handleDialogClose"
    >
      <AIConfigForm
        :config="currentConfig"
        :is-edit="isEdit"
        @save="handleConfigSave"
        @cancel="handleDialogClose"
      />
    </el-dialog>

    <!-- 测试结果对话框 -->
    <el-dialog v-model="showTestDialog" title="连接测试结果" width="500px">
      <div class="test-result">
        <div v-if="testResult.loading" class="test-loading">
          <el-icon class="is-loading"><Loading /></el-icon>
          <span>正在测试连接...</span>
        </div>
        <div v-else-if="testResult.success" class="test-success">
          <el-icon><CircleCheck /></el-icon>
          <span>连接测试成功</span>
          <div class="test-details">
            <p><strong>响应时间:</strong> {{ testResult.responseTime }}ms</p>
            <p><strong>模型版本:</strong> {{ testResult.modelVersion }}</p>
          </div>
        </div>
        <div v-else class="test-error">
          <el-icon><CircleClose /></el-icon>
          <span>连接测试失败</span>
          <div class="error-message">{{ testResult.error }}</div>
        </div>
      </div>
      <template #footer>
        <el-button @click="showTestDialog = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Plus,
  Refresh,
  Search,
  Connection,
  Edit,
  Delete,
  Loading,
  Check as CircleCheck,
  Close as CircleClose
} from '@element-plus/icons-vue'
import { http } from '@/utils/http'
import { formatTime } from '@/utils/format'
import AIConfigForm from './AIConfigForm.vue'

// 类型定义
interface AIConfig {
  id: number
  name: string
  provider: string
  model: string
  api_key: string
  status: string
  is_default: boolean
  created_at: string
}

// 响应式数据
const configs = ref<AIConfig[]>([])
const loading = ref(false)
const searchKeyword = ref('')

// 分页
const pagination = reactive({
  page: 1,
  pageSize: 20,
  total: 0
})

// 对话框
const showConfigDialog = ref(false)
const showCreateDialog = ref(false)
const showTestDialog = ref(false)
const isEdit = ref(false)
const currentConfig = ref<AIConfig | null>(null)

// 测试结果
const testResult = reactive({
  loading: false,
  success: false,
  error: '',
  responseTime: 0,
  modelVersion: ''
})

// 计算属性
const filteredConfigs = computed(() => {
  if (!searchKeyword.value) {
    return configs.value
  }
  
  const keyword = searchKeyword.value.toLowerCase()
  return configs.value.filter(config =>
    config.name.toLowerCase().includes(keyword) ||
    config.provider.toLowerCase().includes(keyword)
  )
})

// 获取配置列表
const fetchConfigs = async () => {
  loading.value = true
  try {
    const response = await http.get('/ai/config', {
      params: {
        page: pagination.page,
        page_size: pagination.pageSize
      }
    })
    
    configs.value = response.data.configs || []
    pagination.total = response.data.total || 0
  } catch (error) {
    ElMessage.error('获取AI配置失败')
  } finally {
    loading.value = false
  }
}

// 搜索处理
const handleSearch = () => {
  // 实时搜索，这里可以添加防抖
}

// 获取提供商标签类型
const getProviderTagType = (provider: string) => {
  const typeMap: Record<string, string> = {
    openai: 'primary',
    azure: 'success',
    anthropic: 'warning',
    google: 'info'
  }
  return typeMap[provider] || 'default'
}

// 获取提供商名称
const getProviderName = (provider: string) => {
  const nameMap: Record<string, string> = {
    openai: 'OpenAI',
    azure: 'Azure OpenAI',
    anthropic: 'Anthropic',
    google: 'Google AI'
  }
  return nameMap[provider] || provider
}

// 掩码API密钥
const maskApiKey = (apiKey: string) => {
  if (!apiKey || apiKey.length <= 8) {
    return '****'
  }
  return apiKey.substring(0, 4) + '****' + apiKey.substring(apiKey.length - 4)
}

// 测试配置
const testConfig = async (config: AIConfig) => {
  showTestDialog.value = true
  testResult.loading = true
  testResult.success = false
  testResult.error = ''
  
  try {
    const startTime = Date.now()
    const response = await http.post(`/ai/health/${config.id}`)
    const endTime = Date.now()
    
    testResult.loading = false
    testResult.success = true
    testResult.responseTime = endTime - startTime
    testResult.modelVersion = response.data.model_version || 'Unknown'
  } catch (error: any) {
    testResult.loading = false
    testResult.success = false
    testResult.error = error.response?.data?.message || '连接失败'
  }
}

// 编辑配置
const editConfig = (config: AIConfig) => {
  currentConfig.value = { ...config }
  isEdit.value = true
  showConfigDialog.value = true
}

// 删除配置
const deleteConfig = async (config: AIConfig) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除配置 "${config.name}" 吗？`,
      '确认删除',
      { type: 'warning' }
    )
    
    await http.delete(`/ai/config/${config.id}`)
    ElMessage.success('配置删除成功')
    fetchConfigs()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除配置失败')
    }
  }
}

// 处理配置保存
const handleConfigSave = async (configData: any) => {
  try {
    if (isEdit.value && currentConfig.value) {
      await http.put(`/ai/config/${currentConfig.value.id}`, configData)
      ElMessage.success('配置更新成功')
    } else {
      await http.post('/ai/config', configData)
      ElMessage.success('配置创建成功')
    }
    
    showConfigDialog.value = false
    fetchConfigs()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.message || '保存配置失败')
  }
}

// 处理对话框关闭
const handleDialogClose = () => {
  showConfigDialog.value = false
  currentConfig.value = null
  isEdit.value = false
}

// 监听创建对话框
const handleCreateDialog = () => {
  currentConfig.value = null
  isEdit.value = false
  showConfigDialog.value = true
}

// 生命周期
onMounted(() => {
  fetchConfigs()
})

// 监听创建按钮
const handleShowCreateDialog = () => {
  showCreateDialog.value = false
  handleCreateDialog()
}

// 修复创建对话框的显示
const showCreateDialog = ref(false)
const handleCreateClick = () => {
  currentConfig.value = null
  isEdit.value = false
  showConfigDialog.value = true
}
</script>

<style scoped>
.ai-config {
  padding: 0;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding: 12px 16px;
  background: #fafafa;
  border-radius: 4px;
  border: 1px solid #e4e7ed;
  flex-shrink: 0;
}

.empty-state {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 300px;
}

.toolbar-left {
  display: flex;
  gap: 8px;
}

.config-name {
  display: flex;
  align-items: center;
  gap: 8px;
}

.api-key {
  font-family: monospace;
  font-size: 12px;
  color: #606266;
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}

.test-result {
  text-align: center;
  padding: 20px;
}

.test-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  color: #409eff;
}

.test-success {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  color: #67c23a;
}

.test-success .el-icon {
  font-size: 48px;
}

.test-details {
  margin-top: 16px;
  text-align: left;
  background: #f5f7fa;
  padding: 12px;
  border-radius: 4px;
}

.test-details p {
  margin: 4px 0;
  font-size: 14px;
}

.test-error {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  color: #f56c6c;
}

.test-error .el-icon {
  font-size: 48px;
}

.error-message {
  margin-top: 8px;
  padding: 8px 12px;
  background: #fef0f0;
  border: 1px solid #fbc4c4;
  border-radius: 4px;
  font-size: 14px;
  color: #f56c6c;
}
</style>