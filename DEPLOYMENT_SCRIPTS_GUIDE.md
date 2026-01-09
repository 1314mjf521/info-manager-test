# 部署脚本使用指南

本项目提供了多个部署脚本，适用于不同的使用场景和平台。以下是各个脚本的详细说明和使用方法。

## 📋 脚本概览

| 脚本名称 | 平台 | 用途 | 推荐场景 |
|---------|------|------|----------|
| `rebuild-and-start.bat` | Windows | 快速重建和启动 | 日常开发 |
| `quick-start.ps1` | Windows | 一键启动服务 | 快速启动 |
| `full-stack-deploy.ps1` | Windows | 完整部署方案 | Windows生产 |
| `install-and-start-frontend.ps1` | Windows | 前端专用脚本 | 前端开发 |
| `deploy-linux.sh` | Linux | Linux服务器部署 | Linux生产 |
| `docker-deploy.sh` | Linux/Windows | Docker容器化部署 | 容器化部署 |
| `k8s-deploy.sh` | Kubernetes | K8s集群部署 | 大规模部署 |

## 🐧 Linux服务器部署

### 1. 传统Linux部署 (`deploy-linux.sh`)

**最适合生产环境的Linux服务器部署**

```bash
# 基本部署
sudo ./scripts/deploy-linux.sh

# 指定参数部署
sudo ./scripts/deploy-linux.sh prod 8080 3000 example.com true

# 参数说明
sudo ./scripts/deploy-linux.sh [模式] [后端端口] [前端端口] [域名] [SSL启用]
```

**功能特性**:
- ✅ 自动检测Linux发行版 (Ubuntu/CentOS/Debian)
- ✅ 自动安装Go和Node.js环境
- ✅ 创建系统服务用户
- ✅ 配置systemd服务
- ✅ 配置Nginx反向代理
- ✅ 可选SSL证书配置
- ✅ 防火墙配置
- ✅ 完整的权限管理

**部署后管理**:
```bash
# 服务管理
sudo systemctl start info-management-system
sudo systemctl stop info-management-system
sudo systemctl restart info-management-system
sudo systemctl status info-management-system

# 查看日志
sudo journalctl -u info-management-system -f
tail -f /var/log/info-management-system/app.log

# Nginx管理
sudo systemctl restart nginx
sudo nginx -t
```

### 2. Docker容器化部署 (`docker-deploy.sh`)

**现代化的容器部署方案**

```bash
# 基本部署
./scripts/docker-deploy.sh

# 生产环境部署
./scripts/docker-deploy.sh prod example.com true

# 开发环境部署
./scripts/docker-deploy.sh dev localhost false
```

**功能特性**:
- ✅ 多服务容器编排 (App + PostgreSQL + Redis + Nginx)
- ✅ 数据持久化
- ✅ 健康检查
- ✅ 自动重启
- ✅ 资源限制
- ✅ 网络隔离

**容器管理**:
```bash
# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 更新应用
docker-compose up -d --build

# 备份数据
docker-compose exec postgres pg_dump -U postgres info_management > backup.sql
```

### 3. Kubernetes集群部署 (`k8s-deploy.sh`)

**企业级大规模部署方案**

```bash
# 部署到K8s集群
./scripts/k8s-deploy.sh deploy v1.0.0 example.com

# 设置端口转发 (本地测试)
./scripts/k8s-deploy.sh port-forward

# 清理资源
./scripts/k8s-deploy.sh cleanup
```

**功能特性**:
- ✅ 高可用部署 (多副本)
- ✅ 自动扩缩容
- ✅ 滚动更新
- ✅ 健康检查和自愈
- ✅ 服务发现
- ✅ 负载均衡
- ✅ 持久化存储

**K8s管理**:
```bash
# 查看资源
kubectl get all -n info-management-system

# 扩缩容
kubectl scale deployment info-management-app --replicas=5 -n info-management-system

# 滚动更新
kubectl set image deployment/info-management-app app=info-management-system:v2.0.0 -n info-management-system

# 查看日志
kubectl logs -f deployment/info-management-app -n info-management-system
```

## 🚀 快速开始

### Windows开发环境
```batch
# 最简单的方式
rebuild-and-start.bat
```

