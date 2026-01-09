<template>
  <div class="user-management">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>用户管理</span>
          <div class="header-actions">
            <el-button @click="handleRefresh" :loading="loading">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
            <el-dropdown @command="handleBatchAction" :disabled="selectedUsers.length === 0">
              <el-button type="warning" :disabled="selectedUsers.length === 0">
                <el-icon><Operation /></el-icon>
                批量操作 ({{ selectedUsers.length }})
                <el-icon class="el-icon--right"><ArrowDown /></el-icon>
              </el-button>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="enable">批量启用</el-dropdown-item>
                  <el-dropdown-item command="disable">批量禁用</el-dropdown-item>
                  <el-dropdown-item command="resetPassword" divided>批量重置密码</el-dropdown-item>
                  <el-dropdown-item command="delete" divided>批量删除</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
            <el-dropdown @command="handleImportAction">
              <el-button type="success">
                <el-icon><Upload /></el-icon>
                导入用户
                <el-icon class="el-icon--right"><ArrowDown /></el-icon>
              </el-button>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="template">下载模板</el-dropdown-item>
                  <el-dropdown-item command="import" divided>导入用户</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
            <el-button type="primary" @click="handleCreate">
              <el-icon><Plus /></el-icon>
              新增用户
            </el-button>
          </div>
        </div>
      </template>

      <!-- 搜索栏 -->
      <div class="search-bar">
        <el-form :model="searchForm" inline class="search-form">
          <el-form-item label="用户名" class="search-item">
            <el-input 
              v-model="searchForm.username" 
              placeholder="请输入用户名" 
              clearable 
              style="width: 200px;"
              @keyup.enter="handleSearch"
            />
          </el-form-item>
          <el-form-item label="邮箱" class="search-item">
            <el-input 
              v-model="searchForm.email" 
              placeholder="请输入邮箱" 
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

      <!-- 用户表格 -->
      <el-table 
        :data="users" 
        v-loading="loading" 
        stripe
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="username" label="用户名" min-width="120" show-overflow-tooltip />
        <el-table-column prop="email" label="邮箱" min-width="180" show-overflow-tooltip />
        <el-table-column prop="displayName" label="显示名称" min-width="120" show-overflow-tooltip />
        <el-table-column label="角色" min-width="150">
          <template #default="{ row }">
            <el-tag 
              v-for="role in row.roles" 
              :key="role.id" 
              size="small" 
              style="margin-right: 4px;"
              :type="getRoleTagType(role.name)"
            >
              {{ role.displayName || role.name }}
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
        <el-table-column prop="lastLoginAt" label="最后登录" width="160" align="center">
          <template #default="{ row }">
            {{ formatTime(row.lastLoginAt) }}
          </template>
        </el-table-column>
        <el-table-column prop="lastLoginIP" label="登录IP" width="140" align="center" show-overflow-tooltip>
          <template #default="{ row }">
            {{ row.lastLoginIP || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="createdAt" label="创建时间" width="160" align="center">
          <template #default="{ row }">
            {{ formatTime(row.createdAt) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="400" fixed="right" align="center">
          <template #default="{ row }">
            <div class="action-buttons">
              <el-button size="small" @click="handleEdit(row)">编辑</el-button>
              <el-button size="small" type="warning" @click="handleRoles(row)">角色</el-button>
              <el-button size="small" type="info" @click="handleResetPassword(row)">重置密码</el-button>
              <el-button 
                size="small" 
                :type="row.status === 'active' ? 'danger' : 'success'"
                @click="handleToggleStatus(row)"
              >
                {{ row.status === 'active' ? '禁用' : '启用' }}
              </el-button>
              <el-button size="small" type="danger" @click="handleDelete(row)">删除</el-button>
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

    <!-- 用户编辑对话框 -->
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
        <el-form-item label="用户名" prop="username">
          <el-input 
            v-model="formData.username" 
            placeholder="请输入用户名"
            :disabled="isEdit"
          />
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input 
            v-model="formData.email" 
            placeholder="请输入邮箱"
            type="email"
          />
        </el-form-item>
        <el-form-item label="显示名称" prop="displayName">
          <el-input 
            v-model="formData.displayName" 
            placeholder="请输入显示名称"
          />
        </el-form-item>
        <el-form-item label="密码" prop="password" v-if="!isEdit">
          <el-input 
            v-model="formData.password" 
            placeholder="请输入密码"
            type="password"
            show-password
          />
        </el-form-item>
        <el-form-item label="确认密码" prop="confirmPassword" v-if="!isEdit">
          <el-input 
            v-model="formData.confirmPassword" 
            placeholder="请确认密码"
            type="password"
            show-password
          />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="formData.status">
            <el-radio label="active">启用</el-radio>
            <el-radio label="inactive">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input 
            v-model="formData.description" 
            placeholder="请输入用户描述"
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

    <!-- 角色分配对话框 -->
    <el-dialog 
      v-model="roleDialogVisible" 
      title="分配角色" 
      width="500px"
    >
      <div v-if="currentUser">
        <p><strong>用户：</strong>{{ currentUser.displayName || currentUser.username }}</p>
        <el-divider />
        <el-form label-width="80px">
          <el-form-item label="角色">
            <el-checkbox-group v-model="selectedRoles">
              <el-checkbox 
                v-for="role in availableRoles" 
                :key="role.id" 
                :label="role.id"
                :value="role.id"
              >
                {{ role.displayName || role.name }}
                <span class="role-description">{{ role.description }}</span>
              </el-checkbox>
            </el-checkbox-group>
          </el-form-item>
        </el-form>
      </div>
      
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="roleDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSaveRoles" :loading="submitting">
            保存
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 导入用户对话框 -->
    <el-dialog v-model="importDialogVisible" title="导入用户" width="600px">
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
              <p>1. 请先下载模板文件，按照模板格式填写用户信息</p>
              <p>2. 支持的文件格式：Excel (.xlsx, .xls) 或 CSV (.csv)</p>
              <p>3. 必填字段：用户名、邮箱、显示名称</p>
              <p>4. 可选字段：角色、状态、密码（留空将生成随机密码）</p>
            </div>
          </template>
        </el-alert>

        <el-upload
          ref="uploadRef"
          class="upload-demo"
          drag
          :auto-upload="false"
          :on-change="handleFileChange"
          :before-upload="beforeUpload"
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

        <div v-if="importFile" class="file-info" style="margin-top: 20px;">
          <el-card>
            <div style="display: flex; align-items: center; justify-content: space-between;">
              <div>
                <el-icon><Document /></el-icon>
                <span style="margin-left: 8px;">{{ importFile.name }}</span>
                <el-tag size="small" style="margin-left: 8px;">{{ formatFileSize(importFile.size) }}</el-tag>
              </div>
              <el-button size="small" type="danger" @click="removeFile">移除</el-button>
            </div>
          </el-card>
        </div>

        <div v-if="importPreview.length > 0" class="preview-section" style="margin-top: 20px;">
          <h4>数据预览 (前5条)</h4>
          <el-table :data="importPreview.slice(0, 5)" size="small" max-height="300">
            <el-table-column prop="username" label="用户名" width="120" />
            <el-table-column prop="email" label="邮箱" width="180" />
            <el-table-column prop="displayName" label="显示名称" width="120" />
            <el-table-column prop="roles" label="角色" width="100" />
            <el-table-column prop="status" label="状态" width="80" />
            <el-table-column prop="password" label="密码" width="100">
              <template #default="{ row }">
                {{ row.password ? '***' : '(随机生成)' }}
              </template>
            </el-table-column>
          </el-table>
          <div style="margin-top: 10px; color: #666; font-size: 14px;">
            共 {{ importPreview.length }} 条数据，将导入 {{ validImportData.length }} 条有效数据
          </div>
        </div>
      </div>

      <template #footer>
        <div class="dialog-footer">
          <el-button @click="importDialogVisible = false">取消</el-button>
          <el-button @click="downloadTemplate">下载模板</el-button>
          <el-button 
            type="primary" 
            @click="handleImportUsers" 
            :loading="importing"
            :disabled="!importFile || validImportData.length === 0"
          >
            导入用户 ({{ validImportData.length }})
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 批量重置密码结果对话框 -->
    <el-dialog v-model="resetPasswordResultDialogVisible" title="批量重置密码结果" width="700px">
      <div v-if="resetPasswordResults.length > 0">
        <el-alert
          title="密码重置完成"
          type="success"
          :closable="false"
          show-icon
          style="margin-bottom: 20px;"
        >
          <template #default>
            成功重置 {{ resetPasswordResults.length }} 个用户的密码，请及时通知用户新密码
          </template>
        </el-alert>

        <el-table :data="resetPasswordResults" size="small" max-height="400">
          <el-table-column prop="username" label="用户名" width="120" />
          <el-table-column prop="email" label="邮箱" width="200" />
          <el-table-column prop="new_password" label="新密码" width="150">
            <template #default="{ row }">
              <div style="display: flex; align-items: center;">
                <span style="font-family: monospace;">{{ row.new_password }}</span>
                <el-button 
                  size="small" 
                  text 
                  @click="copyPassword(row.new_password)"
                  style="margin-left: 8px;"
                >
                  <el-icon><CopyDocument /></el-icon>
                </el-button>
              </div>
            </template>
          </el-table-column>
          <el-table-column prop="status" label="状态" width="100">
            <template #default="{ row }">
              <el-tag :type="row.success ? 'success' : 'danger'" size="small">
                {{ row.success ? '成功' : '失败' }}
              </el-tag>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <template #footer>
        <div class="dialog-footer">
          <el-button @click="resetPasswordResultDialogVisible = false">关闭</el-button>
          <el-button type="primary" @click="exportPasswordResults">导出结果</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  Plus, 
  Refresh, 
  Search, 
  RefreshRight, 
  Operation, 
  ArrowDown, 
  Upload, 
  UploadFilled, 
  Document, 
  CopyDocument 
} from '@element-plus/icons-vue'
import { http } from '../../utils/request'
import { API_ENDPOINTS } from '../../config/api'
import dayjs from 'dayjs'

// 响应式数据
const loading = ref(false)
const submitting = ref(false)
const users = ref([])
const selectedUsers = ref([])
const dialogVisible = ref(false)
const roleDialogVisible = ref(false)
const formRef = ref()
const currentUser = ref(null)
const availableRoles = ref([])
const selectedRoles = ref([])

const searchForm = reactive({
  username: '',
  email: '',
  status: ''
})

const pagination = reactive({
  page: 1,
  size: 20,
  total: 0
})

// 批量操作和导入相关
const importDialogVisible = ref(false)
const importing = ref(false)
const importFile = ref(null)
const importPreview = ref([])
const validImportData = ref([])
const uploadRef = ref()

// 重置密码结果
const resetPasswordResultDialogVisible = ref(false)
const resetPasswordResults = ref([])

const formData = reactive({
  username: '',
  email: '',
  displayName: '',
  password: '',
  confirmPassword: '',
  status: 'active',
  description: ''
})

// 计算属性
const dialogTitle = computed(() => isEdit.value ? '编辑用户' : '新增用户')
const isEdit = ref(false)

// 表单验证规则
const formRules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 20, message: '用户名长度在 3 到 20 个字符', trigger: 'blur' }
  ],
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入正确的邮箱格式', trigger: 'blur' }
  ],
  displayName: [
    { required: true, message: '请输入显示名称', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能少于6位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认密码', trigger: 'blur' },
    { 
      validator: (rule: any, value: string, callback: Function) => {
        if (value !== formData.password) {
          callback(new Error('两次输入密码不一致'))
        } else {
          callback()
        }
      }, 
      trigger: 'blur' 
    }
  ]
}

