<template>
  <div class="ticket-api-test">
    <el-card>
      <template #header>
        <h2>工单API测试</h2>
      </template>
      
      <div class="test-section">
        <h3>1. 创建测试工单</h3>
        <el-button @click="createTestTicket" :loading="loading.create">创建工单</el-button>
        <p v-if="testTicket">测试工单ID: {{ testTicket.id }}, 状态: {{ testTicket.status }}</p>
      </div>

      <div class="test-section" v-if="testTicket">
        <h3>2. 工单状态操作</h3>
        <el-space wrap>
          <el-button 
            v-if="testTicket.status === 'submitted'"
            @click="assignTicket" 
            :loading="loading.assign"
          >
            分配工单
          </el-button>
          
          <el-button 
            v-if="testTicket.status === 'assigned'"
            @click="acceptTicket" 
            :loading="loading.accept"
          >
            接受工单
          </el-button>
          
          <el-button 
            v-if="testTicket.status === 'assigned'"
            @click="rejectTicket" 
            :loading="loading.reject"
          >
            拒绝工单
          </el-button>
          
          <el-button 
            v-if="testTicket.status === 'assigned'"
            @click="reassignTicket" 
            :loading="loading.reassign"
          >
            重新分配
          </el-button>
          
          <el-button 
            v-if="['rejected', 'returned'].includes(testTicket.status)"
            @click="resubmitTicket" 
            :loading="loading.resubmit"
          >
            重新提交
          </el-button>
          
          <el-button 
            v-if="testTicket.status === 'accepted'"
            @click="approveTicket" 
            :loading="loading.approve"
          >
            审批通过
          </el-button>
          
          <el-button 
            v-if="testTicket.status === 'accepted'"
            @click="rejectApproval" 
            :loading="loading.rejectApproval"
            type="danger"
          >
            审批拒绝
          </el-button>
          
          <el-button 
            v-if="testTicket.status === 'approved'"
            @click="startProgress" 
            :loading="loading.progress"
          >
            开始处理
          </el-button>
          
          <el-button 
            v-if="testTicket.status === 'progress'"
            @click="resolveTicket" 
            :loading="loading.resolve"
          >
            解决工单
          </el-button>
          
          <el-button 
            v-if="testTicket.status === 'resolved'"
            @click="closeTicket" 
            :loading="loading.close"
          >
            关闭工单
          </el-button>
          
          <el-button 
            v-if="testTicket.status === 'closed'"
            @click="reopenTicket" 
            :loading="loading.reopen"
          >
            重新打开
          </el-button>
        </el-space>
      </div>

      <div class="test-section">
        <h3>3. API调用日志</h3>
        <el-scrollbar height="300px">
          <div class="log-container">
            <div 
              v-for="(log, index) in apiLogs" 
              :key="index" 
              :class="['log-item', log.type]"
            >
              <span class="log-time">{{ log.time }}</span>
              <span class="log-message">{{ log.message }}</span>
            </div>
          </div>
        </el-scrollbar>
        <el-button @click="clearLogs" size="small">清空日志</el-button>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ticketApi } from '../../api/ticket'
import { useAuthStore } from '../../stores/auth'

const authStore = useAuthStore()
const testTicket = ref<any>(null)
const apiLogs = ref<any[]>([])

const loading = reactive({
  create: false,
  assign: false,
  accept: false,
  reject: false,
  reassign: false,
  resubmit: false,
  approve: false,
  rejectApproval: false,
  progress: false,
  resolve: false,
  close: false,
  reopen: false
})

// 添加日志
const addLog = (message: string, type: 'success' | 'error' | 'info' = 'info') => {
  apiLogs.value.unshift({
    time: new Date().toLocaleTimeString(),
    message,
    type
  })
}

