<template>
  <div class="ai-config-simple">
    <!-- 快速配置区域 -->
    <el-card class="quick-config-card">
      <template #header>
        <div class="card-header">
          <el-icon><Setting /></el-icon>
          <span>快速配置AI服务</span>
        </div>
      </template>
      
      <div class="quick-config-content">
        <!-- 配置状态概览 -->
        <div class="status-overview">
          <el-row :gutter="12">
            <el-col v-for="provider in providers" :key="provider.key" :span="8">
              <div 
                class="provider-card" 
                :class="{ 'configured': provider.configured, 'active': selectedProvider === provider.key }"
                @click="selectProvider(provider.key)"
              >
                <el-icon :class="['provider-icon', provider.configured ? 'success' : 'warning']">
                  <CircleCheck v-if="provider.configured" />
                  <Warning v-else />
                </el-icon>
                <div class="provider-info">
                  <div class="provider-name">{{ provider.name }}</div>
                  <div class="provider-status">{{ provider.configured ? '已配置' : '未配置' }}</div>
                </div>
              </div>
            </el-col>
          </el-row>
        </div>

        <!-- 配置表单 -->
        <div v-if="selectedProvider" class="config-form">
          <el-divider content-position="left">
            <span>配置 {{ getProviderInfo(selectedProvider).name }}</span>
          </el-divider>
          
          <el-form 
            :model="formData" 
            :rules="formRules" 
            ref="formRef" 
            label-width="100px" 
            size="default"
          >
            <el-form-item label="配置名称" prop="name">
              <el-input
                v-model="formData.name"
                placeholder="请输入配置名称"
                clearable
              />
            </el-form-item>
            
            <el-form-item label="API密钥" prop="apiKey">
              <el-input
                v-model="formData.apiKey"
                type="password"
                :placeholder="getApiKeyPlaceholder()"
                show-password
                clearable
              />
            </el-form-item>
            
            <el-form-item 
              v-if="needsEndpoint()" 
              label="API端点" 
              prop="apiEndpoint"
            >
              <el-input
                v-model="formData.apiEndpoint"
                :placeholder="getEndpointPlaceholder()"
                clearable
              />
              <div class="form-tip">
                {{ getEndpointTip() }}
              </div>
            </el-form-item>
            
            <el-form-item label="模型" prop="model">
              <el-select 
                v-model="formData.model" 
                placeholder="选择或输入模型名称"
                filterable
                allow-create
                style="width: 100%"
              >
                <el-option 
                  v-for="model in getAvailableModels()" 
                  :key="model.value" 
                  :label="model.label" 
                  :value="model.value" 
                />
              </el-select>
            </el-form-item>
            
            <el-row :gutter="16">
              <el-col :span="12">
                <el-form-item label="最大Token">
                  <el-input-number
                    v-model="formData.maxTokens"
                    :min="1"
                    :max="32000"
                    style="width: 100%"
                  />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="温度">
                  <el-input-number
                    v-model="formData.temperature"
                    :min="0"
                    :max="2"
                    :step="0.1"
                    style="width: 100%"
                  />
                </el-form-item>
              </el-col>
            </el-row>
            
            <el-form-item>
              <el-checkbox v-model="formData.isDefault">设为默认配置</el-checkbox>
            </el-form-item>
            
            <el-form-item>
              <el-button type="primary" @click="saveConfig" :loading="saving">
                <el-icon><Check /></el-icon>
                保存配置
              </el-button>
              <el-button @click="testConnection" :loading="testing">
                <el-icon><Connection /></el-icon>
                测试连接
              </el-button>
              <el-button @click="resetForm">
                <el-icon><Refresh /></el-icon>
                重置
              </el-button>
            </el-form-item>
          </el-form>
        </div>

        <!-- 提示信息 -->
        <div v-else class="config-tip">
          <el-empty 
            description="请选择一个AI服务提供商开始配置"
            :image-size="80"
          />
        </div>
      </div>
    </el-card>

    <!-- 现有配置 -->
    <el-card v-if="existingConfigs.length > 0" class="existing-configs">
      <template #header>
        <div class="card-header">
          <el-icon><List /></el-icon>
          <span>现有配置 ({{ existingConfigs.length }})</span>
        </div>
      </template>
      
      <div class="config-list">
        <div 
          v-for="config in existingConfigs" 
          :key="config.id" 
          class="config-item"
        >
          <div class="config-main">
            <div class="config-info">
              <div class="config-title">
                <span class="config-name">{{ config.name }}</span>
                <el-tag v-if="config.is_default" type="success" size="small">默认</el-tag>
                <el-tag 
                  :type="config.status === 'active' ? 'success' : 'danger'" 
                  size="small"
                >
                  {{ config.status === 'active' ? '启用' : '禁用' }}
                </el-tag>
              </div>
              <div class="config-details">
                {{ getProviderName(config.provider) }} · {{ config.model }}
              </div>
            </div>
            <div class="config-actions">
              <el-button 
                size="small" 
                @click="testExistingConfig(config)" 
                :loading="config.testing"
              >
                测试
              </el-button>
              <el-button size="small" @click="editConfig(config)">
                编辑
              </el-button>
              <el-button 
                size="small" 
                type="danger" 
                @click="deleteConfig(config)"
                :disabled="config.is_default"
              >
                删除
              </el-button>
            </div>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 使用统计 -->
    <el-card class="stats-card">
      <template #header>
        <div class="card-header">
          <el-icon><DataAnalysis /></el-icon>
          <span>使用统计</span>
        </div>
      </template>
      
      <el-row :gutter="16">
        <el-col :span="8">
          <div class="stat-item">
            <div class="stat-value">{{ stats.todayUsage }}</div>
            <div class="stat-label">今日使用</div>
          </div>
        </el-col>
        <el-col :span="8">
          <div class="stat-item">
            <div class="stat-value">{{ stats.monthUsage }}</div>
            <div class="stat-label">本月使用</div>
          </div>
        </el-col>
        <el-col :span="8">
          <div class="stat-item">
            <div class="stat-value">{{ formatNumber(stats.tokenUsage) }}</div>
            <div class="stat-label">Token消耗</div>
          </div>
        </el-col>
      </el-row>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Check as CircleCheck,
  Warning,
  Setting,
  Check,
  Connection,
  Refresh,
  List,
  DataAnalysis
} from '@element-plus/icons-vue'
import { http } from '../../utils/http'

