<template>
  <div class="ai-chat-simple">
    <!-- 聊天界面 -->
    <div class="chat-container">
      <!-- 消息列表 -->
      <div class="messages-area">
        <div v-if="messages.length === 0" class="welcome-message">
          <el-icon class="welcome-icon"><ChatDotRound /></el-icon>
          <h3>欢迎使用AI助手</h3>
          <p>开始与AI助手对话，获取智能回答和建议</p>
        </div>
        
        <div v-else class="messages-list">
          <div
            v-for="message in messages"
            :key="message.id"
            class="message-item"
            :class="message.role"
          >
            <div class="message-avatar">
              <el-icon v-if="message.role === 'user'"><User /></el-icon>
              <el-icon v-else><Avatar /></el-icon>
            </div>
            <div class="message-content">
              <div class="message-text">{{ message.content }}</div>
              <div class="message-time">{{ formatTime(message.timestamp) }}</div>
            </div>
          </div>
          
          <!-- 正在输入 -->
          <div v-if="isTyping" class="message-item assistant typing">
            <div class="message-avatar">
              <el-icon><Avatar /></el-icon>
            </div>
            <div class="message-content">
              <div class="typing-indicator">
                <span></span>
                <span></span>
                <span></span>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- 输入区域 -->
      <div class="input-area">
        <!-- 模型选择工具栏 -->
        <div class="model-toolbar">
          <div class="model-selector">
            <span class="selector-label">AI模型:</span>
            <el-select
              v-model="selectedConfigId"
              placeholder="选择AI配置"
              size="small"
              style="width: 200px"
              @change="handleModelChange"
            >
              <el-option
                v-for="config in aiConfigs"
                :key="config.id"
                :label="`${config.name} (${config.model})`"
                :value="config.id"
              >
                <div class="config-option">
                  <div class="config-header">
                    <span class="config-name">{{ config.name }}</span>
                    <div class="config-badges">
                      <el-tag v-if="config.is_default" type="success" size="small">默认</el-tag>
                      <el-tag v-if="config.priority > 7" type="warning" size="small">高优先级</el-tag>
                    </div>
                  </div>
                  <div class="config-details">
                    <span class="config-model">{{ getProviderName(config.provider) }} - {{ config.model }}</span>
                    <span v-if="config.description" class="config-desc">{{ config.description }}</span>
                  </div>
                  <div v-if="config.tags" class="config-tags">
                    <el-tag 
                      v-for="tag in parseConfigTags(config.tags)" 
                      :key="tag" 
                      size="small" 
                      type="info"
                    >
                      {{ tag }}
                    </el-tag>
                  </div>
                </div>
              </el-option>
            </el-select>
          </div>
          <div class="model-status">
            <el-tag v-if="selectedConfig" :type="selectedConfig.status === 'active' ? 'success' : 'danger'" size="small">
              {{ selectedConfig.status === 'active' ? '可用' : '不可用' }}
            </el-tag>
          </div>
        </div>
        <div class="input-container">
          <el-input
            v-model="inputMessage"
            type="textarea"
            :rows="2"
            placeholder="输入您的问题..."
            @keydown.ctrl.enter="sendMessage"
            :disabled="isTyping || !selectedConfigId"
          />
          <div class="input-actions">
            <span class="input-tip">Ctrl + Enter 发送</span>
            <el-button
              type="primary"
              @click="sendMessage"
              :loading="isTyping"
              :disabled="!inputMessage.trim() || !selectedConfigId"
            >
              发送
            </el-button>
          </div>
        </div>
      </div>
    </div>
    
    <!-- 快速问题 -->
    <div class="quick-questions">
      <h4>快速问题</h4>
      <div class="question-tags">
        <el-tag
          v-for="question in quickQuestions"
          :key="question"
          @click="askQuestion(question)"
          class="question-tag"
        >
          {{ question }}
        </el-tag>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, nextTick } from 'vue'
import { ElMessage } from 'element-plus'
import {
  ChatDotRound,
  User,
  Avatar
} from '@element-plus/icons-vue'
import { http } from '@/utils/http'

// 响应式数据
const inputMessage = ref('')
const isTyping = ref(false)
const messages = ref([])
const aiConfigs = ref([])
const selectedConfigId = ref(null)
const quickQuestions = [
  '如何使用AI功能？',
  '支持哪些AI模型？',
  '如何配置API密钥？',
  '语音识别支持哪些语言？',
  '内容优化有什么功能？'
]

// 计算属性
const selectedConfig = computed(() => {
  return aiConfigs.value.find(config => config.id === selectedConfigId.value)
})

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

