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
  roles: Role[]
  permissions?: Permission[]
  is_active: boolean
  last_login?: string
  created_at?: string
  updated_at?: string
}

export interface Role {
  id: number
  name: string
  display_name: string
  description?: string
  permissions?: Permission[]
}

export interface Permission {
  id: number
  name: string
  displayName: string
  description?: string
  resource: string
  action: string
  scope: string
  parentId?: number
  children?: Permission[]
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

// AI相关类型定义
export interface AIConfig {
  id: number
  name: string
  provider: string
  model: string
  api_key: string
  api_endpoint?: string
  max_tokens: number
  temperature: number
  timeout: number
  is_default: boolean
  status: 'active' | 'inactive'
  description?: string
  created_at: string
  updated_at: string
}

export interface AIChatSession {
  id: number
  title: string
  user_id: number
  config_id: number
  message_count: number
  created_at: string
  updated_at: string
}

export interface AIChatMessage {
  id: number
  session_id: number
  role: 'user' | 'assistant'
  content: string
  created_at: string
}

export interface AITask {
  id: number
  type: 'chat' | 'optimize' | 'speech-to-text'
  status: 'pending' | 'processing' | 'completed' | 'failed'
  user_id: number
  config_id: number
  input_data: any
  output_data?: any
  error_message?: string
  created_at: string
  updated_at: string
}

export interface AIUsageStats {
  id: number
  user_id: number
  config_id: number
  task_type: string
  date: string
  request_count: number
  success_count: number
  tokens_used: number
  total_duration: number
  created_at: string
}

export interface AIOptimizeRequest {
  content: {
    text: string
    type: string
  }
  goals: string[]
  config_id: number
}

export interface AISpeechToTextRequest {
  audio: File
  language?: string
  config_id: number
}

export interface AISpeechToTextResponse {
  text: string
  language: string
  confidence: number
  duration: number
  segments?: Array<{
    start: number
    end: number
    text: string
  }>
}

// 工单相关类型
export interface Ticket {
  id: number
  title: string
  description: string
  type: 'bug' | 'feature' | 'support' | 'change'
  status: 'open' | 'progress' | 'pending' | 'resolved' | 'closed' | 'rejected'
  priority: 'low' | 'normal' | 'high' | 'critical'
  creator_id: number
  assignee_id?: number
  category?: string
  tags?: string[]
  due_date?: string
  resolved_at?: string
  closed_at?: string
  created_at: string
  updated_at: string
  creator?: User
  assignee?: User
  comments?: TicketComment[]
  attachments?: TicketAttachment[]
  history?: TicketHistory[]
}

export interface TicketComment {
  id: number
  ticket_id: number
  user_id: number
  content: string
  is_public: boolean
  created_at: string
  updated_at: string
  user?: User
}

export interface TicketAttachment {
  id: number
  ticket_id: number
  file_name: string
  file_size: number
  content_type: string
  file_path?: string
  uploaded_by: number
  created_at: string
  uploader?: User
}

export interface TicketHistory {
  id: number
  ticket_id: number
  user_id: number
  action: string
  description: string
  created_at: string
  user?: User
}

export interface TicketStatistics {
  total: number
  open: number
  progress: number
  pending: number
  resolved: number
  closed: number
  rejected: number
  status: Record<string, number>
  type: Record<string, number>
  priority: Record<string, number>
}