// 响应式数据
const saving = ref(false)
const testing = ref(false)
const selectedProvider = ref('')
const formRef = ref(null)
const existingConfigs = ref([])

// 提供商配置
const providers = ref([
  {
    key: 'openai',
    name: 'OpenAI',
    configured: false
  },
  {
    key: 'azure',
    name: 'Azure OpenAI',
    configured: false
  },
  {
    key: 'custom',
    name: '自定义模型',
    configured: false
  }
])

// 表单数据
const formData = reactive({
  name: '',
  provider: '',
  apiKey: '',
  apiEndpoint: '',
  model: '',
  maxTokens: 4096,
  temperature: 0.7,
  isDefault: false
})

// 使用统计
const stats = reactive({
  todayUsage: 0,
  monthUsage: 0,
  tokenUsage: 0
})

// 表单验证规则
const formRules = {
  name: [
    { required: true, message: '请输入配置名称', trigger: 'blur' }
  ],
  apiKey: [
    { required: true, message: '请输入API密钥', trigger: 'blur' }
  ],
  model: [
    { required: true, message: '请选择模型', trigger: 'change' }
  ],
  apiEndpoint: [
    { 
      required: true, 
      message: '请输入API端点', 
      trigger: 'blur',
      validator: (rule, value, callback) => {
        if (needsEndpoint() && !value) {
          callback(new Error('请输入API端点'))
        } else {
          callback()
        }
      }
    }
  ]
}

// 获取现有配置
const fetchConfigs = async () => {
  try {
    const response = await http.get('/ai/config')
    existingConfigs.value = response.data?.configs || []
    
    // 更新提供商配置状态
    providers.value.forEach(provider => {
      const hasConfig = existingConfigs.value.some(config => 
        config.provider === provider.key && config.status === 'active'
      )
      provider.configured = hasConfig
    })
  } catch (error) {
    console.error('获取配置失败:', error)
  }
}

// 获取使用统计
const fetchStats = async () => {
  try {
    const response = await http.get('/ai/stats')
    if (response.data) {
      Object.assign(stats, response.data)
    }
  } catch (error) {
    console.error('获取统计失败:', error)
  }
}

// 选择提供商
const selectProvider = (providerKey) => {
  selectedProvider.value = providerKey
  formData.provider = providerKey
  
  const provider = getProviderInfo(providerKey)
  formData.name = `${provider.name} 配置`
  
  // 设置默认值
  if (providerKey === 'openai') {
    formData.model = 'gpt-3.5-turbo'
    formData.apiEndpoint = ''
  } else if (providerKey === 'azure') {
    formData.model = 'gpt-35-turbo'
    formData.apiEndpoint = 'https://your-resource.openai.azure.com'
  } else if (providerKey === 'custom') {
    formData.model = 'custom-model'
    formData.apiEndpoint = 'http://localhost:8000/v1'
  }
  
  console.log('选择提供商:', providerKey, '表单数据:', formData)
}

