# 信息管理系统 - 前端

基于 Vue 3 + TypeScript + Vite + Element Plus 构建的现代化前端应用。

## 技术栈

- **框架**: Vue 3 (Composition API)
- **语言**: TypeScript
- **构建工具**: Vite
- **UI组件库**: Element Plus
- **状态管理**: Pinia
- **路由**: Vue Router 4
- **HTTP客户端**: Axios
- **日期处理**: Day.js
- **工具库**: Lodash-es
- **进度条**: NProgress

## 项目结构

```
frontend/
├── public/                 # 静态资源
├── src/
│   ├── components/         # 通用组件
│   ├── config/            # 配置文件
│   ├── layout/            # 布局组件
│   ├── router/            # 路由配置
│   ├── stores/            # Pinia状态管理
│   ├── types/             # TypeScript类型定义
│   ├── utils/             # 工具函数
│   ├── views/             # 页面组件
│   ├── App.vue            # 根组件
│   ├── main.ts            # 应用入口
│   └── env.d.ts           # 环境变量类型定义
├── index.html             # HTML模板
├── package.json           # 项目配置
├── tsconfig.json          # TypeScript配置
├── vite.config.ts         # Vite配置
└── README.md              # 项目说明
```

## 功能特性

### 🔐 用户认证
- 用户登录/注册
- JWT Token管理
- 权限控制
- 个人资料管理

### 📝 记录管理
- 多类型记录创建/编辑
- 动态表单生成
- 记录列表/卡片视图
- 高级搜索和筛选
- 批量操作

### 📁 文件管理
- 文件上传/下载
- 图片预览
- OCR文字识别
- 批量文件操作
- 文件类型图标

### 📊 数据导出
- 多格式导出 (Excel/PDF/CSV/JSON)
- 自定义导出模板
- 导出历史管理
- 数据预览

### 🎨 用户界面
- 响应式设计
- 深色/浅色主题
- 多语言支持
- 自定义主题色
- 移动端适配

### 🔧 系统管理
- 用户管理
- 角色权限管理
- 系统配置
- 操作日志

## 开发指南

### 环境要求

- Node.js >= 16.0.0
- npm >= 8.0.0

### 安装依赖

```bash
npm install
```

### 开发服务器

```bash
npm run dev
```

访问 http://localhost:3000

### 构建生产版本

```bash
npm run build
```

构建文件将输出到 `dist` 目录。

### 预览生产版本

```bash
npm run preview
```

### 代码检查

```bash
npm run lint
```

### 代码格式化

```bash
npm run format
```

### 运行测试

```bash
# 单元测试
npm run test

# E2E测试
npm run test:e2e

# 测试UI
npm run test:ui
```

## 配置说明

### 环境变量

在项目根目录创建 `.env` 文件：

```env
# API服务器地址
VITE_API_BASE_URL=http://localhost:8080

# 应用标题
VITE_APP_TITLE=信息管理系统

# 应用版本
VITE_APP_VERSION=1.0.0
```

### API配置

在 `src/config/api.ts` 中配置API端点：

```typescript
export const API_CONFIG = {
  BASE_URL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080',
  VERSION: '/api/v1',
  TIMEOUT: 10000
}
```

### 路由配置

在 `src/router/index.ts` 中配置路由：

```typescript
const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/auth/LoginView.vue')
  }
  // ...更多路由
]
```

## 组件开发

### 创建新组件

1. 在 `src/components/` 或 `src/views/` 下创建 `.vue` 文件
2. 使用 Composition API 和 TypeScript
3. 遵循命名规范：PascalCase

```vue
<template>
  <div class="my-component">
    <!-- 模板内容 -->
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'

// 组件逻辑
</script>

<style scoped>
/* 组件样式 */
</style>
```

### 状态管理

使用 Pinia 进行状态管理：

```typescript
// stores/example.ts
import { defineStore } from 'pinia'

export const useExampleStore = defineStore('example', () => {
  const state = ref('')
  
  const getters = computed(() => state.value)
  
  const actions = () => {
    // 操作逻辑
  }
  
  return { state, getters, actions }
})
```

### API调用

使用封装的 HTTP 客户端：

```typescript
import { http } from '@/utils/request'

// GET请求
const data = await http.get('/api/endpoint')

// POST请求
const result = await http.post('/api/endpoint', { data })
```

## 部署指南

### 构建部署

1. 构建生产版本：
   ```bash
   npm run build
   ```

2. 将 `dist` 目录部署到Web服务器

### Docker部署

```dockerfile
FROM nginx:alpine
COPY dist/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Nginx配置

```nginx
server {
    listen 80;
    server_name localhost;
    
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://backend:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 开发规范

### 代码风格

- 使用 ESLint + Prettier 进行代码格式化
- 遵循 Vue 3 官方风格指南
- 使用 TypeScript 严格模式

### 命名规范

- 组件：PascalCase (MyComponent.vue)
- 文件夹：kebab-case (my-folder)
- 变量/函数：camelCase (myVariable)
- 常量：UPPER_SNAKE_CASE (MY_CONSTANT)

### Git提交规范

```
feat: 新功能
fix: 修复bug
docs: 文档更新
style: 代码格式调整
refactor: 代码重构
test: 测试相关
chore: 构建/工具相关
```

## 性能优化

### 代码分割

- 路由懒加载
- 组件懒加载
- 第三方库按需引入

### 构建优化

- Vite 自动代码分割
- 资源压缩
- Tree Shaking
- 缓存策略

### 运行时优化

- 虚拟滚动
- 图片懒加载
- 防抖节流
- 缓存策略

## 故障排除

### 常见问题

1. **构建失败**
   - 检查 Node.js 版本
   - 清除 node_modules 重新安装
   - 检查 TypeScript 类型错误

2. **API请求失败**
   - 检查后端服务是否运行
   - 检查API地址配置
   - 检查网络连接

3. **路由不工作**
   - 检查路由配置
   - 检查权限设置
   - 检查组件导入路径

### 调试技巧

- 使用 Vue DevTools
- 浏览器开发者工具
- 网络请求监控
- 控制台日志

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 许可证

MIT License