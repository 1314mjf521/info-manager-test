#!/bin/bash

# Docker容器化部署脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置参数
MODE=${1:-"prod"}
DOMAIN=${2:-"localhost"}
SSL_ENABLED=${3:-false}

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

# 检查Docker环境
check_docker() {
    log_header "检查Docker环境"
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        log_info "请访问 https://docs.docker.com/get-docker/ 安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装"
        log_info "请访问 https://docs.docker.com/compose/install/ 安装Docker Compose"
        exit 1
    fi
    
    # 检查Docker服务状态
    if ! docker info &> /dev/null; then
        log_error "Docker服务未运行"
        log_info "请启动Docker服务: sudo systemctl start docker"
        exit 1
    fi
    
    log_success "Docker环境检查通过"
    log_info "Docker版本: $(docker --version)"
    log_info "Docker Compose版本: $(docker-compose --version)"
}

# 创建必要目录
create_directories() {
    log_header "创建目录结构"
    
    mkdir -p data logs uploads configs nginx/conf.d ssl
    
    # 设置权限
    chmod 755 data logs uploads
    
    log_success "目录结构创建完成"
}

# 创建Nginx配置
create_nginx_config() {
    log_header "创建Nginx配置"
    
    # 主配置文件
    cat > nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    # 基本设置
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 10M;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # 包含站点配置
    include /etc/nginx/conf.d/*.conf;
}
EOF

    # 站点配置
    if [[ "$SSL_ENABLED" == "true" ]]; then
        create_ssl_config
    else
        create_http_config
    fi
    
    log_success "Nginx配置创建完成"
}

# 创建HTTP配置
create_http_config() {
    cat > nginx/conf.d/default.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    # 静态文件代理到应用容器
    location / {
        proxy_pass http://app:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # API代理
    location /api/ {
        proxy_pass http://app:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # 健康检查
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF
}

# 创建SSL配置
create_ssl_config() {
    cat > nginx/conf.d/default.conf << EOF
# HTTP重定向到HTTPS
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS配置
server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    # SSL证书配置
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    # SSL安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # 安全头
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # 应用代理
    location / {
        proxy_pass http://app:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        
        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # API代理
    location /api/ {
        proxy_pass http://app:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
}

# 创建应用配置
create_app_config() {
    log_header "创建应用配置"
    
    cat > configs/config.yaml << EOF
# 应用配置
app:
  name: "info-management-system"
  mode: "$MODE"
  port: 8080
  
# 数据库配置
database:
  type: "postgres"
  host: "postgres"
  port: 5432
  name: "info_management"
  user: "postgres"
  password: "postgres123"
  
# Redis配置
redis:
  host: "redis"
  port: 6379
  password: "redis123"
  db: 0
  
# 日志配置
log:
  level: "info"
  file: "/app/logs/app.log"
  max_size: 100
  max_backups: 5
  
# 文件上传配置
upload:
  path: "/app/uploads"
  max_size: 10485760  # 10MB
  
# 安全配置
security:
  jwt_secret: "$(openssl rand -base64 32)"
  cors_origins: ["http://$DOMAIN", "https://$DOMAIN"]
EOF

    log_success "应用配置创建完成"
}

# 创建数据库初始化脚本
create_db_init() {
    log_header "创建数据库初始化脚本"
    
    mkdir -p scripts
    
    cat > scripts/init.sql << 'EOF'
-- 创建数据库
CREATE DATABASE IF NOT EXISTS info_management;

-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 插入默认管理员用户
INSERT INTO users (username, email, password_hash, role) 
VALUES ('admin', 'admin@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin')
ON CONFLICT (username) DO NOTHING;
EOF

    log_success "数据库初始化脚本创建完成"
}

# 创建环境文件
create_env_file() {
    log_header "创建环境配置文件"
    
    cat > .env << EOF
# 应用配置
COMPOSE_PROJECT_NAME=info-management-system
MODE=$MODE
DOMAIN=$DOMAIN

# 数据库配置
POSTGRES_DB=info_management
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123

# Redis配置
REDIS_PASSWORD=redis123

# 应用端口
APP_PORT=8080
HTTP_PORT=80
HTTPS_PORT=443
EOF

    log_success "环境配置文件创建完成"
}

# 构建和启动服务
deploy_services() {
    log_header "构建和启动服务"
    
    # 停止现有服务
    log_info "停止现有服务..."
    docker-compose down --remove-orphans
    
    # 构建镜像
    log_info "构建应用镜像..."
    docker-compose build --no-cache
    
    # 启动服务
    log_info "启动服务..."
    docker-compose up -d
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 30
    
    log_success "服务启动完成"
}

# 验证部署
verify_deployment() {
    log_header "验证部署"
    
    # 检查容器状态
    log_info "检查容器状态..."
    docker-compose ps
    
    # 检查应用健康状态
    local max_retries=30
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        if curl -s -f http://localhost/api/v1/health > /dev/null; then
            log_success "✓ 应用健康检查通过"
            break
        else
            log_info "等待应用启动... ($((retry_count + 1))/$max_retries)"
            sleep 5
            ((retry_count++))
        fi
    done
    
    if [[ $retry_count -eq $max_retries ]]; then
        log_error "✗ 应用健康检查失败"
        log_info "查看应用日志:"
        docker-compose logs app
        return 1
    fi
    
    # 检查数据库连接
    if docker-compose exec -T postgres pg_isready -U postgres > /dev/null; then
        log_success "✓ 数据库连接正常"
    else
        log_error "✗ 数据库连接失败"
        return 1
    fi
    
    # 检查Redis连接
    if docker-compose exec -T redis redis-cli ping > /dev/null; then
        log_success "✓ Redis连接正常"
    else
        log_error "✗ Redis连接失败"
        return 1
    fi
    
    return 0
}

# 显示部署信息
show_deployment_info() {
    log_header "部署完成"
    
    echo -e "${GREEN}🎉 Docker部署成功完成！${NC}"
    echo ""
    echo -e "${CYAN}访问信息:${NC}"
    echo -e "  网站地址: http://$DOMAIN"
    if [[ "$SSL_ENABLED" == "true" ]]; then
        echo -e "  HTTPS地址: https://$DOMAIN"
    fi
    echo -e "  API地址: http://$DOMAIN/api/v1"
    echo -e "  健康检查: http://$DOMAIN/api/v1/health"
    echo ""
    echo -e "${CYAN}容器管理:${NC}"
    echo -e "  查看状态: docker-compose ps"
    echo -e "  查看日志: docker-compose logs -f"
    echo -e "  重启服务: docker-compose restart"
    echo -e "  停止服务: docker-compose down"
    echo -e "  更新服务: docker-compose up -d --build"
    echo ""
    echo -e "${CYAN}数据库管理:${NC}"
    echo -e "  连接数据库: docker-compose exec postgres psql -U postgres -d info_management"
    echo -e "  备份数据库: docker-compose exec postgres pg_dump -U postgres info_management > backup.sql"
    echo -e "  恢复数据库: docker-compose exec -T postgres psql -U postgres -d info_management < backup.sql"
    echo ""
    echo -e "${CYAN}监控命令:${NC}"
    echo -e "  系统资源: docker stats"
    echo -e "  容器详情: docker-compose top"
    echo -e "  网络信息: docker network ls"
    echo ""
    echo -e "${CYAN}默认账号:${NC}"
    echo -e "  用户名: admin"
    echo -e "  密码: admin123"
}

# 主函数
main() {
    log_header "Docker容器化部署脚本"
    log_info "模式: $MODE"
    log_info "域名: $DOMAIN"
    log_info "SSL: $SSL_ENABLED"
    
    # 检查Docker环境
    check_docker
    
    # 创建目录和配置
    create_directories
    create_nginx_config
    create_app_config
    create_db_init
    create_env_file
    
    # 部署服务
    deploy_services
    
    # 验证部署
    if verify_deployment; then
        show_deployment_info
    else
        log_error "部署验证失败，请检查日志"
        docker-compose logs
        exit 1
    fi
    
    log_success "Docker部署脚本执行完成"
}

# 显示帮助
show_help() {
    echo "Docker容器化部署脚本"
    echo ""
    echo "用法: $0 [模式] [域名] [SSL启用]"
    echo ""
    echo "参数:"
    echo "  模式      部署模式 (dev|prod|test)，默认: prod"
    echo "  域名      服务器域名，默认: localhost"
    echo "  SSL启用   是否启用SSL (true|false)，默认: false"
    echo ""
    echo "示例:"
    echo "  $0                              # 使用默认配置"
    echo "  $0 prod example.com true        # 生产环境，启用SSL"
    echo "  $0 dev dev.example.com          # 开发环境"
    echo ""
    echo "注意:"
    echo "  - 需要安装Docker和Docker Compose"
    echo "  - 确保端口80和443未被占用"
    echo "  - SSL需要提供证书文件"
}

# 参数处理
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# 执行主函数
main "$@"