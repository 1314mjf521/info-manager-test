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

    <!-- 权限分配对话框 - 优化版 -->
    <el-dialog 
      v-model="permissionDialogVisible" 
      title="权限管理" 
      width="900px"
      :close-on-click-modal="false"
      class="permission-dialog"
    >
      <div v-if="currentRole">
        <!-- 角色信息卡片 -->
        <el-card class="role-info-card" shadow="never">
          <div class="role-header">
            <div class="role-avatar">
              <el-icon size="24"><User /></el-icon>
            </div>
            <div class="role-details">
              <h4>{{ currentRole.displayName || currentRole.name }}</h4>
              <p class="role-description">{{ currentRole.description || '暂无描述' }}</p>
              <el-tag size="small" :type="currentRole.status === 'active' ? 'success' : 'danger'">
                {{ currentRole.status === 'active' ? '启用' : '禁用' }}
              </el-tag>
            </div>
          </div>
        </el-card>
        
        <el-divider />
        
        <!-- 权限说明 -->
        <el-alert
          title="权限体系说明"
          type="info"
          :closable="false"
          style="margin-bottom: 15px;"
        >
          <template #default>
            <div class="permission-help">
              <p><strong>精细化权限体系：</strong></p>
              <ul>
                <li><strong>模块权限：</strong>按功能模块划分（系统管理、用户管理、记录管理等）</li>
                <li><strong>操作权限：</strong>细分到具体操作（查看、创建、编辑、删除、导入、导出等）</li>
                <li><strong>数据范围：</strong>支持全部数据、仅自己数据、部门数据等不同范围</li>
                <li><strong>层级结构：</strong>采用三级权限结构，便于管理和分配</li>
              </ul>
            </div>
          </template>
        </el-alert>

        <!-- 权限管理区域 -->
        <div class="permission-section">
          <!-- 操作工具栏 -->
          <div class="permission-toolbar">
            <div class="toolbar-left">
              <h4>系统权限配置</h4>
              <div class="permission-stats">
                <el-tag size="small" type="info">
                  已选择: {{ permissionStats.selected }} 项
                </el-tag>
                <el-tag size="small" type="success">
                  总计: {{ permissionStats.total }} 项
                </el-tag>
                <el-tag size="small" :type="permissionStats.coverage > 50 ? 'warning' : 'info'">
                  覆盖率: {{ permissionStats.coverage }}%
                </el-tag>
                <el-popover placement="bottom" :width="300" trigger="hover">
                  <template #reference>
                    <el-tag size="small" type="warning" style="cursor: pointer;">
                      调试信息
                    </el-tag>
                  </template>
                  <div class="debug-info">
                    <p><strong>权限数据状态：</strong></p>
                    <p>原始权限树: {{ permissionTree.length }} 个节点</p>
                    <p>过滤权限树: {{ filteredPermissionTree.length }} 个节点</p>
                    <p>权限分类: {{ permissionCategories.length }} 个模块</p>
                    <p>加载状态: {{ permissionLoading ? '加载中' : '已完成' }}</p>
                    <p>搜索文本: {{ permissionSearchText || '无' }}</p>
                    <p>选中分类: {{ selectedCategory || '全部' }}</p>
                  </div>
                </el-popover>
              </div>
            </div>
            <div class="toolbar-right">
              <!-- 权限搜索 -->
              <el-input
                v-model="permissionSearchText"
                placeholder="搜索权限..."
                size="small"
                style="width: 200px; margin-right: 10px;"
                clearable
                @input="handlePermissionSearch"
              >
                <template #prefix>
                  <el-icon><Search /></el-icon>
                </template>
              </el-input>
              <!-- 快捷操作 -->
              <el-button-group size="small">
                <el-button @click="expandAll" :disabled="permissionLoading">
                  <el-icon><Plus /></el-icon>
                  展开
                </el-button>
                <el-button @click="collapseAll" :disabled="permissionLoading">
                  <el-icon><Minus /></el-icon>
                  折叠
                </el-button>
              </el-button-group>
              <el-button-group size="small" style="margin-left: 10px;">
                <el-button type="success" @click="handleSelectAll" :disabled="permissionLoading">
                  全选
                </el-button>
                <el-button type="warning" @click="handleSelectNone" :disabled="permissionLoading">
                  清空
                </el-button>
              </el-button-group>
              <el-button size="small" type="info" @click="forceRefreshPermissions" style="margin-left: 10px;">
                <el-icon><RefreshRight /></el-icon>
                刷新权限
              </el-button>
            </div>
          </div>

          <!-- 权限分类标签 -->
          <div class="permission-categories" v-if="permissionCategories.length > 0">
            <div class="categories-header">
              <span class="categories-title">权限模块分类：</span>
              <el-tag size="small" type="info">
                共 {{ permissionCategories.length }} 个模块
              </el-tag>
            </div>
            <div class="categories-tags">
              <el-tag
                v-for="category in permissionCategories"
                :key="category.key"
                :type="selectedCategory === category.key ? 'primary' : undefined"
                :effect="selectedCategory === category.key ? 'dark' : 'plain'"
                @click="handleCategoryFilter(category.key)"
                style="margin-right: 8px; margin-bottom: 8px; cursor: pointer;"
              >
                {{ category.name }} ({{ category.count }})
              </el-tag>
            </div>
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
          <div v-if="!permissionLoading" class="permission-tree-container">
            <el-scrollbar height="400px">
              <el-tree
                ref="permissionTreeRef"
                :data="getDisplayPermissionTree()"
                :props="treeProps"
                show-checkbox
                node-key="id"
                :default-checked-keys="selectedPermissions"
                :default-expand-all="false"
                :expand-on-click-node="false"
                :check-on-click-node="true"
                :check-strictly="true"
                :filter-node-method="filterPermissionNode"
                @check="handlePermissionCheck"
                class="permission-tree"
              >
                <template #default="{ node, data }">
                  <div class="tree-node">
                    <div class="node-content">
                      <div class="node-main">
                        <span class="node-label">{{ data.displayName || data.name }}</span>
                        <div class="node-tags">
                          <el-tag v-if="data.resource && data.action" size="small" type="info" class="node-tag">
                            {{ data.resource }}:{{ data.action }}
                          </el-tag>
                          <el-tag v-if="data.scope && data.scope !== 'all'" size="small" :type="getScopeTagType(data.scope)" class="scope-tag">
                            {{ getScopeDisplayName(data.scope) }}
                          </el-tag>
                        </div>
                      </div>
                      <div v-if="data.description" class="node-description">
                        {{ data.description }}
                      </div>
                    </div>
                    <div class="node-actions" v-if="data.children && data.children.length > 0">
                      <el-button
                        size="small"
                        text
                        @click.stop="toggleNodeSelection(data)"
                        :type="isNodeFullySelected(data) ? 'warning' : 'success'"
                      >
                        {{ isNodeFullySelected(data) ? '取消全选' : '全选子项' }}
                      </el-button>
                    </div>
                  </div>
                </template>
              </el-tree>
            </el-scrollbar>
            
            <!-- 如果没有权限数据，显示提示 -->
            <div v-if="getDisplayPermissionTree().length === 0" class="no-permissions-inline">
              <el-empty description="暂无权限数据" :image-size="80">
                <div class="empty-actions">
                  <el-button type="primary" @click="forceRefreshPermissions" size="small">
                    <el-icon><RefreshRight /></el-icon>
                    强制刷新
                  </el-button>
                  <el-button type="success" @click="loadMockPermissions" size="small">
                    <el-icon><Plus /></el-icon>
                    使用模拟权限
                  </el-button>
                </div>
                <div class="empty-tip">
                  <el-text type="info" size="small">
                    提示：如果权限数据未更新，请点击"强制刷新"或"使用精细化权限"
                  </el-text>
                </div>
              </el-empty>
            </div>
          </div>

        </div>
      </div>
      
      <template #footer>
        <div class="dialog-footer">
          <div class="footer-info">
            <el-text type="info" size="small">
              提示：权限修改后将立即生效，请谨慎操作
            </el-text>
          </div>
          <div class="footer-actions">
            <el-button @click="permissionDialogVisible = false">取消</el-button>
            <el-button type="primary" @click="handleSavePermissions" :loading="submitting">
              <el-icon><Check /></el-icon>
              保存权限
            </el-button>
          </div>
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
import { Plus, Refresh, Search, RefreshRight, Upload, ArrowDown, UploadFilled, Document, User, Check, Minus } from '@element-plus/icons-vue'
import { http } from '../../utils/request'
import { API_ENDPOINTS } from '../../config/api'
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

