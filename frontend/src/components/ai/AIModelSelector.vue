<template>
  <div class="ai-model-selector">
    <div class="selector-header">
      <div class="selector-info">
        <h4>智能模型选择</h4>
        <p>根据使用场景自动推荐最适合的AI配置</p>
      </div>
      <el-button size="small" text @click="showAdvanced = !showAdvanced">
        {{ showAdvanced ? '简化选择' : '高级选择' }}
      </el-button>
    </div>

    <!-- 场景选择 -->
    <div class="scenario-selector">
      <el-radio-group v-model="selectedScenario" @change="handleScenarioChange">
        <el-radio-button 
          v-for="scenario in scenarios" 
          :key="scenario.value" 
          :label="scenario.value"
        >
          <div class="scenario-option">
            <el-icon>{{ scenario.icon }}</el-icon>
            <span>{{ scenario.label }}</span>
          </div>
        </el-radio-button>
      </el-radio-group>
    </div>

    <!-- 推荐配置 -->
    <div v-if="recommendedConfigs.length > 0" class="recommended-configs">
      <h5>推荐配置</h5>
      <div class="config-cards">
        <div 
          v-for="config in recommendedConfigs" 
          :key="config.id"
          class="config-card"
          :class="{ 'selected': selectedConfigId === config.id }"
          @click="selectConfig(config)"
        >
          <div class="card-header">
            <div class="config-info">
              <h6>{{ config.name }}</h6>
              <p>{{ getProviderName(config.provider) }} - {{ config.model }}</p>
            </div>
            <div class="config-score">
              <el-rate 
                v-model="config.matchScore" 
                :max="5" 
                disabled 
                show-score 
                text-color="#ff9900"
                score-template="{value}分"
              />
            </div>
          </div>
          
          <div class="card-content">
            <div class="config-tags">
              <el-tag 
                v-for="tag in parseConfigTags(config.tags)" 
                :key="tag" 
                size="small" 
                :type="getTagType(tag)"
              >
                {{ tag }}
              </el-tag>
            </div>
            
            <div class="config-stats">
              <div class="stat-item">
                <span class="stat-label">优先级:</span>
                <el-rate v-model="config.priority" :max="10" disabled size="small" />
              </div>
              <div v-if="config.cost_per_token > 0" class="stat-item">
                <span class="stat-label">成本:</span>
                <span class="stat-value">${{ (config.cost_per_token * 1000).toFixed(4) }}/1K tokens</span>
              </div>
            </div>
            
            <p v-if="config.description" class="config-description">
              {{ config.description }}
            </p>
          </div>
          
          <div class="card-actions">
            <el-button size="small" @click.stop="testConfig(config)" :loading="config.testing">
              测试
            </el-button>
            <el-button 
              size="small" 
              type="primary" 
              @click.stop="selectConfig(config)"
            >
              选择
            </el-button>
          </div>
        </div>
      </div>
    </div>

    <!-- 高级选择 -->
    <div v-if="showAdvanced" class="advanced-selector">
      <h5>高级筛选</h5>
      
      <el-row :gutter="16">
        <el-col :span="8">
          <el-form-item label="提供商">
            <el-select v-model="filters.provider" placeholder="全部" clearable @change="applyFilters">
              <el-option label="OpenAI" value="openai" />
              <el-option label="Azure OpenAI" value="azure" />
              <el-option label="Anthropic" value="anthropic" />
              <el-option label="Google AI" value="google" />
              <el-option label="自定义" value="custom" />
            </el-select>
          </el-form-item>
        </el-col>
        
        <el-col :span="8">
          <el-form-item label="标签">
            <el-select v-model="filters.tags" placeholder="全部" multiple clearable @change="applyFilters">
              <el-option 
                v-for="tag in allTags" 
                :key="tag" 
                :label="tag" 
                :value="tag" 
              />
            </el-select>
          </el-form-item>
        </el-col>
        
        <el-col :span="8">
          <el-form-item label="优先级">
            <el-slider 
              v-model="filters.priorityRange" 
              range 
              :min="1" 
              :max="10" 
              @change="applyFilters"
            />
          </el-form-item>
        </el-col>
      </el-row>
      
      <!-- 所有配置列表 -->
      <div class="all-configs">
        <el-table :data="filteredConfigs" size="small">
          <el-table-column prop="name" label="名称" width="150" />
          <el-table-column prop="provider" label="提供商" width="100">
            <template #default="{ row }">
              {{ getProviderName(row.provider) }}
            </template>
          </el-table-column>
          <el-table-column prop="model" label="模型" width="150" />
          <el-table-column prop="priority" label="优先级" width="80" align="center" />
          <el-table-column label="标签" min-width="150">
            <template #default="{ row }">
              <el-tag 
                v-for="tag in parseConfigTags(row.tags)" 
                :key="tag" 
                size="small" 
                :type="getTagType(tag)"
                style="margin-right: 4px;"
              >
                {{ tag }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="120">
            <template #default="{ row }">
              <el-button size="small" @click="selectConfig(row)">选择</el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { http } from '@/utils/http'

// Props
interface Props {
  functionType?: string // chat, optimize, speech, image, code
  modelValue?: number
}

const props = withDefaults(defineProps<Props>(), {
  functionType: 'chat',
  modelValue: null
})

// Emits
const emit = defineEmits<{
  'update:modelValue': [value: number]
  'config-selected': [config: any]
}>()

// 响应式数据
const showAdvanced = ref(false)
const selectedScenario = ref(props.functionType)
const selectedConfigId = ref(props.modelValue)
const allConfigs = ref([])
const recommendedConfigs = ref([])

// 筛选器
const filters = reactive({
  provider: '',
  tags: [] as string[],
  priorityRange: [1, 10] as [number, number]
})

// 使用场景
const scenarios = [
  { value: 'chat', label: '智能对话', icon: 'ChatDotRound' },
  { value: 'optimize', label: '内容优化', icon: 'MagicStick' },
  { value: 'speech', label: '语音处理', icon: 'Microphone' },
  { value: 'image', label: '图像处理', icon: 'Picture' },
  { value: 'code', label: '代码生成', icon: 'Document' },
  { value: 'translate', label: '翻译服务', icon: 'Connection' },
  { value: 'analysis', label: '数据分析', icon: 'DataAnalysis' }
]

// 计算属性
const allTags = computed(() => {
  const tags = new Set<string>()
  allConfigs.value.forEach(config => {
    parseConfigTags(config.tags).forEach(tag => tags.add(tag))
  })
  return Array.from(tags)
})

const filteredConfigs = computed(() => {
  return allConfigs.value.filter(config => {
    // 提供商筛选
    if (filters.provider && config.provider !== filters.provider) {
      return false
    }
    
    // 标签筛选
    if (filters.tags.length > 0) {
      const configTags = parseConfigTags(config.tags)
      if (!filters.tags.some(tag => configTags.includes(tag))) {
        return false
      }
    }
    
    // 优先级筛选
    const priority = config.priority || 5
    if (priority < filters.priorityRange[0] || priority > filters.priorityRange[1]) {
      return false
    }
    
    return true
  })
})

// 获取AI配置
const fetchConfigs = async () => {
  try {
    const response = await http.get('/ai/config')
    let configs = []
    
    if (response.data && response.data.configs) {
      configs = response.data.configs
    } else if (response.data && Array.isArray(response.data)) {
      configs = response.data
    } else if (Array.isArray(response)) {
      configs = response
    }
    
    allConfigs.value = configs.filter(config => config.status === 'active')
    handleScenarioChange()
  } catch (error) {
    console.error('获取AI配置失败:', error)
    ElMessage.error('获取AI配置失败')
  }
}

// 处理场景变化
const handleScenarioChange = () => {
  const scenario = selectedScenario.value
  
  // 筛选适用于当前场景的配置
  const suitableConfigs = allConfigs.value.filter(config => {
    if (!config.categories) return true // 兼容旧配置
    
    try {
      const categories = JSON.parse(config.categories)
      return categories.includes(scenario) || categories.length === 0
    } catch {
      return true
    }
  })
  
  // 计算匹配分数并排序
  const scoredConfigs = suitableConfigs.map(config => {
    let score = 0
    
    // 基础分数（优先级）
    score += (config.priority || 5) * 0.5
    
    // 功能匹配分数
    try {
      const categories = JSON.parse(config.categories || '[]')
      if (categories.includes(scenario)) {
        score += 3
      }
    } catch {}
    
    // 标签匹配分数
    const tags = parseConfigTags(config.tags)
    if (tags.includes('production')) score += 2
    if (tags.includes('stable')) score += 1.5
    if (tags.includes('fast')) score += 1
    if (tags.includes('accurate')) score += 1
    
    // 默认配置加分
    if (config.is_default) score += 1
    
    return {
      ...config,
      matchScore: Math.min(5, Math.round(score))
    }
  })
  
  // 按分数排序，取前3个
  recommendedConfigs.value = scoredConfigs
    .sort((a, b) => b.matchScore - a.matchScore)
    .slice(0, 3)
}

// 应用筛选器
const applyFilters = () => {
  // 筛选逻辑已在计算属性中实现
}

// 选择配置
const selectConfig = (config) => {
  selectedConfigId.value = config.id
  emit('update:modelValue', config.id)
  emit('config-selected', config)
  ElMessage.success(`已选择配置: ${config.name}`)
}

// 测试配置
const testConfig = async (config) => {
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

// 工具函数
const getProviderName = (provider) => {
  const nameMap = {
    openai: 'OpenAI',
    azure: 'Azure OpenAI',
    anthropic: 'Anthropic',
    google: 'Google AI',
    custom: '自定义'
  }
  return nameMap[provider] || provider
}

const parseConfigTags = (tagsJson) => {
  try {
    return JSON.parse(tagsJson || '[]')
  } catch {
    return []
  }
}

const getTagType = (tag) => {
  const typeMap = {
    'production': 'success',
    'development': 'info',
    'testing': 'warning',
    'fast': 'primary',
    'accurate': 'success',
    'cost-effective': 'info',
    'experimental': 'danger',
    'stable': 'success',
    'beta': 'warning'
  }
  return typeMap[tag] || 'info'
}

// 生命周期
onMounted(() => {
  fetchConfigs()
})
</script>

<style scoped>
.ai-model-selector {
  padding: 16px;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  background: #fafafa;
}

.selector-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
}

.selector-info h4 {
  margin: 0 0 4px 0;
  font-size: 16px;
  font-weight: 600;
}

.selector-info p {
  margin: 0;
  font-size: 14px;
  color: #606266;
}

.scenario-selector {
  margin-bottom: 20px;
}

.scenario-option {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 14px;
}

.recommended-configs h5,
.advanced-selector h5 {
  margin: 0 0 12px 0;
  font-size: 14px;
  font-weight: 600;
  color: #303133;
}

.config-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 16px;
  margin-bottom: 20px;
}