// 获取用户列表
const fetchUsers = async () => {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      size: pagination.size,
      ...searchForm
    }
    
    const response = await http.get('/admin/users', { params })
    
    if (response.data) {
      users.value = response.data.items || response.data || []
      pagination.total = response.data.total || users.value.length
    }
  } catch (error) {
    console.error('获取用户列表失败:', error)
    ElMessage.error('获取用户列表失败')
  } finally {
    loading.value = false
  }
}

// 获取角色列表
const fetchRoles = async () => {
  try {
    const response = await http.get('/admin/roles')
    availableRoles.value = response.data?.items || response.data || []
  } catch (error) {
    console.error('获取角色列表失败:', error)
  }
}

// 搜索
const handleSearch = () => {
  pagination.page = 1
  fetchUsers()
}

// 重置
const handleReset = () => {
  Object.assign(searchForm, {
    username: '',
    email: '',
    status: ''
  })
  handleSearch()
}

// 刷新
const handleRefresh = () => {
  fetchUsers()
}

// 选择变化
const handleSelectionChange = (selection: any[]) => {
  selectedUsers.value = selection
}

// 新增用户
const handleCreate = () => {
  isEdit.value = false
  resetForm()
  dialogVisible.value = true
}

// 编辑用户
const handleEdit = (row: any) => {
  isEdit.value = true
  Object.assign(formData, {
    id: row.id,
    username: row.username,
    email: row.email,
    displayName: row.displayName,
    status: row.status,
    description: row.description,
    password: '',
    confirmPassword: ''
  })
  dialogVisible.value = true
}

