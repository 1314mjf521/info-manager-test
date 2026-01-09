#!/bin/bash

# Linux服务器部署脚本
# 支持Ubuntu/CentOS/Debian等主流Linux发行版

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置参数
MODE=${1:-"prod"}                    # 部署模式: dev, prod, test
BACKEND_PORT=${2:-8080}              # 后端端口
FRONTEND_PORT=${3:-3000}             # 前端端口 (nginx代理)
DOMAIN=${4:-"localhost"}             # 域名
SSL_ENABLED=${5:-false}              # 是否启用SSL

# 项目配置
PROJECT_NAME="info-management-system"
SERVICE_USER="app"
APP_DIR="/opt/${PROJECT_NAME}"
LOG_DIR="/var/log/${PROJECT_NAME}"
CONFIG_DIR="/etc/${PROJECT_NAME}"
SYSTEMD_DIR="/etc/systemd/system"

# 日志函数
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

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0"
        exit 1
    fi
}

# 检测Linux发行版
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    log_info "检测到操作系统: $OS $VER"
}

# 安装系统依赖
install_system_deps() {
    log_header "安装系统依赖"
    
    # 更新包管理器
    if command -v apt-get &> /dev/null; then
        log_info "使用apt包管理器..."
        apt-get update
        apt-get install -y curl wget git build-essential nginx supervisor
    elif command -v yum &> /dev/null; then
        log_info "使用yum包管理器..."
        yum update -y
        yum install -y curl wget git gcc gcc-c++ make nginx supervisor
    elif command -v dnf &> /dev/null; then
        log_info "使用dnf包管理器..."
        dnf update -y
        dnf install -y curl wget git gcc gcc-c++ make nginx supervisor
    else
        log_error "不支持的包管理器"
        exit 1
    fi
    
    log_success "系统依赖安装完成"
}

# 安装Go
install_go() {
    log_header "安装Go环境"
    
    # 检查Go是否已安装
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}')
        log_info "Go已安装: $GO_VERSION"
        return 0
    fi
    
    # 下载并安装Go
    GO_VERSION="1.21.5"
    GO_ARCH="linux-amd64"
    GO_URL="https://golang.org/dl/go${GO_VERSION}.${GO_ARCH}.tar.gz"
    
    log_info "下载Go ${GO_VERSION}..."
    cd /tmp
    wget -q $GO_URL -O go.tar.gz
    
    log_info "安装Go..."
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go.tar.gz
    
    # 设置环境变量
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    echo 'export GOPATH=/opt/go' >> /etc/profile
    echo 'export GOPROXY=https://goproxy.cn,direct' >> /etc/profile
    
    # 立即生效
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=/opt/go
    export GOPROXY=https://goproxy.cn,direct
    
    # 创建GOPATH目录
    mkdir -p /opt/go
    
    log_success "Go安装完成: $(go version)"
}

# 安装Node.js
install_nodejs() {
    log_header "安装Node.js环境"
    
    # 检查Node.js是否已安装
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        NODE_MAJOR=$(echo $NODE_VERSION | sed 's/v//' | cut -d'.' -f1)
        log_info "Node.js已安装: $NODE_VERSION"
        
        # 检查版本是否足够新
        if [[ $NODE_MAJOR -lt 16 ]]; then
            log_warn "Node.js版本过低，需要升级到16+"
        else
            log_success "Node.js版本符合要求"
            return 0
        fi
    fi
    
    # 使用NodeSource仓库安装Node.js 18.x
    log_info "添加NodeSource仓库..."
    
    if command -v apt-get &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    elif command -v yum &> /dev/null; then
        curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
        yum install -y nodejs
    elif command -v dnf &> /dev/null; then
        curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
        dnf install -y nodejs
    else
        # 使用二进制安装
        log_info "使用二进制文件安装Node.js..."
        NODE_VERSION="18.19.0"
        ARCH=$(uname -m)
        
        case $ARCH in
            x86_64) ARCH="x64" ;;
            aarch64) ARCH="arm64" ;;
            *) log_error "不支持的架构: $ARCH"; return 1 ;;
        esac
        
        cd /tmp
        wget -q "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz"
        tar -C /usr/local --strip-components=1 -xf "node-v${NODE_VERSION}-linux-${ARCH}.tar.xz"
        rm -f "node-v${NODE_VERSION}-linux-${ARCH}.tar.xz"
    fi
    
    # 设置npm镜像
    npm config set registry https://registry.npmmirror.com
    
    log_success "Node.js安装完成: $(node --version)"
    log_success "npm版本: $(npm --version)"
}

