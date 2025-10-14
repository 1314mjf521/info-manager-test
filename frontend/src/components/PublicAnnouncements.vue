<template>
  <div v-if="announcements.length > 0" class="public-announcements">
    <!-- 公告横幅 -->
    <div v-for="announcement in announcements" :key="announcement.id" class="announcement-banner" :class="getBannerClass(announcement)">
      <div class="announcement-content">
        <div class="announcement-header">
          <div class="announcement-title">
            <el-icon class="announcement-icon" :class="getIconClass(announcement.type)">
              <Warning v-if="announcement.type === 'warning'" />
              <CircleClose v-else-if="announcement.type === 'error'" />
              <Tools v-else-if="announcement.type === 'maintenance'" />
              <InfoFilled v-else />
            </el-icon>
            <span class="title-text">{{ announcement.title }}</span>
            <el-tag v-if="announcement.is_sticky" type="warning" size="small" class="sticky-tag">置顶</el-tag>
          </div>
          <div class="announcement-actions">
            <el-button size="small" text @click="toggleExpand(announcement.id)">
              {{ expandedIds.includes(announcement.id) ? '收起' : '详情' }}
            </el-button>
            <el-button size="small" text @click="dismissAnnouncement(announcement.id)">
              <el-icon><Close /></el-icon>
            </el-button>
          </div>
        </div>
        
        <!-- 展开的内容 -->
        <div v-if="expandedIds.includes(announcement.id)" class="announcement-details">
          <div class="announcement-text">{{ announcement.content }}</div>
          <div class="announcement-meta">
            <span class="meta-item">
              <el-icon><Clock /></el-icon>
              发布时间: {{ formatTime(announcement.created_at) }}
            </span>
            <span v-if="announcement.end_time" class="meta-item">
              <el-icon><Timer /></el-icon>
              有效期至: {{ formatTime(announcement.end_time) }}
            </span>
            <span class="meta-item">
              <el-icon><View /></el-icon>
              查看次数: {{ announcement.view_count || 0 }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  Warning,
  CircleClose,
  Tools,
  InfoFilled,
  Close,
  Clock,
  Timer,
  View
} from '@element-plus/icons-vue'
import { http } from '@/utils/request'

interface Announcement {
  id: number
  title: string
  content: string
  type: 'info' | 'warning' | 'error' | 'maintenance'
  priority: number
  is_active: boolean
  is_sticky: boolean
  start_time: string
  end_time: string
  view_count: number
  created_at: string
}

const announcements = ref<Announcement[]>([])
const expandedIds = ref<number[]>([])
const dismissedIds = ref<number[]>([])

// 从localStorage获取已忽略的公告ID
const getDismissedIds = (): number[] => {
  try {
    const stored = localStorage.getItem('dismissed_announcements')
    return stored ? JSON.parse(stored) : []
  } catch {
    return []
  }
}

// 保存已忽略的公告ID到localStorage
const saveDismissedIds = (ids: number[]) => {
  try {
    localStorage.setItem('dismissed_announcements', JSON.stringify(ids))
  } catch (error) {
    console.error('Failed to save dismissed announcements:', error)
  }
}

// 获取公共公告
const fetchPublicAnnouncements = async () => {
  try {
    const response = await http.get('/announcements/public', {
      params: {
        page: 1,
        page_size: 10
      }
    })
    
    if (response.data?.announcements) {
      // 过滤掉已忽略的公告
      const dismissed = getDismissedIds()
      announcements.value = response.data.announcements.filter(
        (announcement: Announcement) => !dismissed.includes(announcement.id)
      )
      
      // 按优先级和置顶状态排序
      announcements.value.sort((a, b) => {
        if (a.is_sticky !== b.is_sticky) {
          return b.is_sticky ? 1 : -1
        }
        return b.priority - a.priority
      })
    }
  } catch (error) {
    console.error('Failed to fetch public announcements:', error)
  }
}