### Linux生产环境
```bash
# 传统部署
sudo ./scripts/deploy-linux.sh prod 8080 80 yourdomain.com true

# 容器化部署
./scripts/docker-deploy.sh prod yourdomain.com true

# K8s部署
./scripts/k8s-deploy.sh deploy latest yourdomain.com
```

## 🎯 部署方案选择

### 开发环境
- **Windows**: `rebuild-and-start.bat` 或 `quick-start.ps1`
- **Linux**: `docker-deploy.sh dev`

### 测试环境
- **小规模**: `deploy-linux.sh test`
- **容器化**: `docker-deploy.sh test`

### 生产环境
- **单机部署**: `deploy-linux.sh prod`
- **容器化部署**: `docker-deploy.sh prod`
- **集群部署**: `k8s-deploy.sh deploy`

### 高可用部署
- **Docker Swarm**: 基于 `docker-compose.yml` 扩展
- **Kubernetes**: `k8s-deploy.sh deploy`

## 📊 部署方案对比

| 特性 | Linux传统 | Docker | Kubernetes |
|------|-----------|--------|------------|
| 部署复杂度 | 中等 | 简单 | 复杂 |
| 资源占用 | 低 | 中等 | 高 |
| 扩展性 | 低 | 中等 | 高 |
| 维护成本 | 高 | 中等 | 低 |
| 适用规模 | 小-中 | 小-中 | 中-大 |
| 学习成本 | 低 | 中等 | 高 |

## 🔧 环境要求

### Linux传统部署
- **系统**: Ubuntu 18.04+, CentOS 7+, Debian 9+
- **权限**: root或sudo权限
- **内存**: 最少2GB，推荐4GB+
- **磁盘**: 最少10GB可用空间

### Docker部署
- **Docker**: 20.10+
- **Docker Compose**: 1.29+
- **内存**: 最少4GB，推荐8GB+
- **磁盘**: 最少20GB可用空间

### Kubernetes部署
- **Kubernetes**: 1.20+
- **kubectl**: 配置好的集群访问
- **资源**: 最少2CPU/4GB内存的节点
- **存储**: 支持PVC的存储类

## 🛡️ 安全配置

### SSL/TLS配置
```bash
# Linux传统部署 - 自动SSL
sudo ./scripts/deploy-linux.sh prod 8080 80 yourdomain.com true

# Docker部署 - 手动配置SSL证书
# 将证书文件放在 ssl/ 目录下
./scripts/docker-deploy.sh prod yourdomain.com true
```

### 防火墙配置
```bash
# Ubuntu/Debian
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 数据库安全
```bash
# 修改默认密码
# 编辑配置文件中的数据库密码
# 使用强密码和加密连接
```

## 📈 监控和日志

### 系统监控
```bash
# 资源使用情况
htop
df -h
free -h

# 服务状态
systemctl status info-management-system
systemctl status nginx
```

### 应用日志
```bash
# 传统部署
tail -f /var/log/info-management-system/app.log

# Docker部署
docker-compose logs -f app

# K8s部署
kubectl logs -f deployment/info-management-app -n info-management-system
```

### 性能监控
```bash
# 网络连接
netstat -tlnp | grep :8080

# 进程监控
ps aux | grep info-management

# 磁盘IO
iostat -x 1
```

## 🔄 备份和恢复

### 数据备份
```bash
# PostgreSQL备份
pg_dump -U postgres -h localhost info_management > backup.sql

# Docker环境备份
docker-compose exec postgres pg_dump -U postgres info_management > backup.sql

# 文件备份
tar -czf uploads_backup.tar.gz /app/uploads/
```

### 数据恢复
```bash
# PostgreSQL恢复
psql -U postgres -h localhost info_management < backup.sql

# Docker环境恢复
docker-compose exec -T postgres psql -U postgres -d info_management < backup.sql
```

## 🚨 故障排除

### 常见问题

#### 1. 端口被占用
```bash
# 查看端口占用
netstat -tlnp | grep :8080
lsof -i :8080

# 杀死占用进程
sudo kill -9 <PID>
```

#### 2. 权限问题
```bash
# 检查文件权限
ls -la /opt/info-management-system/

# 修复权限
sudo chown -R app:app /opt/info-management-system/
sudo chmod 755 /opt/info-management-system/bin/info-management-system
```

#### 3. 数据库连接失败
```bash
# 检查数据库状态
sudo systemctl status postgresql
docker-compose ps postgres

