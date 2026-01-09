<template>
  <div class="assignment-rules">
    <div class="page-header">
      <h1>工单自动分配规则</h1>
      <el-button type="primary" @click="saveRules" :loading="saving">
        <el-icon><Check /></el-icon>
        保存规则
      </el-button>
    </div>

    <el-card>
      <template #header>
        <div class="card-header">
          <span>分配规则配置</span>
          <el-text type="info">根据工单类型自动分配给相应的处理人员</el-text>
        </div>
      </template>

      <div v-loading="loading">
        <el-form :model="rules" label-width="120px">
          <div v-for="(rule, type) in rules" :key="type" class="rule-item">
            <el-divider :content-position="left">{{ getTypeLabel(type) }}</el-divider>
            
            <el-row :gutter="20">
              <el-col :span="8">
                <el-form-item label="分配角色">
                  <el-input v-model="rule.role" placeholder="输入角色名称" />
                </el-form-item>
              </el-col>
              <el-col :span="8">
                <el-form-item label="处理人员">
                  <el-select v-model="rule.assignee_id" placeholder="选择处理人员" filterable>
                    <el-option 
                      v-for="user in users" 
                      :key="user.id" 
                      :label="user.username" 
                      :value="user.id"
                    />
                  </el-select>
                </el-form-item>
              </el-col>
              <el-col :span="8">
                <el-form-item label="当前分配">
                  <el-tag type="info">{{ rule.assignee_name || '未设置' }}</el-tag>
                </el-form-item>
              </el-col>
            </el-row>
          </div>
        </el-form>
      </div>
    </el-card>

    <el-card style="margin-top: 20px;">
      <template #header>
        <span>分配规则说明</span>
      </template>
      
      <el-descriptions :column="1" border>
        <el-descriptions-item label="故障报告">自动分配给开发人员处理</el-descriptions-item>
        <el-descriptions-item label="功能请求">自动分配给产品经理评估</el-descriptions-item>
        <el-descriptions-item label="技术支持">自动分配给技术支持人员</el-descriptions-item>
        <el-descriptions-item label="变更请求">自动分配给系统管理员审核</el-descriptions-item>
        <el-descriptions-item label="自定义请求">自动分配给系统管理员处理</el-descriptions-item>
      </el-descriptions>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Check } from '@element-plus/icons-vue'
import { ticketApi } from '../../api/ticket'
import { userApi } from '../../api/user'

const loading = ref(false)
const saving = ref(false)
const users = ref([])
const rules = reactive({})

const getTypeLabel = (type: string) => {
  const typeMap: Record<string, string> = {
    bug: '故障报告',
    feature: '功能请求',
    support: '技术支持',
    change: '变更请求',
    custom: '自定义请求'
  }
  return typeMap[type] || type
}

const loadRules = async () => {
  loading.value = true
  try {
    const response = await ticketApi.getAssignmentRules()
    Object.assign(rules, response.data)
  } catch (error) {
    ElMessage.error('加载分配规则失败')
  } finally {
    loading.value = false
  }
}

const loadUsers = async () => {
  try {
    const response = await userApi.getUsers({ page: 1, size: 1000 })
    users.value = response.data.items || []
  } catch (error) {
    console.error('加载用户列表失败:', error)
  }
}

const saveRules = async () => {
  saving.value = true
  try {
    await ticketApi.updateAssignmentRules(rules)
    ElMessage.success('分配规则保存成功')
    loadRules() // 重新加载以获取最新数据
  } catch (error) {
    ElMessage.error('保存分配规则失败')
  } finally {
    saving.value = false
  }
}

onMounted(() => {
  loadRules()
  loadUsers()
})
</script>

<style scoped>
.assignment-rules {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.page-header h1 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.rule-item {
  margin-bottom: 20px;
}

.rule-item:last-child {
  margin-bottom: 0;
}
</style>
