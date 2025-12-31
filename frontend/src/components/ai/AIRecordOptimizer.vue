<template>
  <div class="ai-record-optimizer">
    <!-- 工具栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <h3>AI记录优化</h3>
        <p>使用AI技术优化记录内容，提升质量和可读性</p>
      </div>
      <div class="toolbar-right">
        <el-select
          v-model="selectedConfigId"
          placeholder="选择AI配置"
          style="width: 200px"
        >
          <el-option
            v-for="config in aiConfigs"
            :key="config.id"
            :label="`${config.name} (${config.provider})`"
            :value="config.id"
          />
        </el-select>
      </div>
    </div>

    <!-- 主要内容区域 -->
    <div class="content-area">
      <el-row :gutter="20">
        <!-- 左侧：输入区域 -->
        <el-col :span="12">
          <el-card class="input-card">
            <template #header>
              <div class="card-header">
                <span>原始内容</span>
                <div class="header-actions">
                  <el-button size="small" @click="loadFromRecord">
                    <el-icon><DocumentCopy /></el-icon>
                    从记录加载
                  </el-button>
                  <el-button size="small" @click="clearInput">
                    <el-icon><Delete /></el-icon>
                    清空
                  </el-button>
                </div>
              </div>
            </template>

            <div class="input-section">
              <el-form :model="optimizeForm" label-width="80px">
                <el-form-item label="内容类型">
                  <el-select v-model="optimizeForm.contentType" style="width: 100%">
                    <el-option label="通用文本" value="general" />
                    <el-option label="技术文档" value="technical" />
                    <el-option label="商务报告" value="business" />
                    <el-option label="学术论文" value="academic" />
                    <el-option label="创意写作" value="creative" />
                  </el-select>
                </el-form-item>

                <el-form-item label="优化目标">
                  <el-checkbox-group v-model="optimizeForm.goals">
                    <el-checkbox label="grammar">语法修正</el-checkbox>
                    <el-checkbox label="clarity">提升清晰度</el-checkbox>
                    <el-checkbox label="conciseness">简化表达</el-checkbox>
                    <el-checkbox label="professionalism">专业化</el-checkbox>
                    <el-checkbox label="engagement">增强吸引力</el-checkbox>
                  </el-checkbox-group>
                </el-form-item>

                <el-form-item label="原始内容">
                  <el-input
                    v-model="optimizeForm.content"
                    type="textarea"
                    :rows="12"
                    placeholder="请输入需要优化的内容..."
                    maxlength="5000"
                    show-word-limit
                  />
                </el-form-item>

                <el-form-item>
                  <el-button
                    type="primary"
                    @click="optimizeContent"
                    :loading="optimizing"
                    :disabled="!optimizeForm.content.trim() || !selectedConfigId"
                    style="width: 100%"
                  >
                    <el-icon><MagicStick /></el-icon>
                    开始优化
                  </el-button>
                </el-form-item>
              </el-form>
            </div>
          </el-card>
        </el-col>

        <!-- 右侧：输出区域 -->
        <el-col :span="12">
          <el-card class="output-card">
            <template #header>
              <div class="card-header">
                <span>优化结果</span>
                <div class="header-actions" v-if="optimizedContent">
                  <el-button size="small" @click="copyResult">
                    <el-icon><DocumentCopy /></el-icon>
                    复制结果
                  </el-button>
                  <el-button size="small" @click="saveToRecord">
                    <el-icon><Document /></el-icon>
                    保存为记录
                  </el-button>
                </div>
              </div>
            </template>

            <div class="output-section">
              <div v-if="!optimizedContent && !optimizing" class="empty-state">
                <el-icon class="empty-icon"><MagicStick /></el-icon>
                <p>优化结果将在这里显示</p>
              </div>

              <div v-if="optimizing" class="optimizing-state">
                <el-icon class="is-loading"><Loading /></el-icon>
                <p>AI正在优化内容，请稍候...</p>
                <div class="progress-info">
                  <span>预计时间: {{ estimatedTime }}秒</span>
                </div>
              </div>

              <div v-if="optimizedContent" class="result-content">
                <div class="result-text">
                  {{ optimizedContent }}
                </div>
                
                <div class="result-stats">
                  <el-divider />
                  <div class="stats-grid">
                    <div class="stat-item">
                      <span class="stat-label">原始字数</span>
                      <span class="stat-value">{{ originalWordCount }}</span>
                    </div>
                    <div class="stat-item">
                      <span class="stat-label">优化后字数</span>
                      <span class="stat-value">{{ optimizedWordCount }}</span>
                    </div>
                    <div class="stat-item">
                      <span class="stat-label">字数变化</span>
                      <span class="stat-value" :class="wordCountChangeClass">
                        {{ wordCountChange }}
                      </span>
                    </div>
                    <div class="stat-item">
                      <span class="stat-label">处理时间</span>
                      <span class="stat-value">{{ processingTime }}秒</span>
                    </div>
                  </div>
                </div>

                <div class="improvement-summary" v-if="improvements.length > 0">
                  <el-divider />
                  <h4>改进说明</h4>
                  <ul class="improvement-list">
                    <li v-for="improvement in improvements" :key="improvement">
                      {{ improvement }}
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- 历史记录 -->
    <el-card class="history-card" v-if="optimizationHistory.length > 0">
      <template #header>
        <div class="card-header">
          <span>优化历史</span>
          <el-button size="small" @click="clearHistory">
            <el-icon><Delete /></el-icon>
            清空历史
          </el-button>
        </div>
      </template>

      <div class="history-list">
        <div
          v-for="item in optimizationHistory"
          :key="item.id"
          class="history-item"
          @click="loadHistoryItem(item)"
        >
          <div class="history-content">
            <div class="history-title">{{ item.contentType }} - {{ formatTime(item.created_at) }}</div>
            <div class="history-preview">{{ item.originalContent.substring(0, 100) }}...</div>
          </div>
          <div class="history-actions">
            <el-button size="small" type="text">查看详情</el-button>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 从记录加载对话框 -->
    <el-dialog v-model="showRecordDialog" title="选择记录" width="600px">
      <RecordSelector @select="handleRecordSelect" />
    </el-dialog>

    <!-- 保存为记录对话框 -->
    <el-dialog v-model="showSaveDialog" title="保存为记录" width="500px">
      <el-form :model="saveForm" label-width="80px">
        <el-form-item label="记录标题">
          <el-input v-model="saveForm.title" placeholder="请输入记录标题" />
        </el-form-item>
        <el-form-item label="记录类型">
          <el-select v-model="saveForm.typeId" style="width: 100%">
            <el-option
              v-for="type in recordTypes"
              :key="type.id"
              :label="type.name"
              :value="type.id"
            />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showSaveDialog = false">取消</el-button>
        <el-button type="primary" @click="confirmSave">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  DocumentCopy,
  Delete,
  MagicStick,
  Loading,
  Document
} from '@element-plus/icons-vue'
import { http } from '@/utils/http'
import { formatTime } from '@/utils/format'
import RecordSelector from '@/components/records/RecordSelector.vue'

