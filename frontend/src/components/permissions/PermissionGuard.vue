<template>
  <div v-if="hasAccess">
    <slot />
  </div>
  <div v-else-if="showFallback">
    <slot name="fallback">
      <div class="permission-denied">
        <el-empty 
          :image-size="80" 
          description="权限不足"
        >
          <template #description>
            <span class="permission-message">
              {{ fallbackMessage || '您没有权限访问此内容' }}
            </span>
          </template>
          <el-button v-if="showContactAdmin" size="small" @click="contactAdmin">
            联系管理员
          </el-button>
        </el-empty>
      </div>
    </slot>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { ElMessage } from 'element-plus'
import { usePermissions } from '@/composables/usePermissions'

interface Props {
  // 单个权限检查
  resource?: string
  action?: string
  scope?: string
  
  // 多个权限检查
  permissions?: Array<{resource: string, action: string, scope?: string}>
  requireAll?: boolean // true: 需要所有权限, false: 需要任意一个权限
  
  // 显示选项
  showFallback?: boolean
  fallbackMessage?: string
  showContactAdmin?: boolean
  
  // 自定义权限检查函数
  customCheck?: () => boolean
}

const props = withDefaults(defineProps<Props>(), {
  scope: 'all',
  requireAll: false,
  showFallback: true,
  showContactAdmin: false
})

const { hasPermission, hasAnyPermission, hasAllPermissions } = usePermissions()

// 计算是否有访问权限
const hasAccess = computed(() => {
  // 自定义权限检查
  if (props.customCheck) {
    return props.customCheck()
  }
  
  // 单个权限检查
  if (props.resource && props.action) {
    return hasPermission(props.resource, props.action, props.scope)
  }
  
  // 多个权限检查
  if (props.permissions && props.permissions.length > 0) {
    return props.requireAll 
      ? hasAllPermissions(props.permissions)
      : hasAnyPermission(props.permissions)
  }
  
  // 如果没有指定权限要求，默认允许访问
  return true
})

// 联系管理员
const contactAdmin = () => {
  ElMessage.info('请联系系统管理员获取相应权限')
}
</script>

<style scoped>
.permission-denied {
  padding: 40px 20px;
  text-align: center;
}

.permission-message {
  color: #909399;
  font-size: 14px;
}
</style>