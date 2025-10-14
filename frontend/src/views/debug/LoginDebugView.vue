<template>
  <div class="debug-container">
    <div class="debug-card">
      <h2>登录跳转调试页面</h2>
      
      <el-divider content-position="left">认证状态</el-divider>
      <div class="debug-section">
        <p><strong>认证状态:</strong> {{ authStore.isAuthenticated ? '已认证' : '未认证' }}</p>
        <p><strong>Token存在:</strong> {{ !!authStore.token }}</p>
        <p><strong>用户信息:</strong> {{ authStore.user ? authStore.user.username : '无' }}</p>
        <p><strong>当前路由:</strong> {{ $route.path }}</p>
      </div>
      
      <el-divider content-position="left">localStorage状态</el-divider>
      <div class="debug-section">
        <p><strong>localStorage token:</strong> {{ !!localStorage.getItem('token') }}</p>
        <p><strong>localStorage user:</strong> {{ !!localStorage.getItem('user') }}</p>
      </div>
      
      <el-divider content-position="left">测试操作</el-divider>
      <div class="debug-section">
        <el-button @click="testLogin" type="primary">测试登录</el-button>
        <el-button @click="testLogout" type="danger">测试登出</el-button>
        <el-button @click="testRedirect" type="success">测试跳转</el-button>
        <el-button @click="clearStorage" type="warning">清除存储</el-button>
      </div>
      
      <el-divider content-position="left">调试日志</el-divider>
      <div class="debug-logs">
        <div v-for="(log, index) in debugLogs" :key="index" class="log-item">
          <span class="log-time">{{ log.time }}</span>
          <span :class="['log-level', log.level]">{{ log.level }}</span>
          <span class="log-message">{{ log.message }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()
const debugLogs = ref<Array<{time: string, level: string, message: string}>>([])

const addLog = (level: string, message: string) => {
  debugLogs.value.unshift({
    time: new Date().toLocaleTimeString(),
    level,
    message
  })
  if (debugLogs.value.length > 50) {
    debugLogs.value = debugLogs.value.slice(0, 50)
  }
}

const testLogin = async () => {
  addLog('INFO', '开始测试登录...')
  try {
    await authStore.login({
      username: 'admin',
      password: 'admin123'
    })
    addLog('SUCCESS', '登录成功')
    ElMessage.success('登录成功')
  } catch (error: any) {
    addLog('ERROR', `登录失败: ${error.message}`)
    ElMessage.error('登录失败')
  }
}

const testLogout = async () => {
  addLog('INFO', '开始测试登出...')
  try {
    await authStore.logout()
    addLog('SUCCESS', '登出成功')
    ElMessage.success('登出成功')
  } catch (error: any) {
    addLog('ERROR', `登出失败: ${error.message}`)
  }
}

const testRedirect = () => {
  addLog('INFO', '测试跳转到首页...')
  router.push('/')
}

const clearStorage = () => {
  localStorage.clear()
  addLog('INFO', 'localStorage已清除')
  ElMessage.info('存储已清除')
}

onMounted(() => {
  addLog('INFO', '调试页面已加载')
})
</script>

<style scoped>
.debug-container {
  padding: 20px;
  max-width: 800px;
  margin: 0 auto;
}

.debug-card {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.debug-section {
  margin: 10px 0;
}

.debug-section p {
  margin: 5px 0;
  font-family: monospace;
}

.debug-logs {
  max-height: 300px;
  overflow-y: auto;
  background: #f5f5f5;
  padding: 10px;
  border-radius: 4px;
  font-family: monospace;
  font-size: 12px;
}

.log-item {
  display: flex;
  margin-bottom: 5px;
  align-items: center;
}

.log-time {
  color: #666;
  margin-right: 10px;
  min-width: 80px;
}

.log-level {
  margin-right: 10px;
  padding: 2px 6px;
  border-radius: 3px;
  font-weight: bold;
  min-width: 60px;
  text-align: center;
}

.log-level.INFO {
  background: #e1f5fe;
  color: #0277bd;
}

.log-level.SUCCESS {
  background: #e8f5e8;
  color: #2e7d32;
}

.log-level.ERROR {
  background: #ffebee;
  color: #c62828;
}

.log-message {
  flex: 1;
}
</style>