<template>
  <div class="ai-speech-to-text">
    <!-- 工具栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <h3>AI语音识别</h3>
        <p>将语音转换为文字，支持多种语言和音频格式</p>
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
        <!-- 左侧：录音和上传 -->
        <el-col :span="12">
          <el-card class="input-card">
            <template #header>
              <span>音频输入</span>
            </template>

            <div class="input-methods">
              <!-- 实时录音 -->
              <div class="recording-section">
                <h4>实时录音</h4>
                <div class="recording-controls">
                  <div class="record-button-container">
                    <el-button
                      :type="isRecording ? 'danger' : 'primary'"
                      :icon="isRecording ? 'VideoPause' : 'Microphone'"
                      size="large"
                      circle
                      @click="toggleRecording"
                      :disabled="!selectedConfigId"
                      class="record-button"
                    >
                    </el-button>
                    <div class="record-status">
                      <span v-if="!isRecording">点击开始录音</span>
                      <span v-else class="recording-text">
                        <el-icon class="recording-icon"><Microphone /></el-icon>
                        录音中... {{ recordingTime }}s
                      </span>
                    </div>
                  </div>

                  <div class="recording-settings">
                    <el-form label-width="80px" size="small">
                      <el-form-item label="语言">
                        <el-select v-model="recordingSettings.language" style="width: 100%">
                          <el-option label="中文" value="zh" />
                          <el-option label="英文" value="en" />
                          <el-option label="日文" value="ja" />
                          <el-option label="韩文" value="ko" />
                          <el-option label="自动检测" value="auto" />
                        </el-select>
                      </el-form-item>
                      <el-form-item label="质量">
                        <el-select v-model="recordingSettings.quality" style="width: 100%">
                          <el-option label="标准" value="standard" />
                          <el-option label="高质量" value="high" />
                        </el-select>
                      </el-form-item>
                    </el-form>
                  </div>
                </div>

                <!-- 音频波形显示 -->
                <div v-if="isRecording" class="audio-visualizer">
                  <canvas ref="visualizerCanvas" width="400" height="60"></canvas>
                </div>
              </div>

              <el-divider />

              <!-- 文件上传 -->
              <div class="upload-section">
                <h4>上传音频文件</h4>
                <el-upload
                  ref="uploadRef"
                  :action="uploadAction"
                  :headers="uploadHeaders"
                  :data="uploadData"
                  :before-upload="beforeUpload"
                  :on-success="handleUploadSuccess"
                  :on-error="handleUploadError"
                  :show-file-list="false"
                  drag
                  accept="audio/*"
                >
                  <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
                  <div class="el-upload__text">
                    将音频文件拖到此处，或<em>点击上传</em>
                  </div>
                  <template #tip>
                    <div class="el-upload__tip">
                      支持 MP3、WAV、M4A、FLAC 格式，文件大小不超过 25MB
                    </div>
                  </template>
                </el-upload>

                <div class="upload-settings">
                  <el-form label-width="80px" size="small">
                    <el-form-item label="语言">
                      <el-select v-model="uploadSettings.language" style="width: 100%">
                        <el-option label="中文" value="zh" />
                        <el-option label="英文" value="en" />
                        <el-option label="日文" value="ja" />
                        <el-option label="韩文" value="ko" />
                        <el-option label="自动检测" value="auto" />
                      </el-select>
                    </el-form-item>
                  </el-form>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>

        <!-- 右侧：识别结果 -->
        <el-col :span="12">
          <el-card class="output-card">
            <template #header>
              <div class="card-header">
                <span>识别结果</span>
                <div class="header-actions" v-if="recognitionResult">
                  <el-button size="small" @click="copyResult">
                    <el-icon><DocumentCopy /></el-icon>
                    复制文本
                  </el-button>
                  <el-button size="small" @click="saveAsRecord">
                    <el-icon><Document /></el-icon>
                    保存为记录
                  </el-button>
                  <el-button size="small" @click="exportText">
                    <el-icon><Download /></el-icon>
                    导出文本
                  </el-button>
                </div>
              </div>
            </template>

            <div class="output-section">
              <div v-if="!recognitionResult && !processing" class="empty-state">
                <el-icon class="empty-icon"><Microphone /></el-icon>
                <p>识别结果将在这里显示</p>
              </div>

              <div v-if="processing" class="processing-state">
                <el-icon class="is-loading"><Loading /></el-icon>
                <p>正在识别语音，请稍候...</p>
                <div class="progress-info">
                  <el-progress :percentage="processingProgress" />
                  <span>预计剩余时间: {{ estimatedTime }}秒</span>
                </div>
              </div>

              <div v-if="recognitionResult" class="result-content">
                <div class="result-text">
                  <el-input
                    v-model="recognitionResult.text"
                    type="textarea"
                    :rows="12"
                    placeholder="识别结果..."
                  />
                </div>

                <div class="result-info">
                  <el-divider />
                  <div class="info-grid">
                    <div class="info-item">
                      <span class="info-label">识别语言</span>
                      <span class="info-value">{{ getLanguageName(recognitionResult.language) }}</span>
                    </div>
                    <div class="info-item">
                      <span class="info-label">置信度</span>
                      <span class="info-value">{{ Math.round(recognitionResult.confidence * 100) }}%</span>
                    </div>
                    <div class="info-item">
                      <span class="info-label">音频时长</span>
                      <span class="info-value">{{ recognitionResult.duration }}秒</span>
                    </div>
                    <div class="info-item">
                      <span class="info-label">处理时间</span>
                      <span class="info-value">{{ recognitionResult.processingTime }}秒</span>
                    </div>
                  </div>
                </div>

                <!-- 时间轴显示 -->
                <div v-if="recognitionResult.segments" class="segments-section">
                  <el-divider />
                  <h4>时间轴</h4>
                  <div class="segments-list">
                    <div
                      v-for="(segment, index) in recognitionResult.segments"
                      :key="index"
                      class="segment-item"
                    >
                      <div class="segment-time">
                        {{ formatTime(segment.start) }} - {{ formatTime(segment.end) }}
                      </div>
                      <div class="segment-text">{{ segment.text }}</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- 历史记录 -->
    <el-card class="history-card" v-if="recognitionHistory.length > 0">
      <template #header>
        <div class="card-header">
          <span>识别历史</span>
          <el-button size="small" @click="clearHistory">
            <el-icon><Delete /></el-icon>
            清空历史
          </el-button>
        </div>
      </template>

      <el-table :data="recognitionHistory" style="width: 100%">
        <el-table-column prop="created_at" label="时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column prop="language" label="语言" width="100">
          <template #default="{ row }">
            {{ getLanguageName(row.language) }}
          </template>
        </el-table-column>
        <el-table-column prop="duration" label="时长" width="100">
          <template #default="{ row }">
            {{ row.duration }}秒
          </template>
        </el-table-column>
        <el-table-column prop="text" label="识别结果" min-width="200">
          <template #default="{ row }">
            <div class="text-preview">
              {{ row.text.substring(0, 100) }}{{ row.text.length > 100 ? '...' : '' }}
            </div>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150">
          <template #default="{ row }">
            <el-button size="small" @click="loadHistoryItem(row)">查看</el-button>
            <el-button size="small" type="danger" @click="deleteHistoryItem(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

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
import { ref, reactive, onMounted, onUnmounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  Microphone,
  VideoPause,
  UploadFilled,
  DocumentCopy,
  Document,
  Download,
  Loading,
  Delete
} from '@element-plus/icons-vue'
import { http } from '@/utils/http'
import { formatTime, formatDateTime } from '@/utils/format'

