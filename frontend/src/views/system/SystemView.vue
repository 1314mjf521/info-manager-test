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
            <div class="section-header">
              <h3>系统配置管理</h3>
              <div class="header-actions">
                <el-button @click="handleCreateConfig" type="primary" size="small">
                  <el-icon><Plus /></el-icon>
                  新增配置
                </el-button>
              </div>
            </div>

            <!-- 配置搜索 -->
            <div class="search-bar">
              <el-form :model="configSearch" inline>
                <el-form-item label="分类">
                  <el-select v-model="configSearch.category" placeholder="选择分类" clearable style="width: 150px;">
                    <el-option label="全部" value="" />
                    <el-option label="系统" value="system" />
                    <el-option label="数据库" value="database" />
                    <el-option label="缓存" value="cache" />
                    <el-option label="邮件" value="email" />
                  </el-select>
                </el-form-item>
                <el-form-item label="公开">
                  <el-select v-model="configSearch.is_public" placeholder="选择类型" clearable style="width: 120px;">
                    <el-option label="全部" value="" />
                    <el-option label="公开" :value="true" />
                    <el-option label="私有" :value="false" />
                  </el-select>
                </el-form-item>
                <el-form-item>
                  <el-button @click="fetchConfigs" :loading="configLoading">搜索</el-button>
                </el-form-item>
              </el-form>
            </div>

            <el-table :data="configs" v-loading="configLoading">
              <el-table-column prop="category" label="分类" width="100" />
              <el-table-column prop="key" label="键" width="200" show-overflow-tooltip />
              <el-table-column prop="description" label="描述" show-overflow-tooltip />
              <el-table-column label="公开" width="80" align="center">
                <template #default="{ row }">
                  <el-tag :type="row.is_public ? 'success' : 'info'" size="small">
                    {{ row.is_public ? '是' : '否' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="updated_at" label="更新时间" width="160" align="center">
                <template #default="{ row }">
                  {{ formatTime(row.updated_at) }}
                </template>
              </el-table-column>
              <el-table-column label="操作" width="150" fixed="right" align="center">
                <template #default="{ row }">
                  <el-button size="small" @click="handleEditConfig(row)">编辑</el-button>
                  <el-button size="small" type="danger" @click="handleDeleteConfig(row)">删除</el-button>
                </template>
              </el-table-column>
            </el-table>

            <!-- 分页 -->
            <div class="pagination">
              <el-pagination
                v-model:current-page="configPagination.page"
                v-model:page-size="configPagination.size"
                :total="configPagination.total"
                :page-sizes="[10, 20, 50]"
                layout="total, sizes, prev, pager, next, jumper"
                @size-change="fetchConfigs"
                @current-change="fetchConfigs"
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
              <el-table-column label="优先级" width="100" align="center">
                <template #default="{ row }">
                  <el-tag :type="getPriorityTag(row.priority)" size="small">
                    {{ getPriorityText(row.priority) }}
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
              <el-table-column label="操作" width="320" fixed="right" align="center">
                <template #default="{ row }">
                  <div class="action-buttons">
                    <el-button size="small" @click="handleViewAnnouncement(row)">查看</el-button>
                    <el-button size="small" type="info" @click="handlePreviewAnnouncement(row)">预览</el-button>
                    <el-button size="small" @click="handleEditAnnouncement(row)">编辑</el-button>
                    <el-button size="small" type="danger" @click="handleDeleteAnnouncement(row)">删除</el-button>
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

    <!-- 配置编辑对话框 -->
    <el-dialog v-model="configDialogVisible" :title="configDialogTitle" width="600px">
      <el-form ref="configFormRef" :model="configForm" :rules="configRules" label-width="100px">
        <el-form-item label="分类" prop="category">
          <el-input v-model="configForm.category" placeholder="请输入配置分类" :disabled="isEditConfig" />
        </el-form-item>
        <el-form-item label="键" prop="key">
          <el-input v-model="configForm.key" placeholder="请输入配置键" :disabled="isEditConfig" />
        </el-form-item>
        <el-form-item label="值" prop="value">
          <el-input v-model="configForm.value" type="textarea" :rows="3" placeholder="请输入配置值" />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="configForm.description" placeholder="请输入配置描述" />
        </el-form-item>
        <el-form-item label="公开">
          <el-switch v-model="configForm.isPublic" />
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="configDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSaveConfig" :loading="configSubmitting">
            {{ isEditConfig ? '更新' : '创建' }}
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 公告编辑对话框 -->
    <el-dialog v-model="announcementDialogVisible" :title="announcementDialogTitle" width="800px">
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
        <el-form-item label="生效时间" prop="startTime">
          <el-date-picker
            v-model="announcementForm.startTime"
            type="datetime"
            placeholder="选择生效时间"
            style="width: 100%;"
          />
        </el-form-item>
        <el-form-item label="失效时间" prop="endTime">
          <el-date-picker
            v-model="announcementForm.endTime"
            type="datetime"
            placeholder="选择失效时间"
            style="width: 100%;"
          />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="announcementForm.is_active" />
        </el-form-item>
        <el-form-item label="置顶">
          <el-switch v-model="announcementForm.is_sticky" />
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
    <el-dialog v-model="logDetailDialogVisible" title="日志详情" width="900px" class="log-detail-dialog">
      <div v-if="currentLog">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="级别">
            <el-tag :type="getLogLevelTag(currentLog.level)" size="small">
              {{ currentLog.level.toUpperCase() }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="分类">{{ currentLog.category }}</el-descriptions-item>
          <el-descriptions-item label="用户">
            <span v-if="currentLog.user_id">
              {{ getUserDisplayName(currentLog) }}
              <el-tag size="small" type="info" style="margin-left: 8px;">ID: {{ currentLog.user_id }}</el-tag>
            </span>
            <span v-else>
              {{ getFallbackUserDisplay(currentLog) }}
            </span>
          </el-descriptions-item>
          <el-descriptions-item label="IP地址">
            <span class="log-detail-text">{{ currentLog.ip_address || '-' }}</span>
          </el-descriptions-item>
          <el-descriptions-item label="用户代理" :span="2">
            <div class="log-detail-text-container">
              <el-tooltip :content="currentLog.user_agent || '-'" placement="top" :disabled="!currentLog.user_agent">
                <span class="log-detail-text">{{ currentLog.user_agent || '-' }}</span>
              </el-tooltip>
            </div>
          </el-descriptions-item>
          <el-descriptions-item label="请求ID">
            <span class="log-detail-text">{{ currentLog.request_id || '-' }}</span>
          </el-descriptions-item>
          <el-descriptions-item label="时间">{{ formatTime(currentLog.created_at) }}</el-descriptions-item>
          <el-descriptions-item label="消息" :span="2">
            <div class="log-detail-message">
              <el-input
                v-model="currentLog.message"
                type="textarea"
                :rows="3"
                readonly
                resize="none"
              />
            </div>
          </el-descriptions-item>
          <el-descriptions-item label="上下文" :span="2">
            <div class="log-detail-context">
              <el-input
                :value="formatLogContext(currentLog.context)"
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
          <el-button @click="logDetailDialogVisible = false">关闭</el-button>
          <el-button type="danger" @click="handleDeleteSingleLog(currentLog)" :loading="logDeleting">
            <el-icon><Delete /></el-icon>
            删除此日志
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Refresh, Monitor, Setting, Bell, Document, Delete, ArrowDown } from '@element-plus/icons-vue'
import { http } from '@/utils/request'
import { useAuthStore } from '@/stores/auth'
import dayjs from 'dayjs'

// 响应式数据
const loading = ref(false)
const activeTab = ref('health')

// 认证信息
const authStore = useAuthStore()

// 系统健康相关
const healthLoading = ref(false)
const systemHealth = ref({
  status: 'healthy',
  components: []
})

// 系统配置相关
const configLoading = ref(false)
const configSubmitting = ref(false)
const configs = ref([])
const configDialogVisible = ref(false)
const configFormRef = ref()
const isEditConfig = ref(false)

const configSearch = reactive({
  category: '',
  is_public: ''
})

const configPagination = reactive({
  page: 1,
  size: 20,
  total: 0
})

const configForm = reactive({
  category: '',
  key: '',
  value: '',
  description: '',
  isPublic: false
})

const configRules = {
  category: [{ required: true, message: '请输入配置分类', trigger: 'blur' }],
  key: [{ required: true, message: '请输入配置键', trigger: 'blur' }],
  value: [{ required: true, message: '请输入配置值', trigger: 'blur' }],
  description: [{ required: true, message: '请输入配置描述', trigger: 'blur' }]
}

// 公告管理相关
const announcementLoading = ref(false)
const announcementSubmitting = ref(false)
const announcements = ref([])
const announcementDialogVisible = ref(false)
const announcementViewDialogVisible = ref(false)
const announcementPreviewDialogVisible = ref(false)
const announcementFormRef = ref()
const isEditAnnouncement = ref(false)
const currentAnnouncement = ref(null)

const announcementSearch = reactive({
  type: '',
  is_active: ''
})

const announcementPagination = reactive({
  page: 1,
  size: 20,
  total: 0
})

const announcementForm = reactive({
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
  priority: [{ required: true, message: '请选择优先级', trigger: 'change' }],
  content: [{ required: true, message: '请输入公告内容', trigger: 'blur' }]
}

// 系统日志相关
const logLoading = ref(false)
const logs = ref([])
const logDetailDialogVisible = ref(false)
const currentLog = ref(null)
const logDeleting = ref(false)
const batchDeleting = ref(false)
const selectedLogs = ref([])
const logTableRef = ref()

const logSearch = reactive({
  level: '',
  category: '',
  ip_address: '',
  timeRange: []
})

// 动态分类管理
const allCategories = ref([])
const categorySet = ref(new Set())

// 用户信息缓存
const userCache = ref(new Map())
const currentUser = computed(() => authStore.user)

const logPagination = reactive({
  page: 1,
  size: 20,
  total: 0
})

// 统计数据
const configStats = ref({ total: 0 })
const announcementStats = ref({ active: 0 })
const logStats = ref({ today: 0 })

// 计算属性
const configDialogTitle = computed(() => isEditConfig.value ? '编辑配置' : '新增配置')
const announcementDialogTitle = computed(() => isEditAnnouncement.value ? '编辑公告' : '发布公告')

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
    const params = {
      page: configPagination.page,
      page_size: configPagination.size,
      ...configSearch
    }
    
    const response = await http.get('/config', { params })
    if (response.success) {
      configs.value = response.data.configs || []
      configPagination.total = response.data.total || 0
      configStats.value.total = response.data.total || 0
    }
  } catch (error) {
    console.error('获取系统配置失败:', error)
    ElMessage.error('获取系统配置失败')
  } finally {
    configLoading.value = false
  }
}

const handleCreateConfig = () => {
  isEditConfig.value = false
  resetConfigForm()
  configDialogVisible.value = true
}

const handleEditConfig = (row: any) => {
  isEditConfig.value = true
  Object.assign(configForm, {
    category: row.category,
    key: row.key,
    value: row.value,
    description: row.description,
    isPublic: row.is_public
  })
  configDialogVisible.value = true
}

const handleSaveConfig = async () => {
  try {
    await configFormRef.value.validate()
    configSubmitting.value = true
    
    if (isEditConfig.value) {
      await http.put(`/config/${configForm.category}/${configForm.key}`, {
        value: configForm.value,
        description: configForm.description,
        is_public: configForm.isPublic
      })
      ElMessage.success('配置更新成功')
    } else {
      await http.post('/config', {
        category: configForm.category,
        key: configForm.key,
        value: configForm.value,
        description: configForm.description,
        is_public: configForm.isPublic
      })
      ElMessage.success('配置创建成功')
    }
    
    configDialogVisible.value = false
    fetchConfigs()
  } catch (error) {
    console.error('保存配置失败:', error)
    ElMessage.error('保存配置失败')
  } finally {
    configSubmitting.value = false
  }
}

const handleDeleteConfig = async (row: any) => {
  try {
    await ElMessageBox.confirm(`确定要删除配置 ${row.category}.${row.key} 吗？`, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await http.delete(`/config/${row.category}/${row.key}`)
    ElMessage.success('配置删除成功')
    fetchConfigs()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除配置失败:', error)
      ElMessage.error('删除配置失败')
    }
  }
}

// 公告管理相关方法
const fetchAnnouncements = async () => {
  announcementLoading.value = true
  try {
    const params = {
      page: announcementPagination.page,
      page_size: announcementPagination.size,
      ...announcementSearch
    }
    
    const response = await http.get('/announcements', { params })
    if (response.success) {
      announcements.value = response.data.announcements || []
      announcementPagination.total = response.data.total || 0
      announcementStats.value.active = response.data.announcements?.filter((item: any) => item.is_active).length || 0
    }
  } catch (error) {
    console.error('获取公告列表失败:', error)
    ElMessage.error('获取公告列表失败')
  } finally {
    announcementLoading.value = false
  }
}

const handleCreateAnnouncement = () => {
  isEditAnnouncement.value = false
  resetAnnouncementForm()
  announcementDialogVisible.value = true
}

const handleEditAnnouncement = (row: any) => {
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
      target_users: [], // 空数组表示所有用户
      start_time: announcementForm.startTime ? announcementForm.startTime.toISOString() : null,
      end_time: announcementForm.endTime ? announcementForm.endTime.toISOString() : null
    }
    
    if (isEditAnnouncement.value) {
      await http.put(`/announcements/${announcementForm.id}`, data)
      ElMessage.success('公告更新成功')
    } else {
      await http.post('/announcements', data)
      ElMessage.success('公告发布成功')
    }
    
    announcementDialogVisible.value = false
    fetchAnnouncements()
  } catch (error) {
    console.error('保存公告失败:', error)
    ElMessage.error('保存公告失败')
  } finally {
    announcementSubmitting.value = false
  }
}

