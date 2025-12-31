<template>
  <div class="ticket-test">
    <h1>工单权限测试</h1>
    
    <div class="debug-info">
      <h3>用户信息</h3>
      <p>用户ID: {{ authStore.user?.id }}</p>
      <p>用户名: {{ authStore.user?.username }}</p>
      <p>角色: {{ authStore.user?.roles?.join(', ') }}</p>
      <p>是否已认证: {{ authStore.isAuthenticated }}</p>
    </div>
    
    <div class="debug-info">
      <h3>权限测试</h3>
      <p>canCreateTickets: {{ ticketPermissions.canCreateTickets() }}</p>
      <p>canViewStatistics: {{ ticketPermissions.canViewStatistics() }}</p>
      <p>canExportTickets: {{ ticketPermissions.canExportTickets() }}</p>
      <p>canImportTickets: {{ ticketPermissions.canImportTickets() }}</p>
    </div>
    
    <div class="debug-info">
      <h3>权限检查详情</h3>
      <p>hasPermission('ticket', 'create'): {{ authStore.hasPermission('ticket', 'create') }}</p>
      <p>hasPermission('ticket', 'statistics'): {{ authStore.hasPermission('ticket', 'statistics') }}</p>
      <p>hasPermission('ticket', 'export'): {{ authStore.hasPermission('ticket', 'export') }}</p>
      <p>hasRole('admin'): {{ authStore.hasRole('admin') }}</p>
    </div>
    
    <!-- 测试按钮显示 -->
    <div class="test-buttons">
      <h3>按钮显示测试</h3>
      <el-button 
        v-if="ticketPermissions.canCreateTickets()" 
        type="primary"
      >
        创建工单 (应该显示)
      </el-button>
      <el-button 
        v-if="ticketPermissions.canExportTickets()" 
        type="success"
      >
        导出工单 (应该显示)
      </el-button>
      <p v-if="!ticketPermissions.canCreateTickets()">创建按钮被隐藏</p>
      <p v-if="!ticketPermissions.canExportTickets()">导出按钮被隐藏</p>
    </div>
    
    <!-- 测试统计卡片 -->
    <div class="test-stats" v-if="ticketPermissions.canViewStatistics()">
      <h3>统计卡片测试</h3>
      <el-card>
        <p>统计卡片应该显示</p>
      </el-card>
    </div>
    <div v-else>
      <h3>统计卡片被隐藏</h3>
      <p>canViewStatistics() 返回 false</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useTicketPermissions } from '@/utils/ticketPermissions'
import { useAuthStore } from '@/stores/auth'

const ticketPermissions = useTicketPermissions()
const authStore = useAuthStore()
</script>

<style scoped>
.ticket-test {
  padding: 20px;
}

.debug-info {
  margin: 20px 0;
  padding: 15px;
  border: 1px solid #ddd;
  border-radius: 4px;
  background: #f9f9f9;
}

.debug-info h3 {
  margin-top: 0;
  color: #333;
}

.debug-info p {
  margin: 5px 0;
  font-family: monospace;
}

.test-buttons {
  margin: 20px 0;
  padding: 15px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.test-stats {
  margin: 20px 0;
  padding: 15px;
  border: 1px solid #ddd;
  border-radius: 4px;
}
</style>