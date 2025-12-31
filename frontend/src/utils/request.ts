import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import { API_CONFIG } from '@/config/api'
import router from '@/router'

// 重试配置
const RETRY_CONFIG = {
  maxRetries: 2,
  retryDelay: 1000,
  retryCondition: (error: any) => {
    // 只对网络错误和5xx错误进行重试
    return !error.response || (error.response.status >= 500 && error.response.status < 600)
  }
}

// 延迟函数
const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms))

// 创建axios实例
const request: AxiosInstance = axios.create({
  baseURL: `${API_CONFIG.BASE_URL}${API_CONFIG.VERSION}`,
  timeout: API_CONFIG.TIMEOUT,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 请求拦截器
request.interceptors.request.use(
  (config) => {
    const authStore = useAuthStore()
    
    // 调试信息
    if (API_CONFIG.DEBUG) {
      console.log('=== HTTP请求 ===')
      console.log('URL:', config.url)
      console.log('方法:', config.method?.toUpperCase())
      console.log('完整地址:', `${config.baseURL}${config.url}`)
      console.log('请求数据:', config.data)
    }
    
    // 添加认证token
    if (authStore.token) {
      config.headers = config.headers || {}
      config.headers.Authorization = `Bearer ${authStore.token}`
      if (API_CONFIG.DEBUG) {
        console.log('添加认证头:', `Bearer ${authStore.token.substring(0, 20)}...`)
      }
    }
    
    return config
  },
  (error) => {
    console.error('Request error:', error)
    return Promise.reject(error)
  }
)

// 响应拦截器
request.interceptors.response.use(
  (response: AxiosResponse) => {
    const { data, status } = response
    
    // 调试信息
    if (API_CONFIG.DEBUG) {
      console.log('=== HTTP响应 ===')
      console.log('状态码:', status)
      console.log('响应数据:', data)
    }
    
    // 请求成功
    if (status >= 200 && status < 300) {
      // 后端返回格式: { success: true, data: {...} }
      if (data.success !== undefined) {
        // 返回完整的响应，让调用方处理
        return data
      }
      // 如果没有包装格式，直接返回
      return data
    }
    
    // 其他状态码处理
    ElMessage.error(data.message || '请求失败')
    return Promise.reject(new Error(data.message || '请求失败'))
  },
  async (error) => {
    const { response, message, config } = error
    const authStore = useAuthStore()
    
    // 重试逻辑
    if (RETRY_CONFIG.retryCondition(error) && config && !config.__retryCount) {
      config.__retryCount = 0
    }
    
    if (config && config.__retryCount < RETRY_CONFIG.maxRetries) {
      config.__retryCount += 1
      
      if (API_CONFIG.DEBUG) {
        console.log(`请求重试 ${config.__retryCount}/${RETRY_CONFIG.maxRetries}:`, config.url)
      }
      
      await delay(RETRY_CONFIG.retryDelay * config.__retryCount)
      return request(config)
    }
    
    if (response) {
      const { status, data } = response
      
      let errorMessage = ''
      
      switch (status) {
        case 401:
          // 未授权，清除token并跳转到登录页
          errorMessage = '登录已过期，请重新登录'
          ElMessage.error(errorMessage)
          authStore.logout()
          router.push('/login')
          break
          
        case 403:
          errorMessage = '没有权限访问该资源'
          ElMessage.error(errorMessage)
          break
          
        case 404:
          errorMessage = '请求的资源不存在'
          ElMessage.error(errorMessage)
          break
          
        case 409:
          // 冲突错误，通常是资源正在使用中
          errorMessage = data.error || data.message || '操作冲突，该资源可能正在使用中'
          ElMessage.error(errorMessage)
          break
          
        case 400:
          // 请求参数错误或业务逻辑错误
          errorMessage = data.error || data.message || '请求参数错误'
          ElMessage.error(errorMessage)
          break
          
        case 422:
          // 表单验证错误
          if (data.errors) {
            const errorMessages = Object.values(data.errors).flat()
            errorMessage = errorMessages.join(', ')
            ElMessage.error(errorMessage)
          } else {
            errorMessage = data.message || '请求参数错误'
            ElMessage.error(errorMessage)
          }
          break
          
        case 429:
          errorMessage = '请求过于频繁，请稍后再试'
          ElMessage.error(errorMessage)
          break
          
        case 500:
          errorMessage = '服务器内部错误，请稍后重试'
          ElMessage.error(errorMessage)
          break
          
        default:
          errorMessage = data.message || `请求失败 (${status})`
          ElMessage.error(errorMessage)
      }
    } else if (message.includes('timeout')) {
      ElMessage.error('请求超时，服务器响应较慢，请稍后重试')
    } else if (message.includes('Network Error')) {
      ElMessage.error('网络连接失败，请检查网络连接')
    } else {
      ElMessage.error('请求失败，请稍后重试')
    }
    
    return Promise.reject(error)
  }
)

// 通用请求方法
export const http = {
  get<T = any>(url: string, config?: AxiosRequestConfig): Promise<T> {
    return request.get(url, config)
  },
  
  post<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
    return request.post(url, data, config)
  },
  
  put<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
    return request.put(url, data, config)
  },
  
  delete<T = any>(url: string, config?: AxiosRequestConfig): Promise<T> {
    return request.delete(url, config)
  },
  
  upload<T = any>(url: string, formData: FormData, onProgress?: (progress: number) => void): Promise<T> {
    return request.post(url, formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      },
      onUploadProgress: (progressEvent) => {
        if (onProgress && progressEvent.total) {
          const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total)
          onProgress(progress)
        }
      }
    })
  }
}

export default request