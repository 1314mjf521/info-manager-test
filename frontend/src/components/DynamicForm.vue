<template>
  <div class="dynamic-form">
    <el-form-item
      v-for="field in fields"
      :key="field.name"
      :label="field.label"
      :prop="`dynamicFields.${field.name}`"
      :rules="getFieldRules(field)"
    >
      <!-- 文本输入 -->
      <el-input
        v-if="field.type === 'text'"
        v-model="modelValue[field.name]"
        :placeholder="`请输入${field.label}`"
        @input="handleFieldChange(field.name, $event)"
      />
      
      <!-- 数字输入 -->
      <el-input-number
        v-else-if="field.type === 'number'"
        v-model="modelValue[field.name]"
        :placeholder="`请输入${field.label}`"
        style="width: 100%"
        @change="handleFieldChange(field.name, $event)"
      />
      
      <!-- 日期选择 -->
      <el-date-picker
        v-else-if="field.type === 'date'"
        v-model="modelValue[field.name]"
        type="date"
        :placeholder="`请选择${field.label}`"
        style="width: 100%"
        @change="handleFieldChange(field.name, $event)"
      />
      
      <!-- 下拉选择 -->
      <el-select
        v-else-if="field.type === 'select'"
        v-model="modelValue[field.name]"
        :placeholder="`请选择${field.label}`"
        style="width: 100%"
        @change="handleFieldChange(field.name, $event)"
      >
        <el-option
          v-for="option in field.options"
          :key="option"
          :label="option"
          :value="option"
        />
      </el-select>
      
      <!-- 多行文本 -->
      <el-input
        v-else-if="field.type === 'textarea'"
        v-model="modelValue[field.name]"
        type="textarea"
        :rows="4"
        :placeholder="`请输入${field.label}`"
        @input="handleFieldChange(field.name, $event)"
      />
      
      <!-- 标签输入 -->
      <div v-else-if="field.type === 'tags'" class="tags-input">
        <el-tag
          v-for="tag in getFieldTags(field.name)"
          :key="tag"
          closable
          @close="removeTag(field.name, tag)"
          style="margin-right: 8px; margin-bottom: 8px;"
        >
          {{ tag }}
        </el-tag>
        
        <el-autocomplete
          v-if="showTagInput[field.name]"
          ref="tagInputRef"
          v-model="tagInputValue[field.name]"
          :fetch-suggestions="(query, cb) => getTagSuggestions(field, query, cb)"
          :placeholder="`输入${field.label}后按回车`"
          size="small"
          style="width: 120px;"
          @keyup.enter="addTag(field.name)"
          @blur="hideTagInput(field.name)"
        />
        
        <el-button
          v-else
          size="small"
          @click="showTagInputField(field.name)"
        >
          + 添加{{ field.label }}
        </el-button>
      </div>
      
      <!-- 文件上传 -->
      <el-upload
        v-else-if="field.type === 'file'"
        :action="uploadUrl"
        :headers="uploadHeaders"
        :file-list="getFieldFiles(field.name)"
        :on-success="(response, file) => handleFileSuccess(field.name, response, file)"
        :on-remove="(file) => handleFileRemove(field.name, file)"
        :before-upload="beforeUpload"
        multiple
      >
        <el-button size="small" type="primary">选择文件</el-button>
        <template #tip>
          <div class="el-upload__tip">
            支持常见文件格式，单个文件不超过10MB
          </div>
        </template>
      </el-upload>
    </el-form-item>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, nextTick, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '../stores/auth'
import { API_CONFIG, API_ENDPOINTS } from '../config/api'

interface DynamicField {
  name: string
  label: string
  type: 'text' | 'number' | 'date' | 'select' | 'textarea' | 'tags' | 'file'
  required: boolean
  options?: string[]
}

interface Props {
  fields: DynamicField[]
  modelValue: Record<string, any>
}

