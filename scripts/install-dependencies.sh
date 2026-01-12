#!/bin/bash

# 依赖安装脚本 - 支持多种Linux发行版

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() { echo -e "\n${BLUE}================================${NC}\n${BLUE}$1${NC}\n${BLUE}================================${NC}"; }

# 检测操作系统
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [[ -f /etc/redhat-release ]]; then
        OS="Red Hat Enterprise Linux"
        VER=$(cat /etc/redhat-release | sed 's/.*release //' | sed 's/ .*//')
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    log_info "检测到操作系统: $OS $VER"
}

# 更新包管理器
update_package_manager() {
    log_header "更新包管理器"
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            apt-get update
            ;;
        *"CentOS"*|*"Red Hat"*|*"Rocky"*|*"AlmaLinux"*)
            yum update -y
            ;;
        *"Fedora"*)
            dnf update -y
            ;;
        *"SUSE"*|*"openSUSE"*)
            zypper refresh
            ;;
        *)
            log_warning "未知的操作系统，跳过包管理器更新"
            ;;
    esac
    
    log_success "包管理器更新完成"
}

# 安装基础工具
install_basic_tools() {
    log_header "安装基础工具"
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            apt-get install -y curl wget git unzip build-essential
            ;;
        *"CentOS"*|*"Red Hat"*|*"Rocky"*|*"AlmaLinux"*)
            yum groupinstall -y "Development Tools"
            yum install -y curl wget git unzip
            ;;
        *"Fedora"*)
            dnf groupinstall -y "Development Tools"
            dnf install -y curl wget git unzip
            ;;
        *"SUSE"*|*"openSUSE"*)
            zypper install -y curl wget git unzip gcc make
            ;;
    esac
    
    log_success "基础工具安装完成"
}

# 安装Node.js
install_nodejs() {
    log_header "安装Node.js"
    
    # 检查是否已安装
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        log_info "Node.js 已安装: $node_version"
        return 0
    fi
    
    # 使用NodeSource仓库安装最新LTS版本
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            apt-get install -y nodejs
            ;;
        *"CentOS"*|*"Red Hat"*|*"Rocky"*|*"AlmaLinux"*)
            yum install -y nodejs npm
            ;;
        *"Fedora"*)
            dnf install -y nodejs npm
            ;;
        *"SUSE"*|*"openSUSE"*)
            zypper install -y nodejs npm
            ;;
    esac
    
    # 验证安装
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        log_success "Node.js 安装完成: $(node --version)"
        log_success "npm 版本: $(npm --version)"
    else
        log_error "Node.js 安装失败"
        exit 1
    fi
}

# 安装Go
install_go() {
    log_header "安装Go"
    
    # 检查是否已安装
    if command -v go &> /dev/null; then
        local go_version=$(go version)
        log_info "Go 已安装: $go_version"
        return 0
    fi
    
    # 下载并安装Go
    local go_version="1.21.5"
    local go_arch="amd64"
    
    # 检测架构
    case $(uname -m) in
        x86_64) go_arch="amd64" ;;
        aarch64|arm64) go_arch="arm64" ;;
        armv7l) go_arch="armv6l" ;;
        *) log_error "不支持的架构: $(uname -m)"; exit 1 ;;
    esac
    
    cd /tmp
    wget https://golang.org/dl/go${go_version}.linux-${go_arch}.tar.gz
    
    # 删除旧版本并安装新版本
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go${go_version}.linux-${go_arch}.tar.gz
    
    # 设置环境变量
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    echo 'export GOPATH=$HOME/go' >> /etc/profile
    echo 'export PATH=$PATH:$GOPATH/bin' >> /etc/profile
    
    # 为当前会话设置环境变量
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin
    
    # 验证安装
    if command -v go &> /dev/null; then
        log_success "Go 安装完成: $(go version)"
    else
        log_error "Go 安装失败"
        exit 1
    fi
}

# 安装PostgreSQL
install_postgresql() {
    log_header "安装PostgreSQL"
    
    # 检查是否已安装
    if command -v psql &> /dev/null; then
        log_info "PostgreSQL 已安装"
        return 0
    fi
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            apt-get install -y postgresql postgresql-contrib
            ;;
        *"CentOS"*|*"Red Hat"*|*"Rocky"*|*"AlmaLinux"*)
            yum install -y postgresql-server postgresql-contrib
            postgresql-setup initdb
            ;;
        *"Fedora"*)
            dnf install -y postgresql-server postgresql-contrib
            postgresql-setup --initdb
            ;;
        *"SUSE"*|*"openSUSE"*)
            zypper install -y postgresql-server postgresql-contrib
            ;;
    esac
    
    # 启动并启用服务
    systemctl start postgresql
    systemctl enable postgresql
    
    log_success "PostgreSQL 安装完成"
}

