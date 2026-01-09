<template>
  <div class="permission-management">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>权限管理</span>
          <div class="header-actions">
            <el-button @click="refreshPermissions" size="small">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
            <el-button @click="handleCreatePermission" type="primary" size="small">
              <el-icon><Plus /></el-icon>
              新增权限
            </el-button>
          </div>
        </div>
      </template>

      <!-- 搜索和筛选 -->
      <div class="search-section" style="margin-bottom: 16px;">
        <el-row :gutter="16">
          <el-col :span="8">
            <el-input 
              v-model="searchText" 
              placeholder="搜索权限名称或描述" 
              clearable 
              @input="handleSearch"
            >
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
          </el-col>
          <el-col :span="6">
            <el-select 
              v-model="selectedResource" 
              placeholder="筛选资源类型" 
              clearable
              @change="handleResourceFilter"
            >
              <el-option 
                v-for="resource in resourceTypes" 
                :key="resource.value" 
                :label="resource.label" 
                :value="resource.value"
              />
            </el-select>
          </el-col>
        </el-row>
      </div>

      <!-- 权限统计 -->
      <div class="permission-stats" style="margin-bottom: 16px;">
        <el-row :gutter="16">
          <el-col :span="6">
            <el-statistic title="总权限数" :value="permissions.length" />
          </el-col>
          <el-col :span="6">
            <el-statistic title="显示数量" :value="displayedPermissions.length" />
          </el-col>
          <el-col :span="6">
            <el-statistic title="资源类型" :value="resourceCount" />
          </el-col>
          <el-col :span="6">
            <el-statistic title="根权限" :value="rootPermissionCount" />
          </el-col>
        </el-row>
      </div>

      <!-- 权限表格 -->
      <div class="table-view">
        <el-table 
          :data="paginatedPermissions" 
          v-loading="loading"
          height="500"
          stripe
          border
        >
          <el-table-column prop="displayName" label="权限名称" width="220" show-overflow-tooltip>
            <template #default="{ row }">
              <div class="permission-name-cell">
                <div class="permission-icon">
                  <el-icon :color="getResourceColor(row.resource)">
                    <component :is="getResourceIcon(row.resource)" />
                  </el-icon>
                </div>
                <div class="permission-info">
                  <div class="name">{{ row.displayName || row.name }}</div>
                  <div class="identifier">{{ row.name }}</div>
                </div>
                <el-tag v-if="row.parentId" size="small" type="info" class="child-tag">
                  子权限
                </el-tag>
              </div>
            </template>
          </el-table-column>
          
          <el-table-column label="资源:操作" width="160" align="center">
            <template #default="{ row }">
              <div class="resource-action">
                <el-tag size="small" :type="getResourceTagType(row.resource)" class="resource-tag">
                  {{ row.resource }}
                </el-tag>
                <el-tag size="small" type="warning" class="action-tag">
                  {{ row.action }}
                </el-tag>
              </div>
            </template>
          </el-table-column>
          
          <el-table-column prop="scope" label="作用域" width="100" align="center">
            <template #default="{ row }">
              <el-tag size="small" :type="getScopeTagType(row.scope)">
                {{ getScopeDisplayName(row.scope) }}
              </el-tag>
            </template>
          </el-table-column>
          
          <el-table-column prop="description" label="描述" show-overflow-tooltip>
            <template #default="{ row }">
              <div class="description-cell">
                {{ row.description || '暂无描述' }}
              </div>
            </template>
          </el-table-column>
          
          <el-table-column label="父权限" width="150" show-overflow-tooltip>
            <template #default="{ row }">
              <span v-if="row.parentId" class="parent-permission">
                {{ getParentPermissionName(row.parentId) }}
              </span>
              <span v-else class="root-permission">根权限</span>
            </template>
          </el-table-column>
          
          <el-table-column label="操作" width="140" fixed="right" align="center">
            <template #default="{ row }">
              <el-button-group size="small">
                <el-button @click="handleEditPermission(row)" type="primary" text>
                  <el-icon><Edit /></el-icon>
                  编辑
                </el-button>
                <el-button @click="handleDeletePermission(row)" type="danger" text>
                  <el-icon><Delete /></el-icon>
                  删除
                </el-button>
              </el-button-group>
            </template>
          </el-table-column>
        </el-table>

        <!-- 分页 -->
        <div class="pagination-wrapper" style="margin-top: 16px; text-align: center;">
          <el-pagination
            v-model:current-page="currentPage"
            v-model:page-size="pageSize"
            :page-sizes="[10, 20, 50, 100]"
            :total="displayedPermissions.length"
            layout="total, sizes, prev, pager, next"
            @size-change="handleSizeChange"
            @current-change="handleCurrentChange"
          />
        </div>
      </div>
    </el-card>

    <!-- 权限编辑对话框 -->
    <el-dialog 
      v-model="permissionDialogVisible" 
      :title="isEditPermission ? '编辑权限' : '新增权限'" 
      width="600px"
    >
      <div class="permission-form">
        <el-form
          ref="formRef"
          :model="permissionForm"
          label-width="100px"
        >
          <el-form-item label="权限名称">
            <el-input v-model="permissionForm.displayName" placeholder="请输入权限显示名称" />
          </el-form-item>
          
          <el-form-item label="权限标识">
            <el-input v-model="permissionForm.name" placeholder="请输入权限标识" />
          </el-form-item>
          
          <el-form-item label="资源类型">
            <el-select v-model="permissionForm.resource" placeholder="选择资源类型">
              <el-option label="系统管理" value="system" />
              <el-option label="用户管理" value="users" />
              <el-option label="角色管理" value="roles" />
              <el-option label="权限管理" value="permissions" />
              <el-option label="工单管理" value="tickets" />
              <el-option label="记录管理" value="records" />
              <el-option label="文件管理" value="files" />
            </el-select>
          </el-form-item>
          
          <el-form-item label="操作类型">
            <el-select v-model="permissionForm.action" placeholder="选择操作类型">
              <el-option label="查看" value="read" />
              <el-option label="创建" value="create" />
              <el-option label="修改" value="update" />
              <el-option label="删除" value="delete" />
              <el-option label="管理" value="manage" />
            </el-select>
          </el-form-item>
          
          <el-form-item label="作用域">
            <el-select v-model="permissionForm.scope" placeholder="选择作用域">
              <el-option label="全部" value="all" />
              <el-option label="部门" value="department" />
              <el-option label="自己" value="own" />
            </el-select>
          </el-form-item>
          
          <el-form-item label="描述">
            <el-input 
              v-model="permissionForm.description" 
              type="textarea" 
              placeholder="请输入权限描述"
            />
          </el-form-item>
          
          <el-form-item>
            <el-button @click="permissionDialogVisible = false">取消</el-button>
            <el-button 
              type="primary" 
              @click="handleSavePermission(permissionForm)"
              :loading="permissionSubmitting"
            >
              {{ isEditPermission ? '更新' : '创建' }}
            </el-button>
          </el-form-item>
        </el-form>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  Plus, Search, Edit, Delete, Refresh,
  Setting, User, Lock, Document, Upload, Bell, 
  Monitor, DataAnalysis, Folder, Files, ChatDotRound, 
  Key, View, Tickets
} from '@element-plus/icons-vue'
import http from '../../utils/request'
import type { Permission } from '../../types'