// 角色管理
const handleRoles = (row: any) => {
  currentUser.value = row
  selectedRoles.value = row.roles?.map((role: any) => role.id) || []
  roleDialogVisible.value = true
}

// 切换状态
const handleToggleStatus = async (row: any) => {
  try {
    const newStatus = row.status === 'active' ? 'inactive' : 'active'
    const action = newStatus === 'active' ? '启用' : '禁用'
    
    await ElMessageBox.confirm(`确定要${action}用户 ${row.displayName || row.username} 吗？`, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await http.put(`/admin/users/${row.id}`, {
      status: newStatus
    })
    
    ElMessage.success(`${action}成功`)
    fetchUsers()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('切换用户状态失败:', error)
      ElMessage.error('操作失败')
    }
  }
}

// 删除用户
const handleDelete = async (row: any) => {
  try {
    await ElMessageBox.confirm(`确定要删除用户 ${row.displayName || row.username} 吗？`, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await http.delete(`/admin/users/${row.id}`)
    ElMessage.success('删除成功')
    fetchUsers()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除用户失败:', error)
      ElMessage.error('删除失败')
    }
  }
}

// 提交表单
const handleSubmit = async () => {
  try {
    await formRef.value.validate()
    submitting.value = true
    
    const data = { ...formData }
    delete data.confirmPassword
    
    if (isEdit.value) {
      await http.put(`/admin/users/${data.id}`, data)
      ElMessage.success('更新成功')
    } else {
      await http.post('/admin/users', data)
      ElMessage.success('创建成功')
    }
    
    dialogVisible.value = false
    fetchUsers()
  } catch (error) {
    console.error('提交失败:', error)
    ElMessage.error('操作失败')
  } finally {
    submitting.value = false
  }
}

