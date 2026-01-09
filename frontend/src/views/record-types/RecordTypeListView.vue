<template>
  <div class="record-type-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>记录类型管理</span>
          <div class="header-actions">
            <el-dropdown @command="handleImportAction">
              <el-button type="success">
                <el-icon><Upload /></el-icon>
                导入类型
                <el-icon class="el-icon--right"><ArrowDown /></el-icon>
              </el-button>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="template">下载模板</el-dropdown-item>
                  <el-dropdown-item command="import" divided>导入类型</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
            <el-button type="primary" @click="handleCreate">
              <el-icon><Plus /></el-icon>
              新建类型
            </el-button>
          </div>
        </div>
      </template>

      <!-- 批量操作栏 -->
      <div class="batch-actions" v-if="selectedRecordTypes.length > 0">
        <el-alert
          :title="`已选择 ${selectedRecordTypes.length} 个记录类型`"
          type="info"
          :closable="false"
          style="margin-bottom: 15px;"
        >
          <template #default>
            <div class="batch-buttons">
              <el-button size="small" type="success" @click="handleBatchEnable">
                批量启用
              </el-button>
              <el-button size="small" type="warning" @click="handleBatchDisable">
                批量禁用
              </el-button>
              <el-button size="small" type="danger" @click="handleBatchDelete">
                批量删除
              </el-button>
              <el-button size="small" @click="clearSelection">
                取消选择
              </el-button>
            </div>
          </template>
        </el-alert>
      </div>

      <!-- 记录类型表格 -->
      <el-table 
        :data="recordTypes" 
        v-loading="loading" 
        stripe
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="name" label="类型名称" min-width="150" />
        <el-table-column label="描述" min-width="200" show-overflow-tooltip>
          <template #default="{ row }">
            {{ row.display_name || row.description }}
          </template>
        </el-table-column>
        <el-table-column label="字段数量" width="100">
          <template #default="{ row }">
            {{ (row.schema?.fields || row.fields || []).length }}
          </template>
        </el-table-column>
        <el-table-column label="记录数量" width="100">
          <template #default="{ row }">
            <el-tag :type="row.record_count > 0 ? 'warning' : 'info'" size="small">
              {{ row.record_count || 0 }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-switch
              v-model="row.is_active"
              @change="handleStatusChange(row)"
              :loading="row.statusLoading"
            />
          </template>
        </el-table-column>
        <el-table-column label="创建者" width="120">
          <template #default="{ row }">
            <div class="creator-info">
              <el-avatar :size="24" style="margin-right: 8px;">
                {{ getCreatorInitial(row) }}
              </el-avatar>
              <span>{{ getCreatorName(row) }}</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="createdAt" label="创建时间" width="160">
          <template #default="{ row }">
            {{ formatTime(row.createdAt) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="handleView(row)">查看</el-button>
            <el-button size="small" @click="handleEdit(row)">编辑</el-button>
            <el-tooltip 
              :content="(row.record_count || 0) > 0 ? `该类型下有 ${row.record_count} 条记录，无法删除` : '删除记录类型'"
              placement="top"
            >
              <el-button 
                size="small" 
                type="danger" 
                :disabled="(row.record_count || 0) > 0"
                @click="handleDelete(row)"
              >
                删除
              </el-button>
            </el-tooltip>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.size"
          :total="pagination.total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 类型详情对话框 -->
    <el-dialog v-model="detailDialogVisible" :title="currentType?.name" width="800px">
      <div v-if="currentType" class="type-detail">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="类型ID">{{ currentType.id }}</el-descriptions-item>
          <el-descriptions-item label="类型名称">{{ currentType.name }}</el-descriptions-item>
          <el-descriptions-item label="描述" :span="2">{{ currentType.display_name || currentType.description }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="(currentType.is_active !== undefined ? currentType.is_active : currentType.isActive) ? 'success' : 'danger'">
              {{ (currentType.is_active !== undefined ? currentType.is_active : currentType.isActive) ? '启用' : '禁用' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="创建时间">
            {{ formatTime(currentType.createdAt) }}
          </el-descriptions-item>
        </el-descriptions>
        
        <h4 style="margin: 20px 0 10px 0;">字段定义</h4>
        <el-table :data="currentType.schema?.fields || currentType.fields || []" border>
          <el-table-column prop="name" label="字段名" />
          <el-table-column prop="label" label="显示名" />
          <el-table-column prop="type" label="字段类型" />
          <el-table-column prop="required" label="必填">
            <template #default="{ row }">
              <el-tag :type="row.required ? 'danger' : 'info'" size="small">
                {{ row.required ? '是' : '否' }}
              </el-tag>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </el-dialog>

    <!-- 类型编辑对话框 -->
    <el-dialog v-model="editDialogVisible" :title="isEdit ? '编辑类型' : '新建类型'" width="800px">
      <el-form
        ref="formRef"
        :model="typeForm"
        :rules="typeRules"
        label-width="100px"
      >
        <el-form-item label="类型名称" prop="name">
          <el-input v-model="typeForm.name" placeholder="请输入类型名称" />
        </el-form-item>
        <el-form-item label="显示名称" prop="description">
          <el-input
            v-model="typeForm.description"
            type="textarea"
            :rows="3"
            placeholder="请输入类型显示名称"
          />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="typeForm.isActive" />
        </el-form-item>
        
        <el-form-item label="字段定义">
          <div class="fields-section">
            <div class="field-header">
              <el-row :gutter="10">
                <el-col :span="5"><strong>字段名</strong></el-col>
                <el-col :span="5"><strong>显示名</strong></el-col>
                <el-col :span="4"><strong>字段类型</strong></el-col>
                <el-col :span="3"><strong>必填</strong></el-col>
                <el-col :span="5"><strong>选项配置</strong></el-col>
                <el-col :span="2"><strong>操作</strong></el-col>
              </el-row>
            </div>
            
            <div v-for="(field, index) in typeForm.fields" :key="index" class="field-item">
              <el-row :gutter="10">
                <el-col :span="5">
                  <el-input 
                    v-model="field.name" 
                    placeholder="如: title, content" 
                    @blur="validateFieldName(field, index)"
                  />
                </el-col>
                <el-col :span="5">
                  <el-input 
                    v-model="field.label" 
                    placeholder="如: 标题, 内容" 
                  />
                </el-col>
                <el-col :span="4">
                  <el-select 
                    v-model="field.type" 
                    placeholder="选择类型"
                    @change="handleFieldTypeChange(field, index)"
                  >
                    <el-option-group label="基础类型">
                      <el-option label="单行文本" value="text">
                        <span>单行文本</span>
                        <span style="float: right; color: #8492a6; font-size: 13px;">适合标题、名称</span>
                      </el-option>
                      <el-option label="多行文本" value="textarea">
                        <span>多行文本</span>
                        <span style="float: right; color: #8492a6; font-size: 13px;">适合描述、内容</span>
                      </el-option>
                      <el-option label="数字" value="number">
                        <span>数字</span>
                        <span style="float: right; color: #8492a6; font-size: 13px;">适合数量、价格</span>
                      </el-option>
                    </el-option-group>
                    <el-option-group label="选择类型">
                      <el-option label="下拉选择" value="select">
                        <span>下拉选择</span>
                        <span style="float: right; color: #8492a6; font-size: 13px;">单选，需配置选项</span>
                      </el-option>
                      <el-option label="标签" value="tags">
                        <span>标签</span>
                        <span style="float: right; color: #8492a6; font-size: 13px;">多选，支持自定义</span>
                      </el-option>
                    </el-option-group>
                    <el-option-group label="其他类型">
                      <el-option label="日期" value="date">
                        <span>日期</span>
                        <span style="float: right; color: #8492a6; font-size: 13px;">日期选择器</span>
                      </el-option>
                      <el-option label="文件" value="file">
                        <span>文件</span>
                        <span style="float: right; color: #8492a6; font-size: 13px;">文件上传</span>
                      </el-option>
                    </el-option-group>
                  </el-select>
                </el-col>
                <el-col :span="3">
                  <el-checkbox v-model="field.required">必填</el-checkbox>
                </el-col>
                <el-col :span="5">
                  <el-input
                    v-if="field.type === 'select'"
                    v-model="field.optionsText"
                    placeholder="选项1,选项2,选项3"
                  />
                  <el-input
                    v-else-if="field.type === 'tags'"
                    v-model="field.optionsText"
                    placeholder="预设标签1,预设标签2"
                  />
                  <span v-else class="field-no-options">无需配置</span>
                </el-col>
                <el-col :span="2">
                  <el-button 
                    size="small" 
                    type="danger" 
                    @click="removeField(index)"
                    :disabled="typeForm.fields.length <= 1"
                  >
                    删除
                  </el-button>
                </el-col>
              </el-row>
            </div>
            
            <div class="add-field-section">
              <el-button @click="addField" type="primary" plain>
                <el-icon><Plus /></el-icon>
                添加新字段
              </el-button>
              <el-button @click="addCommonField('title')" size="small">+ 标题字段</el-button>
              <el-button @click="addCommonField('content')" size="small">+ 内容字段</el-button>
              <el-button @click="addCommonField('tags')" size="small">+ 标签字段</el-button>
            </div>
          </div>
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSave" :loading="saving">
          {{ isEdit ? '更新' : '创建' }}
        </el-button>
      </template>
    </el-dialog>

    <!-- 导入记录类型对话框 -->
    <el-dialog v-model="importDialogVisible" title="导入记录类型" width="600px">
      <div class="import-section">
        <el-alert
          title="导入说明"
          type="info"
          :closable="false"
          show-icon
          style="margin-bottom: 20px;"
        >
          <template #default>
            <div style="font-size: 14px;">
              <p>1. 请先下载模板文件，按照模板格式填写记录类型信息</p>
              <p>2. 支持的文件格式：Excel (.xlsx, .xls) 或 CSV (.csv)</p>
              <p>3. 必填字段：类型名称、显示名称</p>
              <p>4. 可选字段：Schema配置、状态</p>
            </div>
          </template>
        </el-alert>

        <el-upload
          ref="recordTypeUploadRef"
          class="upload-demo"
          drag
          :auto-upload="false"
          :on-change="handleRecordTypeFileChange"
          :before-upload="beforeRecordTypeUpload"
          accept=".xlsx,.xls,.csv"
          :limit="1"
        >
          <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
          <div class="el-upload__text">
            将文件拖到此处，或<em>点击上传</em>
          </div>
          <template #tip>
            <div class="el-upload__tip">
              只能上传 xlsx/xls/csv 文件，且不超过 10MB
            </div>
          </template>
        </el-upload>

        <div v-if="importRecordTypeFile" class="file-info" style="margin-top: 20px;">
          <el-card>
            <div style="display: flex; align-items: center; justify-content: space-between;">
              <div>
                <el-icon><Document /></el-icon>
                <span style="margin-left: 8px;">{{ importRecordTypeFile.name }}</span>
                <el-tag size="small" style="margin-left: 8px;">{{ formatFileSize(importRecordTypeFile.size) }}</el-tag>
              </div>
              <el-button size="small" type="danger" @click="removeRecordTypeFile">移除</el-button>
            </div>
          </el-card>
        </div>

        <div v-if="importRecordTypePreview.length > 0" class="preview-section" style="margin-top: 20px;">
          <h4>数据预览 (前5条)</h4>
          <el-table :data="importRecordTypePreview.slice(0, 5)" size="small" max-height="300">
            <el-table-column prop="name" label="类型名称" width="120" />
            <el-table-column prop="displayName" label="显示名称" width="150" />
            <el-table-column prop="schema" label="Schema配置" width="200" show-overflow-tooltip />
            <el-table-column prop="isActive" label="状态" width="80" />
          </el-table>
          <div style="margin-top: 10px; color: #666; font-size: 14px;">
            共 {{ importRecordTypePreview.length }} 条数据，将导入 {{ validImportRecordTypeData.length }} 条有效数据
          </div>
        </div>
      </div>

      <template #footer>
        <div class="dialog-footer">
          <el-button @click="importDialogVisible = false">取消</el-button>
          <el-button @click="downloadRecordTypeTemplate">下载模板</el-button>
          <el-button 
            type="primary" 
            @click="handleImportRecordTypes" 
            :loading="importing"
            :disabled="!importRecordTypeFile || validImportRecordTypeData.length === 0"
          >
            导入记录类型 ({{ validImportRecordTypeData.length }})
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Upload, ArrowDown, UploadFilled, Document } from '@element-plus/icons-vue'
import { http } from '../../utils/request'
import { API_ENDPOINTS } from '../../config/api'
import dayjs from 'dayjs'

// 响应式数据
const loading = ref(false)
const saving = ref(false)
const recordTypes = ref([])
const selectedRecordTypes = ref([])
const detailDialogVisible = ref(false)
const editDialogVisible = ref(false)
const currentType = ref(null)
const formRef = ref()

// 导入相关数据
const importDialogVisible = ref(false)
const importing = ref(false)
const importRecordTypeFile = ref(null)
const importRecordTypePreview = ref([])
const validImportRecordTypeData = ref([])
const recordTypeUploadRef = ref()

const pagination = reactive({
  page: 1,
  size: 20,
  total: 0
})

const typeForm = reactive({
  name: '',
  description: '',
  isActive: true,
  fields: []
})

// 计算属性
const isEdit = computed(() => !!currentType.value?.id)

// 表单验证规则
const typeRules = {
  name: [
    { required: true, message: '请输入类型名称', trigger: 'blur' },
    { min: 2, max: 50, message: '类型名称长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  description: [
    { required: true, message: '请输入类型描述', trigger: 'blur' }
  ]
}

// 获取记录类型列表
const fetchRecordTypes = async () => {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      size: pagination.size
    }
    
    const response = await http.get(API_ENDPOINTS.RECORD_TYPES.LIST, { params })
    
    if (response.success && response.data) {
      recordTypes.value = response.data.map((type: any) => ({
        ...type,
        statusLoading: false,
        // 确保字段名称一致
        isActive: type.is_active !== undefined ? type.is_active : type.isActive,
        description: type.display_name || type.description,
        fields: type.schema?.fields || type.fields || [],
        // 确保创建者信息正确映射
        creator: type.creator ? { username: type.creator.username || type.creator } : null,
        createdBy: type.created_by || type.createdBy || 1,
        record_count: type.record_count || 0
      }))
      pagination.total = response.data.length || 0
    } else {
      // 使用模拟数据并创建默认类型
      recordTypes.value = [
        {
          id: 1,
          name: 'work',
          description: '工作记录类型',
          isActive: true,
          fields: [
            { name: 'title', label: '标题', type: 'text', required: true },
            { name: 'description', label: '描述', type: 'textarea', required: true },
            { name: 'tags', label: '标签', type: 'tags', required: false }
          ],
          creator: { username: '系统管理员' },
          createdBy: 1,
          record_count: 5,
          createdAt: new Date().toISOString(),
          statusLoading: false
        },
        {
          id: 2,
          name: 'study',
          description: '学习笔记类型',
          isActive: true,
          fields: [
            { name: 'title', label: '标题', type: 'text', required: true },
            { name: 'content', label: '内容', type: 'textarea', required: true },
            { name: 'tags', label: '标签', type: 'tags', required: false }
          ],
          creator: { username: '开发者' },
          createdBy: 2,
          record_count: 3,
          createdAt: new Date(Date.now() - 86400000).toISOString(),
          statusLoading: false
        },
        {
          id: 3,
          name: 'project',
          description: '项目文档类型',
          isActive: true,
          fields: [
            { name: 'title', label: '标题', type: 'text', required: true },
            { name: 'description', label: '描述', type: 'textarea', required: true },
            { name: 'status', label: '状态', type: 'select', required: true, options: ['进行中', '已完成', '暂停'] },
            { name: 'tags', label: '标签', type: 'tags', required: false }
          ],
          creator: { username: '项目经理' },
          createdBy: 3,
          record_count: 8,
          createdAt: new Date(Date.now() - 172800000).toISOString(),
          statusLoading: false
        }
      ]
      pagination.total = 3
      
      ElMessage.warning('后端服务已连接，但需要登录认证。当前显示模拟数据，请先登录系统。')
      // 尝试创建默认类型
      await createDefaultTypes()
    }
  } catch (error) {
    console.error('获取记录类型失败:', error)
    // 使用模拟数据作为fallback
    recordTypes.value = [
      {
        id: 1,
        name: 'work',
        description: '工作记录类型',
        isActive: true,
        fields: [
          { name: 'title', label: '标题', type: 'text', required: true },
          { name: 'description', label: '描述', type: 'textarea', required: true }
        ],
        creator: { username: '系统管理员' },
        createdBy: 1,
        record_count: 0,
        createdAt: new Date().toISOString(),
        statusLoading: false
      }
    ]
    pagination.total = 1
    ElMessage.warning('使用模拟数据，正在尝试创建默认记录类型')
    await createDefaultTypes()
  } finally {
    loading.value = false
  }
}

// 创建默认记录类型
const createDefaultTypes = async () => {
  const defaultTypes = [
    {
      name: 'work',
      description: '工作记录类型',
      isActive: true,
      fields: [
        { name: 'title', label: '标题', type: 'text', required: true },
        { name: 'description', label: '描述', type: 'textarea', required: true }
      ]
    },
    {
      name: 'study',
      description: '学习笔记类型',
      isActive: true,
      fields: [
        { name: 'title', label: '标题', type: 'text', required: true },
        { name: 'content', label: '内容', type: 'textarea', required: true }
      ]
    },
    {
      name: 'project',
      description: '项目文档类型',
      isActive: true,
      fields: [
        { name: 'title', label: '标题', type: 'text', required: true },
        { name: 'description', label: '描述', type: 'textarea', required: true },
        { name: 'status', label: '状态', type: 'select', required: true, options: ['进行中', '已完成', '暂停'] }
      ]
    },
    {
      name: 'other',
      description: '其他类型',
      isActive: true,
      fields: [
        { name: 'title', label: '标题', type: 'text', required: true },
        { name: 'content', label: '内容', type: 'textarea', required: true }
      ]
    }
  ]

  for (const type of defaultTypes) {
    try {
      await http.post(API_ENDPOINTS.RECORD_TYPES.CREATE, type)
      console.log(`创建默认记录类型成功: ${type.name}`)
    } catch (error) {
      console.log(`记录类型 ${type.name} 可能已存在`)
    }
  }
  
  ElMessage.success('默认记录类型创建完成')
}

// 新建类型
const handleCreate = () => {
  currentType.value = null
  Object.assign(typeForm, {
    name: '',
    description: '',
    isActive: true,
    fields: [
      { name: 'title', label: '标题', type: 'text', required: true, optionsText: '' }
    ]
  })
  editDialogVisible.value = true
}

// 查看类型
const handleView = (row: any) => {
  currentType.value = row
  detailDialogVisible.value = true
}

// 编辑类型
const handleEdit = (row: any) => {
  currentType.value = row
  Object.assign(typeForm, {
    name: row.name,
    description: row.display_name || row.description,
    isActive: row.is_active !== undefined ? row.is_active : row.isActive,
    fields: (row.schema?.fields || row.fields || []).map((field: any) => ({
      ...field,
      optionsText: field.options ? field.options.join(', ') : ''
    }))
  })
  editDialogVisible.value = true
}

// 保存类型
const handleSave = async () => {
  if (!formRef.value) return
  
  try {
    await formRef.value.validate()
    
    saving.value = true
    
    // 处理字段数据
    const processedFields = typeForm.fields.map((field: any) => ({
      name: field.name,
      label: field.label,
      type: field.type,
      required: field.required,
      options: (field.type === 'select' || field.type === 'tags') && field.optionsText 
        ? field.optionsText.split(',').map((opt: string) => opt.trim()).filter(Boolean)
        : undefined
    }))
    
    const data = {
      name: typeForm.name,
      display_name: typeForm.description,
      schema: {
        fields: processedFields
      }
    }
    
    if (isEdit.value) {
      await http.put(API_ENDPOINTS.RECORD_TYPES.UPDATE(currentType.value.id), data)
      ElMessage.success('记录类型更新成功')
    } else {
      await http.post(API_ENDPOINTS.RECORD_TYPES.CREATE, data)
      ElMessage.success('记录类型创建成功')
    }
    
    editDialogVisible.value = false
    fetchRecordTypes()
  } catch (error: any) {
    if (error.fields) {
      // 表单验证错误
      return
    }
    console.error('保存记录类型失败:', error)
    ElMessage.error(error.message || '保存记录类型失败')
  } finally {
    saving.value = false
  }
}

// 状态切换
const handleStatusChange = async (row: any) => {
  row.statusLoading = true
  try {
    await http.put(API_ENDPOINTS.RECORD_TYPES.UPDATE(row.id), { is_active: row.is_active })
    ElMessage.success(`记录类型${row.is_active ? '启用' : '禁用'}成功`)
  } catch (error) {
    console.error('状态切换失败:', error)
    row.is_active = !row.is_active // 回滚状态
    ElMessage.error('状态切换失败')
  } finally {
    row.statusLoading = false
  }
}

// 删除类型
const handleDelete = async (row: any) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除记录类型"${row.display_name || row.description}"吗？\n\n注意：如果该类型下还有记录，将无法删除。`, 
      '删除确认', 
      {
        confirmButtonText: '确定删除',
        cancelButtonText: '取消',
        type: 'warning',
        dangerouslyUseHTMLString: false
      }
    )
    
    await http.delete(API_ENDPOINTS.RECORD_TYPES.DELETE(row.id))
    ElMessage.success('删除成功')
    fetchRecordTypes()
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('删除记录类型失败:', error)
      
      // 根据错误类型提供具体提示
      if (error.response?.status === 409) {
        ElMessage.error(`无法删除记录类型"${row.display_name || row.description}"，该类型下还有记录存在。请先删除相关记录后再试。`)
      } else {
        ElMessage.error(error.message || '删除记录类型失败')
      }
    }
  }
}

// 字段管理
const addField = () => {
  typeForm.fields.push({
    name: '',
    label: '',
    type: 'text',
    required: false,
    optionsText: ''
  })
}

const addCommonField = (type: string) => {
  const commonFields = {
    title: { name: 'title', label: '标题', type: 'text', required: true },
    content: { name: 'content', label: '内容', type: 'textarea', required: true },
    tags: { name: 'tags', label: '标签', type: 'tags', required: false }
  }
  
  const field = commonFields[type]
  if (field) {
    typeForm.fields.push({
      ...field,
      optionsText: ''
    })
  }
}

const removeField = (index: number) => {
  if (typeForm.fields.length > 1) {
    typeForm.fields.splice(index, 1)
  } else {
    ElMessage.warning('至少需要保留一个字段')
  }
}

const validateFieldName = (field: any, index: number) => {
  if (!field.name) return
  
  // 检查字段名是否重复
  const duplicateIndex = typeForm.fields.findIndex((f, i) => 
    i !== index && f.name === field.name
  )
  
  if (duplicateIndex !== -1) {
    ElMessage.warning(`字段名 "${field.name}" 已存在，请使用不同的字段名`)
    field.name = ''
  }
}

const handleFieldTypeChange = (field: any, index: number) => {
  // 当字段类型改变时，清空选项配置
  if (field.type !== 'select' && field.type !== 'tags') {
    field.optionsText = ''
  }
  
  // 为不同类型提供默认配置
  if (field.type === 'select' && !field.optionsText) {
    field.optionsText = '选项1,选项2,选项3'
  } else if (field.type === 'tags' && !field.optionsText) {
    field.optionsText = '标签1,标签2,标签3'
  }
}

// 分页处理
const handleSizeChange = (size: number) => {
  pagination.size = size
  fetchRecordTypes()
}

const handleCurrentChange = (page: number) => {
  pagination.page = page
  fetchRecordTypes()
}

// 工具函数
const formatTime = (time: string) => {
  return dayjs(time).format('YYYY-MM-DD HH:mm')
}

// 获取创建者姓名
const getCreatorName = (row: any) => {
  // 优先使用真实用户名
  if (row.creator?.username && row.creator.username !== 'undefined') {
    return row.creator.username
  }
  
  // 根据用户ID映射友好的名称
  const userMap: { [key: number]: string } = {
    1: '系统管理员',
    2: '开发者',
    3: '项目经理',
    4: '测试工程师',
    5: '运维工程师'
  }
  
  if (row.createdBy && userMap[row.createdBy]) {
    return userMap[row.createdBy]
  }
  
  if (row.createdBy) {
    return `用户${row.createdBy}`
  }
  
  return '系统'
}

// 获取创建者头像首字母
const getCreatorInitial = (row: any) => {
  const name = getCreatorName(row)
  return name.charAt(0).toUpperCase()
}

// 选择变化处理
const handleSelectionChange = (selection: any[]) => {
  selectedRecordTypes.value = selection
}

// 清除选择
const clearSelection = () => {
  selectedRecordTypes.value = []
}

// 批量启用
const handleBatchEnable = async () => {
  if (selectedRecordTypes.value.length === 0) {
    ElMessage.warning('请先选择要启用的记录类型')
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要批量启用选中的 ${selectedRecordTypes.value.length} 个记录类型吗？`,
      '批量启用确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    const recordTypeIds = selectedRecordTypes.value.map(item => item.id)
    await http.put(API_ENDPOINTS.RECORD_TYPES.BATCH_STATUS, {
      record_type_ids: recordTypeIds,
      is_active: true
    })

    ElMessage.success('批量启用成功')
    clearSelection()
    fetchRecordTypes()
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('批量启用失败:', error)
      ElMessage.error('批量启用失败')
    }
  }
}

// 批量禁用
const handleBatchDisable = async () => {
  if (selectedRecordTypes.value.length === 0) {
    ElMessage.warning('请先选择要禁用的记录类型')
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要批量禁用选中的 ${selectedRecordTypes.value.length} 个记录类型吗？`,
      '批量禁用确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    const recordTypeIds = selectedRecordTypes.value.map(item => item.id)
    await http.put(API_ENDPOINTS.RECORD_TYPES.BATCH_STATUS, {
      record_type_ids: recordTypeIds,
      is_active: false
    })

    ElMessage.success('批量禁用成功')
    clearSelection()
    fetchRecordTypes()
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('批量禁用失败:', error)
      ElMessage.error('批量禁用失败')
    }
  }
}

// 批量删除
const handleBatchDelete = async () => {
  if (selectedRecordTypes.value.length === 0) {
    ElMessage.warning('请先选择要删除的记录类型')
    return
  }

  // 检查是否有记录类型正在被使用
  const typesInUse = selectedRecordTypes.value.filter(item => (item.record_count || 0) > 0)
  if (typesInUse.length > 0) {
    const typeNames = typesInUse.map(item => item.display_name || item.description).join('、')
    ElMessage.error(`以下记录类型正在被使用，无法删除：${typeNames}`)
    return
  }

  try {
    const typeNames = selectedRecordTypes.value.map(item => item.display_name || item.description).join('、')
    await ElMessageBox.confirm(
      `确定要批量删除以下记录类型吗？\n\n${typeNames}\n\n此操作不可恢复！`,
      '批量删除确认',
      {
        confirmButtonText: '确定删除',
        cancelButtonText: '取消',
        type: 'error'
      }
    )

    const recordTypeIds = selectedRecordTypes.value.map(item => item.id)
    await http.delete(API_ENDPOINTS.RECORD_TYPES.BATCH_DELETE, {
      data: { record_type_ids: recordTypeIds }
    })

    ElMessage.success('批量删除成功')
    clearSelection()
    fetchRecordTypes()
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('批量删除失败:', error)
      ElMessage.error('批量删除失败')
    }
  }
}

// 导入操作处理
const handleImportAction = (command: string) => {
  switch (command) {
    case 'template':
      downloadRecordTypeTemplate()
      break
    case 'import':
      importDialogVisible.value = true
      break
  }
}

// 下载记录类型导入模板
const downloadRecordTypeTemplate = () => {
  const template = [
    ['类型名称*', '显示名称*', 'Schema配置', '状态'],
    ['daily_report', '日报类型', '{"type":"object","properties":{"content":{"type":"string"}}}', 'true'],
    ['weekly_report', '周报类型', '{"type":"object","properties":{"title":{"type":"string"},"content":{"type":"string"}}}', 'true']
  ]
  
  // 创建CSV内容
  const csvContent = template.map(row => row.join(',')).join('\n')
  const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)
  
  link.setAttribute('href', url)
  link.setAttribute('download', '记录类型导入模板.csv')
  link.style.visibility = 'hidden'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  
  ElMessage.success('模板下载成功')
}

// 文件上传处理
const handleRecordTypeFileChange = (file: any) => {
  importRecordTypeFile.value = file.raw
  parseImportRecordTypeFile(file.raw)
}

// 文件上传前检查
const beforeRecordTypeUpload = (file: any) => {
  const isValidType = ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 
                      'application/vnd.ms-excel', 
                      'text/csv'].includes(file.type)
  const isLt10M = file.size / 1024 / 1024 < 10

  if (!isValidType) {
    ElMessage.error('只能上传 Excel 或 CSV 文件!')
    return false
  }
  if (!isLt10M) {
    ElMessage.error('文件大小不能超过 10MB!')
    return false
  }
  return false // 阻止自动上传
}

// 解析导入文件
const parseImportRecordTypeFile = async (file: File) => {
  try {
    const text = await file.text()
    const lines = text.split('\n').filter(line => line.trim())
    
    if (lines.length < 2) {
      ElMessage.error('文件内容不能为空')
      return
    }
    
    // 解析CSV数据
    const data = lines.slice(1).map(line => {
      const values = line.split(',').map(v => v.trim().replace(/"/g, ''))
      return {
        name: values[0] || '',
        displayName: values[1] || '',
        schema: values[2] || '',
        isActive: values[3] || 'true'
      }
    })
    
    importRecordTypePreview.value = data
    
    // 验证数据
    validImportRecordTypeData.value = data.filter(item => 
      item.name && item.displayName
    )
    
    if (validImportRecordTypeData.value.length === 0) {
      ElMessage.error('没有找到有效的记录类型数据')
    } else {
      ElMessage.success(`解析成功，找到 ${validImportRecordTypeData.value.length} 条有效数据`)
    }
  } catch (error) {
    console.error('解析文件失败:', error)
    ElMessage.error('文件解析失败')
  }
}

// 移除文件
const removeRecordTypeFile = () => {
  importRecordTypeFile.value = null
  importRecordTypePreview.value = []
  validImportRecordTypeData.value = []
  recordTypeUploadRef.value?.clearFiles()
}

// 执行导入
const handleImportRecordTypes = async () => {
  if (validImportRecordTypeData.value.length === 0) {
    ElMessage.warning('没有有效的数据可以导入')
    return
  }
  
  try {
    importing.value = true
    
    const response = await http.post(API_ENDPOINTS.RECORD_TYPES.IMPORT, {
      recordTypes: validImportRecordTypeData.value
    })
    
    const results = response.data.results || []
    const successCount = results.filter((r: any) => r.success).length
    const failCount = results.length - successCount
    
    if (failCount === 0) {
      ElMessage.success(`成功导入 ${successCount} 个记录类型`)
    } else {
      ElMessage.warning(`导入完成：成功 ${successCount} 个，失败 ${failCount} 个`)
      
      // 显示失败的详细信息
      const failedItems = results.filter((r: any) => !r.success)
      if (failedItems.length > 0) {
        console.log('导入失败的项目:', failedItems)
      }
    }
    
    importDialogVisible.value = false
    removeRecordTypeFile()
    fetchRecordTypes()
  } catch (error) {
    console.error('导入记录类型失败:', error)
    ElMessage.error('导入记录类型失败')
  } finally {
    importing.value = false
  }
}

// 格式化文件大小
const formatFileSize = (size: any) => {
  if (!size || size === 0) return '未知大小'
  
  const bytes = parseInt(size)
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
  return (bytes / (1024 * 1024 * 1024)).toFixed(1) + ' GB'
}

// 生命周期
onMounted(() => {
  fetchRecordTypes()
})
</script>

<style scoped>
.record-type-list {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  gap: 10px;
  align-items: center;
}

.batch-actions {
  margin-bottom: 15px;
}

.batch-buttons {
  display: flex;
  gap: 10px;
  align-items: center;
  margin-top: 10px;
}

.import-section {
  padding: 10px 0;
}

.file-info {
  margin-top: 15px;
}

.preview-section {
  margin-top: 20px;
}

.preview-section h4 {
  margin-bottom: 10px;
  color: #303133;
}

.pagination {
  margin-top: 20px;
  text-align: right;
}

.type-detail {
  padding: 20px 0;
}

.fields-section {
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  padding: 15px;
  background-color: #fafafa;
}

.field-header {
  margin-bottom: 15px;
  padding-bottom: 10px;
  border-bottom: 2px solid #e4e7ed;
  background-color: #f5f7fa;
  padding: 10px;
  border-radius: 4px;
}

.field-item {
  margin-bottom: 15px;
  padding: 10px;
  background-color: #fff;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
}

.field-item:last-child {
  margin-bottom: 0;
}

.field-no-options {
  color: #909399;
  font-size: 12px;
  line-height: 32px;
  text-align: center;
}

.add-field-section {
  margin-top: 15px;
  padding-top: 15px;
  border-top: 1px dashed #dcdfe6;
  text-align: center;
}

.add-field-section .el-button {
  margin: 0 5px;
}

@media (max-width: 768px) {
  .record-type-list {
    padding: 10px;
  }
}

/* 创建者信息样式 */
.creator-info {
  display: flex;
  align-items: center;
  gap: 8px;
}

.creator-info span {
  font-size: 14px;
  color: #606266;
}

@media (max-width: 768px) {
  .record-type-list {
    padding: 10px;
  }
  
  .creator-info {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }
}
</style>
