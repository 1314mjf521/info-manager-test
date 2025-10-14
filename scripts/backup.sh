#!/bin/bash

# 数据备份脚本
# 使用方法: ./scripts/backup.sh [类型] [保留天数]
# 类型: full, mysql, redis, config, logs
# 保留天数: 默认7天

set -e

# 默认配置
DEFAULT_RETENTION_DAYS=7
BACKUP_BASE_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

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

# 创建备份目录
create_backup_dir() {
    local backup_type=$1
    local backup_dir="$BACKUP_BASE_DIR/${backup_type}_$TIMESTAMP"
    
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

# 备份MySQL数据库
backup_mysql() {
    log_info "备份MySQL数据库..."
    
    local backup_dir=$(create_backup_dir "mysql")
    
    # 检查MySQL容器是否运行
    if ! docker-compose ps mysql | grep -q "Up"; then
        log_error "MySQL容器未运行"
        return 1
    fi
    
    # 备份所有数据库
    docker-compose exec -T mysql mysqldump -u root -prootpassword --all-databases --routines --triggers > "$backup_dir/all_databases.sql"
    
    # 备份应用数据库
    docker-compose exec -T mysql mysqldump -u root -prootpassword info_system > "$backup_dir/info_system.sql"
    
    # 压缩备份文件
    tar -czf "$backup_dir.tar.gz" -C "$BACKUP_BASE_DIR" "$(basename "$backup_dir")"
    rm -rf "$backup_dir"
    
    log_success "MySQL备份完成: $backup_dir.tar.gz"
}

# 备份Redis数据
backup_redis() {
    log_info "备份Redis数据..."
    
    local backup_dir=$(create_backup_dir "redis")
    
    # 检查Redis容器是否运行
    if ! docker-compose ps redis | grep -q "Up"; then
        log_error "Redis容器未运行"
        return 1
    fi
    
    # 触发Redis保存
    docker-compose exec redis redis-cli BGSAVE
    
    # 等待保存完成
    sleep 5
    
    # 复制RDB文件
    docker cp $(docker-compose ps -q redis):/data/dump.rdb "$backup_dir/dump.rdb"
    
    # 导出Redis配置
    docker-compose exec redis redis-cli CONFIG GET "*" > "$backup_dir/redis_config.txt"
    
    # 压缩备份文件
    tar -czf "$backup_dir.tar.gz" -C "$BACKUP_BASE_DIR" "$(basename "$backup_dir")"
    rm -rf "$backup_dir"
    
    log_success "Redis备份完成: $backup_dir.tar.gz"
}

# 备份配置文件
backup_config() {
    log_info "备份配置文件..."
    
    local backup_dir=$(create_backup_dir "config")
    
    # 备份应用配置
    cp -r configs "$backup_dir/"
    
    # 备份部署配置
    cp -r deployments "$backup_dir/"
    
    # 备份Docker配置
    cp docker-compose.yml "$backup_dir/"
    cp Dockerfile "$backup_dir/"
    
    # 备份脚本
    cp -r scripts "$backup_dir/"
    
    # 压缩备份文件
    tar -czf "$backup_dir.tar.gz" -C "$BACKUP_BASE_DIR" "$(basename "$backup_dir")"
    rm -rf "$backup_dir"
    
    log_success "配置备份完成: $backup_dir.tar.gz"
}

# 备份日志文件
backup_logs() {
    log_info "备份日志文件..."
    
    local backup_dir=$(create_backup_dir "logs")
    
    # 备份应用日志
    if [ -d "logs" ]; then
        cp -r logs "$backup_dir/"
    fi
    
    # 备份容器日志
    mkdir -p "$backup_dir/container_logs"
    
    # 获取所有容器的日志
    for container in $(docker-compose ps -q); do
        local container_name=$(docker inspect --format='{{.Name}}' "$container" | sed 's/\///')
        docker logs "$container" > "$backup_dir/container_logs/${container_name}.log" 2>&1
    done
    
    # 压缩备份文件
    tar -czf "$backup_dir.tar.gz" -C "$BACKUP_BASE_DIR" "$(basename "$backup_dir")"
    rm -rf "$backup_dir"
    
    log_success "日志备份完成: $backup_dir.tar.gz"
}

# 完整备份
backup_full() {
    log_info "执行完整备份..."
    
    local backup_dir=$(create_backup_dir "full")
    
    # 备份MySQL
    log_info "备份MySQL数据..."
    mkdir -p "$backup_dir/mysql"
    if docker-compose ps mysql | grep -q "Up"; then
        docker-compose exec -T mysql mysqldump -u root -prootpassword --all-databases --routines --triggers > "$backup_dir/mysql/all_databases.sql"
        docker-compose exec -T mysql mysqldump -u root -prootpassword info_system > "$backup_dir/mysql/info_system.sql"
    fi
    
    # 备份Redis
    log_info "备份Redis数据..."
    mkdir -p "$backup_dir/redis"
    if docker-compose ps redis | grep -q "Up"; then
        docker-compose exec redis redis-cli BGSAVE
        sleep 5
        docker cp $(docker-compose ps -q redis):/data/dump.rdb "$backup_dir/redis/dump.rdb"
        docker-compose exec redis redis-cli CONFIG GET "*" > "$backup_dir/redis/redis_config.txt"
    fi
    
    # 备份配置
    log_info "备份配置文件..."
    cp -r configs "$backup_dir/"
    cp -r deployments "$backup_dir/"
    cp docker-compose.yml "$backup_dir/"
    cp Dockerfile "$backup_dir/"
    cp -r scripts "$backup_dir/"
    
    # 备份日志
    log_info "备份日志文件..."
    if [ -d "logs" ]; then
        cp -r logs "$backup_dir/"
    fi
    
    # 创建备份信息文件
    {
        echo "备份信息"
        echo "========"
        echo "备份时间: $(date)"
        echo "备份类型: 完整备份"
        echo "系统版本: $(git describe --tags --always 2>/dev/null || echo 'unknown')"
        echo ""
        echo "包含内容:"
        echo "- MySQL数据库"
        echo "- Redis数据"
        echo "- 配置文件"
        echo "- 日志文件"
        echo ""
        echo "恢复说明:"
        echo "1. 解压备份文件"
        echo "2. 恢复MySQL: mysql -u root -p < mysql/all_databases.sql"
        echo "3. 恢复Redis: 复制dump.rdb到Redis数据目录"
        echo "4. 恢复配置: 复制配置文件到相应位置"
    } > "$backup_dir/README.txt"
    
    # 压缩备份文件
    tar -czf "$backup_dir.tar.gz" -C "$BACKUP_BASE_DIR" "$(basename "$backup_dir")"
    rm -rf "$backup_dir"
    
    log_success "完整备份完成: $backup_dir.tar.gz"
}

# 清理旧备份
cleanup_old_backups() {
    local retention_days=$1
    
    log_info "清理 $retention_days 天前的备份文件..."
    
    if [ ! -d "$BACKUP_BASE_DIR" ]; then
        log_warning "备份目录不存在"
        return
    fi
    
    # 查找并删除旧备份文件
    local deleted_count=0
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((deleted_count++))
        log_info "删除旧备份: $(basename "$file")"
    done < <(find "$BACKUP_BASE_DIR" -name "*.tar.gz" -type f -mtime +$retention_days -print0)
    
    if [ $deleted_count -eq 0 ]; then
        log_info "没有需要清理的旧备份文件"
    else
        log_success "清理了 $deleted_count 个旧备份文件"
    fi
}

# 列出备份文件
list_backups() {
    log_info "备份文件列表:"
    
    if [ ! -d "$BACKUP_BASE_DIR" ]; then
        log_warning "备份目录不存在"
        return
    fi
    
    echo ""
    printf "%-30s %-15s %-10s\n" "文件名" "大小" "修改时间"
    printf "%-30s %-15s %-10s\n" "------------------------------" "---------------" "----------"
    
    find "$BACKUP_BASE_DIR" -name "*.tar.gz" -type f -exec ls -lh {} \; | \
    awk '{printf "%-30s %-15s %-10s\n", $9, $5, $6" "$7" "$8}' | \
    sed 's|.*/||'
    
    echo ""
}

# 验证备份文件
verify_backup() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        log_error "请指定要验证的备份文件"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        log_error "备份文件不存在: $backup_file"
        return 1
    fi
    
    log_info "验证备份文件: $backup_file"
    
    # 检查文件完整性
    if tar -tzf "$backup_file" > /dev/null 2>&1; then
        log_success "备份文件完整性验证通过"
    else
        log_error "备份文件损坏"
        return 1
    fi
    
    # 显示备份内容
    log_info "备份文件内容:"
    tar -tzf "$backup_file" | head -20
    
    local file_count=$(tar -tzf "$backup_file" | wc -l)
    log_info "总文件数: $file_count"
    
    local file_size=$(ls -lh "$backup_file" | awk '{print $5}')
    log_info "文件大小: $file_size"
}

