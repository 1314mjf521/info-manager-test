# 信息记录管理系统

一个基于Go语言开发的企业级信息记录管理系统，支持多种数据类型记录、权限管理、AI集成等功能。

## 功能特性

- 🔐 完整的用户认证和RBAC权限管理
- 📝 多类型信息记录管理（支持动态字段）
- 📊 数据导入导出（支持多种格式）
- 🤖 AI集成（OpenAI、OCR、语音识别）
- 📱 多平台客户端支持
- 🔔 多渠道通知和告警
- 🌐 多语言和国际化支持

## 技术栈

- **后端**: Go 1.21 + Gin + GORM
- **数据库**: PostgreSQL / MySQL
- **缓存**: Redis
- **前端**: Vue.js 3 + TypeScript (待开发)
- **移动端**: Flutter (待开发)
- **桌面端**: Electron (待开发)

## 快速开始

### 环境要求

- Go 1.21+
- PostgreSQL 15+ 或 MySQL 8.0+
- Redis 7+ (可选)

### 安装和运行

1. 克隆项目
```bash
git clone <repository-url>
cd info-management-system
```

2. 配置Go代理（中国用户推荐）
```bash
go env -w GOPROXY=https://mirrors.aliyun.com/goproxy/,direct
```

3. 安装依赖
```bash
go mod download
go mod tidy
```

4. 配置环境
```bash
cp .env.example .env
# 编辑 configs/config.yaml 或 .env 文件配置数据库连接
```

5. 验证项目设置
```bash
go run ./scripts/test-basic.go
```

6. 构建项目
```bash
go build -o build/server ./cmd/server
```

7. 运行服务
```bash
./build/server
```

### Windows用户快速命令

```powershell
# 构建
go build -o build/server.exe ./cmd/server

# 运行
./build/server.exe

# 开发模式
go run ./cmd/server

# 测试
go test ./...

# 验证设置
go run ./scripts/test-basic.go
```

### 数据库配置

#### PostgreSQL (推荐)
```yaml
database:
  type: "postgres"
  host: "localhost"
  port: "5432"
  username: "postgres"
  password: "password"
  database: "info_system"
  ssl_mode: "disable"
```

#### MySQL
```yaml
database:
  type: "mysql"
  host: "localhost"
  port: "3306"
  username: "root"
  password: "password"
  database: "info_system"
```

## API文档

服务启动后访问：
- 健康检查: http://localhost:8080/health
- 就绪检查: http://localhost:8080/ready
- API基础路径: http://localhost:8080/api/v1/

### 主要API端点

- `POST /api/v1/auth/login` - 用户登录
- `POST /api/v1/auth/register` - 用户注册
- `GET /api/v1/users/profile` - 获取用户信息
- `GET /api/v1/records` - 获取记录列表
- `POST /api/v1/records` - 创建记录

## 项目结构

```
├── cmd/                    # 应用入口
│   └── server/            # 服务器主程序
├── internal/              # 内部包
│   ├── app/              # 应用主逻辑
│   ├── config/           # 配置管理
│   ├── database/         # 数据库连接和迁移
│   ├── middleware/       # HTTP中间件
│   └── models/           # 数据模型
├── configs/              # 配置文件
├── scripts/              # 工具脚本
├── build/                # 构建输出
├── data/                 # 数据文件
└── logs/                 # 日志文件
```

## 开发进度

### ✅ 已完成
- [x] 项目基础架构搭建
- [x] 配置管理系统
- [x] 数据库连接和迁移
- [x] 基础中间件（日志、错误处理、CORS）
- [x] 数据模型定义
- [x] 路由结构设计

### 🚧 开发中
- [ ] 用户认证系统API
- [ ] RBAC权限管理API
- [ ] 记录管理核心API

### 📋 待开发
- [ ] 文件处理服务
- [ ] 数据导出服务
- [ ] 通知告警系统
- [ ] AI集成服务
- [ ] 前端客户端
- [ ] 移动端和桌面端

## 测试

```bash
# 运行所有测试
go test ./...

# 运行特定包测试
go test ./internal/config
go test ./internal/models

# 生成测试覆盖率报告
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html
```

## 部署

### Docker部署
```bash
# 构建镜像
docker build -t info-management-system .

# 使用docker-compose
docker-compose up -d
```

### 生产环境
1. 设置环境变量 `IMS_SERVER_MODE=release`
2. 配置生产数据库
3. 设置强密码和JWT密钥
4. 配置反向代理（Nginx）

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

MIT License

## 联系方式

如有问题或建议，请创建Issue或联系项目维护者。