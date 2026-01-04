# 项目结构说明

## 📁 项目目录结构

```
info-management-system/
├── 📄 README.md                           # 项目说明文档
├── 📄 PROJECT_STRUCTURE.md                # 项目结构说明 (本文件)
├── 📄 go.mod                              # Go模块定义
├── 📄 go.sum                              # Go依赖校验
├── 📄 LICENSE                             # 开源许可证
├── 📄 .gitignore                          # Git忽略文件
│
├── 📂 cmd/                                # 应用程序入口
│   └── 📂 server/
│       └── 📄 main.go                     # 主程序入口
│
├── 📂 internal/                           # 内部代码包
│   ├── 📂 app/                           # 应用程序配置
│   │   └── 📄 app.go                     # 应用初始化和路由配置
│   ├── 📂 config/                        # 配置管理
│   │   └── 📄 config.go                  # 配置结构和加载
│   ├── 📂 database/                      # 数据库连接
│   │   ├── 📄 database.go                # 数据库连接和配置
│   │   └── 📄 migrate.go                 # 数据库迁移
│   ├── 📂 handlers/                      # HTTP处理器
│   │   ├── 📄 auth_handler.go            # 认证处理器
│   │   ├── 📄 user_handler.go            # 用户管理处理器
│   │   ├── 📄 role_handler.go            # 角色管理处理器
│   │   ├── 📄 permission_handler.go      # 权限管理处理器
│   │   ├── 📄 record_handler.go          # 记录管理处理器
│   │   ├── 📄 record_type_handler.go     # 记录类型处理器
│   │   ├── 📄 file_handler.go            # 文件管理处理器
│   │   ├── 📄 ocr_handler.go             # OCR处理器
│   │   ├── 📄 ticket_handler.go          # 工单管理处理器
│   │   ├── 📄 notification_handler.go    # 通知管理处理器
│   │   ├── 📄 export_handler.go          # 导出管理处理器
│   │   ├── 📄 ai_handler.go              # AI功能处理器
│   │   ├── 📄 system_handler.go          # 系统管理处理器
│   │   ├── 📄 audit_handler.go           # 审计日志处理器
│   │   ├── 📄 dashboard_handler.go       # 仪表板处理器
│   │   ├── 📄 wechat_handler.go          # 微信集成处理器
│   │   └── 📄 flexible_handler.go        # 灵活API处理器
│   ├── 📂 services/                      # 业务逻辑服务
│   │   ├── 📄 auth_service.go            # 认证服务
│   │   ├── 📄 user_service.go            # 用户管理服务
│   │   ├── 📄 role_service.go            # 角色管理服务
│   │   ├── 📄 permission_service.go      # 权限管理服务
│   │   ├── 📄 record_service.go          # 记录管理服务
│   │   ├── 📄 record_type_service.go     # 记录类型服务
│   │   ├── 📄 file_service.go            # 文件管理服务
│   │   ├── 📄 ocr_service.go             # OCR服务
│   │   ├── 📄 ticket_service.go          # 工单管理服务
│   │   ├── 📄 notification_service.go    # 通知管理服务
│   │   ├── 📄 export_service.go          # 导出管理服务
│   │   ├── 📄 ai_service.go              # AI功能服务
│   │   ├── 📄 system_service.go          # 系统管理服务
│   │   ├── 📄 audit_service.go           # 审计日志服务
│   │   ├── 📄 dashboard_service.go       # 仪表板服务
│   │   └── 📄 wechat_service.go          # 微信集成服务
│   ├── 📂 models/                        # 数据模型
│   │   ├── 📄 user.go                    # 用户模型
│   │   ├── 📄 role.go                    # 角色模型
│   │   ├── 📄 permission.go              # 权限模型
│   │   ├── 📄 record.go                  # 记录模型
│   │   ├── 📄 record_type.go             # 记录类型模型
│   │   ├── 📄 file.go                    # 文件模型
│   │   ├── 📄 ticket.go                  # 工单模型
│   │   ├── 📄 notification.go            # 通知模型
│   │   ├── 📄 export.go                  # 导出模型
│   │   ├── 📄 ai.go                      # AI模型
│   │   ├── 📄 system.go                  # 系统模型
│   │   ├── 📄 audit.go                   # 审计模型
│   │   └── 📄 common.go                  # 通用模型
│   ├── 📂 middleware/                    # 中间件
│   │   ├── 📄 auth.go                    # 认证中间件
│   │   ├── 📄 permission.go              # 权限中间件
│   │   ├── 📄 cors.go                    # CORS中间件
│   │   ├── 📄 logging.go                 # 日志中间件
│   │   ├── 📄 error.go                   # 错误处理中间件
│   │   ├── 📄 rate_limit.go              # 限流中间件
│   │   └── 📄 response.go                # 响应处理中间件
│   └── 📂 logger/                        # 日志管理
│       └── 📄 logger.go                  # 日志配置和管理
│
├── 📂 configs/                           # 配置文件
│   └── 📄 config.example.yaml           # 配置文件示例
│
├── 📂 docs/                              # 文档目录
│   ├── 📄 API_DOCUMENTATION.md          # API接口文档
│   ├── 📄 DEPLOYMENT_GUIDE.md           # 部署指南
│   ├── 📄 USER_MANUAL.md                # 用户使用手册
│   └── 📄 COMPLETE_PERMISSION_MATRIX.md # 权限矩阵文档
│
├── 📂 scripts/                          # 脚本目录
│   ├── 📄 one-click-deploy.sh           # Linux/macOS一键部署脚本
│   ├── 📄 one-click-deploy.ps1          # Windows一键部署脚本
│   ├── 📄 build.ps1                     # 构建脚本
│   ├── 📄 deploy.sh                     # 部署脚本
│   ├── 📄 backup.sh                     # 备份脚本
│   ├── 📄 health-check.sh               # 健康检查脚本
│   └── 📄 cleanup-project.ps1           # 项目清理脚本
│
├── 📂 build/                            # 构建输出目录
│   └── 📄 server(.exe)                  # 编译后的可执行文件
│
├── 📂 data/                             # 数据目录 (运行时创建)
│   └── 📄 info_system.db                # SQLite数据库文件
│
├── 📂 logs/                             # 日志目录 (运行时创建)
│   └── 📄 app.log                       # 应用日志文件
│
└── 📂 uploads/                          # 文件上传目录 (运行时创建)
    └── 📂 2024/                         # 按年份组织的上传文件
        └── 📂 01/                       # 按月份组织的上传文件
```