// 响应式数据
const loading = ref(false)
const permissions = ref<Permission[]>([])
const searchText = ref('')
const selectedResource = ref('')

// 分页数据
const currentPage = ref(1)
const pageSize = ref(20)

// 权限表单
const permissionDialogVisible = ref(false)
const isEditPermission = ref(false)
const permissionSubmitting = ref(false)

let permissionForm = reactive({
  id: null as number | null,
  name: '',
  displayName: '',
  description: '',
  resource: '',
  action: '',
  scope: 'all',
  parentId: null as number | null
})

// 计算属性
const displayedPermissions = computed(() => {
  let filtered = permissions.value

  // 搜索过滤
  if (searchText.value) {
    const searchLower = searchText.value.toLowerCase()
    filtered = filtered.filter(p => 
      (p.displayName && p.displayName.toLowerCase().includes(searchLower)) ||
      (p.name && p.name.toLowerCase().includes(searchLower)) ||
      (p.description && p.description.toLowerCase().includes(searchLower)) ||
      p.resource.toLowerCase().includes(searchLower) ||
      p.action.toLowerCase().includes(searchLower)
    )
  }

  // 资源类型过滤
  if (selectedResource.value) {
    filtered = filtered.filter(p => p.resource === selectedResource.value)
  }

  return filtered
})