const handleDeleteAnnouncement = async (row: any) => {
  try {
    await ElMessageBox.confirm(`确定要删除公告 "${row.title}" 吗？`, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await http.delete(`/announcements/${row.id}`)
    ElMessage.success('公告删除成功')
    fetchAnnouncements()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除公告失败:', error)
      ElMessage.error('删除公告失败')
    }
  }
}

const handleViewAnnouncement = (row: any) => {
  currentAnnouncement.value = row
  announcementViewDialogVisible.value = true
}

const handlePreviewAnnouncement = (row: any) => {
  currentAnnouncement.value = row
  announcementPreviewDialogVisible.value = true
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
    await http.put(`/announcements/${currentAnnouncement.value.id}`, testData)
    
    ElMessage.success('公告已激活，请刷新页面查看公共显示效果')
    
    // 关闭预览对话框
    announcementPreviewDialogVisible.value = false
    
    // 刷新公告列表
    fetchAnnouncements()
    
    // 提示用户刷新页面
    setTimeout(() => {
      ElMessageBox.confirm('公告已激活，是否刷新页面查看效果？', '提示', {
        confirmButtonText: '刷新页面',
        cancelButtonText: '稍后查看',
        type: 'info'
      }).then(() => {
        window.location.reload()
      }).catch(() => {
        // 用户选择稍后查看
      })
    }, 1000)
    
  } catch (error) {
    console.error('测试公共显示失败:', error)
    ElMessage.error('测试公共显示失败')
  }
}

