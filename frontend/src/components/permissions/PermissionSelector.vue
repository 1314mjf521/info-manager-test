<template>
  <div class="permission-selector">
    <div class="selector-header" v-if="showHeader">
      <div class="header-info">
        <span class="title">权限选择</span>
        <span class="selected-count" v-if="selectedPermissions.length > 0">
          已选择 {{ selectedPermissions.length }} 个权限
        </span>
      </div>
      <div class="header-actions">
        <el-button size="small" @click="expandAll">
          <el-icon><Expand /></el-icon>
          展开全部
        </el-button>
        <el-button size="small" @click="collapseAll">
          <el-icon><Fold /></el-icon>
          收起全部
        </el-button>
        <el-button size="small" @click="clearSelection">
          清空选择
        </el-button>
      </div>
    </div>

    <div class="selector-search" v-if="showSearch">
      <el-input
        v-model="searchText"
        placeholder="搜索权限..."
        clearable
        size="small"
      >
        <template #prefix>
          <el-icon><Search /></el-icon>
        </template>
      </el-input>
    </div>

    <div class="selector-content">
      <el-tree
        ref="treeRef"
        :data="permissionTree"
        :props="treeProps"
        node-key="id"
        show-checkbox
        :check-strictly="checkStrictly"
        :default-expanded-keys="defaultExpandedKeys"
        :filter-node-method="filterNode"
        @check="handleCheck"
      >
        <template #default="{ node, data }">
          <div class="tree-node-content">
            <div class="node-main">
              <div class="node-info">
                <span class="node-title">{{ data.displayName || data.name }}</span>
                <div class="node-tags">
                  <el-tag size="small" type="primary">
                    {{ data.resource }}
                  </el-tag>
                  <el-tag size="small" type="success">
                    {{ data.action }}
                  </el-tag>
                  <el-tag size="small" :type="getScopeTagType(data.scope)">
                    {{ getScopeDisplayName(data.scope) }}
                  </el-tag>
                </div>
              </div>
              <div class="node-description" v-if="data.description && showDescription">
                {{ data.description }}
              </div>
            </div>
          </div>
        </template>
      </el-tree>
    </div>

    <div class="selector-footer" v-if="showFooter">
      <div class="selected-summary">
        <el-tag 
          v-for="permission in selectedPermissionDetails" 
          :key="permission.id"
          closable
          size="small"
          @close="removePermission(permission.id)"
        >
          {{ permission.displayName || permission.name }}
        </el-tag>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { ElTree } from 'element-plus'
import { Search, Expand, Fold } from '@element-plus/icons-vue'
import http from '@/utils/request'
import type { Permission } from '@/types'

interface Props {
  modelValue?: number[]
  checkStrictly?: boolean
  showHeader?: boolean
  showSearch?: boolean
  showFooter?: boolean
  showDescription?: boolean
  disabled?: boolean
}

interface Emits {
  (e: 'update:modelValue', value: number[]): void
  (e: 'change', selectedIds: number[], selectedPermissions: Permission[]): void
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: () => [],
  checkStrictly: false,
  showHeader: true,
  showSearch: true,
  showFooter: true,
  showDescription: true,
  disabled: false
})

const emit = defineEmits<Emits>()

const treeRef = ref<InstanceType<typeof ElTree>>()
const searchText = ref('')
const permissionTree = ref<Permission[]>([])
const allPermissions = ref<Permission[]>([])

const treeProps = {
  children: 'children',
  label: 'displayName'
}

// 计算属性
const selectedPermissions = computed(() => props.modelValue || [])

const defaultExpandedKeys = computed(() => {
  // 默认展开第一层
  return permissionTree.value.map(p => p.id)
})

const selectedPermissionDetails = computed(() => {
  return allPermissions.value.filter(p => selectedPermissions.value.includes(p.id))
})

// 监听搜索文本变化
watch(searchText, (val) => {
  treeRef.value?.filter(val)
})

// 监听选中值变化
watch(() => props.modelValue, (newVal) => {
  if (newVal && treeRef.value) {
    treeRef.value.setCheckedKeys(newVal)
  }
}, { immediate: true })

// 方法
const fetchPermissionTree = async () => {
  try {
    const response = await http.get('/permissions/tree')
    if (response.success) {
      permissionTree.value = response.data || []
    }
  } catch (error) {
    console.error('获取权限树失败:', error)
  }
}

const fetchAllPermissions = async () => {
  try {
    const response = await http.get('/permissions')
    if (response.success) {
      allPermissions.value = response.data || []
    }
  } catch (error) {
    console.error('获取权限列表失败:', error)
  }
}

