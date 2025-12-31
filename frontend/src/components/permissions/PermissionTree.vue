<template>
  <div class="permission-tree">
    <el-tree
      ref="treeRef"
      :data="treeData"
      :props="treeProps"
      :expand-on-click-node="false"
      :default-expand-all="expandAll"
      :filter-node-method="filterNode"
      node-key="id"
      class="permission-tree-component"
    >
      <template #default="{ node, data }">
        <div class="tree-node">
          <div class="node-content">
            <!-- 权限图标 -->
            <div class="node-icon">
              <el-icon :color="getNodeIconColor(data)">
                <component :is="getNodeIcon(data)" />
              </el-icon>
            </div>
            
            <!-- 权限信息 -->
            <div class="node-info">
              <div class="node-title">
                <span class="node-name">{{ data.displayName || data.name }}</span>
                <el-tag 
                  v-if="data.scope && data.scope !== 'all'" 
                  size="small" 
                  :type="getScopeTagType(data.scope)"
                  class="scope-tag"
                >
                  {{ getScopeLabel(data.scope) }}
                </el-tag>
              </div>
              
              <div class="node-meta">
                <el-tag size="small" type="info" class="resource-tag">
                  {{ data.resource }}:{{ data.action }}
                </el-tag>
                <span class="node-description">{{ data.description }}</span>
              </div>
            </div>
          </div>
          
          <!-- 操作按钮 -->
          <div v-if="showActions" class="node-actions">
            <el-button-group size="small">
              <el-button @click.stop="handleEdit(data)" type="primary" text>
                <el-icon><Edit /></el-icon>
              </el-button>
              <el-button @click.stop="handleAddChild(data)" type="success" text>
                <el-icon><Plus /></el-icon>
              </el-button>
              <el-button @click.stop="handleDelete(data)" type="danger" text>
                <el-icon><Delete /></el-icon>
              </el-button>
            </el-button-group>
          </div>
        </div>
      </template>
    </el-tree>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick } from 'vue'
import { ElTree } from 'element-plus'
import { 
  Edit, Plus, Delete, Setting, User, Lock, 
  Document, Upload, Bell, Monitor, DataAnalysis,
  Folder, Files, ChatDotRound, Key, View
} from '@element-plus/icons-vue'

interface PermissionNode {
  id: number
  name: string
  displayName: string
  description: string
  resource: string
  action: string
  scope: string
  parentId?: number
  children?: PermissionNode[]
}

interface Props {
  data: PermissionNode[]
  filterText?: string
  expandAll?: boolean
  showActions?: boolean
}

interface Emits {
  (e: 'edit', node: PermissionNode): void
  (e: 'add-child', node: PermissionNode): void
  (e: 'delete', node: PermissionNode): void
}

const props = withDefaults(defineProps<Props>(), {
  filterText: '',
  expandAll: false,
  showActions: true
})

const emit = defineEmits<Emits>()

const treeRef = ref<InstanceType<typeof ElTree>>()

const treeProps = {
  children: 'children',
  label: 'displayName'
}

const treeData = computed(() => props.data)

// 过滤节点
const filterNode = (value: string, data: PermissionNode) => {
  if (!value) return true
  const searchText = value.toLowerCase()
  return (
    data.name.toLowerCase().includes(searchText) ||
    data.displayName.toLowerCase().includes(searchText) ||
    data.description.toLowerCase().includes(searchText) ||
    data.resource.toLowerCase().includes(searchText) ||
    data.action.toLowerCase().includes(searchText)
  )
}

// 监听过滤文本变化
watch(() => props.filterText, (val) => {
  if (treeRef.value) {
    treeRef.value.filter(val)
  }
}, { debounce: 300 })

// 获取节点图标
const getNodeIcon = (data: PermissionNode) => {
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
  
  return iconMap[data.resource] || View
}

// 获取节点图标颜色
const getNodeIconColor = (data: PermissionNode) => {
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
  
  return colorMap[data.resource] || '#909399'
}

