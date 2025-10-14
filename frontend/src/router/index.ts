import { createRouter, createWebHistory } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import type { RouteMeta } from '@/types'

// 路由配置
const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/auth/LoginView.vue'),
    meta: {
      title: '登录',
      hidden: true
    } as RouteMeta
  },
  {
    path: '/register',
    name: 'Register',
    component: () => import('@/views/auth/RegisterView.vue'),
    meta: {
      title: '注册',
      hidden: true
    } as RouteMeta
  },
  {
    path: '/',
    name: 'Layout',
    component: () => import('@/layout/MainLayout.vue'),
    redirect: '/dashboard',
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/dashboard/DashboardView.vue'),
        meta: {
          title: '仪表板',
          icon: 'Dashboard'
        } as RouteMeta
      },
      {
        path: 'records',
        name: 'Records',
        component: () => import('@/views/records/RecordListView.vue'),
        meta: {
          title: '记录管理',
          icon: 'Document',
          permission: 'records:read'
        } as RouteMeta
      },
      {
        path: 'records/create',
        name: 'RecordCreate',
        component: () => import('@/views/records/RecordFormView.vue'),
        meta: {
          title: '创建记录',
          hidden: true,
          permission: 'records:write'
        } as RouteMeta
      },
      {
        path: 'records/:id',
        name: 'RecordDetail',
        component: () => import('@/views/records/RecordDetailView.vue'),
        meta: {
          title: '记录详情',
          hidden: true,
          permission: 'records:read'
        } as RouteMeta
      },
      {
        path: 'records/:id/edit',
        name: 'RecordEdit',
        component: () => import('@/views/records/RecordFormView.vue'),
        meta: {
          title: '编辑记录',
          hidden: true,
          permission: 'records:write'
        } as RouteMeta
      },
      {
        path: 'record-types',
        name: 'RecordTypes',
        component: () => import('@/views/record-types/RecordTypeListView.vue'),
        meta: {
          title: '记录类型',
          icon: 'Collection',
          permission: 'system:admin'
        } as RouteMeta
      },
      {
        path: 'files',
        name: 'Files',
        component: () => import('@/views/files/FileListView.vue'),
        meta: {
          title: '文件管理',
          icon: 'Folder',
          permission: 'files:read'
        } as RouteMeta
      },
      {
        path: 'export',
        name: 'Export',
        component: () => import('@/views/export/ExportView.vue'),
        meta: {
          title: '数据导出',
          icon: 'Download',
          permission: 'records:read'
        } as RouteMeta
      },
      {
        path: 'users',
        name: 'Users',
        component: () => import('@/views/admin/UserManagement.vue'),
        meta: {
          title: '用户管理',
          icon: 'User',
          permission: 'users:read'
        } as RouteMeta
      },
      {
        path: 'roles',
        name: 'Roles',
        component: () => import('@/views/admin/RoleManagement.vue'),
        meta: {
          title: '角色管理',
          icon: 'UserFilled',
          permission: 'system:admin'
        } as RouteMeta
      },
      {
        path: 'system',
        name: 'System',
        component: () => import('@/views/system/SystemView.vue'),
        meta: {
          title: '系统管理',
          icon: 'Setting',
          permission: 'system:admin'
        } as RouteMeta
      },
      {
        path: 'profile',
        name: 'Profile',
        component: () => import('@/views/profile/ProfileView.vue'),
        meta: {
          title: '个人资料',
          hidden: true
        } as RouteMeta
      },
      {
        path: 'debug/login',
        name: 'LoginDebug',
        component: () => import('@/views/debug/LoginDebugView.vue'),
        meta: {
          title: '登录调试',
          hidden: true
        } as RouteMeta
      }
    ]
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('@/views/error/NotFoundView.vue'),
    meta: {
      title: '页面不存在',
      hidden: true
    } as RouteMeta
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()
  
  // 设置页面标题
  if (to.meta?.title) {
    document.title = `${to.meta.title} - 信息管理系统`
  }
  
  console.log('=== 路由守卫调试信息 ===')
  console.log('目标路由:', to.path)
  console.log('来源路由:', from.path)
  console.log('认证状态:', authStore.isAuthenticated)
  console.log('token存在:', !!authStore.token)
  console.log('用户信息:', authStore.user)
  
  // 公开路由，无需认证
  const publicRoutes = ['/login', '/register']
  if (publicRoutes.includes(to.path)) {
    console.log('访问公开路由:', to.path)
    // 如果已登录，重定向到首页
    if (authStore.isAuthenticated) {
      console.log('已登录用户访问登录页，重定向到首页')
      next('/')
    } else {
      console.log('未登录用户访问登录页，允许访问')
      next()
    }
    return
  }
  
  // 需要认证的路由
  if (!authStore.isAuthenticated) {
    console.log('未认证用户访问受保护路由，重定向到登录页')
    // 保存原始路径用于登录后重定向
    const redirectPath = to.path !== '/' ? to.fullPath : undefined
    if (redirectPath) {
      next(`/login?redirect=${encodeURIComponent(redirectPath)}`)
    } else {
      next('/login')
    }
    return
  }
  
  console.log('用户已认证，检查权限...')
  
  // 权限检查
  if (to.meta?.permission) {
    const permission = to.meta.permission as string
    const [resource, action, scope = 'all'] = permission.split(':')
    console.log('检查权限:', permission)
    
    if (!authStore.hasPermission(resource, action, scope)) {
      console.log('权限检查失败')
      ElMessage.error('没有权限访问该页面')
      next('/')
      return
    }
    console.log('权限检查通过')
  }
  
  console.log('路由守卫通过，允许访问:', to.path)
  next()
})

export default router