#!/bin/bash

# 信息管理系统一键部署脚本
# 支持 Linux 和 macOS

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置变量
APP_NAME="info-management-system"
APP_DIR="/opt/${APP_NAME}"
SERVICE_NAME="info-management"
SERVICE_USER="info-user"
GO_VERSION="1.21.0"
NGINX_AVAILABLE=false

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "请不要使用root用户运行此脚本"
        log_info "建议创建普通用户: sudo adduser deploy"
        exit 1
    fi
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            VER=$VERSION_ID
        else
            OS="Unknown Linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        VER=$(sw_vers -productVersion)
    else
        log_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
    
    log_info "检测到操作系统: $OS $VER"
}

# 检查系统要求
check_requirements() {
    log_step "检查系统要求..."
    
    # 检查内存
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        MEMORY_MB=$((MEMORY_KB / 1024))
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        MEMORY_BYTES=$(sysctl -n hw.memsize)
        MEMORY_MB=$((MEMORY_BYTES / 1024 / 1024))
    fi
    
    if [ $MEMORY_MB -lt 512 ]; then
        log_warning "内存不足 512MB，当前: ${MEMORY_MB}MB"
        log_warning "系统可能运行缓慢"
    else
        log_success "内存检查通过: ${MEMORY_MB}MB"
    fi
    
    # 检查磁盘空间
    DISK_AVAILABLE=$(df . | tail -1 | awk '{print $4}')
    DISK_AVAILABLE_MB=$((DISK_AVAILABLE / 1024))
    
    if [ $DISK_AVAILABLE_MB -lt 1024 ]; then
        log_error "磁盘空间不足 1GB，当前可用: ${DISK_AVAILABLE_MB}MB"
        exit 1
    else
        log_success "磁盘空间检查通过: ${DISK_AVAILABLE_MB}MB 可用"
    fi
}

# 安装系统依赖
install_dependencies() {
    log_step "安装系统依赖..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            sudo apt-get update
            sudo apt-get install -y curl wget git build-essential
            
            # 检查是否可以安装nginx
            if apt-cache show nginx &> /dev/null; then
                NGINX_AVAILABLE=true
            fi
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            sudo yum update -y
            sudo yum install -y curl wget git gcc gcc-c++ make
            
            # 检查是否可以安装nginx
            if yum list nginx &> /dev/null; then
                NGINX_AVAILABLE=true
            fi
        elif command -v dnf &> /dev/null; then
            # Fedora
            sudo dnf update -y
            sudo dnf install -y curl wget git gcc gcc-c++ make
            
            # 检查是否可以安装nginx
            if dnf list nginx &> /dev/null; then
                NGINX_AVAILABLE=true
            fi
        else
            log_warning "未知的Linux发行版，请手动安装: curl wget git build-essential"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! command -v brew &> /dev/null; then
            log_info "安装Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        brew install curl wget git
        NGINX_AVAILABLE=true
    fi
    
    log_success "系统依赖安装完成"
}

# 安装Go
install_go() {
    log_step "检查Go环境..."
    
    if command -v go &> /dev/null; then
        CURRENT_GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        log_info "检测到Go版本: $CURRENT_GO_VERSION"
        
        # 简单版本比较
        if [[ "$CURRENT_GO_VERSION" < "1.19" ]]; then
            log_warning "Go版本过低，需要升级"
            NEED_INSTALL_GO=true
        else
            log_success "Go版本满足要求"
            NEED_INSTALL_GO=false
        fi
    else
        log_info "未检测到Go，需要安装"
        NEED_INSTALL_GO=true
    fi
    
    if [ "$NEED_INSTALL_GO" = true ]; then
        log_step "安装Go $GO_VERSION..."
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            ARCH=$(uname -m)
            if [ "$ARCH" = "x86_64" ]; then
                GO_ARCH="amd64"
            elif [ "$ARCH" = "aarch64" ]; then
                GO_ARCH="arm64"
            else
                log_error "不支持的架构: $ARCH"
                exit 1
            fi
            
            GO_PACKAGE="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
            
            cd /tmp
            wget "https://go.dev/dl/${GO_PACKAGE}"
            sudo tar -C /usr/local -xzf "${GO_PACKAGE}"
            
            # 设置环境变量
            echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
            export PATH=$PATH:/usr/local/go/bin
            
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install go
        fi
        
        log_success "Go安装完成"
    fi
}

# 创建应用用户和目录
setup_user_and_directories() {
    log_step "设置应用用户和目录..."
    
    # 创建应用用户（如果不存在）
    if ! id "$SERVICE_USER" &>/dev/null; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo useradd -r -s /bin/false -d "$APP_DIR" "$SERVICE_USER"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            sudo dscl . -create /Users/$SERVICE_USER
            sudo dscl . -create /Users/$SERVICE_USER UserShell /usr/bin/false
            sudo dscl . -create /Users/$SERVICE_USER RealName "Info Management Service User"
        fi
        log_success "创建用户: $SERVICE_USER"
    else
        log_info "用户已存在: $SERVICE_USER"
    fi
    
    # 创建应用目录
    sudo mkdir -p "$APP_DIR"/{build,configs,data,logs,uploads}
    sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$APP_DIR"
    sudo chmod 755 "$APP_DIR"
    
    log_success "目录设置完成: $APP_DIR"
}

