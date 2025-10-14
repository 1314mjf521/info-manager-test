// API配置
export const API_CONFIG = {
  // 后端服务器地址 - 根据环境自动切换
  BASE_URL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080',

  // API版本
  VERSION: '/api/v1',

  // 请求超时时间
  TIMEOUT: 15000, // 增加超时时间到15秒

  // 分页默认配置
  PAGE_SIZE: 20,

  // 文件上传大小限制 (MB)
  MAX_FILE_SIZE: 10,

  // 调试模式
  DEBUG: import.meta.env.DEV
}

// 获取完整的API地址
export const getApiUrl = (path: string): string => {
  return `${API_CONFIG.BASE_URL}${API_CONFIG.VERSION}${path}`
}

// API端点定义
export const API_ENDPOINTS = {
  // 认证相关
  AUTH: {
    LOGIN: '/auth/login',
    REGISTER: '/auth/register',
    REFRESH: '/auth/refresh',
    LOGOUT: '/auth/logout',
    PROFILE: '/users/profile',
    CHANGE_PASSWORD: '/users/password'
  },

  // 记录管理
  RECORDS: {
    LIST: '/records',
    CREATE: '/records',
    UPDATE: (id: number) => `/records/${id}`,
    DELETE: (id: number) => `/records/${id}`,
    DETAIL: (id: number) => `/records/${id}`,
    BATCH: '/records/batch',
    IMPORT: '/records/import',
    BATCH_STATUS: '/records/batch-status',
    BATCH_DELETE: '/records/batch',
    BY_TYPE: (type: string) => `/records/type/${type}`
  },

  // 记录类型
  RECORD_TYPES: {
    LIST: '/record-types',
    CREATE: '/record-types',
    UPDATE: (id: number) => `/record-types/${id}`,
    DELETE: (id: number) => `/record-types/${id}`,
    DETAIL: (id: number) => `/record-types/${id}`,
    IMPORT: '/record-types/import',
    BATCH_STATUS: '/record-types/batch-status',
    BATCH_DELETE: '/record-types/batch'
  },

  // 文件管理
  FILES: {
    UPLOAD: '/files/upload',
    LIST: '/files',
    DOWNLOAD: (id: number) => `/files/${id}`,
    DELETE: (id: number) => `/files/${id}`,
    INFO: (id: number) => `/files/${id}/info`,
    OCR: '/files/ocr'
  },

  // 数据导出
  EXPORT: {
    TEMPLATES: '/export/templates',
    RECORDS: '/export/records',
    FILES: '/export/files',
    DOWNLOAD: (id: number) => `/export/files/${id}/download`
  },

  // 权限管理
  PERMISSIONS: {
    CHECK: '/permissions/check',
    USER: (userId: number) => `/permissions/user/${userId}`,
    LIST: '/permissions'
  },

  // 用户管理
  USERS: {
    LIST: '/users',
    CREATE: '/users',
    UPDATE: (id: number) => `/users/${id}`,
    DELETE: (id: number) => `/users/${id}`,
    DETAIL: (id: number) => `/users/${id}`,
    ROLES: (id: number) => `/users/${id}/roles`
  },

  // 角色管理
  ROLES: {
    LIST: '/admin/roles',
    CREATE: '/admin/roles',
    UPDATE: (id: number) => `/admin/roles/${id}`,
    DELETE: (id: number) => `/admin/roles/${id}`,
    PERMISSIONS: (id: number) => `/admin/roles/${id}/permissions`,
    IMPORT: '/admin/roles/import',
    BATCH_STATUS: '/admin/roles/batch-status',
    BATCH_DELETE: '/admin/roles/batch'
  },

  // 系统管理
  SYSTEM: {
    HEALTH: '/system/health',
    CONFIG: '/config',
    ANNOUNCEMENTS: '/announcements'
  }
}

// 环境配置
export const ENV_CONFIG = {
  isDevelopment: import.meta.env.DEV,
  isProduction: import.meta.env.PROD,
  apiBaseUrl: API_CONFIG.BASE_URL
}