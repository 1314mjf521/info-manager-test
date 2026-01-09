#!/bin/bash

# 前端构建问题修复脚本
# 专门解决 crypto.getRandomValues 和相关构建问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================${NC}"
}

# 检查前端目录
check_frontend_dir() {
    if [[ ! -d "frontend" ]]; then
        log_error "frontend目录不存在"
        log_info "请确保在项目根目录运行此脚本"
        exit 1
    fi
    
    if [[ ! -f "frontend/package.json" ]]; then
        log_error "frontend/package.json不存在"
        exit 1
    fi
    
    log_success "前端目录检查通过"
}

# 检查Node.js环境
check_node_env() {
    log_header "检查Node.js环境"
    
    if ! command -v node &> /dev/null; then
        log_error "Node.js未安装"
        return 1
    fi
    
    local node_version=$(node --version)
    local major_version=$(echo $node_version | sed 's/v//' | cut -d'.' -f1)
    
    log_info "Node.js版本: $node_version"
    
    if [[ $major_version -lt 16 ]]; then
        log_error "Node.js版本过低，需要16+，当前: $node_version"
        return 1
    fi
    
    log_success "Node.js环境检查通过"
    return 0
}

# 修复vite配置
fix_vite_config() {
    log_header "修复Vite配置"
    
    cd frontend
    
    if [[ -f "vite.config.ts" ]]; then
        # 备份原配置
        cp vite.config.ts vite.config.ts.backup.$(date +%Y%m%d_%H%M%S)
        log_info "已备份原配置文件"
    fi
    
    # 创建修复后的vite.config.ts
    cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
  define: {
    // 修复 crypto.getRandomValues 问题
    global: 'globalThis',
  },
  server: {
    port: 5173,
    host: '0.0.0.0',
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, '/api'),
      },
    },
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', 'vue-router'],
          elementPlus: ['element-plus'],
          utils: ['axios', 'dayjs'],
        },
      },
    },
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true,
      },
    },
  },
  optimizeDeps: {
    include: ['vue', 'vue-router', 'element-plus', 'axios'],
  },
})
EOF
    
    log_success "vite.config.ts已修复"
    cd ..
}

# 修复package.json
fix_package_json() {
    log_header "修复package.json"
    
    cd frontend
    
    # 备份package.json
    cp package.json package.json.backup.$(date +%Y%m%d_%H%M%S)
    
    # 使用Node.js脚本更新package.json
    node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    
    // 更新engines字段
    pkg.engines = pkg.engines || {};
    pkg.engines.node = '>=16.0.0';
    pkg.engines.npm = '>=8.0.0';
    
    // 确保有正确的scripts
    pkg.scripts = pkg.scripts || {};
    if (!pkg.scripts.build) {
        pkg.scripts.build = 'vite build';
    }
    if (!pkg.scripts.dev) {
        pkg.scripts.dev = 'vite';
    }
    if (!pkg.scripts.preview) {
        pkg.scripts.preview = 'vite preview';
    }
    
    fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
    console.log('✓ package.json已更新');
    "
    
    log_success "package.json已修复"
    cd ..
}

# 配置npm
configure_npm() {
    log_header "配置npm"
    
    cd frontend
    
    # 创建.npmrc文件
    cat > .npmrc << 'EOF'
registry=https://registry.npmmirror.com
disturl=https://npmmirror.com/dist
sass_binary_site=https://npmmirror.com/mirrors/node-sass
phantomjs_cdnurl=https://npmmirror.com/mirrors/phantomjs
electron_mirror=https://npmmirror.com/mirrors/electron/
chromedriver_cdnurl=https://npmmirror.com/mirrors/chromedriver
operadriver_cdnurl=https://npmmirror.com/mirrors/operadriver
selenium_cdnurl=https://npmmirror.com/mirrors/selenium
node_inspector_cdnurl=https://npmmirror.com/mirrors/node-inspector
EOF
    
    log_success "npm配置完成"
    cd ..
}

# 清理并重新安装依赖
reinstall_deps() {
    log_header "重新安装依赖"
    
    cd frontend
    
    # 清理现有依赖
    log_info "清理现有依赖和缓存..."
    rm -rf node_modules package-lock.json
    npm cache clean --force
    
    # 重新安装依赖
    log_info "重新安装依赖..."
    npm install
    
    if [[ $? -eq 0 ]]; then
        log_success "依赖安装成功"
        
        # 显示依赖信息
        local dep_count=$(ls node_modules | wc -l)
        local node_modules_size=$(du -sh node_modules | cut -f1)
        log_info "已安装 $dep_count 个依赖包，总大小: $node_modules_size"
    else
        log_error "依赖安装失败"
        cd ..
        return 1
    fi
    
    cd ..
}