// 创建测试工单
const createTestTicket = async () => {
  loading.create = true
  try {
    addLog('正在创建测试工单...', 'info')
    const response = await ticketApi.createTicket({
      title: '测试工单 - API验证',
      description: '这是一个用于验证API功能的测试工单',
      type: 'bug',
      priority: 'normal'
    })
    
    if (response.success) {
      testTicket.value = response.data
      addLog(`工单创建成功，ID: ${response.data.id}`, 'success')
      ElMessage.success('测试工单创建成功')
    } else {
      addLog('工单创建失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('工单创建失败')
    }
  } catch (error: any) {
    addLog('工单创建异常: ' + error.message, 'error')
    ElMessage.error('工单创建异常')
    console.error('创建工单失败:', error)
  } finally {
    loading.create = false
  }
}

// 分配工单
const assignTicket = async () => {
  loading.assign = true
  try {
    addLog('正在分配工单...', 'info')
    const response = await ticketApi.assignTicket(testTicket.value.id, {
      assignee_id: authStore.user?.id || 1,
      comment: '自动分配给当前用户'
    })
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单分配成功', 'success')
      ElMessage.success('工单分配成功')
    } else {
      addLog('工单分配失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('工单分配失败')
    }
  } catch (error: any) {
    addLog('工单分配异常: ' + error.message, 'error')
    ElMessage.error('工单分配异常')
    console.error('分配工单失败:', error)
  } finally {
    loading.assign = false
  }
}

// 接受工单
const acceptTicket = async () => {
  loading.accept = true
  try {
    addLog('正在接受工单...', 'info')
    const response = await ticketApi.acceptTicket(testTicket.value.id, '自动化测试接受工单')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单接受成功', 'success')
      ElMessage.success('工单接受成功')
    } else {
      addLog('工单接受失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('工单接受失败')
    }
  } catch (error: any) {
    addLog('工单接受异常: ' + error.message, 'error')
    ElMessage.error('工单接受异常')
    console.error('接受工单失败:', error)
  } finally {
    loading.accept = false
  }
}

// 拒绝工单
const rejectTicket = async () => {
  loading.reject = true
  try {
    const reason = await ElMessageBox.prompt('请输入拒绝原因', '拒绝工单', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      inputPattern: /.+/,
      inputErrorMessage: '拒绝原因不能为空'
    })
    
    addLog('正在拒绝工单...', 'info')
    const response = await ticketApi.rejectTicket(testTicket.value.id, reason.value)
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单拒绝成功', 'success')
      ElMessage.success('工单拒绝成功')
    } else {
      addLog('工单拒绝失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('工单拒绝失败')
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      addLog('工单拒绝异常: ' + error.message, 'error')
      ElMessage.error('工单拒绝异常')
      console.error('拒绝工单失败:', error)
    }
  } finally {
    loading.reject = false
  }
}

// 审批工单
const approveTicket = async () => {
  loading.approve = true
  try {
    addLog('正在审批工单...', 'info')
    const response = await ticketApi.updateTicketStatus(testTicket.value.id, 'approved', '自动化测试审批')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单审批成功', 'success')
      ElMessage.success('工单审批成功')
    } else {
      addLog('工单审批失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('工单审批失败')
    }
  } catch (error: any) {
    addLog('工单审批异常: ' + error.message, 'error')
    ElMessage.error('工单审批异常')
    console.error('审批工单失败:', error)
  } finally {
    loading.approve = false
  }
}

// 审批拒绝
const rejectApproval = async () => {
  loading.rejectApproval = true
  try {
    const reason = await ElMessageBox.prompt('请输入拒绝原因', '审批拒绝', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      inputPattern: /.+/,
      inputErrorMessage: '拒绝原因不能为空'
    })
    
    addLog('正在拒绝审批...', 'info')
    const response = await ticketApi.updateTicketStatus(testTicket.value.id, 'rejected', `审批拒绝: ${reason.value}`)
    
    if (response.success) {
      testTicket.value = response.data
      addLog('审批拒绝成功', 'success')
      ElMessage.success('审批拒绝成功')
    } else {
      addLog('审批拒绝失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('审批拒绝失败')
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      addLog('审批拒绝异常: ' + error.message, 'error')
      ElMessage.error('审批拒绝异常')
      console.error('审批拒绝失败:', error)
    }
  } finally {
    loading.rejectApproval = false
  }
}

// 开始处理
const startProgress = async () => {
  loading.progress = true
  try {
    addLog('正在开始处理工单...', 'info')
    const response = await ticketApi.updateTicketStatus(testTicket.value.id, 'progress', '自动化测试开始处理')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单已开始处理', 'success')
      ElMessage.success('工单已开始处理')
    } else {
      addLog('开始处理失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('开始处理失败')
    }
  } catch (error: any) {
    addLog('开始处理异常: ' + error.message, 'error')
    ElMessage.error('开始处理异常')
    console.error('开始处理失败:', error)
  } finally {
    loading.progress = false
  }
}