# 测试连接
psql -U postgres -h localhost -d info_management
```

#### 4. Nginx配置错误
```bash
# 测试配置
sudo nginx -t

# 重新加载配置
sudo nginx -s reload

# 查看错误日志
sudo tail -f /var/log/nginx/error.log
```

## 📚 最佳实践

### 1. 生产部署建议
- 使用专用的数据库服务器
- 配置SSL证书
- 设置定期备份
- 配置监控告警
- 使用CDN加速静态资源

### 2. 安全建议
- 定期更新系统和依赖
- 使用强密码
- 限制SSH访问
- 配置防火墙规则
- 定期安全审计

### 3. 性能优化
- 配置数据库连接池
- 启用Gzip压缩
- 使用Redis缓存
- 优化数据库查询
- 配置负载均衡

### 4. 运维建议
- 建立完整的部署文档
- 设置自动化部署流程
- 配置日志轮转
- 建立灾备方案
- 定期性能测试

这个完整的部署指南涵盖了从开发到生产的各种部署场景，选择适合你环境的部署方案即可！

## 🛠️ 详细脚本说明

### 1. rebuild-and-start.bat

**最简单的启动脚本，适合日常开发使用**

```batch
rebuild-and-start.bat
```

**功能**:
- 停止现有的前后端服务
- 编译Go后端服务
- 检查并安装前端依赖
- 构建前端项目
- 启动后端服务 (端口8080)
- 启动前端开发服务器 (端口5173)

**输出**:
- 前端地址: http://localhost:5173
- 后端地址: http://localhost:8080
- API文档: http://localhost:8080/swagger/index.html

### 2. quick-start.ps1

**智能的快速启动脚本**

```powershell
.\scripts\quick-start.ps1
```

**功能**:
- 检查项目结构完整性
- 验证Go和Node.js环境
- 智能停止现有服务
- 编译并启动后端
- 安装依赖并启动前端
- 提供详细的访问信息

**特点**:
- 🔍 环境检查
- 🛑 智能服务管理
- 📊 启动状态监控
- 💡 友好的用户提示

### 3. full-stack-deploy.ps1

**完整的生产级部署脚本**

```powershell
# 开发模式
.\scripts\full-stack-deploy.ps1

# 生产模式
.\scripts\full-stack-deploy.ps1 -Mode prod

# 自定义端口
.\scripts\full-stack-deploy.ps1 -BackendPort 9000 -FrontendPort 4000

# 只部署前端
.\scripts\full-stack-deploy.ps1 -SkipBackend

# 清理重建
.\scripts\full-stack-deploy.ps1 -Clean -Force

# 后台运行
.\scripts\full-stack-deploy.ps1 -Background
```

**参数说明**:
- `-Mode`: 部署模式 (dev|prod|test)
- `-BackendPort`: 后端端口 (默认8080)
- `-FrontendPort`: 前端端口 (默认5173)
- `-SkipBackend`: 跳过后端部署
- `-SkipFrontend`: 跳过前端部署
- `-Clean`: 清理缓存和构建文件
- `-Force`: 强制重新安装/编译
- `-Background`: 后台运行服务

**功能**:
- 🔧 系统环境检查
- 🚦 端口可用性检查
- 🧹 智能清理功能
- 📦 依赖管理
- 🔄 服务生命周期管理
- 📊 部署状态验证
- 📋 详细的部署信息

### 4. install-and-start-frontend.ps1

**前端专用部署脚本**

```powershell
# 开发模式
.\scripts\install-and-start-frontend.ps1

# 构建模式
.\scripts\install-and-start-frontend.ps1 -Mode build

# 预览模式
.\scripts\install-and-start-frontend.ps1 -Mode serve

# 自定义端口
.\scripts\install-and-start-frontend.ps1 -Port 4000

