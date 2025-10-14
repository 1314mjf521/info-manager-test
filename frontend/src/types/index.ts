// 通用类型定义

// API响应基础类型
export interface ApiResponse<T = any> {
  success: boolean
  data?: T
  error?: {
    code: string
    message: string
    details?: string
  }
  meta?: {
    page?: number
    pageSize?: number
    total?: number
    totalPages?: number
  }
}

// 分页响应类型
export interface PaginatedResponse<T> {
  items: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}

// 用户相关类型
export interface User {
  id: number
  username: string
  email: string
  avatar?: string
  roles: string[]
  is_active: boolean
  last_login?: string
  created_at?: string
  updated_at?: string
}

export interface Role {
  id: number
  name: string
  description?: string
  permissions: Permission[]
}

export interface Permission {
  id: number
  resource: string
  action: string
  scope: string
  description?: string
}

// 认证相关类型
export interface LoginRequest {
  username: string
  password: string
}

export interface LoginResponse {
  token: string
  refresh_token: string
  user: User
  expires_at: string
}

export interface RegisterRequest {
  username: string
  email: string
  password: string
  confirmPassword: string
}

// 记录相关类型
export interface Record {
  id: number
  type: string
  title: string
  content: any
  status: 'draft' | 'published' | 'archived'
  createdBy: number
  creator?: User
  createdAt: string
  updatedAt: string
  deletedAt?: string
}

export interface RecordType {
  id: number
  name: string
  description?: string
  fields: RecordField[]
  isActive: boolean
  createdAt: string
  updatedAt: string
}

export interface RecordField {
  name: string
  type: 'text' | 'number' | 'date' | 'select' | 'textarea' | 'tags' | 'file'
  label: string
  required: boolean
  options?: string[]
  validation?: any
}

// 文件相关类型
export interface FileInfo {
  id: number
  filename: string
  originalName: string
  size: number
  mimeType: string
  path: string
  hash: string
  uploadedBy: number
  uploader?: User
  createdAt: string
}

export interface UploadResponse {
  file: FileInfo
  url: string
}

// OCR相关类型
export interface OCRRequest {
  fileId: number
  language?: string
}

export interface OCRResponse {
  text: string
  confidence: number
  language: string
  regions: OCRRegion[]
}

export interface OCRRegion {
  text: string
  confidence: number
  boundingBox: {
    x: number
    y: number
    width: number
    height: number
  }
}

// 导出相关类型
export interface ExportTemplate {
  id: number
  name: string
  description?: string
  format: 'excel' | 'pdf' | 'csv' | 'json'
  config: any
  createdBy: number
  createdAt: string
  updatedAt: string
}

export interface ExportRequest {
  templateId?: number
  format: 'excel' | 'pdf' | 'csv' | 'json'
  filters?: any
  fields?: string[]
}

export interface ExportTask {
  id: number
  status: 'pending' | 'processing' | 'completed' | 'failed'
  progress: number
  format: 'excel' | 'pdf' | 'csv' | 'json'
  fileUrl?: string
  error?: string
  createdAt: string
  completedAt?: string
}

// 系统相关类型
export interface SystemHealth {
  status: 'healthy' | 'unhealthy'
  version: string
  uptime: number
  database: {
    status: 'connected' | 'disconnected'
    responseTime: number
  }
  redis: {
    status: 'connected' | 'disconnected'
    responseTime: number
  }
}

export interface Announcement {
  id: number
  title: string
  content: string
  type: 'info' | 'warning' | 'error' | 'success'
  priority: 'low' | 'medium' | 'high'
  isActive: boolean
  startTime?: string
  endTime?: string
  createdBy: number
  createdAt: string
  updatedAt: string
}

// 表单相关类型
export interface FormField {
  prop: string
  label: string
  type: 'input' | 'select' | 'date' | 'textarea' | 'upload' | 'switch'
  required?: boolean
  options?: Array<{ label: string; value: any }>
  placeholder?: string
  rules?: any[]
}

// 表格相关类型
export interface TableColumn {
  prop: string
  label: string
  width?: number
  minWidth?: number
  sortable?: boolean
  formatter?: (row: any, column: any, cellValue: any) => string
  type?: 'selection' | 'index' | 'expand'
}

// 菜单相关类型
export interface MenuItem {
  id: string
  title: string
  icon?: string
  path?: string
  children?: MenuItem[]
  permission?: string
  hidden?: boolean
}

// 路由元信息类型
export interface RouteMeta {
  title: string
  icon?: string
  permission?: string
  hidden?: boolean
  keepAlive?: boolean
  breadcrumb?: boolean
  [key: string]: any
}