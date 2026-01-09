#!/bin/bash

# 修复Node.js crypto.getRandomValues问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 检查当前Node.js版本
check_node_version() {
    log_info "检查Node.js版本..."
    
    if ! command -v node &> /dev/null; then
        log_error "Node.js未安装"
        return 1
    fi
    
    local node_version=$(node --version)
    local major_version=$(echo $node_version | cut -d'.' -f1 | sed 's/v//')
    
    log_info "当前Node.js版本: $node_version"
    
    if [[ $major_version -lt 16 ]]; then
        log_warn "Node.js版本过低 (需要16+)，当前版本: $node_version"
        return 1
    else
        log_success "Node.js版本符合要求"
        return 0
    fi
}

# 安装或更新Node.js
install_nodejs() {
    log_info "安装/更新Node.js..."
    
    # 检测系统类型
    if [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu系统
        log_info "检测到Debian/Ubuntu系统"
        
        # 添加NodeSource仓库
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
        
    elif [[ -f /etc/redhat-release ]]; then
        # CentOS/RHEL系统
        log_info "检测到CentOS/RHEL系统"
        
        # 添加NodeSource仓库
        curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
        sudo yum install -y nodejs
        
    else
        # 使用通用方法 - 下载二进制文件
        log_info "使用通用安装方法"
        
        local node_version="18.19.0"
        local arch=$(uname -m)
        
        # 确定架构
        case $arch in
            x86_64) arch="x64" ;;
            aarch64) arch="arm64" ;;
            armv7l) arch="armv7l" ;;
            *) log_error "不支持的架构: $arch"; return 1 ;;
        esac
        
        local download_url="https://nodejs.org/dist/v${node_version}/node-v${node_version}-linux-${arch}.tar.xz"
        local install_dir="/usr/local"
        
        log_info "下载Node.js ${node_version} for ${arch}..."
        cd /tmp
        wget -q $download_url -O node.tar.xz
        
        log_info "安装Node.js..."
        sudo tar -C $install_dir --strip-components=1 -xf node.tar.xz
        
        # 清理
        rm -f node.tar.xz
    fi
    
    # 验证安装
    if command -v node &> /dev/null; then
        log_success "Node.js安装成功: $(node --version)"
        log_success "npm版本: $(npm --version)"
    else
        log_error "Node.js安装失败"
        return 1
    fi
}

# 修复前端构建配置
fix_frontend_config() {
    log_info "修复前端构建配置..."
    
    if [[ ! -d "frontend" ]]; then
        log_error "frontend目录不存在"
        return 1
    fi
    
    cd frontend
    
    # 1. 更新package.json中的engines字段
    if [[ -f "package.json" ]]; then
        log_info "更新package.json..."
        
        # 备份原文件
        cp package.json package.json.bak
        
        # 使用node脚本更新engines字段
        node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
        pkg.engines = pkg.engines || {};
        pkg.engines.node = '>=16.0.0';
        pkg.engines.npm = '>=8.0.0';
        fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
        console.log('✓ 已更新package.json engines字段');
        "
    fi
    
    # 2. 检查并修复vite.config.ts
    if [[ -f "vite.config.ts" ]]; then
        log_info "检查vite.config.ts..."
        
        # 备份原文件
        cp vite.config.ts vite.config.ts.bak
        
        # 检查是否需要添加polyfill配置
        if ! grep -q "define.*global" vite.config.ts; then
            log_info "添加全局变量polyfill配置..."
            
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
            log_success "已更新vite.config.ts"
        fi
    fi
    
    # 3. 创建或更新.npmrc文件
    log_info "配置npm镜像..."
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
    
    cd ..
    log_success "前端配置修复完成"
}

# 清理并重新安装依赖
reinstall_dependencies() {
    log_info "清理并重新安装前端依赖..."
    
    cd frontend
    
    # 清理缓存和依赖
    log_info "清理现有依赖和缓存..."
    rm -rf node_modules package-lock.json
    npm cache clean --force
    
    # 重新安装依赖
    log_info "重新安装依赖..."
    npm install
    
    if [[ $? -eq 0 ]]; then
        log_success "依赖安装成功"
    else
        log_error "依赖安装失败"
        return 1
    fi
    
    cd ..
}