const filterNode = (value: string, data: Permission) => {
  if (!value) return true
  const searchValue = value.toLowerCase()
  return (
    data.name.toLowerCase().includes(searchValue) ||
    data.displayName.toLowerCase().includes(searchValue) ||
    data.resource.toLowerCase().includes(searchValue) ||
    data.action.toLowerCase().includes(searchValue) ||
    data.description.toLowerCase().includes(searchValue)
  )
}

const handleCheck = (data: Permission, checked: any) => {
  const checkedKeys = treeRef.value?.getCheckedKeys() as number[] || []
  const checkedNodes = treeRef.value?.getCheckedNodes() as Permission[] || []
  
  emit('update:modelValue', checkedKeys)
  emit('change', checkedKeys, checkedNodes)
}

const expandAll = () => {
  const getAllKeys = (nodes: Permission[]): number[] => {
    let keys: number[] = []
    nodes.forEach(node => {
      keys.push(node.id)
      if (node.children && node.children.length > 0) {
        keys = keys.concat(getAllKeys(node.children))
      }
    })
    return keys
  }
  
  const allKeys = getAllKeys(permissionTree.value)
  allKeys.forEach(key => {
    const node = treeRef.value?.getNode(key)
    if (node) {
      node.expanded = true
    }
  })
}

const collapseAll = () => {
  const getAllKeys = (nodes: Permission[]): number[] => {
    let keys: number[] = []
    nodes.forEach(node => {
      keys.push(node.id)
      if (node.children && node.children.length > 0) {
        keys = keys.concat(getAllKeys(node.children))
      }
    })
    return keys
  }
  
  const allKeys = getAllKeys(permissionTree.value)
  allKeys.forEach(key => {
    const node = treeRef.value?.getNode(key)
    if (node) {
      node.expanded = false
    }
  })
}

const clearSelection = () => {
  treeRef.value?.setCheckedKeys([])
  emit('update:modelValue', [])
  emit('change', [], [])
}

const removePermission = (permissionId: number) => {
  const newSelection = selectedPermissions.value.filter(id => id !== permissionId)
  treeRef.value?.setCheckedKeys(newSelection)
  emit('update:modelValue', newSelection)
  
  const selectedNodes = allPermissions.value.filter(p => newSelection.includes(p.id))
  emit('change', newSelection, selectedNodes)
}

const getScopeTagType = (scope: string) => {
  const typeMap: Record<string, string> = {
    'all': 'danger',
    'own': 'success',
    'department': 'warning'
  }
  return typeMap[scope] || 'info'
}

const getScopeDisplayName = (scope: string) => {
  const nameMap: Record<string, string> = {
    'all': '全部',
    'own': '自己',
    'department': '部门'
  }
  return nameMap[scope] || scope
}

// 暴露方法给父组件
defineExpose({
  getCheckedKeys: () => treeRef.value?.getCheckedKeys(),
  getCheckedNodes: () => treeRef.value?.getCheckedNodes(),
  setCheckedKeys: (keys: number[]) => treeRef.value?.setCheckedKeys(keys),
  clearSelection,
  expandAll,
  collapseAll
})

// 生命周期
onMounted(async () => {
  await Promise.all([fetchPermissionTree(), fetchAllPermissions()])
})
</script>

<style scoped>
.permission-selector {
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  background: #fff;
}

.selector-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  border-bottom: 1px solid #e4e7ed;
  background: #f5f7fa;
}

.header-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.title {
  font-weight: 500;
  color: #303133;
}

.selected-count {
  font-size: 12px;
  color: #909399;
}

.header-actions {
  display: flex;
  gap: 8px;
}

.selector-search {
  padding: 12px 16px;
  border-bottom: 1px solid #e4e7ed;
}

.selector-content {
  max-height: 400px;
  overflow-y: auto;
  padding: 8px;
}

.tree-node-content {
  display: flex;
  align-items: center;
  width: 100%;
  padding: 4px 0;
}

.node-main {
  flex: 1;
  min-width: 0;
}

.node-info {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.node-title {
  font-weight: 500;
  color: #303133;
  font-size: 14px;
}

.node-tags {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
}

.node-description {
  font-size: 12px;
  color: #909399;
  line-height: 1.4;
  margin-top: 4px;
}

.selector-footer {
  padding: 12px 16px;
  border-top: 1px solid #e4e7ed;
  background: #f5f7fa;
}

.selected-summary {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  max-height: 100px;
  overflow-y: auto;
}

:deep(.el-tree-node__content) {
  height: auto;
  min-height: 32px;
  padding: 4px 0;
}

:deep(.el-tree-node__expand-icon) {
  padding: 6px;
}

:deep(.el-tree-node__label) {
  flex: 1;
}
</style>