# 测试构建
test_build() {
    log_header "测试构建"
    
    cd frontend
    
    log_info "开始构建..."
    npm run build
    
    if [[ $? -eq 0 ]]; then
        log_success "构建成功！"
        
        # 显示构建结果
        if [[ -d "dist" ]]; then
            local file_count=$(find dist -type f | wc -l)
            local total_size=$(du -sh dist | cut -f1)
            local js_files=$(find dist -name "*.js" | wc -l)
            local css_files=$(find dist -name "*.css" | wc -l)
            
            log_info "构建统计:"
            log_info "  总文件数: $file_count"
            log_info "  总大小: $total_size"
            log_info "  JS文件: $js_files"
            log_info "  CSS文件: $css_files"
            
            # 检查关键文件
            if [[ -f "dist/index.html" ]]; then
                log_success "✓ index.html存在"
            else
                log_warn "⚠ index.html不存在"
            fi
        fi
    else
        log_error "构建失败"
        cd ..
        return 1
    fi
    
    cd ..
}

# 创建构建脚本
create_build_script() {
    log_header "创建构建脚本"
    
    cat > scripts/build-frontend.sh << 'EOF'
#!/bin/bash

# 前端构建脚本

set -e

echo "🔨 开始构建前端..."

cd frontend

# 检查依赖
if [[ ! -d "node_modules" ]]; then
    echo "📦 安装依赖..."
    npm install
fi

# 构建
echo "🏗️ 构建中..."
npm run build

if [[ $? -eq 0 ]]; then
    echo "✅ 构建成功！"
    
    if [[ -d "dist" ]]; then
        echo "📊 构建统计:"
        echo "  文件数: $(find dist -type f | wc -l)"
        echo "  大小: $(du -sh dist | cut -f1)"
    fi
else
    echo "❌ 构建失败"
    exit 1
fi

cd ..
EOF
    
    chmod +x scripts/build-frontend.sh
    log_success "构建脚本已创建: scripts/build-frontend.sh"
}

# 创建开发脚本
create_dev_script() {
    log_header "创建开发脚本"
    
    cat > scripts/start-frontend-dev.sh << 'EOF'
#!/bin/bash

# 前端开发服务器启动脚本

set -e

echo "🚀 启动前端开发服务器..."

cd frontend

# 检查依赖
if [[ ! -d "node_modules" ]]; then
    echo "📦 安装依赖..."
    npm install
fi

# 启动开发服务器
echo "🌐 启动开发服务器..."
echo "访问地址: http://localhost:5173"
npm run dev

cd ..
EOF
    
    chmod +x scripts/start-frontend-dev.sh
    log_success "开发脚本已创建: scripts/start-frontend-dev.sh"
}

# 主函数
main() {
    log_header "前端构建问题修复脚本"
    
    # 检查前端目录
    check_frontend_dir
    
    # 检查Node.js环境
    if ! check_node_env; then
        log_error "Node.js环境不符合要求"
        log_info "请先安装Node.js 16+版本"
        log_info "可以运行: ./scripts/fix-node-crypto-issue.sh"
        exit 1
    fi
    
    # 修复配置文件
    fix_vite_config
    fix_package_json
    configure_npm
    
    # 重新安装依赖
    reinstall_deps
    
    # 测试构建
    test_build
    
    # 创建辅助脚本
    create_build_script
    create_dev_script
    
    log_header "修复完成"
    log_success "🎉 前端构建问题已修复！"
    
    echo ""
    echo "现在可以使用以下命令："
    echo "  构建前端: ./scripts/build-frontend.sh"
    echo "  开发模式: ./scripts/start-frontend-dev.sh"
    echo "  完整部署: ./scripts/deploy-linux.sh"
    echo ""
    echo "如果仍有问题，请检查："
    echo "  - Node.js版本是否>=16"
    echo "  - 网络连接是否正常"
    echo "  - 磁盘空间是否充足"
}

# 显示帮助
show_help() {
    echo "前端构建问题修复脚本"
    echo ""
    echo "此脚本解决以下问题："
    echo "  - TypeError: crypto.getRandomValues is not a function"
    echo "  - Vite构建配置问题"
    echo "  - 依赖安装问题"
    echo "  - npm镜像配置"
    echo ""
    echo "用法:"
    echo "  $0              # 自动修复所有问题"
    echo "  $0 --help       # 显示帮助"
    echo ""
    echo "修复内容:"
    echo "  1. 修复vite.config.ts配置"
    echo "  2. 更新package.json"
    echo "  3. 配置npm镜像"
    echo "  4. 重新安装依赖"
    echo "  5. 测试构建"
    echo "  6. 创建辅助脚本"
}

# 参数处理
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# 执行主函数
main "$@"