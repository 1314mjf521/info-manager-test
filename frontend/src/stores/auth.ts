import { defineStore } from 'pinia'
import { ref, computed, readonly } from 'vue'
import { http } from '../utils/request'
import { API_ENDPOINTS } from '../config/api'
import type { User, LoginRequest, LoginResponse, RegisterRequest } from '../types'

export const useAuthStore = defineStore('auth', () => {
  // 状态
  const token = ref<string>(localStorage.getItem('token') || '')
  const refreshToken = ref<string>(localStorage.getItem('refreshToken') || '')
  const user = ref<User | null>(null)
  const isLoading = ref(false)

  // 计算属性
  const isAuthenticated = computed(() => !!token.value && !!user.value)
  const userRoles = computed(() => user.value?.roles?.map(role => role.name) || [])
  const userPermissions = computed(() => {
    // 从用户对象中获取实际权限
    if (!user.value || !user.value.permissions) {
      return []
    }
    return user.value.permissions.map(p => p.name) || []
  })

  // 检查权限
  const hasPermission = (resource: string, action: string, scope: string = 'all'): boolean => {
    if (!isAuthenticated.value) return false

    // 管理员拥有所有权限
    if (hasRole('系统管理员')) {
      return true
    }

    // 检查具体权限
    const permissions = userPermissions.value

    // 支持多种权限格式检查
    const permissionPatterns = [
      `${resource}:${action}:${scope}`,
      `${resource}:${action}`,
      `${resource}:manage`,
      resource
    ]

    // 如果scope是all，也检查own权限
    if (scope === 'all') {
      permissionPatterns.push(`${resource}:${action}:own`)
    }

    return permissionPatterns.some(pattern => permissions.includes(pattern))
  }

  // 检查角色
  const hasRole = (roleName: string): boolean => {
    if (!user.value || !user.value.roles) return false
    return user.value.roles.some(role => role.name === roleName || role.display_name === roleName)
  }

  // 登录
  const login = async (credentials: LoginRequest): Promise<void> => {
    try {
      isLoading.value = true
      console.log('=== 开始登录流程 ===')
      console.log('发送登录请求到:', API_ENDPOINTS.AUTH.LOGIN)
      console.log('请求数据:', { username: credentials.username, password: '***' })

      const response = await http.post<any>(API_ENDPOINTS.AUTH.LOGIN, credentials)

      console.log('=== 登录响应 ===')
      console.log('完整响应:', response)
      console.log('响应类型:', typeof response)
      console.log('有success字段:', 'success' in response)
      console.log('有data字段:', 'data' in response)

      // 处理后端响应格式: { success: true, data: { token, user, refresh_token } }
      let authData: LoginResponse
      if (response && response.success && response.data) {
        console.log('使用包装格式响应')
        authData = response.data
      } else if (response && response.token) {
        console.log('使用直接格式响应')
        authData = response
      } else {
        console.error('未知的响应格式:', response)
        throw new Error('登录响应格式不正确')
      }

      console.log('=== 提取的认证数据 ===')
      console.log('认证数据:', authData)
      console.log('token存在:', !!authData.token)
      console.log('user存在:', !!authData.user)

      // 验证响应数据
      if (!authData.token || !authData.user) {
        console.error('登录数据不完整')
        console.error('token:', authData.token)
        console.error('user:', authData.user)
        throw new Error('登录响应数据不完整')
      }

      // 保存认证信息
      token.value = authData.token
      refreshToken.value = authData.refresh_token || ''
      user.value = authData.user

      // 持久化到localStorage
      localStorage.setItem('token', authData.token)
      if (authData.refresh_token) {
        localStorage.setItem('refreshToken', authData.refresh_token)
      }
      localStorage.setItem('user', JSON.stringify(authData.user))

      console.log('=== 登录状态保存完成 ===')
      console.log('token长度:', authData.token.length)
      console.log('token前缀:', authData.token.substring(0, 20) + '...')
      console.log('用户名:', authData.user.username)
      console.log('用户ID:', authData.user.id)
      console.log('用户角色:', authData.user.roles)
      console.log('认证状态:', isAuthenticated.value)

    } catch (error: any) {
      console.error('=== 登录失败 ===')
      console.error('错误对象:', error)
      console.error('错误类型:', typeof error)
      console.error('错误消息:', error.message)
      console.error('错误堆栈:', error.stack)

      if (error.response) {
        console.error('HTTP响应错误:')
        console.error('状态码:', error.response.status)
        console.error('响应数据:', error.response.data)
        console.error('响应头:', error.response.headers)
      } else if (error.request) {
        console.error('网络请求错误:', error.request)
      }

      // 清除可能的部分状态
      token.value = ''
      refreshToken.value = ''
      user.value = null
      localStorage.removeItem('token')
      localStorage.removeItem('refreshToken')
      localStorage.removeItem('user')
      throw error
    } finally {
      isLoading.value = false
    }
  }

  // 注册
  const register = async (registerData: RegisterRequest): Promise<void> => {
    try {
      isLoading.value = true
      await http.post(API_ENDPOINTS.AUTH.REGISTER, registerData)
    } catch (error) {
      console.error('Register failed:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  // 刷新token
  const refreshAccessToken = async (): Promise<void> => {
    try {
      const response = await http.post<LoginResponse>(API_ENDPOINTS.AUTH.REFRESH, {
        refreshToken: refreshToken.value
      })

      token.value = response.token
      localStorage.setItem('token', response.token)

      if (response.refresh_token) {
        refreshToken.value = response.refresh_token
        localStorage.setItem('refreshToken', response.refresh_token)
      }
    } catch (error) {
      console.error('Token refresh failed:', error)
      logout()
      throw error
    }
  }

  // 获取用户信息
  const fetchUserProfile = async (): Promise<void> => {
    try {
      const userData = await http.get<User>(API_ENDPOINTS.AUTH.PROFILE)
      user.value = userData
      localStorage.setItem('user', JSON.stringify(userData))
    } catch (error) {
      console.error('Fetch user profile failed:', error)
      throw error
    }
  }

  // 更新用户信息
  const updateProfile = async (profileData: Partial<User>): Promise<void> => {
    try {
      const updatedUser = await http.put<User>(API_ENDPOINTS.AUTH.PROFILE, profileData)
      user.value = updatedUser
      localStorage.setItem('user', JSON.stringify(updatedUser))
    } catch (error) {
      console.error('Update profile failed:', error)
      throw error
    }
  }

  // 修改密码
  const changePassword = async (passwordData: { oldPassword: string; newPassword: string }): Promise<void> => {
    try {
      await http.put(API_ENDPOINTS.AUTH.CHANGE_PASSWORD, passwordData)
    } catch (error) {
      console.error('Change password failed:', error)
      throw error
    }
  }

  // 登出
  const logout = async (): Promise<void> => {
    try {
      if (token.value) {
        await http.post(API_ENDPOINTS.AUTH.LOGOUT)
      }
    } catch (error) {
      console.error('Logout request failed:', error)
    } finally {
      // 清除本地状态
      token.value = ''
      refreshToken.value = ''
      user.value = null

      // 清除localStorage
      localStorage.removeItem('token')
      localStorage.removeItem('refreshToken')
      localStorage.removeItem('user')
    }
  }

  // 初始化认证状态
  const initAuth = (): void => {
    console.log('=== 初始化认证状态 ===')
    const savedToken = localStorage.getItem('token')
    const savedRefreshToken = localStorage.getItem('refreshToken')
    const savedUser = localStorage.getItem('user')

    console.log('保存的token存在:', !!savedToken)
    console.log('保存的refreshToken存在:', !!savedRefreshToken)
    console.log('保存的用户信息存在:', !!savedUser)

    if (savedToken) {
      token.value = savedToken
    }

    if (savedRefreshToken) {
      refreshToken.value = savedRefreshToken
    }

    if (savedUser && savedToken) {
      try {
        const parsedUser = JSON.parse(savedUser)
        user.value = parsedUser
        console.log('用户信息恢复成功:', parsedUser.username)
        console.log('认证状态:', isAuthenticated.value)
      } catch (error) {
        console.error('解析保存的用户数据失败:', error)
        logout()
      }
    } else if (savedToken && !savedUser) {
      console.warn('有token但没有用户信息，清除认证状态')
      logout()
    }

    console.log('认证状态初始化完成')
  }

  return {
    // 状态
    token: readonly(token),
    refreshToken: readonly(refreshToken),
    user: readonly(user),
    isLoading: readonly(isLoading),

    // 计算属性
    isAuthenticated,
    userRoles,
    userPermissions,

    // 方法
    hasPermission,
    hasRole,
    login,
    register,
    refreshAccessToken,
    fetchUserProfile,
    updateProfile,
    changePassword,
    logout,
    initAuth
  }
})