// 获取AI配置列表
const fetchAIConfigs = async () => {
  try {
    console.log('正在获取AI配置...')
    const response = await http.get('/ai/config')
    console.log('AI配置响应:', response)
    
    // 处理不同的响应格式
    let configs = []
    if (response.data && response.data.configs) {
      configs = response.data.configs
    } else if (response.data && Array.isArray(response.data)) {
      configs = response.data
    } else if (Array.isArray(response)) {
      configs = response
    }
    
    // 过滤出适用于聊天功能的配置
    const chatConfigs = configs.filter(config => {
      if (!config.categories) return true // 兼容旧配置
      try {
        const categories = JSON.parse(config.categories)
        return categories.includes('chat') || categories.length === 0
      } catch {
        return true // 解析失败时包含该配置
      }
    })
    
    // 按优先级排序
    chatConfigs.sort((a, b) => (b.priority || 5) - (a.priority || 5))
    
    aiConfigs.value = chatConfigs
    console.log('解析的AI配置:', aiConfigs.value)
    
    // 智能选择配置：优先级 > 默认配置 > 第一个可用配置
    if (aiConfigs.value.length > 0 && !selectedConfigId.value) {
      const defaultConfig = aiConfigs.value.find(config => config.is_default && config.status === 'active')
      const highestPriorityConfig = aiConfigs.value.find(config => config.status === 'active')
      const firstActiveConfig = aiConfigs.value.find(config => config.status === 'active')
      
      const selectedConfig = defaultConfig || highestPriorityConfig || firstActiveConfig || aiConfigs.value[0]
      selectedConfigId.value = selectedConfig.id
      console.log('智能选择的配置:', selectedConfig)
    }
    
    if (aiConfigs.value.length === 0) {
      ElMessage.warning('暂无适用于聊天功能的AI配置，请先在配置管理中添加支持聊天功能的AI配置')
    }
  } catch (error) {
    console.error('获取AI配置失败:', error)
    ElMessage.error('获取AI配置失败: ' + (error.response?.data?.error || error.message))
  }
}

// 处理模型切换
const handleModelChange = () => {
  const config = selectedConfig.value
  if (config) {
    ElMessage.success(`已切换到 ${config.name} (${config.model})`)
  }
}

// 发送消息
const sendMessage = async () => {
  if (!inputMessage.value.trim() || !selectedConfigId.value) return
  
  const userMessage = {
    id: Date.now(),
    role: 'user',
    content: inputMessage.value.trim(),
    timestamp: new Date()
  }
  
  messages.value.push(userMessage)
  const question = inputMessage.value.trim()
  inputMessage.value = ''
  isTyping.value = true
  
  await nextTick()
  scrollToBottom()
  
  try {
    console.log('发送AI聊天请求:', {
      message: question,
      config_id: selectedConfigId.value,
      session_id: null
    })
    
    // 真实的AI API调用
    const response = await http.post('/ai/chat', {
      message: question,
      config_id: selectedConfigId.value,
      session_id: null // 简化版不使用会话
    })
    
    console.log('AI聊天响应:', response)
    
    // 处理响应格式
    let content = ''
    if (response.data && response.data.messages && response.data.messages.length > 0) {
      // 获取最后一条AI消息
      const lastMessage = response.data.messages[response.data.messages.length - 1]
      if (lastMessage.role === 'assistant') {
        content = lastMessage.content
      }
    }
    
    // 如果没有找到AI回复，使用默认消息
    if (!content) {
      content = '抱歉，我无法回答这个问题。'
    }
    
    const aiMessage = {
      id: Date.now() + 1,
      role: 'assistant',
      content: content,
      timestamp: new Date()
    }
    
    messages.value.push(aiMessage)
    console.log('AI消息已添加:', aiMessage)
  } catch (error) {
    console.error('AI回复失败:', error)
    console.error('错误详情:', error.response?.data)
    
    // 如果API调用失败，使用模拟回复作为后备
    const aiMessage = {
      id: Date.now() + 1,
      role: 'assistant',
      content: `抱歉，AI服务暂时不可用。错误信息：${error.response?.data?.error || error.message}\n\n这是一个模拟回复：${getAIResponse(question)}`,
      timestamp: new Date()
    }
    messages.value.push(aiMessage)
    ElMessage.warning('AI服务连接失败，显示模拟回复')
  } finally {
    isTyping.value = false
    await nextTick()
    scrollToBottom()
  }
}

// 快速提问
const askQuestion = (question: string) => {
  inputMessage.value = question
  sendMessage()
}