// 动态分类管理方法
const handleCategoryChange = (value: string) => {
  if (value && value !== '') {
    categorySet.value.add(value)
    updateAllCategories()
  }
}

const updateAllCategories = () => {
  allCategories.value = Array.from(categorySet.value).sort()
}

const extractCategoriesFromLogs = (logs: any[]) => {
  logs.forEach(log => {
    if (log.category && log.category.trim() !== '') {
      categorySet.value.add(log.category)
    }
  })
  updateAllCategories()
}

// 刷新分类列表
const refreshCategories = async () => {
  try {
    // 获取更多日志来提取分类
    const response = await http.get('/logs', { 
      params: { 
        page: 1, 
        page_size: 500  // 获取更多数据来提取分类
      } 
    })
    
    if (response.success && response.data.logs) {
      extractCategoriesFromLogs(response.data.logs)
    }
  } catch (error) {
    console.warn('刷新分类信息失败:', error)
  }
}

// 获取所有可用的分类
const fetchAllCategories = async () => {
  await refreshCategories()
}

// 用户信息处理方法
const getUserDisplayName = (logItem: any) => {
  if (!logItem.user_id) return '-'
  
  // 如果日志中已经包含用户信息
  if (logItem.user && logItem.user.username) {
    return logItem.user.username
  }
  
  // 从缓存中获取用户信息
  if (userCache.value.has(logItem.user_id)) {
    const cachedUser = userCache.value.get(logItem.user_id)
    return cachedUser.username || `用户${logItem.user_id}`
  }
  
  // 异步获取用户信息
  fetchUserInfo(logItem.user_id)
  
  return `用户${logItem.user_id}`
}

