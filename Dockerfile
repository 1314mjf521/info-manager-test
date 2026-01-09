# 多阶段构建 Dockerfile

# 阶段1: 构建前端
FROM node:18-alpine AS frontend-builder

WORKDIR /app/frontend

# 复制前端依赖文件
COPY frontend/package*.json ./

# 安装依赖
RUN npm ci --only=production=false

# 复制前端源码
COPY frontend/ ./

# 构建前端
RUN npm run build

# 阶段2: 构建后端
FROM golang:1.21-alpine AS backend-builder

# 安装必要工具
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

# 复制Go模块文件
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源码
COPY . .

# 构建后端应用
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/server

# 阶段3: 运行时镜像
FROM alpine:latest

# 安装运行时依赖
RUN apk --no-cache add ca-certificates tzdata

# 创建应用用户
RUN addgroup -g 1001 -S app && \
    adduser -S app -u 1001 -G app

# 设置工作目录
WORKDIR /app

# 从构建阶段复制文件
COPY --from=backend-builder /app/main .
COPY --from=frontend-builder /app/frontend/dist ./static
COPY --chown=app:app configs/ ./configs/

# 创建必要目录
RUN mkdir -p /app/logs /app/uploads /app/data && \
    chown -R app:app /app

# 切换到应用用户
USER app

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/api/v1/health || exit 1

# 启动应用
CMD ["./main"]