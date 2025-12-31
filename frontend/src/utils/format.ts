// 格式化工具函数

/**
 * 格式化时间
 * @param time 时间字符串或Date对象
 * @returns 格式化后的时间字符串
 */
export function formatTime(time: string | Date | null | undefined): string {
  if (!time) return '-'
  
  const date = typeof time === 'string' ? new Date(time) : time
  
  if (isNaN(date.getTime())) return '-'
  
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  
  // 小于1分钟
  if (diff < 60 * 1000) {
    return '刚刚'
  }
  
  // 小于1小时
  if (diff < 60 * 60 * 1000) {
    const minutes = Math.floor(diff / (60 * 1000))
    return `${minutes}分钟前`
  }
  
  // 小于1天
  if (diff < 24 * 60 * 60 * 1000) {
    const hours = Math.floor(diff / (60 * 60 * 1000))
    return `${hours}小时前`
  }
  
  // 小于7天
  if (diff < 7 * 24 * 60 * 60 * 1000) {
    const days = Math.floor(diff / (24 * 60 * 60 * 1000))
    return `${days}天前`
  }
  
  // 超过7天，显示具体日期
  return date.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

/**
 * 格式化日期时间
 * @param time 时间字符串或Date对象
 * @returns 格式化后的日期时间字符串
 */
export function formatDateTime(time: string | Date | null | undefined): string {
  if (!time) return '-'
  
  const date = typeof time === 'string' ? new Date(time) : time
  
  if (isNaN(date.getTime())) return '-'
  
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
}

/**
 * 格式化日期
 * @param time 时间字符串或Date对象
 * @returns 格式化后的日期字符串
 */
export function formatDate(time: string | Date | null | undefined): string {
  if (!time) return '-'
  
  const date = typeof time === 'string' ? new Date(time) : time
  
  if (isNaN(date.getTime())) return '-'
  
  return date.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  })
}

/**
 * 格式化文件大小
 * @param bytes 字节数
 * @returns 格式化后的文件大小字符串
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B'
  
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

/**
 * 格式化数字
 * @param num 数字
 * @param precision 精度
 * @returns 格式化后的数字字符串
 */
export function formatNumber(num: number, precision: number = 2): string {
  if (isNaN(num)) return '0'
  
  if (num >= 1000000) {
    return (num / 1000000).toFixed(precision) + 'M'
  } else if (num >= 1000) {
    return (num / 1000).toFixed(precision) + 'K'
  }
  
  return num.toFixed(precision)
}

/**
 * 格式化百分比
 * @param value 数值 (0-1)
 * @param precision 精度
 * @returns 格式化后的百分比字符串
 */
export function formatPercentage(value: number, precision: number = 1): string {
  if (isNaN(value)) return '0%'
  return (value * 100).toFixed(precision) + '%'
}

/**
 * 格式化货币
 * @param amount 金额
 * @param currency 货币符号
 * @returns 格式化后的货币字符串
 */
export function formatCurrency(amount: number, currency: string = '¥'): string {
  if (isNaN(amount)) return `${currency}0.00`
  return `${currency}${amount.toFixed(2)}`
}

/**
 * 截断文本
 * @param text 文本
 * @param maxLength 最大长度
 * @param suffix 后缀
 * @returns 截断后的文本
 */
export function truncateText(text: string, maxLength: number, suffix: string = '...'): string {
  if (!text || text.length <= maxLength) return text
  return text.substring(0, maxLength) + suffix
}

/**
 * 格式化时长（秒）
 * @param seconds 秒数
 * @returns 格式化后的时长字符串
 */
export function formatDuration(seconds: number): string {
  if (isNaN(seconds) || seconds < 0) return '0:00'
  
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const secs = Math.floor(seconds % 60)
  
  if (hours > 0) {
    return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  } else {
    return `${minutes}:${secs.toString().padStart(2, '0')}`
  }
}