// 回退用户显示方法
const getFallbackUserDisplay = (logItem: any) => {
  // 判断是否为系统日志
  if (isSystemLog(logItem)) {
    return 'system'
  }
  
  // 如果有IP地址且是当前用户的IP，显示当前用户
  if (currentUser.value && isCurrentUserLog(logItem)) {
    return currentUser.value.username || 'current'
  }
  
  // 根据日志类型判断
  if (logItem.category === 'system' || logItem.category === 'health' || logItem.category === 'monitor') {
    return 'system'
  }
  
  // 如果有IP地址，显示IP
  if (logItem.ip_address && logItem.ip_address !== '::1' && logItem.ip_address !== '127.0.0.1') {
    return logItem.ip_address
  }
  
  // 默认显示当前用户或system
  return currentUser.value ? currentUser.value.username : 'system'
}

// 判断是否为系统日志
const isSystemLog = (logItem: any) => {
  const systemCategories = ['system', 'health', 'monitor', 'backup', 'cron', 'database']
  return systemCategories.includes(logItem.category)
}

// 判断是否为当前用户的日志
const isCurrentUserLog = (logItem: any) => {
  if (!currentUser.value) return false
  
  // 如果IP地址是本地地址，可能是当前用户
  const localIPs = ['::1', '127.0.0.1', 'localhost']
  return localIPs.includes(logItem.ip_address)
}

const fetchUserInfo = async (userId: number) => {
  if (userCache.value.has(userId)) return
  
  try {
    const response = await http.get(`/users/${userId}`)
    if (response.success && response.data) {
      userCache.value.set(userId, response.data)
    } else {
      // 如果获取失败，缓存一个默认值避免重复请求
      userCache.value.set(userId, { username: `用户${userId}` })
    }
  } catch (error) {
    console.warn(`获取用户${userId}信息失败:`, error)
    // 缓存一个默认值避免重复请求
    userCache.value.set(userId, { username: `用户${userId}` })
  }
}