// 响应式数据
const aiConfigs = ref([])
const selectedConfigId = ref(null)
const isRecording = ref(false)
const recordingTime = ref(0)
const processing = ref(false)
const processingProgress = ref(0)
const estimatedTime = ref(0)
const recognitionResult = ref(null)
const recognitionHistory = ref([])
const recordTypes = ref([])

// 对话框
const showSaveDialog = ref(false)

// 录音相关
const mediaRecorder = ref(null)
const audioChunks = ref([])
const recordingTimer = ref(null)
const visualizerCanvas = ref(null)
const audioContext = ref(null)
const analyser = ref(null)

// 设置
const recordingSettings = reactive({
  language: 'zh',
  quality: 'standard'
})

const uploadSettings = reactive({
  language: 'zh'
})

const saveForm = reactive({
  title: '',
  typeId: null
})

// 上传配置
const uploadAction = '/api/v1/ai/speech-to-text'
const uploadHeaders = {
  'Authorization': `Bearer ${localStorage.getItem('token')}`
}
const uploadData = reactive({
  config_id: null,
  language: 'zh'
})

// 获取AI配置
const fetchAIConfigs = async () => {
  try {
    const response = await http.get('/ai/config')
    aiConfigs.value = response.data.configs || []
    if (aiConfigs.value.length > 0) {
      selectedConfigId.value = aiConfigs.value[0].id
      uploadData.config_id = aiConfigs.value[0].id
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

// 切换录音状态
const toggleRecording = async () => {
  if (isRecording.value) {
    stopRecording()
  } else {
    await startRecording()
  }
}

// 开始录音
const startRecording = async () => {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    
    mediaRecorder.value = new MediaRecorder(stream)
    audioChunks.value = []
    
    mediaRecorder.value.ondataavailable = (event) => {
      audioChunks.value.push(event.data)
    }
    
    mediaRecorder.value.onstop = async () => {
      const audioBlob = new Blob(audioChunks.value, { type: 'audio/wav' })
      await processAudioBlob(audioBlob)
    }
    
    mediaRecorder.value.start()
    isRecording.value = true
    recordingTime.value = 0
    
    // 开始计时
    recordingTimer.value = setInterval(() => {
      recordingTime.value++
    }, 1000)
    
    // 初始化音频可视化
    initAudioVisualizer(stream)
    
    ElMessage.success('开始录音')
  } catch (error) {
    ElMessage.error('无法访问麦克风')
  }
}

// 停止录音
const stopRecording = () => {
  if (mediaRecorder.value && isRecording.value) {
    mediaRecorder.value.stop()
    isRecording.value = false
    
    if (recordingTimer.value) {
      clearInterval(recordingTimer.value)
    }
    
    // 停止音频流
    const tracks = mediaRecorder.value.stream.getTracks()
    tracks.forEach(track => track.stop())
    
    ElMessage.success('录音结束')
  }
}

// 初始化音频可视化
const initAudioVisualizer = (stream) => {
  if (!visualizerCanvas.value) return
  
  audioContext.value = new AudioContext()
  analyser.value = audioContext.value.createAnalyser()
  const source = audioContext.value.createMediaStreamSource(stream)
  source.connect(analyser.value)
  
  analyser.value.fftSize = 256
  const bufferLength = analyser.value.frequencyBinCount
  const dataArray = new Uint8Array(bufferLength)
  
  const canvas = visualizerCanvas.value
  const ctx = canvas.getContext('2d')
  
  const draw = () => {
    if (!isRecording.value) return
    
    requestAnimationFrame(draw)
    
    analyser.value.getByteFrequencyData(dataArray)
    
    ctx.fillStyle = '#f5f7fa'
    ctx.fillRect(0, 0, canvas.width, canvas.height)
    
    const barWidth = (canvas.width / bufferLength) * 2.5
    let barHeight
    let x = 0
    
    for (let i = 0; i < bufferLength; i++) {
      barHeight = (dataArray[i] / 255) * canvas.height
      
      ctx.fillStyle = `rgb(64, 158, 255)`
      ctx.fillRect(x, canvas.height - barHeight, barWidth, barHeight)
      
      x += barWidth + 1
    }
  }
  
  draw()
}

// 处理音频Blob
const processAudioBlob = async (audioBlob) => {
  processing.value = true
  processingProgress.value = 0
  
  // 模拟进度
  const progressInterval = setInterval(() => {
    if (processingProgress.value < 90) {
      processingProgress.value += Math.random() * 10
    }
  }, 500)
  
  try {
    const formData = new FormData()
    formData.append('audio', audioBlob, 'recording.wav')
    formData.append('config_id', selectedConfigId.value)
    formData.append('language', recordingSettings.language)
    
    const response = await http.post('/ai/speech-to-text', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
    
    processingProgress.value = 100
    clearInterval(progressInterval)
    
    recognitionResult.value = response.data
    
    // 添加到历史记录
    recognitionHistory.value.unshift({
      id: Date.now(),
      ...response.data,
      created_at: new Date().toISOString()
    })
    
    ElMessage.success('语音识别完成')
  } catch (error) {
    clearInterval(progressInterval)
    ElMessage.error('语音识别失败')
  } finally {
    processing.value = false
  }
}

// 文件上传前检查
const beforeUpload = (file) => {
  const isAudio = file.type.startsWith('audio/')
  const isLt25M = file.size / 1024 / 1024 < 25
  
  if (!isAudio) {
    ElMessage.error('只能上传音频文件')
    return false
  }
  
  if (!isLt25M) {
    ElMessage.error('文件大小不能超过 25MB')
    return false
  }
  
  uploadData.config_id = selectedConfigId.value
  uploadData.language = uploadSettings.language
  
  processing.value = true
  return true
}

// 上传成功处理
const handleUploadSuccess = (response) => {
  processing.value = false
  recognitionResult.value = response.data
  
  // 添加到历史记录
  recognitionHistory.value.unshift({
    id: Date.now(),
    ...response.data,
    created_at: new Date().toISOString()
  })
  
  ElMessage.success('文件上传并识别成功')
}

// 上传失败处理
const handleUploadError = () => {
  processing.value = false
  ElMessage.error('文件上传失败')
}

// 获取语言名称
const getLanguageName = (code) => {
  const languageMap = {
    zh: '中文',
    en: '英文',
    ja: '日文',
    ko: '韩文',
    auto: '自动检测'
  }
  return languageMap[code] || code
}

// 复制结果
const copyResult = async () => {
  try {
    await navigator.clipboard.writeText(recognitionResult.value.text)
    ElMessage.success('文本已复制到剪贴板')
  } catch (error) {
    ElMessage.error('复制失败')
  }
}

// 保存为记录
const saveAsRecord = () => {
  saveForm.title = `语音识别结果 - ${formatDateTime(new Date())}`
  showSaveDialog.value = true
}

// 确认保存
const confirmSave = async () => {
  try {
    await http.post('/records', {
      title: saveForm.title,
      content: recognitionResult.value.text,
      type_id: saveForm.typeId
    })
    
    ElMessage.success('记录保存成功')
    showSaveDialog.value = false
  } catch (error) {
    ElMessage.error('保存记录失败')
  }
}

// 导出文本
const exportText = () => {
  const blob = new Blob([recognitionResult.value.text], { type: 'text/plain' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `语音识别结果_${Date.now()}.txt`
  a.click()
  URL.revokeObjectURL(url)
}

// 加载历史项目
const loadHistoryItem = (item) => {
  recognitionResult.value = item
}

// 删除历史项目
const deleteHistoryItem = (item) => {
  const index = recognitionHistory.value.findIndex(h => h.id === item.id)
  if (index > -1) {
    recognitionHistory.value.splice(index, 1)
    ElMessage.success('历史记录已删除')
  }
}

// 清空历史
const clearHistory = () => {
  recognitionHistory.value = []
  ElMessage.success('历史记录已清空')
}

// 生命周期
onMounted(() => {
  fetchAIConfigs()
  fetchRecordTypes()
})

onUnmounted(() => {
  if (isRecording.value) {
    stopRecording()
  }
  if (recordingTimer.value) {
    clearInterval(recordingTimer.value)
  }
})
</script>

<style scoped>
.ai-speech-to-text {
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

.input-methods h4 {
  margin: 0 0 16px 0;
  font-size: 16px;
  font-weight: 600;
}

.recording-controls {
  display: flex;
  gap: 20px;
  align-items: flex-start;
}

.record-button-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

.record-button {
  width: 80px;
  height: 80px;
  font-size: 24px;
}

.record-status {
  text-align: center;
  font-size: 14px;
}

.recording-text {
  display: flex;
  align-items: center;
  gap: 4px;
  color: #f56c6c;
}

.recording-icon {
  animation: pulse 1s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.recording-settings {
  flex: 1;
}

.audio-visualizer {
  margin-top: 16px;
  display: flex;
  justify-content: center;
}

.audio-visualizer canvas {
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  background: #f5f7fa;
}

.upload-section {
  margin-top: 20px;
}

.upload-settings {
  margin-top: 16px;
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

.output-section {
  min-height: 400px;
}

.empty-state,
.processing-state {
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

.processing-state .el-icon {
  font-size: 32px;
  margin-bottom: 16px;
  color: #409eff;
}

.progress-info {
  width: 100%;
  max-width: 300px;
  margin-top: 16px;
}

.result-content {
  height: 100%;
}

.result-text {
  margin-bottom: 16px;
}

.result-info {
  margin-top: 16px;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.info-label {
  font-size: 14px;
  color: #606266;
}

.info-value {
  font-weight: 600;
}

.segments-section h4 {
  margin: 16px 0 8px 0;
  font-size: 14px;
  font-weight: 600;
}

.segments-list {
  max-height: 200px;
  overflow-y: auto;
}

.segment-item {
  display: flex;
  gap: 12px;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.segment-time {
  flex-shrink: 0;
  width: 120px;
  font-size: 12px;
  color: #909399;
  font-family: monospace;
}

.segment-text {
  flex: 1;
  font-size: 14px;
  line-height: 1.4;
}

.history-card {
  margin-top: 20px;
}

.text-preview {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

:deep(.el-upload-dragger) {
  width: 100%;
}

:deep(.el-progress-bar__outer) {
  background-color: #f0f2f5;
}
</style>