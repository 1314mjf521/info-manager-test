<template>
  <div class="ai-chat">
    <div class="chat-container">
      <!-- 聊天会话列表 -->
      <div class="chat-sidebar">
        <div class="sidebar-header">
          <h3>聊天会话</h3>
          <el-button type="primary" size="small" @click="createNewSession">
            <el-icon><Plus /></el-icon>
            新建会话
          </el-button>
        </div>
        
        <div class="session-list">
          <div
            v-for="session in sessions"
            :key="session.id"
            class="session-item"
            :class="{ active: currentSessionId === session.id }"
            @click="selectSession(session.id)"
          >
            <div class="session-title">{{ session.title }}</div>
            <div class="session-time">{{ formatTime(session.updated_at) }}</div>
            <el-dropdown trigger="click" @command="handleSessionAction">
              <el-icon class="session-menu"><MoreFilled /></el-icon>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item :command="{ action: 'rename', session }">重命名</el-dropdown-item>
                  <el-dropdown-item :command="{ action: 'delete', session }" divided>删除</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </div>
        </div>
      </div>

      <!-- 聊天主区域 -->
      <div class="chat-main">
        <div v-if="!currentSessionId" class="chat-welcome">
          <el-icon class="welcome-icon"><ChatDotRound /></el-icon>
          <h2>欢迎使用AI助手</h2>
          <p>选择一个会话开始对话，或创建新的会话</p>
        </div>

        <div v-else class="chat-content">
          <!-- 消息列表 -->
          <div ref="messagesContainer" class="messages-container">
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
                <div class="message-text" v-html="formatMessage(message.content)"></div>
                <div class="message-time">{{ formatTime(message.created_at) }}</div>
              </div>
            </div>

            <!-- 正在输入指示器 -->
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

          <!-- 输入区域 -->
          <div class="input-area">
            <div class="input-toolbar">
              <el-select
                v-model="selectedConfigId"
                placeholder="选择AI配置"
                size="small"
                style="width: 200px"
              >
                <el-option
                  v-for="config in aiConfigs"
                  :key="config.id"
                  :label="`${config.name} (${config.provider})`"
                  :value="config.id"
                />
              </el-select>
              
              <el-button
                size="small"
                @click="clearMessages"
                :disabled="messages.length === 0"
              >
                清空对话
              </el-button>
            </div>

            <div class="input-container">
              <el-input
                v-model="inputMessage"
                type="textarea"
                :rows="3"
                placeholder="输入您的问题..."
                @keydown.ctrl.enter="sendMessage"
                :disabled="isTyping"
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
      </div>
    </div>

    <!-- 重命名会话对话框 -->
    <el-dialog v-model="showRenameDialog" title="重命名会话" width="400px">
      <el-form>
        <el-form-item label="会话名称">
          <el-input v-model="renameTitle" placeholder="请输入会话名称" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showRenameDialog = false">取消</el-button>
        <el-button type="primary" @click="confirmRename">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, nextTick, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Plus,
  MoreFilled,
  ChatDotRound,
  User,
  Avatar
} from '@element-plus/icons-vue'
import { http } from '@/utils/http'
import { formatTime } from '@/utils/format'

// 类型定义
interface ChatSession {
  id: number
  title: string
  updated_at: string
}

interface ChatMessage {
  id: number
  role: 'user' | 'assistant'
  content: string
  created_at: string
}

interface AIConfig {
  id: number
  name: string
  provider: string
}

// 响应式数据
const sessions = ref<ChatSession[]>([])
const messages = ref<ChatMessage[]>([])
const aiConfigs = ref<AIConfig[]>([])
const currentSessionId = ref<number | null>(null)
const selectedConfigId = ref<number | null>(null)
const inputMessage = ref('')
const isTyping = ref(false)
const messagesContainer = ref<HTMLElement>()

// 对话框相关
const showRenameDialog = ref(false)
const renameTitle = ref('')
const currentRenameSession = ref<ChatSession | null>(null)

// 获取聊天会话列表
const fetchSessions = async () => {
  try {
    const response = await http.get('/ai/sessions')
    sessions.value = response.data.sessions || []
  } catch (error) {
    console.error('获取会话列表失败:', error)
  }
}

// 获取AI配置列表
const fetchAIConfigs = async () => {
  try {
    const response = await http.get('/ai/config')
    aiConfigs.value = response.data.configs || []
    if (aiConfigs.value.length > 0 && !selectedConfigId.value) {
      selectedConfigId.value = aiConfigs.value[0].id
    }
  } catch (error) {
    console.error('获取AI配置失败:', error)
  }
}

// 获取会话消息
const fetchMessages = async (sessionId: number) => {
  try {
    const response = await http.get(`/ai/sessions/${sessionId}/messages`)
    messages.value = response.data.messages || []
    await nextTick()
    scrollToBottom()
  } catch (error) {
    console.error('获取消息失败:', error)
  }
}

// 创建新会话
const createNewSession = async () => {
  try {
    const response = await http.post('/ai/sessions', {
      title: '新的对话'
    })
    const newSession = response.data
    sessions.value.unshift(newSession)
    selectSession(newSession.id)
  } catch (error) {
    ElMessage.error('创建会话失败')
  }
}

// 选择会话
const selectSession = (sessionId: number) => {
  currentSessionId.value = sessionId
  fetchMessages(sessionId)
}