// 权限搜索和过滤
const permissionSearchText = ref('')
const selectedCategory = ref('')
const permissionCategories = ref([])
const filteredPermissionTree = ref([])

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
const permissionStats = computed(() => {
  const tree = getDisplayPermissionTree()
  const total = getAllPermissionKeys(tree).length
  const selected = selectedPermissions.value.length
  
  // 统计各个模块的权限数量
  const moduleStats = permissionCategories.value.map(category => ({
    name: category.name,
    total: category.count,
    selected: selectedPermissions.value.filter(id => {
      const permission = findPermissionById(tree, id)
      return permission && permission.resource === category.key
    }).length
  }))
  
  return { 
    total, 
    selected, 
    modules: moduleStats,
    coverage: total > 0 ? Math.round((selected / total) * 100) : 0
  }
})

// 根据ID查找权限
const findPermissionById = (tree: any[], id: any): any => {
  for (const node of tree) {
    if (node.id === id) return node
    if (node.children && node.children.length > 0) {
      const found = findPermissionById(node.children, id)
      if (found) return found
    }
  }
  return null
}

// 验证权限数据完整性
const validatePermissionData = (tree: any[]) => {
  const stats = {
    totalNodes: 0,
    moduleNodes: 0,
    leafNodes: 0,
    modules: new Set()
  }
  
  const traverse = (nodes: any[], level = 0) => {
    nodes.forEach(node => {
      stats.totalNodes++
      if (node.resource) {
        stats.modules.add(node.resource)
      }
      
      if (level === 0) {
        stats.moduleNodes++
      }
      
      if (!node.children || node.children.length === 0) {
        stats.leafNodes++
      } else {
        traverse(node.children, level + 1)
      }
    })
  }
  
  traverse(tree)
  
  console.log('权限数据验证结果:', {
    ...stats,
    modules: Array.from(stats.modules)
  })
  
  return stats
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
  console.log('开始获取权限树数据...')
  
  try {
    // 直接调用权限树API
    console.log('调用权限树API: /permissions/tree')
    const treeResponse = await http.get('/permissions/tree')
    
    console.log('权限树API响应:', {
      success: treeResponse.success,
      dataLength: treeResponse.data?.length,
      data: treeResponse.data
    })
    
    if (treeResponse.success && treeResponse.data && treeResponse.data.length > 0) {
      // 直接使用后端返回的权限树数据
      permissionTree.value = treeResponse.data
      console.log('权限树加载成功，根节点数量:', permissionTree.value.length)
      
      // 统计总权限数量
      const totalCount = countAllPermissions(permissionTree.value)
      console.log('总权限数量:', totalCount)
      
      permissionError.value = ''
    } else {
      throw new Error('权限树数据为空或格式错误')
    }
  } catch (error) {
    console.error('获取权限树失败:', error)
    
    // 重试机制
    if (retryCount < 2) {
      console.log(`权限获取失败，进行第${retryCount + 1}次重试...`)
      setTimeout(() => {
        fetchPermissions(retryCount + 1)
      }, 1000 * (retryCount + 1))
      return
    }
    
    // 最终失败，设置错误信息
    permissionError.value = '权限树加载失败，请刷新页面重试'
    permissionTree.value = []
  }
  
  // 初始化权限分类和过滤树
  permissionCategories.value = getPermissionCategories(permissionTree.value)
  filteredPermissionTree.value = [...permissionTree.value]
  
  // 验证权限数据完整性
  if (permissionTree.value.length > 0) {
    validatePermissionData(permissionTree.value)
  }
}