# 主函数
main() {
    local backup_type=${1:-"full"}
    local retention_days=${2:-$DEFAULT_RETENTION_DAYS}
    
    log_info "信息管理系统备份脚本"
    log_info "备份类型: $backup_type"
    log_info "保留天数: $retention_days"
    echo ""
    
    # 创建备份基础目录
    mkdir -p "$BACKUP_BASE_DIR"
    
    case $backup_type in
        "mysql")
            backup_mysql
            ;;
        "redis")
            backup_redis
            ;;
        "config")
            backup_config
            ;;
        "logs")
            backup_logs
            ;;
        "full")
            backup_full
            ;;
        "list")
            list_backups
            ;;
        "cleanup")
            cleanup_old_backups "$retention_days"
            ;;
        "verify")
            verify_backup "$2"
            ;;
        *)
            log_error "未知备份类型: $backup_type"
            echo "支持的类型: full, mysql, redis, config, logs, list, cleanup, verify"
            exit 1
            ;;
    esac
    
    # 清理旧备份（除了list和verify操作）
    if [[ "$backup_type" != "list" && "$backup_type" != "verify" && "$backup_type" != "cleanup" ]]; then
        cleanup_old_backups "$retention_days"
    fi
    
    log_success "备份操作完成！"
}

# 执行主函数
main "$@"