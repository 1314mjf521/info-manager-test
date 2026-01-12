#!/bin/bash

# 信息管理系统 - 多平台部署脚本
# 支持 Linux, Docker, Kubernetes 部署

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="info-management-system"
VERSION="1.0.0"
BACKEND_PORT=8080
FRONTEND_PORT=3000
DB_PORT=5432
REDIS_PORT=6379

# 默认配置
DEPLOY_MODE=""
DOMAIN="localhost"
SSL_ENABLED=false
DB_PASSWORD=""
REDIS_PASSWORD=""
JWT_SECRET=""

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

log_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# 显示帮助信息
show_help() {
    cat << EOF
信息管理系统部署脚本

用法: $0 [选项]

选项:
    -m, --mode MODE         部署模式 (linux|docker|k8s)
    -d, --domain DOMAIN     域名 (默认: localhost)
    -s, --ssl               启用SSL证书
    --db-password PWD       数据库密码
    --redis-password PWD    Redis密码
    --jwt-secret SECRET     JWT密钥
    -h, --help              显示帮助信息

部署模式:
    linux       直接在Linux系统上部署
    docker      使用Docker Compose部署
    k8s         部署到Kubernetes集群

示例:
    $0 -m linux -d example.com -s
    $0 -m docker --db-password mypass123
    $0 -m k8s --jwt-secret mysecret123

EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mode)
                DEPLOY_MODE="$2"
                shift 2
                ;;
            -d|--domain)
                DOMAIN="$2"
                shift 2
                ;;
            -s|--ssl)
                SSL_ENABLED=true
                shift
                ;;
            --db-password)
                DB_PASSWORD="$2"
                shift 2
                ;;
            --redis-password)
                REDIS_PASSWORD="$2"
                shift 2
                ;;
            --jwt-secret)
                JWT_SECRET="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检查系统要求
check_requirements() {
    log_header "检查系统要求"
    
    case $DEPLOY_MODE in
        linux)
            check_linux_requirements
            ;;
        docker)
            check_docker_requirements
            ;;
        k8s)
            check_k8s_requirements
            ;;
        *)
            log_error "请指定部署模式: -m linux|docker|k8s"
            exit 1
            ;;
    esac
}

# 检查Linux部署要求
check_linux_requirements() {
    local missing_deps=()
    
    # 检查必需的命令
    for cmd in git node npm go nginx postgresql redis-server; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=($cmd)
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "缺少以下依赖: ${missing_deps[*]}"
        log_info "请先安装缺少的依赖，然后重新运行脚本"
        exit 1
    fi
    
    log_success "Linux部署要求检查通过"
}

# 检查Docker部署要求
check_docker_requirements() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装"
        exit 1
    fi
    
    # 检查Docker服务状态
    if ! docker info &> /dev/null; then
        log_error "Docker 服务未运行"
        exit 1
    fi
    
    log_success "Docker部署要求检查通过"
}

# 检查Kubernetes部署要求
check_k8s_requirements() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl 未安装"
        exit 1
    fi
    
    # 检查集群连接
    if ! kubectl cluster-info &> /dev/null; then
        log_error "无法连接到Kubernetes集群"
        exit 1
    fi
    
    log_success "Kubernetes部署要求检查通过"
}

# 生成随机密码
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# 设置默认密码
setup_passwords() {
    if [[ -z "$DB_PASSWORD" ]]; then
        DB_PASSWORD=$(generate_password)
        log_info "生成数据库密码: $DB_PASSWORD"
    fi
    
    if [[ -z "$REDIS_PASSWORD" ]]; then
        REDIS_PASSWORD=$(generate_password)
        log_info "生成Redis密码: $REDIS_PASSWORD"
    fi
    
    if [[ -z "$JWT_SECRET" ]]; then
        JWT_SECRET=$(generate_password)
        log_info "生成JWT密钥: $JWT_SECRET"
    fi
}

# 构建前端
build_frontend() {
    log_header "构建前端应用"
    
    cd frontend
    
    # 安装依赖
    log_info "安装前端依赖..."
    npm ci --production=false
    
    # 构建
    log_info "构建前端应用..."
    npm run build
    
    cd ..
    log_success "前端构建完成"
}

# 构建后端
build_backend() {
    log_header "构建后端应用"
    
    # 设置Go环境
    export CGO_ENABLED=0
    export GOOS=linux
    export GOARCH=amd64
    
    # 构建
    log_info "构建后端应用..."
    go mod tidy
    go build -o bin/server ./cmd/server
    
    log_success "后端构建完成"
}