// 响应式数据
const aiConfigs = ref([])
const selectedConfigId = ref(null)
const optimizing = ref(false)
const estimatedTime = ref(0)
const optimizedContent = ref('')
const originalWordCount = ref(0)
const optimizedWordCount = ref(0)
const processingTime = ref(0)
const improvements = ref([])
const optimizationHistory = ref([])
const recordTypes = ref([])

// 对话框
const showRecordDialog = ref(false)
const showSaveDialog = ref(false)

// 表单数据
const optimizeForm = reactive({
  content: '',
  contentType: 'general',
  goals: ['grammar', 'clarity']
})

const saveForm = reactive({
  title: '',
  typeId: null
})

// 计算属性
const wordCountChange = computed(() => {
  const change = optimizedWordCount.value - originalWordCount.value
  if (change > 0) return `+${change}`
  return change.toString()
})

const wordCountChangeClass = computed(() => {
  const change = optimizedWordCount.value - originalWordCount.value
  if (change > 0) return 'increase'
  if (change < 0) return 'decrease'
  return 'neutral'
})

// 获取AI配置
const fetchAIConfigs = async () => {
  try {
    const response = await http.get('/ai/config')
    aiConfigs.value = response.data.configs || []
    if (aiConfigs.value.length > 0) {
      selectedConfigId.value = aiConfigs.value[0].id
    }
  } catch (error) {
    console.error('获取AI配置失败:', error)
  }
}

// 获取记录类型
const fetchRecordTypes = async () => {
  try {
    const response = await http.get('/record-types')
    recordTypes.value = response.data.types || []
  } catch (error) {
    console.error('获取记录类型失败:', error)
  }
}

