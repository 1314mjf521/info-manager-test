<template>
  <div class="ai-management">
    <!-- 页面头部 -->
    <div class="page-header">
      <div class="header-content">
        <h1 class="page-title">
          <el-icon><Avatar /></el-icon>
          AI功能管理
        </h1>
        <p class="page-description">管理AI服务配置，使用AI功能提升工作效率</p>
      </div>
      <div class="header-actions">
        <el-button type="primary" @click="showConfigDialog = true">
          <el-icon><Plus /></el-icon>
          添加AI配置
        </el-button>
      </div>
    </div>

    <!-- 功能卡片 -->
    <div class="feature-cards">
      <el-row :gutter="{ xs: 8, sm: 12, md: 16, lg: 20, xl: 24 }">
        <el-col :xs="24" :sm="12" :md="6" :lg="6" :xl="6">
          <el-card class="feature-card" :class="{ active: activeTab === 'chat' }" @click="activeTab = 'chat'">
            <div class="card-content">
              <el-icon class="card-icon chat"><ChatDotRound /></el-icon>
              <h3>AI聊天</h3>
              <p>智能对话助手，回答问题和提供建议</p>
            </div>
          </el-card>
        </el-col>
        <el-col :xs="24" :sm="12" :md="6" :lg="6" :xl="6">
          <el-card class="feature-card" :class="{ active: activeTab === 'optimize' }" @click="activeTab = 'optimize'">
            <div class="card-content">
              <el-icon class="card-icon optimize"><MagicStick /></el-icon>
              <h3>内容优化</h3>
              <p>使用AI优化记录内容，提升质量</p>
            </div>
          </el-card>
        </el-col>
        <el-col :xs="24" :sm="12" :md="6" :lg="6" :xl="6">
          <el-card class="feature-card" :class="{ active: activeTab === 'speech' }" @click="activeTab = 'speech'">
            <div class="card-content">
              <el-icon class="card-icon speech"><Microphone /></el-icon>
              <h3>语音识别</h3>
              <p>将语音转换为文字，提高输入效率</p>
            </div>
          </el-card>
        </el-col>
        <el-col :xs="24" :sm="12" :md="6" :lg="6" :xl="6">
          <el-card class="feature-card" :class="{ active: activeTab === 'config' }" @click="activeTab = 'config'">
            <div class="card-content">
              <el-icon class="card-icon config"><Setting /></el-icon>
              <h3>配置管理</h3>
              <p>管理AI服务配置和使用统计</p>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- 主要内容区域 -->
    <el-card class="main-content">
      <el-tabs v-model="activeTab" type="border-card">
        <!-- AI聊天 -->
        <el-tab-pane label="AI聊天" name="chat">
          <AIChatSimple />
        </el-tab-pane>

        <!-- 内容优化 -->
        <el-tab-pane label="内容优化" name="optimize">
          <AIRecordOptimizer />
        </el-tab-pane>

        <!-- 语音识别 -->
        <el-tab-pane label="语音识别" name="speech">
          <AISpeechToText />
        </el-tab-pane>

        <!-- 配置管理 -->
        <el-tab-pane label="配置管理" name="config">
          <AIConfigSimple ref="configComponentRef" @config-saved="handleConfigSaved" />
        </el-tab-pane>

        <!-- 使用统计 -->
        <el-tab-pane label="使用统计" name="stats">
          <AIStats />
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- AI配置对话框 -->
    <el-dialog
      v-model="showConfigDialog"
      title="添加AI配置"
      width="600px"
      :before-close="handleConfigDialogClose"
    >
      <AIConfigForm
        :config="currentConfig"
        @save="handleConfigSave"
        @cancel="handleConfigCancel"
      />
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { http } from '../../utils/http'
import {
  Avatar,
  Plus,
  ChatDotRound,
  MagicStick,
  Microphone,
  Setting
} from '@element-plus/icons-vue'

// 导入子组件
import AIChatSimple from '../../components/ai/AIChatSimple.vue'
import AIRecordOptimizer from '../../components/ai/AIRecordOptimizer.vue'
import AISpeechToText from '../../components/ai/AISpeechToText.vue'
import AIConfigSimple from '../../components/ai/AIConfigSimple.vue'
import AIStats from '../../components/ai/AIStats.vue'
import AIConfigForm from '../../components/ai/AIConfigForm.vue'

// 响应式数据
const activeTab = ref('chat')
const showConfigDialog = ref(false)
const currentConfig = ref(null)
const chatComponentRef = ref(null)
const configComponentRef = ref(null)

// 处理配置对话框
const handleConfigDialogClose = () => {
  showConfigDialog.value = false
  currentConfig.value = null
}

