#!/bin/bash

# 修复前端导入路径问题

set -e

echo "🔧 修复前端导入路径问题..."

cd frontend

# 1. 检查文件是否存在
echo "检查文件结构..."
if [[ ! -f "src/views/files/FileListView.vue" ]]; then
    echo "❌ FileListView.vue 文件不存在"
    echo "正在创建缺失的文件..."
    
    # 创建目录
    mkdir -p src/views/files
    
    # 创建基础的FileListView.vue文件
    cat > src/views/files/FileListView.vue << 'EOF'
<template>
  <div class="file-list-view">
    <el-card>
      <template #header>
        <h2>文件管理</h2>
      </template>
      <div class="content">
        <p>文件管理功能开发中...</p>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
// 文件管理组件
</script>

<style scoped>
.file-list-view {
  padding: 20px;
}

.content {
  text-align: center;
  padding: 40px;
  color: #666;
}
</style>
EOF
    echo "✅ 已创建 FileListView.vue"
fi

# 2. 检查其他可能缺失的文件
echo "检查其他视图文件..."

# 检查并创建TicketListView.vue
if [[ ! -f "src/views/tickets/TicketListView.vue" ]]; then
    echo "创建 TicketListView.vue..."
    mkdir -p src/views/tickets
    
    cat > src/views/tickets/TicketListView.vue << 'EOF'
<template>
  <div class="ticket-list-view">
    <el-card>
      <template #header>
        <h2>工单管理</h2>
      </template>
      <div class="content">
        <p>工单管理功能开发中...</p>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
// 工单管理组件
</script>

<style scoped>
.ticket-list-view {
  padding: 20px;
}

.content {
  text-align: center;
  padding: 40px;
  color: #666;
}
</style>
EOF
    echo "✅ 已创建 TicketListView.vue"
fi

# 3. 检查路由文件
echo "检查路由配置..."
if [[ -f "src/router/index.ts" ]]; then
    echo "修复路由导入路径..."
    
    # 备份原文件
    cp src/router/index.ts src/router/index.ts.bak
    
    # 修复路由文件
    cat > src/router/index.ts << 'EOF'
import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

const routes: Array<RouteRecordRaw> = [
  {
    path: '/',
    name: 'Home',
    component: () => import('../views/HomeView.vue')
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/LoginView.vue')
  },
  {
    path: '/files',
    name: 'Files',
    component: () => import('../views/files/FileListView.vue')
  },
  {
    path: '/tickets',
    name: 'Tickets',
    component: () => import('../views/tickets/TicketListView.vue')
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
EOF
    echo "✅ 路由配置已修复"
fi

# 4. 检查并创建基础视图文件
echo "检查基础视图文件..."

if [[ ! -f "src/views/HomeView.vue" ]]; then
    echo "创建 HomeView.vue..."
    mkdir -p src/views
    
    cat > src/views/HomeView.vue << 'EOF'
<template>
  <div class="home-view">
    <el-card>
      <template #header>
        <h1>信息管理系统</h1>
      </template>
      <div class="welcome">
        <h2>欢迎使用信息管理系统</h2>
        <p>这是一个现代化的信息管理平台</p>
        
        <el-row :gutter="20" class="feature-cards">
          <el-col :span="8">
            <el-card class="feature-card">
              <h3>文件管理</h3>
              <p>上传、下载和管理文件</p>
              <el-button type="primary" @click="$router.push('/files')">
                进入文件管理
              </el-button>
            </el-card>
          </el-col>
          
          <el-col :span="8">
            <el-card class="feature-card">
              <h3>工单管理</h3>
              <p>创建和处理工单</p>
              <el-button type="primary" @click="$router.push('/tickets')">
                进入工单管理
              </el-button>
            </el-card>
          </el-col>
          
          <el-col :span="8">
            <el-card class="feature-card">
              <h3>系统设置</h3>
              <p>配置系统参数</p>
              <el-button type="primary" disabled>
                敬请期待
              </el-button>
            </el-card>
          </el-col>
        </el-row>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
// 首页组件
</script>

<style scoped>
.home-view {
  padding: 20px;
}

.welcome {
  text-align: center;
  padding: 20px;
}

.feature-cards {
  margin-top: 40px;
}

.feature-card {
  text-align: center;
  padding: 20px;
}

.feature-card h3 {
  margin-bottom: 10px;
  color: #409eff;
}

.feature-card p {
  margin-bottom: 20px;
  color: #666;
}
</style>
EOF
    echo "✅ 已创建 HomeView.vue"
fi

if [[ ! -f "src/views/LoginView.vue" ]]; then
    echo "创建 LoginView.vue..."
    
    cat > src/views/LoginView.vue << 'EOF'
<template>
  <div class="login-view">
    <div class="login-container">
      <el-card class="login-card">
        <template #header>
          <h2>系统登录</h2>
        </template>
        
        <el-form :model="loginForm" :rules="rules" ref="loginFormRef">
          <el-form-item prop="username">
            <el-input
              v-model="loginForm.username"
              placeholder="用户名"
              size="large"
            />
          </el-form-item>
          
          <el-form-item prop="password">
            <el-input
              v-model="loginForm.password"
              type="password"
              placeholder="密码"
              size="large"
              @keyup.enter="handleLogin"
            />
          </el-form-item>
          
          <el-form-item>
            <el-button
              type="primary"
              size="large"
              style="width: 100%"
              @click="handleLogin"
              :loading="loading"
            >
              登录
            </el-button>
          </el-form-item>
        </el-form>
      </el-card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'

const router = useRouter()
const loading = ref(false)
const loginFormRef = ref()

const loginForm = reactive({
  username: '',
  password: ''
})

const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' }
  ]
}

const handleLogin = async () => {
  if (!loginFormRef.value) return
  
  try {
    await loginFormRef.value.validate()
    loading.value = true
    
    // 模拟登录
    setTimeout(() => {
      loading.value = false
      ElMessage.success('登录成功')
      router.push('/')
    }, 1000)
    
  } catch (error) {
    console.error('登录失败:', error)
  }
}
</script>

<style scoped>
.login-view {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.login-container {
  width: 100%;
  max-width: 400px;
  padding: 20px;
}

.login-card {
  text-align: center;
}

.login-card h2 {
  margin: 0;
  color: #303133;
}
</style>
EOF
    echo "✅ 已创建 LoginView.vue"
fi

# 5. 测试构建
echo ""
echo "测试构建..."
npm run build

if [[ $? -eq 0 ]]; then
    echo "✅ 构建成功！"
    
    # 显示构建结果
    if [[ -d "dist" ]]; then
        file_count=$(find dist -type f | wc -l)
        total_size=$(du -sh dist | cut -f1)
        echo "📊 构建结果: $file_count 个文件, 总大小: $total_size"
    fi
else
    echo "❌ 构建仍然失败"
    exit 1
fi

cd ..

echo ""
echo "🎉 前端路径修复完成！"