// 保存角色
const handleSaveRoles = async () => {
  try {
    submitting.value = true
    
    await http.put(`/admin/users/${currentUser.value.id}/roles`, {
      roleIds: selectedRoles.value
    })
    
    ElMessage.success('角色分配成功')
    roleDialogVisible.value = false
    fetchUsers()
  } catch (error) {
    console.error('分配角色失败:', error)
    ElMessage.error('分配角色失败')
  } finally {
    submitting.value = false
  }
}

// 分页处理
const handleSizeChange = (size: number) => {
  pagination.size = size
  fetchUsers()
}

const handleCurrentChange = (page: number) => {
  pagination.page = page
  fetchUsers()
}

// 对话框关闭
const handleDialogClose = () => {
  resetForm()
}

// 重置表单
const resetForm = () => {
  Object.assign(formData, {
    username: '',
    email: '',
    displayName: '',
    password: '',
    confirmPassword: '',
    status: 'active',
    description: ''
  })
  formRef.value?.clearValidate()
}

// 批量操作处理
const handleBatchAction = async (command: string) => {
  if (selectedUsers.value.length === 0) {
    ElMessage.warning('请先选择要操作的用户')
    return
  }

  const userNames = selectedUsers.value.map(user => user.displayName || user.username).join('、')
  
  try {
    switch (command) {
      case 'enable':
        await ElMessageBox.confirm(`确定要批量启用选中的 ${selectedUsers.value.length} 个用户吗？`, '批量启用', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        })
        await batchUpdateStatus('active')
        break
        
      case 'disable':
        await ElMessageBox.confirm(`确定要批量禁用选中的 ${selectedUsers.value.length} 个用户吗？`, '批量禁用', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        })
        await batchUpdateStatus('inactive')
        break
        
      case 'resetPassword':
        await ElMessageBox.confirm(`确定要批量重置选中的 ${selectedUsers.value.length} 个用户的密码吗？`, '批量重置密码', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        })
        await batchResetPassword()
        break
        
      case 'delete':
        await ElMessageBox.confirm(`确定要批量删除选中的 ${selectedUsers.value.length} 个用户吗？\n用户：${userNames}`, '批量删除', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'error'
        })
        await batchDeleteUsers()
        break
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('批量操作失败:', error)
      ElMessage.error('批量操作失败')
    }
  }
}