// 获取提供商信息
const getProviderInfo = (providerKey) => {
  return providers.value.find(p => p.key === providerKey) || { name: '未知' }
}

// 是否需要端点配置
const needsEndpoint = () => {
  return selectedProvider.value === 'azure' || selectedProvider.value === 'custom'
}

// 获取API密钥占位符
const getApiKeyPlaceholder = () => {
  switch (selectedProvider.value) {
    case 'openai':
      return '请输入OpenAI API密钥 (sk-...)'
    case 'azure':
      return '请输入Azure OpenAI API密钥'
    case 'custom':
      return '请输入自定义模型的API密钥'
    default:
      return '请输入API密钥'
  }
}

// 获取端点占位符
const getEndpointPlaceholder = () => {
  switch (selectedProvider.value) {
    case 'azure':
      return 'https://your-resource.openai.azure.com'
    case 'custom':
      return 'http://localhost:8000/v1'
    default:
      return '请输入API端点'
  }
}

// 获取端点提示
const getEndpointTip = () => {
  switch (selectedProvider.value) {
    case 'azure':
      return 'Azure OpenAI的API端点，如：https://your-resource.openai.azure.com'
    case 'custom':
      return '自定义模型的API端点，如：http://localhost:8000/v1 或 https://your-api.com/v1'
    default:
      return ''
  }
}

// 获取可用模型
const getAvailableModels = () => {
  switch (selectedProvider.value) {
    case 'openai':
      return [
        { label: 'GPT-3.5 Turbo', value: 'gpt-3.5-turbo' },
        { label: 'GPT-4', value: 'gpt-4' },
        { label: 'GPT-4 Turbo', value: 'gpt-4-turbo' },
        { label: 'GPT-4o', value: 'gpt-4o' }
      ]
    case 'azure':
      return [
        { label: 'GPT-3.5 Turbo', value: 'gpt-35-turbo' },
        { label: 'GPT-4', value: 'gpt-4' },
        { label: 'GPT-4 Turbo', value: 'gpt-4-turbo' }
      ]
    case 'custom':
      return [
        { label: '自定义模型', value: 'custom-model' },
        { label: 'Llama 2', value: 'llama-2' },
        { label: 'Mistral', value: 'mistral' }
      ]
    default:
      return []
  }
}

// 获取提供商名称
const getProviderName = (provider) => {
  const nameMap = {
    openai: 'OpenAI',
    azure: 'Azure OpenAI',
    custom: '自定义模型',
    anthropic: 'Anthropic',
    google: 'Google AI'
  }
  return nameMap[provider] || provider
}

// 保存配置
const saveConfig = async () => {
  if (!formRef.value) return
  
  // 验证必填字段
  if (!formData.name?.trim()) {
    ElMessage.error('请输入配置名称')
    return
  }
  
  if (!formData.provider) {
    ElMessage.error('请选择服务提供商')
    return
  }
  
  if (!formData.apiKey?.trim()) {
    ElMessage.error('请输入API密钥')
    return
  }
  
  if (!formData.model?.trim()) {
    ElMessage.error('请选择模型')
    return
  }
  
  // 检查API端点
  const needsApiEndpoint = formData.provider === 'azure' || formData.provider === 'custom'
  if (needsApiEndpoint && !formData.apiEndpoint?.trim()) {
    ElMessage.error('请输入API端点')
    return
  }
  
  saving.value = true
  try {
    const configData = {
      name: formData.name.trim(),
      provider: formData.provider,
      api_key: formData.apiKey.trim(),
      api_endpoint: formData.apiEndpoint?.trim() || '',
      model: formData.model.trim(),
      config: '',
      categories: ['chat'],
      tags: ['production'],
      description: `${getProviderInfo(formData.provider).name} 配置`,
      priority: 5,
      is_active: true,
      is_default: formData.isDefault,
      max_tokens: formData.maxTokens,
      temperature: formData.temperature,
      daily_limit: 0,
      monthly_limit: 0,
      cost_per_token: 0
    }
    
    console.log('发送配置数据:', configData)
    console.log('当前表单数据:', formData)
    
    await http.post('/ai/config', configData)
    ElMessage.success('配置保存成功')
    
    // 刷新配置列表
    await fetchConfigs()
    resetForm()
  } catch (error) {
    ElMessage.error(error.response?.data?.error || '保存配置失败')
  } finally {
    saving.value = false
  }
}

