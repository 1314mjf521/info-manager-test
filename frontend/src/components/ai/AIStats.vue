<template>
  <div class="ai-stats">
    <!-- 统计概览 -->
    <div class="stats-overview">
      <el-row :gutter="20">
        <el-col :span="6">
          <el-card class="stat-card">
            <el-statistic
              title="总使用次数"
              :value="overviewStats.totalUsage"
              suffix="次"
            >
              <template #prefix>
                <el-icon style="color: #409eff"><DataAnalysis /></el-icon>
              </template>
            </el-statistic>
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card class="stat-card">
            <el-statistic
              title="今日使用"
              :value="overviewStats.todayUsage"
              suffix="次"
            >
              <template #prefix>
                <el-icon style="color: #67c23a"><Calendar /></el-icon>
              </template>
            </el-statistic>
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card class="stat-card">
            <el-statistic
              title="消耗Token"
              :value="overviewStats.totalTokens"
              suffix="个"
            >
              <template #prefix>
                <el-icon style="color: #e6a23c"><Coin /></el-icon>
              </template>
            </el-statistic>
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card class="stat-card">
            <el-statistic
              title="平均响应时间"
              :value="overviewStats.avgResponseTime"
              suffix="ms"
            >
              <template #prefix>
                <el-icon style="color: #f56c6c"><Timer /></el-icon>
              </template>
            </el-statistic>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- 筛选工具栏 -->
    <div class="filter-toolbar">
      <el-form :model="filters" inline>
        <el-form-item label="时间范围">
          <el-date-picker
            v-model="filters.dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
            @change="fetchStats"
          />
        </el-form-item>
        <el-form-item label="功能类型">
          <el-select v-model="filters.taskType" clearable @change="fetchStats">
            <el-option label="全部" value="" />
            <el-option label="AI聊天" value="chat" />
            <el-option label="内容优化" value="optimize" />
            <el-option label="语音识别" value="speech-to-text" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchStats">
            <el-icon><Search /></el-icon>
            查询
          </el-button>
          <el-button @click="resetFilters">
            <el-icon><Refresh /></el-icon>
            重置
          </el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 图表区域 -->
    <div class="charts-area">
      <el-row :gutter="20">
        <!-- 使用趋势图 -->
        <el-col :span="12">
          <el-card class="chart-card">
            <template #header>
              <span>使用趋势</span>
            </template>
            <div ref="usageTrendChart" class="chart-container"></div>
          </el-card>
        </el-col>

        <!-- 功能分布图 -->
        <el-col :span="12">
          <el-card class="chart-card">
            <template #header>
              <span>功能使用分布</span>
            </template>
            <div ref="featureDistChart" class="chart-container"></div>
          </el-card>
        </el-col>
      </el-row>

      <el-row :gutter="20" style="margin-top: 20px">
        <!-- Token消耗图 -->
        <el-col :span="12">
          <el-card class="chart-card">
            <template #header>
              <span>Token消耗统计</span>
            </template>
            <div ref="tokenUsageChart" class="chart-container"></div>
          </el-card>
        </el-col>

        <!-- 响应时间分布 -->
        <el-col :span="12">
          <el-card class="chart-card">
            <template #header>
              <span>响应时间分布</span>
            </template>
            <div ref="responseTimeChart" class="chart-container"></div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- 详细统计表格 -->
    <el-card class="table-card">
      <template #header>
        <div class="card-header">
          <span>详细统计</span>
          <div class="header-actions">
            <el-button size="small" @click="exportStats">
              <el-icon><Download /></el-icon>
              导出数据
            </el-button>
          </div>
        </div>
      </template>

      <el-table :data="detailStats" v-loading="loading" stripe>
        <el-table-column prop="date" label="日期" width="120" />
        <el-table-column prop="task_type" label="功能类型" width="120">
          <template #default="{ row }">
            <el-tag :type="getTaskTypeTag(row.task_type)">
              {{ getTaskTypeName(row.task_type) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="request_count" label="请求次数" width="100" />
        <el-table-column prop="success_count" label="成功次数" width="100" />
        <el-table-column prop="success_rate" label="成功率" width="100">
          <template #default="{ row }">
            {{ Math.round(row.success_rate * 100) }}%
          </template>
        </el-table-column>
        <el-table-column prop="tokens_used" label="Token消耗" width="120" />
        <el-table-column prop="avg_duration" label="平均耗时" width="120">
          <template #default="{ row }">
            {{ row.avg_duration }}ms
          </template>
        </el-table-column>
        <el-table-column prop="total_cost" label="预估费用" width="120">
          <template #default="{ row }">
            ${{ row.total_cost?.toFixed(4) || '0.0000' }}
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.pageSize"
          :total="pagination.total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="fetchStats"
          @current-change="fetchStats"
        />
      </div>
    </el-card>

    <!-- AI配置使用统计 -->
    <el-card class="config-stats-card">
      <template #header>
        <span>AI配置使用统计</span>
      </template>

      <el-table :data="configStats" stripe>
        <el-table-column prop="config_name" label="配置名称" width="200" />
        <el-table-column prop="provider" label="提供商" width="120">
          <template #default="{ row }">
            <el-tag :type="getProviderTag(row.provider)">
              {{ getProviderName(row.provider) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="model" label="模型" width="150" />
        <el-table-column prop="usage_count" label="使用次数" width="100" />
        <el-table-column prop="success_rate" label="成功率" width="100">
          <template #default="{ row }">
            {{ Math.round(row.success_rate * 100) }}%
          </template>
        </el-table-column>
        <el-table-column prop="avg_response_time" label="平均响应时间" width="140">
          <template #default="{ row }">
            {{ row.avg_response_time }}ms
          </template>
        </el-table-column>
        <el-table-column prop="total_tokens" label="Token消耗" width="120" />
        <el-table-column prop="last_used" label="最后使用" width="180">
          <template #default="{ row }">
            {{ formatTime(row.last_used) }}
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onUnmounted, nextTick } from 'vue'
import { ElMessage } from 'element-plus'
import {
  DataAnalysis,
  Calendar,
  Coin,
  Timer,
  Search,
  Refresh,
  Download
} from '@element-plus/icons-vue'
import { http } from '../../utils/http'
import { formatTime } from '../../utils/format'
import * as echarts from 'echarts'

// 响应式数据
const loading = ref(false)
const overviewStats = reactive({
  totalUsage: 0,
  todayUsage: 0,
  totalTokens: 0,
  avgResponseTime: 0
})

const filters = reactive({
  dateRange: [],
  taskType: ''
})

const detailStats = ref([])
const configStats = ref([])

const pagination = reactive({
  page: 1,
  pageSize: 20,
  total: 0
})

// 图表引用
const usageTrendChart = ref()
const featureDistChart = ref()
const tokenUsageChart = ref()
const responseTimeChart = ref()

// 图表实例
let usageTrendChartInstance = null
let featureDistChartInstance = null
let tokenUsageChartInstance = null
let responseTimeChartInstance = null

// 获取统计数据
const fetchStats = async () => {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      page_size: pagination.pageSize,
      task_type: filters.taskType
    }

    if (filters.dateRange && filters.dateRange.length === 2) {
      params.start_date = filters.dateRange[0]
      params.end_date = filters.dateRange[1]
    }

    const response = await http.get('/ai/stats', { params })
    
    // 更新概览统计
    Object.assign(overviewStats, response.data.overview)
    
    // 更新详细统计
    detailStats.value = response.data.details || []
    pagination.total = response.data.total || 0
    
    // 更新配置统计
    configStats.value = response.data.config_stats || []
    
    // 更新图表
    await nextTick()
    updateCharts(response.data)
  } catch (error) {
    ElMessage.error('获取统计数据失败')
  } finally {
    loading.value = false
  }
}

// 重置筛选条件
const resetFilters = () => {
  filters.dateRange = []
  filters.taskType = ''
  fetchStats()
}

// 初始化图表
const initCharts = () => {
  // 使用趋势图
  usageTrendChartInstance = echarts.init(usageTrendChart.value)
  
  // 功能分布图
  featureDistChartInstance = echarts.init(featureDistChart.value)
  
  // Token消耗图
  tokenUsageChartInstance = echarts.init(tokenUsageChart.value)
  
  // 响应时间分布图
  responseTimeChartInstance = echarts.init(responseTimeChart.value)
}

// 更新图表
const updateCharts = (data) => {
  // 使用趋势图
  if (usageTrendChartInstance && data.trend_data) {
    const option = {
      title: {
        text: '使用趋势',
        left: 'center',
        textStyle: { fontSize: 14 }
      },
      tooltip: {
        trigger: 'axis'
      },
      xAxis: {
        type: 'category',
        data: data.trend_data.dates
      },
      yAxis: {
        type: 'value'
      },
      series: [
        {
          name: '使用次数',
          type: 'line',
          data: data.trend_data.usage_counts,
          smooth: true,
          itemStyle: { color: '#409eff' }
        }
      ]
    }
    usageTrendChartInstance.setOption(option)
  }

  // 功能分布图
  if (featureDistChartInstance && data.feature_distribution) {
    const option = {
      title: {
        text: '功能使用分布',
        left: 'center',
        textStyle: { fontSize: 14 }
      },
      tooltip: {
        trigger: 'item',
        formatter: '{a} <br/>{b}: {c} ({d}%)'
      },
      series: [
        {
          name: '功能使用',
          type: 'pie',
          radius: '60%',
          data: data.feature_distribution.map(item => ({
            name: getTaskTypeName(item.task_type),
            value: item.count
          })),
          emphasis: {
            itemStyle: {
              shadowBlur: 10,
              shadowOffsetX: 0,
              shadowColor: 'rgba(0, 0, 0, 0.5)'
            }
          }
        }
      ]
    }
    featureDistChartInstance.setOption(option)
  }

  // Token消耗图
  if (tokenUsageChartInstance && data.token_usage) {
    const option = {
      title: {
        text: 'Token消耗统计',
        left: 'center',
        textStyle: { fontSize: 14 }
      },
      tooltip: {
        trigger: 'axis'
      },
      xAxis: {
        type: 'category',
        data: data.token_usage.dates
      },
      yAxis: {
        type: 'value'
      },
      series: [
        {
          name: 'Token消耗',
          type: 'bar',
          data: data.token_usage.tokens,
          itemStyle: { color: '#67c23a' }
        }
      ]
    }
    tokenUsageChartInstance.setOption(option)
  }

  // 响应时间分布图
  if (responseTimeChartInstance && data.response_time_dist) {
    const option = {
      title: {
        text: '响应时间分布',
        left: 'center',
        textStyle: { fontSize: 14 }
      },
      tooltip: {
        trigger: 'axis'
      },
      xAxis: {
        type: 'category',
        data: data.response_time_dist.ranges
      },
      yAxis: {
        type: 'value'
      },
      series: [
        {
          name: '请求数量',
          type: 'bar',
          data: data.response_time_dist.counts,
          itemStyle: { color: '#e6a23c' }
        }
      ]
    }
    responseTimeChartInstance.setOption(option)
  }
}

// 获取任务类型标签
const getTaskTypeTag = (type) => {
  const tagMap = {
    chat: 'primary',
    optimize: 'success',
    'speech-to-text': 'warning'
  }
  return tagMap[type] || 'info'
}

// 获取任务类型名称
const getTaskTypeName = (type) => {
  const nameMap = {
    chat: 'AI聊天',
    optimize: '内容优化',
    'speech-to-text': '语音识别'
  }
  return nameMap[type] || type
}

// 获取提供商标签
const getProviderTag = (provider) => {
  const tagMap = {
    openai: 'primary',
    azure: 'success',
    anthropic: 'warning',
    google: 'info'
  }
  return tagMap[provider] || 'default'
}

// 获取提供商名称
const getProviderName = (provider) => {
  const nameMap = {
    openai: 'OpenAI',
    azure: 'Azure OpenAI',
    anthropic: 'Anthropic',
    google: 'Google AI'
  }
  return nameMap[provider] || provider
}

// 导出统计数据
const exportStats = async () => {
  try {
    const params = {
      task_type: filters.taskType,
      format: 'excel'
    }

    if (filters.dateRange && filters.dateRange.length === 2) {
      params.start_date = filters.dateRange[0]
      params.end_date = filters.dateRange[1]
    }

    const response = await http.get('/ai/stats/export', {
      params,
      responseType: 'blob'
    })

    const blob = new Blob([response.data], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    })
    
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `AI使用统计_${Date.now()}.xlsx`
    a.click()
    URL.revokeObjectURL(url)

    ElMessage.success('统计数据导出成功')
  } catch (error) {
    ElMessage.error('导出统计数据失败')
  }
}