const handleConfigSave = async (config: any) => {
  try {
    // 转换数据格式以匹配后端期望的格式
    const requestData = {
      name: config.name,
      provider: config.provider,
      api_key: config.apiKey || config.api_key,
      api_endpoint: config.apiEndpoint || config.api_endpoint || '',
      model: config.model,
      config: config.config || '',
      categories: config.categories || ['chat'],
      tags: config.tags || ['production'],
      description: config.description || `${config.provider} 配置`,
      priority: config.priority || 5,
      is_active: config.isActive !== undefined ? config.isActive : true,
      is_default: config.isDefault !== undefined ? config.isDefault : false,
      max_tokens: config.maxTokens || config.max_tokens || 4096,
      temperature: config.temperature || 0.7,
      daily_limit: config.dailyLimit || config.daily_limit || 0,
      monthly_limit: config.monthlyLimit || config.monthly_limit || 0,
      cost_per_token: config.costPerToken || config.cost_per_token || 0
    }

    console.log('AIManagement保存配置数据:', requestData)

    // 调用API保存配置
    await http.post('/ai/config', requestData)
    ElMessage.success('AI配置保存成功')
    
    showConfigDialog.value = false
    currentConfig.value = null
    
    // 触发配置保存事件，刷新相关组件
    handleConfigSaved(requestData)
  } catch (error: any) {
    console.error('保存配置失败:', error)
    ElMessage.error(error.response?.data?.error || error.response?.data?.message || '保存配置失败')
  }
}

const handleConfigCancel = () => {
  showConfigDialog.value = false
  currentConfig.value = null
}

// 处理配置保存事件
const handleConfigSaved = (config: any) => {
  // 刷新配置管理组件
  if (configComponentRef.value && typeof configComponentRef.value.fetchConfigs === 'function') {
    configComponentRef.value.fetchConfigs()
  }
  
  // 刷新聊天组件中的模型选择器
  if (chatComponentRef.value && typeof chatComponentRef.value.refreshModelSelector === 'function') {
    chatComponentRef.value.refreshModelSelector()
  }
}

// 生命周期
onMounted(() => {
  // 初始化数据
})
</script>

<style scoped>
.ai-management {
  padding: 16px;
  background-color: #f5f5f5;
  min-height: calc(100vh - 60px);
  overflow-x: hidden;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
  background: white;
  padding: 16px 20px;
  border-radius: 8px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.header-content {
  flex: 1;
  min-width: 0;
}

.page-title {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 8px 0;
  font-size: 20px;
  font-weight: 600;
  color: #303133;
}

.page-description {
  margin: 0;
  color: #606266;
  font-size: 14px;
}

.header-actions {
  display: flex;
  gap: 8px;
  flex-shrink: 0;
}

.feature-cards {
  margin-bottom: 20px;
}

.feature-card {
  cursor: pointer;
  transition: all 0.3s ease;
  height: 120px;
  border-radius: 8px;
  border: 2px solid transparent;
  margin-bottom: 16px;
}

.feature-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 20px 0 rgba(0, 0, 0, 0.15);
}

.feature-card.active {
  border-color: #409eff;
  box-shadow: 0 2px 12px 0 rgba(64, 158, 255, 0.3);
}

.feature-card.active .card-content h3 {
  color: #409eff;
}