const paginatedPermissions = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return displayedPermissions.value.slice(start, end)
})

const resourceCount = computed(() => {
  return new Set(permissions.value.map(p => p.resource)).size
})

const rootPermissionCount = computed(() => {
  return permissions.value.filter(p => !p.parentId).length
})

const resourceTypes = computed(() => {
  const resources = new Set(permissions.value.map(p => p.resource))
  return Array.from(resources).map(resource => ({
    value: resource,
    label: getResourceDisplayName(resource)
  }))
})

const parentOptions = computed(() => {
  return permissions.value
    .filter(p => !p.parentId) // 只显示根权限作为父权限选项
    .map(p => ({
      value: p.id,
      label: p.displayName || p.name
    }))
})

// 方法
const fetchPermissions = async () => {
  loading.value = true
  try {
    const response = await http.get('/permissions')
    if (response.success) {
      permissions.value = response.data || []
      console.log('权限列表加载成功，总数:', permissions.value.length)
    }
  } catch (error) {
    console.error('获取权限列表失败:', error)
    ElMessage.error('获取权限列表失败')
  } finally {
    loading.value = false
  }
}

const refreshPermissions = async () => {
  await fetchPermissions()
  ElMessage.success('权限数据已刷新')
}

const handleSearch = () => {
  currentPage.value = 1
}

const handleResourceFilter = () => {
  currentPage.value = 1
}

const handleSizeChange = (size: number) => {
  pageSize.value = size
  currentPage.value = 1
}

const handleCurrentChange = (page: number) => {
  currentPage.value = page
}

const handleCreatePermission = () => {
  Object.assign(permissionForm, {
    id: null,
    name: '',
    displayName: '',
    description: '',
    resource: '',
    action: '',
    scope: 'all',
    parentId: null
  })
  isEditPermission.value = false
  permissionDialogVisible.value = true
}

const handleEditPermission = (permission: Permission) => {
  Object.assign(permissionForm, {
    id: permission.id,
    name: permission.name,
    displayName: permission.displayName,
    description: permission.description,
    resource: permission.resource,
    action: permission.action,
    scope: permission.scope,
    parentId: permission.parentId
  })
  isEditPermission.value = true
  permissionDialogVisible.value = true
}

