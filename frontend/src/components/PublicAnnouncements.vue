<template>
  <div class="public-announcements-wrapper">


    <!-- 公告弹窗 -->
    <template v-for="(announcement, index) in visibleAnnouncements" :key="announcement.uniqueKey || `dialog-${announcement.id}-${index}`">
      <el-dialog
        v-model="announcement.visible"
        :title="announcement.title"
        width="500px"
        :modal="true"
        :close-on-click-modal="false"
        :show-close="true"
        :z-index="3000 + index"
        :append-to-body="true"
        destroy-on-close
        @close="handleAnnouncementClose(announcement)"
      >
        <div style="padding: 20px 0;">
          <div style="margin-bottom: 16px;">
            <el-tag :type="getAnnouncementTypeTag(announcement.type)" size="small">
              {{ getAnnouncementTypeText(announcement.type) }}
            </el-tag>
            <el-tag v-if="announcement.is_sticky" type="warning" size="small" style="margin-left: 8px;">
              置顶
            </el-tag>
          </div>
          
          <div style="line-height: 1.6; margin-bottom: 16px;">
            {{ announcement.content }}
          </div>
          
          <div style="font-size: 12px; color: #999;">
            发布时间: {{ formatTime(announcement.created_at) }}
          </div>
        </div>
        
        <template #footer>
          <div style="text-align: right;">
            <el-button @click="handleAnnouncementClose(announcement)">知道了</el-button>
            <el-button @click="dismissAnnouncement(announcement.id)" type="info">不再显示</el-button>
          </div>
        </template>
      </el-dialog>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Warning,
  Close as CircleClose,
  Tools,
  InfoFilled,
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
  visible?: boolean
  uniqueKey?: string
}

const announcements = ref<Announcement[]>([])
const visibleAnnouncements = ref<Announcement[]>([])
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
    
    if (response.success && response.data?.announcements) {
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
      
      if (announcements.value.length > 0) {
        // 清空现有的可见公告
        visibleAnnouncements.value = []
        
        // 等待Vue响应式更新
        await nextTick()
        
        // 创建可见公告列表
        const newVisibleAnnouncements = announcements.value.map((announcement, index) => {
          // 记录查看次数
          recordView(announcement.id)
          
          return {
            ...announcement,
            visible: true,
            uniqueKey: `announcement-${announcement.id}-${Date.now()}-${index}`
          }
        })
        
        // 一次性设置所有可见公告
        visibleAnnouncements.value = newVisibleAnnouncements
        
        // 强制触发响应式更新
        await nextTick()
      }
    }
  } catch (error) {
    console.error('Failed to fetch public announcements:', error)
  }
}

// 处理公告弹窗关闭
const handleAnnouncementClose = (announcement: Announcement) => {
  console.log('Closing announcement:', announcement.title)
  announcement.visible = false
  
  // 从可见列表中移除
  setTimeout(() => {
    const index = visibleAnnouncements.value.findIndex(va => va.id === announcement.id)
    if (index > -1) {
      visibleAnnouncements.value.splice(index, 1)
      console.log('Announcement removed from visible list')
    }
  }, 300) // 等待关闭动画完成
}

// 获取弹窗样式类
const getDialogClass = (type: string) => {
  return `announcement-dialog-${type}`
}

// 获取公告类型标签类型
const getAnnouncementTypeTag = (type: string) => {
  const typeMap: Record<string, string> = {
    'info': 'info',
    'warning': 'warning', 
    'error': 'danger',
    'maintenance': 'primary'
  }
  return typeMap[type] || 'info'
}

// 获取公告类型文本
const getAnnouncementTypeText = (type: string) => {
  const textMap: Record<string, string> = {
    'info': '信息',
    'warning': '警告',
    'error': '错误', 
    'maintenance': '维护'
  }
  return textMap[type] || type
}

