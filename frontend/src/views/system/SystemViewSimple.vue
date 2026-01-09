<template>
  <div class="system-management">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>系统管理</span>
          <div class="header-actions">
            <el-button @click="refreshAll" :loading="loading">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
          </div>
        </div>
      </template>

      <!-- 系统概览 -->
      <div class="system-overview">
        <el-row :gutter="20">
          <el-col :span="6">
            <el-card class="overview-card">
              <div class="overview-item">
                <div class="overview-icon health">
                  <el-icon><Monitor /></el-icon>
                </div>
                <div class="overview-content">
                  <div class="overview-title">系统状态</div>
                  <div class="overview-value" :class="systemHealth.status">
                    {{ systemHealth.status === 'healthy' ? '正常' : '异常' }}
                  </div>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="6">
            <el-card class="overview-card">
              <div class="overview-item">
                <div class="overview-icon config">
                  <el-icon><Setting /></el-icon>
                </div>
                <div class="overview-content">
                  <div class="overview-title">配置项</div>
                  <div class="overview-value">{{ configStats.total }}</div>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="6">
            <el-card class="overview-card">
              <div class="overview-item">
                <div class="overview-icon announcement">
                  <el-icon><Bell /></el-icon>
                </div>
                <div class="overview-content">
                  <div class="overview-title">活跃公告</div>
                  <div class="overview-value">{{ announcementStats.active }}</div>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="6">
            <el-card class="overview-card">
              <div class="overview-item">
                <div class="overview-icon logs">
                  <el-icon><Document /></el-icon>
                </div>
                <div class="overview-content">
                  <div class="overview-title">今日日志</div>
                  <div class="overview-value">{{ logStats.today }}</div>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </div>

      <!-- 功能标签页 -->
      <el-tabs v-model="activeTab" class="system-tabs">
        <!-- 系统健康 -->
        <el-tab-pane label="系统健康" name="health">
          <div class="health-section">
            <div class="section-header">
              <h3>系统健康状态</h3>
              <el-button @click="refreshHealth" :loading="healthLoading" size="small">
                <el-icon><Refresh /></el-icon>
                刷新
              </el-button>
            </div>
            
            <el-alert
              :title="systemHealth.status === 'healthy' ? '系统运行正常' : '系统存在异常'"
              :type="systemHealth.status === 'healthy' ? 'success' : 'error'"
              :closable="false"
              style="margin-bottom: 20px;"
            />

            <el-table :data="systemHealth.components" v-loading="healthLoading">
              <el-table-column prop="component" label="组件" width="150" />
              <el-table-column label="状态" width="100" align="center">
                <template #default="{ row }">
                  <el-tag :type="getHealthTagType(row.status)" size="small">
                    {{ getHealthStatusText(row.status) }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="response_time" label="响应时间" width="120" align="center">
                <template #default="{ row }">
                  {{ row.response_time }}ms
                </template>
              </el-table-column>
              <el-table-column label="详情" show-overflow-tooltip>
                <template #default="{ row }">
                  {{ row.error_msg || formatHealthDetails(row.details) }}
                </template>
              </el-table-column>
              <el-table-column prop="checked_at" label="检查时间" width="160" align="center">
                <template #default="{ row }">
                  {{ formatTime(row.checked_at) }}
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>

        <!-- 系统配置 -->
        <el-tab-pane label="系统配置" name="config">
          <div class="config-section">
            <!-- 系统连接信息概览 -->
            <el-card class="connection-overview-card" shadow="never" style="margin-bottom: 16px;">
              <template #header>
                <div class="card-header">
                  <span>系统连接信息</span>
                  <el-button @click="refreshConnectionInfo" size="small" :loading="loadingConnections">
                    <el-icon><Refresh /></el-icon>
                    刷新
                  </el-button>
                </div>
              </template>
              
              <el-row :gutter="16">
                <!-- 前端服务信息 -->
                <el-col :span="8">
                  <div class="connection-item">
                    <div class="connection-header">
                      <el-icon class="connection-icon frontend"><Monitor /></el-icon>
                      <div class="connection-title">
                        <h4>前端服务</h4>
                        <el-tag :type="frontendStatus.status === 'online' ? 'success' : 'danger'" size="small">
                          {{ frontendStatus.status === 'online' ? '在线' : '离线' }}
                        </el-tag>
                      </div>
                    </div>
                    <div class="connection-details">
                      <p><strong>地址:</strong> {{ frontendStatus.url || 'http://localhost:3000' }}</p>
                      <p><strong>版本:</strong> {{ frontendStatus.version || 'v1.0.0' }}</p>
                      <p><strong>构建时间:</strong> {{ frontendStatus.buildTime || '2024-01-01' }}</p>
                    </div>
                  </div>
                </el-col>

                <!-- 后端服务信息 -->
                <el-col :span="8">
                  <div class="connection-item">
                    <div class="connection-header">
                      <el-icon class="connection-icon backend"><Setting /></el-icon>
                      <div class="connection-title">
                        <h4>后端服务</h4>
                        <el-tag :type="backendStatus.status === 'online' ? 'success' : 'danger'" size="small">
                          {{ backendStatus.status === 'online' ? '在线' : '离线' }}
                        </el-tag>
                      </div>
                    </div>
                    <div class="connection-details">
                      <p><strong>地址:</strong> {{ backendStatus.url || 'http://localhost:8080' }}</p>
                      <p><strong>版本:</strong> {{ backendStatus.version || 'v1.0.0' }}</p>
                      <p><strong>响应时间:</strong> {{ backendStatus.responseTime || '0' }}ms</p>
                    </div>
                  </div>
                </el-col>

                <!-- 数据库连接信息 -->
                <el-col :span="8">
                  <div class="connection-item">
                    <div class="connection-header">
                      <el-icon class="connection-icon database"><Document /></el-icon>
                      <div class="connection-title">
                        <h4>数据库</h4>
                        <el-tag :type="databaseStatus.status === 'connected' ? 'success' : 'danger'" size="small">
                          {{ databaseStatus.status === 'connected' ? '已连接' : '断开' }}
                        </el-tag>
                      </div>
                    </div>
                    <div class="connection-details">
                      <p><strong>类型:</strong> {{ databaseStatus.type || 'MySQL' }}</p>
                      <p><strong>地址:</strong> {{ databaseStatus.host || 'localhost:3306' }}</p>
                      <p><strong>数据库:</strong> {{ databaseStatus.database || 'info_system' }}</p>
                    </div>
                  </div>
                </el-col>
              </el-row>
            </el-card>

            <!-- 配置管理 -->
            <el-card class="config-table-card" shadow="never">
              <template #header>
                <div class="card-header">
                  <span>配置管理</span>
                  <el-button @click="handleCreateConfig" type="primary" size="small">
                    <el-icon><Plus /></el-icon>
                    新增配置
                  </el-button>
                </div>
              </template>

              <el-table :data="configs" v-loading="configLoading">
                <el-table-column prop="category" label="分类" width="120">
                  <template #default="{ row }">
                    <el-tag type="primary" size="small">
                      {{ row.category }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="key" label="配置键" width="200" show-overflow-tooltip />
                <el-table-column prop="description" label="描述" show-overflow-tooltip />
                <el-table-column label="配置值" width="200" show-overflow-tooltip>
                  <template #default="{ row }">
                    <span>{{ getValuePreview(row.value) }}</span>
                  </template>
                </el-table-column>
                <el-table-column label="访问权限" width="100" align="center">
                  <template #default="{ row }">
                    <el-tag :type="row.is_public ? 'success' : 'warning'" size="small">
                      {{ row.is_public ? '公开' : '私有' }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="updated_at" label="更新时间" width="160" align="center">
                  <template #default="{ row }">
                    {{ formatTime(row.updated_at) }}
                  </template>
                </el-table-column>
                <el-table-column label="操作" width="180" fixed="right" align="center">
                  <template #default="{ row }">
                    <el-button-group size="small">
                      <el-button @click="handleEditConfig(row)" type="primary">
                        编辑
                      </el-button>
                      <el-button @click="handleDeleteConfig(row)" type="danger">
                        删除
                      </el-button>
                    </el-button-group>
                  </template>
                </el-table-column>
              </el-table>
            </el-card>
          </div>
        </el-tab-pane>

        <!-- Token管理 -->
        <el-tab-pane label="Token管理" name="tokens">
          <div class="tokens-section">
            <div class="section-header">
              <h3>API Token管理</h3>
              <div class="header-actions">
                <el-button @click="handleCreateToken" type="primary" size="small">
                  <el-icon><Plus /></el-icon>
                  生成Token
                </el-button>
              </div>
            </div>

            <!-- Token搜索 -->
            <div class="search-bar" style="margin-bottom: 16px;">
              <el-form :model="tokenSearch" inline>
                <el-form-item label="用户">
                  <el-select v-model="tokenSearch.user_id" placeholder="选择用户" clearable style="width: 200px;" filterable>
                    <el-option label="全部用户" value="" />
                    <el-option 
                      v-for="user in allUsers" 
                      :key="user.id"
                      :label="`${user.username} (${user.email})`" 
                      :value="user.id" 
                    />
                  </el-select>
                </el-form-item>
                <el-form-item label="状态">
                  <el-select v-model="tokenSearch.status" placeholder="选择状态" clearable style="width: 120px;">
                    <el-option label="全部" value="" />
                    <el-option label="有效" value="active" />
                    <el-option label="过期" value="expired" />
                    <el-option label="禁用" value="disabled" />
                  </el-select>
                </el-form-item>
                <el-form-item>
                  <el-button @click="fetchTokens" :loading="tokenLoading">搜索</el-button>
                </el-form-item>
              </el-form>
            </div>

            <el-table :data="tokens" v-loading="tokenLoading">
              <el-table-column prop="name" label="Token名称" show-overflow-tooltip />
              <el-table-column label="用户" width="150">
                <template #default="{ row }">
                  <div class="user-info">
                    <div>{{ row.user?.username }}</div>
                    <div class="user-email">{{ row.user?.email }}</div>
                  </div>
                </template>
              </el-table-column>
              <el-table-column label="Token" width="200" show-overflow-tooltip>
                <template #default="{ row }">
                  <div class="token-display">
                    <span class="token-preview">{{ maskToken(row.token) }}</span>
                    <el-button size="small" text @click="copyToken(row.token)">
                      复制
                    </el-button>
                  </div>
                </template>
              </el-table-column>
              <el-table-column label="权限范围" width="120">
                <template #default="{ row }">
                  <el-tag size="small" :type="getScopeTagType(row.scope)">
                    {{ getScopeDisplayName(row.scope) }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="状态" width="80" align="center">
                <template #default="{ row }">
                  <el-tag :type="getTokenStatusTag(row)" size="small">
                    {{ getTokenStatusText(row) }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="expires_at" label="过期时间" width="160" align="center">
                <template #default="{ row }">
                  <div :class="{ 'text-danger': isTokenExpired(row.expires_at) }">
                    {{ formatTime(row.expires_at) }}
                  </div>
                </template>
              </el-table-column>
              <el-table-column prop="last_used_at" label="最后使用" width="160" align="center">
                <template #default="{ row }">
                  {{ row.last_used_at ? formatTime(row.last_used_at) : '从未使用' }}
                </template>
              </el-table-column>
              <el-table-column label="操作" width="200" fixed="right" align="center">
                <template #default="{ row }">
                  <div class="action-buttons">
                    <el-button size="small" @click="handleViewTokenDetails(row)">详情</el-button>
                    <el-button size="small" type="warning" @click="handleRenewToken(row)" v-if="isTokenExpired(row.expires_at)">
                      续期
                    </el-button>
                    <el-button size="small" type="danger" @click="handleRevokeToken(row)">
                      撤销
                    </el-button>
                  </div>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>

        <!-- 公告管理 -->
        <el-tab-pane label="公告管理" name="announcement">
          <div class="announcement-section">
            <div class="section-header">
              <h3>公告管理</h3>
              <div class="header-actions">
                <el-button @click="handleCreateAnnouncement" type="primary" size="small">
                  <el-icon><Plus /></el-icon>
                  发布公告
                </el-button>
              </div>
            </div>

            <el-table :data="announcements" v-loading="announcementLoading">
              <el-table-column prop="title" label="标题" show-overflow-tooltip />
              <el-table-column label="类型" width="100" align="center">
                <template #default="{ row }">
                  <el-tag :type="getAnnouncementTypeTag(row.type)" size="small">
                    {{ getAnnouncementTypeText(row.type) }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="状态" width="80" align="center">
                <template #default="{ row }">
                  <el-tag :type="row.is_active ? 'success' : 'info'" size="small">
                    {{ row.is_active ? '启用' : '停用' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="view_count" label="查看数" width="80" align="center" />
              <el-table-column prop="created_at" label="创建时间" width="160" align="center">
                <template #default="{ row }">
                  {{ formatTime(row.created_at) }}
                </template>
              </el-table-column>
              <el-table-column label="操作" width="200" fixed="right" align="center">
                <template #default="{ row }">
                  <div class="action-buttons">
                    <el-button size="small" @click="handleViewAnnouncement(row)">查看</el-button>
                    <el-button size="small" @click="handleEditAnnouncement(row)">编辑</el-button>
                    <el-button size="small" type="danger" @click="handleDeleteAnnouncement(row)">删除</el-button>
                  </div>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>

        <!-- 系统日志 -->
        <el-tab-pane label="系统日志" name="logs">
          <div class="logs-section">
            <div class="section-header">
              <h3>系统日志</h3>
              <div class="header-actions">
                <el-button @click="handleLogCleanup" type="warning" size="small">
                  <el-icon><Delete /></el-icon>
                  清理日志
                </el-button>
              </div>
            </div>

            <!-- 日志搜索 -->
            <div class="search-bar" style="margin-bottom: 16px;">
              <el-form :model="logSearch" inline>
                <el-form-item label="级别">
                  <el-select v-model="logSearch.level" placeholder="选择级别" clearable style="width: 120px;">
                    <el-option label="全部" value="" />
                    <el-option label="调试" value="debug" />
                    <el-option label="信息" value="info" />
                    <el-option label="警告" value="warn" />
                    <el-option label="错误" value="error" />
                  </el-select>
                </el-form-item>
                <el-form-item label="分类">
                  <el-select v-model="logSearch.category" placeholder="选择分类" clearable style="width: 150px;">
                    <el-option label="全部" value="" />
                    <el-option label="认证" value="auth" />
                    <el-option label="系统" value="system" />
                    <el-option label="配置" value="config" />
                  </el-select>
                </el-form-item>
                <el-form-item>
                  <el-button @click="fetchLogs" :loading="logLoading">搜索</el-button>
                </el-form-item>
              </el-form>
            </div>

            <el-table :data="logs" v-loading="logLoading">
              <el-table-column label="级别" width="80" align="center">
                <template #default="{ row }">
                  <el-tag :type="getLogLevelTag(row.level)" size="small">
                    {{ row.level.toUpperCase() }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="category" label="分类" width="100" />
              <el-table-column prop="message" label="消息" show-overflow-tooltip />
              <el-table-column label="用户" width="120" align="center">
                <template #default="{ row }">
                  <span v-if="row.user_id">
                    {{ row.user?.username || `用户${row.user_id}` }}
                  </span>
                  <span v-else>系统</span>
                </template>
              </el-table-column>
              <el-table-column prop="ip_address" label="IP地址" width="140" />
              <el-table-column prop="created_at" label="时间" width="160" align="center">
                <template #default="{ row }">
                  {{ formatTime(row.created_at) }}
                </template>
              </el-table-column>
              <el-table-column label="操作" width="120" align="center" fixed="right">
                <template #default="{ row }">
                  <el-button size="small" @click="handleViewLogDetail(row)">详情</el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Refresh, Monitor, Setting, Bell, Document, Plus } from '@element-plus/icons-vue'
import { http } from '../../utils/request'
import dayjs from 'dayjs'

// 响应式数据
const loading = ref(false)
const activeTab = ref('health')

// 系统健康相关
const healthLoading = ref(false)
const systemHealth = ref({
  status: 'healthy',
  components: []
})

// 统计数据
const configStats = ref({ total: 0 })
const announcementStats = ref({ active: 0 })
const logStats = ref({ today: 0 })

// 系统配置相关
const configLoading = ref(false)
const configs = ref([])

// Token管理相关
const tokens = ref([])
const tokenLoading = ref(false)
const allUsers = ref([])

const tokenSearch = reactive({
  user_id: '',
  status: ''
})

// 公告管理相关
const announcementLoading = ref(false)
const announcements = ref([])

// 系统日志相关
const logLoading = ref(false)
const logs = ref([])

const logSearch = reactive({
  level: '',
  category: ''
})

// 系统连接状态
const loadingConnections = ref(false)
const frontendStatus = ref({
  status: 'online',
  url: '',
  version: '',
  buildTime: ''
})

const backendStatus = ref({
  status: 'online',
  url: '',
  version: '',
  responseTime: 0
})

const databaseStatus = ref({
  status: 'connected',
  type: '',
  host: '',
  database: ''
})

// 系统健康相关方法
const refreshHealth = async () => {
  healthLoading.value = true
  try {
    const response = await http.get('/system/health')
    if (response.success) {
      systemHealth.value = {
        status: response.data.overall_status,
        components: response.data.components || []
      }
    }
  } catch (error) {
    console.error('获取系统健康状态失败:', error)
    ElMessage.error('获取系统健康状态失败')
  } finally {
    healthLoading.value = false
  }
}

// 系统配置相关方法
const fetchConfigs = async () => {
  configLoading.value = true
  try {
    const response = await http.get('/config')
    if (response.success) {
      configs.value = response.data.configs || []
      configStats.value.total = response.data.total || 0
    }
  } catch (error) {
    console.error('获取系统配置失败:', error)
    ElMessage.error('获取系统配置失败')
  } finally {
    configLoading.value = false
  }
}

// 刷新连接信息
const refreshConnectionInfo = async () => {
  loadingConnections.value = true
  try {
    await Promise.all([
      loadFrontendStatus(),
      loadBackendStatus(),
      loadDatabaseStatus()
    ])
  } catch (error) {
    console.error('刷新连接信息失败:', error)
  } finally {
    loadingConnections.value = false
  }
}

const loadFrontendStatus = async () => {
  try {
    frontendStatus.value.url = window.location.origin
    frontendStatus.value.status = 'online'
    frontendStatus.value.version = 'v1.0.0'
    frontendStatus.value.buildTime = '2024-10-17'
  } catch (error) {
    console.error('加载前端状态失败:', error)
  }
}

const loadBackendStatus = async () => {
  try {
    const startTime = Date.now()
    const response = await http.get('/system/health')
    const endTime = Date.now()
    
    backendStatus.value.status = 'online'
    backendStatus.value.responseTime = endTime - startTime
    backendStatus.value.version = response.data.version || 'v1.0.0'
    backendStatus.value.url = 'http://localhost:8080'
  } catch (error) {
    backendStatus.value.status = 'offline'
    backendStatus.value.responseTime = 0
  }
}

const loadDatabaseStatus = async () => {
  try {
    const response = await http.get('/system/health')
    if (response.success) {
      const dbComponent = response.data.components?.find((c: any) => c.component === 'database')
      if (dbComponent) {
        databaseStatus.value.status = dbComponent.status === 'healthy' ? 'connected' : 'disconnected'
        databaseStatus.value.type = 'MySQL'
        databaseStatus.value.host = 'localhost:3306'
        databaseStatus.value.database = 'info_system'
      }
    }
  } catch (error) {
    databaseStatus.value.status = 'disconnected'
  }
}

// 配置管理方法
const handleCreateConfig = () => {
  ElMessage.info('配置创建功能开发中...')
}

const handleEditConfig = (row: any) => {
  ElMessage.info('配置编辑功能开发中...')
}

const handleDeleteConfig = (row: any) => {
  ElMessage.info('配置删除功能开发中...')
}

const getValuePreview = (value: string) => {
  if (!value) return ''
  if (value.length > 50) {
    return value.substring(0, 50) + '...'
  }
  return value
}

// Token管理相关方法
const fetchTokens = async () => {
  tokenLoading.value = true
  try {
    const params = {
      user_id: tokenSearch.user_id || undefined,
      status: tokenSearch.status || undefined
    }
    
    const response = await http.get('/tokens', { params })
    if (response.success) {
      tokens.value = response.data.tokens || []
    }
  } catch (error) {
    console.error('获取Token列表失败:', error)
    ElMessage.error('获取Token列表失败')
  } finally {
    tokenLoading.value = false
  }
}

const fetchAllUsers = async () => {
  try {
    const response = await http.get('/users')
    if (response.success) {
      allUsers.value = response.data.users || []
    }
  } catch (error) {
    console.error('获取用户列表失败:', error)
  }
}

const handleCreateToken = () => {
  ElMessage.info('Token生成功能开发中...')
}

const handleViewTokenDetails = (token: any) => {
  ElMessage.info('Token详情功能开发中...')
}

const handleRenewToken = async (token: any) => {
  try {
    await http.put(`/tokens/${token.id}/renew`)
    ElMessage.success('Token续期成功')
    await fetchTokens()
  } catch (error) {
    ElMessage.error('Token续期失败')
  }
}

const handleRevokeToken = async (token: any) => {
  try {
    await ElMessageBox.confirm(`确定要撤销Token "${token.name}" 吗？撤销后将无法恢复。`, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await http.delete(`/tokens/${token.id}`)
    ElMessage.success('Token撤销成功')
    await fetchTokens()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('Token撤销失败')
    }
  }
}

const copyToken = async (token: string) => {
  try {
    await navigator.clipboard.writeText(token)
    ElMessage.success('Token已复制到剪贴板')
  } catch (error) {
    ElMessage.error('复制失败，请手动复制')
  }
}

const maskToken = (token: string) => {
  if (!token) return ''
  if (token.length <= 8) return token
  return token.substring(0, 8) + '...' + token.substring(token.length - 8)
}

// Token相关工具函数
const getTokenStatusTag = (token: any) => {
  if (!token.expires_at) return 'success' // 永不过期
  if (isTokenExpired(token.expires_at)) return 'danger' // 已过期
  if (token.status === 'disabled') return 'info' // 已禁用
  return 'success' // 有效
}

const getTokenStatusText = (token: any) => {
  if (!token.expires_at) return '永久有效'
  if (isTokenExpired(token.expires_at)) return '已过期'
  if (token.status === 'disabled') return '已禁用'
  return '有效'
}

const getScopeTagType = (scope: string) => {
  const typeMap: Record<string, string> = {
    'read': 'info',
    'write': 'warning',
    'admin': 'danger'
  }
  return typeMap[scope] || 'info'
}

const getScopeDisplayName = (scope: string) => {
  const nameMap: Record<string, string> = {
    'read': '只读权限',
    'write': '读写权限',
    'admin': '管理员权限'
  }
  return nameMap[scope] || scope
}

const isTokenExpired = (expiresAt: string) => {
  if (!expiresAt) return false
  return new Date(expiresAt) < new Date()
}

// 工具方法
const refreshAll = async () => {
  loading.value = true
  try {
    await Promise.all([
      refreshHealth(),
      fetchConfigs(),
      refreshConnectionInfo(),
      fetchTokens(),
      fetchAllUsers()
    ])
    ElMessage.success('刷新完成')
  } catch (error) {
    console.error('刷新失败:', error)
    ElMessage.error('刷新失败')
  } finally {
    loading.value = false
  }
}

const formatTime = (time: string) => {
  return time ? dayjs(time).format('YYYY-MM-DD HH:mm:ss') : '-'
}

const formatHealthDetails = (details: any) => {
  if (!details) return '-'
  if (typeof details === 'string') {
    return details
  }
  try {
    return JSON.stringify(details)
  } catch {
    return String(details)
  }
}

// 标签类型方法
const getHealthTagType = (status: string) => {
  const typeMap: Record<string, string> = {
    'healthy': 'success',
    'unhealthy': 'danger',
    'degraded': 'warning'
  }
  return typeMap[status] || 'info'
}

const getHealthStatusText = (status: string) => {
  const textMap: Record<string, string> = {
    'healthy': '正常',
    'unhealthy': '异常',
    'degraded': '降级'
  }
  return textMap[status] || status
}

// 生命周期
onMounted(() => {
  refreshAll()
})
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

.system-overview {
  margin-bottom: 20px;
}

.overview-card {
  height: 100px;
}

.overview-item {
  display: flex;
  align-items: center;
  height: 100%;
}

.overview-icon {
  font-size: 32px;
  margin-right: 16px;
}

.overview-icon.health {
  color: #67c23a;
}

.overview-icon.config {
  color: #409eff;
}

.overview-icon.announcement {
  color: #e6a23c;
}

.overview-icon.logs {
  color: #909399;
}

.overview-content {
  flex: 1;
}

.overview-title {
  font-size: 14px;
  color: #909399;
  margin-bottom: 8px;
}

.overview-value {
  font-size: 24px;
  font-weight: bold;
  color: #303133;
}

.overview-value.healthy {
  color: #67c23a;
}

.overview-value.unhealthy {
  color: #f56c6c;
}

.system-tabs {
  margin-top: 20px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.section-header h3 {
  margin: 0;
  color: #303133;
}

/* 系统连接信息样式 */
.connection-overview-card {
  margin-bottom: 16px;
}

.connection-item {
  padding: 16px;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  background: #fafafa;
}

.connection-header {
  display: flex;
  align-items: center;
  margin-bottom: 12px;
}

.connection-icon {
  font-size: 24px;
  margin-right: 12px;
}

.connection-icon.frontend {
  color: #409eff;
}

.connection-icon.backend {
  color: #67c23a;
}

.connection-icon.database {
  color: #e6a23c;
}

.connection-title h4 {
  margin: 0 0 4px 0;
  font-size: 16px;
  font-weight: 600;
}

.connection-details p {
  margin: 4px 0;
  font-size: 13px;
  color: #606266;
}

.connection-details strong {
  color: #303133;
  margin-right: 8px;
}

/* Token管理样式 */
.tokens-section {
  padding: 20px;
}

.user-info {
  display: flex;
  flex-direction: column;
}

.user-email {
  font-size: 12px;
  color: #909399;
  margin-top: 2px;
}

.token-display {
  display: flex;
  align-items: center;
  gap: 8px;
}

.token-preview {
  font-family: 'Courier New', monospace;
  font-size: 12px;
  color: #606266;
}

.text-danger {
  color: #f56c6c;
}

.action-buttons {
  display: flex;
  gap: 4px;
}
</style>