// 解决工单
const resolveTicket = async () => {
  loading.resolve = true
  try {
    addLog('正在解决工单...', 'info')
    const response = await ticketApi.updateTicketStatus(testTicket.value.id, 'resolved', '自动化测试解决工单')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单已解决', 'success')
      ElMessage.success('工单已解决')
    } else {
      addLog('解决工单失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('解决工单失败')
    }
  } catch (error: any) {
    addLog('解决工单异常: ' + error.message, 'error')
    ElMessage.error('解决工单异常')
    console.error('解决工单失败:', error)
  } finally {
    loading.resolve = false
  }
}

// 关闭工单
const closeTicket = async () => {
  loading.close = true
  try {
    addLog('正在关闭工单...', 'info')
    const response = await ticketApi.updateTicketStatus(testTicket.value.id, 'closed', '自动化测试关闭工单')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单已关闭', 'success')
      ElMessage.success('工单已关闭')
    } else {
      addLog('关闭工单失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('关闭工单失败')
    }
  } catch (error: any) {
    addLog('关闭工单异常: ' + error.message, 'error')
    ElMessage.error('关闭工单异常')
    console.error('关闭工单失败:', error)
  } finally {
    loading.close = false
  }
}

// 重新打开工单
const reopenTicket = async () => {
  loading.reopen = true
  try {
    addLog('正在重新打开工单...', 'info')
    const response = await ticketApi.reopenTicket(testTicket.value.id, '自动化测试重新打开')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单已重新打开', 'success')
      ElMessage.success('工单已重新打开')
    } else {
      addLog('重新打开失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('重新打开失败')
    }
  } catch (error: any) {
    addLog('重新打开异常: ' + error.message, 'error')
    ElMessage.error('重新打开异常')
    console.error('重新打开失败:', error)
  } finally {
    loading.reopen = false
  }
}

// 重新分配工单
const reassignTicket = async () => {
  loading.reassign = true
  try {
    addLog('正在重新分配工单...', 'info')
    const response = await ticketApi.reassignTicket(testTicket.value.id, {
      assignee_id: authStore.user?.id || 1,
      comment: '自动化测试重新分配',
      auto_accept: true  // 重新分配时自动接受，避免流程倒退
    })
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单重新分配成功', 'success')
      ElMessage.success('工单重新分配成功')
    } else {
      addLog('工单重新分配失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('工单重新分配失败')
    }
  } catch (error: any) {
    addLog('工单重新分配异常: ' + error.message, 'error')
    ElMessage.error('工单重新分配异常')
    console.error('重新分配工单失败:', error)
  } finally {
    loading.reassign = false
  }
}

// 重新提交工单
const resubmitTicket = async () => {
  loading.resubmit = true
  try {
    addLog('正在重新提交工单...', 'info')
    const response = await ticketApi.resubmitTicket(testTicket.value.id, '自动化测试重新提交')
    
    if (response.success) {
      testTicket.value = response.data
      addLog('工单重新提交成功', 'success')
      ElMessage.success('工单重新提交成功')
    } else {
      addLog('工单重新提交失败: ' + (response.error || '未知错误'), 'error')
      ElMessage.error('工单重新提交失败')
    }
  } catch (error: any) {
    addLog('工单重新提交异常: ' + error.message, 'error')
    ElMessage.error('工单重新提交异常')
    console.error('重新提交工单失败:', error)
  } finally {
    loading.resubmit = false
  }
}

// 清空日志
const clearLogs = () => {
  apiLogs.value = []
}
</script>

<style scoped>
.ticket-api-test {
  padding: 20px;
}

.test-section {
  margin-bottom: 30px;
  padding: 20px;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
}

.test-section h3 {
  margin-top: 0;
  color: #303133;
}

.log-container {
  background: #f5f7fa;
  padding: 10px;
  border-radius: 4px;
}

.log-item {
  display: block;
  padding: 5px 0;
  border-bottom: 1px solid #e4e7ed;
}

.log-item:last-child {
  border-bottom: none;
}

.log-time {
  color: #909399;
  font-size: 12px;
  margin-right: 10px;
}

.log-message {
  font-size: 14px;
}

.log-item.success .log-message {
  color: #67c23a;
}

.log-item.error .log-message {
  color: #f56c6c;
}

.log-item.info .log-message {
  color: #409eff;
}
</style>