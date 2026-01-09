#!/usr/bin/env pwsh
# 前端文件恢复脚本

Write-Host "🔄 开始恢复前端文件..." -ForegroundColor Cyan

# 检查前端备份是否存在
if (!(Test-Path "build/frontend")) {
    Write-Host "[ERROR] 前端备份不存在于 build/frontend/" -ForegroundColor Red
    exit 1
}

# 创建前端目录
Write-Host "📁 创建前端目录..." -ForegroundColor Yellow
if (!(Test-Path "frontend")) {
    New-Item -ItemType Directory -Path "frontend" -Force | Out-Null
    Write-Host "  ✅ 创建目录: frontend/" -ForegroundColor Green
}

# 恢复前端文件
Write-Host "📦 恢复前端文件..." -ForegroundColor Yellow

# 复制前端构建文件
if (Test-Path "build/frontend") {
    Copy-Item "build/frontend/*" "frontend/" -Recurse -Force
    Write-Host "  ✅ 恢复前端构建文件" -ForegroundColor Green
}

# 检查是否有前端备份
if (Test-Path "build/frontend_backup") {
    Write-Host "📦 发现前端备份，也进行恢复..." -ForegroundColor Yellow
    
    if (!(Test-Path "frontend/backup")) {
        New-Item -ItemType Directory -Path "frontend/backup" -Force | Out-Null
    }
    
    Copy-Item "build/frontend_backup/*" "frontend/backup/" -Recurse -Force
    Write-Host "  ✅ 恢复前端备份文件" -ForegroundColor Green
}

# 创建前端项目的基本结构（如果需要的话）
Write-Host "📁 创建前端项目结构..." -ForegroundColor Yellow

$frontendDirs = @(
    "frontend/src",
    "frontend/src/components", 
    "frontend/src/views",
    "frontend/src/router",
    "frontend/src/store",
    "frontend/src/utils",
    "frontend/src/api",
    "frontend/src/assets",
    "frontend/public"
)

foreach ($dir in $frontendDirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  ✅ 创建目录: $dir" -ForegroundColor Green
    }
}

# 创建基本的前端配置文件
Write-Host "📄 创建前端配置文件..." -ForegroundColor Yellow

# package.json
if (!(Test-Path "frontend/package.json")) {
    $packageJson = @"
{
  "name": "info-management-frontend",
  "version": "1.0.0",
  "description": "信息管理系统前端",
  "main": "index.js",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "serve": "vite preview --port 3000"
  },
  "dependencies": {
    "vue": "^3.3.0",
    "vue-router": "^4.2.0",
    "element-plus": "^2.3.0",
    "axios": "^1.4.0",
    "@element-plus/icons-vue": "^2.1.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^4.2.0",
    "vite": "^4.3.0"
  }
}
"@
    $packageJson | Out-File -FilePath "frontend/package.json" -Encoding UTF8
    Write-Host "  ✅ 创建 package.json" -ForegroundColor Green
}

# vite.config.js
if (!(Test-Path "frontend/vite.config.js")) {
    $viteConfig = @"
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true
      }
    }
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  }
})
"@
    $viteConfig | Out-File -FilePath "frontend/vite.config.js" -Encoding UTF8
    Write-Host "  ✅ 创建 vite.config.js" -ForegroundColor Green
}

# README.md
if (!(Test-Path "frontend/README.md")) {
    $frontendReadme = @"
# 信息管理系统前端

基于 Vue 3 + Element Plus 的现代化前端界面。

## 开发环境

### 安装依赖
```bash
npm install
```

### 启动开发服务器
```bash
npm run dev
```

### 构建生产版本
```bash
npm run build
```

### 预览生产版本
```bash
npm run preview
```

## 项目结构

```
frontend/
├── src/
│   ├── components/     # 公共组件
│   ├── views/         # 页面组件
│   ├── router/        # 路由配置
│   ├── store/         # 状态管理
│   ├── utils/         # 工具函数
│   ├── api/           # API接口
│   └── assets/        # 静态资源
├── public/            # 公共文件
├── dist/              # 构建输出
└── package.json       # 项目配置
```

## 技术栈

- Vue 3
- Element Plus
- Vue Router
- Axios
- Vite

## API接口

前端通过代理访问后端API：
- 开发环境：http://localhost:3000 -> http://localhost:8080
- 生产环境：直接访问后端API

## 部署

1. 构建项目：`npm run build`
2. 将 `dist` 目录部署到Web服务器
3. 配置反向代理到后端API
"@
    $frontendReadme | Out-File -FilePath "frontend/README.md" -Encoding UTF8
    Write-Host "  ✅ 创建 frontend/README.md" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎯 前端文件恢复完成！" -ForegroundColor Green

# 显示恢复后的前端结构
Write-Host ""
Write-Host "📂 前端项目结构:" -ForegroundColor Cyan

if (Test-Path "frontend") {
    $frontendItems = Get-ChildItem "frontend" -Force
    foreach ($item in $frontendItems) {
        if ($item.PSIsContainer) {
            Write-Host "  📁 frontend/$($item.Name)/" -ForegroundColor Yellow
        } else {
            Write-Host "  📄 frontend/$($item.Name)" -ForegroundColor White
        }
    }
}

Write-Host ""
Write-Host "📋 下一步操作:" -ForegroundColor Yellow
Write-Host "  1. 进入前端目录: cd frontend" -ForegroundColor White
Write-Host "  2. 安装依赖: npm install" -ForegroundColor White  
Write-Host "  3. 启动开发服务器: npm run dev" -ForegroundColor White
Write-Host "  4. 访问前端: http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "🎉 前端已成功恢复！" -ForegroundColor Green