.config-card {
  padding: 16px;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  background: white;
  cursor: pointer;
  transition: all 0.3s ease;
}

.config-card:hover {
  border-color: #409eff;
  box-shadow: 0 2px 8px rgba(64, 158, 255, 0.2);
}

.config-card.selected {
  border-color: #409eff;
  background: #f0f9ff;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 12px;
}

.config-info h6 {
  margin: 0 0 4px 0;
  font-size: 16px;
  font-weight: 600;
}

.config-info p {
  margin: 0;
  font-size: 14px;
  color: #606266;
}

.config-score {
  flex-shrink: 0;
}

.card-content {
  margin-bottom: 12px;
}

.config-tags {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
  margin-bottom: 8px;
}

.config-stats {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-bottom: 8px;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
}

.stat-label {
  color: #909399;
  min-width: 50px;
}

.stat-value {
  color: #606266;
  font-weight: 500;
}

.config-description {
  margin: 0;
  font-size: 12px;
  color: #909399;
  line-height: 1.4;
}

.card-actions {
  display: flex;
  gap: 8px;
  justify-content: flex-end;
}

.advanced-selector {
  border-top: 1px solid #e4e7ed;
  padding-top: 16px;
}

.all-configs {
  margin-top: 16px;
}

:deep(.el-radio-button__inner) {
  padding: 8px 12px;
}

:deep(.el-rate) {
  height: auto;
}

:deep(.el-rate--small .el-rate__icon) {
  font-size: 12px;
}
</style>