# Linux部署
deploy_linux() {
    log_header "Linux系统部署"
    
    # 构建应用
    build_frontend
    build_backend
    
    # 调用Linux部署脚本
    bash scripts/deploy-linux.sh \
        --domain "$DOMAIN" \
        --db-password "$DB_PASSWORD" \
        --redis-password "$REDIS_PASSWORD" \
        --jwt-secret "$JWT_SECRET" \
        $([ "$SSL_ENABLED" = true ] && echo "--ssl")
}

# Docker部署
deploy_docker() {
    log_header "Docker部署"
    
    # 创建环境变量文件
    create_docker_env
    
    # 构建和启动服务
    log_info "构建Docker镜像..."
    docker-compose build
    
    log_info "启动服务..."
    docker-compose up -d
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 10
    
    # 检查服务状态
    check_docker_services
    
    log_success "Docker部署完成"
    show_docker_info
}

# 创建Docker环境变量文件
create_docker_env() {
    cat > .env << EOF
# 应用配置
PROJECT_NAME=$PROJECT_NAME
VERSION=$VERSION
DOMAIN=$DOMAIN

# 端口配置
BACKEND_PORT=$BACKEND_PORT
FRONTEND_PORT=$FRONTEND_PORT
DB_PORT=$DB_PORT
REDIS_PORT=$REDIS_PORT

# 数据库配置
POSTGRES_DB=$PROJECT_NAME
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$DB_PASSWORD

# Redis配置
REDIS_PASSWORD=$REDIS_PASSWORD

# JWT配置
JWT_SECRET=$JWT_SECRET

# SSL配置
SSL_ENABLED=$SSL_ENABLED
EOF
    
    log_success "环境变量文件创建完成"
}

# 检查Docker服务状态
check_docker_services() {
    local services=("app" "postgres" "redis" "nginx")
    
    for service in "${services[@]}"; do
        if docker-compose ps $service | grep -q "Up"; then
            log_success "$service 服务运行正常"
        else
            log_error "$service 服务启动失败"
            docker-compose logs $service
        fi
    done
}

# 显示Docker部署信息
show_docker_info() {
    log_header "部署信息"
    echo "应用地址: http://$DOMAIN"
    echo "API地址: http://$DOMAIN/api"
    echo "数据库密码: $DB_PASSWORD"
    echo "Redis密码: $REDIS_PASSWORD"
    echo ""
    echo "管理命令:"
    echo "  查看日志: docker-compose logs -f"
    echo "  重启服务: docker-compose restart"
    echo "  停止服务: docker-compose down"
}

# Kubernetes部署
deploy_k8s() {
    log_header "Kubernetes部署"
    
    # 构建Docker镜像
    build_docker_image
    
    # 创建命名空间
    kubectl create namespace $PROJECT_NAME --dry-run=client -o yaml | kubectl apply -f -
    
    # 创建配置
    create_k8s_configs
    
    # 部署应用
    log_info "部署到Kubernetes..."
    kubectl apply -f k8s/ -n $PROJECT_NAME
    
    # 等待部署完成
    log_info "等待部署完成..."
    kubectl wait --for=condition=available --timeout=300s deployment/app -n $PROJECT_NAME
    
    log_success "Kubernetes部署完成"
    show_k8s_info
}

# 构建Docker镜像
build_docker_image() {
    log_info "构建Docker镜像..."
    docker build -t $PROJECT_NAME:$VERSION .
    docker tag $PROJECT_NAME:$VERSION $PROJECT_NAME:latest
}

# 创建Kubernetes配置
create_k8s_configs() {
    # 创建Secret
    kubectl create secret generic app-secrets \
        --from-literal=db-password="$DB_PASSWORD" \
        --from-literal=redis-password="$REDIS_PASSWORD" \
        --from-literal=jwt-secret="$JWT_SECRET" \
        --dry-run=client -o yaml | kubectl apply -f - -n $PROJECT_NAME
    
    log_success "Kubernetes配置创建完成"
}

# 显示Kubernetes部署信息
show_k8s_info() {
    log_header "部署信息"
    
    # 获取服务信息
    kubectl get services -n $PROJECT_NAME
    kubectl get pods -n $PROJECT_NAME
    
    echo ""
    echo "管理命令:"
    echo "  查看Pod: kubectl get pods -n $PROJECT_NAME"
    echo "  查看日志: kubectl logs -f deployment/app -n $PROJECT_NAME"
    echo "  删除部署: kubectl delete namespace $PROJECT_NAME"
}

# 主函数
main() {
    log_header "信息管理系统部署脚本"
    
    # 解析参数
    parse_args "$@"
    
    # 检查要求
    check_requirements
    
    # 设置密码
    setup_passwords
    
    # 根据模式部署
    case $DEPLOY_MODE in
        linux)
            deploy_linux
            ;;
        docker)
            deploy_docker
            ;;
        k8s)
            deploy_k8s
            ;;
    esac
    
    log_success "部署完成！"
}

# 运行主函数
main "$@"