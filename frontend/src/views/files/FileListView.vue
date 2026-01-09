<template>
  <div class="file-list-container">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>文件管理</span>
          <el-button type="primary" @click="handleUpload">
            上传文件
          </el-button>
        </div>
      </template>

      <!-- 文件列表 -->
      <el-table
        v-loading="loading"
        :data="fileList"
        style="width: 100%"
      >
        <el-table-column prop="original_name" label="文件名" />
        <el-table-column prop="size" label="大小" />
        <el-table-column prop="mime_type" label="类型" />
        <el-table-column prop="created_at" label="上传时间" />
        <el-table-column label="操作">
          <template #default="{ row }">
            <el-button size="small" @click="handleDownload(row)">下载</el-button>
            <el-button size="small" type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'

// 定义文件信息接口
interface FileInfo {
  id: number
  original_name: string
  filename: string
  size: number
  mime_type: string
  created_at: string
}

// 响应式数据
const loading = ref(false)
const fileList = ref<FileInfo[]>([])

// 获取文件列表
const getFileList = async () => {
  try {
    loading.value = true
    // 模拟数据
    fileList.value = []
  } catch (error) {
    console.error('获取文件列表失败:', error)
    ElMessage.error('获取文件列表失败')
  } finally {
    loading.value = false
  }
}

// 上传处理
const handleUpload = () => {
  ElMessage.info('上传功能开发中')
}

// 下载处理
const handleDownload = async (file: FileInfo) => {
  ElMessage.info('下载功能开发中')
}

// 删除处理
const handleDelete = async (file: FileInfo) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除文件 "${file.original_name}" 吗？`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    ElMessage.success('文件删除成功')
    getFileList()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除文件失败:', error)
      ElMessage.error('删除文件失败')
    }
  }
}

// 生命周期
onMounted(() => {
  getFileList()
})
</script>

<style scoped>
.file-list-container {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>