interface Emits {
  (e: 'update:modelValue', value: Record<string, any>): void
  (e: 'field-change', fieldName: string, value: any): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()
const authStore = useAuthStore()

// 响应式数据
const tagInputRef = ref()
const showTagInput = reactive<Record<string, boolean>>({})
const tagInputValue = reactive<Record<string, string>>({})

// 计算属性
const uploadUrl = computed(() => `${API_CONFIG.BASE_URL}${API_CONFIG.VERSION}${API_ENDPOINTS.FILES.UPLOAD}`)
const uploadHeaders = computed(() => ({
  Authorization: `Bearer ${authStore.token}`
}))

// 初始化字段默认值
watch(() => props.fields, (newFields) => {
  if (!newFields || newFields.length === 0) return
  
  const currentValue = { ...props.modelValue }
  let hasChanges = false
  
  newFields.forEach(field => {
    if (!(field.name in currentValue)) {
      if (field.type === 'tags') {
        currentValue[field.name] = []
      } else if (field.type === 'file') {
        currentValue[field.name] = []
      } else {
        currentValue[field.name] = ''
      }
      hasChanges = true
    }
  })
  
  if (hasChanges) {
    emit('update:modelValue', currentValue)
  }
}, { immediate: true, deep: true })

// 字段变更处理
const handleFieldChange = (fieldName: string, value: any) => {
  const newValue = { ...props.modelValue }
  newValue[fieldName] = value
  emit('update:modelValue', newValue)
  emit('field-change', fieldName, value)
}

// 获取字段验证规则
const getFieldRules = (field: DynamicField) => {
  const rules = []
  
  if (field.required) {
    rules.push({
      required: true,
      message: `请输入${field.label}`,
      trigger: field.type === 'select' ? 'change' : 'blur'
    })
  }
  
  return rules
}

// 标签相关方法
const getFieldTags = (fieldName: string): string[] => {
  const value = props.modelValue[fieldName]
  return Array.isArray(value) ? value : []
}

const showTagInputField = (fieldName: string) => {
  showTagInput[fieldName] = true
  tagInputValue[fieldName] = ''
  nextTick(() => {
    if (tagInputRef.value) {
      tagInputRef.value.focus()
    }
  })
}

const hideTagInput = (fieldName: string) => {
  showTagInput[fieldName] = false
  tagInputValue[fieldName] = ''
}

const addTag = (fieldName: string) => {
  const inputValue = tagInputValue[fieldName]?.trim()
  if (inputValue) {
    const currentTags = getFieldTags(fieldName)
    if (!currentTags.includes(inputValue)) {
      const newTags = [...currentTags, inputValue]
      handleFieldChange(fieldName, newTags)
    }
    tagInputValue[fieldName] = ''
  }
}

const removeTag = (fieldName: string, tag: string) => {
  const currentTags = getFieldTags(fieldName)
  const newTags = currentTags.filter(t => t !== tag)
  handleFieldChange(fieldName, newTags)
}

const getTagSuggestions = (field: DynamicField, query: string, callback: Function) => {
  const suggestions = (field.options || [])
    .filter(option => option.toLowerCase().includes(query.toLowerCase()))
    .map(option => ({ value: option }))
  
  callback(suggestions)
}

// 文件相关方法
const getFieldFiles = (fieldName: string) => {
  const value = props.modelValue[fieldName]
  return Array.isArray(value) ? value : []
}

const beforeUpload = (file: File) => {
  const isValidSize = file.size / 1024 / 1024 < 10
  if (!isValidSize) {
    ElMessage.error('文件大小不能超过10MB')
    return false
  }
  return true
}

const handleFileSuccess = (fieldName: string, response: any, file: any) => {
  if (response.success) {
    const currentFiles = getFieldFiles(fieldName)
    const newFiles = [...currentFiles, {
      name: file.name,
      url: response.data.url,
      id: response.data.id
    }]
    handleFieldChange(fieldName, newFiles)
    ElMessage.success('文件上传成功')
  } else {
    ElMessage.error('文件上传失败')
  }
}

const handleFileRemove = (fieldName: string, file: any) => {
  const currentFiles = getFieldFiles(fieldName)
  const newFiles = currentFiles.filter((f: any) => f.id !== file.id)
  handleFieldChange(fieldName, newFiles)
}
</script>

<style scoped>
.dynamic-form {
  width: 100%;
}

.tags-input {
  min-height: 32px;
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  padding: 8px;
  background-color: #fff;
}

.tags-input:focus-within {
  border-color: #409eff;
}

.el-upload__tip {
  color: #606266;
  font-size: 12px;
  margin-top: 7px;
}
</style>
