# 信息记录管理系统 - Windows 版本

## 快速开始

### 1. 准备配置文件

首次运行前，需要创建配置文件：

1. 复制 `configs/config.example.yaml` 为 `configs/config.yaml`
2. 根据需要修改配置文件中的设置

```bash
copy configs\config.example.yaml configs\config.yaml
```

### 2. 启动系统

#### 方法一：使用启动脚本（推荐）
双击运行 `start.bat` 文件

#### 方法二：命令行启动
```bash
info-management-system.exe
```

### 3. 访问系统

系统启动后，在浏览器中访问：
- 默认地址：http://localhost:8080
- 健康检查：http://localhost:8080/health

## 默认账号

首次启动时，系统会自动创建管理员账号：
- 用户名：admin
- 密码：admin123

**重要：请在首次登录后立即修改默认密码！**

## 主要功能

### 1. 用户管理
- 用户注册和登录
- 角色和权限管理
- 用户信息管理

### 2. 记录管理
- 多类型信息记录（日报、周报、年报等）
- 记录的增删改查
- 批量导入导出
- 记录版本控制

### 3. 权限控制
- 基于角色的访问控制（RBAC）
- 细粒度权限管理
- 数据访问权限控制

### 4. 审计日志
- 完整的操作审计
- 变更历史追踪
- 安全日志记录

## API 接口

系统提供完整的 RESTful API，主要接口包括：

### 认证接口
- `POST /api/v1/auth/login` - 用户登录
- `POST /api/v1/auth/register` - 用户注册
- `POST /api/v1/auth/logout` - 用户登出

### 记录管理接口
- `GET /api/v1/records` - 获取记录列表
- `POST /api/v1/records` - 创建记录
- `GET /api/v1/records/{id}` - 获取单条记录
- `PUT /api/v1/records/{id}` - 更新记录
- `DELETE /api/v1/records/{id}` - 删除记录
- `POST /api/v1/records/batch` - 批量创建记录
- `POST /api/v1/records/import` - 导入记录

### 记录类型管理接口
- `GET /api/v1/record-types` - 获取记录类型列表
- `POST /api/v1/record-types` - 创建记录类型
- `PUT /api/v1/record-types/{id}` - 更新记录类型
- `DELETE /api/v1/record-types/{id}` - 删除记录类型

### 权限管理接口
- `GET /api/v1/roles` - 获取角色列表
- `POST /api/v1/roles` - 创建角色
- `POST /api/v1/permissions/check` - 权限检查

### 审计接口
- `GET /api/v1/audit/logs` - 获取审计日志
- `GET /api/v1/audit/statistics` - 获取审计统计

## 配置说明

### 数据库配置

系统支持多种数据库：

#### SQLite（推荐用于单机部署）
```yaml
database:
  driver: "sqlite"
  sqlite:
    path: "data/info_system.db"
```

#### MySQL
```yaml
database:
  driver: "mysql"
  mysql:
    host: "localhost"
    port: 3306
    username: "root"
    password: "password"
    database: "info_system"
```

#### PostgreSQL
```yaml
database:
  driver: "postgres"
  postgres:
    host: "localhost"
    port: 5432
    username: "postgres"
    password: "password"
    database: "info_system"
```

### 安全配置

#### JWT 配置
```yaml
jwt:
  secret: "your-secret-key-change-this-in-production"
  expires_in: 24h
```

#### CORS 配置
```yaml
security:
  cors:
    allowed_origins:
      - "http://localhost:3000"
    allow_credentials: true
```

## 目录结构

```
info-manager/
├── info-management-system.exe  # 主程序
├── start.bat                   # 启动脚本
├── configs/
│   ├── config.yaml            # 配置文件
│   └── config.example.yaml    # 配置文件示例
├── data/                      # 数据目录（SQLite数据库）
├── logs/                      # 日志目录
├── uploads/                   # 文件上传目录
└── README_Windows.md          # 本文档
```

## 故障排除

### 1. 端口被占用
如果8080端口被占用，可以修改配置文件中的端口：
```yaml
server:
  port: 8081
```

### 2. 数据库连接失败
- 检查数据库配置是否正确
- 确保数据库服务正在运行
- 检查网络连接

### 3. 权限问题
- 确保程序有读写数据目录的权限
- 在某些情况下可能需要以管理员身份运行

### 4. 查看日志
系统日志会输出到控制台，也可以配置输出到文件：
```yaml
log:
  output: "file"
  file_path: "logs/app.log"
```

## 性能优化

### 1. 数据库优化
- 对于大量数据，建议使用 MySQL 或 PostgreSQL
- 定期清理审计日志
- 配置合适的连接池参数

### 2. 缓存配置
启用 Redis 缓存可以提高性能：
```yaml
redis:
  enabled: true
  host: "localhost"
  port: 6379
```

## 备份和恢复

### SQLite 备份
```bash
copy data\info_system.db data\info_system_backup.db
```

### MySQL/PostgreSQL 备份
使用相应数据库的备份工具进行备份。

## 更新升级

1. 停止当前运行的程序
2. 备份数据和配置文件
3. 替换 `info-management-system.exe` 文件
4. 重新启动程序

## 技术支持

如有问题，请检查：
1. 配置文件是否正确
2. 数据库连接是否正常
3. 端口是否被占用
4. 系统日志中的错误信息

## 版本信息

- 版本：v1.0.0
- 构建时间：2025-01-03
- Go 版本：1.21+
- 支持平台：Windows x64