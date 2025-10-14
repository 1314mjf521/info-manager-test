package middleware

import (
	"bytes"
	"io"
	"time"

	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// SystemLoggerMiddleware 系统日志中间件 - 将HTTP请求日志保存到数据库
func SystemLoggerMiddleware(systemService *services.SystemService) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 记录开始时间
		startTime := time.Now()

		// 获取请求信息
		method := c.Request.Method
		path := c.Request.URL.Path
		clientIP := c.ClientIP()
		userAgent := c.Request.UserAgent()
		requestID := c.GetString("request_id")

		// 获取用户ID（如果已认证）
		var userID *uint
		if id, exists := c.Get("user_id"); exists {
			if uid, ok := id.(uint); ok {
				userID = &uid
			}
		}

		// 读取请求体（如果需要）
		var requestBody string
		if c.Request.Body != nil && (method == "POST" || method == "PUT" || method == "PATCH") {
			bodyBytes, err := io.ReadAll(c.Request.Body)
			if err == nil {
				requestBody = string(bodyBytes)
				// 重新设置请求体，以便后续处理器可以读取
				c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
			}
		}

		// 处理请求
		c.Next()

		// 计算处理时间
		latency := time.Since(startTime)
		statusCode := c.Writer.Status()

		// 确定日志级别
		level := "info"
		if statusCode >= 400 && statusCode < 500 {
			level = "warn"
		} else if statusCode >= 500 {
			level = "error"
		}

		// 构建日志消息
		message := ""
		if len(c.Errors) > 0 {
			message = c.Errors.String()
		} else {
			message = "HTTP Request"
		}

		// 构建上下文信息
		context := map[string]interface{}{
			"method":      method,
			"path":        path,
			"status_code": statusCode,
			"latency_ms":  latency.Milliseconds(),
			"request_size": c.Request.ContentLength,
			"response_size": c.Writer.Size(),
		}

		// 如果是敏感操作，记录更多信息
		if method != "GET" && requestBody != "" {
			// 对于非GET请求，记录请求体（但要注意敏感信息）
			if len(requestBody) < 1000 { // 限制长度
				context["request_body"] = requestBody
			} else {
				context["request_body"] = "request body too large"
			}
		}

		// 异步记录日志到数据库
		go func() {
			systemService.LogSystemEvent(level, "http", message, context, userID, clientIP, userAgent, requestID)
		}()
	}
}

// InitialSystemLogs 初始化系统日志 - 在系统启动时记录
func InitialSystemLogs(systemService *services.SystemService) {
	// 记录系统启动日志
	systemService.LogSystemEvent("info", "system", "系统启动", 
		map[string]interface{}{
			"action": "system_startup",
			"timestamp": time.Now().Format(time.RFC3339),
		}, nil, "", "", "")

	// 记录系统初始化日志
	systemService.LogSystemEvent("info", "system", "系统初始化完成", 
		map[string]interface{}{
			"action": "system_initialized",
			"timestamp": time.Now().Format(time.RFC3339),
		}, nil, "", "", "")
}

// AuthLoggerMiddleware 认证日志中间件
func AuthLoggerMiddleware(systemService *services.SystemService) gin.HandlerFunc {
	return func(c *gin.Context) {
		path := c.Request.URL.Path
		method := c.Request.Method
		clientIP := c.ClientIP()
		userAgent := c.Request.UserAgent()

		// 只记录认证相关的请求
		if path == "/api/v1/auth/login" || path == "/api/v1/auth/register" || path == "/api/v1/auth/logout" {
			// 处理请求
			c.Next()

			statusCode := c.Writer.Status()
			
			// 获取用户ID（登录成功后）
			var userID *uint
			if id, exists := c.Get("user_id"); exists {
				if uid, ok := id.(uint); ok {
					userID = &uid
				}
			}

			// 确定日志级别和消息
			var level, message string
			var action string

			switch path {
			case "/api/v1/auth/login":
				action = "user_login"
				if statusCode == 200 {
					level = "info"
					message = "用户登录成功"
				} else {
					level = "warn"
					message = "用户登录失败"
				}
			case "/api/v1/auth/register":
				action = "user_register"
				if statusCode == 201 {
					level = "info"
					message = "用户注册成功"
				} else {
					level = "warn"
					message = "用户注册失败"
				}
			case "/api/v1/auth/logout":
				action = "user_logout"
				level = "info"
				message = "用户注销"
			}

			// 记录认证日志
			go func() {
				systemService.LogSystemEvent(level, "auth", message, 
					map[string]interface{}{
						"action": action,
						"method": method,
						"path": path,
						"status_code": statusCode,
					}, userID, clientIP, userAgent, "")
			}()
		} else {
			c.Next()
		}
	}
}