# 安装Redis
install_redis() {
    log_header "安装Redis"
    
    # 检查是否已安装
    if command -v redis-server &> /dev/null; then
        log_info "Redis 已安装"
        return 0
    fi
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            apt-get install -y redis-server
            ;;
        *"CentOS"*|*"Red Hat"*|*"Rocky"*|*"AlmaLinux"*)
            # 启用EPEL仓库
            yum install -y epel-release
            yum install -y redis
            ;;
        *"Fedora"*)
            dnf install -y redis
            ;;
        *"SUSE"*|*"openSUSE"*)
            zypper install -y redis
            ;;
    esac
    
    # 启动并启用服务
    systemctl start redis
    systemctl enable redis
    
    log_success "Redis 安装完成"
}

# 安装Nginx
install_nginx() {
    log_header "安装Nginx"
    
    # 检查是否已安装
    if command -v nginx &> /dev/null; then
        log_info "Nginx 已安装"
        return 0
    fi
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            apt-get install -y nginx
            ;;
        *"CentOS"*|*"Red Hat"*|*"Rocky"*|*"AlmaLinux"*)
            yum install -y nginx
            ;;
        *"Fedora"*)
            dnf install -y nginx
            ;;
        *"SUSE"*|*"openSUSE"*)
            zypper install -y nginx
            ;;
    esac
    
    # 启动并启用服务
    systemctl start nginx
    systemctl enable nginx
    
    log_success "Nginx 安装完成"
}

# 安装Docker
install_docker() {
    log_header "安装Docker"
    
    # 检查是否已安装
    if command -v docker &> /dev/null; then
        log_info "Docker 已安装"
        return 0
    fi
    
    # 使用官方安装脚本
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    
    # 启动并启用服务
    systemctl start docker
    systemctl enable docker
    
    # 将当前用户添加到docker组
    usermod -aG docker $USER
    
    log_success "Docker 安装完成"
    log_info "请重新登录以使用Docker命令"
}

# 安装Docker Compose
install_docker_compose() {
    log_header "安装Docker Compose"
    
    # 检查是否已安装
    if command -v docker-compose &> /dev/null; then
        log_info "Docker Compose 已安装"
        return 0
    fi
    
    # 下载并安装Docker Compose
    local compose_version="2.23.3"
    curl -L "https://github.com/docker/compose/releases/download/v${compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # 验证安装
    if command -v docker-compose &> /dev/null; then
        log_success "Docker Compose 安装完成: $(docker-compose --version)"
    else
        log_error "Docker Compose 安装失败"
        exit 1
    fi
}

# 配置防火墙
configure_firewall() {
    log_header "配置防火墙"
    
    # 检查防火墙类型
    if command -v ufw &> /dev/null; then
        # Ubuntu/Debian - UFW
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 8080/tcp
        ufw --force enable
        log_success "UFW 防火墙配置完成"
    elif command -v firewall-cmd &> /dev/null; then
        # CentOS/RHEL/Fedora - firewalld
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --permanent --add-port=8080/tcp
        firewall-cmd --reload
        log_success "firewalld 防火墙配置完成"
    else
        log_warning "未检测到防火墙，请手动配置"
    fi
}

# 显示安装摘要
show_summary() {
    log_header "安装摘要"
    
    echo "已安装的组件:"
    
    if command -v node &> /dev/null; then
        echo "✓ Node.js: $(node --version)"
    fi
    
    if command -v go &> /dev/null; then
        echo "✓ Go: $(go version | cut -d' ' -f3)"
    fi
    
    if command -v psql &> /dev/null; then
        echo "✓ PostgreSQL: $(psql --version | cut -d' ' -f3)"
    fi
    
    if command -v redis-server &> /dev/null; then
        echo "✓ Redis: $(redis-server --version | cut -d' ' -f3)"
    fi
    
    if command -v nginx &> /dev/null; then
        echo "✓ Nginx: $(nginx -v 2>&1 | cut -d' ' -f3)"
    fi
    
    if command -v docker &> /dev/null; then
        echo "✓ Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
    fi
    
    if command -v docker-compose &> /dev/null; then
        echo "✓ Docker Compose: $(docker-compose --version | cut -d' ' -f4 | tr -d ',')"
    fi
    
    echo ""
    echo "下一步:"
    echo "1. 重新登录以使环境变量生效"
    echo "2. 运行部署脚本: ./scripts/deploy.sh -m linux"
}

# 主函数
main() {
    # 检查是否为root用户
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0"
        exit 1
    fi
    
    log_header "信息管理系统依赖安装脚本"
    
    detect_os
    update_package_manager
    install_basic_tools
    install_nodejs
    install_go
    install_postgresql
    install_redis
    install_nginx
    install_docker
    install_docker_compose
    configure_firewall
    
    show_summary
    
    log_success "所有依赖安装完成！"
}

# 运行主函数
main "$@"