// 批量获取用户信息
const fetchUsersInfo = async (userIds: number[]) => {
  const uniqueUserIds = [...new Set(userIds)].filter(id => !userCache.value.has(id))
  
  if (uniqueUserIds.length === 0) return
  
  try {
    // 尝试批量获取用户信息
    const response = await http.post('/users/batch', { ids: uniqueUserIds })
    if (response.success && response.data) {
      response.data.forEach((user: any) => {
        userCache.value.set(user.id, user)
      })
    }
  } catch (error) {
    console.warn('批量获取用户信息失败，尝试逐个获取:', error)
    // 如果批量获取失败，逐个获取
    for (const userId of uniqueUserIds) {
      await fetchUserInfo(userId)
    }
  }
}

// 系统日志相关方法
const fetchLogs = async () => {
  logLoading.value = true
  try {
    const params: any = {
      page: logPagination.page,
      page_size: logPagination.size
    }
    
    // 添加筛选条件（只有非空值才添加）
    if (logSearch.level) {
      params.level = logSearch.level
    }
    if (logSearch.category) {
      params.category = logSearch.category
    }
    if (logSearch.ip_address) {
      params.ip_address = logSearch.ip_address
    }
    
    // 处理时间范围
    if (logSearch.timeRange && logSearch.timeRange.length === 2) {
      params.start_time = logSearch.timeRange[0].toISOString()
      params.end_time = logSearch.timeRange[1].toISOString()
    }
    
    const response = await http.get('/logs', { params })
    if (response.success) {
      logs.value = response.data.logs || response.data.items || []
      logPagination.total = response.data.total || 0
      
      // 提取动态分类
      extractCategoriesFromLogs(logs.value)
      
      // 批量获取用户信息
      const userIds = logs.value
        .filter((log: any) => log.user_id && !log.user?.username)
        .map((log: any) => log.user_id)
      
      if (userIds.length > 0) {
        await fetchUsersInfo(userIds)
      }
      
      // 计算今日日志数量
      const today = dayjs().format('YYYY-MM-DD')
      logStats.value.today = logs.value.filter((log: any) => 
        dayjs(log.created_at).format('YYYY-MM-DD') === today
      ).length
    } else {
      ElMessage.error(response.message || '获取系统日志失败')
    }
  } catch (error: any) {
    console.error('获取系统日志失败:', error)
    ElMessage.error(`获取系统日志失败: ${error.response?.data?.message || error.message || '未知错误'}`)
  } finally {
    logLoading.value = false
  }
}

const handleViewLogDetail = (row: any) => {
  currentLog.value = row
  logDetailDialogVisible.value = true
}

// 单条日志删除
const handleDeleteSingleLog = async (log: any) => {
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
    
    try {
      const response = await http.delete(`/logs/${log.id}`)
      
      if (response.success) {
        ElMessage.success(response.message || '日志删除成功')
        // 关闭详情对话框（如果是从详情页删除的）
        if (logDetailDialogVisible.value && currentLog.value?.id === log.id) {
          logDetailDialogVisible.value = false
        }
        // 刷新日志列表
        await fetchLogs()
      } else {
        ElMessage.error(response.message || '删除日志失败')
      }
    } catch (apiError: any) {
      console.error('删除日志API错误:', apiError)
      
      // 检查具体的错误类型
      if (apiError.response?.status === 404) {
        ElMessage.error('日志不存在或已被删除')
      } else if (apiError.response?.status === 403) {
        ElMessage.error('没有权限删除此日志')
      } else if (apiError.response?.status === 400) {
        ElMessage.error(apiError.response?.data?.message || '请求参数错误')
      } else {
        ElMessage.error(`删除日志失败: ${apiError.response?.data?.message || apiError.message || '未知错误'}`)
      }
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除日志失败:', error)
    }
  } finally {
    logDeleting.value = false
  }
}

// 批量选择处理
const handleSelectionChange = (selection: any[]) => {
  selectedLogs.value = selection
}

// 清空选择
const clearSelection = () => {
  logTableRef.value?.clearSelection()
  selectedLogs.value = []
}

