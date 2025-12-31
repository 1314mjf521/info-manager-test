<template>
  <div class="record-selector">
    <!-- 搜索工具栏 -->
    <div class="search-toolbar">
      <el-input
        v-model="searchKeyword"
        placeholder="搜索记录标题或内容"
        clearable
        @input="handleSearch"
      >
        <template #prefix>
          <el-icon><Search /></el-icon>
        </template>
      </el-input>
      <el-select
        v-model="selectedTypeId"
        placeholder="记录类型"
        clearable
        style="width: 200px; margin-left: 12px"
        @change="fetchRecords"
      >
        <el-option
          v-for="type in recordTypes"
          :key="type.id"
          :label="type.name"
          :value="type.id"
        />
      </el-select>
    </div>

    <!-- 记录列表 -->
    <div class="record-list">
      <el-table
        :data="records"
        v-loading="loading"
        @row-click="handleRowClick"
        highlight-current-row
        style="width: 100%"
        max-height="400px"
      >
        <el-table-column prop="title" label="标题" min-width="200">
          <template #default="{ row }">
            <div class="record-title">
              <span>{{ row.title }}</span>
              <el-tag v-if="row.type_name" size="small" type="info">
                {{ row.type_name }}
              </el-tag>
            </div>
          </template>
        </el-table-column>
        
        <el-table-column prop="content" label="内容预览" min-width="300">
          <template #default="{ row }">
            <div class="content-preview">
              {{ getContentPreview(row) }}
            </div>
          </template>
        </el-table-column>
        
        <el-table-column prop="created_at" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatTime(row.created_at) }}
          </template>
        </el-table-column>
        
        <el-table-column label="操作" width="100">
          <template #default="{ row }">
            <el-button size="small" type="primary" @click="selectRecord(row)">
              选择
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div class="pagination" v-if="pagination.total > 0">
      <el-pagination
        v-model:current-page="pagination.page"
        v-model:page-size="pagination.pageSize"
        :total="pagination.total"
        :page-sizes="[10, 20, 50]"
        layout="total, sizes, prev, pager, next"
        @size-change="fetchRecords"
        @current-change="fetchRecords"
      />
    </div>

    <!-- 空状态 -->
    <div v-if="!loading && records.length === 0" class="empty-state">
      <el-empty description="暂无记录数据" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import { http } from '@/utils/http'
import { formatTime } from '@/utils/format'

// Emits
const emit = defineEmits<{
  select: [record: any]
}>()

// 响应式数据
const records = ref([])
const recordTypes = ref([])
const loading = ref(false)
const searchKeyword = ref('')
const selectedTypeId = ref(null)

// 分页
const pagination = reactive({
  page: 1,
  pageSize: 20,
  total: 0
})

// 获取记录列表
const fetchRecords = async () => {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      page_size: pagination.pageSize,
      keyword: searchKeyword.value,
      type_id: selectedTypeId.value
    }

    // 清理空参数
    Object.keys(params).forEach(key => {
      if (params[key] === null || params[key] === undefined || params[key] === '') {
        delete params[key]
      }
    })

    const response = await http.get('/records', { params })
    records.value = response.data.records || []
    pagination.total = response.data.total || 0
  } catch (error) {
    ElMessage.error('获取记录列表失败')
  } finally {
    loading.value = false
  }
}

// 获取记录类型
const fetchRecordTypes = async () => {
  try {
    const response = await http.get('/record-types')
    recordTypes.value = response.data.types || []
  } catch (error) {
    console.error('获取记录类型失败:', error)
  }
}

// 搜索处理
const handleSearch = () => {
  pagination.page = 1
  fetchRecords()
}

// 行点击处理
const handleRowClick = (row: any) => {
  selectRecord(row)
}

// 选择记录
const selectRecord = (record: any) => {
  emit('select', record)
}

// 获取内容预览
const getContentPreview = (record: any) => {
  const content = record.content || record.description || ''
  return content.length > 100 ? content.substring(0, 100) + '...' : content
}

// 生命周期
onMounted(() => {
  fetchRecordTypes()
  fetchRecords()
})
</script>

<style scoped>
.record-selector {
  padding: 0;
}

.search-toolbar {
  display: flex;
  align-items: center;
  margin-bottom: 16px;
}

.record-list {
  margin-bottom: 16px;
}

.record-title {
  display: flex;
  align-items: center;
  gap: 8px;
}

.content-preview {
  color: #606266;
  font-size: 14px;
  line-height: 1.4;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.pagination {
  display: flex;
  justify-content: center;
}

.empty-state {
  text-align: center;
  padding: 40px 0;
}

:deep(.el-table__row) {
  cursor: pointer;
}

:deep(.el-table__row:hover) {
  background-color: #f5f7fa;
}
</style>