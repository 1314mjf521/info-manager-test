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
                  <div class="header-actions">
                    <el-button @click="handleInitializeConfigs" type="success" size="small" v-if="configs.length === 0">
                      <el-icon><Setting /></el-icon>
                      初始化默认配置
                    </el-button>
                    <el-button @click="handleCreateConfig" type="primary" size="small">
                      <el-icon><Plus /></el-icon>
                      新增配置
                    </el-button>
                  </div>
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
                <el-table-column prop="key" label="配置键" width="180" show-overflow-tooltip />
                <el-table-column prop="description" label="描述" show-overflow-tooltip />
                <el-table-column label="数据类型" width="80" align="center">
                  <template #default="{ row }">
                    <el-tag size="small" type="info">
                      {{ getDataTypeDisplayName(row.data_type) }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column label="配置值" width="200" show-overflow-tooltip>
                  <template #default="{ row }">
                    <span>{{ getValuePreview(row.value) }}</span>
                  </template>
                </el-table-column>
                <el-table-column label="权限" width="80" align="center">
                  <template #default="{ row }">
                    <el-tag :type="row.is_public ? 'success' : 'warning'" size="small">
                      {{ row.is_public ? '公开' : '私有' }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column label="可编辑" width="80" align="center">
                  <template #default="{ row }">
                    <el-tag :type="row.is_editable ? 'success' : 'danger'" size="small">
                      {{ row.is_editable ? '是' : '否' }}
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
                      <el-button @click="handleEditConfig(row)" type="primary" :disabled="!row.is_editable">
                        编辑
                      </el-button>
                      <el-button @click="handleDeleteConfig(row)" type="danger" :disabled="!row.is_editable">
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

            <!-- Token统计信息 -->
            <div class="token-stats" style="margin-bottom: 16px;">
              <el-row :gutter="16">
                <el-col :span="6">
                  <el-statistic title="总Token数" :value="tokenStats.total" />
                </el-col>
                <el-col :span="6">
                  <el-statistic title="有效Token" :value="tokenStats.active" />
                </el-col>
                <el-col :span="6">
                  <el-statistic title="过期Token" :value="tokenStats.expired" />
                </el-col>
                <el-col :span="6">
                  <el-statistic title="今日使用" :value="tokenStats.todayUsed" />
                </el-col>
              </el-row>
            </div>

            <!-- Token搜索和批量操作 -->
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
                <el-form-item label="权限范围">
                  <el-select v-model="tokenSearch.scope" placeholder="选择权限" clearable style="width: 120px;">
                    <el-option label="全部权限" value="" />
                    <el-option label="只读" value="read" />
                    <el-option label="读写" value="write" />
                    <el-option label="管理员" value="admin" />
                  </el-select>
                </el-form-item>
                <el-form-item>
                  <el-button @click="fetchTokens" :loading="tokenLoading">搜索</el-button>
                  <el-button @click="resetTokenSearch">重置</el-button>
                </el-form-item>
              </el-form>
              
              <!-- 批量操作 -->
              <div class="batch-actions" v-if="selectedTokens.length > 0" style="margin-top: 10px;">
                <el-alert
                  :title="`已选择 ${selectedTokens.length} 个Token`"
                  type="info"
                  :closable="false"
                >
                  <template #default>
                    <div class="batch-buttons">
                      <el-button size="small" type="warning" @click="handleBatchDisable">
                        批量禁用
                      </el-button>
                      <el-button size="small" type="success" @click="handleBatchEnable">
                        批量启用
                      </el-button>
                      <el-button size="small" type="danger" @click="handleBatchRevoke">
                        批量撤销
                      </el-button>
                    </div>
                  </template>
                </el-alert>
              </div>
            </div>

            <el-table :data="tokens" v-loading="tokenLoading" @selection-change="handleTokenSelection">
              <el-table-column type="selection" width="55" />
              <el-table-column prop="name" label="Token名称" show-overflow-tooltip>
                <template #default="{ row }">
                  <div class="token-name">
                    <span>{{ row.name }}</span>
                    <el-tag v-if="row.is_system" size="small" type="info" style="margin-left: 8px;">
                      系统
                    </el-tag>
                  </div>
                </template>
              </el-table-column>
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
                      <el-icon><CopyDocument /></el-icon>
                    </el-button>
                    <el-button size="small" text @click="showFullToken(row)">
                      <el-icon><View /></el-icon>
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
              <el-table-column label="状态" width="100" align="center">
                <template #default="{ row }">
                  <div class="token-status">
                    <el-tag :type="getTokenStatusTag(row)" size="small">
                      {{ getTokenStatusText(row) }}
                    </el-tag>
                    <div class="status-indicator" v-if="!isTokenExpired(row.expires_at) && row.status === 'active'">
                      <el-tooltip content="Token正常使用中">
                        <div class="status-dot active"></div>
                      </el-tooltip>
                    </div>
                  </div>
                </template>
              </el-table-column>
              <el-table-column label="使用情况" width="120" align="center">
                <template #default="{ row }">
                  <div class="usage-info">
                    <div class="usage-count">{{ row.usage_count || 0 }} 次</div>
                    <div class="last-used">
                      {{ row.last_used_at ? formatTime(row.last_used_at) : '从未使用' }}
                    </div>
                  </div>
                </template>
              </el-table-column>
              <el-table-column label="过期时间" width="160" align="center">
                <template #default="{ row }">
                  <div class="expiry-info">
                    <div :class="{ 'text-danger': isTokenExpired(row.expires_at), 'text-warning': isTokenExpiringSoon(row.expires_at) }">
                      {{ row.expires_at ? formatTime(row.expires_at) : '永不过期' }}
                    </div>
                    <div v-if="row.expires_at" class="expiry-countdown">
                      {{ getExpiryCountdown(row.expires_at) }}
                    </div>
                  </div>
                </template>
              </el-table-column>
              <el-table-column prop="created_at" label="创建时间" width="160" align="center">
                <template #default="{ row }">
                  {{ formatTime(row.created_at) }}
                </template>
              </el-table-column>
              <el-table-column label="操作" width="280" fixed="right" align="center">
                <template #default="{ row }">
                  <div class="action-buttons">
                    <el-button size="small" @click="handleViewTokenDetails(row)">
                      <el-icon><View /></el-icon>
                      详情
                    </el-button>
                    <el-button size="small" @click="handleEditToken(row)">
                      <el-icon><Edit /></el-icon>
                      编辑
                    </el-button>
                    <el-dropdown @command="(command) => handleTokenAction(command, row)" trigger="click">
                      <el-button size="small">
                        更多
                        <el-icon class="el-icon--right"><ArrowDown /></el-icon>
                      </el-button>
                      <template #dropdown>
                        <el-dropdown-menu>
                          <el-dropdown-item command="renew" v-if="isTokenExpired(row.expires_at) || isTokenExpiringSoon(row.expires_at)">
                            <el-icon><Timer /></el-icon>
                            续期
                          </el-dropdown-item>
                          <el-dropdown-item command="disable" v-if="row.status === 'active'">
                            <el-icon><CircleClose /></el-icon>
                            禁用
                          </el-dropdown-item>
                          <el-dropdown-item command="enable" v-if="row.status === 'disabled'">
                            <el-icon><CircleCheck /></el-icon>
                            启用
                          </el-dropdown-item>
                          <el-dropdown-item command="regenerate">
                            <el-icon><Refresh /></el-icon>
                            重新生成
                          </el-dropdown-item>
                          <el-dropdown-item command="usage">
                            <el-icon><DataAnalysis /></el-icon>
                            使用统计
                          </el-dropdown-item>
                          <el-dropdown-item divided command="revoke" style="color: #f56c6c;">
                            <el-icon><Delete /></el-icon>
                            撤销删除
                          </el-dropdown-item>
                        </el-dropdown-menu>
                      </template>
                    </el-dropdown>
                  </div>
                </template>
              </el-table-column>
            </el-table>

            <!-- 分页 -->
            <div class="pagination" style="margin-top: 16px;">
              <el-pagination
                v-model:current-page="tokenPagination.page"
                v-model:page-size="tokenPagination.size"
                :total="tokenPagination.total"
                :page-sizes="[10, 20, 50, 100]"
                layout="total, sizes, prev, pager, next, jumper"
                @size-change="fetchTokens"
                @current-change="fetchTokens"
              />
            </div>
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

            <!-- 公告搜索 -->
            <div class="search-bar">
              <el-form :model="announcementSearch" inline>
                <el-form-item label="类型">
                  <el-select v-model="announcementSearch.type" placeholder="选择类型" clearable style="width: 120px;">
                    <el-option label="全部" value="" />
                    <el-option label="信息" value="info" />
                    <el-option label="警告" value="warning" />
                    <el-option label="错误" value="error" />
                    <el-option label="维护" value="maintenance" />
                  </el-select>
                </el-form-item>
                <el-form-item label="状态">
                  <el-select v-model="announcementSearch.is_active" placeholder="选择状态" clearable style="width: 120px;">
                    <el-option label="全部" value="" />
                    <el-option label="活跃" :value="true" />
                    <el-option label="停用" :value="false" />
                  </el-select>
                </el-form-item>
                <el-form-item>
                  <el-button @click="fetchAnnouncements" :loading="announcementLoading">搜索</el-button>
                </el-form-item>
              </el-form>
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
                    <el-dropdown @command="(command) => handleAnnouncementAction(command, row)">
                      <el-button size="small" type="primary">
                        操作
                        <el-icon class="el-icon--right"><ArrowDown /></el-icon>
                      </el-button>
                      <template #dropdown>
                        <el-dropdown-menu>
                          <el-dropdown-item command="view">
                            <el-icon><View /></el-icon>
                            查看详情
                          </el-dropdown-item>
                          <el-dropdown-item command="preview">
                            <el-icon><Monitor /></el-icon>
                            预览效果
                          </el-dropdown-item>
                          <el-dropdown-item command="edit">
                            <el-icon><Edit /></el-icon>
                            编辑公告
                          </el-dropdown-item>
                          <el-dropdown-item command="delete" divided>
                            <el-icon><Delete /></el-icon>
                            <span style="color: #f56c6c;">删除公告</span>
                          </el-dropdown-item>
                        </el-dropdown-menu>
                      </template>
                    </el-dropdown>
                  </div>
                </template>
              </el-table-column>
            </el-table>

            <!-- 分页 -->
            <div class="pagination">
              <el-pagination
                v-model:current-page="announcementPagination.page"
                v-model:page-size="announcementPagination.size"
                :total="announcementPagination.total"
                :page-sizes="[10, 20, 50]"
                layout="total, sizes, prev, pager, next, jumper"
                @size-change="fetchAnnouncements"
                @current-change="fetchAnnouncements"
              />
            </div>
          </div>
        </el-tab-pane>

        <!-- 系统日志 -->
        <el-tab-pane label="系统日志" name="logs">
          <div class="logs-section">
            <div class="section-header">
              <h3>系统日志</h3>
              <div class="header-actions">
                <el-dropdown @command="handleLogAction">
                  <el-button type="warning" size="small">
                    <el-icon><Delete /></el-icon>
                    清理日志
                    <el-icon class="el-icon--right"><ArrowDown /></el-icon>
                  </el-button>
                  <template #dropdown>
                    <el-dropdown-menu>
                      <el-dropdown-item command="cleanup-filtered">按筛选条件清理</el-dropdown-item>
                      <el-dropdown-item divided command="cleanup-30days">清理30天前日志</el-dropdown-item>
                      <el-dropdown-item command="cleanup-7days">清理7天前日志</el-dropdown-item>
                      <el-dropdown-item command="cleanup-1day">清理1天前日志</el-dropdown-item>
                    </el-dropdown-menu>
                  </template>
                </el-dropdown>
              </div>
            </div>

            <!-- 日志搜索 -->
            <div class="search-bar">
              <el-form :model="logSearch" inline>
                <el-form-item label="级别">
                  <el-select v-model="logSearch.level" placeholder="选择级别" clearable style="width: 120px;">
                    <el-option label="全部" value="" />
                    <el-option label="调试" value="debug" />
                    <el-option label="信息" value="info" />
                    <el-option label="警告" value="warn" />
                    <el-option label="错误" value="error" />
                    <el-option label="致命" value="fatal" />
                  </el-select>
                </el-form-item>
                <el-form-item label="分类">
                  <el-select 
                    v-model="logSearch.category" 
                    placeholder="选择或输入分类" 
                    clearable 
                    filterable 
                    allow-create 
                    default-first-option
                    style="width: 180px;"
                    @change="handleCategoryChange"
                    @focus="refreshCategories"
                  >
                    <el-option label="全部" value="" />
                    <el-option 
                      v-for="category in allCategories" 
                      :key="category" 
                      :label="category" 
                      :value="category" 
                    />
                  </el-select>
                </el-form-item>
                <el-form-item label="IP地址">
                  <el-input 
                    v-model="logSearch.ip_address" 
                    placeholder="IP地址" 
                    clearable 
                    style="width: 140px;"
                  />
                </el-form-item>
                <el-form-item label="时间范围">
                  <el-date-picker
                    v-model="logSearch.timeRange"
                    type="datetimerange"
                    range-separator="至"
                    start-placeholder="开始时间"
                    end-placeholder="结束时间"
                    style="width: 300px;"
                  />
                </el-form-item>
                <el-form-item>
                  <el-button @click="fetchLogs" :loading="logLoading">搜索</el-button>
                </el-form-item>
              </el-form>
              
              <!-- 使用提示 -->
              <el-alert
                title="使用说明"
                type="info"
                :closable="false"
                show-icon
                style="margin-top: 10px;"
              >
                <template #default>
                  <div style="font-size: 12px;">
                    <div style="margin-bottom: 8px;">
                      <strong>筛选功能：</strong>
                      • 分类支持自定义输入，可清理任意分类的日志
                      • 支持按级别、分类、用户、时间范围等条件筛选
                    </div>
                    <div>
                      <strong>清理功能：</strong>
                      • "按筛选条件清理"会清理当前筛选出的所有日志
                      • 其他清理选项按固定时间清理（如清理7天前的所有日志）
                      • 清理前会显示符合条件的日志数量
                    </div>
                  </div>
                </template>
              </el-alert>
            </div>

            <!-- 批量操作工具栏 -->
            <div v-if="selectedLogs.length > 0" class="batch-actions" style="margin-bottom: 16px;">
              <el-alert
                :title="`已选择 ${selectedLogs.length} 条日志`"
                type="info"
                :closable="false"
                show-icon
              >
                <template #default>
                  <div style="display: flex; align-items: center; gap: 12px;">
                    <span>已选择 {{ selectedLogs.length }} 条日志</span>
                    <el-button size="small" @click="clearSelection">清空选择</el-button>
                    <el-button size="small" type="danger" @click="handleBatchDeleteLogs" :loading="batchDeleting">
                      <el-icon><Delete /></el-icon>
                      批量删除
                    </el-button>
                  </div>
                </template>
              </el-alert>
            </div>

            <el-table 
              :data="logs" 
              v-loading="logLoading"
              @selection-change="handleSelectionChange"
              ref="logTableRef"
            >
              <el-table-column type="selection" width="55" />
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
                    {{ getUserDisplayName(row) }}
                  </span>
                  <span v-else>
                    {{ getFallbackUserDisplay(row) }}
                  </span>
                </template>
              </el-table-column>
              <el-table-column prop="ip_address" label="IP地址" width="140" />
              <el-table-column prop="created_at" label="时间" width="160" align="center">
                <template #default="{ row }">
                  {{ formatTime(row.created_at) }}
                </template>
              </el-table-column>
              <el-table-column label="操作" width="160" align="center" fixed="right">
                <template #default="{ row }">
                  <div style="display: flex; gap: 4px; justify-content: center;">
                    <el-button size="small" @click="handleViewLogDetail(row)">详情</el-button>
                    <el-button size="small" type="danger" @click="handleDeleteSingleLog(row)" :loading="logDeleting">
                      删除
                    </el-button>
                  </div>
                </template>
              </el-table-column>
            </el-table>

            <!-- 分页 -->
            <div class="pagination">
              <el-pagination
                v-model:current-page="logPagination.page"
                v-model:page-size="logPagination.size"
                :total="logPagination.total"
                :page-sizes="[10, 20, 50, 100]"
                layout="total, sizes, prev, pager, next, jumper"
                @size-change="fetchLogs"
                @current-change="fetchLogs"
              />
            </div>
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 公告编辑对话框 -->
    <el-dialog v-model="announcementDialogVisible" :title="isEditAnnouncement ? '编辑公告' : '发布公告'" width="800px">
      <el-form ref="announcementFormRef" :model="announcementForm" :rules="announcementRules" label-width="100px">
        <el-form-item label="标题" prop="title">
          <el-input v-model="announcementForm.title" placeholder="请输入公告标题" />
        </el-form-item>
        <el-form-item label="类型" prop="type">
          <el-select v-model="announcementForm.type" placeholder="选择公告类型">
            <el-option label="信息" value="info" />
            <el-option label="警告" value="warning" />
            <el-option label="错误" value="error" />
            <el-option label="维护" value="maintenance" />
          </el-select>
        </el-form-item>
        <el-form-item label="优先级" prop="priority">
          <el-input-number v-model="announcementForm.priority" :min="1" :max="10" placeholder="输入优先级(1-10)" />
        </el-form-item>
        <el-form-item label="内容" prop="content">
          <el-input v-model="announcementForm.content" type="textarea" :rows="6" placeholder="请输入公告内容" />
        </el-form-item>
        <el-form-item label="生效时间">
          <el-date-picker
            v-model="announcementForm.startTime"
            type="datetime"
            placeholder="选择生效时间"
            style="width: 100%;"
          />
        </el-form-item>
        <el-form-item label="失效时间">
          <el-date-picker
            v-model="announcementForm.endTime"
            type="datetime"
            placeholder="选择失效时间"
            style="width: 100%;"
          />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="announcementForm.is_active" />
          <span style="margin-left: 10px;">{{ announcementForm.is_active ? '启用' : '停用' }}</span>
        </el-form-item>
        <el-form-item label="置顶">
          <el-switch v-model="announcementForm.is_sticky" />
          <span style="margin-left: 10px;">{{ announcementForm.is_sticky ? '是' : '否' }}</span>
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="announcementDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSaveAnnouncement" :loading="announcementSubmitting">
            {{ isEditAnnouncement ? '更新' : '发布' }}
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 公告查看对话框 -->
    <el-dialog v-model="announcementViewDialogVisible" title="公告详情" width="700px">
      <div v-if="currentAnnouncement">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="标题" :span="2">
            <h3 style="margin: 0; color: #303133;">{{ currentAnnouncement.title }}</h3>
          </el-descriptions-item>
          <el-descriptions-item label="类型">
            <el-tag :type="getAnnouncementTypeTag(currentAnnouncement.type)" size="small">
              {{ getAnnouncementTypeText(currentAnnouncement.type) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="优先级">
            <el-tag :type="getPriorityTag(currentAnnouncement.priority)" size="small">
              {{ getPriorityText(currentAnnouncement.priority) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="currentAnnouncement.is_active ? 'success' : 'info'" size="small">
              {{ currentAnnouncement.is_active ? '启用' : '停用' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="置顶">
            <el-tag :type="currentAnnouncement.is_sticky ? 'warning' : 'info'" size="small">
              {{ currentAnnouncement.is_sticky ? '是' : '否' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="生效时间">
            {{ formatTime(currentAnnouncement.start_time) }}
          </el-descriptions-item>
          <el-descriptions-item label="失效时间">
            {{ formatTime(currentAnnouncement.end_time) }}
          </el-descriptions-item>
          <el-descriptions-item label="查看次数">
            {{ currentAnnouncement.view_count || 0 }}
          </el-descriptions-item>
          <el-descriptions-item label="创建时间">
            {{ formatTime(currentAnnouncement.created_at) }}
          </el-descriptions-item>
          <el-descriptions-item label="内容" :span="2">
            <div class="announcement-content">
              <el-input
                :value="currentAnnouncement.content"
                type="textarea"
                :rows="6"
                readonly
                resize="vertical"
              />
            </div>
          </el-descriptions-item>
        </el-descriptions>
      </div>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="announcementViewDialogVisible = false">关闭</el-button>
          <el-button type="primary" @click="handleEditAnnouncement(currentAnnouncement)">
            编辑此公告
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 公告预览对话框 -->
    <el-dialog v-model="announcementPreviewDialogVisible" title="公告预览" width="600px" class="announcement-preview-dialog">
      <div v-if="currentAnnouncement" class="announcement-preview">
        <div class="preview-header">
          <div class="preview-title">
            <el-icon v-if="currentAnnouncement.type === 'warning'" class="preview-icon warning"><Warning /></el-icon>
            <el-icon v-else-if="currentAnnouncement.type === 'error'" class="preview-icon error"><CircleClose /></el-icon>
            <el-icon v-else-if="currentAnnouncement.type === 'maintenance'" class="preview-icon maintenance"><Tools /></el-icon>
            <el-icon v-else class="preview-icon info"><InfoFilled /></el-icon>
            {{ currentAnnouncement.title }}
          </div>
          <div class="preview-meta">
            <el-tag :type="getPriorityTag(currentAnnouncement.priority)" size="small">
              优先级: {{ getPriorityText(currentAnnouncement.priority) }}
            </el-tag>
            <span class="preview-time">{{ formatTime(currentAnnouncement.created_at) }}</span>
          </div>
        </div>
        <el-divider />
        <div class="preview-content">
          <p v-html="currentAnnouncement.content.replace(/\n/g, '<br>')"></p>
        </div>
        <div class="preview-footer">
          <small class="text-muted">
            此预览展示了公告在用户界面中的显示效果
          </small>
        </div>
      </div>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="announcementPreviewDialogVisible = false">关闭</el-button>
          <el-button type="success" @click="handleTestPublicDisplay">测试公共显示</el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 日志详情对话框 -->
    <el-dialog v-model="logDetailDialogVisible" title="日志详情" width="800px">
      <div v-if="currentLog">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="级别">
            <el-tag :type="getLogLevelTag(currentLog.level)" size="small">
              {{ currentLog.level.toUpperCase() }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="分类">
            {{ currentLog.category }}
          </el-descriptions-item>
          <el-descriptions-item label="用户">
            {{ getUserDisplayName(currentLog) }}
          </el-descriptions-item>
          <el-descriptions-item label="IP地址">
            {{ currentLog.ip_address || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="时间">
            {{ formatTime(currentLog.created_at) }}
          </el-descriptions-item>
          <el-descriptions-item label="请求ID">
            {{ currentLog.request_id || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="消息" :span="2">
            <div class="log-message">
              {{ currentLog.message }}
            </div>
          </el-descriptions-item>
          <el-descriptions-item label="上下文" :span="2" v-if="currentLog.context">
            <div class="log-context">
              <el-input
                :value="formatLogContext(currentLog.context)"
                type="textarea"
                :rows="8"
                readonly
                resize="vertical"
              />
            </div>
          </el-descriptions-item>
        </el-descriptions>
      </div>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="logDetailDialogVisible = false">关闭</el-button>
          <el-button type="danger" @click="handleDeleteSingleLog(currentLog)" :loading="logDeleting">
            <el-icon><Delete /></el-icon>
            删除此日志
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- Token创建/编辑对话框 -->
    <el-dialog
      v-model="tokenDialogVisible"
      :title="currentToken ? '编辑Token' : '创建Token'"
      width="600px"
      :close-on-click-modal="false"
    >
      <el-form :model="tokenForm" label-width="100px" :rules="tokenFormRules" ref="tokenFormRef">
        <el-form-item label="Token名称" prop="name">
          <el-input v-model="tokenForm.name" placeholder="请输入Token名称" />
        </el-form-item>
        
        <el-form-item label="关联用户" prop="user_id">
          <div v-if="allUsers.length > 0">
            <el-select v-model="tokenForm.user_id" placeholder="选择用户" style="width: 100%;" filterable>
              <el-option 
                v-for="user in allUsers" 
                :key="user.id"
                :label="`${user.username} (${user.email})`" 
                :value="user.id" 
              />
            </el-select>
          </div>
          <div v-else>
            <el-input 
              v-model="tokenForm.user_id" 
              placeholder="请输入用户ID（数字）" 
              type="number"
              style="width: 100%;"
            />
            <div style="font-size: 12px; color: #e6a23c; margin-top: 4px;">
              ⚠️ 无法加载用户列表，请手动输入用户ID
            </div>
          </div>
          <!-- 调试信息 -->
          <div style="font-size: 12px; color: #999; margin-top: 4px;">
            已加载 {{ allUsers.length }} 个用户
            <el-button size="small" text @click="fetchAllUsers" style="margin-left: 8px;">
              重新加载用户列表
            </el-button>
          </div>
        </el-form-item>
        
        <el-form-item label="权限范围" prop="scope">
          <el-select v-model="tokenForm.scope" style="width: 100%;">
            <el-option label="只读权限" value="read" />
            <el-option label="读写权限" value="write" />
            <el-option label="管理员权限" value="admin" />
          </el-select>
        </el-form-item>
        
        <el-form-item label="有效期" prop="expires_in">
          <el-select v-model="tokenForm.expires_in" style="width: 100%;">
            <el-option label="7天" :value="7" />
            <el-option label="30天" :value="30" />
            <el-option label="90天" :value="90" />
            <el-option label="180天" :value="180" />
            <el-option label="365天" :value="365" />
            <el-option label="永不过期" :value="0" />
          </el-select>
        </el-form-item>
        
        <el-form-item label="描述">
          <el-input 
            v-model="tokenForm.description" 
            type="textarea" 
            :rows="3"
            placeholder="请输入Token用途描述（可选）"
          />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <div>
          <el-button @click="tokenDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSaveToken" :loading="tokenLoading">
            {{ currentToken ? '更新' : '创建' }}
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- Token详情对话框 -->
    <el-dialog
      v-model="tokenDetailDialogVisible"
      title="Token详情"
      width="700px"
    >
      <div v-if="currentToken">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="Token名称" :span="2">
            <div style="display: flex; align-items: center; gap: 8px;">
              <span style="font-weight: 600;">{{ currentToken.name }}</span>
              <el-tag v-if="currentToken.is_system" size="small" type="info">系统Token</el-tag>
            </div>
          </el-descriptions-item>
          
          <el-descriptions-item label="关联用户">
            <div>
              <div>{{ currentToken.user?.username }}</div>
              <div style="font-size: 12px; color: #999;">{{ currentToken.user?.email }}</div>
            </div>
          </el-descriptions-item>
          
          <el-descriptions-item label="权限范围">
            <el-tag :type="getScopeTagType(currentToken.scope)">
              {{ getScopeDisplayName(currentToken.scope) }}
            </el-tag>
          </el-descriptions-item>
          
          <el-descriptions-item label="状态">
            <el-tag :type="getTokenStatusTag(currentToken)">
              {{ getTokenStatusText(currentToken) }}
            </el-tag>
          </el-descriptions-item>
          
          <el-descriptions-item label="使用次数">
            {{ currentToken.usage_count || 0 }} 次
          </el-descriptions-item>
          
          <el-descriptions-item label="创建时间">
            {{ formatTime(currentToken.created_at) }}
          </el-descriptions-item>
          
          <el-descriptions-item label="过期时间">
            <div :class="{ 'text-danger': isTokenExpired(currentToken.expires_at) }">
              {{ currentToken.expires_at ? formatTime(currentToken.expires_at) : '永不过期' }}
            </div>
          </el-descriptions-item>
          
          <el-descriptions-item label="最后使用">
            {{ currentToken.last_used_at ? formatTime(currentToken.last_used_at) : '从未使用' }}
          </el-descriptions-item>
          
          <el-descriptions-item label="Token值" :span="2">
            <div class="token-value">
              <el-input 
                :value="currentToken.token" 
                readonly 
                type="textarea" 
                :rows="2"
                style="font-family: monospace;"
              />
              <div style="margin-top: 8px;">
                <el-button size="small" @click="copyToken(currentToken.token)">
                  <el-icon><CopyDocument /></el-icon>
                  复制Token
                </el-button>
              </div>
            </div>
          </el-descriptions-item>
          
          <el-descriptions-item label="描述" :span="2" v-if="currentToken.description">
            {{ currentToken.description }}
          </el-descriptions-item>
        </el-descriptions>
      </div>
      
      <template #footer>
        <div>
          <el-button @click="tokenDetailDialogVisible = false">关闭</el-button>
          <el-button type="primary" @click="handleEditToken(currentToken)">编辑</el-button>
        </div>
      </template>
    </el-dialog>

    <!-- Token使用统计对话框 -->
    <el-dialog
      v-model="tokenUsageDialogVisible"
      title="Token使用统计"
      width="1000px"
    >
      <div v-if="currentToken">
        <div class="usage-stats">
          <!-- 统计概览 -->
          <el-row :gutter="16" style="margin-bottom: 20px;">
            <el-col :span="6">
              <el-statistic title="总使用次数" :value="currentToken.total_usage || currentToken.usage_count || 0" />
            </el-col>
            <el-col :span="6">
              <el-statistic title="今日使用" :value="currentToken.today_usage || 0" />
            </el-col>
            <el-col :span="6">
              <el-statistic title="本周使用" :value="currentToken.week_usage || 0" />
            </el-col>
            <el-col :span="6">
              <el-statistic title="本月使用" :value="currentToken.month_usage || 0" />
            </el-col>
          </el-row>
          
          <el-divider content-position="left">使用历史</el-divider>
          
          <!-- 使用历史表格 -->
          <div class="usage-history">
            <el-table 
              :data="tokenUsageHistory" 
              v-loading="usageHistoryLoading"
              style="width: 100%"
              max-height="400"
            >
              <el-table-column prop="method" label="请求方法" width="80" align="center">
                <template #default="{ row }">
                  <el-tag :type="getMethodTagType(row.method)" size="small">
                    {{ row.method }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="path" label="请求路径" show-overflow-tooltip />
              <el-table-column prop="status_code" label="状态码" width="80" align="center">
                <template #default="{ row }">
                  <el-tag :type="getStatusTagType(row.status_code)" size="small">
                    {{ row.status_code }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="duration" label="耗时" width="80" align="center">
                <template #default="{ row }">
                  {{ row.duration }}ms
                </template>
              </el-table-column>
              <el-table-column prop="ip_address" label="IP地址" width="120" />
              <el-table-column prop="created_at" label="使用时间" width="160" align="center">
                <template #default="{ row }">
                  {{ formatTime(row.created_at) }}
                </template>
              </el-table-column>
            </el-table>
            
            <!-- 分页 -->
            <div class="pagination" style="margin-top: 16px;" v-if="usageHistoryPagination.total > 0">
              <el-pagination
                v-model:current-page="usageHistoryPagination.page"
                v-model:page-size="usageHistoryPagination.size"
                :total="usageHistoryPagination.total"
                :page-sizes="[10, 20, 50]"
                layout="total, sizes, prev, pager, next, jumper"
                @size-change="() => fetchTokenUsageHistory(currentToken.id)"
                @current-change="() => fetchTokenUsageHistory(currentToken.id)"
              />
            </div>
            
            <!-- 空状态 -->
            <el-empty v-if="!usageHistoryLoading && tokenUsageHistory.length === 0" description="暂无使用记录" />
          </div>
        </div>
      </div>
      
      <template #footer>
        <div>
          <el-button @click="tokenUsageDialogVisible = false">关闭</el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 配置编辑对话框 -->
    <el-dialog v-model="configDialogVisible" :title="isEditConfig ? '编辑配置' : '新增配置'" width="600px">
      <el-form ref="configFormRef" :model="configForm" :rules="configRules" label-width="100px">
        <el-form-item label="分类" prop="category">
          <el-select v-model="configForm.category" placeholder="选择或输入分类" filterable allow-create>
            <el-option label="系统配置" value="system" />
            <el-option label="数据库配置" value="database" />
            <el-option label="文件存储" value="storage" />
            <el-option label="缓存配置" value="cache" />
            <el-option label="邮件配置" value="email" />
            <el-option label="安全配置" value="security" />
          </el-select>
        </el-form-item>
        <el-form-item label="配置键" prop="key">
          <el-input v-model="configForm.key" placeholder="请输入配置键" :disabled="isEditConfig" />
        </el-form-item>
        <el-form-item label="数据类型" prop="data_type">
          <el-select v-model="configForm.data_type" placeholder="选择数据类型">
            <el-option label="字符串" value="string" />
            <el-option label="整数" value="int" />
            <el-option label="布尔值" value="bool" />
            <el-option label="JSON" value="json" />
          </el-select>
        </el-form-item>
        <el-form-item label="配置值" prop="value">
          <el-input 
            v-if="configForm.data_type !== 'json'"
            v-model="configForm.value" 
            :type="configForm.data_type === 'int' ? 'number' : 'text'"
            placeholder="请输入配置值" 
          />
          <el-input 
            v-else
            v-model="configForm.value" 
            type="textarea" 
            :rows="4"
            placeholder="请输入JSON格式的配置值" 
          />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="configForm.description" type="textarea" :rows="2" placeholder="请输入配置描述" />
        </el-form-item>
        <el-form-item label="访问权限">
          <el-checkbox v-model="configForm.is_public">公开访问（前端可访问）</el-checkbox>
        </el-form-item>
        <el-form-item label="编辑权限">
          <el-checkbox v-model="configForm.is_editable">允许编辑</el-checkbox>
        </el-form-item>
        <el-form-item label="变更原因" prop="reason" v-if="isEditConfig">
          <el-input v-model="configForm.reason" placeholder="请输入变更原因" />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <div>
          <el-button @click="configDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSaveConfig" :loading="configSubmitting">
            {{ isEditConfig ? '更新' : '创建' }}
          </el-button>
        </div>
      </template>
    </el-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  Refresh, Monitor, Setting, Bell, Document, Plus, Delete, ArrowDown, Warning, Close as CircleClose, Tools, InfoFilled, View, Edit,
  CopyDocument, Timer, Check as CircleCheck, DataAnalysis, Key
} from '@element-plus/icons-vue'
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
const configDialogVisible = ref(false)
const isEditConfig = ref(false)
const configForm = reactive({
  id: null,
  category: '',
  key: '',
  value: '',
  description: '',
  data_type: 'string',
  is_public: false,
  is_editable: true,
  reason: ''
})
const configFormRef = ref(null)
const configSubmitting = ref(false)

// 配置表单验证规则
const configRules = {
  category: [
    { required: true, message: '请选择或输入分类', trigger: 'blur' }
  ],
  key: [
    { required: true, message: '请输入配置键', trigger: 'blur' },
    { pattern: /^[a-zA-Z][a-zA-Z0-9_]*$/, message: '配置键只能包含字母、数字和下划线，且以字母开头', trigger: 'blur' }
  ],
  value: [
    { required: true, message: '请输入配置值', trigger: 'blur' }
  ],
  data_type: [
    { required: true, message: '请选择数据类型', trigger: 'change' }
  ]
}

// Token管理相关
const tokens = ref([])
const tokenLoading = ref(false)
const selectedTokens = ref([])
const tokenStats = ref({
  total: 0,
  active: 0,
  expired: 0,
  todayUsed: 0
})
const tokenSearch = reactive({
  user_id: '',
  status: '',
  scope: ''
})
const tokenPagination = reactive({
  page: 1,
  size: 20,
  total: 0
})

// Token对话框相关
const tokenDialogVisible = ref(false)
const tokenDetailDialogVisible = ref(false)
const tokenUsageDialogVisible = ref(false)
const currentToken = ref(null)
const tokenUsageHistory = ref([])
const usageHistoryLoading = ref(false)
const usageHistoryPagination = reactive({
  page: 1,
  size: 20,
  total: 0
})
const tokenForm = reactive({
  name: '',
  user_id: '',
  scope: 'read',
  expires_in: 30, // 天数
  description: ''
})

// 用户列表
const allUsers = ref([])

// Token表单验证规则
const tokenFormRules = {
  name: [
    { required: true, message: '请输入Token名称', trigger: 'blur' },
    { min: 2, max: 50, message: '长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  user_id: [
    { required: true, message: '请选择关联用户', trigger: 'change' }
  ],
  scope: [
    { required: true, message: '请选择权限范围', trigger: 'change' }
  ]
}

// 表单引用
const tokenFormRef = ref(null)

// 公告管理相关数据
const announcementSearch = reactive({
  type: '',
  is_active: ''
})

const announcementPagination = reactive({
  page: 1,
  size: 20,
  total: 0
})

// 公告管理相关
const announcementLoading = ref(false)
const announcements = ref([])
const announcementDialogVisible = ref(false)
const announcementViewDialogVisible = ref(false)
const announcementPreviewDialogVisible = ref(false)
const announcementFormRef = ref()
const announcementSubmitting = ref(false)
const isEditAnnouncement = ref(false)
const currentAnnouncement = ref(null)

const announcementForm = reactive({
  id: null,
  title: '',
  type: 'info',
  priority: 1,
  content: '',
  startTime: null,
  endTime: null,
  is_active: true,
  is_sticky: false
})

const announcementRules = {
  title: [{ required: true, message: '请输入公告标题', trigger: 'blur' }],
  type: [{ required: true, message: '请选择公告类型', trigger: 'change' }],
  content: [{ required: true, message: '请输入公告内容', trigger: 'blur' }]
}

// 系统日志相关
const logLoading = ref(false)
const logs = ref([])
const selectedLogs = ref([])
const logDeleting = ref(false)
const batchDeleting = ref(false)
const logTableRef = ref()
const allCategories = ref([])
const currentLog = ref(null)
const logDetailDialogVisible = ref(false)

const logSearch = reactive({
  level: '',
  category: '',
  ip_address: '',
  timeRange: null
})

const logPagination = reactive({
  page: 1,
  size: 50,
  total: 0
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
const resetConfigForm = () => {
  Object.assign(configForm, {
    id: null,
    category: '',
    key: '',
    value: '',
    description: '',
    data_type: 'string',
    is_public: false,
    is_editable: true,
    reason: ''
  })
}

const handleCreateConfig = () => {
  isEditConfig.value = false
  resetConfigForm()
  configDialogVisible.value = true
}

const handleEditConfig = (row: any) => {
  isEditConfig.value = true
  Object.assign(configForm, {
    id: row.id,
    category: row.category,
    key: row.key,
    value: row.value,
    description: row.description,
    data_type: row.data_type,
    is_public: row.is_public,
    is_editable: row.is_editable,
    reason: ''
  })
  configDialogVisible.value = true
}

const handleSaveConfig = async () => {
  try {
    await configFormRef.value.validate()
    configSubmitting.value = true
    
    const data = {
      category: configForm.category,
      key: configForm.key,
      value: configForm.value,
      description: configForm.description,
      data_type: configForm.data_type,
      is_public: configForm.is_public,
      is_editable: configForm.is_editable,
      reason: configForm.reason
    }
    
    if (isEditConfig.value) {
      const response = await http.put(`/config/${configForm.category}/${configForm.key}`, {
        value: configForm.value,
        reason: configForm.reason
      })
      if (response.success) {
        ElMessage.success('配置更新成功')
      } else {
        ElMessage.error(response.message || '更新配置失败')
      }
    } else {
      const response = await http.post('/config', data)
      if (response.success) {
        ElMessage.success('配置创建成功')
      } else {
        ElMessage.error(response.message || '创建配置失败')
      }
    }
    
    configDialogVisible.value = false
    await fetchConfigs()
  } catch (error) {
    console.error('保存配置失败:', error)
    ElMessage.error('保存配置失败')
  } finally {
    configSubmitting.value = false
  }
}

const handleDeleteConfig = async (row: any) => {
  try {
    const { value: reason } = await ElMessageBox.prompt(
      `确定要删除配置 "${row.category}.${row.key}" 吗？请输入删除原因：`,
      '删除配置',
      {
        confirmButtonText: '确定删除',
        cancelButtonText: '取消',
        inputPattern: /.+/,
        inputErrorMessage: '请输入删除原因'
      }
    )
    
    const response = await http.delete(`/config/${row.category}/${row.key}?reason=${encodeURIComponent(reason)}`)
    if (response.success) {
      ElMessage.success('配置删除成功')
      await fetchConfigs()
    } else {
      ElMessage.error(response.message || '删除配置失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除配置失败:', error)
      ElMessage.error('删除配置失败')
    }
  }
}

const handleInitializeConfigs = async () => {
  try {
    await ElMessageBox.confirm(
      '这将创建系统默认配置项，包括系统设置、数据库配置、文件存储、安全配置等。确定要初始化吗？',
      '初始化默认配置',
      {
        confirmButtonText: '确定初始化',
        cancelButtonText: '取消',
        type: 'info'
      }
    )
    
    configLoading.value = true
    const response = await http.post('/config/initialize')
    if (response.success) {
      ElMessage.success(`默认配置初始化成功，创建了 ${response.data.count} 个配置项`)
      await fetchConfigs()
      await fetchSystemStats() // 刷新统计信息
    } else {
      ElMessage.error(response.message || '初始化默认配置失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('初始化默认配置失败:', error)
      ElMessage.error('初始化默认配置失败')
    }
  } finally {
    configLoading.value = false
  }
}

const getValuePreview = (value: string) => {
  if (!value) return ''
  if (value.length > 50) {
    return value.substring(0, 50) + '...'
  }
  return value
}

// 获取数据类型显示名称
const getDataTypeDisplayName = (dataType: string) => {
  const typeMap: Record<string, string> = {
    'string': '字符串',
    'int': '整数',
    'bool': '布尔值',
    'json': 'JSON'
  }
  return typeMap[dataType] || dataType
}

// Token管理相关方法
const fetchTokens = async () => {
  tokenLoading.value = true
  try {
    const params = {
      page: tokenPagination.page,
      page_size: tokenPagination.size,
      user_id: tokenSearch.user_id || undefined,
      status: tokenSearch.status || undefined,
      scope: tokenSearch.scope || undefined
    }
    
    const response = await http.get('/tokens', { params })
    if (response.success) {
      tokens.value = response.data.tokens || []
      tokenPagination.total = response.data.total || 0
      
      // 更新统计信息
      tokenStats.value = {
        total: response.data.stats?.total || 0,
        active: response.data.stats?.active || 0,
        expired: response.data.stats?.expired || 0,
        todayUsed: response.data.stats?.today_used || 0
      }
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
    console.log('正在获取用户列表...')
    const response = await http.get('/system/users')
    console.log('用户列表API响应:', response)
    
    if (response.success) {
      allUsers.value = response.data.users || []
      console.log('用户列表加载成功:', allUsers.value.length, '个用户')
      console.log('用户详情:', allUsers.value)
    } else {
      console.error('用户列表API返回失败:', response)
      ElMessage.error(`获取用户列表失败: ${response.error || '未知错误'}`)
    }
  } catch (error) {
    console.error('获取用户列表失败:', error)
    
    // 检查具体的错误类型
    if (error.response) {
      console.error('HTTP错误状态:', error.response.status)
      console.error('错误响应:', error.response.data)
      
      if (error.response.status === 403) {
        ElMessage.error('没有权限访问用户列表，请联系管理员')
      } else if (error.response.status === 404) {
        ElMessage.error('用户API不存在，请检查后端配置')
      } else {
        ElMessage.error(`获取用户列表失败: HTTP ${error.response.status}`)
      }
    } else {
      ElMessage.error('网络连接失败，请检查网络')
    }
  }
}

const handleCreateToken = async () => {
  // 重置表单
  Object.assign(tokenForm, {
    name: '',
    user_id: '',
    scope: 'read',
    expires_in: 30,
    description: ''
  })
  
  // 确保用户列表已加载
  if (allUsers.value.length === 0) {
    await fetchAllUsers()
  }
  
  tokenDialogVisible.value = true
}

const handleViewTokenDetails = (token: any) => {
  currentToken.value = token
  tokenDetailDialogVisible.value = true
}

const handleRenewToken = async (token: any) => {
  try {
    // 弹出对话框让用户选择续期时间
    const { value: expiresIn } = await ElMessageBox.prompt(
      '请输入续期时间（小时），0表示永不过期',
      `续期Token: ${token.name}`,
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        inputPattern: /^\d+$/,
        inputErrorMessage: '请输入有效的数字',
        inputValue: '720' // 默认30天
      }
    )
    
    await http.put(`/tokens/${token.id}/renew`, {
      expires_in: parseInt(expiresIn)
    })
    ElMessage.success('Token续期成功')
    await fetchTokens()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('Token续期失败')
    }
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

// 新增Token管理方法
const handleTokenSelection = (selection: any[]) => {
  selectedTokens.value = selection
}

const resetTokenSearch = () => {
  Object.assign(tokenSearch, {
    user_id: '',
    status: '',
    scope: ''
  })
  fetchTokens()
}

const handleEditToken = (token: any) => {
  Object.assign(tokenForm, {
    name: token.name,
    user_id: token.user_id,
    scope: token.scope,
    expires_in: 30,
    description: token.description || ''
  })
  currentToken.value = token
  tokenDialogVisible.value = true
}

const handleTokenAction = async (command: string, token: any) => {
  switch (command) {
    case 'renew':
      await handleRenewToken(token)
      break
    case 'disable':
      await handleDisableToken(token)
      break
    case 'enable':
      await handleEnableToken(token)
      break
    case 'regenerate':
      await handleRegenerateToken(token)
      break
    case 'usage':
      await handleViewTokenUsage(token)
      break
    case 'revoke':
      await handleRevokeToken(token)
      break
  }
}

const handleDisableToken = async (token: any) => {
  try {
    await ElMessageBox.confirm(`确定要禁用Token "${token.name}" 吗？`, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await http.put(`/tokens/${token.id}/disable`)
    ElMessage.success('Token禁用成功')
    await fetchTokens()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('Token禁用失败')
    }
  }
}

const handleEnableToken = async (token: any) => {
  try {
    await http.put(`/tokens/${token.id}/enable`)
    ElMessage.success('Token启用成功')
    await fetchTokens()
  } catch (error) {
    ElMessage.error('Token启用失败')
  }
}

const handleRegenerateToken = async (token: any) => {
  try {
    await ElMessageBox.confirm(
      `确定要重新生成Token "${token.name}" 吗？原Token将立即失效，请确保已更新所有使用该Token的应用。`,
      '重新生成Token',
      {
        confirmButtonText: '确定重新生成',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    const response = await http.post(`/tokens/${token.id}/regenerate`)
    if (response.success) {
      ElMessage.success('Token重新生成成功')
      // 显示新Token
      await ElMessageBox.alert(
        `新Token: ${response.data.token}`,
        '新Token已生成',
        {
          confirmButtonText: '我已复制',
          type: 'success'
        }
      )
      await fetchTokens()
    }
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('Token重新生成失败')
    }
  }
}

const fetchTokenUsageHistory = async (tokenId: number) => {
  usageHistoryLoading.value = true
  try {
    const params = {
      page: usageHistoryPagination.page,
      page_size: usageHistoryPagination.size
    }
    
    const response = await http.get(`/tokens/${tokenId}/history`, { params })
    if (response.success) {
      tokenUsageHistory.value = response.data.usage_logs || []
      usageHistoryPagination.total = response.data.total || 0
    }
  } catch (error) {
    console.error('获取Token使用历史失败:', error)
    ElMessage.error('获取Token使用历史失败')
  } finally {
    usageHistoryLoading.value = false
  }
}

const handleViewTokenUsage = async (token: any) => {
  try {
    // 获取Token使用统计
    const statsResponse = await http.get(`/tokens/${token.id}/stats`)
    if (statsResponse.success) {
      // 合并统计数据到token对象
      currentToken.value = {
        ...token,
        ...statsResponse.data
      }
    } else {
      currentToken.value = token
    }
    
    // 重置分页
    usageHistoryPagination.page = 1
    
    // 获取使用历史
    await fetchTokenUsageHistory(token.id)
    
    tokenUsageDialogVisible.value = true
  } catch (error) {
    console.error('获取Token使用统计失败:', error)
    ElMessage.error('获取Token使用统计失败')
    // 即使获取统计失败，也显示对话框
    currentToken.value = token
    tokenUsageDialogVisible.value = true
  }
}

// HTTP方法标签类型
const getMethodTagType = (method: string) => {
  const methodMap: Record<string, string> = {
    'GET': 'success',
    'POST': 'primary',
    'PUT': 'warning',
    'DELETE': 'danger',
    'PATCH': 'info'
  }
  return methodMap[method] || 'info'
}

// 状态码标签类型
const getStatusTagType = (statusCode: number) => {
  if (statusCode >= 200 && statusCode < 300) return 'success'
  if (statusCode >= 300 && statusCode < 400) return 'info'
  if (statusCode >= 400 && statusCode < 500) return 'warning'
  if (statusCode >= 500) return 'danger'
  return 'info'
}

const showFullToken = async (token: any) => {
  try {
    await ElMessageBox.alert(
      `完整Token: ${token.token}`,
      `Token: ${token.name}`,
      {
        confirmButtonText: '关闭',
        type: 'info'
      }
    )
  } catch (error) {
    // 用户取消
  }
}

// 批量操作方法
const handleBatchDisable = async () => {
  try {
    await ElMessageBox.confirm(
      `确定要禁用选中的 ${selectedTokens.value.length} 个Token吗？`,
      '批量禁用',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    const tokenIds = selectedTokens.value.map(token => token.id)
    await http.put('/tokens/batch/disable', { token_ids: tokenIds })
    ElMessage.success('批量禁用成功')
    selectedTokens.value = []
    await fetchTokens()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('批量禁用失败')
    }
  }
}

const handleBatchEnable = async () => {
  try {
    const tokenIds = selectedTokens.value.map(token => token.id)
    await http.put('/tokens/batch/enable', { token_ids: tokenIds })
    ElMessage.success('批量启用成功')
    selectedTokens.value = []
    await fetchTokens()
  } catch (error) {
    ElMessage.error('批量启用失败')
  }
}

const handleBatchRevoke = async () => {
  try {
    await ElMessageBox.confirm(
      `确定要撤销选中的 ${selectedTokens.value.length} 个Token吗？此操作不可恢复！`,
      '批量撤销',
      {
        confirmButtonText: '确定撤销',
        cancelButtonText: '取消',
        type: 'error'
      }
    )
    
    const tokenIds = selectedTokens.value.map(token => token.id)
    await http.delete('/tokens/batch', { data: { token_ids: tokenIds } })
    ElMessage.success('批量撤销成功')
    selectedTokens.value = []
    await fetchTokens()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('批量撤销失败')
    }
  }
}

// Token状态和时间相关工具函数
const isTokenExpiringSoon = (expiresAt: string) => {
  if (!expiresAt) return false
  const expiry = new Date(expiresAt)
  const now = new Date()
  const diffDays = Math.ceil((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
  return diffDays <= 7 && diffDays > 0
}

const getExpiryCountdown = (expiresAt: string) => {
  if (!expiresAt) return ''
  const expiry = new Date(expiresAt)
  const now = new Date()
  const diffMs = expiry.getTime() - now.getTime()
  
  if (diffMs <= 0) return '已过期'
  
  const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24))
  if (diffDays <= 1) {
    const diffHours = Math.ceil(diffMs / (1000 * 60 * 60))
    return `${diffHours}小时后过期`
  }
  return `${diffDays}天后过期`
}

// Token保存方法
const handleSaveToken = async () => {
  try {
    await tokenFormRef.value?.validate()
    
    tokenLoading.value = true
    
    const tokenData = {
      name: tokenForm.name,
      user_id: tokenForm.user_id,
      scope: tokenForm.scope,
      expires_in: tokenForm.expires_in,
      description: tokenForm.description
    }
    
    let response
    if (currentToken.value) {
      // 更新Token
      response = await http.put(`/tokens/${currentToken.value.id}`, tokenData)
    } else {
      // 创建Token
      response = await http.post('/tokens', tokenData)
    }
    
    if (response.success) {
      ElMessage.success(currentToken.value ? 'Token更新成功' : 'Token创建成功')
      
      // 如果是新创建的Token，显示Token值
      if (!currentToken.value && response.data.token) {
        await ElMessageBox.alert(
          `Token已创建成功！请妥善保存以下Token，它只会显示一次：\n\n${response.data.token}`,
          'Token创建成功',
          {
            confirmButtonText: '我已复制保存',
            type: 'success'
          }
        )
      }
      
      tokenDialogVisible.value = false
      currentToken.value = null
      await fetchTokens()
    }
  } catch (error) {
    if (error !== 'validation failed') {
      ElMessage.error(currentToken.value ? 'Token更新失败' : 'Token创建失败')
    }
  } finally {
    tokenLoading.value = false
  }
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
const fetchSystemStats = async () => {
  try {
    const response = await http.get('/system/stats')
    if (response.success) {
      configStats.value = response.data.config_stats || { total: 0 }
      announcementStats.value = response.data.announcement_stats || { active: 0 }
      logStats.value = response.data.log_stats || { today: 0 }
      // 可以在这里更新其他统计信息
    }
  } catch (error) {
    console.error('获取系统统计信息失败:', error)
    // 不显示错误消息，因为这不是关键功能
  }
}

const refreshAll = async () => {
  loading.value = true
  try {
    await Promise.all([
      refreshHealth(),
      fetchConfigs(),
      refreshConnectionInfo(),
      fetchTokens(),
      fetchAllUsers(),
      fetchSystemStats()
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

// 公告管理相关方法
const resetAnnouncementForm = () => {
  Object.assign(announcementForm, {
    id: null,
    title: '',
    type: 'info',
    priority: 1,
    content: '',
    startTime: null,
    endTime: null,
    is_active: true,
    is_sticky: false
  })
}

const handleCreateAnnouncement = () => {
  isEditAnnouncement.value = false
  resetAnnouncementForm()
  announcementDialogVisible.value = true
}

const handleEditAnnouncement = (row) => {
  isEditAnnouncement.value = true
  Object.assign(announcementForm, {
    id: row.id,
    title: row.title,
    type: row.type,
    priority: row.priority,
    content: row.content,
    startTime: row.start_time ? new Date(row.start_time) : null,
    endTime: row.end_time ? new Date(row.end_time) : null,
    is_active: row.is_active,
    is_sticky: row.is_sticky
  })
  announcementDialogVisible.value = true
}

const handleSaveAnnouncement = async () => {
  try {
    await announcementFormRef.value.validate()
    announcementSubmitting.value = true
    
    const data = {
      title: announcementForm.title,
      type: announcementForm.type,
      priority: announcementForm.priority,
      content: announcementForm.content,
      is_active: announcementForm.is_active,
      is_sticky: announcementForm.is_sticky,
      target_users: [],
      start_time: announcementForm.startTime ? announcementForm.startTime.toISOString() : null,
      end_time: announcementForm.endTime ? announcementForm.endTime.toISOString() : null
    }
    
    if (isEditAnnouncement.value) {
      const response = await http.put(`/announcements/${announcementForm.id}`, data)
      if (response.success) {
        ElMessage.success('公告更新成功')
      } else {
        ElMessage.error(response.message || '更新公告失败')
      }
    } else {
      const response = await http.post('/announcements', data)
      if (response.success) {
        ElMessage.success('公告发布成功')
      } else {
        ElMessage.error(response.message || '发布公告失败')
      }
    }
    
    announcementDialogVisible.value = false
    await fetchAnnouncements()
  } catch (error) {
    console.error('保存公告失败:', error)
    ElMessage.error('保存公告失败')
  } finally {
    announcementSubmitting.value = false
  }
}

const handleViewAnnouncement = (row) => {
  currentAnnouncement.value = row
  announcementViewDialogVisible.value = true
}

const handlePreviewAnnouncement = (row) => {
  currentAnnouncement.value = row
  announcementPreviewDialogVisible.value = true
}

const handleAnnouncementAction = (command, row) => {
  switch (command) {
    case 'view':
      handleViewAnnouncement(row)
      break
    case 'preview':
      handlePreviewAnnouncement(row)
      break
    case 'edit':
      handleEditAnnouncement(row)
      break
    case 'delete':
      handleDeleteAnnouncement(row)
      break
  }
}

const handleTestPublicDisplay = async () => {
  if (!currentAnnouncement.value) return
  
  try {
    // 临时激活公告以便测试，只发送必要的字段
    const testData = {
      title: currentAnnouncement.value.title,
      content: currentAnnouncement.value.content,
      type: currentAnnouncement.value.type,
      priority: currentAnnouncement.value.priority,
      is_active: true,
      is_sticky: currentAnnouncement.value.is_sticky,
      target_users: [], // 空数组表示所有用户
      start_time: new Date().toISOString(),
      end_time: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString() // 24小时后过期
    }
    
    // 更新公告状态
    const response = await http.put(`/announcements/${currentAnnouncement.value.id}`, testData)
    
    if (response.success) {
      ElMessage.success('公告已激活，请刷新页面查看公共显示效果')
      
      // 关闭预览对话框
      announcementPreviewDialogVisible.value = false
      
      // 刷新公告列表
      await fetchAnnouncements()
      
      // 通知公告组件刷新
      setTimeout(() => {
        // 触发公告组件刷新
        const publicAnnouncementsComponent = document.querySelector('.public-announcements')
        if (publicAnnouncementsComponent) {
          // 发送自定义事件通知公告组件刷新
          window.dispatchEvent(new CustomEvent('refreshAnnouncements'))
        }
        
        ElMessageBox.confirm('公告已激活，现在应该能看到弹窗公告了！是否刷新页面？', '提示', {
          confirmButtonText: '刷新页面',
          cancelButtonText: '已经看到了',
          type: 'success'
        }).then(() => {
          window.location.reload()
        }).catch(() => {
          // 用户选择不刷新
        })
      }, 1000)
    } else {
      ElMessage.error(response.message || '激活公告失败')
    }
    
  } catch (error) {
    console.error('测试公共显示失败:', error)
    ElMessage.error('测试公共显示失败')
  }
}

const getAnnouncementTypeTag = (type: string) => {
  const typeMap: Record<string, string> = {
    'info': 'info',
    'warning': 'warning',
    'error': 'danger',
    'maintenance': 'primary'
  }
  return typeMap[type] || 'info'
}

const getAnnouncementTypeText = (type: string) => {
  const textMap: Record<string, string> = {
    'info': '信息',
    'warning': '警告',
    'error': '错误',
    'maintenance': '维护'
  }
  return textMap[type] || type
}

const getPriorityTag = (priority: number) => {
  if (priority >= 8) return 'danger'
  if (priority >= 6) return 'warning'
  if (priority >= 4) return 'primary'
  return 'info'
}

const getPriorityText = (priority: number) => {
  if (priority >= 8) return '紧急'
  if (priority >= 6) return '重要'
  if (priority >= 4) return '普通'
  return '低'
}

// 系统日志相关方法
const fetchLogs = async () => {
  logLoading.value = true
  try {
    const params = {
      page: logPagination.page,
      page_size: logPagination.size,
      level: logSearch.level || undefined,
      category: logSearch.category || undefined,
      ip_address: logSearch.ip_address || undefined,
      start_time: logSearch.timeRange?.[0]?.toISOString(),
      end_time: logSearch.timeRange?.[1]?.toISOString()
    }
    
    // 移除undefined值
    Object.keys(params).forEach(key => {
      if (params[key] === undefined) {
        delete params[key]
      }
    })
    
    const response = await http.get('/logs', { params })
    if (response.success) {
      logs.value = response.data.logs || []
      logPagination.total = response.data.total || 0
      
      // 提取分类
      const categories = [...new Set(logs.value.map(log => log.category).filter(Boolean))]
      allCategories.value = categories
      
      // 不再在这里计算统计信息，改为从API获取
    }
  } catch (error) {
    console.error('获取系统日志失败:', error)
    ElMessage.error('获取系统日志失败')
  } finally {
    logLoading.value = false
  }
}

const handleViewLogDetail = (row) => {
  currentLog.value = row
  logDetailDialogVisible.value = true
}

const handleDeleteSingleLog = async (log) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除这条日志吗？\n\n级别: ${log.level}\n分类: ${log.category}\n时间: ${formatTime(log.created_at)}`,
      '删除确认',
      {
        confirmButtonText: '确定删除',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    logDeleting.value = true
    const response = await http.delete(`/logs/${log.id}`)
    
    if (response.success) {
      ElMessage.success('日志删除成功')
      if (logDetailDialogVisible.value && currentLog.value?.id === log.id) {
        logDetailDialogVisible.value = false
      }
      await fetchLogs()
    } else {
      ElMessage.error(response.message || '删除日志失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除日志失败:', error)
      ElMessage.error('删除日志失败')
    }
  } finally {
    logDeleting.value = false
  }
}

const handleSelectionChange = (selection) => {
  selectedLogs.value = selection
}

const clearSelection = () => {
  logTableRef.value?.clearSelection()
  selectedLogs.value = []
}

const handleBatchDeleteLogs = async () => {
  if (selectedLogs.value.length === 0) {
    ElMessage.warning('请先选择要删除的日志')
    return
  }
  
  try {
    await ElMessageBox.confirm(
      `确定要删除选中的 ${selectedLogs.value.length} 条日志吗？\n\n此操作不可撤销！`,
      '批量删除确认',
      {
        confirmButtonText: '确定删除',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    batchDeleting.value = true
    const logIds = selectedLogs.value.map(log => log.id)
    
    const response = await http.post('/logs/batch-delete', { ids: logIds })
    
    if (response.success) {
      const deletedCount = response.data.deleted_count || logIds.length
      ElMessage.success(`成功删除 ${deletedCount} 条日志`)
      clearSelection()
      await fetchLogs()
    } else {
      ElMessage.error(response.message || '批量删除失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('批量删除日志失败:', error)
      ElMessage.error('批量删除失败')
    }
  } finally {
    batchDeleting.value = false
  }
}

const handleLogAction = async (command) => {
  try {
    let confirmMessage = ''
    let requestData = {}
    
    switch (command) {
      case 'cleanup-filtered':
        const hasFilters = logSearch.level || logSearch.category || logSearch.ip_address || logSearch.timeRange
        if (!hasFilters) {
          ElMessage.warning('请先设置筛选条件')
          return
        }
        confirmMessage = '确定要清理符合当前筛选条件的日志吗？'
        requestData = { cleanup_by_filter: true }
        break
      case 'cleanup-30days':
        confirmMessage = '确定要清理30天前的日志吗？'
        requestData = { retention_days: 30 }
        break
      case 'cleanup-7days':
        confirmMessage = '确定要清理7天前的日志吗？'
        requestData = { retention_days: 7 }
        break
      case 'cleanup-1day':
        confirmMessage = '确定要清理1天前的日志吗？'
        requestData = { retention_days: 1 }
        break
      default:
        return
    }
    
    await ElMessageBox.confirm(confirmMessage, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    const response = await http.post('/logs/cleanup', requestData)
    if (response.success) {
      const deletedCount = response.data.deleted_count || 0
      ElMessage.success(`成功清理 ${deletedCount} 条日志`)
      await fetchLogs()
    } else {
      ElMessage.error(response.message || '清理日志失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('清理日志失败:', error)
      ElMessage.error('清理日志失败')
    }
  }
}

const handleCategoryChange = () => {
  // 分类变更时的处理
}

const refreshCategories = () => {
  // 刷新分类列表
}

const getLogLevelTag = (level) => {
  const typeMap = {
    'debug': 'info',
    'info': 'success',
    'warn': 'warning',
    'error': 'danger',
    'fatal': 'danger'
  }
  return typeMap[level] || 'info'
}

const getUserDisplayName = (row) => {
  return row.user?.username || row.user?.email || `用户${row.user_id}`
}

const getFallbackUserDisplay = (row) => {
  return row.user_id ? `用户${row.user_id}` : '系统'
}

const formatLogContext = (context) => {
  if (!context) return ''
  try {
    if (typeof context === 'string') {
      const parsed = JSON.parse(context)
      return JSON.stringify(parsed, null, 2)
    }
    return JSON.stringify(context, null, 2)
  } catch {
    return context
  }
}

const announcementDialogTitle = computed(() => {
  return isEditAnnouncement.value ? '编辑公告' : '发布公告'
})

// 公告管理相关方法
const fetchAnnouncements = async () => {
  announcementLoading.value = true
  try {
    const params = {
      page: announcementPagination.page,
      page_size: announcementPagination.size,
      type: announcementSearch.type || undefined,
      is_active: announcementSearch.is_active !== '' ? announcementSearch.is_active : undefined
    }
    
    // 移除undefined值
    Object.keys(params).forEach(key => {
      if (params[key] === undefined) {
        delete params[key]
      }
    })
    
    const response = await http.get('/announcements', { params })
    if (response.success) {
      announcements.value = response.data.announcements || []
      announcementPagination.total = response.data.total || 0
      
      // 计算活跃公告数量
      announcementStats.value.active = announcements.value.filter(a => a.is_active).length
    }
  } catch (error) {
    console.error('获取公告列表失败:', error)
    ElMessage.error('获取公告列表失败')
  } finally {
    announcementLoading.value = false
  }
}

const handleDeleteAnnouncement = async (row) => {
  try {
    await ElMessageBox.confirm(`确定要删除公告 "${row.title}" 吗？`, '删除确认', {
      confirmButtonText: '确定删除',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    const response = await http.delete(`/announcements/${row.id}`)
    if (response.success) {
      ElMessage.success('公告删除成功')
      await fetchAnnouncements()
    } else {
      ElMessage.error(response.message || '删除公告失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除公告失败:', error)
      ElMessage.error('删除公告失败')
    }
  }
}

// 生命周期
onMounted(() => {
  refreshAll()
  fetchLogs()
  fetchAnnouncements()
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
  justify-content: center;
}

/* 公告预览对话框样式 */
.announcement-preview-dialog .announcement-preview {
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  padding: 20px;
  background: #fafafa;
}

.preview-header {
  margin-bottom: 16px;
}

.preview-title {
  display: flex;
  align-items: center;
  font-size: 18px;
  font-weight: 600;
  color: #303133;
  margin-bottom: 8px;
}

.preview-icon {
  margin-right: 8px;
  font-size: 20px;
}

.preview-icon.warning {
  color: #e6a23c;
}

.preview-icon.error {
  color: #f56c6c;
}

.preview-icon.maintenance {
  color: #409eff;
}

.preview-icon.info {
  color: #909399;
}

.preview-meta {
  display: flex;
  align-items: center;
  gap: 12px;
}

.preview-time {
  font-size: 12px;
  color: #909399;
}

.preview-content {
  line-height: 1.6;
  color: #606266;
  margin: 16px 0;
}

.preview-footer {
  text-align: center;
  margin-top: 16px;
}

.text-muted {
  color: #909399;
}
</style>/* T
oken管理样式 */
.tokens-section {
  padding: 20px;
}

.token-stats {
  background: #f8f9fa;
  padding: 16px;
  border-radius: 8px;
  margin-bottom: 16px;
}

.token-name {
  display: flex;
  align-items: center;
}

.token-display {
  display: flex;
  align-items: center;
  gap: 8px;
}

.token-preview {
  font-family: 'Courier New', monospace;
  font-size: 12px;
  color: #666;
}

.token-status {
  display: flex;
  align-items: center;
  gap: 8px;
}

.status-indicator {
  display: flex;
  align-items: center;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: #67c23a;
  animation: pulse 2s infinite;
}

.status-dot.active {
  background-color: #67c23a;
}

@keyframes pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(103, 194, 58, 0.7);
  }
  70% {
    box-shadow: 0 0 0 10px rgba(103, 194, 58, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(103, 194, 58, 0);
  }
}

.usage-info {
  text-align: center;
}

.usage-count {
  font-weight: 600;
  color: #409eff;
}

.last-used {
  font-size: 12px;
  color: #999;
  margin-top: 4px;
}

.expiry-info {
  text-align: center;
}

.expiry-countdown {
  font-size: 12px;
  color: #e6a23c;
  margin-top: 4px;
}

.text-danger {
  color: #f56c6c !important;
}

.text-warning {
  color: #e6a23c !important;
}

.action-buttons {
  display: flex;
  gap: 4px;
  justify-content: center;
  flex-wrap: wrap;
}

.batch-actions {
  margin-top: 10px;
}

.batch-buttons {
  display: flex;
  gap: 8px;
  margin-top: 8px;
}

.user-info {
  line-height: 1.4;
}

.user-email {
  font-size: 12px;
  color: #999;
}

.token-value {
  width: 100%;
}

.usage-stats {
  padding: 16px;
}

.usage-history {
  min-height: 200px;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .tokens-section {
    padding: 10px;
  }
  
  .action-buttons {
    flex-direction: column;
  }
  
  .batch-buttons {
    flex-direction: column;
  }
  
  .token-stats .el-col {
    margin-bottom: 16px;
  }
}
