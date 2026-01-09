# 部署脚本使用指南

本项目提供了多个部署脚本，适用于不同的使用场景。以下是各个脚本的详细说明和使用方法。

## 📋 脚本概览

| 脚本名称 | 用途 | 平台 | 推荐场景 |
|---------|------|------|----------|
| `rebuild-and-start.bat` | 快速重建和启动 | Windows | 日常开发 |
| `quick-start.ps1` | 一键启动服务 | Windows | 快速启动 |
| `full-stack-deploy.ps1` | 完整部署方案 | Windows | 生产部署 |
| `install-and-start-frontend.ps1` | 前端专用脚本 | Windows | 前端开发 |

## 🚀 快速开始

### 1. 最简单的启动方式

```batch
# 双击运行或在命令行执行
rebuild-and-start.bat
```

**适用场景**: 日常开发，需要同时启动前后端
**特点**: 
- ✅ 自动编译后端
- ✅ 自动安装前端依赖
- ✅ 自动构建前端
- ✅ 同时启动前后端服务
- ✅ 支持中文显示

### 2. PowerShell 快速启动

```powershell
# 在项目根目录执行
.\scripts\quick-start.ps1
```

**适用场景**: 开发环境快速启动
**特点**:
- ✅ 环境检查
- ✅ 智能依赖管理
- ✅ 后台服务启动
- ✅ 详细的启动信息

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