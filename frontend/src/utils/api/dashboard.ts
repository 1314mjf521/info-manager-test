import { http } from '../request'
import { API_ENDPOINTS } from '../../config/api'

// 仪表盘统计数据类型
export interface DashboardStats {
  records: number
  files: number
  users: number
  today_records: number
}

// 最近记录类型
export interface RecentRecord {
  id: number
  title: string
  type: string
  created_at: string
  creator: string
}

// 系统信息类型
export interface SystemInfo {
  uptime: string
  db_status: string
  version: string
}

// 仪表盘API
export const dashboardApi = {
  // 获取仪表盘统计数据
  async getStats(): Promise<DashboardStats> {
    const response = await http.get(API_ENDPOINTS.DASHBOARD.STATS)
    return response.data
  },

  // 获取最近记录
  async getRecentRecords(): Promise<RecentRecord[]> {
    const response = await http.get(API_ENDPOINTS.DASHBOARD.RECENT_RECORDS)
    return response.data
  },

  // 获取系统信息
  async getSystemInfo(): Promise<SystemInfo> {
    const response = await http.get(API_ENDPOINTS.DASHBOARD.SYSTEM_INFO)
    return response.data
  }
}