// 批量删除日志
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
    
    try {
      // 调用批量删除API
      const response = await http.post('/logs/batch-delete', { ids: logIds })
      
      if (response.success) {
        const deletedCount = response.data.deleted_count || response.data.deletedCount || logIds.length
        ElMessage.success(response.message || `成功删除 ${deletedCount} 条日志`)
        clearSelection()
        await fetchLogs()
      } else {
        ElMessage.error(response.message || '批量删除失败')
      }
    } catch (apiError: any) {
      console.error('批量删除API错误:', apiError)
      
      // 检查具体的错误类型
      if (apiError.response?.status === 400) {
        const errorMsg = apiError.response?.data?.message || '请求参数错误'
        ElMessage.error(`批量删除失败: ${errorMsg}`)
      } else if (apiError.response?.status === 403) {
        ElMessage.error('没有权限执行批量删除操作')
      } else if (apiError.response?.status === 404) {
        ElMessage.error('批量删除接口不存在，请联系管理员')
      } else {
        // 如果批量删除API出现其他错误，尝试逐个删除（作为备选方案）
        ElMessage.info('批量删除失败，正在尝试逐个删除...')
        
        let deletedCount = 0
        let failedCount = 0
        
        for (const log of selectedLogs.value) {
          try {
            const singleResponse = await http.delete(`/logs/${log.id}`)
            if (singleResponse.success) {
              deletedCount++
            } else {
              failedCount++
            }
          } catch (deleteError) {
            failedCount++
            console.warn(`删除日志 ${log.id} 失败:`, deleteError)
          }
        }
        
        if (deletedCount > 0) {
          ElMessage.success(`成功删除 ${deletedCount} 条日志${failedCount > 0 ? `，${failedCount} 条删除失败` : ''}`)
          clearSelection()
          await fetchLogs()
        } else {
          ElMessage.error('所有日志删除失败')
        }
      }
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('批量删除日志失败:', error)
    }
  } finally {
    batchDeleting.value = false
  }
}

const handleLogAction = async (command: string) => {
  try {
    let confirmMessage = ''
    let requestData: any = {}
    
    switch (command) {
      case 'cleanup-filtered':
        // 检查是否有任何筛选条件
        const hasLevel = logSearch.level && logSearch.level.trim() !== ''
        const hasCategory = logSearch.category && logSearch.category.trim() !== ''
        const hasIpAddress = logSearch.ip_address && logSearch.ip_address.trim() !== ''
        const hasTimeRange = logSearch.timeRange && logSearch.timeRange.length === 2
        
        if (!hasLevel && !hasCategory && !hasIpAddress && !hasTimeRange) {
          ElMessage.warning('请先设置筛选条件（级别、分类、IP地址或时间范围）')
          return
        }
        
        // 构建筛选条件描述
        const filterDescriptions = []
        if (hasLevel) filterDescriptions.push(`级别: ${logSearch.level}`)
        if (hasCategory) filterDescriptions.push(`分类: ${logSearch.category}`)
        if (hasIpAddress) filterDescriptions.push(`IP地址: ${logSearch.ip_address}`)
        if (hasTimeRange) {
          const startTime = formatTime(logSearch.timeRange[0])
          const endTime = formatTime(logSearch.timeRange[1])
          filterDescriptions.push(`时间范围: ${startTime} 至 ${endTime}`)
        }
        
        confirmMessage = `确定要清理符合以下筛选条件的日志吗？\n\n筛选条件:\n${filterDescriptions.join('\n')}`
        
        // 构建请求参数（使用当前筛选条件）
        requestData = {
          cleanup_by_filter: true
        }
        
        if (hasLevel) requestData.level = logSearch.level
        if (hasCategory) requestData.category = logSearch.category
        if (hasIpAddress) requestData.ip_address = logSearch.ip_address
        if (hasTimeRange) {
          requestData.start_time = logSearch.timeRange[0].toISOString()
          requestData.end_time = logSearch.timeRange[1].toISOString()
        }
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
    
    // 对于筛选清理，先预览要清理的数量并实现批量删除
    if (command === 'cleanup-filtered') {
      try {
        // 构建预览参数（使用当前筛选条件）
        const previewParams: any = {
          page: 1,
          page_size: 1
        }
        
        // 添加筛选条件
        if (requestData.level) previewParams.level = requestData.level
        if (requestData.category) previewParams.category = requestData.category
        if (requestData.user_id) previewParams.user_id = requestData.user_id
        if (requestData.start_time) previewParams.start_time = requestData.start_time
        if (requestData.end_time) previewParams.end_time = requestData.end_time
        
        // 获取符合条件的日志总数
        const previewResponse = await http.get('/logs', { params: previewParams })
        const totalCount = previewResponse.success ? previewResponse.data.total : 0
        
        if (totalCount === 0) {
          ElMessage.info('没有找到符合筛选条件的日志')
          return
        }
        
        confirmMessage += `\n\n找到 ${totalCount} 条符合条件的日志`
        
        // 确认后执行批量删除
        await ElMessageBox.confirm(confirmMessage, '提示', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning',
          dangerouslyUseHTMLString: false
        })
        
        // 执行批量删除
        ElMessage.info('正在清理日志，请稍候...')
        
        let deletedCount = 0
        let currentPage = 1
        const pageSize = 100 // 每次处理100条
        
        while (true) {
          // 获取当前页的日志
          const batchParams = { ...previewParams }
          batchParams.page = currentPage
          batchParams.page_size = pageSize
          
          const batchResponse = await http.get('/logs', { params: batchParams })
          if (!batchResponse.success || !batchResponse.data.logs || batchResponse.data.logs.length === 0) {
            break
          }
          
          // 提取日志ID
          const logIds = batchResponse.data.logs.map((log: any) => log.id)
          
          // 批量删除这些日志
          try {
            const deleteResponse = await http.post('/logs/batch-delete', { ids: logIds })
            if (deleteResponse.success) {
              deletedCount += deleteResponse.data.deleted_count || logIds.length
            }
          } catch (deleteError) {
            console.warn('批量删除失败，尝试逐个删除:', deleteError)
            // 如果批量删除不支持，尝试逐个删除
            for (const logId of logIds) {
              try {
                const singleDeleteResponse = await http.delete(`/logs/${logId}`)
                if (singleDeleteResponse.success) {
                  deletedCount++
                }
              } catch (singleDeleteError) {
                console.warn(`删除日志 ${logId} 失败:`, singleDeleteError)
              }
            }
          }
          
          currentPage++
          
          // 避免无限循环
          if (currentPage > Math.ceil(totalCount / pageSize)) {
            break
          }
        }
        
        ElMessage.success(`成功清理了 ${deletedCount} 条日志`)
        await fetchLogs()
        return // 直接返回，不执行后面的通用清理逻辑
        
      } catch (error) {
        if (error !== 'cancel') {
          console.error('筛选清理失败:', error)
          ElMessage.error('筛选清理失败')
        }
        return
      }
    }
    
    await ElMessageBox.confirm(confirmMessage, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
      dangerouslyUseHTMLString: false
    })
    
    const response = await http.post('/logs/cleanup', requestData)
    if (response.success) {
      const deletedCount = response.data.deleted_count || response.data.deletedCount || 0
      ElMessage.success(`成功清理了 ${deletedCount} 条日志`)
      fetchLogs()
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('清理日志失败:', error)
      ElMessage.error('清理日志失败')
    }
  }
}