// 获取AI回复（模拟）
const getAIResponse = (question: string) => {
  const responses = {
    '如何使用AI功能？': '您可以通过以下方式使用AI功能：\n1. AI聊天：与智能助手对话\n2. 内容优化：优化文本质量\n3. 语音识别：将语音转为文字\n4. 配置管理：管理AI服务设置',
    '支持哪些AI模型？': '目前支持以下AI模型：\n• OpenAI: GPT-3.5 Turbo, GPT-4, GPT-4 Turbo\n• Azure OpenAI: 企业级GPT模型\n• Anthropic: Claude 3系列\n• Google AI: Gemini Pro系列',
    '如何配置API密钥？': '配置API密钥的步骤：\n1. 进入"配置管理"标签页\n2. 选择AI服务提供商\n3. 输入您的API密钥\n4. 选择合适的模型\n5. 点击"测试连接"验证\n6. 保存配置',
    '语音识别支持哪些语言？': '语音识别支持多种语言：\n• 中文（普通话）\n• 英文\n• 日文\n• 韩文\n• 自动语言检测\n\n支持多种音频格式：MP3、WAV、M4A、FLAC等',
    '内容优化有什么功能？': '内容优化功能包括：\n• 语法修正：纠正语法错误\n• 提升清晰度：让表达更清晰\n• 简化表达：去除冗余内容\n• 专业化：提升专业性\n• 增强吸引力：让内容更有趣'
  }
  
  return responses[question] || `感谢您的问题："${question}"。这是一个很好的问题！作为AI助手，我会尽力为您提供帮助。如果您需要更详细的信息，请随时告诉我。`
}

// 格式化时间
const formatTime = (time: Date) => {
  return time.toLocaleTimeString('zh-CN', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

// 滚动到底部
const scrollToBottom = () => {
  const messagesArea = document.querySelector('.messages-area')
  if (messagesArea) {
    messagesArea.scrollTop = messagesArea.scrollHeight
  }
}

// 生命周期
onMounted(() => {
  fetchAIConfigs()
})
</script>

<style scoped>
.ai-chat-simple {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.chat-container {
  flex: 1;
  display: flex;
  flex-direction: column;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  overflow: hidden;
  background: white;
}

.messages-area {
  flex: 1;
  padding: 16px;
  overflow-y: auto;
  max-height: 400px;
}

.welcome-message {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 200px;
  color: #909399;
  text-align: center;
}

.welcome-icon {
  font-size: 48px;
  margin-bottom: 16px;
  color: #c0c4cc;
}

.welcome-message h3 {
  margin: 0 0 8px 0;
  font-size: 18px;
  font-weight: 600;
}

.welcome-message p {
  margin: 0;
  font-size: 14px;
}

.messages-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.message-item {
  display: flex;
  gap: 8px;
}

.message-item.user {
  flex-direction: row-reverse;
}

.message-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.message-item.user .message-avatar {
  background-color: #409eff;
  color: white;
}

.message-item.assistant .message-avatar {
  background-color: #67c23a;
  color: white;
}

.message-content {
  max-width: 70%;
  flex: 1;
}

.message-item.user .message-content {
  text-align: right;
}

.message-text {
  background-color: #f5f7fa;
  padding: 8px 12px;
  border-radius: 8px;
  line-height: 1.5;
  word-wrap: break-word;
  white-space: pre-wrap;
}

.message-item.user .message-text {
  background-color: #409eff;
  color: white;
}

.message-time {
  font-size: 11px;
  color: #c0c4cc;
  margin-top: 4px;
}

.typing-indicator {
  display: flex;
  align-items: center;
  padding: 8px 12px;
  background-color: #f5f7fa;
  border-radius: 8px;
}

.typing-indicator span {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background-color: #c0c4cc;
  margin-right: 4px;
  animation: typing 1.4s infinite ease-in-out;
}

.typing-indicator span:nth-child(1) {
  animation-delay: -0.32s;
}

.typing-indicator span:nth-child(2) {
  animation-delay: -0.16s;
}

@keyframes typing {
  0%, 80%, 100% {
    transform: scale(0.8);
    opacity: 0.5;
  }
  40% {
    transform: scale(1);
    opacity: 1;
  }
}

.input-area {
  border-top: 1px solid #e4e7ed;
  padding: 12px 16px;
  background: #fafafa;
}

.model-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  padding: 8px 12px;
  background: white;
  border-radius: 6px;
  border: 1px solid #e4e7ed;
}

.model-selector {
  display: flex;
  align-items: center;
  gap: 8px;
}

.selector-label {
  font-size: 14px;
  color: #606266;
  font-weight: 500;
}

.config-option {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 4px 0;
}

.config-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.config-name {
  font-weight: 500;
  font-size: 14px;
}

.config-badges {
  display: flex;
  gap: 4px;
}

.config-details {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.config-model {
  font-size: 12px;
  color: #606266;
  font-weight: 500;
}

.config-desc {
  font-size: 11px;
  color: #909399;
  line-height: 1.2;
}

.config-tags {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
}

.model-status {
  display: flex;
  align-items: center;
}

.input-container {
  position: relative;
}

.input-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 8px;
}

.input-tip {
  font-size: 12px;
  color: #909399;
}

.quick-questions {
  background: white;
  padding: 16px;
  border-radius: 8px;
  border: 1px solid #e4e7ed;
}

.quick-questions h4 {
  margin: 0 0 12px 0;
  font-size: 14px;
  font-weight: 600;
  color: #303133;
}

.question-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.question-tag {
  cursor: pointer;
  transition: all 0.2s;
}

.question-tag:hover {
  background-color: #409eff;
  color: white;
  border-color: #409eff;
}

:deep(.el-textarea__inner) {
  resize: none;
}
</style>