// 处理后端权限数据，补充缺失信息
const processBackendPermissions = (permissions: any[]) => {
  const resourceDisplayNames: Record<string, string> = {
    'system': '系统管理',
    'users': '用户管理', 
    'roles': '角色管理',
    'permissions': '权限管理',
    'records': '记录管理',
    'record-types': '记录类型管理',
    'files': '文件管理',
    'export': '数据导出',
    'notifications': '通知管理',
    'ai': 'AI功能',
    'audit': '审计日志',
    'dashboard': '仪表盘',
    'ticket': '工单系统',
    'tickets': '工单系统'
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

// 模拟权限数据 - 精细化权限体系
const getMockPermissions = () => {
  return [
    // ==================== 系统管理模块 ====================
    {
      id: 1,
      name: 'system',
      displayName: '系统管理',
      description: '系统管理模块总权限',
      resource: 'system',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    // 系统配置管理
    {
      id: 101,
      name: 'system:config',
      displayName: '系统配置管理',
      description: '系统配置相关权限',
      resource: 'system',
      action: 'config',
      scope: 'all',
      parentId: 1
    },
    {
      id: 1011,
      name: 'system:config:read',
      displayName: '查看系统配置',
      description: '查看系统配置列表和详情',
      resource: 'system',
      action: 'config:read',
      scope: 'all',
      parentId: 101
    },
    {
      id: 1012,
      name: 'system:config:write',
      displayName: '编辑系统配置',
      description: '创建、修改系统配置',
      resource: 'system',
      action: 'config:write',
      scope: 'all',
      parentId: 101
    },
    {
      id: 1013,
      name: 'system:config:delete',
      displayName: '删除系统配置',
      description: '删除系统配置项',
      resource: 'system',
      action: 'config:delete',
      scope: 'all',
      parentId: 101
    },
    {
      id: 1014,
      name: 'system:config:import',
      displayName: '导入系统配置',
      description: '批量导入系统配置',
      resource: 'system',
      action: 'config:import',
      scope: 'all',
      parentId: 101
    },
    {
      id: 1015,
      name: 'system:config:export',
      displayName: '导出系统配置',
      description: '导出系统配置数据',
      resource: 'system',
      action: 'config:export',
      scope: 'all',
      parentId: 101
    },
    // 系统监控
    {
      id: 102,
      name: 'system:monitor',
      displayName: '系统监控',
      description: '系统监控相关权限',
      resource: 'system',
      action: 'monitor',
      scope: 'all',
      parentId: 1
    },
    {
      id: 1021,
      name: 'system:monitor:health',
      displayName: '系统健康检查',
      description: '查看系统健康状态',
      resource: 'system',
      action: 'monitor:health',
      scope: 'all',
      parentId: 102
    },
    {
      id: 1022,
      name: 'system:monitor:metrics',
      displayName: '系统指标监控',
      description: '查看系统性能指标',
      resource: 'system',
      action: 'monitor:metrics',
      scope: 'all',
      parentId: 102
    },
    // 系统日志
    {
      id: 103,
      name: 'system:logs',
      displayName: '系统日志管理',
      description: '系统日志相关权限',
      resource: 'system',
      action: 'logs',
      scope: 'all',
      parentId: 1
    },
    {
      id: 1031,
      name: 'system:logs:read',
      displayName: '查看系统日志',
      description: '查看系统日志记录',
      resource: 'system',
      action: 'logs:read',
      scope: 'all',
      parentId: 103
    },
    {
      id: 1032,
      name: 'system:logs:delete',
      displayName: '删除系统日志',
      description: '删除系统日志记录',
      resource: 'system',
      action: 'logs:delete',
      scope: 'all',
      parentId: 103
    },
    {
      id: 1033,
      name: 'system:logs:export',
      displayName: '导出系统日志',
      description: '导出系统日志数据',
      resource: 'system',
      action: 'logs:export',
      scope: 'all',
      parentId: 103
    },
    // 公告管理
    {
      id: 104,
      name: 'system:announcements',
      displayName: '公告管理',
      description: '系统公告相关权限',
      resource: 'system',
      action: 'announcements',
      scope: 'all',
      parentId: 1
    },
    {
      id: 1041,
      name: 'system:announcements:read',
      displayName: '查看公告',
      description: '查看系统公告',
      resource: 'system',
      action: 'announcements:read',
      scope: 'all',
      parentId: 104
    },
    {
      id: 1042,
      name: 'system:announcements:write',
      displayName: '发布公告',
      description: '创建、编辑系统公告',
      resource: 'system',
      action: 'announcements:write',
      scope: 'all',
      parentId: 104
    },
    {
      id: 1043,
      name: 'system:announcements:delete',
      displayName: '删除公告',
      description: '删除系统公告',
      resource: 'system',
      action: 'announcements:delete',
      scope: 'all',
      parentId: 104
    },
    
    // ==================== 用户管理模块 ====================
    {
      id: 2,
      name: 'users',
      displayName: '用户管理',
      description: '用户管理模块总权限',
      resource: 'users',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    // 用户基础操作
    {
      id: 201,
      name: 'users:basic',
      displayName: '用户基础操作',
      description: '用户基础CRUD操作',
      resource: 'users',
      action: 'basic',
      scope: 'all',
      parentId: 2
    },
    {
      id: 2011,
      name: 'users:read',
      displayName: '查看用户',
      description: '查看用户列表和详情',
      resource: 'users',
      action: 'read',
      scope: 'all',
      parentId: 201
    },
    {
      id: 2012,
      name: 'users:create',
      displayName: '创建用户',
      description: '创建新用户账号',
      resource: 'users',
      action: 'create',
      scope: 'all',
      parentId: 201
    },
    {
      id: 2013,
      name: 'users:update',
      displayName: '编辑用户',
      description: '编辑用户基本信息',
      resource: 'users',
      action: 'update',
      scope: 'all',
      parentId: 201
    },
    {
      id: 2014,
      name: 'users:delete',
      displayName: '删除用户',
      description: '删除用户账号',
      resource: 'users',
      action: 'delete',
      scope: 'all',
      parentId: 201
    },
    // 用户高级操作
    {
      id: 202,
      name: 'users:advanced',
      displayName: '用户高级操作',
      description: '用户高级管理功能',
      resource: 'users',
      action: 'advanced',
      scope: 'all',
      parentId: 2
    },
    {
      id: 2021,
      name: 'users:reset_password',
      displayName: '重置密码',
      description: '重置用户密码',
      resource: 'users',
      action: 'reset_password',
      scope: 'all',
      parentId: 202
    },
    {
      id: 2022,
      name: 'users:change_status',
      displayName: '修改用户状态',
      description: '启用/禁用用户账号',
      resource: 'users',
      action: 'change_status',
      scope: 'all',
      parentId: 202
    },
    {
      id: 2023,
      name: 'users:assign_roles',
      displayName: '分配角色',
      description: '为用户分配角色',
      resource: 'users',
      action: 'assign_roles',
      scope: 'all',
      parentId: 202
    },
    {
      id: 2024,
      name: 'users:batch_operations',
      displayName: '批量操作',
      description: '批量管理用户',
      resource: 'users',
      action: 'batch_operations',
      scope: 'all',
      parentId: 202
    },
    // 用户数据操作
    {
      id: 203,
      name: 'users:data',
      displayName: '用户数据操作',
      description: '用户数据导入导出',
      resource: 'users',
      action: 'data',
      scope: 'all',
      parentId: 2
    },
    {
      id: 2031,
      name: 'users:import',
      displayName: '导入用户',
      description: '批量导入用户数据',
      resource: 'users',
      action: 'import',
      scope: 'all',
      parentId: 203
    },
    {
      id: 2032,
      name: 'users:export',
      displayName: '导出用户',
      description: '导出用户数据',
      resource: 'users',
      action: 'export',
      scope: 'all',
      parentId: 203
    },
    
    // ==================== 角色权限管理模块 ====================
    {
      id: 3,
      name: 'roles',
      displayName: '角色权限管理',
      description: '角色权限管理模块总权限',
      resource: 'roles',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    // 角色基础操作
    {
      id: 301,
      name: 'roles:basic',
      displayName: '角色基础操作',
      description: '角色基础CRUD操作',
      resource: 'roles',
      action: 'basic',
      scope: 'all',
      parentId: 3
    },
    {
      id: 3011,
      name: 'roles:read',
      displayName: '查看角色',
      description: '查看角色列表和详情',
      resource: 'roles',
      action: 'read',
      scope: 'all',
      parentId: 301
    },
    {
      id: 3012,
      name: 'roles:create',
      displayName: '创建角色',
      description: '创建新角色',
      resource: 'roles',
      action: 'create',
      scope: 'all',
      parentId: 301
    },
    {
      id: 3013,
      name: 'roles:update',
      displayName: '编辑角色',
      description: '编辑角色基本信息',
      resource: 'roles',
      action: 'update',
      scope: 'all',
      parentId: 301
    },
    {
      id: 3014,
      name: 'roles:delete',
      displayName: '删除角色',
      description: '删除角色',
      resource: 'roles',
      action: 'delete',
      scope: 'all',
      parentId: 301
    },
    // 权限管理
    {
      id: 302,
      name: 'roles:permissions',
      displayName: '权限管理',
      description: '角色权限分配管理',
      resource: 'roles',
      action: 'permissions',
      scope: 'all',
      parentId: 3
    },
    {
      id: 3021,
      name: 'roles:assign_permissions',
      displayName: '分配权限',
      description: '为角色分配权限',
      resource: 'roles',
      action: 'assign_permissions',
      scope: 'all',
      parentId: 302
    },
    {
      id: 3022,
      name: 'roles:view_permissions',
      displayName: '查看权限',
      description: '查看角色权限详情',
      resource: 'roles',
      action: 'view_permissions',
      scope: 'all',
      parentId: 302
    },
    {
      id: 3023,
      name: 'roles:copy_permissions',
      displayName: '复制权限',
      description: '复制角色权限到其他角色',
      resource: 'roles',
      action: 'copy_permissions',
      scope: 'all',
      parentId: 302
    },
    // 角色数据操作
    {
      id: 303,
      name: 'roles:data',
      displayName: '角色数据操作',
      description: '角色数据导入导出',
      resource: 'roles',
      action: 'data',
      scope: 'all',
      parentId: 3
    },
    {
      id: 3031,
      name: 'roles:import',
      displayName: '导入角色',
      description: '批量导入角色数据',
      resource: 'roles',
      action: 'import',
      scope: 'all',
      parentId: 303
    },
    {
      id: 3032,
      name: 'roles:export',
      displayName: '导出角色',
      description: '导出角色数据',
      resource: 'roles',
      action: 'export',
      scope: 'all',
      parentId: 303
    },
    
    // ==================== 记录管理模块 ====================
    {
      id: 4,
      name: 'records',
      displayName: '记录管理',
      description: '记录管理模块总权限',
      resource: 'records',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    // 记录查看权限
    {
      id: 401,
      name: 'records:read',
      displayName: '记录查看权限',
      description: '记录查看相关权限',
      resource: 'records',
      action: 'read',
      scope: 'all',
      parentId: 4
    },
    {
      id: 4011,
      name: 'records:read:all',
      displayName: '查看所有记录',
      description: '查看系统中所有记录',
      resource: 'records',
      action: 'read:all',
      scope: 'all',
      parentId: 401
    },
    {
      id: 4012,
      name: 'records:read:own',
      displayName: '查看自己的记录',
      description: '只能查看自己创建的记录',
      resource: 'records',
      action: 'read:own',
      scope: 'own',
      parentId: 401
    },
    {
      id: 4013,
      name: 'records:read:department',
      displayName: '查看部门记录',
      description: '查看本部门的记录',
      resource: 'records',
      action: 'read:department',
      scope: 'department',
      parentId: 401
    },
    {
      id: 4014,
      name: 'records:read:details',
      displayName: '查看记录详情',
      description: '查看记录的详细信息',
      resource: 'records',
      action: 'read:details',
      scope: 'all',
      parentId: 401
    },
    // 记录编辑权限
    {
      id: 402,
      name: 'records:write',
      displayName: '记录编辑权限',
      description: '记录编辑相关权限',
      resource: 'records',
      action: 'write',
      scope: 'all',
      parentId: 4
    },
    {
      id: 4021,
      name: 'records:create',
      displayName: '创建记录',
      description: '创建新记录',
      resource: 'records',
      action: 'create',
      scope: 'all',
      parentId: 402
    },
    {
      id: 4022,
      name: 'records:update:all',
      displayName: '编辑所有记录',
      description: '编辑系统中所有记录',
      resource: 'records',
      action: 'update:all',
      scope: 'all',
      parentId: 402
    },
    {
      id: 4023,
      name: 'records:update:own',
      displayName: '编辑自己的记录',
      description: '只能编辑自己创建的记录',
      resource: 'records',
      action: 'update:own',
      scope: 'own',
      parentId: 402
    },
    {
      id: 4024,
      name: 'records:update:department',
      displayName: '编辑部门记录',
      description: '编辑本部门的记录',
      resource: 'records',
      action: 'update:department',
      scope: 'department',
      parentId: 402
    },
    // 记录删除权限
    {
      id: 403,
      name: 'records:delete',
      displayName: '记录删除权限',
      description: '记录删除相关权限',
      resource: 'records',
      action: 'delete',
      scope: 'all',
      parentId: 4
    },
    {
      id: 4031,
      name: 'records:delete:all',
      displayName: '删除所有记录',
      description: '删除系统中所有记录',
      resource: 'records',
      action: 'delete:all',
      scope: 'all',
      parentId: 403
    },
    {
      id: 4032,
      name: 'records:delete:own',
      displayName: '删除自己的记录',
      description: '只能删除自己创建的记录',
      resource: 'records',
      action: 'delete:own',
      scope: 'own',
      parentId: 403
    },
    {
      id: 4033,
      name: 'records:delete:department',
      displayName: '删除部门记录',
      description: '删除本部门的记录',
      resource: 'records',
      action: 'delete:department',
      scope: 'department',
      parentId: 403
    },
    // 记录类型管理
    {
      id: 404,
      name: 'records:types',
      displayName: '记录类型管理',
      description: '记录类型管理权限',
      resource: 'records',
      action: 'types',
      scope: 'all',
      parentId: 4
    },
    {
      id: 4041,
      name: 'records:types:read',
      displayName: '查看记录类型',
      description: '查看记录类型配置',
      resource: 'records',
      action: 'types:read',
      scope: 'all',
      parentId: 404
    },
    {
      id: 4042,
      name: 'records:types:write',
      displayName: '管理记录类型',
      description: '创建、编辑记录类型',
      resource: 'records',
      action: 'types:write',
      scope: 'all',
      parentId: 404
    },
    {
      id: 4043,
      name: 'records:types:delete',
      displayName: '删除记录类型',
      description: '删除记录类型配置',
      resource: 'records',
      action: 'types:delete',
      scope: 'all',
      parentId: 404
    },
    // 记录批量操作
    {
      id: 405,
      name: 'records:batch',
      displayName: '记录批量操作',
      description: '记录批量操作权限',
      resource: 'records',
      action: 'batch',
      scope: 'all',
      parentId: 4
    },
    {
      id: 4051,
      name: 'records:batch:import',
      displayName: '批量导入记录',
      description: '批量导入记录数据',
      resource: 'records',
      action: 'batch:import',
      scope: 'all',
      parentId: 405
    },
    {
      id: 4052,
      name: 'records:batch:export',
      displayName: '批量导出记录',
      description: '批量导出记录数据',
      resource: 'records',
      action: 'batch:export',
      scope: 'all',
      parentId: 405
    },
    {
      id: 4053,
      name: 'records:batch:update',
      displayName: '批量更新记录',
      description: '批量更新记录状态',
      resource: 'records',
      action: 'batch:update',
      scope: 'all',
      parentId: 405
    },
    {
      id: 4054,
      name: 'records:batch:delete',
      displayName: '批量删除记录',
      description: '批量删除记录数据',
      resource: 'records',
      action: 'batch:delete',
      scope: 'all',
      parentId: 405
    },
    
    // ==================== 文件管理模块 ====================
    {
      id: 5,
      name: 'files',
      displayName: '文件管理',
      description: '文件管理模块总权限',
      resource: 'files',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    // 文件基础操作
    {
      id: 501,
      name: 'files:basic',
      displayName: '文件基础操作',
      description: '文件基础操作权限',
      resource: 'files',
      action: 'basic',
      scope: 'all',
      parentId: 5
    },
    {
      id: 5011,
      name: 'files:read:all',
      displayName: '查看所有文件',
      description: '查看和下载所有文件',
      resource: 'files',
      action: 'read:all',
      scope: 'all',
      parentId: 501
    },
    {
      id: 5012,
      name: 'files:read:own',
      displayName: '查看自己的文件',
      description: '只能查看自己上传的文件',
      resource: 'files',
      action: 'read:own',
      scope: 'own',
      parentId: 501
    },
    {
      id: 5013,
      name: 'files:upload',
      displayName: '上传文件',
      description: '上传文件到系统',
      resource: 'files',
      action: 'upload',
      scope: 'all',
      parentId: 501
    },
    {
      id: 5014,
      name: 'files:download',
      displayName: '下载文件',
      description: '下载文件到本地',
      resource: 'files',
      action: 'download',
      scope: 'all',
      parentId: 501
    },
    // 文件高级操作
    {
      id: 502,
      name: 'files:advanced',
      displayName: '文件高级操作',
      description: '文件高级管理功能',
      resource: 'files',
      action: 'advanced',
      scope: 'all',
      parentId: 5
    },
    {
      id: 5021,
      name: 'files:update:all',
      displayName: '编辑所有文件',
      description: '编辑所有文件信息',
      resource: 'files',
      action: 'update:all',
      scope: 'all',
      parentId: 502
    },
    {
      id: 5022,
      name: 'files:update:own',
      displayName: '编辑自己的文件',
      description: '只能编辑自己上传的文件',
      resource: 'files',
      action: 'update:own',
      scope: 'own',
      parentId: 502
    },
    {
      id: 5023,
      name: 'files:delete:all',
      displayName: '删除所有文件',
      description: '删除系统中所有文件',
      resource: 'files',
      action: 'delete:all',
      scope: 'all',
      parentId: 502
    },
    {
      id: 5024,
      name: 'files:delete:own',
      displayName: '删除自己的文件',
      description: '只能删除自己上传的文件',
      resource: 'files',
      action: 'delete:own',
      scope: 'own',
      parentId: 502
    },
    {
      id: 5025,
      name: 'files:share',
      displayName: '分享文件',
      description: '分享文件给其他用户',
      resource: 'files',
      action: 'share',
      scope: 'all',
      parentId: 502
    },
    // OCR功能
    {
      id: 503,
      name: 'files:ocr',
      displayName: 'OCR文字识别',
      description: 'OCR文字识别功能',
      resource: 'files',
      action: 'ocr',
      scope: 'all',
      parentId: 5
    },
    {
      id: 5031,
      name: 'files:ocr:use',
      displayName: '使用OCR功能',
      description: '使用OCR识别文件中的文字',
      resource: 'files',
      action: 'ocr:use',
      scope: 'all',
      parentId: 503
    },
    {
      id: 5032,
      name: 'files:ocr:batch',
      displayName: '批量OCR识别',
      description: '批量进行OCR文字识别',
      resource: 'files',
      action: 'ocr:batch',
      scope: 'all',
      parentId: 503
    },
    
    // ==================== 数据导出模块 ====================
    {
      id: 6,
      name: 'export',
      displayName: '数据导出',
      description: '数据导出模块总权限',
      resource: 'export',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    // 导出模板管理
    {
      id: 601,
      name: 'export:templates',
      displayName: '导出模板管理',
      description: '导出模板管理权限',
      resource: 'export',
      action: 'templates',
      scope: 'all',
      parentId: 6
    },
    {
      id: 6011,
      name: 'export:templates:read',
      displayName: '查看导出模板',
      description: '查看导出模板列表',
      resource: 'export',
      action: 'templates:read',
      scope: 'all',
      parentId: 601
    },
    {
      id: 6012,
      name: 'export:templates:write',
      displayName: '管理导出模板',
      description: '创建、编辑导出模板',
      resource: 'export',
      action: 'templates:write',
      scope: 'all',
      parentId: 601
    },
    {
      id: 6013,
      name: 'export:templates:delete',
      displayName: '删除导出模板',
      description: '删除导出模板',
      resource: 'export',
      action: 'templates:delete',
      scope: 'all',
      parentId: 601
    },
    // 数据导出操作
    {
      id: 602,
      name: 'export:data',
      displayName: '数据导出操作',
      description: '数据导出操作权限',
      resource: 'export',
      action: 'data',
      scope: 'all',
      parentId: 6
    },
    {
      id: 6021,
      name: 'export:records:all',
      displayName: '导出所有记录',
      description: '导出系统中所有记录数据',
      resource: 'export',
      action: 'records:all',
      scope: 'all',
      parentId: 602
    },
    {
      id: 6022,
      name: 'export:records:own',
      displayName: '导出自己的记录',
      description: '只能导出自己创建的记录',
      resource: 'export',
      action: 'records:own',
      scope: 'own',
      parentId: 602
    },
    {
      id: 6023,
      name: 'export:users',
      displayName: '导出用户数据',
      description: '导出用户数据',
      resource: 'export',
      action: 'users',
      scope: 'all',
      parentId: 602
    },
    {
      id: 6024,
      name: 'export:files',
      displayName: '导出文件数据',
      description: '导出文件信息数据',
      resource: 'export',
      action: 'files',
      scope: 'all',
      parentId: 602
    },
    {
      id: 6025,
      name: 'export:logs',
      displayName: '导出系统日志',
      description: '导出系统日志数据',
      resource: 'export',
      action: 'logs',
      scope: 'all',
      parentId: 602
    },
    // 导出任务管理
    {
      id: 603,
      name: 'export:tasks',
      displayName: '导出任务管理',
      description: '导出任务管理权限',
      resource: 'export',
      action: 'tasks',
      scope: 'all',
      parentId: 6
    },
    {
      id: 6031,
      name: 'export:tasks:read',
      displayName: '查看导出任务',
      description: '查看导出任务列表和进度',
      resource: 'export',
      action: 'tasks:read',
      scope: 'all',
      parentId: 603
    },
    {
      id: 6032,
      name: 'export:tasks:download',
      displayName: '下载导出文件',
      description: '下载导出的文件',
      resource: 'export',
      action: 'tasks:download',
      scope: 'all',
      parentId: 603
    },
    {
      id: 6033,
      name: 'export:tasks:delete',
      displayName: '删除导出任务',
      description: '删除导出任务和文件',
      resource: 'export',
      action: 'tasks:delete',
      scope: 'all',
      parentId: 603
    },
    
    // ==================== 通知管理模块 ====================
    {
      id: 7,
      name: 'notifications',
      displayName: '通知管理',
      description: '通知管理模块总权限',
      resource: 'notifications',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    // 通知模板管理
    {
      id: 701,
      name: 'notifications:templates',
      displayName: '通知模板管理',
      description: '通知模板管理权限',
      resource: 'notifications',
      action: 'templates',
      scope: 'all',
      parentId: 7
    },
    {
      id: 7011,
      name: 'notifications:templates:read',
      displayName: '查看通知模板',
      description: '查看通知模板列表',
      resource: 'notifications',
      action: 'templates:read',
      scope: 'all',
      parentId: 701
    },
    {
      id: 7012,
      name: 'notifications:templates:write',
      displayName: '管理通知模板',
      description: '创建、编辑通知模板',
      resource: 'notifications',
      action: 'templates:write',
      scope: 'all',
      parentId: 701
    },
    {
      id: 7013,
      name: 'notifications:templates:delete',
      displayName: '删除通知模板',
      description: '删除通知模板',
      resource: 'notifications',
      action: 'templates:delete',
      scope: 'all',
      parentId: 701
    },
    // 通知发送
    {
      id: 702,
      name: 'notifications:send',
      displayName: '通知发送',
      description: '通知发送权限',
      resource: 'notifications',
      action: 'send',
      scope: 'all',
      parentId: 7
    },
    {
      id: 7021,
      name: 'notifications:send:single',
      displayName: '发送单个通知',
      description: '发送单个通知消息',
      resource: 'notifications',
      action: 'send:single',
      scope: 'all',
      parentId: 702
    },
    {
      id: 7022,
      name: 'notifications:send:batch',
      displayName: '批量发送通知',
      description: '批量发送通知消息',
      resource: 'notifications',
      action: 'send:batch',
      scope: 'all',
      parentId: 702
    },
    {
      id: 7023,
      name: 'notifications:send:system',
      displayName: '发送系统通知',
      description: '发送系统级通知',
      resource: 'notifications',
      action: 'send:system',
      scope: 'all',
      parentId: 702
    },
    // 通知历史
    {
      id: 703,
      name: 'notifications:history',
      displayName: '通知历史',
      description: '通知历史查看权限',
      resource: 'notifications',
      action: 'history',
      scope: 'all',
      parentId: 7
    },
    {
      id: 7031,
      name: 'notifications:history:read',
      displayName: '查看通知历史',
      description: '查看通知发送历史',
      resource: 'notifications',
      action: 'history:read',
      scope: 'all',
      parentId: 703
    },
    {
      id: 7032,
      name: 'notifications:history:export',
      displayName: '导出通知历史',
      description: '导出通知历史数据',
      resource: 'notifications',
      action: 'history:export',
      scope: 'all',
      parentId: 703
    },
    
    // ==================== AI功能模块 ====================
    {
      id: 8,
      name: 'ai',
      displayName: 'AI功能',
      description: 'AI功能模块总权限',
      resource: 'ai',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    // AI配置管理
    {
      id: 801,
      name: 'ai:config',
      displayName: 'AI配置管理',
      description: 'AI配置管理权限',
      resource: 'ai',
      action: 'config',
      scope: 'all',
      parentId: 8
    },
    {
      id: 8011,
      name: 'ai:config:read',
      displayName: '查看AI配置',
      description: '查看AI服务配置',
      resource: 'ai',
      action: 'config:read',
      scope: 'all',
      parentId: 801
    },
    {
      id: 8012,
      name: 'ai:config:write',
      displayName: '管理AI配置',
      description: '创建、编辑AI配置',
      resource: 'ai',
      action: 'config:write',
      scope: 'all',
      parentId: 801
    },
    // AI功能使用
    {
      id: 802,
      name: 'ai:features',
      displayName: 'AI功能使用',
      description: 'AI功能使用权限',
      resource: 'ai',
      action: 'features',
      scope: 'all',
      parentId: 8
    },
    {
      id: 8021,
      name: 'ai:chat',
      displayName: 'AI聊天',
      description: '使用AI聊天功能',
      resource: 'ai',
      action: 'chat',
      scope: 'all',
      parentId: 802
    },
    {
      id: 8022,
      name: 'ai:optimize',
      displayName: 'AI优化记录',
      description: '使用AI优化记录内容',
      resource: 'ai',
      action: 'optimize',
      scope: 'all',
      parentId: 802
    },
    {
      id: 8023,
      name: 'ai:speech_to_text',
      displayName: '语音识别',
      description: '使用AI语音转文字功能',
      resource: 'ai',
      action: 'speech_to_text',
      scope: 'all',
      parentId: 802
    },
    
    // ==================== 仪表盘模块 ====================
    {
      id: 9,
      name: 'dashboard',
      displayName: '仪表盘',
      description: '仪表盘模块总权限',
      resource: 'dashboard',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    {
      id: 901,
      name: 'dashboard:view',
      displayName: '查看仪表盘',
      description: '查看仪表盘数据',
      resource: 'dashboard',
      action: 'view',
      scope: 'all',
      parentId: 9
    },
    {
      id: 9011,
      name: 'dashboard:stats:all',
      displayName: '查看全部统计',
      description: '查看系统全部统计数据',
      resource: 'dashboard',
      action: 'stats:all',
      scope: 'all',
      parentId: 901
    },
    {
      id: 9012,
      name: 'dashboard:stats:own',
      displayName: '查看个人统计',
      description: '只能查看个人相关统计',
      resource: 'dashboard',
      action: 'stats:own',
      scope: 'own',
      parentId: 901
    },
    {
      id: 9013,
      name: 'dashboard:recent_records',
      displayName: '查看最近记录',
      description: '查看最近的记录动态',
      resource: 'dashboard',
      action: 'recent_records',
      scope: 'all',
      parentId: 901
    },
    {
      id: 9014,
      name: 'dashboard:system_info',
      displayName: '查看系统信息',
      description: '查看系统运行信息',
      resource: 'dashboard',
      action: 'system_info',
      scope: 'all',
      parentId: 901
    },
    
    // ==================== 审计日志模块 ====================
    {
      id: 10,
      name: 'audit',
      displayName: '审计日志',
      description: '审计日志模块总权限',
      resource: 'audit',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    {
      id: 1001,
      name: 'audit:logs',
      displayName: '审计日志查看',
      description: '审计日志查看权限',
      resource: 'audit',
      action: 'logs',
      scope: 'all',
      parentId: 10
    },
    {
      id: 10011,
      name: 'audit:logs:read:all',
      displayName: '查看所有审计日志',
      description: '查看系统所有审计日志',
      resource: 'audit',
      action: 'logs:read:all',
      scope: 'all',
      parentId: 1001
    },
    {
      id: 10012,
      name: 'audit:logs:read:own',
      displayName: '查看个人审计日志',
      description: '只能查看个人操作日志',
      resource: 'audit',
      action: 'logs:read:own',
      scope: 'own',
      parentId: 1001
    },
    {
      id: 10013,
      name: 'audit:logs:export',
      displayName: '导出审计日志',
      description: '导出审计日志数据',
      resource: 'audit',
      action: 'logs:export',
      scope: 'all',
      parentId: 1001
    },
    {
      id: 10014,
      name: 'audit:logs:cleanup',
      displayName: '清理审计日志',
      description: '清理过期的审计日志',
      resource: 'audit',
      action: 'logs:cleanup',
      scope: 'all',
      parentId: 1001
    },
    
    // ==================== 工单系统模块 ====================
    {
      id: 11,
      name: 'tickets',
      displayName: '工单系统',
      description: '工单系统模块总权限',
      resource: 'tickets',
      action: 'manage',
      scope: 'all',
      parentId: null
    },
    // 导出基础操作
    {
      id: 6011,
      name: 'export:templates:read',
      displayName: '查看导出模板',
      description: '查看导出模板列表',
      resource: 'export',
      action: 'templates:read',
      scope: 'all',
      parentId: 601
    },
    {
      id: 1102,
      name: 'ticket:view_all',
      displayName: '查看所有工单',
      description: '查看所有用户的工单',
      resource: 'ticket',
      action: 'view',
      scope: 'all',
      parentId: 11
    },
    {
      id: 1103,
      name: 'ticket:create',
      displayName: '创建工单',
      description: '创建新工单',
      resource: 'ticket',
      action: 'create',
      scope: 'all',
      parentId: 11
    },
    {
      id: 1104,
      name: 'ticket:edit',
      displayName: '编辑工单',
      description: '编辑自己的工单',
      resource: 'ticket',
      action: 'edit',
      scope: 'own',
      parentId: 11
    },
    {
      id: 1105,
      name: 'ticket:edit_all',
      displayName: '编辑所有工单',
      description: '编辑所有用户的工单',
      resource: 'ticket',
      action: 'edit',
      scope: 'all',
      parentId: 11
    },
    {
      id: 1106,
      name: 'ticket:delete',
      displayName: '删除工单',
      description: '删除工单',
      resource: 'ticket',
      action: 'delete',
      scope: 'own',
      parentId: 11
    },
    // 工单状态管理
    {
      id: 1107,
      name: 'ticket:assign',
      displayName: '分配工单',
      description: '分配工单给其他用户',
      resource: 'ticket',
      action: 'assign',
      scope: 'all',
      parentId: 11
    },
    {
      id: 1108,
      name: 'ticket:status_all',
      displayName: '更新工单状态',
      description: '更新任何工单的状态',
      resource: 'ticket',
      action: 'status',
      scope: 'all',
      parentId: 11
    },
    {
      id: 1109,
      name: 'ticket:approve',
      displayName: '审批工单',
      description: '审批工单，将状态从已分派改为已审批',
      resource: 'ticket',
      action: 'approve',
      scope: 'all',
      parentId: 11
    },
    // 工单评论权限
    {
      id: 1110,
      name: 'ticket:comment',
      displayName: '添加工单评论',
      description: '在工单中添加评论',
      resource: 'ticket',
      action: 'comment',
      scope: 'all',
      parentId: 11
    },
    {
      id: 1111,
      name: 'ticket:comment_view',
      displayName: '查看工单评论',
      description: '查看工单评论',
      resource: 'ticket',
      action: 'comment_view',
      scope: 'all',
      parentId: 11
    },
    // 工单附件权限
    {
      id: 1112,
      name: 'ticket:attachment_upload',
      displayName: '上传工单附件',
      description: '上传工单附件',
      resource: 'ticket',
      action: 'attachment_upload',
      scope: 'all',
      parentId: 11
    },
    {
      id: 1113,
      name: 'ticket:attachment_download',
      displayName: '下载工单附件',
      description: '下载工单附件',
      resource: 'ticket',
      action: 'attachment_download',
      scope: 'all',
      parentId: 11
    },
    {
      id: 1114,
      name: 'ticket:delete_attachment',
      displayName: '删除工单附件',
      description: '删除工单附件',
      resource: 'ticket',
      action: 'delete_attachment',
      scope: 'all',
      parentId: 11
    },
    // 工单统计权限
    {
      id: 1115,
      name: 'ticket:statistics',
      displayName: '查看工单统计',
      description: '查看工单统计数据',
      resource: 'ticket',
      action: 'statistics',
      scope: 'all',
      parentId: 11
    }

  ]
}

// 构建权限树
const buildPermissionTree = (permissions: any[]) => {
  console.log('构建权限树，输入权限数量:', permissions.length)
  
  // 如果后端数据没有正确的父子关系，我们需要智能构建
  const hasValidHierarchy = permissions.some(p => p.parentId !== null)
  console.log('是否有有效的层次结构:', hasValidHierarchy)
  
  let tree
  if (hasValidHierarchy) {
    // 使用现有的层次结构
    tree = buildTreeFromHierarchy(permissions)
    console.log('使用层次结构构建，结果节点数:', tree.length)
  } else {
    // 智能构建层次结构
    tree = buildIntelligentTree(permissions)
    console.log('使用智能构建，结果节点数:', tree.length)
  }
  
  return tree
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
        'roles': '角色权限管理', 
        'permissions': '权限管理',
        'records': '记录管理',
        'record-types': '记录类型管理',
        'files': '文件管理',
        'export': '数据导出',
        'notifications': '通知管理',
        'ai': 'AI功能',
        'audit': '审计日志',
        'dashboard': '仪表盘',
        'ticket': '工单系统',
        'tickets': '工单系统'
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

// 统计权限树中的所有权限数量（包括子权限）
const countAllPermissions = (tree: any[]): number => {
  let count = 0
  const traverse = (nodes: any[]) => {
    nodes.forEach(node => {
      count++
      if (node.children && node.children.length > 0) {
        traverse(node.children)
      }
    })
  }
  traverse(tree)
  return count
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
  permissionLoading.value = true
  try {
    // 首先加载完整的权限树结构（所有可用权限）
    console.log('加载权限树结构...')
    await fetchPermissions()
    
    // 验证权限树是否加载成功
    const totalPermissionCount = countAllPermissions(permissionTree.value)
    console.log('权限树加载完成，总权限数量:', totalPermissionCount)
    
    if (totalPermissionCount === 0) {
      throw new Error('权限树数据为空')
    }
    
    // 更新权限分类和过滤树
    permissionCategories.value = getPermissionCategories(permissionTree.value)
    filteredPermissionTree.value = [...permissionTree.value]
    
  } catch (error) {
    console.error('权限树加载失败:', error)
    permissionError.value = '权限树加载失败，请重试'
  }
  
  // 获取角色当前已分配的权限
  try {
    console.log(`获取角色 ${row.id} 的已分配权限...`)
    const response = await http.get(`/admin/roles/${row.id}/permissions`)
    
    if (response.success) {
      const rolePermissions = response.data || []
      console.log('角色已分配权限:', rolePermissions.length, '个')
      
      // 提取权限ID
      selectedPermissions.value = rolePermissions.map((p: any) => p.id)
      
      // 设置树形控件的选中状态
      setTimeout(() => {
        if (permissionTreeRef.value) {
          permissionTreeRef.value.setCheckedKeys(selectedPermissions.value)
          console.log('已设置选中权限:', selectedPermissions.value.length, '个')
        }
      }, 200)
    } else {
      console.warn('获取角色权限响应失败:', response.message)
      selectedPermissions.value = []
    }
  } catch (error) {
    console.error('获取角色权限失败:', error)
    // 即使获取角色权限失败，也要显示权限树供用户选择
    selectedPermissions.value = []
    setTimeout(() => {
      if (permissionTreeRef.value) {
        permissionTreeRef.value.setCheckedKeys([])
      }
    }, 200)
  }
  
  permissionLoading.value = false
}

// 权限选择处理
const handlePermissionCheck = () => {
  // 获取选中的权限ID
  const checkedKeys = permissionTreeRef.value?.getCheckedKeys() || []
  selectedPermissions.value = [...checkedKeys]
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

// 权限搜索处理
const handlePermissionSearch = () => {
  filterPermissionTree()
}

// 权限分类过滤
const handleCategoryFilter = (categoryKey: string) => {
  selectedCategory.value = selectedCategory.value === categoryKey ? '' : categoryKey
  filterPermissionTree()
}

// 过滤权限树
const filterPermissionTree = () => {
  let filtered = [...permissionTree.value]
  
  // 按分类过滤
  if (selectedCategory.value) {
    console.log('过滤分类:', selectedCategory.value)
    console.log('原始权限树节点数:', permissionTree.value.length)
    
    // 打印第一个节点的结构用于调试
    if (permissionTree.value.length > 0) {
      console.log('第一个节点结构:', JSON.stringify(permissionTree.value[0], null, 2))
    }
    
    filtered = filtered.filter(node => {
      // 检查根节点是否匹配
      if (node.resource === selectedCategory.value) {
        console.log('根节点匹配:', node.name, '子节点数量:', node.children?.length || 0)
        return true
      }
      
      // 检查是否有子节点匹配
      if (node.children && node.children.length > 0) {
        const hasMatchingChild = node.children.some((child: any) => child.resource === selectedCategory.value)
        if (hasMatchingChild) {
          console.log('子节点匹配:', node.name)
          return true
        }
      }
      
      return false
    }).map(node => {
      // 确保保留完整的节点结构，包括子节点
      return {
        ...node,
        children: node.children || []
      }
    })
    
    console.log('过滤结果:', filtered.length, '个节点')
    if (filtered.length > 0) {
      console.log('过滤后第一个节点:', JSON.stringify(filtered[0], null, 2))
    }
  }
  
  // 按搜索文本过滤
  if (permissionSearchText.value) {
    filtered = filterTreeByText(filtered, permissionSearchText.value)
  }
  
  filteredPermissionTree.value = filtered
}

// 按文本过滤树节点
const filterTreeByText = (tree: any[], searchText: string): any[] => {
  const result: any[] = []
  
  tree.forEach(node => {
    const nodeMatches = (node.displayName || node.name || '').toLowerCase().includes(searchText.toLowerCase()) ||
                       (node.description || '').toLowerCase().includes(searchText.toLowerCase()) ||
                       (node.resource || '').toLowerCase().includes(searchText.toLowerCase()) ||
                       (node.action || '').toLowerCase().includes(searchText.toLowerCase())
    
    if (nodeMatches) {
      result.push({ ...node })
    } else if (node.children && node.children.length > 0) {
      const filteredChildren = filterTreeByText(node.children, searchText)
      if (filteredChildren.length > 0) {
        result.push({
          ...node,
          children: filteredChildren
        })
      }
    }
  })
  
  return result
}

// 权限树节点过滤方法
const filterPermissionNode = (value: string, data: any) => {
  if (!value) return true
  return (data.displayName || data.name || '').toLowerCase().includes(value.toLowerCase())
}

// 获取权限分类
const getPermissionCategories = (tree: any[]) => {
  const categories = new Map()
  
  const traverse = (nodes: any[]) => {
    nodes.forEach(node => {
      if (node.resource) {
        const key = node.resource
        const existing = categories.get(key)
        if (existing) {
          existing.count++
        } else {
          categories.set(key, {
            key,
            name: getResourceDisplayName(key),
            count: 1
          })
        }
      }
      if (node.children && node.children.length > 0) {
        traverse(node.children)
      }
    })
  }
  
  traverse(tree)
  return Array.from(categories.values())
}

// 获取资源显示名称
const getResourceDisplayName = (resource: string) => {
  const resourceNames: { [key: string]: string } = {
    'system': '系统管理',
    'users': '用户管理',
    'roles': '角色权限管理',
    'permissions': '权限管理',
    'records': '记录管理',
    'record-types': '记录类型管理',
    'files': '文件管理',
    'export': '数据导出',
    'notifications': '通知管理',
    'ai': 'AI功能',
    'audit': '审计日志',
    'dashboard': '仪表盘',
    'ticket': '工单系统',
    'tickets': '工单系统'
  }
  return resourceNames[resource] || resource
}

// 获取权限范围标签类型
const getScopeTagType = (scope: string) => {
  if (!scope || scope.trim() === '') {
    return 'info'
  }
  
  const scopeTypes: { [key: string]: string } = {
    'all': 'success',
    'own': 'warning',
    'department': 'info',
    'custom': 'danger'
  }
  return scopeTypes[scope] || 'info'
}

// 获取权限范围显示名称
const getScopeDisplayName = (scope: string) => {
  const scopeNames: { [key: string]: string } = {
    'all': '全部',
    'own': '仅自己',
    'department': '部门',
    'custom': '自定义'
  }
  return scopeNames[scope] || scope
}

// 切换节点选择状态
const toggleNodeSelection = (node: any) => {
  const isFullySelected = isNodeFullySelected(node)
  const nodeKeys = getAllNodeKeys(node)
  
  if (isFullySelected) {
    // 取消选择该节点及其所有子节点
    const currentChecked = permissionTreeRef.value?.getCheckedKeys() || []
    const newChecked = currentChecked.filter((key: string) => !nodeKeys.includes(key))
    permissionTreeRef.value?.setCheckedKeys(newChecked)
  } else {
    // 选择该节点及其所有子节点
    const currentChecked = permissionTreeRef.value?.getCheckedKeys() || []
    const newChecked = [...new Set([...currentChecked, ...nodeKeys])]
    permissionTreeRef.value?.setCheckedKeys(newChecked)
  }
  
  handlePermissionCheck()
}

// 检查节点是否完全选中
const isNodeFullySelected = (node: any) => {
  const nodeKeys = getAllNodeKeys(node)
  const checkedKeys = permissionTreeRef.value?.getCheckedKeys() || []
  return nodeKeys.every((key: string) => checkedKeys.includes(key))
}

// 获取节点及其所有子节点的键
const getAllNodeKeys = (node: any): string[] => {
  const keys = [node.id]
  if (node.children && node.children.length > 0) {
    node.children.forEach((child: any) => {
      keys.push(...getAllNodeKeys(child))
    })
  }
  return keys
}

// 强制加载模拟权限数据
const loadMockPermissions = () => {
  console.log('强制加载模拟权限数据')
  permissionTree.value = buildPermissionTree(getMockPermissions())
  permissionCategories.value = getPermissionCategories(permissionTree.value)
  filteredPermissionTree.value = [...permissionTree.value]
  permissionError.value = ''
  console.log('模拟权限数据加载完成:', permissionTree.value.length)
  ElMessage.success('模拟权限数据加载成功')
}

// 强制刷新权限数据
const forceRefreshPermissions = async () => {
  console.log('强制刷新权限数据')
  permissionLoading.value = true
  permissionError.value = ''
  
  try {
    // 清空现有数据
    permissionTree.value = []
    filteredPermissionTree.value = []
    permissionCategories.value = []
    
    // 重新加载权限数据
    await fetchPermissions()
    
    if (permissionTree.value.length === 0) {
      // 如果还是没有数据，强制使用模拟数据
      console.log('后端无数据，使用模拟权限数据')
      permissionTree.value = buildPermissionTree(getMockPermissions())
      permissionCategories.value = getPermissionCategories(permissionTree.value)
      filteredPermissionTree.value = [...permissionTree.value]
    }
    
    console.log('权限数据刷新完成，权限数量:', permissionTree.value.length)
    console.log('权限分类数量:', permissionCategories.value.length)
    ElMessage.success('权限数据刷新成功')
  } catch (error) {
    console.error('刷新权限数据失败:', error)
    // 使用模拟数据作为回退
    permissionTree.value = buildPermissionTree(getMockPermissions())
    permissionCategories.value = getPermissionCategories(permissionTree.value)
    filteredPermissionTree.value = [...permissionTree.value]
    ElMessage.warning('使用模拟权限数据')
  } finally {
    permissionLoading.value = false
  }
}

// 获取要显示的权限树数据
const getDisplayPermissionTree = () => {
  // 如果有过滤后的数据，优先显示过滤后的
  if (filteredPermissionTree.value.length > 0) {
    return filteredPermissionTree.value
  }
  
  // 如果没有过滤数据但有原始数据，显示原始数据
  if (permissionTree.value.length > 0) {
    return permissionTree.value
  }
  
  // 如果都没有，返回模拟数据
  console.log('没有权限数据，使用模拟数据')
  const mockData = buildPermissionTree(getMockPermissions())
  permissionTree.value = mockData
  filteredPermissionTree.value = [...mockData]
  return mockData
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
onMounted(async () => {
  fetchRoles()
  
  // 强制加载最新的精细化权限数据
  console.log('=== 角色管理页面初始化 ===')
  console.log('开始加载精细化权限数据...')
  
  try {
    await fetchPermissions()
    console.log('后端权限数据加载完成:', permissionTree.value.length)
    
    // 统计权限树中的总权限数量（包括子权限）
    const totalPermissionCount = countAllPermissions(permissionTree.value)
    console.log('权限树总权限数量:', totalPermissionCount)
    
    // 验证权限数据是否正确加载
    if (permissionTree.value.length > 0) {
      console.log('权限树加载成功')
      ElMessage.success({
        message: `权限数据加载成功，共 ${permissionTree.value.length} 个模块，${totalPermissionCount} 个权限`,
        duration: 2000
      })
    } else {
      throw new Error('权限树数据为空')
    }
  } catch (error) {
    console.error('权限数据加载失败:', error)
    ElMessage.error('权限数据加载失败，请刷新页面重试')
  }
  
  console.log('=== 权限数据加载完成 ===')
  console.log('权限总数:', permissionTree.value.length)
  console.log('模块数量:', permissionCategories.value.length)
  console.log('权限分类:', permissionCategories.value.map(c => c.name))
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

/* 权限对话框优化样式 */
.permission-dialog .el-dialog__body {
  padding: 20px;
}

.role-info-card {
  margin-bottom: 20px;
  border: 1px solid #e4e7ed;
}

.role-header {
  display: flex;
  align-items: center;
  gap: 15px;
}

.role-avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.role-details h4 {
  margin: 0 0 8px 0;
  font-size: 18px;
  font-weight: 600;
  color: #303133;
}

.role-description {
  margin: 0 0 8px 0;
  color: #606266;
  font-size: 14px;
}

.permission-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 8px;
}

.toolbar-left h4 {
  margin: 0 0 10px 0;
  color: #303133;
  font-size: 16px;
  font-weight: 600;
}

.toolbar-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.permission-stats {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.permission-categories {
  margin-bottom: 15px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 6px;
  border: 1px solid #e4e7ed;
}

.categories-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 10px;
}

.categories-title {
  font-weight: 500;
  color: #303133;
  font-size: 14px;
}

.categories-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.permission-tree-container {
  border: 1px solid #e4e7ed;
  border-radius: 6px;
  background: white;
}

.permission-tree {
  padding: 10px;
}

.tree-node {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 4px 0;
}

.node-content {
  flex: 1;
  min-width: 0;
}

.node-main {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.node-label {
  font-weight: 500;
  color: #303133;
}

.node-tags {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
}

.node-tag {
  font-size: 11px;
  padding: 2px 6px;
}

.scope-tag {
  font-size: 11px;
  padding: 2px 6px;
}

.node-description {
  font-size: 12px;
  color: #909399;
  margin-top: 2px;
  line-height: 1.4;
}

.node-actions {
  margin-left: 10px;
  opacity: 0;
  transition: opacity 0.2s;
}

.tree-node:hover .node-actions {
  opacity: 1;
}

.permission-loading {
  text-align: center;
  padding: 40px 0;
}

.loading-text {
  margin-top: 15px;
  color: #909399;
  font-size: 14px;
}

.no-permissions {
  text-align: center;
  padding: 40px 0;
}

.no-permissions-inline {
  padding: 20px;
  text-align: center;
}

.empty-actions {
  display: flex;
  gap: 10px;
  justify-content: center;
  margin-top: 15px;
}

.empty-tip {
  margin-top: 10px;
  text-align: center;
}

.dialog-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 15px;
  border-top: 1px solid #e4e7ed;
}

.footer-info {
  flex: 1;
}

.footer-actions {
  display: flex;
  gap: 10px;
}

/* 权限说明样式 */
.permission-help {
  font-size: 13px;
  line-height: 1.6;
}

.permission-help p {
  margin: 0 0 8px 0;
}

.permission-help ul {
  margin: 8px 0 0 0;
  padding-left: 20px;
}

.permission-help li {
  margin-bottom: 4px;
}

/* 调试信息样式 */
.debug-info {
  font-size: 12px;
  line-height: 1.5;
}

.debug-info p {
  margin: 4px 0;
  color: #606266;
}

.debug-info strong {
  color: #303133;
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
