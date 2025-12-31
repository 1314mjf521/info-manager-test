<template>
  <div class="user-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>用户管理</span>
          <el-button type="primary" @click="handleCreate">
            <el-icon><Plus /></el-icon>
            新建用户
          </el-button>
        </div>
      </template>

      <!-- 搜索栏 -->
      <div class="search-bar">
        <el-form :model="searchForm" inline>
          <el-form-item label="用户名">
            <el-input v-model="searchForm.username" placeholder="请输入用户名" clearable />
          </el-form-item>
          <el-form-item label="邮箱">
            <el-input v-model="searchForm.email" placeholder="请输入邮箱" clearable />
          </el-form-item>
          <el-form-item label="状态">
            <el-select v-model="searchForm.isActive" placeholder="请选择状态" clearable>
              <el-option label="启用" :value="true" />
              <el-option label="禁用" :value="false" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleSearch">搜索</el-button>
            <el-button @click="handleReset">重置</el-button>
          </el-form-item>
        </el-form>
      </div>

      <!-- 用户表格 -->
      <el-table :data="users" v-loading="loading" stripe>
        <el-table-column type="selection" width="55" />
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column label="头像" width="80">
          <template #default="{ row }">
            <el-avatar :src="row.avatar" :size="40">
              {{ row.username?.charAt(0).toUpperCase() }}
            </el-avatar>
          </template>
        </el-table-column>
        <el-table-column prop="username" label="用户名" min-width="120" />
        <el-table-column prop="email" label="邮箱" min-width="180" />
        <el-table-column label="角色" min-width="120">
          <template #default="{ row }">
            <el-tag
              v-for="role in row.roles"
              :key="role"
              size="small"
              style="margin-right: 4px;"
            >
              {{ getRoleText(role) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="isActive" label="状态" width="100">
          <template #default="{ row }">
            <el-switch
              v-model="row.isActive"
              @change="handleStatusChange(row)"
              :loading="row.statusLoading"
            />
          </template>
        </el-table-column>
        <el-table-column prop="lastLogin" label="最后登录" width="160">
          <template #default="{ row }">
            {{ row.lastLogin ? formatTime(row.lastLogin) : '从未登录' }}
          </template>
        </el-table-column>
        <el-table-column prop="createdAt" label="创建时间" width="160">
          <template #default="{ row }">
            {{ formatTime(row.createdAt) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="handleView(row)">查看</el-button>
            <el-button size="small" @click="handleEdit(row)">编辑</el-button>
            <el-button size="small" type="danger" @click="handleDelete(row)">删除</el-button>
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

    <!-- 用户详情对话框 -->
    <el-dialog v-model="detailDialogVisible" :title="currentUser?.username" width="600px">
      <div v-if="currentUser" class="user-detail">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="用户ID">{{ currentUser.id }}</el-descriptions-item>
          <el-descriptions-item label="用户名">{{ currentUser.username }}</el-descriptions-item>
          <el-descriptions-item label="邮箱">{{ currentUser.email }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="currentUser.isActive ? 'success' : 'danger'">
              {{ currentUser.isActive ? '启用' : '禁用' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="角色" :span="2">
            <el-tag
              v-for="role in currentUser.roles"
              :key="role"
              size="small"
              style="margin-right: 4px;"
            >
              {{ getRoleText(role) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="最后登录">
            {{ currentUser.lastLogin ? formatTime(currentUser.lastLogin) : '从未登录' }}
          </el-descriptions-item>
          <el-descriptions-item label="创建时间">
            {{ formatTime(currentUser.createdAt) }}
          </el-descriptions-item>
        </el-descriptions>
      </div>
    </el-dialog>

    <!-- 用户编辑对话框 -->
    <el-dialog v-model="editDialogVisible" :title="isEdit ? '编辑用户' : '新建用户'" width="600px">
      <el-form
        ref="formRef"
        :model="userForm"
        :rules="userRules"
        label-width="100px"
      >
        <el-form-item label="用户名" prop="username">
          <el-input v-model="userForm.username" placeholder="请输入用户名" />
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="userForm.email" placeholder="请输入邮箱" />
        </el-form-item>
        <el-form-item v-if="!isEdit" label="密码" prop="password">
          <el-input v-model="userForm.password" type="password" placeholder="请输入密码" />
        </el-form-item>
        <el-form-item label="角色" prop="roles">
          <el-select v-model="userForm.roles" multiple placeholder="请选择角色" style="width: 100%">
            <el-option label="管理员" value="admin" />
            <el-option label="用户" value="user" />
            <el-option label="访客" value="guest" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="userForm.isActive" />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSave" :loading="saving">
          {{ isEdit ? '更新' : '创建' }}
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { http } from '@/utils/request'
import { API_ENDPOINTS } from '@/config/api'
import dayjs from 'dayjs'
import { useEventBus } from '@/utils/eventBus'

// 响应式数据
const loading = ref(false)
const saving = ref(false)
const users = ref([])
const detailDialogVisible = ref(false)
const editDialogVisible = ref(false)
const currentUser = ref(null)
const formRef = ref()
const { emit } = useEventBus()

const searchForm = reactive({
  username: '',
  email: '',
  isActive: null
})

const pagination = reactive({
  page: 1,
  size: 20,
  total: 0
})

const userForm = reactive({
  username: '',
  email: '',
  password: '',
  roles: [],
  isActive: true
})

// 计算属性
const isEdit = computed(() => !!currentUser.value?.id)

// 表单验证规则
const userRules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 50, message: '用户名长度在 3 到 50 个字符', trigger: 'blur' }
  ],
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入正确的邮箱格式', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能少于 6 个字符', trigger: 'blur' }
  ],
  roles: [
    { required: true, message: '请选择角色', trigger: 'change' }
  ]
}

// 获取用户列表
const fetchUsers = async () => {
  loading.value = true
  try {
    const params = {
      ...searchForm,
      page: pagination.page,
      size: pagination.size
    }
    
    const response = await http.get('/users', { params })
    
    if (response.items) {
      users.value = response.items.map((user: any) => ({
        ...user,
        statusLoading: false
      }))
      pagination.total = response.total || 0
    } else {
      // 使用模拟数据
      users.value = [
        {
          id: 1,
          username: 'admin',
          email: 'admin@example.com',
          roles: ['admin'],
          isActive: true,
          lastLogin: new Date().toISOString(),
          createdAt: new Date(Date.now() - 86400000 * 30).toISOString(),
          statusLoading: false
        },
        {
          id: 2,
          username: 'user1',
          email: 'user1@example.com',
          roles: ['user'],
          isActive: true,
          lastLogin: new Date(Date.now() - 3600000).toISOString(),
          createdAt: new Date(Date.now() - 86400000 * 7).toISOString(),
          statusLoading: false
        },
        {
          id: 3,
          username: 'guest',
          email: 'guest@example.com',
          roles: ['guest'],
          isActive: false,
          lastLogin: null,
          createdAt: new Date(Date.now() - 86400000 * 3).toISOString(),
          statusLoading: false
        }
      ]
      pagination.total = 3
    }
  } catch (error) {
    console.error('获取用户列表失败:', error)
    // 使用模拟数据作为fallback
    users.value = [
      {
        id: 1,
        username: 'admin',
        email: 'admin@example.com',
        roles: ['admin'],
        isActive: true,
        lastLogin: new Date().toISOString(),
        createdAt: new Date().toISOString(),
        statusLoading: false
      }
    ]
    pagination.total = 1
    ElMessage.warning('使用模拟数据，请检查后端API连接')
  } finally {
    loading.value = false
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
    isActive: null
  })
  handleSearch()
}

// 新建用户
const handleCreate = () => {
  currentUser.value = null
  Object.assign(userForm, {
    username: '',
    email: '',
    password: '',
    roles: [],
    isActive: true
  })
  editDialogVisible.value = true
}

// 查看用户
const handleView = (row: any) => {
  currentUser.value = row
  detailDialogVisible.value = true
}

// 编辑用户
const handleEdit = (row: any) => {
  currentUser.value = row
  Object.assign(userForm, {
    username: row.username,
    email: row.email,
    password: '',
    roles: [...row.roles],
    isActive: row.isActive
  })
  editDialogVisible.value = true
}

// 保存用户
const handleSave = async () => {
  if (!formRef.value) return
  
  try {
    await formRef.value.validate()
    
    saving.value = true
    
    if (isEdit.value) {
      await http.put(`/users/${currentUser.value.id}`, userForm)
      ElMessage.success('用户更新成功')
      // 触发用户更新事件
      emit('user:updated')
    } else {
      await http.post('/users', userForm)
      ElMessage.success('用户创建成功')
      // 触发用户创建事件
      emit('user:created')
    }
    
    editDialogVisible.value = false
    fetchUsers()
  } catch (error: any) {
    if (error.fields) {
      // 表单验证错误
      return
    }
    console.error('保存用户失败:', error)
    ElMessage.error(error.message || '保存用户失败')
  } finally {
    saving.value = false
  }
}

// 状态切换
const handleStatusChange = async (row: any) => {
  row.statusLoading = true
  try {
    await http.put(`/users/${row.id}/status`, { isActive: row.isActive })
    ElMessage.success(`用户${row.isActive ? '启用' : '禁用'}成功`)
  } catch (error) {
    console.error('状态切换失败:', error)
    row.isActive = !row.isActive // 回滚状态
    ElMessage.error('状态切换失败')
  } finally {
    row.statusLoading = false
  }
}

// 删除用户
const handleDelete = async (row: any) => {
  try {
    await ElMessageBox.confirm('确定要删除这个用户吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await http.delete(`/users/${row.id}`)
    ElMessage.success('删除成功')
    fetchUsers()
    // 触发用户删除事件
    emit('user:deleted')
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除用户失败:', error)
      ElMessage.error('删除用户失败')
    }
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

// 工具函数
const getRoleText = (role: string) => {
  const roleMap: { [key: string]: string } = {
    admin: '管理员',
    user: '用户',
    guest: '访客'
  }
  return roleMap[role] || role
}

const formatTime = (time: string) => {
  return dayjs(time).format('YYYY-MM-DD HH:mm')
}

// 生命周期
onMounted(() => {
  fetchUsers()
})
</script>

<style scoped>
.user-list {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.search-bar {
  margin-bottom: 20px;
}

.pagination {
  margin-top: 20px;
  text-align: right;
}

.user-detail {
  padding: 20px 0;
}

@media (max-width: 768px) {
  .user-list {
    padding: 10px;
  }
  
  .search-bar .el-form {
    flex-direction: column;
  }
  
  .search-bar .el-form-item {
    margin-right: 0;
    margin-bottom: 10px;
  }
}
</style>