// 工具方法
const refreshAll = async () => {
  loading.value = true
  try {
    await Promise.all([
      refreshHealth(),
      fetchConfigs(),
      fetchAnnouncements(),
      fetchLogs()
    ])
  } finally {
    loading.value = false
  }
}

const resetConfigForm = () => {
  Object.assign(configForm, {
    category: '',
    key: '',
    value: '',
    description: '',
    isPublic: false
  })
  configFormRef.value?.clearValidate()
}

const resetAnnouncementForm = () => {
  Object.assign(announcementForm, {
    title: '',
    type: 'info',
    priority: 1,
    content: '',
    startTime: null,
    endTime: null,
    is_active: true,
    is_sticky: false
  })
  announcementFormRef.value?.clearValidate()
}

const formatTime = (time: string) => {
  return time ? dayjs(time).format('YYYY-MM-DD HH:mm:ss') : '-'
}

const formatLogContext = (context: any) => {
  return context ? JSON.stringify(context, null, 2) : '-'
}

const formatHealthDetails = (details: any) => {
  if (!details) return '-'
  if (typeof details === 'string') {
    try {
      const parsed = JSON.parse(details)
      return Object.entries(parsed).map(([key, value]) => `${key}: ${value}`).join(', ')
    } catch {
      return details
    }
  }
  return Object.entries(details).map(([key, value]) => `${key}: ${value}`).join(', ')
}

// 标签类型方法
const getHealthTagType = (status: string) => {
  const typeMap: Record<string, string> = {
    'healthy': 'success',
    'unhealthy': 'danger',
    'warning': 'warning'
  }
  return typeMap[status] || 'info'
}

const getHealthStatusText = (status: string) => {
  const textMap: Record<string, string> = {
    'healthy': '正常',
    'unhealthy': '异常',
    'warning': '警告'
  }
  return textMap[status] || status
}

