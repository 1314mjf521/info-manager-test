#!/bin/bash

# 信息管理系统部署脚本
# 使用方法: ./scripts/deploy.sh [环境] [操作] [选项]
# 环境: dev, staging, prod
# 操作: build, up, down, restart, logs, status, backup, cleanup
# 选项: --with-elasticsearch (启用日志收集)

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查Docker和Docker Compose
check_requirements() {
    log_info "检查系统要求..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    log_success "系统要求检查通过"
}

# 创建必要的目录
create_directories() {
    log_info "创建必要的目录..."
    
    mkdir -p logs/nginx
    mkdir -p deployments/nginx/ssl
    mkdir -p data/mysql
    mkdir -p data/redis
    mkdir -p data/prometheus
    mkdir -p data/grafana
    
    log_success "目录创建完成"
}

# 设置权限
set_permissions() {
    log_info "设置文件权限..."
    
    # 设置日志目录权限
    chmod -R 755 logs/
    
    # 设置配置文件权限
    chmod -R 644 deployments/
    
    log_success "权限设置完成"
}

# 构建镜像
build_images() {
    log_info "构建应用镜像..."
    
    if [ "$with_elasticsearch" = true ]; then
        docker-compose -f docker-compose.yml -f docker-compose.elasticsearch.yml build --no-cache
    else
        docker-compose build --no-cache
    fi
    
    log_success "镜像构建完成"
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    if [ "$with_elasticsearch" = true ]; then
        # 启用Elasticsearch时的启动顺序
        log_info "启动基础服务（包含Elasticsearch）..."
        docker-compose -f docker-compose.yml -f docker-compose.elasticsearch.yml up -d mysql redis elasticsearch
        
        # 等待Elasticsearch启动
        log_info "等待Elasticsearch启动..."
        sleep 60
        
        # 启动应用服务
        docker-compose -f docker-compose.yml -f docker-compose.elasticsearch.yml up -d app
        
        # 等待应用启动
        log_info "等待应用启动..."
        sleep 20
        
        # 启动其他服务
        docker-compose -f docker-compose.yml -f docker-compose.elasticsearch.yml up -d nginx prometheus grafana kibana filebeat
        
        log_success "所有服务启动完成（包含日志收集系统）"
    else
        # 标准启动顺序
        log_info "启动基础服务..."
        docker-compose up -d mysql redis
        
        # 等待数据库启动
        log_info "等待数据库启动..."
        sleep 30
        
        # 启动应用服务
        docker-compose up -d app
        
        # 等待应用启动
        log_info "等待应用启动..."
        sleep 20
        
        # 启动其他服务
        docker-compose up -d nginx prometheus grafana
        
        log_success "所有服务启动完成"
    fi
}

# 停止服务
stop_services() {
    log_info "停止服务..."
    
    if [ "$with_elasticsearch" = true ]; then
        docker-compose -f docker-compose.yml -f docker-compose.elasticsearch.yml down
    else
        docker-compose down
    fi
    
    log_success "服务停止完成"
}

# 重启服务
restart_services() {
    log_info "重启服务..."
    
    stop_services
    start_services
    
    log_success "服务重启完成"
}

# 查看日志
view_logs() {
    local service=${1:-""}
    
    if [ -z "$service" ]; then
        docker-compose logs -f
    else
        docker-compose logs -f "$service"
    fi
}

# 查看状态
check_status() {
    log_info "检查服务状态..."
    
    docker-compose ps
    
    echo ""
    log_info "检查服务健康状态..."
    
    # 检查应用健康状态
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        log_success "应用服务: 健康"
    else
        log_error "应用服务: 不健康"
    fi
    
    # 检查MySQL
    if docker-compose exec mysql mysqladmin ping -h localhost -u root -prootpassword > /dev/null 2>&1; then
        log_success "MySQL服务: 健康"
    else
        log_error "MySQL服务: 不健康"
    fi
    
    # 检查Redis
    if docker-compose exec redis redis-cli ping > /dev/null 2>&1; then
        log_success "Redis服务: 健康"
    else
        log_error "Redis服务: 不健康"
    fi
}

# 备份数据
backup_data() {
    log_info "备份数据..."
    
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 备份MySQL数据
    docker-compose exec mysql mysqldump -u root -prootpassword info_system > "$backup_dir/mysql_backup.sql"
    
    # 备份Redis数据
    docker-compose exec redis redis-cli BGSAVE
    docker cp $(docker-compose ps -q redis):/data/dump.rdb "$backup_dir/redis_backup.rdb"
    
    log_success "数据备份完成: $backup_dir"
}

# 清理资源
cleanup() {
    log_info "清理Docker资源..."
    
    # 停止并删除容器
    docker-compose down -v
    
    # 删除未使用的镜像
    docker image prune -f
    
    # 删除未使用的卷
    docker volume prune -f
    
    log_success "清理完成"
}

# 主函数
main() {
    local env=${1:-"dev"}
    local action=${2:-"up"}
    local with_elasticsearch=false
    
    # 解析选项参数
    shift 2
    while [[ $# -gt 0 ]]; do
        case $1 in
            --with-elasticsearch)
                with_elasticsearch=true
                shift
                ;;
            *)
                log_warning "未知选项: $1"
                shift
                ;;
        esac
    done
    
    log_info "信息管理系统部署脚本"
    log_info "环境: $env"
    log_info "操作: $action"
    log_info "Elasticsearch: $([ "$with_elasticsearch" = true ] && echo "启用" || echo "禁用")"
    
    case $action in
        "build")
            check_requirements
            create_directories
            set_permissions
            build_images
            ;;
        "up")
            check_requirements
            create_directories
            set_permissions
            build_images
            start_services
            check_status
            ;;
        "down")
            stop_services
            ;;
        "restart")
            restart_services
            check_status
            ;;
        "logs")
            view_logs $3
            ;;
        "status")
            check_status
            ;;
        "backup")
            backup_data
            ;;
        "cleanup")
            cleanup
            ;;
        *)
            log_error "未知操作: $action"
            echo "支持的操作: build, up, down, restart, logs, status, backup, cleanup"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"