# 测试构建
test_build() {
    log_info "测试前端构建..."
    
    cd frontend
    
    # 尝试构建
    npm run build
    
    if [[ $? -eq 0 ]]; then
        log_success "前端构建成功"
        
        # 检查构建结果
        if [[ -d "dist" ]]; then
            local file_count=$(find dist -type f | wc -l)
            local total_size=$(du -sh dist | cut -f1)
            log_info "构建结果: $file_count 个文件, 总大小: $total_size"
        fi
    else
        log_error "前端构建失败"
        return 1
    fi
    
    cd ..
}

# 创建环境检查脚本
create_env_check() {
    log_info "创建环境检查脚本..."
    
    cat > scripts/check-build-env.sh << 'EOF'
#!/bin/bash

# 构建环境检查脚本

echo "=== 构建环境检查 ==="

# 检查Node.js
if command -v node &> /dev/null; then
    echo "✓ Node.js: $(node --version)"
else
    echo "✗ Node.js: 未安装"
    exit 1
fi

# 检查npm
if command -v npm &> /dev/null; then
    echo "✓ npm: $(npm --version)"
else
    echo "✗ npm: 未安装"
    exit 1
fi

# 检查Node.js版本
node_version=$(node --version | sed 's/v//' | cut -d'.' -f1)
if [[ $node_version -ge 16 ]]; then
    echo "✓ Node.js版本符合要求 (>=16)"
else
    echo "✗ Node.js版本过低 (需要>=16, 当前: $(node --version))"
    exit 1
fi

# 检查前端目录
if [[ -d "frontend" ]]; then
    echo "✓ 前端目录存在"
else
    echo "✗ 前端目录不存在"
    exit 1
fi

# 检查package.json
if [[ -f "frontend/package.json" ]]; then
    echo "✓ package.json存在"
else
    echo "✗ package.json不存在"
    exit 1
fi

# 检查依赖
if [[ -d "frontend/node_modules" ]]; then
    echo "✓ 依赖已安装"
else
    echo "⚠ 依赖未安装，需要运行 npm install"
fi

echo "=== 环境检查完成 ==="
EOF

    chmod +x scripts/check-build-env.sh
    log_success "环境检查脚本创建完成"
}

# 主函数
main() {
    echo "================================"
    echo "Node.js Crypto 问题修复脚本"
    echo "================================"
    
    # 检查当前Node.js版本
    if ! check_node_version; then
        log_warn "需要更新Node.js版本"
        
        # 询问是否安装/更新Node.js
        read -p "是否安装/更新Node.js到18.x版本? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if ! install_nodejs; then
                log_error "Node.js安装失败"
                exit 1
            fi
        else
            log_error "需要Node.js 16+版本才能继续"
            exit 1
        fi
    fi
    
    # 修复前端配置
    fix_frontend_config
    
    # 重新安装依赖
    reinstall_dependencies
    
    # 测试构建
    test_build
    
    # 创建环境检查脚本
    create_env_check
    
    echo "================================"
    log_success "修复完成！"
    echo "================================"
    
    echo "现在可以正常构建前端了："
    echo "  cd frontend && npm run build"
    echo ""
    echo "或者使用部署脚本："
    echo "  ./scripts/deploy-linux.sh"
    echo ""
    echo "环境检查："
    echo "  ./scripts/check-build-env.sh"
}

# 显示帮助
show_help() {
    echo "Node.js Crypto 问题修复脚本"
    echo ""
    echo "此脚本解决以下问题："
    echo "  - TypeError: crypto.getRandomValues is not a function"
    echo "  - Node.js版本过低导致的构建失败"
    echo "  - Vite构建配置问题"
    echo ""
    echo "用法:"
    echo "  $0              # 自动修复"
    echo "  $0 --help       # 显示帮助"
    echo ""
    echo "修复内容:"
    echo "  1. 检查并更新Node.js到18.x版本"
    echo "  2. 修复vite.config.ts配置"
    echo "  3. 更新package.json engines字段"
    echo "  4. 配置npm镜像加速"
    echo "  5. 重新安装依赖"
    echo "  6. 测试构建"
}

# 参数处理
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# 执行主函数
main "$@"