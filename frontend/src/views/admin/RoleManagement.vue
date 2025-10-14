<template>
  <div class="role-management">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>角色管理</span>
          <div class="header-actions">
            <el-button @click="handleRefresh" :loading="loading">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
            <el-dropdown @command="handleImportAction">
              <el-button type="success">
                <el-icon><Upload /></el-icon>
                导入角色
                <el-icon class="el-icon--right"><ArrowDown /></el-icon>
              </el-button>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="template">下载模板</el-dropdown-item>
                  <el-dropdown-item command="import" divided>导入角色</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
            <el-button type="primary" @click="handleCreate">
              <el-icon><Plus /></el-icon>
              新增角色
            </el-button>
          </div>
        </div>
      </template>

      <!-- 批量操作栏 -->
      <div class="batch-actions" v-if="selectedRoles.length > 0">
        <el-alert
          :title="`已选择 ${selectedRoles.length} 个角色`"
          type="info"
          :closable="false"
          style="margin-bottom: 15px;"
        >
          <template #default>
            <div class="batch-buttons">
              <el-button size="small" type="success" @click="handleBatchEnable">
                批量启用
              </el-button>
              <el-button size="small" type="warning" @click="handleBatchDisable">
                批量禁用
              </el-button>
              <el-button size="small" type="danger" @click="handleBatchDelete">
                批量删除
              </el-button>
              <el-button size="small" @click="clearRoleSelection">
                取消选择
              </el-button>
            </div>
          </template>
        </el-alert>
      </div>

      <!-- 搜索栏 -->
      <div class="search-bar">
        <el-form :model="searchForm" inline class="search-form">
          <el-form-item label="角色名称" class="search-item">
            <el-input 
              v-model="searchForm.name" 
              placeholder="请输入角色名称" 
              clearable 
              style="width: 200px;"
              @keyup.enter="handleSearch"
            />
          </el-form-item>
          <el-form-item label="状态" class="search-item">
            <el-select 
              v-model="searchForm.status" 
              placeholder="请选择状态" 
              clearable
              style="width: 120px;"
            >
              <el-option label="全部" value="" />
              <el-option label="启用" value="active" />
              <el-option label="禁用" value="inactive" />
            </el-select>
          </el-form-item>
          <el-form-item class="search-buttons">
            <el-button type="primary" @click="handleSearch" :loading="loading">
              <el-icon><Search /></el-icon>
              搜索
            </el-button>
            <el-button @click="handleReset">
              <el-icon><RefreshRight /></el-icon>
              重置
            </el-button>
          </el-form-item>
        </el-form>
      </div>

      <!-- 角色表格 -->
      <el-table 
        :data="roles" 
        v-loading="loading" 
        stripe
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="name" label="角色名称" min-width="120" show-overflow-tooltip />
        <el-table-column prop="displayName" label="显示名称" min-width="120" show-overflow-tooltip />
        <el-table-column prop="description" label="描述" min-width="200" show-overflow-tooltip />
        <el-table-column label="权限数量" width="100" align="center">
          <template #default="{ row }">
            <el-tag size="small" type="info">
              {{ row.permissions?.length || 0 }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="用户数量" width="100" align="center">
          <template #default="{ row }">
            <el-tag size="small" type="success">
              {{ row.userCount || 0 }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 'active' ? 'success' : 'danger'" size="small">
              {{ row.status === 'active' ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="类型" width="80" align="center">
          <template #default="{ row }">
            <el-tag v-if="row.is_system || row.isSystem" size="small" type="warning">
              系统
            </el-tag>
            <el-tag v-else size="small" type="info">
              自定义
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdAt" label="创建时间" width="160" align="center">
          <template #default="{ row }">
            {{ formatTime(row.createdAt) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="320" fixed="right" align="center">
          <template #default="{ row }">
            <div class="action-buttons">
              <el-button 
                size="small" 
                @click="handleEdit(row)"
                :disabled="row.is_system || row.isSystem"
              >
                编辑
              </el-button>
              <el-button size="small" type="warning" @click="handlePermissions(row)">权限</el-button>
              <el-button 
                size="small" 
                :type="row.status === 'active' ? 'danger' : 'success'"
                @click="handleToggleStatus(row)"
                :disabled="row.is_system || row.isSystem"
              >
                {{ row.status === 'active' ? '禁用' : '启用' }}
              </el-button>
              <el-button 
                size="small" 
                type="danger" 
                @click="handleDelete(row)"
                :disabled="row.is_system || row.isSystem"
              >
                删除
              </el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.size"
          :total="pagination.total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 角色编辑对话框 -->
    <el-dialog 
      v-model="dialogVisible" 
      :title="dialogTitle" 
      width="600px"
      @close="handleDialogClose"
    >
      <el-form 
        ref="formRef" 
        :model="formData" 
        :rules="formRules" 
        label-width="100px"
      >
        <el-form-item label="角色名称" prop="name">
          <el-input 
            v-model="formData.name" 
            placeholder="请输入角色名称（英文）"
            :disabled="isEdit && (formData.is_system || formData.isSystem)"
          />
        </el-form-item>
        <el-form-item label="显示名称" prop="displayName">
          <el-input 
            v-model="formData.displayName" 
            placeholder="请输入显示名称"
            :disabled="formData.is_system || formData.isSystem"
          />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="formData.status" :disabled="formData.is_system || formData.isSystem">
            <el-radio label="active">启用</el-radio>
            <el-radio label="inactive">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input 
            v-model="formData.description" 
            placeholder="请输入角色描述"
            type="textarea"
            :rows="3"
          />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSubmit" :loading="submitting">
            {{ isEdit ? '更新' : '创建' }}
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 权限分配对话框 -->
    <el-dialog 
      v-model="permissionDialogVisible" 
      title="权限管理" 
      width="800px"
      :close-on-click-modal="false"
    >
      <div v-if="currentRole">
        <div class="role-info">
          <p><strong>角色：</strong>{{ currentRole.displayName || currentRole.name }}</p>
          <p><strong>描述：</strong>{{ currentRole.description || '-' }}</p>
        </div>
        <el-divider />
        
        <div class="permission-section">
          <div class="section-header">
            <h4>系统权限</h4>
            <div class="permission-actions">
              <el-button size="small" @click="expandAll" :disabled="permissionLoading">展开全部</el-button>
              <el-button size="small" @click="collapseAll" :disabled="permissionLoading">折叠全部</el-button>
              <el-button size="small" type="success" @click="handleSelectAll" :disabled="permissionLoading">全选</el-button>
              <el-button size="small" type="warning" @click="handleSelectNone" :disabled="permissionLoading">全不选</el-button>
            </div>
          </div>
          
          <div class="permission-stats">
            <el-tag size="small" type="info">
              已选择: {{ selectedPermissions.length }} 项权限
            </el-tag>
            <el-tag v-if="permissionTree.length > 0" size="small" type="success">
              总权限: {{ getAllPermissionKeys(permissionTree).length }} 项
            </el-tag>
          </div>
          
          <!-- 错误提示 -->
          <el-alert
            v-if="permissionError"
            :title="permissionError"
            type="error"
            :closable="false"
            style="margin-bottom: 15px;"
          />
          
          <!-- 权限树加载状态 -->
          <div v-if="permissionLoading" class="permission-loading">
            <el-skeleton :rows="5" animated />
            <div class="loading-text">正在加载权限数据...</div>
          </div>
          
          <!-- 权限树 -->
          <div v-else-if="permissionTree.length > 0" class="permission-tree">
            <el-tree
              ref="permissionTreeRef"
              :data="permissionTree"
              :props="treeProps"
              show-checkbox
              node-key="id"
              :default-checked-keys="selectedPermissions"
              :default-expand-all="false"
              :expand-on-click-node="false"
              :check-on-click-node="true"
              :check-strictly="false"
              @check="handlePermissionCheck"
            >
              <template #default="{ node, data }">
                <div class="tree-node">
                  <div class="node-content">
                    <span class="node-label">{{ data.displayName || data.name }}</span>
                    <div class="node-tags">
                      <el-tag v-if="data.resource && data.action" size="small" type="info" class="node-tag">
                        {{ data.resource }}:{{ data.action }}
                      </el-tag>
                      <el-tag v-if="data.scope && data.scope !== 'all'" size="small" type="warning" class="scope-tag">
                        {{ data.scope === 'own' ? '仅自己' : data.scope }}
                      </el-tag>
                    </div>
                  </div>
                  <span v-if="data.description" class="node-description">{{ data.description }}</span>
                </div>
              </template>
            </el-tree>
          </div>
          
          <!-- 无权限数据提示 -->
          <div v-else class="no-permissions">
            <el-empty description="暂无权限数据">
              <el-button type="primary" @click="fetchPermissions">重新加载</el-button>
            </el-empty>
          </div>
        </div>
      </div>
      
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="permissionDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSavePermissions" :loading="submitting">
            保存权限
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 导入角色对话框 -->
    <el-dialog v-model="importDialogVisible" title="导入角色" width="600px">
      <div class="import-section">
        <el-alert
          title="导入说明"
          type="info"
          :closable="false"
          show-icon
          style="margin-bottom: 20px;"
        >
          <template #default>
            <div style="font-size: 14px;">
              <p>1. 请先下载模板文件，按照模板格式填写角色信息</p>
              <p>2. 支持的文件格式：Excel (.xlsx, .xls) 或 CSV (.csv)</p>
              <p>3. 必填字段：角色名称、显示名称</p>
              <p>4. 可选字段：描述、状态、权限（权限名称用逗号分隔）</p>
            </div>
          </template>
        </el-alert>

        <el-upload
          ref="roleUploadRef"
          class="upload-demo"
          drag
          :auto-upload="false"
          :on-change="handleRoleFileChange"
          :before-upload="beforeRoleUpload"
          accept=".xlsx,.xls,.csv"
          :limit="1"
        >
          <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
          <div class="el-upload__text">
            将文件拖到此处，或<em>点击上传</em>
          </div>
          <template #tip>
            <div class="el-upload__tip">
              只能上传 xlsx/xls/csv 文件，且不超过 10MB
            </div>
          </template>
        </el-upload>

        <div v-if="importRoleFile" class="file-info" style="margin-top: 20px;">
          <el-card>
            <div style="display: flex; align-items: center; justify-content: space-between;">
              <div>
                <el-icon><Document /></el-icon>
                <span style="margin-left: 8px;">{{ importRoleFile.name }}</span>
                <el-tag size="small" style="margin-left: 8px;">{{ formatFileSize(importRoleFile.size) }}</el-tag>
              </div>
              <el-button size="small" type="danger" @click="removeRoleFile">移除</el-button>
            </div>
          </el-card>
        </div>

        <div v-if="importRolePreview.length > 0" class="preview-section" style="margin-top: 20px;">
          <h4>数据预览 (前5条)</h4>
          <el-table :data="importRolePreview.slice(0, 5)" size="small" max-height="300">
            <el-table-column prop="name" label="角色名称" width="120" />
            <el-table-column prop="displayName" label="显示名称" width="150" />
            <el-table-column prop="description" label="描述" width="200" show-overflow-tooltip />
            <el-table-column prop="status" label="状态" width="80" />
            <el-table-column prop="permissions" label="权限" width="200" show-overflow-tooltip />
          </el-table>
          <div style="margin-top: 10px; color: #666; font-size: 14px;">
            共 {{ importRolePreview.length }} 条数据，将导入 {{ validImportRoleData.length }} 条有效数据
          </div>
        </div>
      </div>

      <template #footer>
        <div class="dialog-footer">
          <el-button @click="importDialogVisible = false">取消</el-button>
          <el-button @click="downloadRoleTemplate">下载模板</el-button>
          <el-button 
            type="primary" 
            @click="handleImportRoles" 
            :loading="importing"
            :disabled="!importRoleFile || validImportRoleData.length === 0"
          >
            导入角色 ({{ validImportRoleData.length }})
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Refresh, Search, RefreshRight, Upload, ArrowDown, UploadFilled, Document } from '@element-plus/icons-vue'
import { http } from '@/utils/request'
import { API_ENDPOINTS } from '@/config/api'
import dayjs from 'dayjs'

// 响应式数据
const loading = ref(false)
const submitting = ref(false)
const permissionLoading = ref(false)
const roles = ref([])
const selectedRoles = ref([])
const dialogVisible = ref(false)
const permissionDialogVisible = ref(false)
const formRef = ref()
const permissionTreeRef = ref()
const currentRole = ref(null)
const permissionTree = ref([])
const selectedPermissions = ref([])
const permissionError = ref('')

// 导入相关数据
const importDialogVisible = ref(false)
const importing = ref(false)
const importRoleFile = ref(null)
const importRolePreview = ref([])
const validImportRoleData = ref([])
const roleUploadRef = ref()

const searchForm = reactive({
  name: '',
  status: ''
})

const pagination = reactive({
  page: 1,
  size: 20,
  total: 0
})

const formData = reactive({
  name: '',
  displayName: '',
  status: 'active',
  description: ''
})

// 树形控件配置
const treeProps = {
  children: 'children',
  label: 'displayName'
}

// 计算属性
const dialogTitle = computed(() => isEdit.value ? '编辑角色' : '新增角色')
const isEdit = ref(false)

// 表单验证规则
const formRules = {
  name: [
    { required: true, message: '请输入角色名称', trigger: 'blur' },
    { pattern: /^[a-zA-Z][a-zA-Z0-9_]*$/, message: '角色名称只能包含字母、数字和下划线，且以字母开头', trigger: 'blur' }
  ],
  displayName: [
    { required: true, message: '请输入显示名称', trigger: 'blur' }
  ]
}

// 获取角色列表
const fetchRoles = async () => {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      size: pagination.size,
      ...searchForm
    }
    
    const response = await http.get('/admin/roles', { params })
    
    if (response.data) {
      roles.value = response.data.items || response.data || []
      pagination.total = response.data.total || roles.value.length
    }
  } catch (error) {
    console.error('获取角色列表失败:', error)
    ElMessage.error('获取角色列表失败')
  } finally {
    loading.value = false
  }
}

// 获取权限树
const fetchPermissions = async (retryCount = 0) => {
  try {
    // 首先尝试获取权限树结构
    const treeResponse = await http.get('/permissions/tree')
    if (treeResponse.success && treeResponse.data && treeResponse.data.length > 0) {
      // 检查权限数据的完整性
      const hasValidData = treeResponse.data.some(item => 
        item.displayName && item.displayName.trim() !== ''
      )
      
      if (hasValidData) {
        // 处理后端数据，补充缺失的显示信息
        const processedData = processBackendPermissions(treeResponse.data)
        permissionTree.value = buildPermissionTree(processedData)
        console.log('权限树加载成功，节点数量:', permissionTree.value.length)
        return
      }
    }
    
    // 如果权限树数据不完整，尝试获取平面权限列表
    const response = await http.get('/permissions')
    let permissions = response.success ? (response.data?.items || response.data || []) : []
    
    if (permissions.length > 0) {
      const processedData = processBackendPermissions(permissions)
      permissionTree.value = buildPermissionTree(processedData)
      console.log('从平面权限列表构建权限树成功，权限数量:', permissions.length)
    } else {
      // 使用完整的模拟数据
      console.warn('后端权限数据不完整，使用完整的模拟数据')
      permissionTree.value = buildPermissionTree(getMockPermissions())
    }
  } catch (error) {
    console.error('获取权限列表失败:', error)
    
    // 重试机制
    if (retryCount < 2) {
      console.log(`权限获取失败，进行第${retryCount + 1}次重试...`)
      setTimeout(() => {
        fetchPermissions(retryCount + 1)
      }, 1000 * (retryCount + 1))
      return
    }
    
    // 使用模拟权限数据
    console.warn('权限获取失败，使用模拟数据')
    permissionTree.value = buildPermissionTree(getMockPermissions())
  }
}

// 处理后端权限数据，补充缺失信息
const processBackendPermissions = (permissions: any[]) => {
  const resourceDisplayNames: Record<string, string> = {
    'system': '系统管理',
    'users': '用户管理', 
    'roles': '角色管理',
    'records': '记录管理',
    'files': '文件管理',
    'export': '数据导出',
    'ai': 'AI功能'
  }
  
  const actionDisplayNames: Record<string, string> = {
    'manage': '管理',
    'read': '查看',
    'write': '编辑',
    'delete': '删除',
    'admin': '管理员',
    'config': '配置',
    'assign': '分配权限',
    'upload': '上传',
    'share': '分享',
    'chat': '聊天',
    'ocr': 'OCR识别',
    'speech': '语音识别'
  }
  
  return permissions.map(permission => {
    // 如果缺少显示名称，根据resource和action生成
    let displayName = permission.displayName
    if (!displayName || displayName.trim() === '') {
      const resourceName = resourceDisplayNames[permission.resource] || permission.resource
      const actionName = actionDisplayNames[permission.action] || permission.action
      
      if (permission.action === 'manage') {
        displayName = resourceName
      } else {
        displayName = `${actionName}${resourceName}`
        if (permission.scope === 'own') {
          displayName += '(仅自己)'
        }
      }
    }
    
    // 如果缺少name，生成一个
    let name = permission.name
    if (!name || name.trim() === '') {
      name = `${permission.resource}:${permission.action}`
      if (permission.scope !== 'all') {
        name += `:${permission.scope}`
      }
    }
    
    // 如果缺少描述，生成一个
    let description = permission.description
    if (!description || description.trim() === '') {
      description = `${displayName}相关权限`
    }
    
    return {
      ...permission,
      name,
      displayName,
      description
    }
  })
}

// 模拟权限数据 - 包含完整的系统权限
const getMockPermissions = () => {
  return [
    // 系统管理
    {
      id: 1,
      name: 'system',
      displayName: '系统管理',
      description: '系统管理相关权限',
      resource: 'system',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    {
      id: 2,
      name: 'system:admin',
      displayName: '系统管理员',
      description: '系统管理员权限',
      resource: 'system',
      action: 'admin',
      scope: 'all',
      parentId: 1
    },
    {
      id: 3,
      name: 'system:config',
      displayName: '系统配置',
      description: '系统配置管理权限',
      resource: 'system',
      action: 'config',
      scope: 'all',
      parentId: 1
    },
    
    // 用户管理
    {
      id: 4,
      name: 'users',
      displayName: '用户管理',
      description: '用户管理相关权限',
      resource: 'users',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    {
      id: 5,
      name: 'users:read',
      displayName: '查看用户',
      description: '查看用户列表和详情',
      resource: 'users',
      action: 'read',
      scope: 'all',
      parentId: 4
    },
    {
      id: 6,
      name: 'users:write',
      displayName: '编辑用户',
      description: '创建和编辑用户',
      resource: 'users',
      action: 'write',
      scope: 'all',
      parentId: 4
    },
    {
      id: 7,
      name: 'users:delete',
      displayName: '删除用户',
      description: '删除用户账号',
      resource: 'users',
      action: 'delete',
      scope: 'all',
      parentId: 4
    },
    
    // 角色管理
    {
      id: 8,
      name: 'roles',
      displayName: '角色管理',
      description: '角色管理相关权限',
      resource: 'roles',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    {
      id: 9,
      name: 'roles:read',
      displayName: '查看角色',
      description: '查看角色列表和详情',
      resource: 'roles',
      action: 'read',
      scope: 'all',
      parentId: 8
    },
    {
      id: 10,
      name: 'roles:write',
      displayName: '编辑角色',
      description: '创建和编辑角色',
      resource: 'roles',
      action: 'write',
      scope: 'all',
      parentId: 8
    },
    {
      id: 11,
      name: 'roles:delete',
      displayName: '删除角色',
      description: '删除角色',
      resource: 'roles',
      action: 'delete',
      scope: 'all',
      parentId: 8
    },
    {
      id: 12,
      name: 'roles:assign',
      displayName: '分配权限',
      description: '为角色分配权限',
      resource: 'roles',
      action: 'assign',
      scope: 'all',
      parentId: 8
    },
    
    // 记录管理
    {
      id: 13,
      name: 'records',
      displayName: '记录管理',
      description: '记录管理相关权限',
      resource: 'records',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    {
      id: 14,
      name: 'records:read',
      displayName: '查看记录',
      description: '查看记录列表和详情',
      resource: 'records',
      action: 'read',
      scope: 'all',
      parentId: 13
    },
    {
      id: 15,
      name: 'records:read:own',
      displayName: '查看自己的记录',
      description: '只能查看自己创建的记录',
      resource: 'records',
      action: 'read',
      scope: 'own',
      parentId: 13
    },
    {
      id: 16,
      name: 'records:write',
      displayName: '编辑记录',
      description: '创建和编辑记录',
      resource: 'records',
      action: 'write',
      scope: 'all',
      parentId: 13
    },
    {
      id: 17,
      name: 'records:write:own',
      displayName: '编辑自己的记录',
      description: '只能编辑自己创建的记录',
      resource: 'records',
      action: 'write',
      scope: 'own',
      parentId: 13
    },
    {
      id: 18,
      name: 'records:delete',
      displayName: '删除记录',
      description: '删除记录数据',
      resource: 'records',
      action: 'delete',
      scope: 'all',
      parentId: 13
    },
    {
      id: 19,
      name: 'records:delete:own',
      displayName: '删除自己的记录',
      description: '只能删除自己创建的记录',
      resource: 'records',
      action: 'delete',
      scope: 'own',
      parentId: 13
    },
    
    // 文件管理
    {
      id: 20,
      name: 'files',
      displayName: '文件管理',
      description: '文件管理相关权限',
      resource: 'files',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    {
      id: 21,
      name: 'files:read',
      displayName: '查看文件',
      description: '查看和下载文件',
      resource: 'files',
      action: 'read',
      scope: 'all',
      parentId: 20
    },
    {
      id: 22,
      name: 'files:upload',
      displayName: '上传文件',
      description: '上传文件',
      resource: 'files',
      action: 'upload',
      scope: 'all',
      parentId: 20
    },
    {
      id: 23,
      name: 'files:write',
      displayName: '编辑文件',
      description: '编辑文件信息',
      resource: 'files',
      action: 'write',
      scope: 'all',
      parentId: 20
    },
    {
      id: 24,
      name: 'files:delete',
      displayName: '删除文件',
      description: '删除文件数据',
      resource: 'files',
      action: 'delete',
      scope: 'all',
      parentId: 20
    },
    {
      id: 25,
      name: 'files:share',
      displayName: '分享文件',
      description: '分享文件给其他用户',
      resource: 'files',
      action: 'share',
      scope: 'all',
      parentId: 20
    },
    
    // 导出功能
    {
      id: 26,
      name: 'export',
      displayName: '数据导出',
      description: '数据导出相关权限',
      resource: 'export',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    {
      id: 27,
      name: 'export:records',
      displayName: '导出记录',
      description: '导出记录数据',
      resource: 'export',
      action: 'records',
      scope: 'all',
      parentId: 26
    },
    {
      id: 28,
      name: 'export:users',
      displayName: '导出用户',
      description: '导出用户数据',
      resource: 'export',
      action: 'users',
      scope: 'all',
      parentId: 26
    },
    
    // 通知功能
    {
      id: 29,
      name: 'notifications',
      displayName: '通知管理',
      description: '通知管理相关权限',
      resource: 'notifications',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    {
      id: 30,
      name: 'notifications:send',
      displayName: '发送通知',
      description: '发送通知消息',
      resource: 'notifications',
      action: 'send',
      scope: 'all',
      parentId: 29
    },
    {
      id: 31,
      name: 'notifications:template',
      displayName: '通知模板',
      description: '管理通知模板',
      resource: 'notifications',
      action: 'template',
      scope: 'all',
      parentId: 29
    },
    
    // AI功能
    {
      id: 32,
      name: 'ai',
      displayName: 'AI功能',
      description: 'AI相关功能权限',
      resource: 'ai',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    {
      id: 33,
      name: 'ai:chat',
      displayName: 'AI聊天',
      description: '使用AI聊天功能',
      resource: 'ai',
      action: 'chat',
      scope: 'all',
      parentId: 32
    },
    {
      id: 34,
      name: 'ai:ocr',
      displayName: 'OCR识别',
      description: '使用OCR文字识别功能',
      resource: 'ai',
      action: 'ocr',
      scope: 'all',
      parentId: 32
    },
    {
      id: 35,
      name: 'ai:speech',
      displayName: '语音识别',
      description: '使用语音识别功能',
      resource: 'ai',
      action: 'speech',
      scope: 'all',
      parentId: 32
    },
    {
      id: 36,
      name: 'ai:config',
      displayName: 'AI配置',
      description: '管理AI配置',
      resource: 'ai',
      action: 'config',
      scope: 'all',
      parentId: 32
    },
    
    // 审计功能
    {
      id: 37,
      name: 'audit',
      displayName: '审计管理',
      description: '审计管理相关权限',
      resource: 'audit',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    {
      id: 38,
      name: 'audit:read',
      displayName: '查看审计',
      description: '查看审计日志',
      resource: 'audit',
      action: 'read',
      scope: 'all',
      parentId: 37
    },
    {
      id: 39,
      name: 'audit:cleanup',
      displayName: '清理审计',
      description: '清理旧的审计日志',
      resource: 'audit',
      action: 'cleanup',
      scope: 'all',
      parentId: 37
    }
  ]
}

// 构建权限树
const buildPermissionTree = (permissions: any[]) => {
  // 如果后端数据没有正确的父子关系，我们需要智能构建
  const hasValidHierarchy = permissions.some(p => p.parentId !== null)
  
  if (hasValidHierarchy) {
    // 使用现有的层次结构
    return buildTreeFromHierarchy(permissions)
  } else {
    // 智能构建层次结构
    return buildIntelligentTree(permissions)
  }
}

// 从现有层次结构构建树
const buildTreeFromHierarchy = (permissions: any[]) => {
  const tree: any[] = []
  const map = new Map()
  
  // 创建节点映射
  permissions.forEach(permission => {
    map.set(permission.id, {
      ...permission,
      children: []
    })
  })
  
  // 构建树结构
  permissions.forEach(permission => {
    const node = map.get(permission.id)
    if (permission.parentId && map.has(permission.parentId)) {
      map.get(permission.parentId).children.push(node)
    } else {
      tree.push(node)
    }
  })
  
  return tree
}

// 智能构建权限树结构
const buildIntelligentTree = (permissions: any[]) => {
  const tree: any[] = []
  const resourceGroups: Record<string, any[]> = {}
  
  // 按资源分组
  permissions.forEach(permission => {
    const resource = permission.resource
    if (!resourceGroups[resource]) {
      resourceGroups[resource] = []
    }
    resourceGroups[resource].push(permission)
  })
  
  // 为每个资源组创建树节点
  Object.keys(resourceGroups).forEach(resource => {
    const group = resourceGroups[resource]
    
    // 查找管理节点作为父节点
    const manageNode = group.find(p => p.action === 'manage')
    
    if (manageNode) {
      // 使用管理节点作为父节点
      const parentNode = {
        ...manageNode,
        children: []
      }
      
      // 将其他权限作为子节点
      group.forEach(permission => {
        if (permission.action !== 'manage') {
          parentNode.children.push({
            ...permission,
            children: []
          })
        }
      })
      
      tree.push(parentNode)
    } else {
      // 如果没有管理节点，创建一个虚拟父节点
      const resourceDisplayNames: Record<string, string> = {
        'system': '系统管理',
        'users': '用户管理',
        'roles': '角色管理', 
        'records': '记录管理',
        'files': '文件管理',
        'export': '数据导出',
        'ai': 'AI功能'
      }
      
      const parentNode = {
        id: `${resource}_parent`,
        name: resource,
        displayName: resourceDisplayNames[resource] || resource,
        description: `${resourceDisplayNames[resource] || resource}相关权限`,
        resource: resource,
        action: 'manage',
        scope: 'all',
        parentId: null,
        children: group.map(permission => ({
          ...permission,
          children: []
        }))
      }
      
      tree.push(parentNode)
    }
  })
  
  return tree
}

// 获取树中所有叶子节点的ID（用于权限分配）
const getLeafPermissionIds = (tree: any[]): any[] => {
  const leafIds: any[] = []
  const traverse = (nodes: any[]) => {
    nodes.forEach(node => {
      if (!node.children || node.children.length === 0) {
        // 叶子节点
        leafIds.push(node.id)
      } else {
        // 继续遍历子节点
        traverse(node.children)
      }
    })
  }
  traverse(tree)
  return leafIds
}

// 搜索
const handleSearch = () => {
  pagination.page = 1
  fetchRoles()
}

// 重置
const handleReset = () => {
  Object.assign(searchForm, {
    name: '',
    status: ''
  })
  handleSearch()
}

// 刷新
const handleRefresh = () => {
  fetchRoles()
}

// 选择变化
const handleSelectionChange = (selection: any[]) => {
  selectedRoles.value = selection
}

// 清除选择
const clearRoleSelection = () => {
  selectedRoles.value = []
}

// 批量启用角色
const handleBatchEnable = async () => {
  if (selectedRoles.value.length === 0) {
    ElMessage.warning('请先选择要启用的角色')
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要批量启用选中的 ${selectedRoles.value.length} 个角色吗？`,
      '批量启用确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    const roleIds = selectedRoles.value.map(role => role.id)
    await http.put(API_ENDPOINTS.ROLES.BATCH_STATUS, {
      role_ids: roleIds,
      status: 'active'
    })

    ElMessage.success('批量启用成功')
    clearRoleSelection()
    fetchRoles()
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('批量启用失败:', error)
      ElMessage.error('批量启用失败')
    }
  }
}

// 批量禁用角色
const handleBatchDisable = async () => {
  if (selectedRoles.value.length === 0) {
    ElMessage.warning('请先选择要禁用的角色')
    return
  }

  // 检查是否包含系统角色
  const systemRoles = selectedRoles.value.filter(role => role.is_system || role.isSystem)
  if (systemRoles.length > 0) {
    ElMessage.error('不能禁用系统角色')
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要批量禁用选中的 ${selectedRoles.value.length} 个角色吗？`,
      '批量禁用确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    const roleIds = selectedRoles.value.map(role => role.id)
    await http.put(API_ENDPOINTS.ROLES.BATCH_STATUS, {
      role_ids: roleIds,
      status: 'inactive'
    })

    ElMessage.success('批量禁用成功')
    clearRoleSelection()
    fetchRoles()
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('批量禁用失败:', error)
      ElMessage.error('批量禁用失败')
    }
  }
}

// 批量删除角色
const handleBatchDelete = async () => {
  if (selectedRoles.value.length === 0) {
    ElMessage.warning('请先选择要删除的角色')
    return
  }

  // 检查是否包含系统角色
  const systemRoles = selectedRoles.value.filter(role => role.is_system || role.isSystem)
  if (systemRoles.length > 0) {
    ElMessage.error('不能删除系统角色')
    return
  }

  // 检查是否有角色正在被用户使用
  const rolesInUse = selectedRoles.value.filter(role => (role.userCount || 0) > 0)
  if (rolesInUse.length > 0) {
    const roleNames = rolesInUse.map(role => role.displayName || role.name).join('、')
    ElMessage.error(`以下角色正在被用户使用，无法删除：${roleNames}`)
    return
  }

  try {
    const roleNames = selectedRoles.value.map(role => role.displayName || role.name).join('、')
    await ElMessageBox.confirm(
      `确定要批量删除以下角色吗？\n\n${roleNames}\n\n此操作不可恢复！`,
      '批量删除确认',
      {
        confirmButtonText: '确定删除',
        cancelButtonText: '取消',
        type: 'error'
      }
    )

    const roleIds = selectedRoles.value.map(role => role.id)
    await http.delete(API_ENDPOINTS.ROLES.BATCH_DELETE, {
      data: { role_ids: roleIds }
    })

    ElMessage.success('批量删除成功')
    clearRoleSelection()
    fetchRoles()
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('批量删除失败:', error)
      ElMessage.error('批量删除失败')
    }
  }
}

// 新增角色
const handleCreate = () => {
  isEdit.value = false
  resetForm()
  dialogVisible.value = true
}

// 编辑角色
const handleEdit = (row: any) => {
  isEdit.value = true
  Object.assign(formData, {
    id: row.id,
    name: row.name,
    displayName: row.displayName,
    status: row.status,
    description: row.description,
    is_system: row.is_system || row.isSystem,
    isSystem: row.is_system || row.isSystem
  })
  dialogVisible.value = true
}

// 权限管理
const handlePermissions = async (row: any) => {
  currentRole.value = row
  permissionError.value = ''
  permissionDialogVisible.value = true
  
  // 确保权限树已加载
  if (permissionTree.value.length === 0) {
    permissionLoading.value = true
    await fetchPermissions()
    permissionLoading.value = false
  }
  
  // 获取角色当前权限
  try {
    const response = await http.get(`/admin/roles/${row.id}/permissions`)
    if (response.success) {
      const rolePermissions = response.data || []
      selectedPermissions.value = rolePermissions.map((p: any) => p.id)
      
      // 设置选中的权限
      setTimeout(() => {
        permissionTreeRef.value?.setCheckedKeys(selectedPermissions.value)
      }, 100)
    } else {
      throw new Error(response.message || '获取权限失败')
    }
  } catch (error) {
    console.error('获取角色权限失败:', error)
    permissionError.value = '获取角色权限失败，请重试'
    selectedPermissions.value = row.permissions?.map((p: any) => p.id) || []
    setTimeout(() => {
      permissionTreeRef.value?.setCheckedKeys(selectedPermissions.value)
    }, 100)
  }
}

// 权限选择处理
const handlePermissionCheck = () => {
  // 获取选中的权限ID（包括半选中的父节点）
  const checkedKeys = permissionTreeRef.value?.getCheckedKeys() || []
  const halfCheckedKeys = permissionTreeRef.value?.getHalfCheckedKeys() || []
  selectedPermissions.value = [...checkedKeys, ...halfCheckedKeys]
}

// 全选权限
const handleSelectAll = () => {
  const allKeys = getAllPermissionKeys(permissionTree.value)
  permissionTreeRef.value?.setCheckedKeys(allKeys)
  selectedPermissions.value = allKeys
}

// 全不选权限
const handleSelectNone = () => {
  permissionTreeRef.value?.setCheckedKeys([])
  selectedPermissions.value = []
}

// 展开所有节点
const expandAll = () => {
  const allKeys = getAllPermissionKeys(permissionTree.value)
  allKeys.forEach(key => {
    permissionTreeRef.value?.setExpanded(key, true)
  })
}

// 折叠所有节点
const collapseAll = () => {
  const allKeys = getAllPermissionKeys(permissionTree.value)
  allKeys.forEach(key => {
    permissionTreeRef.value?.setExpanded(key, false)
  })
}

// 获取所有权限ID
const getAllPermissionKeys = (tree: any[]): string[] => {
  const keys: string[] = []
  const traverse = (nodes: any[]) => {
    nodes.forEach(node => {
      keys.push(node.id)
      if (node.children && node.children.length > 0) {
        traverse(node.children)
      }
    })
  }
  traverse(tree)
  return keys
}

// 切换状态
const handleToggleStatus = async (row: any) => {
  try {
    // 检查是否为系统角色
    if (row.is_system || row.isSystem) {
      ElMessage.error('系统角色不能修改状态')
      return
    }
    
    const newStatus = row.status === 'active' ? 'inactive' : 'active'
    const action = newStatus === 'active' ? '启用' : '禁用'
    
    await ElMessageBox.confirm(`确定要${action}角色 ${row.displayName || row.name} 吗？`, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await http.put(`/admin/roles/${row.id}`, {
      status: newStatus
    })
    
    ElMessage.success(`${action}成功`)
    fetchRoles()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('切换角色状态失败:', error)
      
      // 更具体的错误处理
      let errorMessage = '操作失败'
      if (error.response?.data?.message) {
        errorMessage = error.response.data.message
      } else if (error.response?.data?.error) {
        errorMessage = error.response.data.error
      } else if (error.message) {
        errorMessage = error.message
      }
      
      ElMessage.error(errorMessage)
    }
  }
}

// 删除角色
const handleDelete = async (row: any) => {
  try {
    // 检查是否为系统角色
    if (row.is_system || row.isSystem) {
      ElMessage.error('系统角色不能删除')
      return
    }
    
    await ElMessageBox.confirm(`确定要删除角色 ${row.displayName || row.name} 吗？`, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await http.delete(`/admin/roles/${row.id}`)
    ElMessage.success('删除成功')
    fetchRoles()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除角色失败:', error)
      
      // 更具体的错误处理
      let errorMessage = '删除失败'
      if (error.response?.data?.message) {
        errorMessage = error.response.data.message
      } else if (error.response?.data?.error) {
        errorMessage = error.response.data.error
      } else if (error.message) {
        errorMessage = error.message
      }
      
      ElMessage.error(errorMessage)
    }
  }
}

// 提交表单
const handleSubmit = async () => {
  try {
    await formRef.value.validate()
    
    // 检查是否为系统角色
    if (isEdit.value && (formData.is_system || formData.isSystem)) {
      ElMessage.error('系统角色不能修改')
      return
    }
    
    submitting.value = true
    
    if (isEdit.value) {
      await http.put(`/admin/roles/${formData.id}`, formData)
      ElMessage.success('更新成功')
    } else {
      await http.post('/admin/roles', formData)
      ElMessage.success('创建成功')
    }
    
    dialogVisible.value = false
    fetchRoles()
  } catch (error) {
    console.error('提交失败:', error)
    
    // 更具体的错误处理
    let errorMessage = '操作失败'
    if (error.response?.data?.message) {
      errorMessage = error.response.data.message
    } else if (error.response?.data?.error) {
      errorMessage = error.response.data.error
    } else if (error.message) {
      errorMessage = error.message
    }
    
    ElMessage.error(errorMessage)
  } finally {
    submitting.value = false
  }
}

// 保存权限
const handleSavePermissions = async () => {
  try {
    submitting.value = true
    
    await http.put(`/admin/roles/${currentRole.value.id}/permissions`, {
      permissionIds: selectedPermissions.value
    })
    
    ElMessage.success('权限分配成功')
    permissionDialogVisible.value = false
    fetchRoles()
  } catch (error) {
    console.error('分配权限失败:', error)
    ElMessage.error('分配权限失败')
  } finally {
    submitting.value = false
  }
}

// 分页处理
const handleSizeChange = (size: number) => {
  pagination.size = size
  fetchRoles()
}

const handleCurrentChange = (page: number) => {
  pagination.page = page
  fetchRoles()
}

// 对话框关闭
const handleDialogClose = () => {
  resetForm()
}

// 重置表单
const resetForm = () => {
  Object.assign(formData, {
    name: '',
    displayName: '',
    status: 'active',
    description: ''
  })
  formRef.value?.clearValidate()
}

// 工具函数
const formatTime = (time: string) => {
  return time ? dayjs(time).format('YYYY-MM-DD HH:mm') : '-'
}

// 导入操作处理
const handleImportAction = (command: string) => {
  switch (command) {
    case 'template':
      downloadRoleTemplate()
      break
    case 'import':
      importDialogVisible.value = true
      break
  }
}

// 下载角色导入模板
const downloadRoleTemplate = () => {
  const template = [
    ['角色名称*', '显示名称*', '描述', '状态', '权限'],
    ['user', '普通用户', '系统普通用户角色', 'active', 'records:read:own,files:read'],
    ['editor', '编辑者', '内容编辑者角色', 'active', 'records:read,records:write:own,files:read,files:upload']
  ]
  
  // 创建CSV内容
  const csvContent = template.map(row => row.join(',')).join('\n')
  const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)
  
  link.setAttribute('href', url)
  link.setAttribute('download', '角色导入模板.csv')
  link.style.visibility = 'hidden'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  
  ElMessage.success('模板下载成功')
}

// 文件上传处理
const handleRoleFileChange = (file: any) => {
  importRoleFile.value = file.raw
  parseImportRoleFile(file.raw)
}

// 文件上传前检查
const beforeRoleUpload = (file: any) => {
  const isValidType = ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 
                      'application/vnd.ms-excel', 
                      'text/csv'].includes(file.type)
  const isLt10M = file.size / 1024 / 1024 < 10

  if (!isValidType) {
    ElMessage.error('只能上传 Excel 或 CSV 文件!')
    return false
  }
  if (!isLt10M) {
    ElMessage.error('文件大小不能超过 10MB!')
    return false
  }
  return false // 阻止自动上传
}

// 解析导入文件
const parseImportRoleFile = async (file: File) => {
  try {
    const text = await file.text()
    const lines = text.split('\n').filter(line => line.trim())
    
    if (lines.length < 2) {
      ElMessage.error('文件内容不能为空')
      return
    }
    
    // 解析CSV数据
    const data = lines.slice(1).map(line => {
      const values = line.split(',').map(v => v.trim().replace(/"/g, ''))
      return {
        name: values[0] || '',
        displayName: values[1] || '',
        description: values[2] || '',
        status: values[3] || 'active',
        permissions: values[4] || ''
      }
    })
    
    importRolePreview.value = data
    
    // 验证数据
    validImportRoleData.value = data.filter(item => 
      item.name && item.displayName
    )
    
    if (validImportRoleData.value.length === 0) {
      ElMessage.error('没有找到有效的角色数据')
    } else {
      ElMessage.success(`解析成功，找到 ${validImportRoleData.value.length} 条有效数据`)
    }
  } catch (error) {
    console.error('解析文件失败:', error)
    ElMessage.error('文件解析失败')
  }
}

// 移除文件
const removeRoleFile = () => {
  importRoleFile.value = null
  importRolePreview.value = []
  validImportRoleData.value = []
  roleUploadRef.value?.clearFiles()
}

// 执行导入
const handleImportRoles = async () => {
  if (validImportRoleData.value.length === 0) {
    ElMessage.warning('没有有效的数据可以导入')
    return
  }
  
  try {
    importing.value = true
    
    const response = await http.post(API_ENDPOINTS.ROLES.IMPORT, {
      roles: validImportRoleData.value
    })
    
    const results = response.data.results || []
    const successCount = results.filter((r: any) => r.success).length
    const failCount = results.length - successCount
    
    if (failCount === 0) {
      ElMessage.success(`成功导入 ${successCount} 个角色`)
    } else {
      ElMessage.warning(`导入完成：成功 ${successCount} 个，失败 ${failCount} 个`)
    }
    
    importDialogVisible.value = false
    removeRoleFile()
    fetchRoles()
  } catch (error) {
    console.error('导入角色失败:', error)
    ElMessage.error('导入角色失败')
  } finally {
    importing.value = false
  }
}

// 格式化文件大小
const formatFileSize = (size: any) => {
  if (!size || size === 0) return '未知大小'
  
  const bytes = parseInt(size)
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
  return (bytes / (1024 * 1024 * 1024)).toFixed(1) + ' GB'
}

// 生命周期
onMounted(() => {
  fetchRoles()
  fetchPermissions()
})
</script>

<style scoped>
.role-management {
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
}

.search-bar {
  margin-bottom: 20px;
}

.search-form {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  align-items: center;
}

.search-item {
  margin-bottom: 0;
}

.search-buttons {
  margin-bottom: 0;
}

/* 批量操作样式 */
.batch-actions {
  margin-bottom: 20px;
}

.batch-buttons {
  display: flex;
  gap: 10px;
  align-items: center;
  flex-wrap: wrap;
}

.batch-buttons .el-button {
  margin: 0;
}

.action-buttons {
  display: flex;
  gap: 6px;
  justify-content: center;
  align-items: center;
  flex-wrap: nowrap;
}

.action-buttons .el-button {
  padding: 5px 8px;
  font-size: 12px;
  min-width: 48px;
  white-space: nowrap;
}

.pagination {
  margin-top: 20px;
  display: flex;
  justify-content: center;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.role-info {
  background: #f5f7fa;
  padding: 15px;
  border-radius: 4px;
  margin-bottom: 15px;
}

.role-info p {
  margin: 5px 0;
  color: #606266;
}

.permission-section {
  max-height: 500px;
  overflow-y: auto;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.section-header h4 {
  margin: 0;
  color: #303133;
}

.permission-actions {
  display: flex;
  gap: 8px;
}

.permission-stats {
  margin-bottom: 15px;
}

.permission-tree {
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  padding: 10px;
  background: #fff;
}

.tree-node {
  display: flex;
  flex-direction: column;
  width: 100%;
}

.node-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}

.node-label {
  font-weight: 500;
  color: #303133;
}

.node-tags {
  display: flex;
  gap: 4px;
  margin-left: 10px;
}

.node-tag {
  font-size: 11px;
}

.scope-tag {
  font-size: 11px;
}

.node-description {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
  margin-left: 20px;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .role-management {
    padding: 10px;
  }
  
  .search-form {
    flex-direction: column;
    align-items: stretch;
  }
  
  .search-item {
    width: 100%;
  }
  
  .action-buttons {
    flex-direction: column;
  }
  
  .action-buttons .el-button {
    width: 100%;
  }
  
  .permission-actions {
    flex-wrap: wrap;
  }
  
  .node-content {
    flex-direction: column;
    align-items: flex-start;
  }
  
  .node-tags {
    margin-left: 0;
    margin-top: 5px;
  }
}

/* 表格优化 */
.el-table {
  font-size: 14px;
}

.el-table .el-table__cell {
  padding: 12px 0;
}

/* 对话框优化 */
.el-dialog {
  margin-top: 5vh;
}

.el-dialog__body {
  padding: 20px;
}

/* 权限树优化 */
.el-tree {
  background: transparent;
}

.el-tree-node__content {
  height: auto;
  min-height: 32px;
  padding: 8px 0;
}

.el-tree-node__content:hover {
  background-color: #f5f7fa;
}

/* 标签优化 */
.el-tag {
  margin: 2px;
}

/* 按钮组优化 */
.el-button-group .el-button {
  margin: 0;
}

/* 加载状态优化 */
.el-loading-mask {
  background-color: rgba(255, 255, 255, 0.8);
}

.permission-loading {
  padding: 20px;
  text-align: center;
}

.loading-text {
  margin-top: 10px;
  color: #909399;
  font-size: 14px;
}

.no-permissions {
  padding: 40px 20px;
  text-align: center;
}

/* 权限统计标签间距 */
.permission-stats .el-tag {
  margin-right: 8px;
}

/* 错误提示样式 */
.el-alert {
  margin-bottom: 15px;
}

/* 权限树节点优化 */
.el-tree-node__expand-icon {
  color: #c0c4cc;
}

.el-tree-node__expand-icon.expanded {
  color: #409eff;
}

/* 复选框样式优化 */
.el-checkbox__input.is-checked .el-checkbox__inner {
  background-color: #409eff;
  border-color: #409eff;
}

.el-checkbox__input.is-indeterminate .el-checkbox__inner {
  background-color: #409eff;
  border-color: #409eff;
}

/* 权限节点悬停效果 */
.tree-node:hover {
  background-color: rgba(64, 158, 255, 0.05);
  border-radius: 4px;
}

/* 权限标签颜色优化 */
.node-tag {
  background-color: #ecf5ff;
  border-color: #b3d8ff;
  color: #409eff;
}

.scope-tag {
  background-color: #fdf6ec;
  border-color: #f5dab1;
  color: #e6a23c;
}
.role-management {
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

.search-bar {
  margin-bottom: 20px;
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
}

.search-form {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 16px;
}

.search-item {
  margin-bottom: 0 !important;
  margin-right: 0 !important;
}

.search-buttons {
  margin-bottom: 0 !important;
  margin-right: 0 !important;
}

.pagination {
  margin-top: 20px;
  text-align: right;
}

.action-buttons {
  display: flex;
  gap: 4px;
  justify-content: center;
  flex-wrap: wrap;
}

.action-buttons .el-button {
  padding: 6px 10px;
  font-size: 12px;
  min-width: 50px;
}

.dialog-footer {
  text-align: right;
}

.role-info {
  background: #f8f9fa;
  padding: 16px;
  border-radius: 8px;
  margin-bottom: 16px;
}

.role-info p {
  margin: 8px 0;
}

.permission-section {
  max-height: 400px;
  overflow-y: auto;
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.section-header h4 {
  margin: 0;
  color: #303133;
}

.permission-actions {
  display: flex;
  gap: 8px;
}

.permission-stats {
  margin-bottom: 12px;
  padding: 8px 12px;
  background: #f0f9ff;
  border-radius: 4px;
  border-left: 3px solid #409eff;
}

.permission-tree {
  border: 1px solid #e4e7ed;
  border-radius: 6px;
  padding: 12px;
  background: #fafafa;
  max-height: 350px;
  overflow-y: auto;
}

.tree-node {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  width: 100%;
  padding: 2px 0;
}

.node-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  gap: 8px;
}

.node-label {
  font-weight: 500;
  color: #303133;
  font-size: 14px;
  flex: 1;
}

.node-tags {
  display: flex;
  gap: 4px;
  align-items: center;
}

.node-tag {
  font-size: 10px;
  height: 18px;
  line-height: 16px;
}

.scope-tag {
  font-size: 10px;
  height: 18px;
  line-height: 16px;
}

.node-description {
  font-size: 12px;
  color: #909399;
  margin-top: 2px;
  margin-left: 2px;
  line-height: 1.4;
}

/* 权限树样式优化 */
.permission-tree :deep(.el-tree-node__content) {
  padding: 6px 0;
  height: auto;
  min-height: 32px;
}

.permission-tree :deep(.el-tree-node__expand-icon) {
  color: #409eff;
}

.permission-tree :deep(.el-checkbox) {
  margin-right: 8px;
}

.permission-tree :deep(.el-tree-node__label) {
  font-size: 14px;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .role-management {
    padding: 10px;
  }
  
  .search-form {
    flex-direction: column;
    align-items: stretch;
  }
  
  .search-item,
  .search-buttons {
    width: 100%;
  }
  
  .search-item .el-input,
  .search-item .el-select {
    width: 100% !important;
  }
  
  .header-actions {
    flex-direction: column;
    gap: 8px;
  }
  
  .header-actions .el-button {
    width: 100%;
  }
  
  .action-buttons {
    flex-direction: column;
    gap: 2px;
  }
  
  .action-buttons .el-button {
    width: 100%;
  }
  
  .section-header {
    flex-direction: column;
    align-items: stretch;
  }
  
  .section-header h4 {
    margin-bottom: 10px;
  }
}
</style>