const getAnnouncementTypeTag = (type: string) => {
  const typeMap: Record<string, string> = {
    'info': 'info',
    'warning': 'warning',
    'error': 'danger',
    'maintenance': 'warning'
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
  if (priority >= 4) return 'success'
  return 'info'
}

const getPriorityText = (priority: number) => {
  if (priority >= 8) return '紧急'
  if (priority >= 6) return '高'
  if (priority >= 4) return '中'
  return '低'
}

const getLogLevelTag = (level: string) => {
  const typeMap: Record<string, string> = {
    'debug': 'info',
    'info': 'success',
    'warn': 'warning',
    'error': 'danger',
    'fatal': 'danger'
  }
  return typeMap[level] || 'info'
}

// 生命周期
onMounted(() => {
  refreshAll()
  // 获取所有可用分类
  fetchAllCategories()
})
</script>

<style scoped>
/* 日志详情对话框样式 */
.log-detail-dialog .el-dialog__body {
  padding: 20px;
}

.log-detail-text-container {
  max-width: 300px;
}

.log-detail-text {
  display: inline-block;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  word-break: break-all;
}

.log-detail-message {
  width: 100%;
}

.log-detail-message .el-textarea__inner {
  font-family: 'Courier New', monospace;
  font-size: 13px;
  line-height: 1.4;
  word-break: break-all;
  white-space: pre-wrap;
}

.log-detail-context {
  width: 100%;
}

.log-detail-context .el-textarea__inner {
  font-family: 'Courier New', monospace;
  font-size: 12px;
  line-height: 1.4;
  word-break: break-all;
  white-space: pre-wrap;
  background-color: #f5f5f5;
}

/* 批量操作工具栏样式 */
.batch-actions {
  margin-bottom: 16px;
}

.batch-actions .el-alert__content {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

/* 系统管理整体样式 */
.system-management {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  gap: 8px;
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
  padding: 16px;
}

.overview-icon {
  width: 48px;
  height: 48px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 16px;
  font-size: 24px;
  color: white;
}

.overview-icon.health {
  background: linear-gradient(135deg, #67c23a, #85ce61);
}

.overview-icon.config {
  background: linear-gradient(135deg, #409eff, #66b1ff);
}

.overview-icon.announcement {
  background: linear-gradient(135deg, #e6a23c, #ebb563);
}

.overview-icon.logs {
  background: linear-gradient(135deg, #909399, #a6a9ad);
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

.system-tabs {
  margin-top: 20px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.section-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.search-bar {
  margin-bottom: 16px;
  padding: 16px;
  background: #f8f9fa;
  border-radius: 6px;
}

.pagination {
  margin-top: 16px;
  display: flex;
  justify-content: center;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .system-management {
    padding: 10px;
  }
  
  .overview-item {
    padding: 12px;
  }
  
  .overview-icon {
    width: 40px;
    height: 40px;
    font-size: 20px;
    margin-right: 12px;
  }
  
  .overview-value {
    font-size: 20px;
  }
  
  .log-detail-dialog {
    width: 95% !important;
  }
}
.system-management {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  gap: 10px;
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
  width: 60px;
  height: 60px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 15px;
  font-size: 24px;
  color: white;
}

.overview-icon.health {
  background: linear-gradient(135deg, #67c23a, #85ce61);
}

.overview-icon.config {
  background: linear-gradient(135deg, #409eff, #66b1ff);
}

.overview-icon.announcement {
  background: linear-gradient(135deg, #e6a23c, #ebb563);
}

.overview-icon.logs {
  background: linear-gradient(135deg, #909399, #a6a9ad);
}

.overview-content {
  flex: 1;
}

.overview-title {
  font-size: 14px;
  color: #909399;
  margin-bottom: 5px;
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

.search-bar {
  margin-bottom: 20px;
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
}

.pagination {
  margin-top: 20px;
  text-align: right;
}

.dialog-footer {
  text-align: right;
}

pre {
  background: #f5f5f5;
  padding: 10px;
  border-radius: 4px;
  font-size: 12px;
  max-height: 200px;
  overflow-y: auto;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .system-management {
    padding: 10px;
  }
  
  .overview-item {
    flex-direction: column;
    text-align: center;
  }
  
  .overview-icon {
    margin-right: 0;
    margin-bottom: 10px;
  }
  
  .search-bar .el-form {
    flex-direction: column;
  }
  
  .search-bar .el-form-item {
    width: 100%;
    margin-bottom: 10px;
  }
}

/* 操作按钮样式 */
.action-buttons {
  display: flex;
  gap: 4px;
  justify-content: center;
  flex-wrap: nowrap;
}

.action-buttons .el-button {
  min-width: 60px;
  padding: 5px 8px;
}

/* 公告预览对话框样式 */
.announcement-preview-dialog .announcement-preview {
  padding: 16px;
}

.announcement-preview .preview-header {
  margin-bottom: 16px;
}

.announcement-preview .preview-title {
  display: flex;
  align-items: center;
  font-size: 18px;
  font-weight: 600;
  color: #303133;
  margin-bottom: 8px;
}

.announcement-preview .preview-icon {
  margin-right: 8px;
  font-size: 20px;
}

.announcement-preview .preview-icon.info {
  color: #409eff;
}

.announcement-preview .preview-icon.warning {
  color: #e6a23c;
}

.announcement-preview .preview-icon.error {
  color: #f56c6c;
}

.announcement-preview .preview-icon.maintenance {
  color: #909399;
}

.announcement-preview .preview-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 14px;
  color: #606266;
}

.announcement-preview .preview-time {
  color: #909399;
}

.announcement-preview .preview-content {
  font-size: 14px;
  line-height: 1.6;
  color: #606266;
  margin: 16px 0;
}

.announcement-preview .preview-footer {
  text-align: center;
  margin-top: 16px;
}

.announcement-preview .text-muted {
  color: #c0c4cc;
  font-size: 12px;
}
</style>