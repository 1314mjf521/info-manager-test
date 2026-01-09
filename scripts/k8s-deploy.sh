#!/bin/bash

# Kubernetes部署脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置参数
NAMESPACE="info-management-system"
IMAGE_NAME="info-management-system"
IMAGE_TAG=${1:-"latest"}
DOMAIN=${2:-"localhost"}

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

# 检查kubectl
check_kubectl() {
    log_header "检查Kubernetes环境"
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl未安装"
        log_info "请访问 https://kubernetes.io/docs/tasks/tools/ 安装kubectl"
        exit 1
    fi
    
    # 检查集群连接
    if ! kubectl cluster-info &> /dev/null; then
        log_error "无法连接到Kubernetes集群"
        log_info "请检查kubeconfig配置"
        exit 1
    fi
    
    log_success "Kubernetes环境检查通过"
    log_info "kubectl版本: $(kubectl version --client --short)"
    log_info "集群信息: $(kubectl cluster-info | head -1)"
}

# 构建Docker镜像
build_image() {
    log_header "构建Docker镜像"
    
    log_info "构建镜像: $IMAGE_NAME:$IMAGE_TAG"
    docker build -t $IMAGE_NAME:$IMAGE_TAG .
    
    log_success "镜像构建完成"
}

# 创建命名空间
create_namespace() {
    log_header "创建命名空间"
    
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        log_info "命名空间 $NAMESPACE 已存在"
    else
        kubectl apply -f k8s/namespace.yaml
        log_success "命名空间 $NAMESPACE 创建完成"
    fi
}

# 更新配置
update_configs() {
    log_header "更新配置文件"
    
    # 更新域名
    sed -i.bak "s/host: localhost/host: $DOMAIN/g" k8s/app.yaml
    
    # 更新镜像标签
    sed -i.bak "s/image: info-management-system:latest/image: $IMAGE_NAME:$IMAGE_TAG/g" k8s/app.yaml
    
    log_success "配置文件更新完成"
}

# 部署数据库
deploy_database() {
    log_header "部署PostgreSQL数据库"
    
    kubectl apply -f k8s/postgres.yaml
    
    # 等待数据库就绪
    log_info "等待PostgreSQL就绪..."
    kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=300s
    
    log_success "PostgreSQL部署完成"
}

# 部署Redis
deploy_redis() {
    log_header "部署Redis缓存"
    
    kubectl apply -f k8s/redis.yaml
    
    # 等待Redis就绪
    log_info "等待Redis就绪..."
    kubectl wait --for=condition=ready pod -l app=redis -n $NAMESPACE --timeout=300s
    
    log_success "Redis部署完成"
}

# 部署配置
deploy_config() {
    log_header "部署应用配置"
    
    kubectl apply -f k8s/configmap.yaml
    
    log_success "应用配置部署完成"
}

# 部署应用
deploy_app() {
    log_header "部署应用服务"
    
    kubectl apply -f k8s/app.yaml
    
    # 等待应用就绪
    log_info "等待应用就绪..."
    kubectl wait --for=condition=ready pod -l app=info-management-app -n $NAMESPACE --timeout=300s
    
    log_success "应用服务部署完成"
}

# 验证部署
verify_deployment() {
    log_header "验证部署状态"
    
    # 检查所有Pod状态
    log_info "检查Pod状态..."
    kubectl get pods -n $NAMESPACE
    
    # 检查服务状态
    log_info "检查服务状态..."
    kubectl get services -n $NAMESPACE
    
    # 检查Ingress状态
    log_info "检查Ingress状态..."
    kubectl get ingress -n $NAMESPACE
    
    # 健康检查
    log_info "执行健康检查..."
    local app_pod=$(kubectl get pods -n $NAMESPACE -l app=info-management-app -o jsonpath='{.items[0].metadata.name}')
    
    if [[ -n "$app_pod" ]]; then
        if kubectl exec -n $NAMESPACE $app_pod -- wget -q --spider http://localhost:8080/api/v1/health; then
            log_success "✓ 应用健康检查通过"
        else
            log_error "✗ 应用健康检查失败"
            return 1
        fi
    else
        log_error "✗ 未找到应用Pod"
        return 1
    fi
    
    return 0
}