// 优化内容
const optimizeContent = async () => {
  if (!optimizeForm.content.trim() || !selectedConfigId.value) {
    return
  }

  optimizing.value = true
  originalWordCount.value = optimizeForm.content.length
  estimatedTime.value = Math.ceil(originalWordCount.value / 100) * 2 // 估算时间

  const startTime = Date.now()

  try {
    const response = await http.post('/ai/optimize-record', {
      content: {
        text: optimizeForm.content,
        type: optimizeForm.contentType
      },
      goals: optimizeForm.goals,
      config_id: selectedConfigId.value
    })

    optimizedContent.value = response.data.optimized_content
    optimizedWordCount.value = optimizedContent.value.length
    processingTime.value = Math.round((Date.now() - startTime) / 1000)
    improvements.value = response.data.improvements || []

    // 添加到历史记录
    optimizationHistory.value.unshift({
      id: Date.now(),
      originalContent: optimizeForm.content,
      optimizedContent: optimizedContent.value,
      contentType: optimizeForm.contentType,
      goals: [...optimizeForm.goals],
      created_at: new Date().toISOString()
    })

    ElMessage.success('内容优化完成')
  } catch (error) {
    ElMessage.error('内容优化失败')
  } finally {
    optimizing.value = false
  }
}

// 清空输入
const clearInput = () => {
  optimizeForm.content = ''
  optimizedContent.value = ''
  improvements.value = []
}

// 复制结果
const copyResult = async () => {
  try {
    await navigator.clipboard.writeText(optimizedContent.value)
    ElMessage.success('结果已复制到剪贴板')
  } catch (error) {
    ElMessage.error('复制失败')
  }
}

// 从记录加载
const loadFromRecord = () => {
  showRecordDialog.value = true
}

// 处理记录选择
const handleRecordSelect = (record: any) => {
  optimizeForm.content = record.content || record.description || ''
  showRecordDialog.value = false
}

// 保存为记录
const saveToRecord = () => {
  saveForm.title = `优化后的${optimizeForm.contentType}内容`
  showSaveDialog.value = true
}

// 确认保存
const confirmSave = async () => {
  try {
    await http.post('/records', {
      title: saveForm.title,
      content: optimizedContent.value,
      type_id: saveForm.typeId
    })
    
    ElMessage.success('记录保存成功')
    showSaveDialog.value = false
  } catch (error) {
    ElMessage.error('保存记录失败')
  }
}

// 加载历史项目
const loadHistoryItem = (item: any) => {
  optimizeForm.content = item.originalContent
  optimizeForm.contentType = item.contentType
  optimizeForm.goals = item.goals
  optimizedContent.value = item.optimizedContent
}

// 清空历史
const clearHistory = () => {
  optimizationHistory.value = []
  ElMessage.success('历史记录已清空')
}

// 生命周期
onMounted(() => {
  fetchAIConfigs()
  fetchRecordTypes()
})
</script>

<style scoped>
.ai-record-optimizer {
  padding: 0;
}

.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
  padding: 16px;
  background: white;
  border-radius: 4px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.toolbar-left h3 {
  margin: 0 0 4px 0;
  font-size: 18px;
  font-weight: 600;
}

.toolbar-left p {
  margin: 0;
  color: #606266;
  font-size: 14px;
}

.content-area {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  gap: 8px;
}

.input-section,
.output-section {
  min-height: 400px;
}

.empty-state,
.optimizing-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 300px;
  color: #909399;
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 16px;
  color: #c0c4cc;
}

.optimizing-state .el-icon {
  font-size: 32px;
  margin-bottom: 16px;
  color: #409eff;
}

.progress-info {
  margin-top: 8px;
  font-size: 12px;
}

.result-content {
  height: 100%;
}

.result-text {
  padding: 16px;
  background: #f5f7fa;
  border-radius: 4px;
  line-height: 1.6;
  white-space: pre-wrap;
  word-wrap: break-word;
  max-height: 300px;
  overflow-y: auto;
}

.result-stats {
  margin-top: 16px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

.stat-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.stat-label {
  font-size: 14px;
  color: #606266;
}

.stat-value {
  font-weight: 600;
}

.stat-value.increase {
  color: #f56c6c;
}

.stat-value.decrease {
  color: #67c23a;
}

.stat-value.neutral {
  color: #909399;
}

.improvement-summary h4 {
  margin: 16px 0 8px 0;
  font-size: 14px;
  font-weight: 600;
}

.improvement-list {
  margin: 0;
  padding-left: 20px;
}

.improvement-list li {
  margin-bottom: 4px;
  font-size: 14px;
  color: #606266;
}

.history-card {
  margin-top: 20px;
}

.history-list {
  max-height: 300px;
  overflow-y: auto;
}

.history-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  margin-bottom: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.history-item:hover {
  background-color: #f5f7fa;
  border-color: #409eff;
}

.history-content {
  flex: 1;
}

.history-title {
  font-weight: 500;
  margin-bottom: 4px;
}

.history-preview {
  font-size: 12px;
  color: #909399;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

:deep(.el-checkbox-group) {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

:deep(.el-checkbox) {
  margin-right: 0;
}
</style>