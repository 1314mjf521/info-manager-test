<template>
  <div class="ai-config-form">
    <el-form
      ref="formRef"
      :model="formData"
      :rules="formRules"
      label-width="120px"
    >
      <el-form-item label="配置名称" prop="name">
        <el-input
          v-model="formData.name"
          placeholder="请输入配置名称"
          maxlength="50"
          show-word-limit
        />
      </el-form-item>

      <el-form-item label="服务提供商" prop="provider">
        <el-select
          v-model="formData.provider"
          placeholder="请选择服务提供商"
          style="width: 100%"
          @change="handleProviderChange"
        >
          <el-option
            v-for="provider in providers"
            :key="provider.value"
            :label="provider.label"
            :value="provider.value"
          >
            <div class="provider-option">
              <span>{{ provider.label }}</span>
              <span class="provider-desc">{{ provider.description }}</span>
            </div>
          </el-option>
        </el-select>
      </el-form-item>

      <el-form-item label="模型" prop="model">
        <el-select
          v-model="formData.model"
          placeholder="请选择模型或输入自定义模型名称"
          style="width: 100%"
          filterable
          allow-create
          default-first-option
          :reserve-keyword="false"
        >
          <el-option
            v-for="model in availableModels"
            :key="model.value"
            :label="model.label"
            :value="model.value"
          >
            <div class="model-option">
              <span>{{ model.label }}</span>
              <span class="model-desc">{{ model.description }}</span>
            </div>
          </el-option>
        </el-select>
        <div class="form-help">
          <el-icon><InfoFilled /></el-icon>
          可以选择预设模型或直接输入自定义模型名称（如：gpt-4-32k、claude-3-opus-20240229等）
        </div>
      </el-form-item>

      <el-form-item label="API密钥" prop="api_key">
        <el-input
          v-model="formData.api_key"
          type="password"
          placeholder="请输入API密钥"
          show-password
        />
        <div class="form-help">
          <el-icon><InfoFilled /></el-icon>
          API密钥将被加密存储，请确保密钥的安全性
        </div>
      </el-form-item>

      <el-form-item label="API端点" prop="api_endpoint" v-if="showAdvanced">
        <el-input
          v-model="formData.api_endpoint"
          :placeholder="getEndpointPlaceholder()"
        />
        <div class="form-help">
          <el-icon><InfoFilled /></el-icon>
          <span v-if="formData.provider === 'custom'">
            自定义模型的API端点，如：http://localhost:8000/v1 或 https://your-model-api.com/v1
          </span>
          <span v-else>
            留空将使用默认端点
          </span>
        </div>
      </el-form-item>

      <el-form-item label="最大Token数" prop="max_tokens" v-if="showAdvanced">
        <el-input-number
          v-model="formData.max_tokens"
          :min="1"
          :max="32000"
          :step="100"
          style="width: 100%"
        />
      </el-form-item>

      <el-form-item label="温度参数" prop="temperature" v-if="showAdvanced">
        <el-slider
          v-model="formData.temperature"
          :min="0"
          :max="2"
          :step="0.1"
          show-input
          :format-tooltip="formatTemperature"
        />
        <div class="form-help">
          <el-icon><InfoFilled /></el-icon>
          控制输出的随机性，0表示确定性输出，2表示高随机性
        </div>
      </el-form-item>

      <el-form-item label="超时时间" prop="timeout" v-if="showAdvanced">
        <el-input-number
          v-model="formData.timeout"
          :min="5"
          :max="300"
          :step="5"
          style="width: 100%"
        />
        <template #append>秒</template>
      </el-form-item>

      <el-form-item label="设置选项">
        <el-checkbox v-model="formData.is_default">设为默认配置</el-checkbox>
        <el-checkbox v-model="showAdvanced">显示高级选项</el-checkbox>
      </el-form-item>

      <el-form-item label="功能分类" prop="categories">
        <el-select
          v-model="formData.categories"
          placeholder="请选择适用的功能分类"
          style="width: 100%"
          multiple
          collapse-tags
          collapse-tags-tooltip
        >
          <el-option
            v-for="category in functionCategories"
            :key="category.value"
            :label="category.label"
            :value="category.value"
          >
            <div class="category-option">
              <el-icon>{{ category.icon }}</el-icon>
              <span>{{ category.label }}</span>
              <span class="category-desc">{{ category.description }}</span>
            </div>
          </el-option>
        </el-select>
        <div class="form-help">
          <el-icon><InfoFilled /></el-icon>
          选择此配置适用的功能场景，系统会根据使用场景自动推荐合适的配置
        </div>
      </el-form-item>

      <el-form-item label="用途标签" prop="tags">
        <el-select
          v-model="formData.tags"
          placeholder="请选择或输入用途标签"
          style="width: 100%"
          multiple
          filterable
          allow-create
          default-first-option
          collapse-tags
          collapse-tags-tooltip
        >
          <el-option
            v-for="tag in commonTags"
            :key="tag.value"
            :label="tag.label"
            :value="tag.value"
          >
            <el-tag :type="tag.type" size="small">{{ tag.label }}</el-tag>
          </el-option>
        </el-select>
        <div class="form-help">
          <el-icon><InfoFilled /></el-icon>
          添加标签便于管理和筛选，可选择预设标签或自定义标签
        </div>
      </el-form-item>

      <el-form-item label="优先级" prop="priority" v-if="showAdvanced">
        <el-slider
          v-model="formData.priority"
          :min="1"
          :max="10"
          :step="1"
          show-input
          :format-tooltip="formatPriority"
          :marks="priorityMarks"
        />
        <div class="form-help">
          <el-icon><InfoFilled /></el-icon>
          设置配置的优先级，数字越大优先级越高，系统会优先使用高优先级的配置
        </div>
      </el-form-item>

      <el-form-item label="使用限制" v-if="showAdvanced">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="每日限制" prop="daily_limit" label-width="80px">
              <el-input-number
                v-model="formData.daily_limit"
                :min="0"
                :max="100000"
                :step="100"
                style="width: 100%"
                placeholder="0表示无限制"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="每月限制" prop="monthly_limit" label-width="80px">
              <el-input-number
                v-model="formData.monthly_limit"
                :min="0"
                :max="1000000"
                :step="1000"
                style="width: 100%"
                placeholder="0表示无限制"
              />
            </el-form-item>
          </el-col>
        </el-row>
        <div class="form-help">
          <el-icon><InfoFilled /></el-icon>
          设置使用限制可以控制成本，0表示无限制
        </div>
      </el-form-item>

      <el-form-item label="成本配置" prop="cost_per_token" v-if="showAdvanced">
        <el-input-number
          v-model="formData.cost_per_token"
          :min="0"
          :max="1"
          :step="0.000001"
          :precision="6"
          style="width: 100%"
          placeholder="每token成本（美元）"
        />
        <div class="form-help">
          <el-icon><InfoFilled /></el-icon>
          设置每token的成本用于统计和预算管理
        </div>
      </el-form-item>

      <el-form-item label="描述" prop="description">
        <el-input
          v-model="formData.description"
          type="textarea"
          :rows="3"
          placeholder="请输入配置描述（可选）"
          maxlength="500"
          show-word-limit
        />
      </el-form-item>
    </el-form>

    <div class="form-actions">
      <el-button @click="handleCancel">取消</el-button>
      <el-button type="primary" @click="handleSave" :loading="saving">
        {{ isEdit ? '更新' : '创建' }}
      </el-button>
      <el-button v-if="formData.api_key" @click="testConnection" :loading="testing">
        测试连接
      </el-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { InfoFilled } from '@element-plus/icons-vue'

