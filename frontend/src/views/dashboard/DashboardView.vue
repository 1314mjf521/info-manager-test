<template>
  <div class="dashboard-container">
    <div class="dashboard-header">
      <div class="header-content">
        <div>
          <h1>仪表板</h1>
          <p>欢迎使用信息管理系统</p>
        </div>
        <div class="header-actions">
          <el-button 
            :icon="RefreshRight" 
            :loading="loading" 
            @click="refreshData"
            type="primary"
            size="small"
          >
            刷新数据
          </el-button>
        </div>
      </div>
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
                <div class="stat-value">{{ stats.today_records }}</div>
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
              <div v-if="loading" class="loading-text">加载中...</div>
              <div v-else-if="recentRecords.length === 0" class="empty-text">暂无记录</div>
              <div v-else v-for="record in recentRecords" :key="record.id" class="record-item">
                <div class="record-info">
                  <div class="record-title">{{ record.title }}</div>
                  <div class="record-meta">
                    <span class="record-type">{{ record.type }}</span>
                    <span class="record-creator">{{ record.creator }}</span>
                  </div>
                </div>
                <div class="record-time">{{ record.created_at }}</div>
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
                <el-tag :type="systemInfo.db_status === 'healthy' ? 'success' : 'danger'">
                  {{ systemInfo.db_status === 'healthy' ? '正常' : '异常' }}
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
      
      <!-- 刷新信息 -->
      <div class="refresh-info" v-if="lastRefreshTime">
        <span class="refresh-text">最后更新时间: {{ lastRefreshTime }}</span>
        <span class="auto-refresh-text">• 自动刷新: 30秒</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onActivated, onBeforeUnmount } from 'vue'
import { Document, Folder, User, TrendCharts, RefreshRight } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { dashboardApi, type DashboardStats, type RecentRecord, type SystemInfo } from '../../utils/api/dashboard'
import { useEventBus } from '../../utils/eventBus'

const loading = ref(false)
const autoRefreshTimer = ref<NodeJS.Timeout | null>(null)
const lastRefreshTime = ref<string>('')
const { on, off, emit } = useEventBus()

const stats = ref<DashboardStats>({
  records: 0,
  files: 0,
  users: 0,
  today_records: 0
})

const recentRecords = ref<RecentRecord[]>([])

const systemInfo = ref<SystemInfo>({
  uptime: '加载中...',
  db_status: 'unknown',
  version: '加载中...'
})

// 加载仪表盘数据
const loadDashboardData = async (showMessage = false) => {
  loading.value = true
  try {
    // 并行加载所有数据
    const [statsData, recordsData, systemData] = await Promise.all([
      dashboardApi.getStats(),
      dashboardApi.getRecentRecords(),
      dashboardApi.getSystemInfo()
    ])

    stats.value = statsData
    recentRecords.value = recordsData
    systemInfo.value = systemData
    lastRefreshTime.value = new Date().toLocaleTimeString()
    
    if (showMessage) {
      ElMessage.success('数据已刷新')
    }
  } catch (error) {
    console.error('加载仪表盘数据失败:', error)
    ElMessage.error('加载仪表盘数据失败')
  } finally {
    loading.value = false
  }
}

// 仅刷新系统信息（用于定时更新）
const refreshSystemInfo = async () => {
  try {
    const systemData = await dashboardApi.getSystemInfo()
    systemInfo.value = systemData
  } catch (error) {
    console.error('刷新系统信息失败:', error)
  }
}

// 手动刷新数据
const refreshData = () => {
  loadDashboardData(true)
}

// 启动自动刷新
const startAutoRefresh = () => {
  // 每30秒自动刷新统计数据
  autoRefreshTimer.value = setInterval(() => {
    loadDashboardData()
  }, 30000)
  
  // 每10秒刷新系统信息（更频繁，因为系统状态变化较快）
  setInterval(() => {
    refreshSystemInfo()
  }, 10000)
}

// 停止自动刷新
const stopAutoRefresh = () => {
  if (autoRefreshTimer.value) {
    clearInterval(autoRefreshTimer.value)
    autoRefreshTimer.value = null
  }
}

// 设置事件监听器
const setupEventListeners = () => {
  // 监听数据变化事件，自动刷新仪表盘
  on('record:created', () => loadDashboardData())
  on('record:updated', () => loadDashboardData())
  on('record:deleted', () => loadDashboardData())
  on('file:uploaded', () => loadDashboardData())
  on('file:deleted', () => loadDashboardData())
  on('user:created', () => loadDashboardData())
  on('user:updated', () => loadDashboardData())
  on('user:deleted', () => loadDashboardData())
  on('dashboard:refresh', () => loadDashboardData(true))
}

// 移除事件监听器
const removeEventListeners = () => {
  off('record:created', loadDashboardData)
  off('record:updated', loadDashboardData)
  off('record:deleted', loadDashboardData)
  off('file:uploaded', loadDashboardData)
  off('file:deleted', loadDashboardData)
  off('user:created', loadDashboardData)
  off('user:updated', loadDashboardData)
  off('user:deleted', loadDashboardData)
  off('dashboard:refresh', refreshData)
}

// 组件挂载时加载数据并启动自动刷新
onMounted(() => {
  loadDashboardData()
  startAutoRefresh()
  setupEventListeners()
})

// 当组件被激活时（从其他页面返回）刷新数据
onActivated(() => {
  loadDashboardData()
  if (!autoRefreshTimer.value) {
    startAutoRefresh()
  }
})

// 组件卸载时清理定时器和事件监听器
onBeforeUnmount(() => {
  stopAutoRefresh()
  removeEventListeners()
})
</script>

<style scoped>
.dashboard-container {
  padding: 20px;
}

.dashboard-header {
  margin-bottom: 30px;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
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

.header-actions {
  display: flex;
  gap: 12px;
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

.record-info {
  flex: 1;
}

.record-title {
  font-size: 14px;
  color: #303133;
  margin-bottom: 4px;
}

.record-meta {
  display: flex;
  gap: 8px;
  font-size: 12px;
}

.record-type {
  color: #409eff;
  background: #ecf5ff;
  padding: 2px 6px;
  border-radius: 4px;
}

.record-creator {
  color: #909399;
}

.record-time {
  font-size: 12px;
  color: #909399;
  white-space: nowrap;
}

.loading-text, .empty-text {
  text-align: center;
  color: #909399;
  padding: 20px 0;
  font-size: 14px;
}

.refresh-info {
  margin-top: 30px;
  padding-top: 20px;
  border-top: 1px solid #f0f0f0;
  text-align: center;
  font-size: 12px;
  color: #909399;
}

.refresh-text {
  margin-right: 16px;
}

.auto-refresh-text {
  color: #67c23a;
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