# 创建应用用户
create_app_user() {
    log_header "创建应用用户"
    
    if id "$SERVICE_USER" &>/dev/null; then
        log_info "用户 $SERVICE_USER 已存在"
    else
        log_info "创建用户 $SERVICE_USER..."
        useradd -r -s /bin/false -d $APP_DIR $SERVICE_USER
        log_success "用户 $SERVICE_USER 创建完成"
    fi
}

# 创建目录结构
create_directories() {
    log_header "创建目录结构"
    
    # 创建应用目录
    mkdir -p $APP_DIR
    mkdir -p $LOG_DIR
    mkdir -p $CONFIG_DIR
    mkdir -p $APP_DIR/bin
    mkdir -p $APP_DIR/static
    mkdir -p $APP_DIR/uploads
    
    # 设置权限
    chown -R $SERVICE_USER:$SERVICE_USER $APP_DIR
    chown -R $SERVICE_USER:$SERVICE_USER $LOG_DIR
    chmod 755 $APP_DIR
    chmod 755 $LOG_DIR
    
    log_success "目录结构创建完成"
}

# 编译后端应用
build_backend() {
    log_header "编译后端应用"
    
    # 确保在项目根目录
    if [[ ! -f "go.mod" ]]; then
        log_error "未找到go.mod文件，请确保在项目根目录运行此脚本"
        exit 1
    fi
    
    if [[ ! -d "cmd/server" ]]; then
        log_error "未找到cmd/server目录，请检查项目结构"
        exit 1
    fi
    
    log_info "编译Go应用..."
    
    # 设置Go环境
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=/opt/go
    export GOPROXY=https://goproxy.cn,direct
    
    # 编译应用
    go mod tidy
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o $APP_DIR/bin/$PROJECT_NAME ./cmd/server
    
    # 检查编译结果
    if [[ ! -f "$APP_DIR/bin/$PROJECT_NAME" ]]; then
        log_error "编译失败，未生成可执行文件"
        exit 1
    fi
    
    # 设置执行权限
    chmod +x $APP_DIR/bin/$PROJECT_NAME
    chown $SERVICE_USER:$SERVICE_USER $APP_DIR/bin/$PROJECT_NAME
    
    log_success "后端编译完成"
}

