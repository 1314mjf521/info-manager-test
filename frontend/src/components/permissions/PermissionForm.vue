<template>
  <div class="permission-form">
    <el-form
      ref="formRef"
      :model="formData"
      :rules="formRules"
      label-width="100px"
      @submit.prevent="handleSubmit"
    >
      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item label="权限名称" prop="displayName">
            <el-input
              v-model="formData.displayName"
              placeholder="请输入权限显示名称"
              clearable
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="权限标识" prop="name">
            <el-input
              v-model="formData.name"
              placeholder="请输入权限标识（英文）"
              clearable
            />
            <div class="form-tip">
              建议格式：resource:action 或 resource:action:scope
            </div>
          </el-form-item>
        </el-col>
      </el-row>

      <el-row :gutter="20">
        <el-col :span="8">
          <el-form-item label="资源类型" prop="resource">
            <el-select
              v-model="formData.resource"
              placeholder="选择资源类型"
              filterable
              allow-create
              @change="onResourceChange"
            >
              <el-option-group label="系统模块">
                <el-option label="系统管理" value="system" />
                <el-option label="用户管理" value="users" />
                <el-option label="角色管理" value="roles" />
                <el-option label="权限管理" value="permissions" />
              </el-option-group>
              <el-option-group label="业务模块">
                <el-option label="工单管理" value="tickets" />
                <el-option label="记录管理" value="records" />
                <el-option label="文件管理" value="files" />
                <el-option label="数据导出" value="export" />
              </el-option-group>
              <el-option-group label="功能模块">
                <el-option label="通知管理" value="notifications" />
                <el-option label="审计日志" value="audit" />
                <el-option label="仪表盘" value="dashboard" />
                <el-option label="AI功能" value="ai" />
              </el-option-group>
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="操作类型" prop="action">
            <el-select
              v-model="formData.action"
              placeholder="选择操作类型"
              filterable
              allow-create
            >
              <el-option-group label="基本操作">
                <el-option label="查看" value="read" />
                <el-option label="创建" value="create" />
                <el-option label="修改" value="update" />
                <el-option label="删除" value="delete" />
              </el-option-group>
              <el-option-group label="高级操作">
                <el-option label="管理" value="manage" />
                <el-option label="配置" value="config" />
                <el-option label="审批" value="approve" />
                <el-option label="分配" value="assign" />
              </el-option-group>
              <el-option-group label="特殊操作">
                <el-option label="监控" value="monitor" />
                <el-option label="统计" value="statistics" />
                <el-option label="导出" value="export" />
                <el-option label="初始化" value="initialize" />
              </el-option-group>
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="作用域" prop="scope">
            <el-select v-model="formData.scope" placeholder="选择作用域">
              <el-option label="全部" value="all">
                <div class="scope-option">
                  <span>全部</span>
                  <el-tag size="small" type="danger">高权限</el-tag>
                </div>
              </el-option>
              <el-option label="部门" value="department">
                <div class="scope-option">
                  <span>部门</span>
                  <el-tag size="small" type="warning">中权限</el-tag>
                </div>
              </el-option>
              <el-option label="自己" value="own">
                <div class="scope-option">
                  <span>自己</span>
                  <el-tag size="small" type="success">低权限</el-tag>
                </div>
              </el-option>
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>

      <el-form-item label="父权限" prop="parentId">
        <el-tree-select
          v-model="formData.parentId"
          :data="parentOptions"
          :props="treeProps"
          placeholder="选择父权限（可选）"
          clearable
          check-strictly
          :render-after-expand="false"
          style="width: 100%"
        >
          <template #default="{ data }">
            <div class="parent-option">
              <el-icon :color="getResourceColor(data.resource)">
                <component :is="getResourceIcon(data.resource)" />
              </el-icon>
              <span>{{ data.displayName || data.name }}</span>
              <el-tag size="small" type="info">{{ data.resource }}:{{ data.action }}</el-tag>
            </div>
          </template>
        </el-tree-select>
      </el-form-item>

      <el-form-item label="权限描述" prop="description">
        <el-input
          v-model="formData.description"
          type="textarea"
          :rows="3"
          placeholder="请输入权限描述"
          maxlength="200"
          show-word-limit
        />
      </el-form-item>

      <!-- 权限预览 -->
      <el-form-item label="权限预览">
        <div class="permission-preview">
          <div class="preview-item">
            <label>完整标识：</label>
            <el-tag type="info">{{ generatePermissionName() }}</el-tag>
          </div>
          <div class="preview-item">
            <label>显示名称：</label>
            <span>{{ formData.displayName || '未设置' }}</span>
          </div>
          <div class="preview-item">
            <label>权限级别：</label>
            <el-tag :type="getScopeTagType(formData.scope)">
              {{ getScopeLabel(formData.scope) }}
            </el-tag>
          </div>
        </div>
      </el-form-item>

      <el-form-item>
        <el-button @click="handleCancel">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">
          {{ isEdit ? '更新' : '创建' }}
        </el-button>
      </el-form-item>
    </el-form>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue'
