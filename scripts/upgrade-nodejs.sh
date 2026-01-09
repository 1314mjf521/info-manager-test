#!/bin/bash

# Node.js升级脚本 - 从16升级到18

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

echo "🚀 Node.js升级脚本 (16 -> 18)"
echo "================================"

# 检查当前版本
log_info "检查当前Node.js版本..."
current_version=$(node --version)
log_info "当前版本: $current_version"

# 检查是否需要升级
major_version=$(echo $current_version | sed 's/v//' | cut -d'.' -f1)
if [[ $major_version -ge 18 ]]; then
    log_success "Node.js版本已经是18+，无需升级"
    exit 0
fi

log_warn "Node.js版本过低，需要升级到18.x"

# 检查系统类型
if [[ -f /etc/debian_version ]]; then
    DISTRO="debian"
elif [[ -f /etc/redhat-release ]]; then
    DISTRO="redhat"
else
    DISTRO="unknown"
fi

log_info "检测到系统类型: $DISTRO"

# 升级Node.js
case $DISTRO in
    "debian")
        log_info "使用Debian/Ubuntu方式升级..."
        
        # 移除旧的NodeSource仓库
        sudo rm -f /etc/apt/sources.list.d/nodesource.list
        sudo rm -f /usr/share/keyrings/nodesource.gpg
        
        # 添加新的NodeSource仓库
        log_info "添加NodeSource 18.x仓库..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        
        # 安装Node.js 18
        log_info "安装Node.js 18..."
        sudo apt-get install -y nodejs
        ;;
        
    "redhat")
        log_info "使用RedHat/CentOS方式升级..."
        
        # 移除旧版本
        sudo yum remove -y nodejs npm
        
        # 添加新的NodeSource仓库
        log_info "添加NodeSource 18.x仓库..."
        curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
        
        # 安装Node.js 18
        log_info "安装Node.js 18..."
        sudo yum install -y nodejs
        ;;
        
    *)
        log_info "使用通用二进制文件方式升级..."
        
        # 下载Node.js 18二进制文件
        NODE_VERSION="18.19.0"
        ARCH=$(uname -m)
        
        case $ARCH in
            x86_64) ARCH="x64" ;;
            aarch64) ARCH="arm64" ;;
            armv7l) ARCH="armv7l" ;;
            *) log_error "不支持的架构: $ARCH"; exit 1 ;;
        esac
        
        DOWNLOAD_URL="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz"
        
        log_info "下载Node.js ${NODE_VERSION} for ${ARCH}..."
        cd /tmp
        wget -q $DOWNLOAD_URL -O node.tar.xz
        
        # 备份旧版本
        if [[ -d "/usr/local/bin/node" ]]; then
            sudo mv /usr/local/bin/node /usr/local/bin/node.bak
        fi
        if [[ -d "/usr/local/bin/npm" ]]; then
            sudo mv /usr/local/bin/npm /usr/local/bin/npm.bak
        fi
        
        # 安装新版本
        log_info "安装Node.js ${NODE_VERSION}..."
        sudo tar -C /usr/local --strip-components=1 -xf node.tar.xz
        
        # 清理
        rm -f node.tar.xz
        ;;
esac

# 验证安装
log_info "验证Node.js安装..."
if command -v node &> /dev/null; then
    new_version=$(node --version)
    new_major=$(echo $new_version | sed 's/v//' | cut -d'.' -f1)
    
    if [[ $new_major -ge 18 ]]; then
        log_success "✅ Node.js升级成功: $new_version"
        log_success "✅ npm版本: $(npm --version)"
    else
        log_error "❌ Node.js升级失败，版本仍然是: $new_version"
        exit 1
    fi
else
    log_error "❌ Node.js安装失败"
    exit 1
fi

# 配置npm
log_info "配置npm镜像..."
npm config set registry https://registry.npmmirror.com

# 清理npm缓存
log_info "清理npm缓存..."
npm cache clean --force

echo "================================"
log_success "🎉 Node.js升级完成！"
echo "================================"

echo "升级信息:"
echo "  旧版本: $current_version"
echo "  新版本: $(node --version)"
echo "  npm版本: $(npm --version)"
echo ""
echo "现在可以继续构建前端了："
echo "  cd frontend && npm install && npm run build"