#!/bin/bash

# 一键修复并部署脚本

set -e

echo "🔧 一键修复并部署脚本"
echo "================================"

# 1. 升级Node.js到18.x
echo "步骤1: 升级Node.js..."
current_version=$(node --version | sed 's/v//' | cut -d'.' -f1)
if [[ $current_version -lt 18 ]]; then
    echo "当前Node.js版本过低: $(node --version)"
    echo "正在升级到Node.js 18..."
    
    # 检测系统并升级
    if [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu
        sudo rm -f /etc/apt/sources.list.d/nodesource.list
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [[ -f /etc/redhat-release ]]; then
        # CentOS/RHEL
        sudo yum remove -y nodejs npm
        curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
        sudo yum install -y nodejs
    else
        echo "❌ 不支持的系统，请手动升级Node.js到18+"
        exit 1
    fi
    
    echo "✅ Node.js升级完成: $(node --version)"
else
    echo "✅ Node.js版本正常: $(node --version)"
fi

# 2. 修复前端配置和构建
echo ""
echo "步骤2: 修复前端配置..."
cd frontend

# 配置npm
npm config set registry https://registry.npmmirror.com

# 修复vite.config.ts
if [[ -f "vite.config.ts" ]]; then
    cp vite.config.ts vite.config.ts.bak
    
    cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
  define: {
    global: 'globalThis',
  },
  server: {
    port: 5173,
    host: '0.0.0.0',
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', 'vue-router'],
          elementPlus: ['element-plus'],
        },
      },
    },
  },
})
EOF
    echo "✅ vite.config.ts已修复"
fi

# 3. 重新安装依赖
echo ""
echo "步骤3: 重新安装依赖..."
rm -rf node_modules package-lock.json
npm cache clean --force
npm install

if [[ $? -ne 0 ]]; then
    echo "❌ 依赖安装失败"
    exit 1
fi

echo "✅ 依赖安装成功"

# 4. 构建前端
echo ""
echo "步骤4: 构建前端..."
npm run build

if [[ $? -ne 0 ]]; then
    echo "❌ 前端构建失败"
    exit 1
fi

echo "✅ 前端构建成功"

# 显示构建结果
if [[ -d "dist" ]]; then
    file_count=$(find dist -type f | wc -l)
    total_size=$(du -sh dist | cut -f1)
    echo "📊 构建结果: $file_count 个文件, 总大小: $total_size"
fi

cd ..

# 5. 构建后端
echo ""
echo "步骤5: 构建后端..."
go build -o info-management-system ./cmd/server

if [[ $? -ne 0 ]]; then
    echo "❌ 后端构建失败"
    exit 1
fi

echo "✅ 后端构建成功"

# 6. 完成
echo ""
echo "================================"
echo "🎉 修复和构建完成！"
echo "================================"

echo "现在可以继续部署："
echo "  1. 手动启动: ./info-management-system"
echo "  2. 使用部署脚本: sudo ./scripts/deploy-linux.sh"
echo "  3. 使用Docker: ./scripts/docker-deploy.sh"
echo ""
echo "访问地址:"
echo "  前端: http://your-server:5173"
echo "  后端: http://your-server:8080"