## 📋 核心文件说明

### 🔧 配置文件
- **configs/config.example.yaml**: 配置文件模板，包含所有配置项的说明和示例

### 📚 文档文件
- **README.md**: 项目概述、快速开始、特性介绍
- **docs/API_DOCUMENTATION.md**: 完整的API接口文档
- **docs/DEPLOYMENT_GUIDE.md**: 详细的部署指南
- **docs/USER_MANUAL.md**: 用户使用手册
- **docs/COMPLETE_PERMISSION_MATRIX.md**: 权限系统说明

### 🚀 部署脚本
- **scripts/one-click-deploy.sh**: Linux/macOS一键部署脚本
- **scripts/one-click-deploy.ps1**: Windows一键部署脚本
- **scripts/build.ps1**: 项目构建脚本
- **scripts/deploy.sh**: 服务器部署脚本
- **scripts/backup.sh**: 数据备份脚本
- **scripts/health-check.sh**: 系统健康检查脚本

### 💻 核心代码
- **cmd/server/main.go**: 应用程序入口点
- **internal/app/app.go**: 应用初始化和路由配置
- **internal/config/config.go**: 配置管理
- **internal/database/**: 数据库连接和迁移
- **internal/handlers/**: HTTP请求处理器
- **internal/services/**: 业务逻辑服务层
- **internal/models/**: 数据模型定义
- **internal/middleware/**: HTTP中间件

## 🎯 使用说明

### 快速开始
1. **配置系统**: 复制 `configs/config.example.yaml` 为 `configs/config.yaml` 并修改配置
2. **一键部署**: 运行对应平台的一键部署脚本
3. **访问系统**: 浏览器打开 `http://localhost:8080`
4. **默认账号**: admin / admin123

### 开发环境
```bash
# 安装依赖
go mod download

# 编译项目
go build -o build/server cmd/server/main.go

# 运行项目
./build/server
```

### 生产环境
```bash
# 使用一键部署脚本
./scripts/one-click-deploy.sh

# 或手动部署
./scripts/deploy.sh
```

## 🔒 安全注意事项

1. **修改默认密码**: 首次登录后立即修改默认管理员密码
2. **配置JWT密钥**: 生产环境必须修改JWT密钥
3. **数据库安全**: 生产环境建议使用MySQL/PostgreSQL
4. **HTTPS配置**: 生产环境建议配置HTTPS
5. **防火墙设置**: 合理配置防火墙规则

## 📊 系统特性

- ✅ **用户管理**: 完整的用户生命周期管理
- ✅ **权限控制**: 细粒度的权限管理系统
- ✅ **记录管理**: 多类型记录管理
- ✅ **文件管理**: 文件上传、下载、OCR识别
- ✅ **工单管理**: 完整的工单处理流程
- ✅ **通知管理**: 多渠道通知系统
- ✅ **数据导出**: 多格式数据导出
- ✅ **AI功能**: 智能文本处理和语音识别
- ✅ **系统监控**: 实时系统状态监控
- ✅ **多数据库**: 支持SQLite、MySQL、PostgreSQL、TiDB

## 🚀 部署支持

- **操作系统**: Linux、Windows、macOS
- **数据库**: SQLite、MySQL、PostgreSQL、TiDB
- **容器化**: Docker、Docker Compose
- **反向代理**: Nginx、Apache
- **进程管理**: Systemd、PM2、Supervisor

## 📞 技术支持

- **项目地址**: https://github.com/your-repo/info-management-system
- **问题反馈**: https://github.com/your-repo/info-management-system/issues
- **文档站点**: https://docs.example.com
- **技术支持**: support@example.com

---

**版本**: v1.0.0  
**更新时间**: 2024年1月4日  
**系统状态**: 生产就绪 ✅