# 清理重建
.\scripts\install-and-start-frontend.ps1 -Clean -Force
```

**参数说明**:
- `-Mode`: 运行模式 (dev|build|serve)
- `-Port`: 端口号 (默认5173)
- `-Force`: 强制重新安装依赖
- `-Clean`: 清理缓存和构建文件

**功能**:
- 🔍 Node.js环境检查
- 📁 前端目录结构验证
- 🧹 缓存清理
- 📦 依赖安装管理
- 🔨 构建管理
- 🚀 开发服务器启动
- 📊 预览服务器启动

## 🎯 使用场景推荐

### 日常开发
```batch
# 最简单，双击即可
rebuild-and-start.bat
```

### 首次启动项目
```powershell
# 完整的环境检查和设置
.\scripts\full-stack-deploy.ps1 -Clean -Force
```

### 只开发前端
```powershell
# 只启动前端开发服务器
.\scripts\install-and-start-frontend.ps1
```

### 生产部署
```powershell
# 生产模式部署
.\scripts\full-stack-deploy.ps1 -Mode prod -Background
```

### 测试环境
```powershell
# 测试模式
.\scripts\full-stack-deploy.ps1 -Mode test
```

### 端口冲突解决
```powershell
# 使用自定义端口
.\scripts\full-stack-deploy.ps1 -BackendPort 9000 -FrontendPort 4000
```

## 🔧 故障排除

### 常见问题

#### 1. 端口被占用
```powershell
# 查看端口占用
netstat -ano | findstr :8080
netstat -ano | findstr :5173

# 杀死占用进程
taskkill /f /pid <PID>

# 或使用脚本自动处理
.\scripts\full-stack-deploy.ps1 -Force
```

#### 2. 依赖安装失败
```powershell
# 清理并重新安装
.\scripts\full-stack-deploy.ps1 -Clean -Force
```

#### 3. 编译失败
```powershell
# 检查Go环境
go version

# 检查项目依赖
go mod tidy

# 强制重新编译
.\scripts\full-stack-deploy.ps1 -Force
```

#### 4. 前端启动失败
```powershell
# 只重建前端
.\scripts\install-and-start-frontend.ps1 -Clean -Force
```

### 环境要求

#### 必需软件
- **Go**: 1.19+ (后端编译)
- **Node.js**: 16+ (前端开发)
- **npm**: 8+ (包管理)

#### 检查命令
```bash
go version
node --version
npm --version
```

#### 安装链接
- Go: https://golang.org/dl/
- Node.js: https://nodejs.org/

### 日志和调试

#### 查看服务状态
```powershell
# 查看运行的服务
Get-Process -Name "info-management-system","node" -ErrorAction SilentlyContinue

# 查看端口占用
netstat -ano | findstr :8080
netstat -ano | findstr :5173
```

#### 停止所有服务
```powershell
# 停止后端
Get-Process -Name "info-management-system" -ErrorAction SilentlyContinue | Stop-Process

# 停止前端
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process
```

#### 查看日志
```powershell
# 后端日志 (如果配置了日志文件)
Get-Content logs/app.log -Wait

# PowerShell作业日志
Get-Job | Receive-Job
```

## 📚 高级用法

### 自定义配置

#### 环境变量
```powershell
# 设置API基础URL
$env:VITE_API_BASE_URL = "http://localhost:9000"

# 设置后端端口
$env:PORT = "9000"

# 然后启动服务
.\scripts\full-stack-deploy.ps1
```

#### 配置文件
- 后端配置: `config/config.yaml`
- 前端配置: `frontend/.env`

### 批量操作

#### 多环境部署
```powershell
# 开发环境
.\scripts\full-stack-deploy.ps1 -Mode dev -BackendPort 8080 -FrontendPort 5173

# 测试环境
.\scripts\full-stack-deploy.ps1 -Mode test -BackendPort 8081 -FrontendPort 5174

# 生产环境
.\scripts\full-stack-deploy.ps1 -Mode prod -BackendPort 8082 -FrontendPort 5175
```

#### 自动化脚本
```powershell
# 创建自动化部署脚本
$environments = @(
    @{Mode="dev"; BackendPort=8080; FrontendPort=5173},
    @{Mode="test"; BackendPort=8081; FrontendPort=5174}
)

foreach ($env in $environments) {
    Write-Host "部署 $($env.Mode) 环境..."
    & .\scripts\full-stack-deploy.ps1 -Mode $env.Mode -BackendPort $env.BackendPort -FrontendPort $env.FrontendPort -Background
}
```

## 🎉 总结

选择合适的脚本可以大大提高开发效率：

- **新手推荐**: `rebuild-and-start.bat` - 简单易用
- **开发推荐**: `quick-start.ps1` - 智能便捷  
- **生产推荐**: `full-stack-deploy.ps1` - 功能完整
- **前端专用**: `install-and-start-frontend.ps1` - 专业高效

所有脚本都经过测试，支持中文环境，并提供详细的错误信息和使用提示。