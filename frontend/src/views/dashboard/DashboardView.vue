<template>
  <div class="dashboard-container">
    <div class="dashboard-header">
      <h1>仪表板</h1>
      <p>欢迎使用信息管理系统</p>
    </div>
    
    <div class="dashboard-content">
      <el-row :gutter="20">
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-item">
              <div class="stat-icon">
                <el-icon><Document /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ stats.records }}</div>
                <div class="stat-label">记录总数</div>
              </div>
            </div>
          </el-card>
        </el-col>
        
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-item">
              <div class="stat-icon">
                <el-icon><Folder /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ stats.files }}</div>
                <div class="stat-label">文件总数</div>
              </div>
            </div>
          </el-card>
        </el-col>
        
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-item">
              <div class="stat-icon">
                <el-icon><User /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ stats.users }}</div>
                <div class="stat-label">用户总数</div>
              </div>
            </div>
          </el-card>
        </el-col>
        
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-item">
              <div class="stat-icon">
                <el-icon><TrendCharts /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ stats.todayRecords }}</div>
                <div class="stat-label">今日新增</div>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
      
      <el-row :gutter="20" style="margin-top: 20px;">
        <el-col :span="12">
          <el-card>
            <template #header>
              <span>最近记录</span>
            </template>
            <div class="recent-records">
              <div v-for="record in recentRecords" :key="record.id" class="record-item">
                <div class="record-title">{{ record.title }}</div>
                <div class="record-time">{{ record.createdAt }}</div>
              </div>
            </div>
          </el-card>
        </el-col>
        
        <el-col :span="12">
          <el-card>
            <template #header>
              <span>系统状态</span>
            </template>
            <div class="system-status">
              <div class="status-item">
                <span class="status-label">系统运行时间</span>
                <span class="status-value">{{ systemInfo.uptime }}</span>
              </div>
              <div class="status-item">
                <span class="status-label">数据库状态</span>
                <el-tag :type="systemInfo.dbStatus === 'healthy' ? 'success' : 'danger'">
                  {{ systemInfo.dbStatus === 'healthy' ? '正常' : '异常' }}
                </el-tag>
              </div>
              <div class="status-item">
                <span class="status-label">系统版本</span>
                <span class="status-value">{{ systemInfo.version }}</span>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Document, Folder, User, TrendCharts } from '@element-plus/icons-vue'

const stats = ref({
  records: 0,
  files: 0,
  users: 0,
  todayRecords: 0
})

const recentRecords = ref([
  { id: 1, title: '示例记录1', createdAt: '2025-01-04 10:30' },
  { id: 2, title: '示例记录2', createdAt: '2025-01-04 09:15' },
  { id: 3, title: '示例记录3', createdAt: '2025-01-04 08:45' }
])

const systemInfo = ref({
  uptime: '2天 3小时',
  dbStatus: 'healthy',
  version: 'v1.0.0'
})

onMounted(() => {
  // 模拟加载统计数据
  stats.value = {
    records: 156,
    files: 89,
    users: 12,
    todayRecords: 8
  }
})
</script>

<style scoped>
.dashboard-container {
  padding: 20px;
}

.dashboard-header {
  margin-bottom: 30px;
}

.dashboard-header h1 {
  font-size: 28px;
  color: #303133;
  margin-bottom: 8px;
}

.dashboard-header p {
  color: #606266;
  font-size: 16px;
}

.stat-card {
  height: 120px;
}

.stat-item {
  display: flex;
  align-items: center;
  height: 100%;
}

.stat-icon {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 20px;
}

.stat-icon .el-icon {
  font-size: 24px;
  color: white;
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 32px;
  font-weight: bold;
  color: #303133;
  line-height: 1;
}

.stat-label {
  font-size: 14px;
  color: #909399;
  margin-top: 4px;
}

.recent-records {
  max-height: 300px;
  overflow-y: auto;
}

.record-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #f0f0f0;
}

.record-item:last-child {
  border-bottom: none;
}

.record-title {
  font-size: 14px;
  color: #303133;
}

.record-time {
  font-size: 12px;
  color: #909399;
}

.system-status {
  space-y: 16px;
}

.status-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #f0f0f0;
}

.status-item:last-child {
  border-bottom: none;
}

.status-label {
  font-size: 14px;
  color: #606266;
}

.status-value {
  font-size: 14px;
  color: #303133;
  font-weight: 500;
}
</style>