// 获取作用域标签类型
const getScopeTagType = (scope: string) => {
  const typeMap: Record<string, string> = {
    'all': 'danger',
    'own': 'success',
    'department': 'warning'
  }
  return typeMap[scope] || 'info'
}

// 获取作用域标签文本
const getScopeLabel = (scope: string) => {
  const labelMap: Record<string, string> = {
    'all': '全部',
    'own': '自己',
    'department': '部门'
  }
  return labelMap[scope] || scope
}

// 事件处理
const handleEdit = (data: PermissionNode) => {
  emit('edit', data)
}

const handleAddChild = (data: PermissionNode) => {
  emit('add-child', data)
}

const handleDelete = (data: PermissionNode) => {
  emit('delete', data)
}

// 展开所有节点
const expandAll = () => {
  const expandAllNodes = (nodes: PermissionNode[]) => {
    nodes.forEach(node => {
      treeRef.value?.setExpanded(node.id, true)
      if (node.children && node.children.length > 0) {
        expandAllNodes(node.children)
      }
    })
  }
  
  nextTick(() => {
    expandAllNodes(treeData.value)
  })
}

// 折叠所有节点
const collapseAll = () => {
  const collapseAllNodes = (nodes: PermissionNode[]) => {
    nodes.forEach(node => {
      treeRef.value?.setExpanded(node.id, false)
      if (node.children && node.children.length > 0) {
        collapseAllNodes(node.children)
      }
    })
  }
  
  nextTick(() => {
    collapseAllNodes(treeData.value)
  })
}

// 暴露方法
defineExpose({
  expandAll,
  collapseAll
})
</script>

<style scoped>
.permission-tree {
  width: 100%;
}

.permission-tree-component {
  background: transparent;
}

.permission-tree-component :deep(.el-tree-node__content) {
  height: auto;
  padding: 8px 0;
  border-radius: 6px;
  margin-bottom: 4px;
  transition: all 0.2s ease;
}

.permission-tree-component :deep(.el-tree-node__content:hover) {
  background-color: #f5f7fa;
}

.tree-node {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 0 8px;
}

.node-content {
  display: flex;
  align-items: center;
  flex: 1;
  min-width: 0;
}

.node-icon {
  margin-right: 12px;
  font-size: 18px;
  display: flex;
  align-items: center;
}

.node-info {
  flex: 1;
  min-width: 0;
}

.node-title {
  display: flex;
  align-items: center;
  margin-bottom: 4px;
}

.node-name {
  font-weight: 500;
  color: #303133;
  margin-right: 8px;
}

.scope-tag {
  margin-left: 8px;
}

.node-meta {
  display: flex;
  align-items: center;
  gap: 8px;
}

.resource-tag {
  font-family: 'Courier New', monospace;
  font-size: 11px;
}

.node-description {
  color: #909399;
  font-size: 12px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.node-actions {
  opacity: 0;
  transition: opacity 0.2s ease;
  margin-left: 12px;
}

.tree-node:hover .node-actions {
  opacity: 1;
}

/* 根节点样式 */
.permission-tree-component :deep(.el-tree-node__content[aria-level="1"]) {
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  border: 1px solid #e4e7ed;
  font-weight: 600;
}

.permission-tree-component :deep(.el-tree-node__content[aria-level="1"]:hover) {
  background: linear-gradient(135deg, #e4e7ed 0%, #b3c0d1 100%);
}

/* 二级节点样式 */
.permission-tree-component :deep(.el-tree-node__content[aria-level="2"]) {
  background: #fafbfc;
  border-left: 3px solid #409eff;
  margin-left: 20px;
}

/* 三级及以下节点样式 */
.permission-tree-component :deep(.el-tree-node__content[aria-level="3"]),
.permission-tree-component :deep(.el-tree-node__content[aria-level="4"]) {
  margin-left: 40px;
  border-left: 2px solid #e4e7ed;
  padding-left: 16px;
}

/* 展开/折叠图标样式 */
.permission-tree-component :deep(.el-tree-node__expand-icon) {
  color: #409eff;
  font-size: 14px;
}

.permission-tree-component :deep(.el-tree-node__expand-icon.expanded) {
  transform: rotate(90deg);
}
</style>