// 窗口大小变化时重新调整图表
const handleResize = () => {
  usageTrendChartInstance?.resize()
  featureDistChartInstance?.resize()
  tokenUsageChartInstance?.resize()
  responseTimeChartInstance?.resize()
}

// 生命周期
onMounted(async () => {
  // 设置默认时间范围（最近30天）
  const endDate = new Date()
  const startDate = new Date()
  startDate.setDate(startDate.getDate() - 30)
  
  filters.dateRange = [
    startDate.toISOString().split('T')[0],
    endDate.toISOString().split('T')[0]
  ]

  await fetchStats()
  await nextTick()
  initCharts()
  
  // 监听窗口大小变化
  window.addEventListener('resize', handleResize)
})

// 生命周期
onMounted(async () => {
  // 设置默认时间范围（最近30天）
  const endDate = new Date()
  const startDate = new Date()
  startDate.setDate(startDate.getDate() - 30)
  
  filters.dateRange = [
    startDate.toISOString().split('T')[0],
    endDate.toISOString().split('T')[0]
  ]

  await fetchStats()
  await nextTick()
  initCharts()
  
  // 监听窗口大小变化
  window.addEventListener('resize', handleResize)
})

// 组件卸载时清理
onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  usageTrendChartInstance?.dispose()
  featureDistChartInstance?.dispose()
  tokenUsageChartInstance?.dispose()
  responseTimeChartInstance?.dispose()
})
</script>

<style scoped>
.ai-stats {
  padding: 0;
}

.stats-overview {
  margin-bottom: 20px;
}

.stat-card {
  text-align: center;
}

.filter-toolbar {
  margin-bottom: 20px;
  padding: 16px;
  background: white;
  border-radius: 4px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.charts-area {
  margin-bottom: 20px;
}

.chart-card {
  height: 400px;
}

.chart-container {
  height: 320px;
}

.table-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  gap: 8px;
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}

.config-stats-card {
  margin-bottom: 20px;
}

:deep(.el-statistic__content) {
  font-size: 24px;
}

:deep(.el-statistic__title) {
  font-size: 14px;
  color: #606266;
}
</style>