// 批量更新状态
const batchUpdateStatus = async (status: string) => {
  const userIds = selectedUsers.value.map(user => user.id)
  
  try {
    await http.put('/admin/users/batch-status', {
      user_ids: userIds,
      status: status
    })
    
    ElMessage.success(`批量${status === 'active' ? '启用' : '禁用'}成功`)
    selectedUsers.value = []
    fetchUsers()
  } catch (error) {
    throw error
  }
}

// 批量重置密码
const batchResetPassword = async () => {
  const userIds = selectedUsers.value.map(user => user.id)
  
  try {
    const response = await http.post('/admin/users/batch-reset-password', {
      user_ids: userIds
    })
    
    resetPasswordResults.value = response.data.results || []
    resetPasswordResultDialogVisible.value = true
    selectedUsers.value = []
    
    ElMessage.success('批量重置密码成功')
  } catch (error) {
    throw error
  }
}

// 批量删除用户
const batchDeleteUsers = async () => {
  const userIds = selectedUsers.value.map(user => user.id)
  
  try {
    await http.delete('/admin/users/batch', {
      data: { user_ids: userIds }
    })
    
    ElMessage.success('批量删除成功')
    selectedUsers.value = []
    fetchUsers()
  } catch (error) {
    throw error
  }
}

// 单个用户重置密码
const handleResetPassword = async (row: any) => {
  try {
    await ElMessageBox.confirm(`确定要重置用户 ${row.displayName || row.username} 的密码吗？`, '重置密码', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    const response = await http.post(`/admin/users/${row.id}/reset-password`)
    
    resetPasswordResults.value = [response.data]
    resetPasswordResultDialogVisible.value = true
    
    ElMessage.success('密码重置成功')
  } catch (error) {
    if (error !== 'cancel') {
      console.error('重置密码失败:', error)
      ElMessage.error('重置密码失败')
    }
  }
}

// 导入操作处理
const handleImportAction = (command: string) => {
  switch (command) {
    case 'template':
      downloadTemplate()
      break
    case 'import':
      importDialogVisible.value = true
      break
  }
}

// 下载导入模板
const downloadTemplate = () => {
  const template = [
    ['用户名*', '邮箱*', '显示名称*', '角色', '状态', '密码', '描述'],
    ['user1', 'user1@example.com', '用户1', 'user', 'active', '', '示例用户1'],
    ['user2', 'user2@example.com', '用户2', 'user', 'active', 'password123', '示例用户2']
  ]
  
  // 创建CSV内容
  const csvContent = template.map(row => row.join(',')).join('\n')
  const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)
  
  link.setAttribute('href', url)
  link.setAttribute('download', '用户导入模板.csv')
  link.style.visibility = 'hidden'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  
  ElMessage.success('模板下载成功')
}

// 文件上传处理
const handleFileChange = (file: any) => {
  importFile.value = file.raw
  parseImportFile(file.raw)
}

