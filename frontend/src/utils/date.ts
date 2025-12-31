/**
 * 日期时间工具函数
 */

/**
 * 格式化日期时间
 * @param dateString 日期字符串
 * @param format 格式化模式
 * @returns 格式化后的日期字符串
 */
export function formatDateTime(dateString: string | Date, format: string = 'YYYY-MM-DD HH:mm:ss'): string {
  if (!dateString) return ''
  
  const date = typeof dateString === 'string' ? new Date(dateString) : dateString
  
  if (isNaN(date.getTime())) return ''
  
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  const seconds = String(date.getSeconds()).padStart(2, '0')
  
  return format
    .replace('YYYY', String(year))
    .replace('MM', month)
    .replace('DD', day)
    .replace('HH', hours)
    .replace('mm', minutes)
    .replace('ss', seconds)
}

/**
 * 格式化日期
 * @param dateString 日期字符串
 * @returns 格式化后的日期字符串
 */
export function formatDate(dateString: string | Date): string {
  return formatDateTime(dateString, 'YYYY-MM-DD')
}

/**
 * 格式化时间
 * @param dateString 日期字符串
 * @returns 格式化后的时间字符串
 */
export function formatTime(dateString: string | Date): string {
  return formatDateTime(dateString, 'HH:mm:ss')
}

/**
 * 相对时间格式化
 * @param dateString 日期字符串
 * @returns 相对时间字符串
 */
export function formatRelativeTime(dateString: string | Date): string {
  if (!dateString) return ''
  
  const date = typeof dateString === 'string' ? new Date(dateString) : dateString
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  
  const minute = 60 * 1000
  const hour = 60 * minute
  const day = 24 * hour
  const week = 7 * day
  const month = 30 * day
  const year = 365 * day
  
  if (diff < minute) {
    return '刚刚'
  } else if (diff < hour) {
    return `${Math.floor(diff / minute)}分钟前`
  } else if (diff < day) {
    return `${Math.floor(diff / hour)}小时前`
  } else if (diff < week) {
    return `${Math.floor(diff / day)}天前`
  } else if (diff < month) {
    return `${Math.floor(diff / week)}周前`
  } else if (diff < year) {
    return `${Math.floor(diff / month)}个月前`
  } else {
    return `${Math.floor(diff / year)}年前`
  }
}

/**
 * 检查日期是否为今天
 * @param dateString 日期字符串
 * @returns 是否为今天
 */
export function isToday(dateString: string | Date): boolean {
  if (!dateString) return false
  
  const date = typeof dateString === 'string' ? new Date(dateString) : dateString
  const today = new Date()
  
  return date.getFullYear() === today.getFullYear() &&
         date.getMonth() === today.getMonth() &&
         date.getDate() === today.getDate()
}

/**
 * 检查日期是否为昨天
 * @param dateString 日期字符串
 * @returns 是否为昨天
 */
export function isYesterday(dateString: string | Date): boolean {
  if (!dateString) return false
  
  const date = typeof dateString === 'string' ? new Date(dateString) : dateString
  const yesterday = new Date()
  yesterday.setDate(yesterday.getDate() - 1)
  
  return date.getFullYear() === yesterday.getFullYear() &&
         date.getMonth() === yesterday.getMonth() &&
         date.getDate() === yesterday.getDate()
}

/**
 * 获取日期范围
 * @param days 天数
 * @returns 日期范围
 */
export function getDateRange(days: number): { start: Date, end: Date } {
  const end = new Date()
  const start = new Date()
  start.setDate(start.getDate() - days)
  
  return { start, end }
}

/**
 * 格式化文件大小
 * @param bytes 字节数
 * @returns 格式化后的文件大小
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B'
  
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}