# 下载或复制源码
setup_source_code() {
    log_step "设置源码..."
    
    if [ -f "go.mod" ] && [ -f "cmd/server/main.go" ]; then
        # 当前目录就是项目目录
        log_info "检测到当前目录为项目目录"
        PROJECT_DIR=$(pwd)
    else
        # 需要下载源码
        log_info "下载项目源码..."
        PROJECT_DIR="/tmp/${APP_NAME}"
        
        if [ -d "$PROJECT_DIR" ]; then
            rm -rf "$PROJECT_DIR"
        fi
        
        # 这里需要替换为实际的Git仓库地址
        git clone https://github.com/your-repo/info-management-system.git "$PROJECT_DIR"
        cd "$PROJECT_DIR"
    fi
    
    log_success "源码准备完成: $PROJECT_DIR"
}

# 编译应用
build_application() {
    log_step "编译应用..."
    
    cd "$PROJECT_DIR"
    
    # 下载依赖
    log_info "下载Go依赖..."
    go mod download
    
    # 编译
    log_info "编译应用..."
    CGO_ENABLED=1 go build -ldflags "-s -w" -o build/server cmd/server/main.go
    
    if [ ! -f "build/server" ]; then
        log_error "编译失败"
        exit 1
    fi
    
    log_success "编译完成"
}

# 安装应用文件
install_application() {
    log_step "安装应用文件..."
    
    cd "$PROJECT_DIR"
    
    # 复制二进制文件
    sudo cp build/server "$APP_DIR/build/"
    sudo chmod +x "$APP_DIR/build/server"
    
    # 复制配置文件
    if [ -f "configs/config.example.yaml" ]; then
        sudo cp configs/config.example.yaml "$APP_DIR/configs/config.yaml"
    elif [ -f "configs/config.yaml" ]; then
        sudo cp configs/config.yaml "$APP_DIR/configs/"
    else
        # 创建默认配置文件
        create_default_config
    fi
    
    # 设置权限
    sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$APP_DIR"
    
    log_success "应用文件安装完成"
}

# 创建默认配置文件
create_default_config() {
    log_info "创建默认配置文件..."
    
    sudo tee "$APP_DIR/configs/config.yaml" > /dev/null <<EOF
# 信息管理系统配置文件

server:
  port: "8080"
  mode: "release"

database:
  driver: "sqlite"
  sqlite:
    path: "data/info_system.db"
    journal_mode: "WAL"
    busy_timeout: 30000
    cache_size: -64000
    synchronous: "NORMAL"
    temp_store: "MEMORY"
    max_open_conns: 1
    max_idle_conns: 1
    conn_max_lifetime: "1h"
    conn_max_idle_time: "30m"

jwt:
  secret: "$(openssl rand -base64 32)"
  expire_time: 24

log:
  level: "info"
  format: "json"
  output: "both"
  file_path: "logs/app.log"
  max_size: 100
  max_backups: 10
  max_age: 30
  compress: true
EOF
    
    log_success "默认配置文件创建完成"
}

