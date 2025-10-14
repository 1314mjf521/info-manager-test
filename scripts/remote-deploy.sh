#!/bin/bash

# 远程服务器部署脚本
# 使用方法: ./scripts/remote-deploy.sh

set -e

# 服务器配置
REMOTE_HOST="192.168.100.15"
REMOTE_PORT="22"
REMOTE_USER="root"
REMOTE_PASSWORD="QAZwe@01010"
REMOTE_PATH="/opt/info-management-system"

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查sshpass是否安装
check_sshpass() {
    if ! command -v sshpass &> /dev/null; then
        log_error "sshpass未安装，请先安装sshpass"
        log_info "Ubuntu/Debian: sudo apt-get install sshpass"
        log_info "CentOS/RHEL: sudo yum install sshpass"
        log_info "macOS: brew install sshpass"
        exit 1
    fi
}

# 执行远程命令
remote_exec() {
    local command="$1"
    sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "$command"
}

# 上传文件
upload_file() {
    local local_path="$1"
    local remote_path="$2"
    sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no -P "$REMOTE_PORT" -r "$local_path" "$REMOTE_USER@$REMOTE_HOST:$remote_path"
}

# 安装Docker
install_docker() {
    log_info "在远程服务器安装Docker..."
    
    remote_exec "
        # 更新系统
        yum update -y
        
        # 安装必要的包
        yum install -y yum-utils device-mapper-persistent-data lvm2
        
        # 添加Docker仓库
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        
        # 安装Docker
        yum install -y docker-ce docker-ce-cli containerd.io
        
        # 启动Docker服务
        systemctl start docker
        systemctl enable docker
        
        # 安装Docker Compose
        curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        
        # 验证安装
        docker --version
        docker-compose --version
    "
    
    log_success "Docker安装完成"
}

# 准备远程环境
prepare_remote_env() {
    log_info "准备远程环境..."
    
    # 创建应用目录
    remote_exec "mkdir -p $REMOTE_PATH"
    
    # 安装必要的工具
    remote_exec "
        yum install -y wget curl git vim
        
        # 安装防火墙管理工具
        yum install -y firewalld
        systemctl start firewalld
        systemctl enable firewalld
        
        # 开放必要端口
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --permanent --add-port=8080/tcp
        firewall-cmd --permanent --add-port=3306/tcp
        firewall-cmd --permanent --add-port=6379/tcp
        firewall-cmd --permanent --add-port=9090/tcp
        firewall-cmd --permanent --add-port=3000/tcp
        firewall-cmd --reload
    "
    
    log_success "远程环境准备完成"
}

# 上传项目文件
upload_project() {
    log_info "上传项目文件到远程服务器..."
    
    # 创建临时目录
    local temp_dir=$(mktemp -d)
    
    # 复制项目文件到临时目录
    cp -r . "$temp_dir/info-management-system"
    
    # 删除不需要的文件
    rm -rf "$temp_dir/info-management-system/.git"
    rm -rf "$temp_dir/info-management-system/build"
    rm -rf "$temp_dir/info-management-system/logs"
    rm -rf "$temp_dir/info-management-system/test"
    
    # 上传到远程服务器
    upload_file "$temp_dir/info-management-system" "$REMOTE_PATH/../"
    
    # 清理临时目录
    rm -rf "$temp_dir"
    
    log_success "项目文件上传完成"
}

# 部署应用
deploy_application() {
    log_info "部署应用..."
    
    remote_exec "
        cd $REMOTE_PATH
        
        # 设置执行权限
        chmod +x scripts/deploy.sh
        
        # 使用生产配置
        cp configs/config.prod.yaml configs/config.yaml
        
        # 构建和启动服务
        ./scripts/deploy.sh prod up
    "
    
    log_success "应用部署完成"
}

# 验证部署
verify_deployment() {
    log_info "验证部署..."
    
    # 等待服务启动
    sleep 30
    
    # 检查服务状态
    remote_exec "
        cd $REMOTE_PATH
        ./scripts/deploy.sh prod status
    "
    
    # 测试API接口
    if remote_exec "curl -f http://localhost:8080/health"; then
        log_success "应用健康检查通过"
    else
        log_error "应用健康检查失败"
        return 1
    fi
    
    log_success "部署验证完成"
}

# 显示部署信息
show_deployment_info() {
    log_success "部署完成！"
    echo ""
    log_info "服务访问地址:"
    log_info "  应用服务: http://$REMOTE_HOST:8080"
    log_info "  API文档: http://$REMOTE_HOST:8080/api/v1"
    log_info "  健康检查: http://$REMOTE_HOST:8080/health"
    log_info "  Grafana监控: http://$REMOTE_HOST:3000 (admin/admin123)"
    log_info "  Prometheus: http://$REMOTE_HOST:9090"
    echo ""
    log_info "管理命令:"
    log_info "  查看状态: ssh root@$REMOTE_HOST 'cd $REMOTE_PATH && ./scripts/deploy.sh prod status'"
    log_info "  查看日志: ssh root@$REMOTE_HOST 'cd $REMOTE_PATH && ./scripts/deploy.sh prod logs'"
    log_info "  重启服务: ssh root@$REMOTE_HOST 'cd $REMOTE_PATH && ./scripts/deploy.sh prod restart'"
    echo ""
}

# 主函数
main() {
    log_info "开始远程部署信息管理系统..."
    log_info "目标服务器: $REMOTE_HOST:$REMOTE_PORT"
    
    # 检查本地环境
    check_sshpass
    
    # 测试SSH连接
    log_info "测试SSH连接..."
    if ! remote_exec "echo 'SSH连接成功'"; then
        log_error "SSH连接失败，请检查服务器信息"
        exit 1
    fi
    
    # 执行部署步骤
    install_docker
    prepare_remote_env
    upload_project
    deploy_application
    verify_deployment
    show_deployment_info
    
    log_success "远程部署完成！"
}

# 执行主函数
main "$@"