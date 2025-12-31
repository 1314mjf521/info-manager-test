<template>
  <div class="ticket-test">
    <h1>工单系统测试页面</h1>
    
    <el-card>
      <h3>基础信息</h3>
      <p>认证状态: {{ authStore.isAuthenticated ? '已登录' : '未登录' }}</p>
      <p>用户信息: {{ authStore.user?.username || '无' }}</p>
      <p>用户角色: {{ authStore.userRoles.join(', ') || '无' }}</p>
    </el-card>

    <el-card style="margin-top: 20px;">
      <h3>权限测试</h3>
      <p>查看工单权限: {{ authStore.hasPermission('ticket', 'view') ? '有' : '无' }}</p>
      <p>创建工单权限: {{ authStore.hasPermission('ticket', 'create') ? '有' : '无' }}</p>
      <p>编辑工单权限: {{ authStore.hasPermission('ticket', 'edit') ? '有' : '无' }}</p>
      <p>分配工单权限: {{ authStore.hasPermission('ticket', 'assign') ? '有' : '无' }}</p>
    </el-card>

    <el-card style="margin-top: 20px;">
      <h3>API测试</h3>
      <el-button @click="testTicketAPI" :loading="testing">测试工单API</el-button>
      <div v-if="apiResult" style="margin-top: 10px;">
        <h4>API响应:</h4>
        <pre>{{ JSON.stringify(apiResult, null, 2) }}</pre>
      </div>
      <div v-if="apiError" style="margin-top: 10px; color: red;">
        <h4>API错误:</h4>
        <pre>{{ apiError }}</pre>
      </div>
    </el-card>

    <el-card style="margin-top: 20px;">
      <h3>导航测试</h3>
      <el-button @click="goToTicketList">前往工单列表</el-button>
      <el-button @click="goToTicketCreate">前往创建工单</el-button>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import { ticketApi } from '@/api/ticket'

const router = useRouter()
const authStore = useAuthStore()

const testing = ref(false)
const apiResult = ref(null)
const apiError = ref('')

const testTicketAPI = async () => {
  testing.value = true
  apiResult.value = null
  apiError.value = ''
  
  try {
    const response = await ticketApi.getTickets({ page: 1, size: 5 })
    apiResult.value = response
    ElMessage.success('API测试成功')
  } catch (error: any) {
    apiError.value = error.message || '未知错误'
    ElMessage.error('API测试失败')
  } finally {
    testing.value = false
  }
}

const goToTicketList = () => {
  router.push('/tickets')
}

const goToTicketCreate = () => {
  router.push('/tickets/create')
}
</script>

<style scoped>
.ticket-test {
  padding: 20px;
  max-width: 800px;
  margin: 0 auto;
}

pre {
  background: #f5f5f5;
  padding: 10px;
  border-radius: 4px;
  overflow-x: auto;
  max-height: 300px;
}
</style>