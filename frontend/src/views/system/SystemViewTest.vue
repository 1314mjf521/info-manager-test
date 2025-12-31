<template>
  <div class="system-management">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>系统管理测试</span>
          <div class="header-actions">
            <el-button @click="testFunction" :loading="loading">
              <el-icon><Refresh /></el-icon>
              测试
            </el-button>
          </div>
        </div>
      </template>

      <div class="test-content">
        <p>系统管理页面测试</p>
        <p>状态: {{ status }}</p>
        <p>计数: {{ count }}</p>
        
        <el-button @click="increment" type="primary">增加计数</el-button>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh } from '@element-plus/icons-vue'

// 响应式数据
const loading = ref(false)
const status = ref('正常')
const count = ref(0)

// 测试方法
const testFunction = async () => {
  loading.value = true
  try {
    await new Promise(resolve => setTimeout(resolve, 1000))
    status.value = '测试完成'
    ElMessage.success('测试成功')
  } catch (error) {
    ElMessage.error('测试失败')
  } finally {
    loading.value = false
  }
}

const increment = () => {
  count.value++
}
</script>

<style scoped>
.system-management {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.test-content {
  padding: 20px;
}

.test-content p {
  margin: 10px 0;
}
</style>