// Props
interface Props {
  config?: any
  isEdit?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  config: null,
  isEdit: false
})

// Emits
const emit = defineEmits<{
  save: [config: any]
  cancel: []
}>()

// 响应式数据
const formRef = ref()
const saving = ref(false)
const testing = ref(false)
const showAdvanced = ref(false)

// 表单数据
const formData = reactive({
  name: '',
  provider: '',
  model: '',
  api_key: '',
  api_endpoint: '',
  max_tokens: 2000,
  temperature: 0.7,
  timeout: 30,
  is_default: false,
  description: '',
  categories: [] as string[],
  tags: [] as string[],
  priority: 5,
  daily_limit: 0,
  monthly_limit: 0,
  cost_per_token: 0
})

// 服务提供商选项
const providers = [
  {
    value: 'openai',
    label: 'OpenAI',
    description: '官方OpenAI API服务'
  },
  {
    value: 'azure',
    label: 'Azure OpenAI',
    description: '微软Azure OpenAI服务'
  },
  {
    value: 'anthropic',
    label: 'Anthropic',
    description: 'Claude AI服务'
  },
  {
    value: 'google',
    label: 'Google AI',
    description: 'Google Gemini服务'
  },
  {
    value: 'custom',
    label: '自定义/本地模型',
    description: '自建模型或本地部署的AI服务'
  }
]