const handleDeletePermission = async (permission: Permission) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除权限 "${permission.displayName || permission.name}" 吗？`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    const response = await http.delete(`/permissions/${permission.id}`)
    if (response.success) {
      ElMessage.success('权限删除成功')
      await fetchPermissions()
    } else {
      throw new Error(response.message || '删除失败')
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('删除权限失败:', error)
      ElMessage.error(error.message || '删除权限失败')
    }
  }
}

const handleSavePermission = async (formData: any) => {
  permissionSubmitting.value = true
  try {
    let response
    if (isEditPermission.value) {
      response = await http.put(`/permissions/${formData.id}`, formData)
    } else {
      response = await http.post('/permissions', formData)
    }
    
    if (response.success) {
      ElMessage.success(isEditPermission.value ? '权限更新成功' : '权限创建成功')
      permissionDialogVisible.value = false
      await fetchPermissions()
    } else {
      throw new Error(response.message || '保存失败')
    }
  } catch (error: any) {
    console.error('保存权限失败:', error)
    ElMessage.error(error.message || '保存权限失败')
  } finally {
    permissionSubmitting.value = false
  }
}

// 辅助方法
const getResourceIcon = (resource: string) => {
  const iconMap: Record<string, any> = {
    system: Setting,
    users: User,
    roles: Key,
    permissions: Lock,
    records: Document,
    files: Files,
    export: Upload,
    notifications: Bell,
    ai: ChatDotRound,
    audit: Monitor,
    dashboard: DataAnalysis,
    ticket: Tickets
  }
  return iconMap[resource] || Document
}

const getResourceColor = (resource: string) => {
  const colorMap: Record<string, string> = {
    system: '#409eff',
    users: '#67c23a',
    roles: '#e6a23c',
    permissions: '#f56c6c',
    records: '#909399',
    files: '#409eff',
    export: '#67c23a',
    notifications: '#e6a23c',
    ai: '#f56c6c',
    audit: '#909399',
    dashboard: '#409eff',
    ticket: '#67c23a'
  }
  return colorMap[resource] || '#909399'
}

const getResourceTagType = (resource: string) => {
  const typeMap: Record<string, string> = {
    system: 'primary',
    users: 'success',
    roles: 'warning',
    permissions: 'danger',
    records: 'info',
    files: 'primary',
    export: 'success',
    notifications: 'warning',
    ai: 'danger',
    audit: 'info',
    dashboard: 'primary',
    ticket: 'success'
  }
  return typeMap[resource] || 'info'
}

const getResourceDisplayName = (resource: string) => {
  const nameMap: Record<string, string> = {
    system: '系统管理',
    users: '用户管理',
    roles: '角色管理',
    permissions: '权限管理',
    records: '记录管理',
    files: '文件管理',
    export: '数据导出',
    notifications: '通知管理',
    ai: 'AI功能',
    audit: '审计日志',
    dashboard: '仪表盘',
    ticket: '工单管理'
  }
  return nameMap[resource] || resource
}

const getScopeTagType = (scope: string) => {
  const typeMap: Record<string, string> = {
    all: 'primary',
    own: 'success',
    department: 'warning',
    custom: 'info'
  }
  return typeMap[scope] || 'info'
}

const getScopeDisplayName = (scope: string) => {
  const nameMap: Record<string, string> = {
    all: '全部',
    own: '仅自己',
    department: '部门',
    custom: '自定义'
  }
  return nameMap[scope] || scope
}

const getParentPermissionName = (parentId: number) => {
  const parent = permissions.value.find(p => p.id === parentId)
  return parent ? (parent.displayName || parent.name) : '未知'
}

// 生命周期
onMounted(() => {
  fetchPermissions()
})
</script>

<style scoped>
.permission-management {
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

.permission-stats {
  background: #f8f9fa;
  padding: 16px;
  border-radius: 8px;
}

.search-section {
  background: #f8f9fa;
  padding: 16px;
  border-radius: 8px;
}

.pagination-wrapper {
  display: flex;
  justify-content: center;
  align-items: center;
}

.permission-name-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.permission-icon {
  font-size: 16px;
}

.permission-info {
  flex: 1;
  min-width: 0;
}

.permission-info .name {
  font-weight: 500;
  color: #303133;
  margin-bottom: 2px;
}

.permission-info .identifier {
  font-size: 12px;
  color: #909399;
  font-family: 'Courier New', monospace;
}

.child-tag {
  margin-left: auto;
}

.resource-action {
  display: flex;
  flex-direction: column;
  gap: 4px;
  align-items: center;
}

.resource-tag, .action-tag {
  font-size: 11px;
  font-family: 'Courier New', monospace;
}

.description-cell {
  color: #606266;
  line-height: 1.4;
}

.parent-permission {
  color: #409eff;
  font-size: 12px;
}

.root-permission {
  color: #909399;
  font-size: 12px;
  font-style: italic;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .permission-management {
    padding: 10px;
  }
}
</style>