// 切换展开状态
const toggleExpand = (id: number) => {
  const index = expandedIds.value.indexOf(id)
  if (index > -1) {
    expandedIds.value.splice(index, 1)
  } else {
    expandedIds.value.push(id)
    // 记录查看次数
    recordView(id)
  }
}

// 忽略公告
const dismissAnnouncement = (id: number) => {
  announcements.value = announcements.value.filter(a => a.id !== id)
  const dismissed = getDismissedIds()
  dismissed.push(id)
  saveDismissedIds(dismissed)
}

// 记录查看次数
const recordView = async (id: number) => {
  try {
    await http.post(`/announcements/${id}/view`)
  } catch (error) {
    console.error('Failed to record view:', error)
  }
}

// 获取横幅样式类
const getBannerClass = (announcement: Announcement) => {
  return `banner-${announcement.type}`
}

// 获取图标样式类
const getIconClass = (type: string) => {
  return `icon-${type}`
}

// 格式化时间
const formatTime = (timeStr: string) => {
  if (!timeStr) return ''
  try {
    return new Date(timeStr).toLocaleString('zh-CN')
  } catch {
    return timeStr
  }
}

// 定时刷新公告
let refreshTimer: NodeJS.Timeout | null = null

const startAutoRefresh = () => {
  refreshTimer = setInterval(() => {
    fetchPublicAnnouncements()
  }, 5 * 60 * 1000) // 每5分钟刷新一次
}

const stopAutoRefresh = () => {
  if (refreshTimer) {
    clearInterval(refreshTimer)
    refreshTimer = null
  }
}

// 生命周期
onMounted(() => {
  dismissedIds.value = getDismissedIds()
  fetchPublicAnnouncements()
  startAutoRefresh()
})

onUnmounted(() => {
  stopAutoRefresh()
})

// 暴露方法供外部调用
defineExpose({
  refresh: fetchPublicAnnouncements
})
</script>

<style scoped>
.public-announcements {
  position: fixed;
  top: 60px;
  left: 0;
  right: 0;
  z-index: 1000;
  pointer-events: none;
}

.announcement-banner {
  margin: 4px 8px;
  border-radius: 6px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  pointer-events: auto;
  animation: slideDown 0.3s ease-out;
}

@keyframes slideDown {
  from {
    transform: translateY(-100%);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.banner-info {
  background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
  border-left: 4px solid #2196f3;
}

.banner-warning {
  background: linear-gradient(135deg, #fff8e1 0%, #ffecb3 100%);
  border-left: 4px solid #ff9800;
}

.banner-error {
  background: linear-gradient(135deg, #ffebee 0%, #ffcdd2 100%);
  border-left: 4px solid #f44336;
}

.banner-maintenance {
  background: linear-gradient(135deg, #f3e5f5 0%, #e1bee7 100%);
  border-left: 4px solid #9c27b0;
}

.announcement-content {
  padding: 12px 16px;
}

.announcement-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.announcement-title {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: 1;
}

.announcement-icon {
  font-size: 18px;
}

.icon-info {
  color: #2196f3;
}

.icon-warning {
  color: #ff9800;
}

.icon-error {
  color: #f44336;
}

.icon-maintenance {
  color: #9c27b0;
}

.title-text {
  font-weight: 600;
  font-size: 14px;
  color: #333;
}

.sticky-tag {
  margin-left: 8px;
}

.announcement-actions {
  display: flex;
  align-items: center;
  gap: 4px;
}

.announcement-details {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid rgba(0, 0, 0, 0.1);
}

.announcement-text {
  font-size: 13px;
  line-height: 1.5;
  color: #666;
  margin-bottom: 8px;
  white-space: pre-wrap;
}

.announcement-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  font-size: 12px;
  color: #999;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 4px;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .public-announcements {
    top: 50px;
  }
  
  .announcement-banner {
    margin: 2px 4px;
  }
  
  .announcement-content {
    padding: 8px 12px;
  }
  
  .announcement-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
  
  .announcement-actions {
    align-self: flex-end;
  }
  
  .announcement-meta {
    flex-direction: column;
    gap: 4px;
  }
}
</style>