// 忽略公告
const dismissAnnouncement = (id: number) => {
  console.log('Dismissing announcement:', id)
  
  // 关闭弹窗
  const visibleAnnouncement = visibleAnnouncements.value.find(va => va.id === id)
  if (visibleAnnouncement) {
    visibleAnnouncement.visible = false
  }
  
  // 从列表中移除
  announcements.value = announcements.value.filter(a => a.id !== id)
  
  // 延迟移除以等待关闭动画
  setTimeout(() => {
    visibleAnnouncements.value = visibleAnnouncements.value.filter(va => va.id !== id)
  }, 300)
  
  // 保存到忽略列表
  const dismissed = getDismissedIds()
  dismissed.push(id)
  saveDismissedIds(dismissed)
  
  ElMessage.success('公告已忽略')
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
  
  // 延迟一点时间确保应用完全初始化后再获取公告
  setTimeout(() => {
    fetchPublicAnnouncements()
  }, 1000)
  
  // 启动自动刷新
  startAutoRefresh()
  
  // 监听刷新事件
  window.addEventListener('refreshAnnouncements', fetchPublicAnnouncements)
})

onUnmounted(() => {
  stopAutoRefresh()
  window.removeEventListener('refreshAnnouncements', fetchPublicAnnouncements)
})

// 测试弹窗显示
const showTestDialog = async () => {
  console.log('Showing test dialog...')
  
  // 创建测试公告
  const testAnnouncement: Announcement = {
    id: 9999,
    title: '测试公告弹窗',
    content: '这是一个测试公告，用来验证弹窗功能是否正常工作。如果你能看到这个弹窗，说明公告系统运行正常。',
    type: 'info',
    priority: 1,
    is_active: true,
    is_sticky: false,
    start_time: new Date().toISOString(),
    end_time: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    view_count: 0,
    created_at: new Date().toISOString(),
    visible: true,
    uniqueKey: `test-announcement-${Date.now()}`
  }
  
  // 清空现有公告
  visibleAnnouncements.value = []
  
  // 等待DOM更新
  await nextTick()
  
  // 添加测试公告
  visibleAnnouncements.value.push(testAnnouncement)
  
  console.log('Test announcement added:', testAnnouncement)
  console.log('Visible announcements:', visibleAnnouncements.value)
}

// 暴露方法供外部调用
defineExpose({
  refresh: fetchPublicAnnouncements,
  showTest: showTestDialog
})
</script>

<style scoped>
.public-announcements {
  position: fixed;
  top: 60px;
  left: 0;
  right: 0;
  z-index: 2000;
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

<style scoped>
/* 公告弹窗样式 */
:deep(.announcement-dialog) {
  border-radius: 12px;
  overflow: hidden;
}

:deep(.announcement-dialog-info .el-dialog__header) {
  background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
  border-bottom: 3px solid #2196f3;
}

:deep(.announcement-dialog-warning .el-dialog__header) {
  background: linear-gradient(135deg, #fff8e1 0%, #ffecb3 100%);
  border-bottom: 3px solid #ff9800;
}

:deep(.announcement-dialog-error .el-dialog__header) {
  background: linear-gradient(135deg, #ffebee 0%, #ffcdd2 100%);
  border-bottom: 3px solid #f44336;
}

:deep(.announcement-dialog-maintenance .el-dialog__header) {
  background: linear-gradient(135deg, #f3e5f5 0%, #e1bee7 100%);
  border-bottom: 3px solid #9c27b0;
}

.announcement-dialog-content {
  padding: 20px 0;
}

.announcement-header {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 20px;
}

.announcement-icon-wrapper {
  flex-shrink: 0;
}

.announcement-icon {
  font-size: 32px;
  padding: 8px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.8);
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

.announcement-meta {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.announcement-time {
  font-size: 12px;
  color: #999;
  margin-left: 8px;
}

.announcement-content {
  margin: 20px 0;
  line-height: 1.6;
  color: #333;
  font-size: 14px;
}

.announcement-content p {
  margin: 0;
}

.announcement-footer {
  margin-top: 20px;
  padding-top: 16px;
  border-top: 1px solid #eee;
}

.announcement-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  color: #666;
}

.expire-info,
.view-count {
  display: flex;
  align-items: center;
  gap: 4px;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

/* 弹窗动画 */
:deep(.el-dialog) {
  animation: dialogFadeIn 0.3s ease-out;
}

@keyframes dialogFadeIn {
  from {
    opacity: 0;
    transform: scale(0.9) translateY(-20px);
  }
  to {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

/* 响应式设计 */
@media (max-width: 768px) {
  :deep(.announcement-dialog) {
    width: 90% !important;
    margin: 0 5%;
  }
  
  .announcement-header {
    flex-direction: column;
    align-items: center;
    text-align: center;
    gap: 12px;
  }
  
  .announcement-info {
    flex-direction: column;
    gap: 8px;
    align-items: flex-start;
  }
}
</style>