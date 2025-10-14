<template>
  <el-container class="layout-container">
    <!-- 侧边栏 -->
    <el-aside :width="isCollapse ? '64px' : '200px'" class="sidebar">
      <div class="logo">
        <span>{{ isCollapse ? '信管' : '信息管理系统' }}</span>
      </div>
      
      <el-menu
        :default-active="$route.path"
        :collapse="isCollapse"
        :unique-opened="true"
        router
        class="sidebar-menu"
      >
        <template v-for="item in menuItems" :key="item.path">
          <el-menu-item
            v-if="!item.hidden && hasPermission(item.permission)"
            :index="item.path"
          >
            <el-icon><component :is="item.icon" /></el-icon>
            <template #title>{{ item.title }}</template>
          </el-menu-item>
        </template>
      </el-menu>
    </el-aside>

    <el-container>
      <!-- 头部 -->
      <el-header class="header">
        <div class="header-left">
          <el-button type="text" @click="toggleCollapse">
            <el-icon><Expand v-if="isCollapse" /><Fold v-else /></el-icon>
          </el-button>
          
          <el-breadcrumb separator="/">
            <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
            <el-breadcrumb-item v-if="$route.meta?.title">
              {{ $route.meta.title }}
            </el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        
        <div class="header-right">
          <!-- 系统健康状态 -->
          <el-tooltip content="系统状态" placement="bottom">
            <el-badge :is-dot="!systemHealthy" type="danger">
              <el-button type="text" @click="checkSystemHealth">
                <el-icon><Monitor /></el-icon>
              </el-button>
            </el-badge>
          </el-tooltip>
          
          <!-- 用户菜单 -->
          <el-dropdown @command="handleUserCommand">
            <span class="user-dropdown">
              <el-avatar :size="32" :src="authStore.user?.avatar">
                {{ authStore.user?.username?.charAt(0).toUpperCase() }}
              </el-avatar>
              <span class="username">{{ authStore.user?.username }}</span>
              <el-icon><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile">
                  <el-icon><User /></el-icon>
                  个人资料
                </el-dropdown-item>
                <el-dropdown-item divided command="logout">
                  <el-icon><SwitchButton /></el-icon>
                  退出登录
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <!-- 主内容区 -->
      <el-main class="main-content">
        <router-view />
      </el-main>
    </el-container>
    
    <!-- 公共公告组件 -->
    <PublicAnnouncements ref="publicAnnouncementsRef" />
  </el-container>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Expand,
  Fold,
  Monitor,
  User,
  ArrowDown,
  SwitchButton,
  Dashboard,
  Document,
  Collection,
  Folder,
  Download,
  UserFilled,
  Setting
} from '@element-plus/icons-vue'
import { useAuthStore } from '@/stores/auth'
import PublicAnnouncements from '@/components/PublicAnnouncements.vue'

const router = useRouter()
const authStore = useAuthStore()

// 侧边栏折叠状态
const isCollapse = ref(false)
const systemHealthy = ref(true)

// 公告组件引用
const publicAnnouncementsRef = ref()

// 菜单项
const menuItems = computed(() => [
  {
    path: '/dashboard',
    title: '仪表板',
    icon: 'Dashboard',
    permission: null,
    hidden: false
  },
  {
    path: '/records',
    title: '记录管理',
    icon: 'Document',
    permission: 'records:read',
    hidden: false
  },
  {
    path: '/record-types',
    title: '记录类型',
    icon: 'Collection',
    permission: 'system:admin',
    hidden: false
  },
  {
    path: '/files',
    title: '文件管理',
    icon: 'Folder',
    permission: 'files:read',
    hidden: false
  },
  {
    path: '/export',
    title: '数据导出',
    icon: 'Download',
    permission: 'records:read',
    hidden: false
  },
  {
    path: '/users',
    title: '用户管理',
    icon: 'User',
    permission: 'users:read',
    hidden: false
  },
  {
    path: '/roles',
    title: '角色管理',
    icon: 'UserFilled',
    permission: 'system:admin',
    hidden: false
  },
  {
    path: '/system',
    title: '系统管理',
    icon: 'Setting',
    permission: 'system:admin',
    hidden: false
  }
])

// 权限检查
const hasPermission = (permission: string | null) => {
  if (!permission) return true
  const [resource, action, scope = 'all'] = permission.split(':')
  return authStore.hasPermission(resource, action, scope)
}

// 切换侧边栏
const toggleCollapse = () => {
  isCollapse.value = !isCollapse.value
}

// 检查系统健康状态
const checkSystemHealth = async () => {
  try {
    // TODO: 调用系统健康检查API
    if (systemHealthy.value) {
      ElMessage.success('系统运行正常')
    } else {
      ElMessage.warning('系统状态异常')
    }
  } catch (error) {
    ElMessage.error('无法获取系统状态')
  }
}

// 用户菜单命令处理
const handleUserCommand = async (command: string) => {
  switch (command) {
    case 'profile':
      router.push('/profile')
      break
    case 'logout':
      try {
        await ElMessageBox.confirm('确定要退出登录吗？', '提示', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        })
        
        await authStore.logout()
        ElMessage.success('已退出登录')
        router.push('/login')
      } catch (error) {
        // 用户取消
      }
      break
  }
}

// 生命周期
onMounted(() => {
  // 初始化系统状态检查
  checkSystemHealth()
})
</script>

<style scoped>
.layout-container {
  height: 100vh;
}

.sidebar {
  background-color: #304156;
  transition: width 0.3s;
}

.logo {
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #2b3a4b;
  color: white;
  font-size: 16px;
  font-weight: 600;
}

.sidebar-menu {
  border: none;
  background-color: #304156;
}

.sidebar-menu .el-menu-item {
  color: #bfcbd9;
}

.sidebar-menu .el-menu-item:hover {
  background-color: #263445;
  color: #409eff;
}

.sidebar-menu .el-menu-item.is-active {
  background-color: #409eff;
  color: white;
}

.header {
  background-color: white;
  border-bottom: 1px solid #e4e7ed;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 20px;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 15px;
}

.user-dropdown {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 5px 10px;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.user-dropdown:hover {
  background-color: #f5f7fa;
}

.username {
  font-size: 14px;
  color: #606266;
}

.main-content {
  background-color: #f0f2f5;
  padding: 20px;
  overflow-y: auto;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .sidebar {
    width: 64px !important;
  }
  
  .header {
    padding: 0 10px;
  }
  
  .main-content {
    padding: 10px;
  }
  
  .username {
    display: none;
  }
}
</style>