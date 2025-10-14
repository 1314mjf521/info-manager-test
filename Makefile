# 项目配置
PROJECT_NAME := info-management-system
BINARY_NAME := server
BUILD_DIR := build
DOCKER_IMAGE := $(PROJECT_NAME)

# Go配置
GO_VERSION := 1.21
GOOS := $(shell go env GOOS)
GOARCH := $(shell go env GOARCH)
GOPROXY := https://mirrors.aliyun.com/goproxy/,direct
GOSUMDB := sum.golang.google.cn

# 版本信息
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT := $(shell git rev-parse HEAD 2>/dev/null || echo "unknown")

# 构建标志
LDFLAGS := -ldflags "-X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME) -X main.GitCommit=$(GIT_COMMIT)"

.PHONY: help build run test clean docker deps lint fmt vet

# 默认目标
all: build

# 显示帮助信息
help:
	@echo "Available commands:"
	@echo "  build     - Build the application"
	@echo "  run       - Run the application"
	@echo "  test      - Run tests"
	@echo "  clean     - Clean build artifacts"
	@echo "  docker    - Build Docker image"
	@echo "  deps      - Download dependencies"
	@echo "  lint      - Run linter"
	@echo "  fmt       - Format code"
	@echo "  vet       - Run go vet"

# 下载依赖
deps:
	@echo "Downloading dependencies..."
	GOPROXY=$(GOPROXY) GOSUMDB=$(GOSUMDB) go mod download
	GOPROXY=$(GOPROXY) GOSUMDB=$(GOSUMDB) go mod tidy

# 格式化代码
fmt:
	@echo "Formatting code..."
	go fmt ./...

# 运行go vet
vet:
	@echo "Running go vet..."
	go vet ./...

# 运行linter (需要安装golangci-lint)
lint:
	@echo "Running linter..."
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "golangci-lint not installed, skipping..."; \
	fi

# 构建应用
build: deps fmt vet
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 GOOS=$(GOOS) GOARCH=$(GOARCH) GOPROXY=$(GOPROXY) GOSUMDB=$(GOSUMDB) go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd/server

# Windows构建
build-windows: deps fmt vet
	@echo "Building $(BINARY_NAME) for Windows..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME).exe ./cmd/server

# Linux构建
build-linux: deps fmt vet
	@echo "Building $(BINARY_NAME) for Linux..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd/server

# 多平台构建
build-all: build-linux build-windows
	@echo "Multi-platform build completed"

# 运行应用
run: build
	@echo "Running $(BINARY_NAME)..."
	./$(BUILD_DIR)/$(BINARY_NAME)

# 运行开发模式
dev:
	@echo "Running in development mode..."
	go run ./cmd/server

# 运行测试
test:
	@echo "Running tests..."
	go test -v -race -coverprofile=coverage.out ./...

# 运行测试并生成覆盖率报告
test-coverage: test
	@echo "Generating coverage report..."
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

# 基准测试
benchmark:
	@echo "Running benchmarks..."
	go test -bench=. -benchmem ./...

# 清理构建产物
clean:
	@echo "Cleaning..."
	rm -rf $(BUILD_DIR)
	rm -f coverage.out coverage.html
	go clean -cache

# 构建Docker镜像
docker:
	@echo "Building Docker image..."
	docker build -t $(DOCKER_IMAGE):$(VERSION) .
	docker tag $(DOCKER_IMAGE):$(VERSION) $(DOCKER_IMAGE):latest

# 运行Docker容器
docker-run:
	@echo "Running Docker container..."
	docker run -p 8080:8080 --env-file .env $(DOCKER_IMAGE):latest

# 创建数据目录
create-dirs:
	@echo "Creating directories..."
	mkdir -p data logs

# 初始化项目
init: create-dirs deps
	@echo "Project initialized successfully!"

# 安装开发工具
install-tools:
	@echo "Installing development tools..."
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install github.com/swaggo/swag/cmd/swag@latest

# 生成API文档
docs:
	@echo "Generating API documentation..."
	@if command -v swag >/dev/null 2>&1; then \
		swag init -g cmd/server/main.go; \
	else \
		echo "swag not installed, run 'make install-tools' first"; \
	fi

# 数据库迁移
migrate:
	@echo "Running database migrations..."
	go run ./cmd/server -migrate

# 重置数据库
reset-db:
	@echo "Resetting database..."
	rm -f data/info_system.db
	$(MAKE) migrate

# 验证项目设置
verify:
	@echo "Verifying project setup..."
	go run ./scripts/test-basic.go

# 完整验证（需要数据库）
verify-full:
	@echo "Full verification with database..."
	go run ./scripts/verify-setup.go