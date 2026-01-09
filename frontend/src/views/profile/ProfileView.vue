<template>
  <div class="profile-view">
    <el-row :gutter="20">
      <!-- 个人信息 -->
      <el-col :span="8">
        <el-card>
          <template #header>
            <span>个人信息</span>
          </template>
          
          <div class="profile-info">
            <div class="avatar-section">
              <el-avatar :src="userInfo.avatar" :size="80">
                {{ userInfo.username?.charAt(0).toUpperCase() }}
              </el-avatar>
              <el-button size="small" style="margin-top: 10px;" @click="handleAvatarUpload">
                更换头像
              </el-button>
            </div>
            
            <div class="info-section">
              <div class="info-item">
                <label>用户名:</label>
                <span>{{ userInfo.username }}</span>
              </div>
              <div class="info-item">
                <label>邮箱:</label>
                <span>{{ userInfo.email }}</span>
              </div>
              <div class="info-item">
                <label>角色:</label>
                <el-tag
                  v-for="role in userInfo.roles"
                  :key="role"
                  size="small"
                  style="margin-right: 4px;"
                >
                  {{ getRoleText(role) }}
                </el-tag>
              </div>
              <div class="info-item">
                <label>最后登录:</label>
                <span>{{ userInfo.lastLogin ? formatTime(userInfo.lastLogin) : '从未登录' }}</span>
              </div>
              <div class="info-item">
                <label>注册时间:</label>
                <span>{{ formatTime(userInfo.createdAt) }}</span>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <!-- 编辑资料 -->
      <el-col :span="16">
        <el-card>
          <template #header>
            <span>编辑资料</span>
          </template>
          
          <el-tabs v-model="activeTab">
            <el-tab-pane label="基本信息" name="basic">
              <el-form
                ref="basicFormRef"
                :model="basicForm"
                :rules="basicRules"
                label-width="100px"
                style="max-width: 500px;"
              >
                <el-form-item label="用户名" prop="username">
                  <el-input v-model="basicForm.username" placeholder="请输入用户名" />
                </el-form-item>
                <el-form-item label="邮箱" prop="email">
                  <el-input v-model="basicForm.email" placeholder="请输入邮箱" />
                </el-form-item>
                <el-form-item label="昵称">
                  <el-input v-model="basicForm.nickname" placeholder="请输入昵称" />
                </el-form-item>
                <el-form-item label="手机号">
                  <el-input v-model="basicForm.phone" placeholder="请输入手机号" />
                </el-form-item>
                <el-form-item label="个人简介">
                  <el-input
                    v-model="basicForm.bio"
                    type="textarea"
                    :rows="3"
                    placeholder="请输入个人简介"
                  />
                </el-form-item>
                <el-form-item>
                  <el-button type="primary" @click="handleUpdateBasic" :loading="updating">
                    更新基本信息
                  </el-button>
                </el-form-item>
              </el-form>
            </el-tab-pane>
            
            <el-tab-pane label="修改密码" name="password">
              <el-form
                ref="passwordFormRef"
                :model="passwordForm"
                :rules="passwordRules"
                label-width="100px"
                style="max-width: 500px;"
              >
                <el-form-item label="当前密码" prop="oldPassword">
                  <el-input
                    v-model="passwordForm.oldPassword"
                    type="password"
                    placeholder="请输入当前密码"
                    show-password
                  />
                </el-form-item>
                <el-form-item label="新密码" prop="newPassword">
                  <el-input
                    v-model="passwordForm.newPassword"
                    type="password"
                    placeholder="请输入新密码"
                    show-password
                  />
                </el-form-item>
                <el-form-item label="确认密码" prop="confirmPassword">
                  <el-input
                    v-model="passwordForm.confirmPassword"
                    type="password"
                    placeholder="请确认新密码"
                    show-password
                  />
                </el-form-item>
                <el-form-item>
                  <el-button type="primary" @click="handleChangePassword" :loading="changingPassword">
                    修改密码
                  </el-button>
                </el-form-item>
              </el-form>
            </el-tab-pane>
            
            <el-tab-pane label="安全设置" name="security">
              <div class="security-settings">
                <div class="security-item">
                  <div class="security-info">
                    <h4>登录保护</h4>
                    <p>开启后，登录时需要验证手机号或邮箱</p>
                  </div>
                  <el-switch v-model="securitySettings.loginProtection" />
                </div>
                
                <div class="security-item">
                  <div class="security-info">
                    <h4>操作验证</h4>
                    <p>重要操作时需要验证身份</p>
                  </div>
                  <el-switch v-model="securitySettings.operationVerification" />
                </div>
                
                <div class="security-item">
                  <div class="security-info">
                    <h4>登录通知</h4>
                    <p>新设备登录时发送通知</p>
                  </div>
                  <el-switch v-model="securitySettings.loginNotification" />
                </div>
                
                <el-button type="primary" @click="handleUpdateSecurity" :loading="updatingSecurity">
                  保存安全设置
                </el-button>
              </div>
            </el-tab-pane>
          </el-tabs>
        </el-card>
      </el-col>
    </el-row>
    
    <!-- 头像上传对话框 -->
    <el-dialog v-model="avatarDialogVisible" title="更换头像" width="400px">
      <el-upload
        ref="avatarUploadRef"
        :action="uploadUrl"
        :headers="uploadHeaders"
        :show-file-list="false"
        :on-success="handleAvatarSuccess"
        :before-upload="beforeAvatarUpload"
        drag
      >
        <el-icon class="el-icon--upload"><upload-filled /></el-icon>
        <div class="el-upload__text">
          将头像拖到此处，或<em>点击上传</em>
        </div>
        <template #tip>
          <div class="el-upload__tip">
            只能上传jpg/png文件，且不超过2MB
          </div>
        </template>
      </el-upload>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { UploadFilled } from '@element-plus/icons-vue'
