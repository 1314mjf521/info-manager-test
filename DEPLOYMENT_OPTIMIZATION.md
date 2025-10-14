# 部署优化说明

## 概述

本文档说明了信息管理系统的部署优化内容，包括Docker镜像地址更新、编译流程优化和Elasticsearch组件配置。

## 优化内容

### 1. Docker镜像地址优化

已将所有第三方Docker镜像地址更新为华为云SWR镜像仓库地址，提高镜像拉取速度和稳定性：

- **Redis**: `swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/redis:7-alpine`
- **Prometheus**: `swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/prom/prometheus:latest`
- **Grafana**: `swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/grafana/grafana:latest`
- **Elasticsearch**: `swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/elasticsearch:8.11.0`
- **Kibana**: `swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/kibana:8.11.0`
- **Filebeat**: `swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/elastic/filebeat:8.11.0`

### 2. Elasticsearch组件配置

Elasticsearch **不是后端核心功能必需的组件**，仅用于日志收集和搜索功能。已创建可选配置：

#### 核心部署（默认）
```bash
# 标准部署，不包含Elasticsearch
./scripts/deploy.sh prod up
```

#### 完整部署（包含日志收集）
```bash
# 包含Elasticsearch日志收集系统
./scripts/deploy.sh prod up --with-elasticsearch
```

#### Elasticsearch组件说明
- **Elasticsearch**: 日志存储和搜索引擎
- **Kibana**: 日志可视化界面 (http://服务器:5601)
- **Filebeat**: 日志收集器，自动收集应用日志

### 3. 编译流程优化

#### Windows环境编译

**方式1: 使用批处理文件**
```cmd
# 标准编译
build.bat

# 清理后编译
build.bat --clean

# 运行测试后编译
build.bat --test

# 调试模式编译
build.bat --debug
```

**方式2: 使用PowerShell脚本**
```powershell
# 标准编译
.\scripts\build.ps1

# 清理后编译
.\scripts\build.ps1 -Clean

# 运行测试
.\scripts\build.ps1 -Test

# 调试模式
.\scripts\build.ps1 -BuildMode debug
```

**方式3: 使用Makefile**
```cmd
# Linux目标编译
make build-linux

# Windows目标编译
make build-windows

# 多平台编译
make build-all
```

#### 编译产物
编译后的文件统一放置在 `build/` 目录：
```
build/
├── server          # Linux可执行文件
├── server.exe      # Windows可执行文件（如果编译）
├── configs/        # 配置文件
├── start.sh        # Linux启动脚本
└── start.bat       # Windows启动脚本
```

### 4. 部署脚本优化

#### Windows部署优化

**一键部署**
```cmd
# 使用批处理文件
deploy-now.bat

# 使用PowerShell脚本
.\deploy-to-remote.ps1
```

**部署选项**
```powershell
# 跳过Docker安装
.\deploy-to-remote.ps1 -SkipDocker

# 跳过文件上传
.\deploy-to-remote.ps1 -SkipUpload

# 跳过两者（仅部署）
.\deploy-to-remote.ps1 -SkipDocker -SkipUpload
```

#### Linux部署
```bash
# 标准部署
bash scripts/remote-deploy.sh

# 本地部署
./scripts/deploy.sh prod up

# 包含日志收集的部署
./scripts/deploy.sh prod up --with-elasticsearch
```

## 服务访问地址

### 核心服务
- **应用服务**: http://服务器:8080
- **API文档**: http://服务器:8080/api/v1
- **健康检查**: http://服务器:8080/health

### 监控服务
- **Grafana**: http://服务器:3000 (admin/admin123)
- **Prometheus**: http://服务器:9090

### 日志服务（可选）
- **Kibana**: http://服务器:5601
- **Elasticsearch**: http://服务器:9200

## 故障排除

### 1. Windows部署失败

**问题**: PowerShell脚本执行失败
```powershell
# 解决方案1: 设置执行策略
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 解决方案2: 临时绕过策略
powershell -ExecutionPolicy Bypass -File deploy-to-remote.ps1
```

**问题**: SSH连接失败
```cmd
# 检查SSH客户端
ssh -V

# 安装OpenSSH（Windows 10/11）
# 设置 -> 应用 -> 可选功能 -> OpenSSH客户端

# 或安装Git for Windows
# https://git-scm.com/download/win
```

### 2. 编译失败

**问题**: Go环境未配置
```cmd
# 检查Go版本
go version

# 下载安装Go
# https://golang.org/dl/
```

**问题**: 依赖下载失败
```cmd
# 清理模块缓存
go clean -modcache

# 重新下载依赖
go mod download
go mod tidy
```

### 3. Docker镜像拉取失败

**问题**: 华为云SWR镜像拉取慢
```bash
# 方案1: 配置Docker镜像加速器
# 编辑 /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://swr.cn-north-4.myhuaweicloud.com"
  ]
}

# 重启Docker服务
sudo systemctl restart docker
```

**问题**: 网络连接问题
```bash
# 方案2: 使用原始Docker Hub镜像
# 临时修改docker-compose.yml中的镜像地址
# 将 swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/ 前缀删除
```

### 4. Elasticsearch启动失败

**问题**: 内存不足
```bash
# 检查系统内存
free -h

# 降低Elasticsearch内存使用
# 编辑 docker-compose.elasticsearch.yml
environment:
  - ES_JAVA_OPTS=-Xms256m -Xmx256m  # 降低内存使用
```

**问题**: 磁盘空间不足
```bash
# 检查磁盘空间
df -h

# 清理Docker资源
docker system prune -a
```

## 最佳实践

### 1. 生产环境部署
1. 使用核心部署模式（不包含Elasticsearch）以节省资源
2. 定期备份数据：`./scripts/deploy.sh prod backup`
3. 监控服务状态：`./scripts/deploy.sh prod status`
4. 查看日志：`./scripts/deploy.sh prod logs`

### 2. 开发环境
1. 使用完整部署模式进行日志分析
2. 定期编译测试：`build.bat --test`
3. 使用热重载开发：`make dev`

### 3. 维护建议
1. 定期更新Docker镜像
2. 监控系统资源使用
3. 备份重要数据
4. 保持配置文件版本控制

## 总结

通过本次优化：

1. **提升了部署稳定性** - 使用华为云SWR镜像仓库
2. **简化了编译流程** - 支持Windows和Linux多种编译方式
3. **优化了资源使用** - Elasticsearch作为可选组件
4. **改善了用户体验** - 更好的错误处理和故障排除指导

系统现在支持灵活的部署配置，可以根据实际需求选择合适的部署模式。