// 测试连接
const testConnection = async () => {
  if (!formData.apiKey.trim()) {
    ElMessage.warning('请先输入API密钥')
    return
  }
  
  if (needsEndpoint() && !formData.apiEndpoint.trim()) {
    ElMessage.warning('请先输入API端点')
    return
  }
  
  testing.value = true
  try {
    const testData = {
      provider: formData.provider,
      api_key: formData.apiKey,
      api_endpoint: formData.apiEndpoint || '',
      model: formData.model
    }
    
    console.log('测试连接数据:', testData)
    await http.post('/ai/test-connection', testData)
    ElMessage.success('连接测试成功')
  } catch (error) {
    ElMessage.error(error.response?.data?.error || '连接测试失败')
  } finally {
    testing.value = false
  }
}

// 测试现有配置
const testExistingConfig = async (config) => {
  config.testing = true
  try {
    await http.post(`/ai/health/${config.id}`)
    ElMessage.success(`${config.name} 连接测试成功`)
  } catch (error) {
    ElMessage.error(`${config.name} 连接测试失败`)
  } finally {
    config.testing = false
  }
}

// 编辑配置
const editConfig = (config) => {
  selectedProvider.value = config.provider
  Object.assign(formData, {
    name: config.name,
    provider: config.provider,
    apiKey: config.api_key,
    apiEndpoint: config.api_endpoint || '',
    model: config.model,
    maxTokens: config.max_tokens || 4096,
    temperature: config.temperature || 0.7,
    isDefault: config.is_default
  })
}

// 删除配置
const deleteConfig = async (config) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除配置 "${config.name}" 吗？`,
      '确认删除',
      { type: 'warning' }
    )
    
    await http.delete(`/ai/config/${config.id}`)
    ElMessage.success('配置删除成功')
    await fetchConfigs()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除配置失败')
    }
  }
}

// 重置表单
const resetForm = () => {
  selectedProvider.value = ''
  Object.assign(formData, {
    name: '',
    provider: '',
    apiKey: '',
    apiEndpoint: '',
    model: '',
    maxTokens: 4096,
    temperature: 0.7,
    isDefault: false
  })
  
  if (formRef.value) {
    formRef.value.resetFields()
  }
}

// 格式化数字
const formatNumber = (num) => {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1) + 'M'
  } else if (num >= 1000) {
    return (num / 1000).toFixed(1) + 'K'
  }
  return num.toString()
}

// 生命周期
onMounted(() => {
  fetchConfigs()
  fetchStats()
})

// 暴露方法给父组件
defineExpose({
  fetchConfigs
})
</script>

<style scoped>
.ai-config-simple {
  padding: 0;
}

.quick-config-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
}

.quick-config-content {
  padding: 0;
}

.status-overview {
  margin-bottom: 20px;
}

.provider-card {
  padding: 12px;
  border: 2px solid #e4e7ed;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 8px;
  min-height: 60px;
}

.provider-card:hover {
  border-color: #409eff;
  background: #f0f9ff;
}

.provider-card.active {
  border-color: #409eff;
  background: #e6f7ff;
}

.provider-card.configured {
  border-color: #67c23a;
}

.provider-icon {
  font-size: 18px;
  flex-shrink: 0;
}

.provider-icon.success {
  color: #67c23a;
}

.provider-icon.warning {
  color: #e6a23c;
}

.provider-info {
  flex: 1;
  min-width: 0;
}

.provider-name {
  font-size: 14px;
  font-weight: 600;
  margin-bottom: 2px;
}

.provider-status {
  font-size: 12px;
  color: #606266;
}

.config-form {
  margin-top: 20px;
}

.form-tip {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
  line-height: 1.4;
}

.config-tip {
  text-align: center;
  padding: 40px 20px;
}

.existing-configs {
  margin-bottom: 20px;
}

.config-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.config-item {
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  overflow: hidden;
}

.config-main {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: #fafafa;
  transition: all 0.3s ease;
}

.config-main:hover {
  background: #f0f9ff;
}

.config-info {
  flex: 1;
  min-width: 0;
}

.config-title {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.config-name {
  font-size: 16px;
  font-weight: 600;
}

.config-details {
  font-size: 14px;
  color: #606266;
}

.config-actions {
  display: flex;
  gap: 8px;
  flex-shrink: 0;
}

.stats-card {
  margin-bottom: 20px;
}

.stat-item {
  text-align: center;
  padding: 16px;
}

.stat-value {
  font-size: 24px;
  font-weight: 600;
  color: #409eff;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 12px;
  color: #909399;
}

:deep(.el-divider__text) {
  font-weight: 600;
  color: #409eff;
}

:deep(.el-form-item__label) {
  font-weight: 500;
}

:deep(.el-card__header) {
  padding: 16px 20px;
  border-bottom: 1px solid #f0f0f0;
}

:deep(.el-card__body) {
  padding: 20px;
}
</style>