# 构建前端应用
build_frontend() {
    log_header "构建前端应用"
    
    if [[ ! -d "frontend" ]]; then
        log_warn "前端目录不存在，跳过前端构建"
        return 0
    fi
    
    cd frontend
    
    # 修复vite配置以解决crypto.getRandomValues问题
    log_info "修复前端配置..."
    if [[ -f "vite.config.ts" ]]; then
        # 备份原配置
        cp vite.config.ts vite.config.ts.backup
        
        # 创建修复后的配置
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
        log_success "vite.config.ts已修复"
    fi
    
    # 清理旧的依赖和缓存
    log_info "清理依赖和缓存..."
    rm -rf node_modules package-lock.json
    npm cache clean --force
    
    # 配置npm镜像
    npm config set registry https://registry.npmmirror.com
    
    log_info "安装前端依赖..."
    # 直接使用npm install，因为我们删除了package-lock.json
    npm install
    
    if [[ $? -ne 0 ]]; then
        log_error "前端依赖安装失败"
        cd ..
        return 1
    fi
    
    log_info "构建前端应用..."
    npm run build
    
    if [[ $? -ne 0 ]]; then
        log_error "前端构建失败"
        cd ..
        return 1
    fi
    
    # 复制构建文件到静态目录
    if [[ -d "dist" ]]; then
        cp -r dist/* $APP_DIR/static/
        chown -R $SERVICE_USER:$SERVICE_USER $APP_DIR/static
        
        # 显示构建统计
        local file_count=$(find dist -type f | wc -l)
        local total_size=$(du -sh dist | cut -f1)
        log_success "前端构建完成: $file_count 个文件, 总大小: $total_size"
    else
        log_error "前端构建失败，未找到dist目录"
        cd ..
        return 1
    fi
    
    cd ..
}

# 创建配置文件
create_config() {
    log_header "创建配置文件"
    
    # 创建应用配置
    cat > $CONFIG_DIR/config.yaml << EOF
# 应用配置
app:
  name: "$PROJECT_NAME"
  mode: "$MODE"
  port: $BACKEND_PORT
  
# 数据库配置
database:
  type: "sqlite"
  dsn: "$APP_DIR/data.db"
  
# 日志配置
log:
  level: "info"
  file: "$LOG_DIR/app.log"
  max_size: 100
  max_backups: 5
  
# 文件上传配置
upload:
  path: "$APP_DIR/uploads"
  max_size: 10485760  # 10MB
  
# 安全配置
security:
  jwt_secret: "$(openssl rand -base64 32)"
  cors_origins: ["http://$DOMAIN", "https://$DOMAIN"]
EOF

    chown $SERVICE_USER:$SERVICE_USER $CONFIG_DIR/config.yaml
    chmod 600 $CONFIG_DIR/config.yaml
    
    log_success "配置文件创建完成"
}

# 创建systemd服务
create_systemd_service() {
    log_header "创建systemd服务"
    
    cat > $SYSTEMD_DIR/$PROJECT_NAME.service << EOF
[Unit]
Description=$PROJECT_NAME
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/bin/$PROJECT_NAME -config $CONFIG_DIR/config.yaml
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$PROJECT_NAME

# 环境变量
Environment=GIN_MODE=release
Environment=PORT=$BACKEND_PORT

# 安全设置
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR $LOG_DIR

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd
    systemctl daemon-reload
    systemctl enable $PROJECT_NAME
    
    log_success "systemd服务创建完成"
}

# 配置Nginx
configure_nginx() {
    log_header "配置Nginx"
    
    # 检测Nginx配置目录结构
    if [[ -d /etc/nginx/sites-available ]]; then
        # Debian/Ubuntu风格
        NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
        NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
        USE_SITES_STRUCTURE=true
    else
        # CentOS/RHEL风格
        NGINX_SITES_AVAILABLE="/etc/nginx/conf.d"
        NGINX_SITES_ENABLED="/etc/nginx/conf.d"
        USE_SITES_STRUCTURE=false
    fi
    
    # 备份原配置
    if [[ -f $NGINX_SITES_AVAILABLE/default ]] && [[ "$USE_SITES_STRUCTURE" == "true" ]]; then
        cp $NGINX_SITES_AVAILABLE/default $NGINX_SITES_AVAILABLE/default.backup
    fi
    
    # 设置配置文件名
    if [[ "$USE_SITES_STRUCTURE" == "true" ]]; then
        CONFIG_FILE="$NGINX_SITES_AVAILABLE/$PROJECT_NAME"
    else
        CONFIG_FILE="$NGINX_SITES_AVAILABLE/$PROJECT_NAME.conf"
    fi
    
    # 创建站点配置
    cat > "$CONFIG_FILE" << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    # 静态文件
    location / {
        root $APP_DIR/static;
        try_files \$uri \$uri/ /index.html;
        
        # 缓存设置
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API代理
    location /api/ {
        proxy_pass http://127.0.0.1:$BACKEND_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # 文件上传大小限制
    client_max_body_size 10M;
    
    # 日志
    access_log $LOG_DIR/nginx_access.log;
    error_log $LOG_DIR/nginx_error.log;
}
EOF

    # 启用站点（仅在使用sites结构时）
    if [[ "$USE_SITES_STRUCTURE" == "true" ]]; then
        ln -sf $NGINX_SITES_AVAILABLE/$PROJECT_NAME $NGINX_SITES_ENABLED/
        # 删除默认站点
        rm -f $NGINX_SITES_ENABLED/default
    fi
    
    # 测试配置
    nginx -t
    
    log_success "Nginx配置完成"
}

# 配置SSL (可选)
configure_ssl() {
    if [[ "$SSL_ENABLED" != "true" ]]; then
        return 0
    fi
    
    log_header "配置SSL证书"
    
    # 安装Certbot
    if command -v apt-get &> /dev/null; then
        apt-get install -y certbot python3-certbot-nginx
    elif command -v yum &> /dev/null; then
        yum install -y certbot python3-certbot-nginx
    fi
    
    # 获取SSL证书
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN
    
    log_success "SSL证书配置完成"
}

# 配置防火墙
configure_firewall() {
    log_header "配置防火墙"
    
    # UFW (Ubuntu)
    if command -v ufw &> /dev/null; then
        ufw --force enable
        ufw allow ssh
        ufw allow 80/tcp
        ufw allow 443/tcp
        log_success "UFW防火墙配置完成"
    # Firewalld (CentOS/RHEL)
    elif command -v firewall-cmd &> /dev/null; then
        systemctl enable firewalld
        systemctl start firewalld
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
        log_success "Firewalld防火墙配置完成"
    else
        log_warn "未检测到防火墙，请手动配置"
    fi
}

# 启动服务
start_services() {
    log_header "启动服务"
    
    # 启动后端服务
    systemctl start $PROJECT_NAME
    systemctl status $PROJECT_NAME --no-pager
    
    # 启动Nginx
    systemctl enable nginx
    systemctl restart nginx
    systemctl status nginx --no-pager
    
    log_success "服务启动完成"
}

# 验证部署
verify_deployment() {
    log_header "验证部署"
    
    # 检查后端服务
    if systemctl is-active --quiet $PROJECT_NAME; then
        log_success "✓ 后端服务运行正常"
    else
        log_error "✗ 后端服务启动失败"
        systemctl status $PROJECT_NAME --no-pager
        return 1
    fi
    
    # 检查Nginx
    if systemctl is-active --quiet nginx; then
        log_success "✓ Nginx运行正常"
    else
        log_error "✗ Nginx启动失败"
        systemctl status nginx --no-pager
        return 1
    fi
    
    # 检查端口
    if netstat -tlnp | grep -q ":$BACKEND_PORT "; then
        log_success "✓ 后端端口 $BACKEND_PORT 监听正常"
    else
        log_error "✗ 后端端口 $BACKEND_PORT 未监听"
        return 1
    fi
    
    if netstat -tlnp | grep -q ":80 "; then
        log_success "✓ HTTP端口 80 监听正常"
    else
        log_error "✗ HTTP端口 80 未监听"
        return 1
    fi
    
    # 测试HTTP请求
    if curl -s -o /dev/null -w "%{http_code}" http://localhost/api/v1/health | grep -q "200"; then
        log_success "✓ API健康检查通过"
    else
        log_error "✗ API健康检查失败"
        return 1
    fi
    
    return 0
}

# 显示部署信息
show_deployment_info() {
    log_header "部署完成"
    
    echo -e "${GREEN}🎉 部署成功完成！${NC}"
    echo ""
    echo -e "${CYAN}访问信息:${NC}"
    echo -e "  网站地址: http://$DOMAIN"
    if [[ "$SSL_ENABLED" == "true" ]]; then
        echo -e "  HTTPS地址: https://$DOMAIN"
    fi
    echo -e "  API地址: http://$DOMAIN/api/v1"
    echo -e "  健康检查: http://$DOMAIN/api/v1/health"
    echo ""
    echo -e "${CYAN}服务管理:${NC}"
    echo -e "  启动服务: systemctl start $PROJECT_NAME"
    echo -e "  停止服务: systemctl stop $PROJECT_NAME"
    echo -e "  重启服务: systemctl restart $PROJECT_NAME"
    echo -e "  查看状态: systemctl status $PROJECT_NAME"
    echo -e "  查看日志: journalctl -u $PROJECT_NAME -f"
    echo ""
    echo -e "${CYAN}文件位置:${NC}"
    echo -e "  应用目录: $APP_DIR"
    echo -e "  配置文件: $CONFIG_DIR/config.yaml"
    echo -e "  日志目录: $LOG_DIR"
    echo -e "  静态文件: $APP_DIR/static"
    echo ""
    echo -e "${CYAN}Nginx管理:${NC}"
    echo -e "  重启Nginx: systemctl restart nginx"
    echo -e "  测试配置: nginx -t"
    echo -e "  查看日志: tail -f $LOG_DIR/nginx_access.log"
}

# 清理函数
cleanup() {
    log_info "清理临时文件..."
    rm -f /tmp/go.tar.gz
}

# 主函数
main() {
    log_header "Linux服务器部署脚本"
    log_info "模式: $MODE"
    log_info "后端端口: $BACKEND_PORT"
    log_info "前端端口: $FRONTEND_PORT"
    log_info "域名: $DOMAIN"
    log_info "SSL: $SSL_ENABLED"
    
    # 检查权限
    check_root
    
    # 检测系统
    detect_os
    
    # 安装依赖
    install_system_deps
    install_go
    install_nodejs
    
    # 创建用户和目录
    create_app_user
    create_directories
    
    # 构建应用
    build_backend
    build_frontend
    
    # 配置系统
    create_config
    create_systemd_service
    configure_nginx
    configure_ssl
    configure_firewall
    
    # 启动服务
    start_services
    
    # 验证部署
    if verify_deployment; then
        show_deployment_info
    else
        log_error "部署验证失败，请检查日志"
        exit 1
    fi
    
    # 清理
    cleanup
    
    log_success "部署脚本执行完成"
}

# 显示帮助
show_help() {
    echo "Linux服务器部署脚本"
    echo ""
    echo "用法: $0 [模式] [后端端口] [前端端口] [域名] [SSL启用]"
    echo ""
    echo "参数:"
    echo "  模式        部署模式 (dev|prod|test)，默认: prod"
    echo "  后端端口    后端服务端口，默认: 8080"
    echo "  前端端口    前端服务端口，默认: 3000"
    echo "  域名        服务器域名，默认: localhost"
    echo "  SSL启用     是否启用SSL (true|false)，默认: false"
    echo ""
    echo "示例:"
    echo "  $0                                    # 使用默认配置"
    echo "  $0 prod 8080 3000 example.com true   # 生产环境，启用SSL"
    echo "  $0 dev 8081 3001 dev.example.com     # 开发环境"
    echo ""
    echo "注意:"
    echo "  - 需要root权限运行"
    echo "  - 确保域名已解析到服务器IP"
    echo "  - SSL证书需要域名验证"
}

# 参数处理
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# 执行主函数
main "$@"