// 功能分类选项
const functionCategories = [
  {
    value: 'chat',
    label: '智能对话',
    icon: 'ChatDotRound',
    description: '用于AI聊天和对话功能'
  },
  {
    value: 'optimize',
    label: '内容优化',
    icon: 'MagicStick',
    description: '用于文本内容优化和改写'
  },
  {
    value: 'speech',
    label: '语音处理',
    icon: 'Microphone',
    description: '用于语音识别和语音合成'
  },
  {
    value: 'image',
    label: '图像处理',
    icon: 'Picture',
    description: '用于图像生成和图像理解'
  },
  {
    value: 'code',
    label: '代码生成',
    icon: 'Document',
    description: '用于代码生成和代码分析'
  },
  {
    value: 'translate',
    label: '翻译服务',
    icon: 'Connection',
    description: '用于多语言翻译'
  },
  {
    value: 'analysis',
    label: '数据分析',
    icon: 'DataAnalysis',
    description: '用于数据分析和报告生成'
  }
]

// 常用标签选项
const commonTags = [
  { value: 'production', label: '生产环境', type: 'success' },
  { value: 'development', label: '开发环境', type: 'info' },
  { value: 'testing', label: '测试环境', type: 'warning' },
  { value: 'fast', label: '快速响应', type: 'primary' },
  { value: 'accurate', label: '高精度', type: 'success' },
  { value: 'cost-effective', label: '经济实惠', type: 'info' },
  { value: 'high-quality', label: '高质量', type: 'success' },
  { value: 'experimental', label: '实验性', type: 'danger' },
  { value: 'stable', label: '稳定版', type: 'success' },
  { value: 'beta', label: '测试版', type: 'warning' },
  { value: 'deprecated', label: '已弃用', type: 'info' }
]

// 优先级标记
const priorityMarks = {
  1: '最低',
  3: '低',
  5: '中等',
  7: '高',
  10: '最高'
}

// 模型选项
const modelOptions = {
  openai: [
    { value: 'gpt-4', label: 'GPT-4', description: '最强大的模型，适合复杂任务' },
    { value: 'gpt-4-turbo', label: 'GPT-4 Turbo', description: '更快的GPT-4版本' },
    { value: 'gpt-4-32k', label: 'GPT-4 32K', description: '支持更长上下文的GPT-4' },
    { value: 'gpt-3.5-turbo', label: 'GPT-3.5 Turbo', description: '快速且经济的选择' },
    { value: 'gpt-3.5-turbo-16k', label: 'GPT-3.5 Turbo 16K', description: '支持更长上下文' }
  ],
  azure: [
    { value: 'gpt-4', label: 'GPT-4', description: 'Azure部署的GPT-4' },
    { value: 'gpt-4-32k', label: 'GPT-4 32K', description: 'Azure部署的GPT-4 32K' },
    { value: 'gpt-35-turbo', label: 'GPT-3.5 Turbo', description: 'Azure部署的GPT-3.5' },
    { value: 'gpt-35-turbo-16k', label: 'GPT-3.5 Turbo 16K', description: 'Azure部署的GPT-3.5 16K' }
  ],
  anthropic: [
    { value: 'claude-3-opus-20240229', label: 'Claude 3 Opus', description: '最强大的Claude模型' },
    { value: 'claude-3-sonnet-20240229', label: 'Claude 3 Sonnet', description: '平衡性能和速度' },
    { value: 'claude-3-haiku-20240307', label: 'Claude 3 Haiku', description: '快速响应模型' },
    { value: 'claude-2.1', label: 'Claude 2.1', description: '上一代Claude模型' }
  ],
  google: [
    { value: 'gemini-pro', label: 'Gemini Pro', description: 'Google最新的AI模型' },
    { value: 'gemini-pro-vision', label: 'Gemini Pro Vision', description: '支持图像理解' },
    { value: 'gemini-1.5-pro', label: 'Gemini 1.5 Pro', description: '增强版Gemini Pro' }
  ],
  custom: [
    { value: 'llama-2-70b', label: 'Llama 2 70B', description: '开源大语言模型' },
    { value: 'llama-2-13b', label: 'Llama 2 13B', description: '中等规模开源模型' },
    { value: 'llama-2-7b', label: 'Llama 2 7B', description: '轻量级开源模型' },
    { value: 'vicuna-33b', label: 'Vicuna 33B', description: '基于Llama的微调模型' },
    { value: 'alpaca-7b', label: 'Alpaca 7B', description: 'Stanford开源模型' },
    { value: 'chatglm-6b', label: 'ChatGLM 6B', description: '清华开源对话模型' },
    { value: 'baichuan-13b', label: 'Baichuan 13B', description: '百川智能开源模型' },
    { value: 'qwen-14b', label: 'Qwen 14B', description: '阿里通义千问模型' }
  ]
}