import { http } from '../../utils/request'
import { useAuthStore } from '../../stores/auth'
import { API_CONFIG, API_ENDPOINTS } from '../../config/api'
import dayjs from 'dayjs'

const authStore = useAuthStore()

// 响应式数据
const activeTab = ref('basic')
const updating = ref(false)
const changingPassword = ref(false)
const updatingSecurity = ref(false)
const avatarDialogVisible = ref(false)
const basicFormRef = ref()
const passwordFormRef = ref()
const avatarUploadRef = ref()

const userInfo = ref({
  id: 0,
  username: '',
  email: '',
  nickname: '',
  phone: '',
  bio: '',
  avatar: '',
  roles: [],
  lastLogin: '',
  createdAt: ''
})

const basicForm = reactive({
  username: '',
  email: '',
  nickname: '',
  phone: '',
  bio: ''
})

const passwordForm = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const securitySettings = reactive({
  loginProtection: false,
  operationVerification: true,
  loginNotification: true
})

// 计算属性
const uploadUrl = computed(() => `${API_CONFIG.BASE_URL}${API_CONFIG.VERSION}${API_ENDPOINTS.FILES.UPLOAD}`)
const uploadHeaders = computed(() => ({
  Authorization: `Bearer ${authStore.token}`
}))

// 表单验证规则
const basicRules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 50, message: '用户名长度在 3 到 50 个字符', trigger: 'blur' }
  ],
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入正确的邮箱格式', trigger: 'blur' }
  ]
}

const passwordRules = {
  oldPassword: [
    { required: true, message: '请输入当前密码', trigger: 'blur' }
  ],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能少于 6 个字符', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    {
      validator: (rule: any, value: string, callback: Function) => {
        if (value !== passwordForm.newPassword) {
          callback(new Error('两次输入密码不一致'))
        } else {
          callback()
        }
      },
      trigger: 'blur'
    }
  ]
}

// 获取用户信息
const fetchUserInfo = async () => {
  try {
    const response = await http.get(API_ENDPOINTS.AUTH.PROFILE)
    
    if (response) {
      userInfo.value = {
        ...response,
        nickname: response.nickname || '',
        phone: response.phone || '',
        bio: response.bio || ''
      }
      
      // 同步到表单
      Object.assign(basicForm, {
        username: response.username,
        email: response.email,
        nickname: response.nickname || '',
        phone: response.phone || '',
        bio: response.bio || ''
      })
    } else {
      // 使用当前认证用户信息
      const currentUser = authStore.user
      if (currentUser) {
        userInfo.value = {
          ...currentUser,
          nickname: '',
          phone: '',
          bio: '',
          avatar: '',
          lastLogin: '',
          createdAt: new Date().toISOString()
        }
        
        Object.assign(basicForm, {
          username: currentUser.username,
          email: currentUser.email,
          nickname: '',
          phone: '',
          bio: ''
        })
      }
    }
  } catch (error) {
    console.error('获取用户信息失败:', error)
    // 使用当前认证用户信息作为fallback
    const currentUser = authStore.user
    if (currentUser) {
      userInfo.value = {
        id: currentUser.id,
        username: currentUser.username,
        email: currentUser.email,
        nickname: '',
        phone: '',
        bio: '',
        avatar: '',
        roles: currentUser.roles || [],
        lastLogin: '',
        createdAt: new Date().toISOString()
      }
      
      Object.assign(basicForm, {
        username: currentUser.username,
        email: currentUser.email,
        nickname: '',
        phone: '',
        bio: ''
      })
    }
    ElMessage.warning('使用缓存数据，请检查网络连接')
  }
}

