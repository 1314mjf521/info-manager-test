# 信息管理系统 Makefile

.PHONY: help build run test clean init-permissions

# 默认目标
help:
	@echo "可用的命令:"
	@echo "  build           - 构建应用程序"
	@echo "  run             - 运行应用程序"
	@echo "  test            - 运行测试"
	@echo "  clean           - 清理构建文件"
	@echo "  init-permissions - 初始化精细化权限数据"

# 构建应用程序
build:
	@echo "构建应用程序..."
	go build -o bin/info-management-system cmd/server/main.go
	go build -o bin/init-permissions cmd/init-permissions/main.go

# 运行应用程序
run:
	@echo "启动应用程序..."
	go run cmd/server/main.go

# 运行测试
test:
	@echo "运行测试..."
	go test -v ./...

# 清理构建文件
clean:
	@echo "清理构建文件..."
	rm -rf bin/

# 初始化精细化权限数据
init-permissions:
	@echo "初始化精细化权限数据..."
	go run cmd/init-permissions/main.go

# 开发环境设置
dev-setup:
	@echo "设置开发环境..."
	go mod tidy
	go mod download

# 数据库迁移
migrate:
	@echo "执行数据库迁移..."
	go run cmd/migrate/main.go

# 构建Docker镜像
docker-build:
	@echo "构建Docker镜像..."
	docker build -t info-management-system .

# 运行Docker容器
docker-run:
	@echo "运行Docker容器..."
	docker-compose up -d