.card-content {
  text-align: center;
  padding: 16px 12px;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.card-icon {
  font-size: 32px;
  margin-bottom: 8px;
  flex-shrink: 0;
}

.card-icon.chat {
  color: #409eff;
}

.card-icon.optimize {
  color: #67c23a;
}

.card-icon.speech {
  color: #e6a23c;
}

.card-icon.config {
  color: #909399;
}

.card-content h3 {
  margin: 6px 0 4px 0;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  white-space: nowrap;
}

.card-content p {
  margin: 0;
  font-size: 12px;
  color: #606266;
  line-height: 1.4;
  text-align: center;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.main-content {
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  border-radius: 8px;
  overflow: hidden;
  background: white;
}

:deep(.el-tabs__content) {
  padding: 20px;
  min-height: 400px;
  max-height: calc(100vh - 320px);
  overflow-y: auto;
}

:deep(.el-tabs__item) {
  font-weight: 500;
  font-size: 14px;
  padding: 0 20px;
}

:deep(.el-tabs__item.is-active) {
  color: #409eff;
}

:deep(.el-tabs__header) {
  margin: 0;
  background: #fafafa;
  border-bottom: 1px solid #e4e7ed;
}

:deep(.el-tabs__nav-wrap) {
  padding: 0 16px;
}

:deep(.el-card__body) {
  padding: 0;
}

/* 功能卡片容器优化 */
.feature-cards :deep(.el-row) {
  display: flex;
  flex-wrap: wrap;
}

.feature-cards :deep(.el-col) {
  display: flex;
  flex-direction: column;
}

/* 确保卡片在所有屏幕上都有相同高度 */
.feature-cards :deep(.el-card) {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.feature-cards :deep(.el-card__body) {
  flex: 1;
  display: flex;
  flex-direction: column;
}

/* 响应式设计 */

/* 超大屏幕 (≥1920px) */
@media (min-width: 1920px) {
  .feature-card {
    height: 140px;
  }
  
  .card-icon {
    font-size: 36px;
    margin-bottom: 10px;
  }
  
  .card-content h3 {
    font-size: 18px;
  }
  
  .card-content p {
    font-size: 14px;
  }
}

/* 大屏幕 (1200px-1919px) */
@media (min-width: 1200px) and (max-width: 1919px) {
  .feature-card {
    height: 120px;
  }
  
  .card-icon {
    font-size: 32px;
  }
  
  .card-content h3 {
    font-size: 16px;
  }
  
  .card-content p {
    font-size: 12px;
  }
}

/* 中等屏幕 (992px-1199px) */
@media (min-width: 992px) and (max-width: 1199px) {
  .ai-management {
    padding: 12px;
  }
  
  .feature-card {
    height: 110px;
  }
  
  .card-content {
    padding: 12px 8px;
  }
  
  .card-icon {
    font-size: 28px;
    margin-bottom: 6px;
  }
  
  .card-content h3 {
    font-size: 15px;
    margin: 4px 0 3px 0;
  }
  
  .card-content p {
    font-size: 11px;
  }
}

/* 平板屏幕 (768px-991px) */
@media (min-width: 768px) and (max-width: 991px) {
  .ai-management {
    padding: 12px;
  }
  
  .page-header {
    flex-direction: column;
    gap: 12px;
    align-items: stretch;
    padding: 16px;
  }
  
  .header-actions {
    justify-content: flex-start;
  }
  
  .feature-card {
    height: 100px;
    margin-bottom: 12px;
  }
  
  .card-content {
    padding: 10px 8px;
  }
  
  .card-icon {
    font-size: 26px;
    margin-bottom: 5px;
  }
  
  .card-content h3 {
    font-size: 14px;
    margin: 3px 0 2px 0;
  }
  
  .card-content p {
    font-size: 11px;
    line-height: 1.3;
  }
}

/* 小屏幕 (576px-767px) */
@media (min-width: 576px) and (max-width: 767px) {
  .ai-management {
    padding: 10px;
  }
  
  .page-header {
    flex-direction: column;
    gap: 12px;
    padding: 14px;
  }
  
  .page-title {
    font-size: 18px;
  }
  
  .feature-card {
    height: 90px;
    margin-bottom: 10px;
  }
  
  .card-content {
    padding: 8px 6px;
  }
  
  .card-icon {
    font-size: 24px;
    margin-bottom: 4px;
  }
  
  .card-content h3 {
    font-size: 13px;
    margin: 2px 0 1px 0;
  }
  
  .card-content p {
    font-size: 10px;
    line-height: 1.2;
    -webkit-line-clamp: 1;
  }
  
  :deep(.el-tabs__content) {
    padding: 12px;
    min-height: 300px;
  }
}

/* 超小屏幕 (<576px) */
@media (max-width: 575px) {
  .ai-management {
    padding: 8px;
  }
  
  .page-header {
    flex-direction: column;
    gap: 10px;
    padding: 12px;
  }
  
  .page-title {
    font-size: 16px;
  }
  
  .page-description {
    font-size: 12px;
  }
  
  .header-actions {
    flex-direction: column;
    gap: 8px;
  }
  
  .header-actions .el-button {
    width: 100%;
    font-size: 14px;
  }
  
  .feature-cards {
    margin-bottom: 16px;
  }
  
  .feature-card {
    height: 80px;
    margin-bottom: 8px;
  }
  
  .card-content {
    padding: 6px 4px;
  }
  
  .card-icon {
    font-size: 20px;
    margin-bottom: 3px;
  }
  
  .card-content h3 {
    font-size: 12px;
    margin: 1px 0;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  
  .card-content p {
    font-size: 9px;
    line-height: 1.1;
    -webkit-line-clamp: 1;
  }
  
  :deep(.el-tabs__content) {
    padding: 8px;
    min-height: 250px;
  }
  
  :deep(.el-tabs__item) {
    font-size: 12px;
    padding: 0 8px;
  }
}
</style>