// 更新基本信息
const handleUpdateBasic = async () => {
  if (!basicFormRef.value) return
  
  try {
    await basicFormRef.value.validate()
    
    updating.value = true
    
    await http.put(API_ENDPOINTS.AUTH.PROFILE, basicForm)
    
    ElMessage.success('基本信息更新成功')
    fetchUserInfo()
  } catch (error: any) {
    if (error.fields) {
      // 表单验证错误
      return
    }
    console.error('更新基本信息失败:', error)
    ElMessage.error(error.message || '更新基本信息失败')
  } finally {
    updating.value = false
  }
}

// 修改密码
const handleChangePassword = async () => {
  if (!passwordFormRef.value) return
  
  try {
    await passwordFormRef.value.validate()
    
    changingPassword.value = true
    
    await http.put(API_ENDPOINTS.AUTH.CHANGE_PASSWORD, {
      oldPassword: passwordForm.oldPassword,
      newPassword: passwordForm.newPassword
    })
    
    ElMessage.success('密码修改成功')
    
    // 重置表单
    Object.assign(passwordForm, {
      oldPassword: '',
      newPassword: '',
      confirmPassword: ''
    })
  } catch (error: any) {
    if (error.fields) {
      // 表单验证错误
      return
    }
    console.error('修改密码失败:', error)
    ElMessage.error(error.message || '修改密码失败')
  } finally {
    changingPassword.value = false
  }
}

// 更新安全设置
const handleUpdateSecurity = async () => {
  updatingSecurity.value = true
  try {
    await http.put('/users/security', securitySettings)
    ElMessage.success('安全设置更新成功')
  } catch (error) {
    console.error('更新安全设置失败:', error)
    ElMessage.error('更新安全设置失败')
  } finally {
    updatingSecurity.value = false
  }
}

// 头像上传
const handleAvatarUpload = () => {
  avatarDialogVisible.value = true
}

const beforeAvatarUpload = (file: File) => {
  const isJPG = file.type === 'image/jpeg' || file.type === 'image/png'
  const isLt2M = file.size / 1024 / 1024 < 2

  if (!isJPG) {
    ElMessage.error('头像只能是 JPG/PNG 格式!')
    return false
  }
  if (!isLt2M) {
    ElMessage.error('头像大小不能超过 2MB!')
    return false
  }
  return true
}

const handleAvatarSuccess = (response: any) => {
  if (response.success) {
    userInfo.value.avatar = response.data.url
    ElMessage.success('头像更新成功')
    avatarDialogVisible.value = false
  } else {
    ElMessage.error('头像上传失败')
  }
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
  fetchUserInfo()
})
</script>

<style scoped>
.profile-view {
  padding: 20px;
}

.profile-info {
  text-align: center;
}

.avatar-section {
  margin-bottom: 30px;
}

.info-section {
  text-align: left;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 0;
  border-bottom: 1px solid #f0f0f0;
}

.info-item:last-child {
  border-bottom: none;
}

.info-item label {
  font-weight: 500;
  color: #606266;
  min-width: 80px;
}

.security-settings {
  max-width: 500px;
}

.security-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 0;
  border-bottom: 1px solid #f0f0f0;
}

.security-item:last-child {
  border-bottom: none;
}

.security-info h4 {
  margin: 0 0 5px 0;
  color: #303133;
}

.security-info p {
  margin: 0;
  color: #909399;
  font-size: 14px;
}

@media (max-width: 768px) {
  .profile-view {
    padding: 10px;
  }
  
  .el-row {
    flex-direction: column;
  }
  
  .el-col {
    margin-bottom: 20px;
  }
}
</style>