# 显示部署信息
show_deployment_info() {
    log_header "部署完成"
    
    echo -e "${GREEN}🎉 Kubernetes部署成功完成！${NC}"
    echo ""
    echo -e "${CYAN}访问信息:${NC}"
    
    # 获取Ingress信息
    local ingress_ip=$(kubectl get ingress app-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    if [[ "$ingress_ip" == "pending" ]] || [[ -z "$ingress_ip" ]]; then
        ingress_ip=$(kubectl get ingress app-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "localhost")
    fi
    
    echo -e "  网站地址: http://$ingress_ip"
    echo -e "  API地址: http://$ingress_ip/api/v1"
    echo -e "  健康检查: http://$ingress_ip/api/v1/health"
    echo ""
    echo -e "${CYAN}Kubernetes管理:${NC}"
    echo -e "  查看Pod: kubectl get pods -n $NAMESPACE"
    echo -e "  查看服务: kubectl get services -n $NAMESPACE"
    echo -e "  查看日志: kubectl logs -f deployment/info-management-app -n $NAMESPACE"
    echo -e "  进入容器: kubectl exec -it deployment/info-management-app -n $NAMESPACE -- /bin/sh"
    echo -e "  扩缩容: kubectl scale deployment info-management-app --replicas=3 -n $NAMESPACE"
    echo ""
    echo -e "${CYAN}监控命令:${NC}"
    echo -e "  资源使用: kubectl top pods -n $NAMESPACE"
    echo -e "  事件查看: kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'"
    echo -e "  描述Pod: kubectl describe pod <pod-name> -n $NAMESPACE"
    echo ""
    echo -e "${CYAN}更新应用:${NC}"
    echo -e "  构建新镜像: docker build -t $IMAGE_NAME:<new-tag> ."
    echo -e "  更新部署: kubectl set image deployment/info-management-app app=$IMAGE_NAME:<new-tag> -n $NAMESPACE"
    echo -e "  回滚部署: kubectl rollout undo deployment/info-management-app -n $NAMESPACE"
    echo ""
    echo -e "${CYAN}清理资源:${NC}"
    echo -e "  删除应用: kubectl delete -f k8s/"
    echo -e "  删除命名空间: kubectl delete namespace $NAMESPACE"
}

# 端口转发 (用于本地测试)
port_forward() {
    log_header "设置端口转发"
    
    log_info "设置端口转发到本地8080端口..."
    log_info "访问地址: http://localhost:8080"
    log_info "按Ctrl+C停止端口转发"
    
    kubectl port-forward service/app-service 8080:8080 -n $NAMESPACE
}

# 清理部署
cleanup() {
    log_header "清理部署资源"
    
    log_warn "这将删除所有部署的资源，包括数据！"
    read -p "确定要继续吗？(y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete -f k8s/
        log_success "资源清理完成"
    else
        log_info "取消清理操作"
    fi
}

# 主函数
main() {
    log_header "Kubernetes部署脚本"
    log_info "镜像标签: $IMAGE_TAG"
    log_info "域名: $DOMAIN"
    log_info "命名空间: $NAMESPACE"
    
    # 检查环境
    check_kubectl
    
    # 构建镜像
    build_image
    
    # 更新配置
    update_configs
    
    # 创建命名空间
    create_namespace
    
    # 部署组件
    deploy_config
    deploy_database
    deploy_redis
    deploy_app
    
    # 验证部署
    if verify_deployment; then
        show_deployment_info
    else
        log_error "部署验证失败，请检查日志"
        kubectl logs -l app=info-management-app -n $NAMESPACE --tail=50
        exit 1
    fi
    
    log_success "Kubernetes部署脚本执行完成"
}

# 显示帮助
show_help() {
    echo "Kubernetes部署脚本"
    echo ""
    echo "用法: $0 [命令] [镜像标签] [域名]"
    echo ""
    echo "命令:"
    echo "  deploy      部署应用 (默认)"
    echo "  port-forward 设置端口转发"
    echo "  cleanup     清理部署资源"
    echo "  help        显示帮助信息"
    echo ""
    echo "参数:"
    echo "  镜像标签    Docker镜像标签，默认: latest"
    echo "  域名        服务器域名，默认: localhost"
    echo ""
    echo "示例:"
    echo "  $0                              # 使用默认配置部署"
    echo "  $0 deploy v1.0.0 example.com   # 指定版本和域名"
    echo "  $0 port-forward                 # 设置端口转发"
    echo "  $0 cleanup                      # 清理资源"
    echo ""
    echo "注意:"
    echo "  - 需要安装kubectl和Docker"
    echo "  - 需要连接到Kubernetes集群"
    echo "  - 确保有足够的集群资源"
}

# 参数处理
case "${1:-deploy}" in
    "deploy")
        main "${@:2}"
        ;;
    "port-forward")
        port_forward
        ;;
    "cleanup")
        cleanup
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        log_error "未知命令: $1"
        show_help
        exit 1
        ;;
esac