// 发送消息
const sendMessage = async () => {
  if (!inputMessage.value.trim() || !selectedConfigId.value || !currentSessionId.value) {
    return
  }

  const userMessage = inputMessage.value.trim()
  inputMessage.value = ''
  isTyping.value = true

  // 添加用户消息到界面
  const userMsg: ChatMessage = {
    id: Date.now(),
    role: 'user',
    content: userMessage,
    created_at: new Date().toISOString()
  }
  messages.value.push(userMsg)
  await nextTick()
  scrollToBottom()

  try {
    const response = await http.post('/ai/chat', {
      session_id: currentSessionId.value,
      message: userMessage,
      config_id: selectedConfigId.value
    })

    // 添加AI回复到界面
    const aiMsg: ChatMessage = {
      id: response.data.message.id,
      role: 'assistant',
      content: response.data.message.content,
      created_at: response.data.message.created_at
    }
    messages.value.push(aiMsg)
    
    await nextTick()
    scrollToBottom()
  } catch (error) {
    ElMessage.error('发送消息失败')
  } finally {
    isTyping.value = false
  }
}

// 清空对话
const clearMessages = async () => {
  try {
    await ElMessageBox.confirm('确定要清空当前对话吗？', '确认清空', {
      type: 'warning'
    })
    
    messages.value = []
    ElMessage.success('对话已清空')
  } catch {
    // 用户取消
  }
}

// 处理会话操作
const handleSessionAction = async (command: any) => {
  const { action, session } = command
  
  if (action === 'rename') {
    currentRenameSession.value = session
    renameTitle.value = session.title
    showRenameDialog.value = true
  } else if (action === 'delete') {
    try {
      await ElMessageBox.confirm('确定要删除这个会话吗？', '确认删除', {
        type: 'warning'
      })
      
      await http.delete(`/ai/sessions/${session.id}`)
      sessions.value = sessions.value.filter(s => s.id !== session.id)
      
      if (currentSessionId.value === session.id) {
        currentSessionId.value = null
        messages.value = []
      }
      
      ElMessage.success('会话已删除')
    } catch {
      // 用户取消或删除失败
    }
  }
}

// 确认重命名
const confirmRename = async () => {
  if (!renameTitle.value.trim() || !currentRenameSession.value) {
    return
  }

  try {
    await http.put(`/ai/sessions/${currentRenameSession.value.id}`, {
      title: renameTitle.value.trim()
    })
    
    const session = sessions.value.find(s => s.id === currentRenameSession.value!.id)
    if (session) {
      session.title = renameTitle.value.trim()
    }
    
    showRenameDialog.value = false
    ElMessage.success('会话重命名成功')
  } catch (error) {
    ElMessage.error('重命名失败')
  }
}

// 格式化消息内容
const formatMessage = (content: string) => {
  // 简单的Markdown渲染
  return content
    .replace(/\n/g, '<br>')
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
    .replace(/`(.*?)`/g, '<code>$1</code>')
}

// 滚动到底部
const scrollToBottom = () => {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
}

// 监听当前会话变化
watch(currentSessionId, (newId) => {
  if (newId) {
    fetchMessages(newId)
  }
})

// 生命周期
onMounted(() => {
  fetchSessions()
  fetchAIConfigs()
})
</script>

<style scoped>
.ai-chat {
  height: 100%;
}

.chat-container {
  display: flex;
  height: 600px;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  overflow: hidden;
}

.chat-sidebar {
  width: 280px;
  border-right: 1px solid #e4e7ed;
  background: #fafafa;
  display: flex;
  flex-direction: column;
}

.sidebar-header {
  padding: 16px;
  border-bottom: 1px solid #e4e7ed;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.sidebar-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
}

.session-list {
  flex: 1;
  overflow-y: auto;
}

.session-item {
  padding: 12px 16px;
  border-bottom: 1px solid #f0f0f0;
  cursor: pointer;
  position: relative;
  transition: background-color 0.2s;
}

.session-item:hover {
  background-color: #f5f7fa;
}

.session-item.active {
  background-color: #e6f7ff;
  border-right: 3px solid #409eff;
}

.session-title {
  font-weight: 500;
  margin-bottom: 4px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.session-time {
  font-size: 12px;
  color: #909399;
}

.session-menu {
  position: absolute;
  top: 12px;
  right: 12px;
  cursor: pointer;
  opacity: 0;
  transition: opacity 0.2s;
}

.session-item:hover .session-menu {
  opacity: 1;
}

.chat-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: white;
}

.chat-welcome {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  color: #909399;
}

.welcome-icon {
  font-size: 64px;
  margin-bottom: 16px;
  color: #c0c4cc;
}

.chat-content {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.messages-container {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
}

.message-item {
  display: flex;
  margin-bottom: 16px;
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
  margin: 0 8px;
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
  padding: 12px 16px;
  border-radius: 12px;
  line-height: 1.5;
  word-wrap: break-word;
}

.message-item.user .message-text {
  background-color: #409eff;
  color: white;
}

.message-time {
  font-size: 12px;
  color: #c0c4cc;
  margin-top: 4px;
}

.typing-indicator {
  display: flex;
  align-items: center;
  padding: 12px 16px;
  background-color: #f5f7fa;
  border-radius: 12px;
}

.typing-indicator span {
  width: 8px;
  height: 8px;
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
  padding: 16px;
}

.input-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
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

:deep(.el-textarea__inner) {
  resize: none;
}
</style>