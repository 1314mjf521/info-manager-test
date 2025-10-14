#!/bin/bash

# 健康检查脚本
# 使用方法: ./scripts/health-check.sh [服务器地址]

set -e

# 默认配置
DEFAULT_HOST="localhost"
DEFAULT_PORT="8080"

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

# 检查HTTP服务
check_http_service() {
    local host=$1
    local port=$2
    local endpoint=$3
    local service_name=$4
    
    log_info "检查 $service_name ($host:$port$endpoint)..."
    
    if curl -f -s --max-time 10 "http://$host:$port$endpoint" > /dev/null; then
        log_success "$service_name: 健康"
        return 0
    else
        log_error "$service_name: 不健康"
        return 1
    fi
}

# 检查TCP端口
check_tcp_port() {
    local host=$1
    local port=$2
    local service_name=$3
    
    log_info "检查 $service_name TCP端口 ($host:$port)..."
    
    if timeout 5 bash -c "</dev/tcp/$host/$port"; then
        log_success "$service_name: 端口可达"
        return 0
    else
        log_error "$service_name: 端口不可达"
        return 1
    fi
}

# 检查应用服务
check_application() {
    local host=$1
    
    log_info "检查应用服务..."
    
    # 健康检查端点
    if check_http_service "$host" "8080" "/health" "应用健康检查"; then
        # 获取详细健康信息
        local health_info=$(curl -s "http://$host:8080/health" | jq -r '.data.status // "unknown"' 2>/dev/null || echo "unknown")
        log_info "健康状态: $health_info"
    fi
    
    # 检查API端点
    check_http_service "$host" "8080" "/api/v1" "API服务"
    
    # 检查认证端点
    local auth_response=$(curl -s -w "%{http_code}" -o /dev/null "http://$host:8080/api/v1/auth/login")
    if [ "$auth_response" = "400" ] || [ "$auth_response" = "422" ]; then
        log_success "认证端点: 正常响应"
    else
        log_warning "认证端点: 异常响应码 $auth_response"
    fi
}

# 检查数据库服务
check_database() {
    local host=$1
    
    log_info "检查数据库服务..."
    
    # 检查MySQL端口
    if check_tcp_port "$host" "3306" "MySQL"; then
        # 如果是本地，尝试连接测试
        if [ "$host" = "localhost" ] || [ "$host" = "127.0.0.1" ]; then
            if command -v mysql &> /dev/null; then
                if mysql -h "$host" -P 3306 -u root -prootpassword -e "SELECT 1;" &> /dev/null; then
                    log_success "MySQL: 连接测试成功"
                else
                    log_warning "MySQL: 连接测试失败"
                fi
            fi
        fi
    fi
}

# 检查Redis服务
check_redis() {
    local host=$1
    
    log_info "检查Redis服务..."
    
    # 检查Redis端口
    if check_tcp_port "$host" "6379" "Redis"; then
        # 如果是本地，尝试ping测试
        if [ "$host" = "localhost" ] || [ "$host" = "127.0.0.1" ]; then
            if command -v redis-cli &> /dev/null; then
                if redis-cli -h "$host" -p 6379 ping | grep -q "PONG"; then
                    log_success "Redis: Ping测试成功"
                else
                    log_warning "Redis: Ping测试失败"
                fi
            fi
        fi
    fi
}

# 检查Nginx服务
check_nginx() {
    local host=$1
    
    log_info "检查Nginx服务..."
    
    # 检查HTTP端口
    check_tcp_port "$host" "80" "Nginx HTTP"
    
    # 检查HTTPS端口（如果配置了）
    check_tcp_port "$host" "443" "Nginx HTTPS"
}

# 检查监控服务
check_monitoring() {
    local host=$1
    
    log_info "检查监控服务..."
    
    # 检查Prometheus
    check_http_service "$host" "9090" "/" "Prometheus"
    
    # 检查Grafana
    check_http_service "$host" "3000" "/api/health" "Grafana"
}

# 性能测试
performance_test() {
    local host=$1
    
    log_info "执行性能测试..."
    
    # 响应时间测试
    local response_time=$(curl -o /dev/null -s -w "%{time_total}" "http://$host:8080/health")
    log_info "健康检查响应时间: ${response_time}s"
    
    if (( $(echo "$response_time < 1.0" | bc -l) )); then
        log_success "响应时间: 优秀"
    elif (( $(echo "$response_time < 3.0" | bc -l) )); then
        log_warning "响应时间: 一般"
    else
        log_error "响应时间: 较慢"
    fi
    
    # 并发测试（简单）
    log_info "执行简单并发测试..."
    local concurrent_requests=10
    local success_count=0
    
    for i in $(seq 1 $concurrent_requests); do
        if curl -f -s --max-time 5 "http://$host:8080/health" > /dev/null; then
            ((success_count++))
        fi &
    done
    
    wait
    
    log_info "并发测试结果: $success_count/$concurrent_requests 成功"
    
    if [ $success_count -eq $concurrent_requests ]; then
        log_success "并发测试: 通过"
    else
        log_warning "并发测试: 部分失败"
    fi
}

# 生成报告
generate_report() {
    local host=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local report_file="health-check-report-$(date '+%Y%m%d-%H%M%S').txt"
    
    log_info "生成健康检查报告..."
    
    {
        echo "信息管理系统健康检查报告"
        echo "=========================="
        echo "检查时间: $timestamp"
        echo "目标服务器: $host"
        echo ""
        
        echo "服务状态检查:"
        echo "------------"
        
        # 重新执行检查并记录结果
        if curl -f -s --max-time 10 "http://$host:8080/health" > /dev/null; then
            echo "✓ 应用服务: 健康"
        else
            echo "✗ 应用服务: 不健康"
        fi
        
        if timeout 5 bash -c "</dev/tcp/$host/3306" 2>/dev/null; then
            echo "✓ MySQL数据库: 可达"
        else
            echo "✗ MySQL数据库: 不可达"
        fi
        
        if timeout 5 bash -c "</dev/tcp/$host/6379" 2>/dev/null; then
            echo "✓ Redis缓存: 可达"
        else
            echo "✗ Redis缓存: 不可达"
        fi
        
        if timeout 5 bash -c "</dev/tcp/$host/80" 2>/dev/null; then
            echo "✓ Nginx代理: 可达"
        else
            echo "✗ Nginx代理: 不可达"
        fi
        
        echo ""
        echo "性能指标:"
        echo "--------"
        local response_time=$(curl -o /dev/null -s -w "%{time_total}" "http://$host:8080/health" 2>/dev/null || echo "N/A")
        echo "响应时间: ${response_time}s"
        
        echo ""
        echo "建议:"
        echo "----"
        echo "1. 定期执行健康检查"
        echo "2. 监控系统资源使用情况"
        echo "3. 检查日志文件是否有异常"
        echo "4. 确保备份策略正常执行"
        
    } > "$report_file"
    
    log_success "报告已生成: $report_file"
}

# 主函数
main() {
    local host=${1:-$DEFAULT_HOST}
    
    log_info "信息管理系统健康检查"
    log_info "目标服务器: $host"
    log_info "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # 执行各项检查
    check_application "$host"
    echo ""
    
    check_database "$host"
    echo ""
    
    check_redis "$host"
    echo ""
    
    check_nginx "$host"
    echo ""
    
    check_monitoring "$host"
    echo ""
    
    performance_test "$host"
    echo ""
    
    generate_report "$host"
    
    log_success "健康检查完成！"
}

# 执行主函数
main "$@"