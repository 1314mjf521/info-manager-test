#!/bin/bash

# 修复npm安装问题

set -e

echo "🔧 修复npm安装问题..."

# 进入前端目录
cd frontend

# 1. 清理npm缓存
echo "清理npm缓存..."
npm cache clean --force

# 2. 配置npm镜像
echo "配置npm镜像..."
npm config set registry https://registry.npmmirror.com

# 3. 直接使用npm install而不是npm ci
echo "安装依赖..."
npm install

# 4. 测试构建
echo "测试构建..."
npm run build

if [[ $? -eq 0 ]]; then
    echo "✅ 前端构建成功！"
else
    echo "❌ 构建失败"
    exit 1
fi

echo "🎉 修复完成！"