import { ElForm } from 'element-plus'
import { 
  Setting, User, Lock, Key, Document, 
  Folder, Files, Upload, Bell, Monitor, 
  DataAnalysis, ChatDotRound 
} from '@element-plus/icons-vue'

interface PermissionData {
  id?: number
  name: string
  displayName: string
  description: string
  resource: string
  action: string
  scope: string
  parentId?: number
}

interface Props {
  modelValue: PermissionData
  parentOptions: any[]
  isEdit: boolean
  submitting: boolean
}

interface Emits {
  (e: 'update:modelValue', value: PermissionData): void
  (e: 'submit', value: PermissionData): void
  (e: 'cancel'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const formRef = ref<InstanceType<typeof ElForm>>()

const formData = reactive<PermissionData>({
  name: '',
  displayName: '',
  description: '',
  resource: '',
  action: '',
  scope: 'all',
  parentId: undefined
})

const treeProps = {
  children: 'children',
  label: 'displayName',
  value: 'id'
}

// 表单验证规则
const formRules = {
  displayName: [
    { required: true, message: '请输入权限显示名称', trigger: 'blur' }
  ],
  name: [
    { required: true, message: '请输入权限标识', trigger: 'blur' },
    { pattern: /^[a-zA-Z][a-zA-Z0-9_:]*$/, message: '权限标识只能包含字母、数字、下划线和冒号，且以字母开头', trigger: 'blur' }
  ],
  resource: [
    { required: true, message: '请选择资源类型', trigger: 'change' }
  ],
  action: [
    { required: true, message: '请选择操作类型', trigger: 'change' }
  ],
  scope: [
    { required: true, message: '请选择作用域', trigger: 'change' }
  ]
}

// 监听props变化
watch(() => props.modelValue, (newVal) => {
  Object.assign(formData, newVal)
}, { immediate: true, deep: true })

// 监听formData变化
watch(formData, (newVal) => {
  emit('update:modelValue', { ...newVal })
}, { deep: true })

// 资源类型改变时自动生成权限名称
const onResourceChange = () => {
  if (formData.resource && formData.action) {
    generatePermissionName()
  }
}

// 生成权限名称
const generatePermissionName = () => {
  if (!formData.resource || !formData.action) return ''
  
  let name = `${formData.resource}:${formData.action}`
  if (formData.scope && formData.scope !== 'all') {
    name += `_${formData.scope}`
  }
  
  // 自动更新name字段
  if (!props.isEdit || !formData.name) {
    formData.name = name
  }
  
  return name
}

// 获取资源图标
const getResourceIcon = (resource: string) => {
  const iconMap: Record<string, any> = {
    'system': Setting,
    'users': User,
    'roles': Lock,
    'permissions': Key,
    'tickets': Document,
    'records': Folder,
    'files': Files,
    'export': Upload,
    'notifications': Bell,
    'audit': Monitor,
    'dashboard': DataAnalysis,
    'ai': ChatDotRound
  }
  return iconMap[resource] || Document
}

// 获取资源颜色
const getResourceColor = (resource: string) => {
  const colorMap: Record<string, string> = {
    'system': '#f56c6c',
    'users': '#409eff',
    'roles': '#67c23a',
    'permissions': '#e6a23c',
    'tickets': '#909399',
    'records': '#409eff',
    'files': '#67c23a',
    'export': '#e6a23c',
    'notifications': '#f56c6c',
    'audit': '#909399',
    'dashboard': '#409eff',
    'ai': '#67c23a'
  }
  return colorMap[resource] || '#909399'
}

// 获取作用域标签类型
const getScopeTagType = (scope: string) => {
  const typeMap: Record<string, string> = {
    'all': 'danger',
    'department': 'warning',
    'own': 'success'
  }
  return typeMap[scope] || 'info'
}

// 获取作用域标签文本
const getScopeLabel = (scope: string) => {
  const labelMap: Record<string, string> = {
    'all': '全部权限',
    'department': '部门权限',
    'own': '个人权限'
  }
  return labelMap[scope] || scope
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return
  
  try {
    await formRef.value.validate()
    emit('submit', { ...formData })
  } catch (error) {
    console.error('表单验证失败:', error)
  }
}

// 取消操作
const handleCancel = () => {
  emit('cancel')
}
</script>

<style scoped>
.permission-form {
  padding: 20px;
}

.form-tip {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
}

.scope-option {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}

.parent-option {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
}

.permission-preview {
  background: #f5f7fa;
  padding: 16px;
  border-radius: 6px;
  border: 1px solid #e4e7ed;
}

.preview-item {
  display: flex;
  align-items: center;
  margin-bottom: 8px;
}

.preview-item:last-child {
  margin-bottom: 0;
}

.preview-item label {
  font-weight: 500;
  color: #606266;
  margin-right: 8px;
  min-width: 80px;
}
</style>