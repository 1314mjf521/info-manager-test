<template>
  <div class="login-container">
    <div class="login-card">
      <div class="login-header">
        <h2>信息管理系统</h2>
        <p>欢迎登录</p>
      </div>
      
      <el-form
        ref="loginFormRef"
        :model="loginForm"
        class="login-form"
      >
        <el-form-item>
          <el-input
            v-model="loginForm.username"
            placeholder="请输入用户名"
            size="large"
            prefix-icon="User"
            clearable
          />
        </el-form-item>
        
        <el-form-item>
          <el-input
            v-model="loginForm.password"
            type="password"
            placeholder="请输入密码"
            size="large"
            prefix-icon="Lock"
            show-password
            clearable
          />
        </el-form-item>
        
        <el-form-item>
          <el-button
            type="primary"
            size="large"
            class="login-btn"
            @click="handleLogin"
          >
            登录
          </el-button>
        </el-form-item>
        
        <div class="login-footer">
          <router-link to="/register">还没有账号？立即注册</router-link>
        </div>
      </el-form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import { API_CONFIG, API_ENDPOINTS } from '@/config/api'

const router = useRouter()
const authStore = useAuthStore()

const loginFormRef = ref()
const loginForm = reactive({
  username: '',
  password: ''
})

const handleLogin = async () => {
  if (!loginForm.username || !loginForm.password) {
    ElMessage.warning('请输入用户名和密码')
    return
  }
  
  console.log('=== 登录调试信息 ===')
  console.log('用户名:', loginForm.username)
  console.log('密码长度:', loginForm.password.length)
  console.log('API配置:', API_CONFIG)
  console.log('完整API地址:', `${API_CONFIG.BASE_URL}${API_CONFIG.VERSION}${API_ENDPOINTS.AUTH.LOGIN}`)
  
  try {
    console.log('开始调用authStore.login...')
    await authStore.login({
      username: loginForm.username,
      password: loginForm.password
    })
    
    console.log('authStore.login调用成功')
    console.log('认证状态:', authStore.isAuthenticated)
    console.log('token存在:', !!authStore.token)
    console.log('用户信息存在:', !!authStore.user)
    
    // 等待一个tick确保状态更新完成
    await new Promise(resolve => setTimeout(resolve, 100))
    
    // 验证登录是否真正成功
    if (authStore.isAuthenticated && authStore.token && authStore.user) {
      ElMessage.success('登录成功')
      console.log('登录验证通过，准备跳转...')
      
      // 获取重定向目标，默认为首页
      const redirect = router.currentRoute.value.query.redirect as string || '/'
      console.log('跳转目标:', redirect)
      
      // 使用nextTick确保DOM更新完成后再跳转
      await router.push(redirect)
      console.log('跳转完成')
    } else {
      console.error('登录状态验证失败')
      console.error('isAuthenticated:', authStore.isAuthenticated)
      console.error('token存在:', !!authStore.token)
      console.error('user存在:', !!authStore.user)
      ElMessage.error('登录状态异常，请重试')
    }
  } catch (error: any) {
    console.error('=== 登录错误详情 ===')
    console.error('错误对象:', error)
    console.error('错误消息:', error.message)
    console.error('错误响应:', error.response?.data)
    console.error('错误状态码:', error.response?.status)
    console.error('网络错误:', error.code)
    
    // 显示具体的错误信息
    let errorMessage = '登录失败，请检查用户名和密码'
    
    if (error.code === 'ECONNREFUSED' || error.message?.includes('ECONNREFUSED')) {
      errorMessage = '无法连接到服务器，请确认后端服务已启动'
    } else if (error.code === 'NETWORK_ERROR' || error.message?.includes('Network Error')) {
      errorMessage = '网络连接失败，请检查网络连接'
    } else if (error.response?.status === 400) {
      errorMessage = '用户名或密码错误'
    } else if (error.response?.status === 401) {
      errorMessage = '认证失败，请检查登录信息'
    } else if (error.response?.status === 403) {
      errorMessage = '账户被禁用，请联系管理员'
    } else if (error.response?.status >= 500) {
      errorMessage = '服务器错误，请稍后重试'
    } else if (error.response?.data?.message) {
      errorMessage = error.response.data.message
    } else if (error.response?.data?.error) {
      errorMessage = error.response.data.error
    }
    
    ElMessage.error(errorMessage)
  }
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.login-card {
  width: 400px;
  padding: 40px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
}

.login-header {
  text-align: center;
  margin-bottom: 30px;
}

.login-header h2 {
  color: #303133;
  margin-bottom: 8px;
  font-size: 24px;
  font-weight: 600;
}

.login-header p {
  color: #909399;
  font-size: 14px;
}

.login-btn {
  width: 100%;
  margin-top: 10px;
}

.login-footer {
  text-align: center;
  margin-top: 20px;
}

.login-footer a {
  color: #409eff;
  text-decoration: none;
  font-size: 14px;
}
</style>