# 创建系统服务
create_system_service() {
    log_step "创建系统服务..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # 创建systemd服务文件
        sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" > /dev/null <<EOF
[Unit]
Description=Info Management System
Documentation=https://github.com/your-repo/info-management-system
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/build/server
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=5
Environment=GIN_MODE=release
Environment=TZ=Asia/Shanghai

# 安全设置
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR

# 资源限制
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF
        
        # 重新加载systemd配置
        sudo systemctl daemon-reload
        sudo systemctl enable "$SERVICE_NAME"
        
        log_success "Systemd服务创建完成"
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # 创建launchd服务文件
        SERVICE_PLIST="/Library/LaunchDaemons/com.${APP_NAME}.plist"
        
        sudo tee "$SERVICE_PLIST" > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.${APP_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_DIR/build/server</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$APP_DIR</string>
    <key>UserName</key>
    <string>$SERVICE_USER</string>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$APP_DIR/logs/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$APP_DIR/logs/stderr.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>GIN_MODE</key>
        <string>release</string>
    </dict>
</dict>
</plist>
EOF
        
        sudo launchctl load "$SERVICE_PLIST"
        
        log_success "Launchd服务创建完成"
    fi
}

# 配置防火墙
configure_firewall() {
    log_step "配置防火墙..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v ufw &> /dev/null; then
            # Ubuntu UFW
            sudo ufw allow 8080/tcp
            log_success "UFW防火墙规则添加完成"
        elif command -v firewall-cmd &> /dev/null; then
            # CentOS/RHEL firewalld
            sudo firewall-cmd --permanent --add-port=8080/tcp
            sudo firewall-cmd --reload
            log_success "Firewalld防火墙规则添加完成"
        else
            log_warning "未检测到防火墙管理工具，请手动开放8080端口"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "macOS防火墙配置请手动处理"
    fi
}

# 安装和配置Nginx（可选）
setup_nginx() {
    if [ "$NGINX_AVAILABLE" = false ]; then
        log_warning "Nginx不可用，跳过反向代理配置"
        return
    fi
    
    read -p "是否安装和配置Nginx反向代理? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_step "安装和配置Nginx..."
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get install -y nginx
            elif command -v yum &> /dev/null; then
                sudo yum install -y nginx
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y nginx
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install nginx
        fi
        
        # 创建Nginx配置
        NGINX_CONFIG="/etc/nginx/sites-available/${APP_NAME}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            NGINX_CONFIG="/usr/local/etc/nginx/servers/${APP_NAME}.conf"
        fi
        
        sudo tee "$NGINX_CONFIG" > /dev/null <<EOF
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:8080;
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
    client_max_body_size 100M;
    
    # 静态文件缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # 启用站点
            sudo ln -sf "$NGINX_CONFIG" "/etc/nginx/sites-enabled/"
            sudo nginx -t && sudo systemctl restart nginx
            sudo systemctl enable nginx
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            sudo nginx -t && sudo brew services restart nginx
        fi
        
        log_success "Nginx配置完成"
    fi
}

# 启动服务
start_service() {
    log_step "启动服务..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo systemctl start "$SERVICE_NAME"
        sleep 3
        
        if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
            log_success "服务启动成功"
        else
            log_error "服务启动失败"
            sudo systemctl status "$SERVICE_NAME"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        sudo launchctl start "com.${APP_NAME}"
        sleep 3
        log_success "服务启动完成"
    fi
}

# 健康检查
health_check() {
    log_step "执行健康检查..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:8080/health > /dev/null; then
            log_success "健康检查通过"
            return 0
        fi
        
        log_info "等待服务启动... ($attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    log_error "健康检查失败，服务可能未正常启动"
    return 1
}

# 显示部署结果
show_deployment_result() {
    echo
    echo "=================================="
    log_success "🎉 部署完成！"
    echo "=================================="
    echo
    log_info "服务信息:"
    echo "  - 应用目录: $APP_DIR"
    echo "  - 配置文件: $APP_DIR/configs/config.yaml"
    echo "  - 日志文件: $APP_DIR/logs/app.log"
    echo "  - 数据目录: $APP_DIR/data"
    echo
    log_info "访问地址:"
    echo "  - 本地访问: http://localhost:8080"
    echo "  - 健康检查: http://localhost:8080/health"
    echo
    log_info "默认账号:"
    echo "  - 用户名: admin"
    echo "  - 密码: admin123"
    echo
    log_info "服务管理命令:"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "  - 启动服务: sudo systemctl start $SERVICE_NAME"
        echo "  - 停止服务: sudo systemctl stop $SERVICE_NAME"
        echo "  - 重启服务: sudo systemctl restart $SERVICE_NAME"
        echo "  - 查看状态: sudo systemctl status $SERVICE_NAME"
        echo "  - 查看日志: sudo journalctl -u $SERVICE_NAME -f"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  - 启动服务: sudo launchctl start com.${APP_NAME}"
        echo "  - 停止服务: sudo launchctl stop com.${APP_NAME}"
        echo "  - 查看日志: tail -f $APP_DIR/logs/app.log"
    fi
    echo
    log_info "配置文件位置: $APP_DIR/configs/config.yaml"
    log_info "如需修改配置，请编辑配置文件后重启服务"
    echo
    log_warning "重要提示:"
    echo "  1. 请及时修改默认密码"
    echo "  2. 生产环境请配置HTTPS"
    echo "  3. 定期备份数据目录"
    echo "  4. 监控日志文件大小"
    echo
}

# 主函数
main() {
    echo "=================================="
    echo "🚀 信息管理系统一键部署脚本"
    echo "=================================="
    echo
    
    # 检查root权限
    check_root
    
    # 检测操作系统
    detect_os
    
    # 检查系统要求
    check_requirements
    
    # 安装系统依赖
    install_dependencies
    
    # 安装Go
    install_go
    
    # 设置用户和目录
    setup_user_and_directories
    
    # 设置源码
    setup_source_code
    
    # 编译应用
    build_application
    
    # 安装应用
    install_application
    
    # 创建系统服务
    create_system_service
    
    # 配置防火墙
    configure_firewall
    
    # 配置Nginx（可选）
    setup_nginx
    
    # 启动服务
    start_service
    
    # 健康检查
    if health_check; then
        show_deployment_result
    else
        log_error "部署可能存在问题，请检查日志"
        exit 1
    fi
}

# 捕获中断信号
trap 'log_error "部署被中断"; exit 1' INT TERM

# 运行主函数
main "$@"