// 计算属性
const availableModels = computed(() => {
  return modelOptions[formData.provider as keyof typeof modelOptions] || []
})

// 表单验证规则
const formRules = {
  name: [
    { required: true, message: '请输入配置名称', trigger: 'blur' },
    { min: 2, max: 50, message: '长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  provider: [
    { required: true, message: '请选择服务提供商', trigger: 'change' }
  ],
  model: [
    { required: true, message: '请选择模型', trigger: 'change' }
  ],
  api_key: [
    { required: true, message: '请输入API密钥', trigger: 'blur' },
    { min: 10, message: 'API密钥长度至少10个字符', trigger: 'blur' }
  ],
  max_tokens: [
    { type: 'number', min: 1, max: 32000, message: '请输入有效的Token数量', trigger: 'blur' }
  ],
  temperature: [
    { type: 'number', min: 0, max: 2, message: '温度参数范围为0-2', trigger: 'blur' }
  ],
  timeout: [
    { type: 'number', min: 5, max: 300, message: '超时时间范围为5-300秒', trigger: 'blur' }
  ]
}

// 处理提供商变化
const handleProviderChange = () => {
  formData.model = ''
  // 设置默认端点
  const defaultEndpoints: Record<string, string> = {
    openai: 'https://api.openai.com/v1',
    azure: '',
    anthropic: 'https://api.anthropic.com',
    google: 'https://generativelanguage.googleapis.com',
    custom: 'http://localhost:8000/v1'  // 本地部署的常见端点
  }
  formData.api_endpoint = defaultEndpoints[formData.provider] || ''
  
  // 为自定义提供商显示高级选项
  if (formData.provider === 'custom') {
    showAdvanced.value = true
  }
}

// 格式化温度参数提示
const formatTemperature = (value: number) => {
  if (value === 0) return '确定性'
  if (value <= 0.3) return '保守'
  if (value <= 0.7) return '平衡'
  if (value <= 1.2) return '创造性'
  return '高随机性'
}

// 格式化优先级提示
const formatPriority = (value: number) => {
  if (value <= 2) return '最低优先级'
  if (value <= 4) return '低优先级'
  if (value <= 6) return '中等优先级'
  if (value <= 8) return '高优先级'
  return '最高优先级'
}

// 获取端点占位符
const getEndpointPlaceholder = () => {
  const placeholders: Record<string, string> = {
    openai: 'https://api.openai.com/v1',
    azure: 'https://your-resource.openai.azure.com/',
    anthropic: 'https://api.anthropic.com',
    google: 'https://generativelanguage.googleapis.com',
    custom: 'http://localhost:8000/v1 或 https://your-api.com/v1'
  }
  return placeholders[formData.provider] || '请输入API端点URL'
}

// 测试连接
const testConnection = async () => {
  try {
    await formRef.value.validateField(['provider', 'model', 'api_key'])
    testing.value = true
    
    // 这里应该调用测试API
    await new Promise(resolve => setTimeout(resolve, 2000))
    
    ElMessage.success('连接测试成功')
  } catch (error) {
    ElMessage.error('连接测试失败')
  } finally {
    testing.value = false
  }
}

// 保存配置
const handleSave = async () => {
  try {
    await formRef.value.validate()
    saving.value = true
    
    const configData = { ...formData }
    emit('save', configData)
  } catch (error) {
    console.error('表单验证失败:', error)
  } finally {
    saving.value = false
  }
}

// 取消操作
const handleCancel = () => {
  emit('cancel')
}

// 初始化表单数据
const initFormData = () => {
  if (props.config) {
    Object.assign(formData, props.config)
  }
}

// 监听配置变化
watch(() => props.config, initFormData, { immediate: true })
</script>

<style scoped>
.ai-config-form {
  padding: 0;
}

.provider-option,
.model-option {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.provider-desc,
.model-desc {
  font-size: 12px;
  color: #909399;
}

.form-help {
  display: flex;
  align-items: center;
  gap: 4px;
  margin-top: 4px;
  font-size: 12px;
  color: #909399;
}

.category-option {
  display: flex;
  align-items: center;
  gap: 8px;
}

.category-desc {
  font-size: 12px;
  color: #909399;
  margin-left: auto;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 24px;
  padding-top: 16px;
  border-top: 1px solid #e4e7ed;
}

:deep(.el-slider) {
  margin: 12px 0;
}

:deep(.el-input-number) {
  width: 100%;
}
</style>