// 文件上传前检查
const beforeUpload = (file: any) => {
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
const parseImportFile = async (file: File) => {
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
        username: values[0] || '',
        email: values[1] || '',
        displayName: values[2] || '',
        roles: values[3] || 'user',
        status: values[4] || 'active',
        password: values[5] || '',
        description: values[6] || ''
      }
    })
    
    importPreview.value = data
    
    // 验证数据
    validImportData.value = data.filter(item => 
      item.username && item.email && item.displayName
    )
    
    if (validImportData.value.length === 0) {
      ElMessage.error('没有找到有效的用户数据')
    } else {
      ElMessage.success(`解析成功，找到 ${validImportData.value.length} 条有效数据`)
    }
  } catch (error) {
    console.error('解析文件失败:', error)
    ElMessage.error('文件解析失败')
  }
}

// 移除文件
const removeFile = () => {
  importFile.value = null
  importPreview.value = []
  validImportData.value = []
  uploadRef.value?.clearFiles()
}

// 执行导入
const handleImportUsers = async () => {
  if (validImportData.value.length === 0) {
    ElMessage.warning('没有有效的数据可以导入')
    return
  }
  
  try {
    importing.value = true
    
    const response = await http.post('/admin/users/import', {
      users: validImportData.value
    })
    
    const results = response.data.results || []
    const successCount = results.filter((r: any) => r.success).length
    const failCount = results.length - successCount
    
    if (failCount === 0) {
      ElMessage.success(`导入成功！共导入 ${successCount} 个用户`)
    } else {
      ElMessage.warning(`导入完成！成功 ${successCount} 个，失败 ${failCount} 个`)
    }
    
    importDialogVisible.value = false
    removeFile()
    fetchUsers()
  } catch (error) {
    console.error('导入失败:', error)
    ElMessage.error('导入失败')
  } finally {
    importing.value = false
  }
}

// 复制密码
const copyPassword = async (password: string) => {
  try {
    await navigator.clipboard.writeText(password)
    ElMessage.success('密码已复制到剪贴板')
  } catch (error) {
    ElMessage.error('复制失败')
  }
}

// 导出密码重置结果
const exportPasswordResults = () => {
  const data = [
    ['用户名', '邮箱', '新密码', '状态'],
    ...resetPasswordResults.value.map(item => [
      item.username,
      item.email,
      item.new_password,
      item.success ? '成功' : '失败'
    ])
  ]
  
  const csvContent = data.map(row => row.join(',')).join('\n')
  const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)
  
  link.setAttribute('href', url)
  link.setAttribute('download', `密码重置结果_${dayjs().format('YYYY-MM-DD_HH-mm-ss')}.csv`)
  link.style.visibility = 'hidden'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  
  ElMessage.success('结果导出成功')
}

// 格式化文件大小
const formatFileSize = (bytes: number) => {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

// 工具函数
const getRoleTagType = (roleName: string) => {
  const typeMap: Record<string, string> = {
    'admin': 'danger',
    'manager': 'warning',
    'user': 'info',
    'guest': ''
  }
  return typeMap[roleName] || 'info'
}

const formatTime = (time: string) => {
  return time ? dayjs(time).format('YYYY-MM-DD HH:mm') : '-'
}

// 生命周期
onMounted(() => {
  fetchUsers()
  fetchRoles()
})
</script>

<style scoped>
.user-management {
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

.dialog-footer {
  text-align: right;
}

.role-description {
  font-size: 12px;
  color: #909399;
  margin-left: 8px;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .user-management {
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
}

/* 导入和批量操作样式 */
.import-section {
  padding: 20px 0;
}

.file-info {
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  padding: 12px;
  background-color: #f9f9f9;
}

.preview-section {
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  padding: 16px;
  background-color: #fafafa;
}

.preview-section h4 {
  margin: 0 0 12px 0;
  color: #303133;
  font-size: 14px;
}

.action-buttons {
  display: flex;
  gap: 4px;
  justify-content: center;
  flex-wrap: wrap;
}

.action-buttons .el-button {
  min-width: 60px;
  padding: 5px 8px;
}

/* 批量操作按钮样式 */
.header-actions .el-dropdown {
  margin-right: 8px;
}

.header-actions .el-dropdown:last-child {
  margin-right: 0;
}
</style>
